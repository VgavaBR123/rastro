// Sessao do Rastro Seguro com relogio e tick falsos contra o servidor falso
// do contrato: posicoes a cada tick (com e sem ponto novo, moving pelo
// deslocamento real), silencio de rede e reenvio, checagem chegando (voz
// critica e vibracao uma vez, prazo local), Estou bem, Estender, alerta, SOS
// (antes da posicao, pendente sem rede, sem esperar tick preso), erros 5xx,
// 401 e 400, fim pelo backend com aviso, encerrar chamando arrived (pendente
// no banco), 409 de outro aparelho, recuperacao que so encerra sessao deste
// aparelho, descarte durante a criacao e troca de conta.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/narrator.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_ui_state.dart';
import 'package:strava_estudo_app/safety/safety_api.dart';
import 'package:strava_estudo_app/safety/safety_local_store.dart';
import 'package:strava_estudo_app/safety/safety_models.dart';
import 'package:strava_estudo_app/safety/safety_session_controller.dart';

import '../narrator/fake_voice_announcer.dart';
import '../recording/fakes.dart';
import 'fake_safety_server.dart';

class FakeSafetyHaptics implements SafetyHaptics {
  int alerts = 0;
  @override
  Future<void> alert() async => alerts++;
}

const min = 60000;

void main() {
  late FakeSafetyServer server;
  late FakeHeartbeatTicker ticker;
  late FakeVoiceAnnouncer voice;
  late FakeSafetyHaptics haptics;
  late RecordingDatabase db;
  late SafetyLocalStore local;
  late SafetySessionController ctrl;
  late String contactId;
  late TrustedContact contact;
  var nowMs = 0;
  LocationSample? sample;
  var accepted = <LocationSample>[];
  var rec = const RecordingUiState(state: RecordingState.recording);
  String? recGuid = 'act_1';

  /// [meters] para o norte a partir de -23.5, -46.6.
  LocationSample fix(double meters, int at, {double acc = 4}) => LocationSample(
    position: GeoPoint(latitude: -23.5 + meters / 111195, longitude: -46.6),
    wallClockMs: at,
    monotonicMs: at,
    horizontalAccuracyMeters: acc,
  );

  SafetyApi api() => SafetyApi(Dio()..httpClientAdapter = server, 'http://srv', token: () async => 'tok');

  SafetySessionController newCtrl() => SafetySessionController(
    api: api(),
    local: local,
    ticker: ticker,
    interval: const Duration(seconds: 60),
    now: () => nowMs,
    lastSample: () => sample,
    recentAccepted: (since) => [
      for (final s in accepted)
        if (s.wallClockMs >= since) s,
    ],
    recording: () => rec,
    recordingGuid: () => recGuid,
    currentUserId: () => 'u_ana',
    narrator: Narrator(voice, now: () => nowMs),
    haptics: haptics,
  );

  Future<void> tick() async {
    ticker.tick();
    await Future<void>.delayed(Duration.zero);
    await ctrl.idle();
    await Future<void>.delayed(Duration.zero);
    await ctrl.idle();
  }

  List<Object?> positions() => [for (final r in server.requestsTo('POST', '/positions')) r.body];

  setUp(() {
    nowMs = 100 * min;
    sample = null;
    accepted = [];
    rec = const RecordingUiState(state: RecordingState.recording);
    recGuid = 'act_1';
    server = FakeSafetyServer(now: () => nowMs);
    final ana = server.addUser('tok', 'u_ana', 'ana@x.com', 'Ana');
    final bia = server.addUser('tok-bia', 'u_bia', 'bia@x.com', 'Bia');
    contactId = server.linkAccepted(ana, bia);
    contact = TrustedContact(
      id: contactId,
      otherUserId: 'u_bia',
      displayName: 'Bia',
      email: 'bia@x.com',
      status: ContactStatus.accepted,
      createdAt: 0,
    );
    ticker = FakeHeartbeatTicker();
    voice = FakeVoiceAnnouncer();
    haptics = FakeSafetyHaptics();
    db = RecordingDatabase(NativeDatabase.memory());
    local = SafetyLocalStore(db);
    ctrl = newCtrl();
  });

  tearDown(() async {
    ctrl.dispose();
    await db.close();
  });

  Future<void> begin({int minutes = 30}) async {
    final r = await ctrl.begin(guid: 'act_1', plan: SafetyPlan(contacts: [contact], minutes: minutes), startMs: nowMs);
    expect(r, SafetyBeginResult.started);
    await ctrl.idle();
  }

  /// Sessao criada por fora (outro aparelho da mesma conta).
  Future<String> otherDeviceSession(String guid) async =>
      (await api().createSession(activityGuid: guid, etaMs: nowMs + 60 * min, contactIds: [contactId])).id;

  test('Iniciar cria a sessao com guid, eta e contatos, registra no aparelho e manda o primeiro sinal', () async {
    await begin(minutes: 45);
    final body = server.requestsTo('POST', '/safety/sessions').first.body as Map;
    expect(body['activityGuid'], 'act_1');
    expect(body['etaMs'], nowMs + 45 * min);
    expect(body['contactIds'], [contactId]);
    expect(ctrl.state.active, isTrue);
    expect(await local.isLocal(ctrl.sessionId!), isTrue);
    expect(ticker.intervals, [const Duration(seconds: 60)]);
    expect((positions().single as Map)['lat'], isNull);
  });

  test('horario fora de 5 min a 12 h nao cria sessao', () async {
    final r = await ctrl.begin(
      guid: 'act_1',
      plan: SafetyPlan(contacts: [contact], etaAtMs: nowMs + 2 * min),
      startMs: nowMs,
    );
    expect(r, SafetyBeginResult.invalidEta);
    expect(server.requests, isEmpty);
  });

  test('sem rede, 5xx ou sem login no Iniciar: resultado explica e nao liga', () async {
    final plan = SafetyPlan(contacts: [contact], minutes: 30);
    server.offline = true;
    expect(await ctrl.begin(guid: 'act_1', plan: plan, startMs: nowMs), SafetyBeginResult.offline);
    server.offline = false;
    server.overrides['POST /safety/sessions'] = (503, {'error': 'fora'});
    expect(await ctrl.begin(guid: 'act_1', plan: plan, startMs: nowMs), SafetyBeginResult.offline);
    server.overrides.clear();
    server.tokens.clear();
    expect(await ctrl.begin(guid: 'act_1', plan: plan, startMs: nowMs), SafetyBeginResult.signedOut);
    expect(ctrl.state.active, isFalse);
  });

  group('moving pelo deslocamento real', () {
    test('auto-pausa desligada e a pessoa parada: moving false', () async {
      await begin();
      // Gravando (sem auto-pausa) com pontos aceitos no mesmo lugar.
      accepted = [fix(0, nowMs + 10000), fix(3, nowMs + 30000), fix(5, nowMs + 50000)];
      sample = accepted.last;
      nowMs += min;
      await tick();
      expect((positions().last as Map)['moving'], isFalse);
      expect((positions().last as Map)['paused'], isFalse);
    });

    test('andando mais de 15 m no intervalo: moving true, mesmo em auto-pausa', () async {
      await begin();
      rec = const RecordingUiState(state: RecordingState.autoPaused);
      accepted = [fix(0, nowMs + 10000), fix(40, nowMs + 50000)];
      sample = accepted.last;
      nowMs += min;
      await tick();
      expect((positions().last as Map)['moving'], isTrue);
    });

    test('precisao ruim: 20 m com precisao de 30 m nao conta', () async {
      await begin();
      accepted = [fix(0, nowMs + 10000, acc: 30), fix(20, nowMs + 50000, acc: 30)];
      sample = accepted.last;
      nowMs += min;
      await tick();
      expect((positions().last as Map)['moving'], isFalse);
    });

    test('sem amostra nova no intervalo: moving false; pausa manual: paused', () async {
      await begin();
      accepted = [fix(0, nowMs - 30000)];
      nowMs += 2 * min;
      await tick();
      expect((positions().last as Map)['moving'], isFalse);
      rec = const RecordingUiState(state: RecordingState.manuallyPaused);
      await tick();
      expect((positions().last as Map)['paused'], isTrue);
      expect((positions().last as Map)['moving'], isFalse);
    });

    test('ancora antes do intervalo: um ponto novo a 30 m conta como movimento', () async {
      await begin();
      accepted = [fix(0, nowMs + 1000), fix(30, nowMs + min + 20000)];
      sample = accepted.last;
      nowMs += min + 30000;
      await tick();
      expect((positions().last as Map)['moving'], isTrue);
    });
  });

  test('tick manda a ultima posicao; sem ponto novo vai batimento', () async {
    await begin();
    sample = fix(0, nowMs);
    nowMs += min;
    await tick();
    expect((positions().last as Map)['lat'], closeTo(-23.5, 1e-9));
    expect((positions().last as Map)['accuracyM'], 4.0);
    nowMs += min;
    await tick();
    expect((positions().last as Map)['lat'], isNull);
    expect((positions().last as Map)['recordedAtMs'], nowMs);
  });

  test('sem rede guarda so a ultima posicao e reenvia no proximo tick', () async {
    await begin();
    server.offline = true;
    sample = fix(10, nowMs);
    await tick();
    expect(ctrl.state.offline, isTrue);
    sample = fix(20, nowMs + 1);
    await tick();
    final sent = positions().length;
    server.offline = false;
    await tick();
    expect(ctrl.state.offline, isFalse);
    expect(positions().length, sent + 1);
    expect((positions().last as Map)['recordedAtMs'], nowMs + 1);
    await tick();
    expect((positions().last as Map)['lat'], isNull);
  });

  group('erros', () {
    test('5xx conta como sem conexao', () async {
      await begin();
      server.overrides['POST /safety/sessions/'] = (502, {'error': 'gateway'});
      await tick();
      expect(ctrl.state.offline, isTrue);
      expect(ctrl.state.active, isTrue);
    });

    test('401: fala critica e aviso de entrar de novo', () async {
      await begin();
      server.overrides['POST /safety/sessions/'] = (401, {'error': 'token'});
      await tick();
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.state.notice, SafetyNotice.signedOut);
      expect(voice.spoken.last, safetyNoticeText(SafetyNotice.signedOut));
      expect(haptics.alerts, 1);
      await tick();
      expect(haptics.alerts, 1, reason: 'uma vez so');
      server.overrides.clear();
      await tick();
      expect(ctrl.state.notice, isNull);
    });

    test('400 na posicao: a amostra e descartada e o proximo envio e batimento', () async {
      await begin();
      sample = fix(0, nowMs);
      server.overrides['POST /safety/sessions/'] = (400, {'error': 'lat fora da faixa'});
      await tick();
      server.overrides.clear();
      await tick();
      expect((positions().last as Map)['lat'], isNull);
    });

    test('backend encerrou a sessao (409): fala, vibra e aviso ate dispensar', () async {
      await begin();
      server.sessionById(ctrl.sessionId!)!['status'] = 'ended';
      await tick();
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.state.active, isFalse);
      expect(ticker.hasListener, isFalse);
      expect(ctrl.state.notice, SafetyNotice.ended);
      expect(voice.spoken.last, 'Rastro Seguro encerrado. Seus contatos nao estao mais acompanhando.');
      expect(haptics.alerts, 1);
      ctrl.dismissNotice();
      expect(ctrl.state.notice, isNull);
    });

    test('sessao some (404) tambem avisa', () async {
      await begin();
      server.sessions.clear();
      await tick();
      expect(ctrl.state.notice, SafetyNotice.ended);
    });
  });

  test('checagem: voz e vibracao uma vez; prazo contado no relogio local', () async {
    await begin();
    final id = ctrl.sessionId!;
    // Relogio do servidor adiantado 10 min: o prazo local usa so a duracao.
    server.now = () => nowMs + 10 * min;
    server.startCheck(id, reason: 'stopped', deadlineMs: nowMs + 10 * min + 2 * min);
    await tick();
    expect(ctrl.state.check!.reason, CheckReason.stopped);
    expect(ctrl.state.checkLocalDeadlineMs, nowMs + 2 * min);
    await Future<void>.delayed(Duration.zero);
    expect(voice.spoken, [kSafetyCheckPhrase]);
    expect(haptics.alerts, 1);
    await tick();
    expect(voice.spoken, hasLength(1));
    expect(await ctrl.ok(), isTrue);
    expect(ctrl.state.check, isNull);
    expect(ctrl.state.checkLocalDeadlineMs, isNull);
  });

  test('checagem vinda da caixa de entrada rele a sessao', () async {
    await begin();
    server.startCheck(ctrl.sessionId!);
    await ctrl.onInboxCheck(ctrl.sessionId);
    expect(ctrl.state.check, isNotNull);
    await ctrl.onInboxCheck('ss_outra');
    expect(server.requestsTo('GET', '/safety/sessions/ss_outra'), isEmpty);
  });

  test('Estender soma ao horario; alerta avisa e Estou bem continua', () async {
    await begin();
    final eta = ctrl.state.session!.etaMs;
    expect(await ctrl.extend(15), isTrue);
    expect(ctrl.state.session!.etaMs, eta + 15 * min);
    server.startCheck(ctrl.sessionId!);
    server.alert(ctrl.sessionId!);
    await tick();
    expect(ctrl.state.alerted, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(voice.spoken.last, contains('contatos foram avisados'));
    expect(await ctrl.ok(), isTrue);
    expect(ctrl.state.alerted, isFalse);
  });

  test('sem contatos na sessao: aviso persistente e fala critica', () async {
    await begin();
    ctrl.onNoContacts(ctrl.sessionId);
    await Future<void>.delayed(Duration.zero);
    expect(ctrl.state.notice, SafetyNotice.noContacts);
    expect(voice.spoken.last, contains('Ninguem vai ser avisado'));
    ctrl.onNoContacts(ctrl.sessionId);
    expect(haptics.alerts, 1);
  });

  group('SOS', () {
    test('o SOS sai antes da posicao', () async {
      await begin();
      sample = fix(0, nowMs);
      final before = server.requests.length;
      expect(await ctrl.sos(), isTrue);
      await ctrl.idle();
      final after = server.requests.sublist(before).map((r) => r.path.split('/').last).toList();
      expect(after, ['sos', 'positions']);
      expect((positions().last as Map)['lat'], isNotNull);
      expect(ctrl.state.message, contains('enviada'));
    });

    test('sem rede fica pendente e e repetido no tick ate sair', () async {
      await begin();
      server.offline = true;
      expect(await ctrl.sos(), isFalse);
      expect(ctrl.state.sosPending, isTrue);
      expect(ctrl.state.message, kSosPendingText);
      await tick();
      expect(ctrl.state.sosPending, isTrue);
      server.offline = false;
      await tick();
      expect(ctrl.state.sosPending, isFalse);
      expect(server.notifications.where((n) => n['type'] == 'safety_sos'), hasLength(1));
    });

    test('nao espera um envio de posicao preso', () async {
      await begin();
      final gate = server.gates['/positions'] = Completer<void>();
      ticker.tick(); // envio preso
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(await ctrl.sos(), isTrue);
      expect(server.notifications.where((n) => n['type'] == 'safety_sos'), hasLength(1));
      gate.complete();
      await ctrl.idle();
    });
  });

  group('fim', () {
    test('fim da gravacao chama arrived e para o tick', () async {
      await begin();
      final id = ctrl.sessionId!;
      ctrl.onRecording(const RecordingUiState(state: RecordingState.finished));
      await ctrl.idle();
      expect(server.sessionById(id)!['status'], 'ended');
      expect(await local.isLocal(id), isFalse);
      expect(ticker.hasListener, isFalse);
      expect(ctrl.state.notice, isNull, reason: 'fim pedido nao vira aviso');
    });

    test('arrived sem rede fica no banco e sai na proxima abertura', () async {
      await begin();
      final id = ctrl.sessionId!;
      server.offline = true;
      await ctrl.arrive();
      expect((await local.pendingArrivals()).single.sessionId, id);
      // App fechado e aberto de novo.
      ctrl.dispose();
      rec = const RecordingUiState();
      recGuid = null;
      server.offline = false;
      ctrl = newCtrl();
      await ctrl.reconcile();
      expect(server.sessionById(id)!['status'], 'ended');
      expect(await local.pendingArrivals(), isEmpty);
    });

    test('sem rede o tick tambem repete o arrived', () async {
      await begin();
      final id = ctrl.sessionId!;
      server.offline = true;
      await ctrl.arrive();
      server.offline = false;
      await tick();
      expect(server.sessionById(id)!['status'], 'ended');
    });

    test('descartou enquanto a sessao era criada: encerra e nao liga o tick', () async {
      final gate = server.gates['/safety/sessions'] = Completer<void>();
      final r = ctrl.begin(guid: 'act_1', plan: SafetyPlan(contacts: [contact], minutes: 30), startMs: nowMs);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      rec = const RecordingUiState(state: RecordingState.finished);
      server.gates.clear();
      gate.complete();
      expect(await r, SafetyBeginResult.cancelled);
      expect(server.sessions.single['status'], 'ended');
      expect(ticker.hasListener, isFalse);
      expect(ctrl.state.active, isFalse);
    });

    test('sair da conta encerra a sessao em andamento e zera o controller', () async {
      await begin();
      final id = ctrl.sessionId!;
      await ctrl.beforeSignOut();
      expect(server.sessionById(id)!['status'], 'ended');
      expect(ctrl.state.active, isFalse);
      expect(ticker.hasListener, isFalse);
    });

    test('sem conta conhecida, a recuperacao nao manda pendente de ninguem', () async {
      await local.created(sessionId: 'ss_y', activityGuid: 'g', ownerUserId: 'u_outra', nowMs: 1);
      await local.markPendingArrival('ss_y');
      ctrl.dispose();
      ctrl = SafetySessionController(
        api: api(),
        local: local,
        ticker: ticker,
        now: () => nowMs,
        lastSample: () => null,
        recording: () => const RecordingUiState(),
        recordingGuid: () => null,
        narrator: Narrator(voice, now: () => nowMs),
      );
      await ctrl.reconcile();
      expect(server.requestsTo('POST', '/ss_y/arrived'), isEmpty);
      expect(await local.pendingArrivals(), hasLength(1));
    });

    test('pendente de outra conta nao sai com esta', () async {
      await local.created(sessionId: 'ss_x', activityGuid: 'g', ownerUserId: 'u_outra', nowMs: 1);
      await local.markPendingArrival('ss_x');
      await sendPendingArrivals(api(), local, ownerUserId: 'u_ana');
      expect(server.requestsTo('POST', '/ss_x/arrived'), isEmpty);
    });
  });

  group('outro aparelho', () {
    test('409 com sessao de outro aparelho: nao encerra nada e avisa', () async {
      final other = await otherDeviceSession('act_outro');
      final r = await ctrl.begin(guid: 'act_1', plan: SafetyPlan(contacts: [contact], minutes: 30), startMs: nowMs);
      expect(r, SafetyBeginResult.otherDevice);
      expect(server.sessionById(other)!['status'], 'active');
      expect(server.requestsTo('POST', '/arrived'), isEmpty);
      expect(server.notifications.where((n) => n['type'] == 'safety_all_clear'), isEmpty);
    });

    test('Encerrar o outro e usar este: encerra e cria', () async {
      final other = await otherDeviceSession('act_outro');
      final r = await ctrl.takeOver(guid: 'act_1', plan: SafetyPlan(contacts: [contact], minutes: 30), startMs: nowMs);
      expect(r, SafetyBeginResult.started);
      expect(server.sessionById(other)!['status'], 'ended');
      expect(ctrl.state.session!.activityGuid, 'act_1');
    });

    test('409 com sobra de crash DESTE aparelho: encerra a sobra e cria', () async {
      final old = await otherDeviceSession('act_0');
      await local.created(sessionId: old, activityGuid: 'act_0', ownerUserId: 'u_ana', nowMs: 1);
      await begin();
      expect(server.sessionById(old)!['status'], 'ended');
    });

    test('recuperacao nao encerra sessao de outro aparelho', () async {
      final other = await otherDeviceSession('act_outro');
      rec = const RecordingUiState();
      recGuid = null;
      await ctrl.reconcile(interrupted: (_) async => false);
      await ctrl.endFor('act_outro');
      expect(server.sessionById(other)!['status'], 'active');
    });
  });

  group('recuperacao apos crash (sessao deste aparelho)', () {
    late String id;
    setUp(() async {
      id = await otherDeviceSession('act_1');
      await local.created(sessionId: id, activityGuid: 'act_1', ownerUserId: 'u_ana', nowMs: 1);
    });

    test('sessao da gravacao retomada religa a faixa e o tick', () async {
      await ctrl.reconcile();
      expect(ctrl.sessionId, id);
      await tick();
      expect(positions(), hasLength(1));
    });

    test('atividade esperando a decisao de retomar: fica como esta; salvar encerra', () async {
      rec = const RecordingUiState();
      recGuid = null;
      await ctrl.reconcile(interrupted: (g) async => g == 'act_1');
      expect(server.sessionById(id)!['status'], 'active');
      await ctrl.endFor('act_1');
      expect(server.sessionById(id)!['status'], 'ended');
    });

    test('atividade que ja terminou: encerra', () async {
      rec = const RecordingUiState();
      recGuid = null;
      await ctrl.reconcile(interrupted: (_) async => false);
      expect(server.sessionById(id)!['status'], 'ended');
    });
  });
}
