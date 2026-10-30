// Fechamento gentil (F04) na tela de gravacao: Salvar grava RPE e humor e
// mostra o fechamento com 2 ou 3 frases (Concluir fecha a tela); o Modo
// Gentil esconde o pace ao vivo.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/closing/closing_service.dart';
import 'package:strava_estudo_app/closing/domain/effort.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/settings/app_settings.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/sample_route.dart';
import '../recording/fakes.dart';

class _FixedSettings extends SettingsController {
  _FixedSettings(super.db, AppSettings s) {
    state = s;
  }
  @override
  Future<void> load() async {}
}

/// Frases fixas (o dominio tem testes proprios).
class _FakeClosing extends ClosingService {
  final List<String> phrases;
  final bool fail;
  bool? lastGentle;
  _FakeClosing(super.repo, this.phrases, {this.fail = false});

  @override
  Future<List<String>> phrasesFor(String guid, {required bool gentle, required bool metric}) async {
    lastGentle = gentle;
    if (fail) throw StateError('falhou');
    return phrases;
  }
}

/// Fotografa a linha no instante em que ela entra na fila de upload: um sync
/// que ja estivesse rodando leria exatamente isto.
class _SnapshotOnFinish extends RecordingRepository {
  Activity? atFinish;
  _SnapshotOnFinish(super.db);

  @override
  Future<void> finish(
    String guid,
    int endTimestampMs, {
    int? endBattery,
    double? distanceMeters,
    int? timerTimeMs,
    double? calories,
  }) async {
    await super.finish(
      guid,
      endTimestampMs,
      endBattery: endBattery,
      distanceMeters: distanceMeters,
      timerTimeMs: timerTimeMs,
      calories: calories,
    );
    atFinish = await (db.select(db.activities)..where((t) => t.guid.equals(guid))).getSingle();
  }
}

void main() {
  late RecordingDatabase db;
  late FakeLocationSource source;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> hold(WidgetTester tester, Finder f) async {
    final g = await tester.startGesture(tester.getCenter(f));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
  }

  Future<void> pump(
    WidgetTester tester, {
    bool gentle = false,
    ClosingService Function(RecordingRepository repo)? closing,
    RecordingRepository Function(RecordingDatabase db)? repo,
  }) async {
    db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    source = FakeLocationSource();
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith(
            (ref) => _FixedSettings(db, AppSettings(gentleMode: gentle)),
          ),
          if (repo != null) recordingRepositoryProvider.overrideWithValue(repo(db)),
          if (closing != null)
            closingServiceProvider.overrideWith(
              (ref) => closing(ref.watch(recordingRepositoryProvider)),
            ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecordingScreen(activityType: ActivityType.run),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    for (final s in sampleRoute().take(5)) {
      source.add(s);
    }
    await settle(tester);
  }

  Future<void> openSave(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await hold(tester, find.byKey(const Key('stop')));
    expect(find.byKey(const Key('save_activity_view')), findsOneWidget);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  testWidgets('Salvar com RPE e humor: grava e mostra o fechamento', (tester) async {
    late _FakeClosing fake;
    await pump(tester, closing: (repo) => fake = _FakeClosing(repo, const [
      'Sua corrida mais longa das ultimas 4 semanas.',
      'Foram 32 min em movimento.',
    ]));
    await openSave(tester);
    await tapVisible(tester, const Key('rpe_6'));
    await tapVisible(tester, const Key('mood_good'));
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);

    // A tela continua aberta, agora no fechamento.
    expect(find.byType(RecordingScreen), findsOneWidget);
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    expect(find.text('Sua corrida mais longa das ultimas 4 semanas.'), findsOneWidget);
    expect(find.text('Foram 32 min em movimento.'), findsOneWidget);
    expect(find.byKey(const Key('closing_effort')), findsOneWidget);
    expect(find.text('6 - Moderado'), findsOneWidget);
    expect(find.text('Bem'), findsOneWidget);
    expect(fake.lastGentle, isFalse);

    final row = (await db.select(db.activities).get()).single;
    expect(row.isFinished, isTrue);
    expect(row.rpe, 6);
    expect(Mood.fromDb(row.mood), Mood.good);

    await tester.tap(find.byKey(const Key('closing_done')));
    await drain(tester);
    expect(find.byType(RecordingScreen), findsNothing);
  });

  testWidgets('RPE, humor e detalhes ja estao gravados quando a atividade entra na fila', (tester) async {
    late _SnapshotOnFinish snap;
    await pump(
      tester,
      closing: (repo) => _FakeClosing(repo, const ['Frase um.', 'Frase dois.']),
      repo: (db) => snap = _SnapshotOnFinish(db),
    );
    await openSave(tester);
    await tapVisible(tester, const Key('rpe_8'));
    await tapVisible(tester, const Key('mood_tired'));
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);

    final row = snap.atFinish!;
    expect(row.isFinished, isTrue);
    expect(row.rpe, 8);
    expect(Mood.fromDb(row.mood), Mood.tired);
  });

  testWidgets('sem RPE: fechamento sem bloco de esforco; voltar do sistema fecha', (tester) async {
    await pump(tester, closing: (repo) => _FakeClosing(repo, const ['Frase um.', 'Frase dois.']));
    await openSave(tester);
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    expect(find.byKey(const Key('closing_effort')), findsNothing);
    expect((await db.select(db.activities).get()).single.rpe, isNull);

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    await nav.maybePop();
    await drain(tester);
    expect(find.byType(RecordingScreen), findsNothing);
  });

  testWidgets('frases falharam: o fechamento abre mesmo assim', (tester) async {
    await pump(tester, closing: (repo) => _FakeClosing(repo, const [], fail: true));
    await openSave(tester);
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    expect(find.text('Treino salvo.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('closing_done')));
    await drain(tester);
    expect(find.byType(RecordingScreen), findsNothing);
  });

  testWidgets('frases reais do historico (servico de verdade)', (tester) async {
    await pump(tester);
    await openSave(tester);
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    // Primeira corrida do aparelho.
    expect(find.text('Sua primeira corrida registrada aqui. Bom comeco.'), findsOneWidget);
    expect(find.byKey(const Key('closing_done')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('closing_done'))).height, greaterThanOrEqualTo(64));
  });

  testWidgets('Modo Gentil: sem pace ao vivo, no Salvar e nas frases', (tester) async {
    late _FakeClosing fake;
    await pump(tester, gentle: true, closing: (repo) => fake = _FakeClosing(repo, const ['a', 'b']));
    expect(find.byKey(const Key('pace')), findsNothing);
    expect(find.text('Pace medio'), findsNothing);
    expect(find.byKey(const Key('duration')), findsOneWidget);
    expect(find.byKey(const Key('distance')), findsOneWidget);
    final split = find.byKey(const Key('current_split'));
    expect(find.descendant(of: split, matching: find.textContaining('/km')), findsNothing);

    await openSave(tester);
    expect(find.byKey(const Key('save_pace')), findsNothing);
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);
    expect(fake.lastGentle, isTrue);
  });
}
