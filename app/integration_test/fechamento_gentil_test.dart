// Teste de ponta a ponta NO APARELHO do Fechamento gentil (F04).
//
// 1) Conta nova, corrida, tela Salvar com esforco (RPE) e humor, fechamento
//    com as frases e o esforco, sync contra o BACKEND DE VERDADE e conferencia
//    de que `rpe` e `mood` chegaram ao servidor (GET /activities/<id>).
// 2) Modo Gentil ligado: nada de pace na gravacao, no Salvar, no fechamento
//    nem no Perfil.
//
// Pre-requisitos e execucao: os mesmos de fluxo_sync_test.dart
//   docker compose up -d
//   PORT=8081 DB_PORT=5433 dart run bin/server.dart
//   adb reverse tcp:8081 tcp:8081
//   flutter test integration_test/fechamento_gentil_test.dart -d <device> \
//     --dart-define=SYNC_BASE_URL=http://localhost:8081
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';

import 'fluxo_sync_test.dart' show RotaFakeSource;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<RecordingDatabase> abrir(
    WidgetTester tester,
    RotaFakeSource source, {
    required SessionStore sessao,
    bool gentil = false,
  }) async {
    final db = RecordingDatabase();
    addTearDown(db.close);
    // Banco limpo: o arquivo sobrevive entre runs no aparelho.
    await db.delete(db.waypoints).go();
    await db.delete(db.activities).go();
    await db.saveSettings(reliabilityChecklistSeen: true, gentleMode: gentil);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(sessao),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
        ],
        child: MaterialApp.router(routerConfig: buildAppRouter()),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  Future<void> esperar(WidgetTester tester, bool Function() pronto) async {
    for (var i = 0; i < 60 && !pronto(); i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> gravarCorrida(WidgetTester tester, RotaFakeSource source) async {
    await tester.tap(find.byKey(const Key('nav_record')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sport_run')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record_start')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < source.pontos; i++) {
      source.emitir(i);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> abrirSalvar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('pause')));
    await tester.pumpAndSettle();
    final gesto = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('stop'))),
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesto.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save_activity_view')), findsOneWidget);
  }

  Future<void> tocar(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  void semRitmo(String onde) {
    final textos = find.byType(Text).evaluate().map((e) {
      final t = e.widget as Text;
      return (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase();
    });
    for (final t in textos) {
      for (final w in ['/km', 'pace', 'rapid', 'rápid', 'ritmo', 'km/h']) {
        expect(t, isNot(contains(w)), reason: '$onde mostra "$t"');
      }
    }
  }

  testWidgets('esforco e humor: fechamento e chegada ao servidor', (tester) async {
    final source = RotaFakeSource();
    final sessao = InMemorySessionStore();
    final db = await abrir(tester, source, sessao: sessao);

    final email = 'f04-${DateTime.now().millisecondsSinceEpoch}@teste.dev';
    debugPrint('[e2e-f04] conta: $email');
    await tester.tap(find.byKey(const Key('nav_profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_signin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth_toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth_name')), 'Fechamento E2E');
    await tester.enterText(find.byKey(const Key('auth_email')), email);
    await tester.enterText(find.byKey(const Key('auth_password')), 'senha-e2e-123');
    await tester.tap(find.byKey(const Key('auth_submit')));
    await esperar(tester, () => find.byKey(const Key('auth_submit')).evaluate().isEmpty);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_name')), findsOneWidget);

    await gravarCorrida(tester, source);
    // Fora do Modo Gentil o pace aparece ao vivo.
    expect(find.byKey(const Key('pace')), findsOneWidget);
    await abrirSalvar(tester);
    expect(find.byKey(const Key('save_pace')), findsOneWidget);
    await tocar(tester, const Key('rpe_7'));
    await tocar(tester, const Key('mood_tired'));
    await tocar(tester, const Key('save_activity'));
    await esperar(tester, () => find.byKey(const Key('closing_view')).evaluate().isNotEmpty);
    await tester.pumpAndSettle();

    // Fechamento: 2 ou 3 frases e o esforco escolhido.
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    expect(find.byKey(const Key('closing_phrase_0')), findsOneWidget);
    expect(find.byKey(const Key('closing_phrase_1')), findsOneWidget);
    expect(find.byKey(const Key('closing_effort')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      final f = find.byKey(Key('closing_phrase_$i'));
      if (f.evaluate().isEmpty) break;
      final t = tester.widget<Text>(find.descendant(of: f, matching: find.byType(Text)).first);
      debugPrint('[e2e-f04] frase $i: ${t.data ?? t.textSpan?.toPlainText()}');
    }
    final local = (await db.recentActivities()).first;
    expect(local.rpe, 7);
    expect(local.mood, 'tired');
    await tocar(tester, const Key('closing_done'));

    // Sync contra o backend real.
    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sync')));
    Activity? enviada;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      enviada = (await db.recentActivities()).first;
      if (enviada.syncState == SyncState.synced) break;
    }
    expect(enviada!.syncState, SyncState.synced, reason: 'backend no ar em $kSyncBaseUrl?');
    debugPrint('[e2e-f04] guid ${enviada.guid} remoteId ${enviada.remoteId}');

    // O servidor guardou o esforco e o humor.
    final token = (await sessao.read())!.token;
    final http = HttpClient();
    addTearDown(http.close);
    final req = await http.getUrl(Uri.parse('$kSyncBaseUrl/activities/${enviada.remoteId}'));
    req.headers.set('authorization', 'Bearer $token');
    final resp = await req.close();
    final corpo = jsonDecode(await resp.transform(utf8.decoder).join()) as Map<String, dynamic>;
    debugPrint('[e2e-f04] servidor: rpe=${corpo['rpe']} mood=${corpo['mood']}');
    expect(resp.statusCode, 200);
    expect(corpo['rpe'], 7);
    expect(corpo['mood'], 'tired');
  });

  testWidgets('Modo Gentil: sem pace na gravacao, no Salvar, no fechamento e no Perfil', (
    tester,
  ) async {
    final source = RotaFakeSource();
    final db = await abrir(tester, source, sessao: InMemorySessionStore(), gentil: true);

    await gravarCorrida(tester, source);
    expect(find.byKey(const Key('pace')), findsNothing);
    expect(find.byKey(const Key('duration')), findsOneWidget);
    expect(find.byKey(const Key('distance')), findsOneWidget);
    semRitmo('gravacao');

    await abrirSalvar(tester);
    expect(find.byKey(const Key('save_pace')), findsNothing);
    await tocar(tester, const Key('rpe_3'));
    await tocar(tester, const Key('save_activity'));
    await esperar(tester, () => find.byKey(const Key('closing_view')).evaluate().isNotEmpty);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    semRitmo('fechamento');
    expect((await db.recentActivities()).first.rpe, 3);
    await tocar(tester, const Key('closing_done'));

    await tester.tap(find.byKey(const Key('nav_profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_record_run_bestPace')), findsNothing);
    semRitmo('perfil');
  });
}
