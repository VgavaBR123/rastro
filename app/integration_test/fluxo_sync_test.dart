// Teste de ponta a ponta NO APARELHO: cria uma conta, grava uma atividade,
// encerra, abre o historico, sincroniza contra o BACKEND DE VERDADE e confere
// o total no perfil.
//
// O que este teste cobre e exatamente o que os testes de unidade nao cobrem:
// o caminho HTTP real (octet-stream + header x-activity-guid) ate o servidor
// e a persistencia no Postgres/PostGIS.
//
// Pre-requisitos (ver backend/README.md):
//   docker compose up -d
//   PORT=8081 DB_PORT=5433 dart run bin/server.dart
//   adb reverse tcp:8081 tcp:8081
//
// Execucao:
//   flutter test integration_test/fluxo_sync_test.dart -d <device> \
//     --dart-define=SYNC_BASE_URL=http://localhost:8081
//
// A fonte de localizacao e substituida por uma rota sintetica deterministica:
// o objetivo aqui e o fluxo completo, nao o GPS do emulador (esse e verificado
// a mao com `adb emu geo fix`). O guid da atividade sai no console para o
// conferidor do banco saber o que procurar.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';
import 'package:strava_estudo_app/ui/home_screen.dart';

/// Rota sintetica: pontos a ~10 m de distancia, 1 por segundo, emitidos sob
/// demanda pelo teste (nada de timer: o teste controla o ritmo).
class RotaFakeSource implements LocationSource {
  RotaFakeSource({this.pontos = 30});

  final int pontos;
  final StreamController<LocationSample> _c =
      StreamController<LocationSample>.broadcast();

  static const double _lat0 = -19.9245;
  static const double _lon0 = -43.9352;
  static const int _inicioMs = 1760000000000;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Stream<LocationSample> positions() => _c.stream;

  @override
  Future<void> stop() async {
    if (!_c.isClosed) await _c.close();
  }

  /// Emite o i-esimo ponto da rota.
  void emitir(int i) {
    _c.add(
      LocationSample(
        position: GeoPoint(
          latitude: _lat0 + i * 0.00009,
          longitude: _lon0 + i * 0.00009,
          altitudeMeters: 850 + (i % 5).toDouble(),
        ),
        wallClockMs: _inicioMs + i * 1000,
        monotonicMs: i * 1000,
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 3,
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gravar, encerrar e sincronizar contra o backend real', (
    tester,
  ) async {
    final source = RotaFakeSource();
    final db = RecordingDatabase();
    addTearDown(db.close);

    // Banco limpo: o teste roda no aparelho e o arquivo sobrevive entre runs.
    await db.delete(db.waypoints).go();
    await db.delete(db.activities).go();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          // Sessao so em memoria: o teste nao deixa conta logada no aparelho.
          sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 0) Cria uma conta nova (e-mail unico por execucao) pela UI.
    final email = 'e2e${DateTime.now().millisecondsSinceEpoch}@teste.dev';
    debugPrint('[e2e] conta: $email');
    await tester.tap(find.byKey(const Key('account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth_toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth_name')), 'Corredor E2E');
    await tester.enterText(find.byKey(const Key('auth_email')), email);
    await tester.enterText(
      find.byKey(const Key('auth_password')),
      'senha-e2e-123',
    );
    await tester.tap(find.byKey(const Key('auth_submit')));
    for (
      int i = 0;
      i < 40 && find.byKey(const Key('auth_submit')).evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    expect(
      find.byIcon(Icons.account_circle),
      findsOneWidget,
      reason: 'o cadastro precisa ter funcionado no backend',
    );

    // 1) Inicia uma corrida.
    expect(find.text('Correr'), findsOneWidget);
    await tester.tap(find.text('Correr'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    // 2) Alimenta a rota.
    for (int i = 0; i < source.pontos; i++) {
      source.emitir(i);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 200));

    // A distancia tem que ter saido do zero.
    // _Metric mostra dois Texts: rotulo e valor (nessa ordem).
    final textos = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('distance')),
            matching: find.byType(Text),
          ),
        )
        .toList();
    final String? distancia = textos.last.data;
    debugPrint('[e2e] distancia na tela: $distancia');
    expect(distancia, isNot('0 m'));

    // 3) Encerra a atividade.
    await tester.tap(find.byKey(const Key('stop')));
    await tester.pumpAndSettle();

    final atividades = await db.recentActivities();
    expect(atividades, isNotEmpty);
    final atividade = atividades.first;
    debugPrint('[e2e] guid da atividade: ${atividade.guid}');
    expect(atividade.distanceMeters, greaterThan(0));
    expect(atividade.syncState, SyncState.pending);

    // 4) Historico -> sincronizar.
    await tester.tap(find.byKey(const Key('history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sync')));

    // O upload e uma chamada HTTP real; da tempo dela terminar.
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      final estado = (await db.recentActivities()).first.syncState;
      if (estado != SyncState.pending && estado != SyncState.uploading) break;
    }

    // 5) O backend aceitou: estado final sincronizado.
    final finalizada = (await db.recentActivities()).first;
    debugPrint('[e2e] estado de sync: ${finalizada.syncState}');
    expect(
      finalizada.syncState,
      SyncState.synced,
      reason:
          'o backend precisa estar no ar em SYNC_BASE_URL '
          '(veja backend/README.md e use adb reverse tcp:8081 tcp:8081)',
    );

    // 6) O perfil (vindo do servidor) conta a atividade da conta nova.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account')));
    for (
      int i = 0;
      i < 40 && find.byKey(const Key('profile_count')).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    final total = tester
        .widget<Text>(find.byKey(const Key('profile_count')))
        .data;
    debugPrint('[e2e] atividades no perfil: $total');
    expect(total, '1');
    expect(finalizada.remoteId, isNotNull, reason: 'id do servidor guardado');

    // 7) Excluir no historico apaga no servidor tambem: o perfil volta a 0.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('menu-${finalizada.guid}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('delete-${finalizada.guid}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('apagada do servidor'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sync')));
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if ((await db.pendingRemoteDeletions()).isEmpty) break;
    }
    expect(await db.pendingRemoteDeletions(), isEmpty,
        reason: 'a exclusao precisa ter chegado ao servidor');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account')));
    String? depois;
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      final f = find.byKey(const Key('profile_count'));
      if (f.evaluate().isNotEmpty) {
        depois = tester.widget<Text>(f).data;
        if (depois == '0') break;
      }
    }
    debugPrint('[e2e] atividades no perfil apos excluir: $depois');
    expect(depois, '0');
  });
}
