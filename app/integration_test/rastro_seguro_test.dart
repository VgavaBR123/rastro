// Teste de ponta a ponta NO APARELHO do Rastro Seguro (F08), contra o BACKEND
// DE VERDADE com tempos curtos. Num aparelho so cabe uma conta por vez na tela,
// entao o "outro lado" e feito por chamadas HTTP diretas ao backend.
//
// 1) A dona pela tela: convida o contato, grava com o Rastro Seguro, para de
//    andar, recebe "Esta tudo bem?" e nao responde. O contato (HTTP) recebe o
//    alerta com o link publico, que mostra "nao respondeu" e a ultima posicao.
//    A dona toca Estou bem (o contato recebe "esta bem") e encerra a gravacao
//    (o link passa a "chegou").
// 2) O contato pela tela: outra conta (HTTP) manda SOS; o alerta aparece por
//    cima da tela, com Ver localizacao abrindo o link do backend, e fica na
//    caixa de entrada.
//
// Backend (pasta backend):
//   docker compose up -d
//   PORT=8081 DB_PORT=5433 SAFETY_TICK_MS=1000 SAFETY_SILENCE_MS=20000 \
//     SAFETY_STOP_MS=30000 SAFETY_CHECK_MS=15000 SAFETY_ETA_MIN_MS=60000 \
//     PUBLIC_BASE_URL=http://localhost:8081 dart run bin/server.dart
//   adb reverse tcp:8081 tcp:8081
// Execucao:
//   flutter test integration_test/rastro_seguro_test.dart -d <device> \
//     --dart-define=SYNC_BASE_URL=http://localhost:8081
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/main.dart' show StravaEstudoApp;
import 'package:strava_estudo_app/auth/auth_models.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/recording/source/current_position.dart';
import 'package:strava_estudo_app/safety/safety_alerts.dart';
import 'package:strava_estudo_app/safety/safety_providers.dart';
import 'package:strava_estudo_app/safety/safety_session_controller.dart';
import 'package:strava_estudo_app/safety/url_opener.dart';

import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';

/// Rota sintetica com o horario de AGORA: o backend trata como so sinal de
/// vida uma posicao gravada mais de 1 h antes do inicio da sessao.
class _RotaAgora implements LocationSource {
  final _c = StreamController<LocationSample>.broadcast();
  final int _t0 = DateTime.now().millisecondsSinceEpoch;
  final Stopwatch _mono = Stopwatch()..start();

  @override
  Future<bool> ensurePermission() async => true;
  @override
  Stream<LocationSample> positions() => _c.stream;
  @override
  Future<void> stop() async {
    if (!_c.isClosed) await _c.close();
  }

  void emitir(int i) => _c.add(LocationSample(
        position: GeoPoint(
          latitude: -19.9245 + i * 0.00009,
          longitude: -43.9352 + i * 0.00009,
          altitudeMeters: 850,
        ),
        wallClockMs: _t0 + _mono.elapsedMilliseconds,
        monotonicMs: _mono.elapsedMilliseconds,
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 3,
      ));
}

class _PosicaoFixa implements CurrentPositionSource {
  static const _p = GeoPoint(latitude: -19.9245, longitude: -43.9352);
  @override
  Future<bool> hasAccess({bool request = false}) async => true;
  @override
  Future<GeoPoint?> lastKnown() async => _p;
  @override
  Future<GeoPoint?> current() async => _p;
}

class _Abridor implements UrlOpener {
  final List<String> abertos = [];
  @override
  Future<UrlOpenResult> open(String url) async {
    abertos.add(url);
    return const UrlOpenResult.opened();
  }
}

class _SemVibrar implements SafetyHaptics {
  int vezes = 0;
  @override
  Future<void> alert() async => vezes++;
}

/// Cliente HTTP minimo do "outro lado".
class _Api {
  final HttpClient _http = HttpClient();
  final String base = kSyncBaseUrl;

  Future<(int, dynamic)> chamar(String metodo, String caminho, {String? token, Object? corpo}) async {
    final req = await _http.openUrl(metodo, Uri.parse('$base$caminho'));
    if (token != null) req.headers.set('authorization', 'Bearer $token');
    if (corpo != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(corpo));
    }
    final resp = await req.close();
    final texto = await resp.transform(utf8.decoder).join();
    Object? json;
    try {
      json = texto.isEmpty ? null : jsonDecode(texto);
    } on FormatException {
      json = texto;
    }
    return (resp.statusCode, json);
  }

  Future<Map<String, dynamic>> conta(String rotulo) async {
    final email = '$rotulo-${DateTime.now().microsecondsSinceEpoch}@teste.dev';
    final (st, j) = await chamar('POST', '/auth/register',
        corpo: {'email': email, 'password': 'senha-e2e-123', 'displayName': rotulo});
    expect(st, 201, reason: 'cadastro de $rotulo: $j (limite de cadastros por IP? reinicie o backend)');
    return j as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> notificacoes(String token) async {
    final (st, j) = await chamar('GET', '/notifications?since=0', token: token);
    expect(st, 200);
    return [for (final n in (j as Map)['notifications'] as List) n as Map<String, dynamic>];
  }

  void fechar() => _http.close(force: true);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<RecordingDatabase> bancoLimpo() async {
    final db = RecordingDatabase();
    await db.delete(db.waypoints).go();
    await db.delete(db.laps).go();
    await db.delete(db.activities).go();
    await db.delete(db.safetyLocalSessions).go();
    await db.delete(db.safetyMeta).go();
    await db.saveSettings(reliabilityChecklistSeen: true);
    return db;
  }

  Future<void> esperar(WidgetTester tester, bool Function() pronto, {int segundos = 60}) async {
    for (var i = 0; i < segundos * 4 && !pronto(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump();
    }
  }

  bool tem(Key k) => find.byKey(k).evaluate().isNotEmpty;

  String textoDe(Key k) => find
      .descendant(of: find.byKey(k), matching: find.byType(Text), matchRoot: true)
      .evaluate()
      .map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '')
      .join(' ');

  Future<void> tocar(WidgetTester tester, Key k) async {
    await esperar(tester, () => tem(k), segundos: 15);
    await tester.ensureVisible(find.byKey(k));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(k));
    await tester.pumpAndSettle();
  }

  Future<void> segurar(WidgetTester tester, Key k) async {
    final g = await tester.startGesture(tester.getCenter(find.byKey(k)));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pumpAndSettle();
  }

  testWidgets('dona: parada sem resposta alerta o contato, link publico, Estou bem e chegada', (
    tester,
  ) async {
    final api = _Api();
    addTearDown(api.fechar);
    final dona = await api.conta('Ana');
    final contato = await api.conta('Bia');
    final tokenBia = contato['token'] as String;
    final emailBia = (contato['user'] as Map)['email'] as String;

    final db = await bancoLimpo();
    addTearDown(db.close);
    final source = _RotaAgora();
    final abridor = _Abridor();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore(AuthSession.fromJson(dona))),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
          currentPositionSourceProvider.overrideWithValue(_PosicaoFixa()),
          safetyPositionIntervalProvider.overrideWithValue(const Duration(seconds: 3)),
          inboxIntervalProvider.overrideWithValue(const Duration(seconds: 3)),
          safetyHapticsProvider.overrideWithValue(_SemVibrar()),
          safetyLocalNotifierProvider.overrideWithValue(const NoopSafetyLocalNotifier()),
          urlOpenerProvider.overrideWithValue(abridor),
        ],
        child: const StravaEstudoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 0) Configuracoes > Rastro Seguro: convida a Bia; ela aceita (HTTP).
    await tocar(tester, const Key('nav_profile'));
    await tocar(tester, const Key('profile_settings'));
    await tester.scrollUntilVisible(find.byKey(const Key('safety_settings')), 200,
        scrollable: find.byType(Scrollable).first);
    await tocar(tester, const Key('safety_settings'));
    expect(find.byKey(const Key('safety_push_notice')), findsOneWidget,
        reason: 'aviso honesto de que sem push o contato so e avisado com o app aberto');
    await tester.enterText(find.byKey(const Key('safety_invite_email')), emailBia);
    await tocar(tester, const Key('safety_invite_send'));
    var (st, recebidos) = await api.chamar('GET', '/safety/contacts', token: tokenBia);
    final convite = ((recebidos as Map)['incoming'] as List).single as Map;
    (st, _) = await api.chamar('POST', '/safety/contacts/${convite['id']}/accept', token: tokenBia);
    expect(st, 200);
    expect((await api.notificacoes(tokenBia)).any((n) => n['type'] == 'contact_invite'), isTrue);

    // 1) Gravar com o Rastro Seguro: Bia e chegada em 30 min.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tocar(tester, const Key('nav_record'));
    await tocar(tester, const Key('safety_entry'));
    final escolha = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('safety_pick_'));
    await esperar(tester, () => escolha.evaluate().isNotEmpty, segundos: 15);
    expect(escolha, findsOneWidget, reason: 'so o contato aceito aparece');
    await tester.tap(escolha);
    await tester.pumpAndSettle();
    await tocar(tester, const Key('safety_eta_30'));
    await tocar(tester, const Key('safety_plan_confirm'));
    await tocar(tester, const Key('sport_run'));
    await tocar(tester, const Key('record_start'));
    await esperar(tester, () => tem(const Key('safety_banner')), segundos: 20);
    debugPrint('[e2e-f08] faixa: ${textoDe(const Key('safety_banner_text'))}');
    expect(textoDe(const Key('safety_banner_text')), contains('chegada prevista'));

    // Anda 10 s (sinal de vida com posicao) e depois para: nenhuma amostra nova.
    for (var i = 0; i < 10; i++) {
      source.emitir(i);
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await tester.pump();
    }
    var (_, ativa) = await api.chamar('GET', '/safety/sessions/active', token: dona['token'] as String);
    final sessao = ativa as Map;
    debugPrint('[e2e-f08] sessao ${sessao['id']} status ${sessao['status']} '
        'ultima posicao ${sessao['lastPosition']}');
    expect(sessao['lastPosition'], isNotNull, reason: 'o app mandou a posicao');

    // 2) Parada: o backend pergunta "esta tudo bem?" (regra de 30 s parada).
    final inicio = DateTime.now();
    await esperar(tester, () => tem(const Key('safety_check')), segundos: 90);
    final ateChecagem = DateTime.now().difference(inicio).inSeconds;
    debugPrint('[e2e-f08] checagem em ${ateChecagem}s: ${textoDe(const Key('safety_check'))}');
    expect(find.byKey(const Key('safety_check')), findsOneWidget);
    expect(find.byKey(const Key('safety_check_ok')), findsOneWidget);
    expect(find.byKey(const Key('safety_check_help')), findsOneWidget, reason: 'Preciso de ajuda no aviso');
    expect(textoDe(const Key('safety_check_countdown')), matches(RegExp(r'^\d:\d\d$')));

    // 3) Sem resposta: alerta para a Bia.
    await esperar(tester, () => textoDe(const Key('safety_banner_text')).contains('avisados'),
        segundos: 60);
    debugPrint('[e2e-f08] faixa depois do prazo: ${textoDe(const Key('safety_banner_text'))}');
    expect(textoDe(const Key('safety_banner_text')), contains('avisados'));
    final alerta = (await api.notificacoes(tokenBia)).firstWhere((n) => n['type'] == 'safety_alert');
    final data = alerta['data'] as Map;
    debugPrint('[e2e-f08] alerta para a Bia: ${alerta['title']} / ${alerta['body']} / $data');
    final shareUrl = data['shareUrl'] as String;

    // Link publico: sem conta, mostra "nao respondeu" e a posicao, sem email.
    var (stLink, jsonLink) = await api.chamar('GET', '${Uri.parse(shareUrl).path}.json');
    debugPrint('[e2e-f08] link .json: $stLink $jsonLink');
    expect(stLink, 200);
    expect((jsonLink as Map)['state'], 'no_response');
    final (stHtml, html) = await api.chamar('GET', Uri.parse(shareUrl).path);
    expect(stHtml, 200);
    expect(html as String, contains('Ana'));
    expect(html, isNot(contains((dona['user'] as Map)['email'] as String)));
    expect(html, isNot(contains(emailBia)));

    // 4) A dona responde depois do alerta: a Bia recebe "esta bem".
    await tocar(tester, const Key('safety_banner_ok'));
    await esperar(tester, () => false, segundos: 3);
    final depois = await api.notificacoes(tokenBia);
    debugPrint('[e2e-f08] Bia recebeu: ${[for (final n in depois) n['type']]}');
    expect(depois.any((n) => n['type'] == 'safety_all_clear'), isTrue);

    // 5) Encerra a gravacao: arrived; o link passa a "chegou".
    await tester.tap(find.byKey(const Key('pause')));
    await tester.pumpAndSettle();
    await segurar(tester, const Key('stop'));
    await tocar(tester, const Key('save_activity'));
    await esperar(tester, () => tem(const Key('closing_done')), segundos: 15);
    await tocar(tester, const Key('closing_done'));
    await esperar(tester, () => false, segundos: 4);
    (stLink, jsonLink) = await api.chamar('GET', '${Uri.parse(shareUrl).path}.json');
    debugPrint('[e2e-f08] link depois de encerrar: $stLink $jsonLink');
    expect((jsonLink as Map)['state'], 'arrived');
    final (stAtiva, _) = await api.chamar('GET', '/safety/sessions/active', token: dona['token'] as String);
    expect(stAtiva, 404, reason: 'nenhuma sessao ativa depois de encerrar');
  });

  testWidgets('contato: SOS de outra conta aparece por cima da tela e na caixa de entrada', (
    tester,
  ) async {
    final api = _Api();
    addTearDown(api.fechar);
    final contato = await api.conta('Bia');
    final dona = await api.conta('Cris');
    final tokenCris = dona['token'] as String;
    final tokenBia = contato['token'] as String;

    // Cris convida a Bia, que aceita; Cris comeca uma sessao e manda posicao.
    var (st, ct) = await api.chamar('POST', '/safety/contacts',
        token: tokenCris, corpo: {'email': (contato['user'] as Map)['email']});
    expect(st, 201);
    (st, _) = await api.chamar('POST', '/safety/contacts/${(ct as Map)['id']}/accept', token: tokenBia);
    expect(st, 200);
    final eta = DateTime.now().add(const Duration(minutes: 40)).millisecondsSinceEpoch;
    var (stS, s) = await api.chamar('POST', '/safety/sessions', token: tokenCris, corpo: {
      'activityGuid': 'act_e2e_${DateTime.now().millisecondsSinceEpoch}',
      'etaMs': eta,
      'contactIds': [ct['id']],
    });
    expect(stS, 201, reason: '$s');
    final sid = (s as Map)['id'];
    await api.chamar('POST', '/safety/sessions/$sid/positions', token: tokenCris, corpo: {
      'lat': -19.93, 'lon': -43.94, 'accuracyM': 6,
      'recordedAtMs': DateTime.now().millisecondsSinceEpoch, 'moving': true, 'paused': false,
    });

    final db = await bancoLimpo();
    addTearDown(db.close);
    final abridor = _Abridor();
    final vibra = _SemVibrar();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore(AuthSession.fromJson(contato))),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
          currentPositionSourceProvider.overrideWithValue(_PosicaoFixa()),
          inboxIntervalProvider.overrideWithValue(const Duration(seconds: 2)),
          safetyHapticsProvider.overrideWithValue(vibra),
          safetyLocalNotifierProvider.overrideWithValue(const NoopSafetyLocalNotifier()),
          urlOpenerProvider.overrideWithValue(abridor),
        ],
        child: const StravaEstudoApp(),
      ),
    );
    await tester.pumpAndSettle();
    // A Bia esta numa tela qualquer (Estatisticas), nao no Inicio.
    await tocar(tester, const Key('nav_stats'));
    await esperar(tester, () => false, segundos: 4); // o convite ja lido nao abre painel

    // SOS da Cris.
    (st, _) = await api.chamar('POST', '/safety/sessions/$sid/sos', token: tokenCris);
    expect(st, 200);
    await esperar(tester, () => tem(const Key('safety_alert_panel')), segundos: 20);
    debugPrint('[e2e-f08] painel: ${textoDe(const Key('safety_alert_panel'))}');
    expect(find.byKey(const Key('safety_alert_panel')), findsOneWidget,
        reason: 'alerta por cima da tela de Estatisticas');
    expect(textoDe(const Key('safety_alert_title')), contains('Cris'));
    expect(vibra.vezes, greaterThan(0), reason: 'vibra no alerta');
    await tocar(tester, const Key('safety_alert_location'));
    debugPrint('[e2e-f08] abriu: ${abridor.abertos}');
    expect(abridor.abertos.single, startsWith('$kSyncBaseUrl/s/'));
    // Ver localizacao abre o link e tira o alerta da fila (a pessoa vai para o
    // mapa); se houvesse outro alerta na fila, ele apareceria em seguida.
    if (tem(const Key('safety_alert_panel'))) {
      await tocar(tester, const Key('safety_alert_close'));
    }
    expect(find.byKey(const Key('safety_alert_panel')), findsNothing);

    // Caixa de entrada: o SOS esta la.
    await tocar(tester, const Key('nav_home'));
    await tocar(tester, const Key('inbox_bell'));
    final itens = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('notification_location_'));
    await esperar(tester, () => itens.evaluate().isNotEmpty, segundos: 10);
    expect(itens, findsWidgets);

    // Limpa a sessao da Cris.
    await api.chamar('POST', '/safety/sessions/$sid/arrived', token: tokenCris);
  });
}
