// Teste de ponta a ponta NO APARELHO do Plano Do Zero aos 5 km (F06).
//
// Tabela curta (17 s por sessao) e o relogio e o tick REAIS do aparelho: o
// que se prova aqui e que o plano anda sozinho pelo tick de 1 s, fecha as
// voltas, salva concluida/parcial e aplica a regra "pesada demais repete a
// semana". Sem backend (o plano e so local).
//
// Segundo plano: no meio de uma sessao o teste imprime
// `[e2e-f06] SEGUNDO_PLANO`; um script no PC (ver app/testes) manda o app para
// a tela inicial com `adb shell input keyevent 3` e o traz de volta 8 s depois.
// Sem o script o teste passa do mesmo jeito (so nao exercita esse trecho).
//
// Execucao:
//   flutter test integration_test/plano_5k_test.dart -d <device>
library;

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_table.dart';
import 'package:strava_estudo_app/plan5k/plan_providers.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/recording/source/current_position.dart';

import 'fluxo_sync_test.dart' show RotaFakeSource;

/// Posicao da tela Gravar sem o GPS do aparelho: o geolocator de verdade
/// pediria a permissao num dialogo do sistema, que fica por cima do app ao
/// voltar do segundo plano e congela os quadros do teste.
class _PosicaoFixa implements CurrentPositionSource {
  static const _p = GeoPoint(latitude: -19.9245, longitude: -43.9352);
  @override
  Future<bool> hasAccess({bool request = false}) async => true;
  @override
  Future<GeoPoint?> lastKnown() async => _p;
  @override
  Future<GeoPoint?> current() async => _p;
}

/// 30 sessoes de 17 s: aquecimento 3, corre 4, caminha 3, corre 4, desaquece 3.
final List<PlanSession> _tabelaCurta = [
  for (var i = 0; i < 30; i++)
    PlanSession(
      week: i ~/ 3 + 1,
      number: i % 3 + 1,
      blocks: const [
        PlanBlock(BlockKind.warmup, 3000),
        PlanBlock(BlockKind.run, 4000),
        PlanBlock(BlockKind.walk, 3000),
        PlanBlock(BlockKind.run, 4000),
        PlanBlock(BlockKind.cooldown, 3000),
      ],
    ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plano 5 km: parcial, concluidas, voltas e repetir a semana', (tester) async {
    final source = RotaFakeSource(pontos: 100000);
    final db = RecordingDatabase();
    addTearDown(db.close);
    await db.delete(db.plan5kSessions).go();
    await db.delete(db.plan5kStates).go();
    await db.delete(db.laps).go();
    await db.delete(db.waypoints).go();
    await db.delete(db.activities).go();
    await db.delete(db.settingsRows).go();
    await db.saveSettings(reliabilityChecklistSeen: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
          plan5kTableProvider.overrideWithValue(_tabelaCurta),
          currentPositionSourceProvider.overrideWithValue(_PosicaoFixa()),
        ],
        child: MaterialApp.router(routerConfig: buildAppRouter()),
      ),
    );
    await tester.pumpAndSettle();

    var ponto = 0;

    /// Espera [segundos] de relogio real com GPS chegando (sem GPS a
    /// auto-pausa congelaria o plano) e devolve os blocos vistos na tela.
    Future<List<String>> correr(int segundos, {int? segundoPlanoEm}) async {
      final vistos = <String>[];
      for (var s = 0; s < segundos; s++) {
        if (s == segundoPlanoEm) debugPrint('[e2e-f06] SEGUNDO_PLANO');
        source.emitir(ponto++);
        await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
        await tester.pump();
        final f = find.byKey(const Key('plan_block_label'));
        if (f.evaluate().isNotEmpty) {
          final t = tester.widget<Text>(f);
          final rotulo = t.data ?? t.textSpan?.toPlainText() ?? '';
          if (vistos.isEmpty || vistos.last != rotulo) vistos.add(rotulo);
        }
      }
      return vistos;
    }

    Future<void> esperar(Finder f) async {
      for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();
    }

    Future<void> tocar(Key key) async {
      await esperar(find.byKey(key));
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    Future<void> abrirPlano() async {
      // Depois do Concluir a gravacao guiada volta para a tela do plano, que
      // fica por cima das abas.
      await tester.pumpAndSettle();
      if (find.byKey(const Key('plan_list')).evaluate().isNotEmpty) return;
      await tester.tap(find.byKey(const Key('nav_record')));
      await tester.pumpAndSettle();
      await tocar(const Key('plan_entry'));
    }

    /// Pausa, segura Encerrar, Salvar (com RPE opcional) e Concluir.
    Future<void> encerrar({int? rpe}) async {
      await tester.tap(find.byKey(const Key('pause')));
      await tester.pumpAndSettle();
      final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('stop'))));
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await tester.pumpAndSettle();
      if (rpe != null) await tocar(Key('rpe_$rpe'));
      await tocar(const Key('save_activity'));
      await tocar(const Key('closing_done'));
    }

    Future<Plan5kSessionRow> ultimaSessao() async =>
        (await (db.select(db.plan5kSessions)
                  ..orderBy([(t) => OrderingTerm.desc(t.id)])
                  ..limit(1))
                .get())
            .single;

    // 0) Comeca o plano pela tela Gravar.
    await abrirPlano();
    expect(find.byKey(const Key('plan_health_notice')), findsOneWidget);
    await tocar(const Key('plan_begin'));
    // A proxima sessao aparece no topo da lista (fora da tela se ela estava
    // rolada ate o Comecar).
    final topo = find.byKey(const Key('plan_start_next'));
    if (topo.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        topo,
        -300,
        scrollable: find
            .descendant(of: find.byKey(const Key('plan_list')), matching: find.byType(Scrollable))
            .first,
      );
      debugPrint('[e2e-f06] PLAN-UX: proxima sessao fora da tela depois de Comecar');
    }
    await tocar(const Key('plan_start_next'));
    await esperar(find.byKey(const Key('plan_block_card')));
    expect(find.byKey(const Key('plan_block_card')), findsOneWidget);

    // 1) Encerra cedo: parcial, e a proxima continua sendo a mesma.
    await correr(5);
    await encerrar();
    final parcial = await ultimaSessao();
    debugPrint('[e2e-f06] sessao 1: ${parcial.status} ${parcial.movingMs} ms');
    expect(parcial.status, 'partial');
    expect((parcial.week, parcial.number), (1, 1));

    // 2) Tres sessoes inteiras; a 2a com RPE 9. A 3a passa pelo segundo plano.
    for (final (n, rpe, bg) in [(1, null, null), (2, 9, null), (3, 5, 6)]) {
      await abrirPlano();
      await tocar(const Key('plan_start_next'));
      await esperar(find.byKey(const Key('plan_block_card')));
      final blocos = await correr(20, segundoPlanoEm: bg);
      debugPrint('[e2e-f06] sessao 1.$n blocos: $blocos');
      await encerrar(rpe: rpe);
      final row = await ultimaSessao();
      final voltas = await db.lapsForActivity(row.activityGuid!);
      debugPrint('[e2e-f06] sessao 1.$n: ${row.status} ${row.movingMs} ms, '
          '${voltas.length} voltas');
      expect((row.week, row.number), (1, n));
      expect(row.status, 'done', reason: 'sessao 1.$n cobriu os 17 s');
      expect(voltas.length, greaterThanOrEqualTo(4),
          reason: 'cada troca de bloco fecha uma volta');
      if (bg == null) {
        expect(blocos.length, greaterThanOrEqualTo(4), reason: 'blocos vistos: $blocos');
      }
    }

    // 3) Fim da semana 1 com um RPE 9: sugere repetir (padrao).
    await esperar(find.byKey(const Key('plan_repeat_dialog')));
    expect(find.byKey(const Key('plan_repeat_dialog')), findsOneWidget);
    await tocar(const Key('plan_repeat_week'));
    await abrirPlano();
    await esperar(find.byKey(const Key('plan_next_card')));
    final proxima = find.descendant(
      of: find.byKey(const Key('plan_next_card')),
      matching: find.textContaining('Semana 1'),
    );
    expect(proxima, findsWidgets, reason: 'semana 1 repetida');
    final estado = (await db.select(db.plan5kStates).get()).single;
    debugPrint('[e2e-f06] estado: $estado');
  });
}
