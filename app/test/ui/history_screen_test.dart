// Widget tests do historico e do detalhe, com DB em memoria semeado.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/activity_detail_screen.dart';
import 'package:strava_estudo_app/ui/components/activity_card.dart';
import 'package:strava_estudo_app/ui/history_screen.dart';
import 'package:strava_estudo_app/ui/share/share_activity_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/fake_sharer.dart';

dom.Waypoint acc(double lat, double dist) => dom.Waypoint(
  position: GeoPoint(latitude: lat, longitude: 0, altitudeMeters: 100),
  cumulativeDistanceMeters: dist,
  elapsedTimeMs: 0,
  timerTimeMs: 60000,
  classification: dom.WaypointClassification.accept,
  horizontalAccuracyMeters: 5,
);

Future<RecordingDatabase> seededDb() async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  await repo.startActivity(
    guid: 'a',
    type: ActivityType.run,
    startTimestampMs: 1000,
  );
  await repo.appendWaypoints('a', [acc(0.0, 0), acc(0.001, 1200)]);
  await repo.finish('a', 61000, distanceMeters: 1200, timerTimeMs: 60000);
  return db;
}

void main() {
  testWidgets('Historico lista a atividade finalizada', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Corrida'), findsOneWidget); // chip do esporte
    expect(find.byType(ActivityCard), findsOneWidget);
  });

  for (final (name, theme) in [
    ('escuro', AppTheme.dark),
    ('claro', AppTheme.light),
  ]) {
    testWidgets('Historico no visual novo, com badge de pendentes ($name)', (
      tester,
    ) async {
      final db = await seededDb();
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [recordingDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(theme: theme, home: const HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Historico'), findsOneWidget);
      expect(find.byKey(const Key('sync')), findsOneWidget);
      expect(find.byTooltip('Sincronizar, 1 pendente'), findsOneWidget);
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isTrue);
      // Cartao compacto: sem miniatura e sem os botoes do feed.
      final card = tester.widget<ActivityCard>(find.byType(ActivityCard));
      expect(card.compact, isTrue);
      expect(find.text('Ver detalhe'), findsNothing);
      expect(find.text('1,20 km'), findsOneWidget);
      expect(find.byKey(const Key('menu-a')), findsOneWidget);
    });
  }

  testWidgets('HIS-01: sem conta, cada toque em Sincronizar mostra o aviso', (
    tester,
  ) async {
    final db = await seededDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('sync')));
      await tester.pumpAndSettle();
      expect(
        find.text('Entre na sua conta para sincronizar'),
        findsOneWidget,
        reason: 'toque ${i + 1}',
      );
      // O aviso some (troca de aba, tempo) antes do proximo toque.
      ScaffoldMessenger.of(tester.element(find.byType(HistoryScreen)))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.text('Entre na sua conta para sincronizar'), findsNothing);
    }
  });

  testWidgets('HIS-02: o aviso com "Entrar" some sozinho em ~4 s', (
    tester,
  ) async {
    final db = await seededDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sync')));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Entre na sua conta para sincronizar'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Entre na sua conta para sincronizar'), findsNothing);
  });

  testWidgets('HIS-11: sync com rotulo unico e cartao anunciado como botao', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = await seededDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.dark, home: const HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // O numero do selo nao e lido de novo: um rotulo so.
    expect(
      tester.getSemantics(find.byKey(const Key('sync'))),
      isSemantics(
        tooltip: 'Sincronizar, 1 pendente',
        label: '',
        isButton: true,
      ),
    );

    final card = find.bySemanticsLabel(RegExp(r'abrir detalhe$'));
    expect(card, findsOneWidget);
    final node = tester.getSemantics(card);
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    expect(node.label, contains('1,20 quilometros'));
    expect(node.label, contains('1 minuto'));
    // Atividade nova nasce "So eu" (GRA-05): o selo entra no rotulo unico.
    expect(node.label, contains('quem pode ver: So eu'));
    // O menu do cartao continua alcancavel como elemento proprio.
    final buttons = <SemanticsNode>[];
    void collect(SemanticsNode n) {
      if (n.getSemanticsData().flagsCollection.isButton) buttons.add(n);
      n.visitChildren((c) {
        collect(c);
        return true;
      });
    }

    node.visitChildren((c) {
      collect(c);
      return true;
    });
    expect(buttons, hasLength(1), reason: 'o botao do menu, dentro do cartao');
    handle.dispose();
  });

  testWidgets('Confirmar no dialogo exclui a atividade da lista', (
    tester,
  ) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-a')));
    await tester.pumpAndSettle();

    expect(find.text('Excluir atividade?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityCard), findsNothing);
    expect(find.text('Nenhuma atividade ainda'), findsOneWidget);
    expect(find.text('Atividade excluida'), findsOneWidget);
    expect(await RecordingRepository(db).recent(), isEmpty);
  });

  testWidgets('Compartilhar no menu abre a tela Compartilhar', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    final sharer = FakeActivitySharer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          activitySharerProvider.overrideWithValue(sharer),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-a')));
    await tester.pumpAndSettle();

    expect(find.byType(ShareActivityScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('share_text_only')));
    await tester.pump();
    expect(sharer.texts.single, startsWith('Corrida'));

    await tester.tap(find.byKey(const Key('share_back')));
    await tester.pumpAndSettle();
    expect(find.byType(ShareActivityScreen), findsNothing);
    expect(find.byType(ActivityCard), findsOneWidget);
  });

  testWidgets('Cancelar no dialogo mantem a atividade', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-delete')));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityCard), findsOneWidget);
    expect(find.text('Atividade excluida'), findsNothing);
    expect((await RecordingRepository(db).recent()).length, 1);
  });

  testWidgets('Detalhe mostra metricas da atividade', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    final activity = (await RecordingRepository(db).recent()).first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ActivityDetailScreen(activity: activity)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Pace'), findsOneWidget);
    expect(find.text('1,20 km'), findsOneWidget); // 1200 m
  });
}
