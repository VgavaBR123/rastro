// Sessao do Rastro Seguro com relogio e tick falsos contra o servidor falso
// do contrato: posicoes a cada tick (com e sem ponto novo), silencio de rede
// e reenvio, checagem chegando (voz critica e vibracao uma vez), Estou bem,
// Estender, alerta, SOS, encerrar chamando arrived (com reenvio sem rede),
// 409 de sessao presa e recuperacao apos crash.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/narrator.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_ui_state.dart';
import 'package:strava_estudo_app/safety/safety_api.dart';
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
  late SafetySessionController ctrl;
  late String contactId;
  late TrustedContact contact;
  var nowMs = 0;
  LocationSample? sample;
  var rec = const RecordingUiState(state: RecordingState.recording);
  String? recGuid = 'act_1';

  LocationSample fix(double lat, int at) => LocationSample(
    position: GeoPoint(latitude: lat, longitude: -46.6),
    wallClockMs: at,
    monotonicMs: at,
    horizontalAccuracyMeters: 4,
  );

  Future<void> tick() async {
    ticker.tick();
    await Future<void>.delayed(Duration.zero);
    await ctrl.idle();
  }

  List<Object?> positions() => [for (final r in server.requestsTo('POST', '/positions')) r.body];

  setUp(() {
    nowMs = 100 * min;
    sample = null;
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
    ctrl = SafetySessionController(
      api: SafetyApi(Dio()..httpClientAdapter = server, 'http://srv', token: () async => 'tok'),
      ticker: ticker,
      interval: const Duration(seconds: 60),
      now: () => nowMs,
      lastSample: () => sample,
      recording: () => rec,
      recordingGuid: () => recGuid,
      narrator: Narrator(voice, now: () => nowMs),
      haptics: haptics,
    );
  });

  tearDown(() => ctrl.dispose());

  Future<void> begin({int minutes = 30}) async {
    final r = await ctrl.begin(
      guid: 'act_1',
      plan: SafetyPlan(contacts: [contact], minutes: minutes),
      startMs: nowMs,
    );
    expect(r, SafetyBeginResult.started);
    await ctrl.idle();
  }

  test('Iniciar cria a sessao com guid, eta e contatos e manda o primeiro sinal', () async {
    await begin(minutes: 45);
    final body = server.requestsTo('POST', '/safety/sessions').first.body as Map;
    expect(body['activityGuid'], 'act_1');
    expect(body['etaMs'], nowMs + 45 * min);
    expect(body['contactIds'], [contactId]);
    expect(ctrl.state.active, isTrue);
    expect(ctrl.state.session!.etaMs, nowMs + 45 * min);
    expect(ticker.intervals, [const Duration(seconds: 60)]);
    // Sem GPS ainda: batimento.
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
    expect(ctrl.state.active, isFalse);
  });

  test('sem rede ou sem login no Iniciar: resultado explica e nao liga', () async {
    server.offline = true;
    expect(
      await ctrl.begin(
        guid: 'act_1',
        plan: SafetyPlan(contacts: [contact], minutes: 30),
        startMs: nowMs,
      ),
      SafetyBeginResult.offline,
    );
    server.offline = false;
    server.tokens.clear();
    expect(
      await ctrl.begin(
        guid: 'act_1',
        plan: SafetyPlan(contacts: [contact], minutes: 30),
        startMs: nowMs,
      ),
      SafetyBeginResult.signedOut,
    );
    expect(ctrl.state.active, isFalse);
  });

  test('tick manda a ultima posicao; sem ponto novo vai batimento; pausa e parada', () async {
    await begin();
    sample = fix(-23.5, nowMs);
    nowMs += min;
    await tick();
    final p1 = positions().last as Map;
    expect(p1['lat'], -23.5);
    expect(p1['accuracyM'], 4.0);
    expect(p1['moving'], isTrue);
    expect(p1['paused'], isFalse);

    // Mesmo ponto (GPS mudo): batimento, mesmo sem a gravacao andar.
    nowMs += min;
    await tick();
    final p2 = positions().last as Map;
    expect(p2['lat'], isNull);
    expect(p2['recordedAtMs'], nowMs);

    rec = const RecordingUiState(state: RecordingState.autoPaused);
    await tick();
    expect((positions().last as Map)['moving'], isFalse);
    expect((positions().last as Map)['paused'], isFalse);
    rec = const RecordingUiState(state: RecordingState.manuallyPaused);
    await tick();
    expect((positions().last as Map)['paused'], isTrue);
  });

  test('sem rede guarda so a ultima posicao e reenvia no proximo tick', () async {
    await begin();
    server.offline = true;
    sample = fix(-23.1, nowMs);
    await tick();
    expect(ctrl.state.offline, isTrue);
    sample = fix(-23.2, nowMs + 1);
    await tick();
    final sent = positions().length;
    server.offline = false;
    await tick();
    expect(ctrl.state.offline, isFalse);
    expect(positions().length, sent + 1);
    expect((positions().last as Map)['lat'], -23.2);
    // Ja saiu: o proximo e batimento.
    await tick();
    expect((positions().last as Map)['lat'], isNull);
  });

  test('checagem na resposta: voz critica e vibracao uma vez; Estou bem zera', () async {
    await begin();
    final id = ctrl.sessionId!;
    server.startCheck(id, reason: 'stopped', deadlineMs: nowMs + 2 * min);
    await tick();
    expect(ctrl.state.check, isNotNull);
    expect(ctrl.state.check!.reason, CheckReason.stopped);
    expect(ctrl.state.check!.deadlineMs, nowMs + 2 * min);
    await Future<void>.delayed(Duration.zero);
    expect(voice.spoken, [kSafetyCheckPhrase]);
    expect(haptics.alerts, 1);
    await tick();
    expect(voice.spoken, hasLength(1));
    expect(haptics.alerts, 1);

    expect(await ctrl.ok(), isTrue);
    expect(ctrl.state.check, isNull);
    expect(server.requestsTo('POST', '/$id/ok'), hasLength(1));
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
    expect(server.notifications.where((n) => n['type'] == 'safety_all_clear'), hasLength(1));
  });

  test('Estender sem rede: mensagem e a sessao segue', () async {
    await begin();
    server.offline = true;
    expect(await ctrl.extend(30), isFalse);
    expect(ctrl.state.message, contains('Sem rede'));
    expect(ctrl.state.active, isTrue);
  });

  test('SOS manda a posicao atual e o alerta aos contatos sem encerrar', () async {
    await begin();
    sample = fix(-23.7, nowMs);
    await tick();
    expect(await ctrl.sos(), isTrue);
    // Mesmo ja enviada, a posicao vai junto do SOS.
    expect((positions().last as Map)['lat'], -23.7);
    expect(server.notifications.where((n) => n['type'] == 'safety_sos'), hasLength(1));
    expect(ctrl.state.active, isTrue);
    expect(ctrl.state.message, contains('enviada'));
  });

  test('fim da gravacao chama arrived e para o tick; sem rede tenta de novo', () async {
    await begin();
    final id = ctrl.sessionId!;
    server.offline = true;
    ctrl.onRecording(const RecordingUiState(state: RecordingState.finished));
    await ctrl.idle();
    expect(ctrl.state.active, isFalse);
    expect(server.sessionById(id)!['status'], isNot('ended'));
    server.offline = false;
    await tick();
    expect(server.sessionById(id)!['status'], 'ended');
    final before = server.requests.length;
    await tick();
    expect(server.requests.length, before, reason: 'tick parou depois do arrived');
    expect(ticker.hasListener, isFalse);
  });

  test('Cheguei pela faixa encerra so o Rastro Seguro', () async {
    await begin();
    final id = ctrl.sessionId!;
    await ctrl.arrive();
    expect(server.sessionById(id)!['status'], 'ended');
    expect(ctrl.state.active, isFalse);
    ctrl.onRecording(const RecordingUiState(state: RecordingState.finished));
    await ctrl.idle();
    expect(server.requestsTo('POST', '/arrived'), hasLength(1));
  });

  test('409 de sessao presa: encerra a antiga e cria de novo', () async {
    final old = await SafetyApi(
      Dio()..httpClientAdapter = server,
      'http://srv',
      token: () async => 'tok',
    ).createSession(activityGuid: 'act_0', etaMs: nowMs + 60 * min, contactIds: [contactId]);
    await begin();
    expect(server.sessionById(old.id)!['status'], 'ended');
    expect(ctrl.state.session!.activityGuid, 'act_1');
  });

  test('sessao encerrada no backend (409): a faixa sai e o tick para', () async {
    await begin();
    server.sessionById(ctrl.sessionId!)!['status'] = 'ended';
    await tick();
    expect(ctrl.state.active, isFalse);
    expect(ticker.hasListener, isFalse);
  });

  group('recuperacao apos crash', () {
    late String id;
    setUp(() async {
      final s = await SafetyApi(
        Dio()..httpClientAdapter = server,
        'http://srv',
        token: () async => 'tok',
      ).createSession(activityGuid: 'act_1', etaMs: nowMs + 60 * min, contactIds: [contactId]);
      id = s.id;
    });

    test('sessao da gravacao retomada religa a faixa e o tick', () async {
      await ctrl.reconcile();
      expect(ctrl.state.active, isTrue);
      expect(ctrl.sessionId, id);
      await tick();
      expect(positions(), hasLength(1));
    });

    test('atividade esperando a decisao de retomar: fica como esta', () async {
      rec = const RecordingUiState();
      recGuid = null;
      await ctrl.reconcile(interrupted: (g) async => g == 'act_1');
      expect(server.sessionById(id)!['status'], 'active');
      expect(ctrl.state.active, isFalse);
      // Salvou ou descartou no dialogo: encerra.
      await ctrl.endFor('act_1');
      expect(server.sessionById(id)!['status'], 'ended');
    });

    test('sessao de atividade que ja terminou: encerra', () async {
      rec = const RecordingUiState();
      recGuid = null;
      await ctrl.reconcile(interrupted: (_) async => false);
      expect(server.sessionById(id)!['status'], 'ended');
    });
  });
}
