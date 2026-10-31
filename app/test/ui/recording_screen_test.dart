// Widget test da RecordingScreen com providers sobrescritos (fonte fake + DB em
// memoria). Verifica que a tela inicia a gravacao, renderiza metricas e
// controles, e o fluxo Pausar -> segurar Encerrar -> Salvar ou Descartar.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/settings/app_settings.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/sample_route.dart';
import '../recording/fakes.dart';

/// Configuracoes fixas (sem banco) para escolher a unidade no teste.
class _FixedSettings extends SettingsController {
  _FixedSettings(super.db, AppSettings s) {
    state = s;
  }
  @override
  Future<void> load() async {}
}

class _FakeSource implements LocationSource {
  final _c = StreamController<LocationSample>();
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Stream<LocationSample> positions() => _c.stream;
  @override
  Future<void> stop() async => _c.close();
}

void main() {
  testWidgets('RecordingScreen inicia e mostra metricas e controles', (
    tester,
  ) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(_FakeSource()),
          recordingDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: RecordingScreen(activityType: ActivityType.run),
        ),
      ),
    );

    // Deixa o postFrameCallback iniciar a gravacao.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Rotulos das metricas e controles presentes.
    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Pace medio'), findsOneWidget);
    // Pace atual e subida sairam da tela de gravacao (3 numeros grandes).
    expect(find.text('Pace atual'), findsNothing);
    expect(find.text('Subida'), findsNothing);
    expect(find.byKey(const Key('pause')), findsOneWidget);
    expect(find.byKey(const Key('lap')), findsOneWidget);
    // Encerrar so aparece pausado.
    expect(find.byKey(const Key('stop')), findsNothing);
  });

  testWidgets(
      'app recem-aberto: a gravacao espera as configuracoes (auto-pausa off)',
      (tester) async {
    // Regressao vista no emulador: tocar em Correr logo apos abrir o app
    // gravava com os PADROES (auto-pausa ligada, sem peso), porque as
    // configuracoes ainda nao tinham carregado do banco.
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.saveSettings(autoPauseEnabled: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(_FakeSource()),
          recordingDatabaseProvider.overrideWithValue(db),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
        ],
        child: const MaterialApp(
          home: RecordingScreen(activityType: ActivityType.run),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    final rows = await db.select(db.activities).get();
    expect(rows, hasLength(1));
    expect(rows.single.autoPauseEnabled, isFalse);
  });

  Future<FakeLocationSource> pumpScreen(
    WidgetTester tester, {
    required bool metric,
    FakeRecordingService? service,
    RecordingDatabase? database,
    ThemeData? theme,
    List<Object?>? popped,
  }) async {
    final db = database ?? RecordingDatabase(NativeDatabase.memory());
    if (database == null) addTearDown(db.close);
    final source = FakeLocationSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith(
            (ref) => _FixedSettings(db, AppSettings(useMetric: metric)),
          ),
          if (service != null)
            recordingServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  // A tela devolve o guid salvo ao fechar (E2E-04).
                  onPressed: () => Navigator.of(context)
                      .push<Object?>(
                        MaterialPageRoute(
                          builder: (_) => const RecordingScreen(
                            activityType: ActivityType.ride,
                          ),
                        ),
                      )
                      .then((r) => popped?.add(r)),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return source;
  }

  /// Deixa microtarefas e timers da gravacao (banco em memoria) andarem.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> feed(
    WidgetTester tester,
    FakeLocationSource source,
    int n,
  ) async {
    for (final s in sampleRoute().take(n)) {
      source.add(s);
    }
    await settle(tester);
  }

  testWidgets('mostra o split corrente (km) e a volta corrente ao vivo', (
    tester,
  ) async {
    final source = await pumpScreen(tester, metric: true);
    await feed(tester, source, 5);

    final split = find.byKey(const Key('current_split'));
    expect(
      find.descendant(of: split, matching: find.text('Km 1')),
      findsOneWidget,
    );
    // ~44 m em 4 s -> pace ao vivo de ~1:30 /km.
    expect(
      find.descendant(of: split, matching: find.textContaining('/km')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: split, matching: find.text('--:-- /km')),
      findsNothing,
    );
    final lap = find.byKey(const Key('current_lap'));
    expect(
      find.descendant(of: lap, matching: find.text('Volta 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: lap, matching: find.text('0:04')),
      findsOneWidget,
    );

    // Botao Volta: fecha a volta 1 e abre a 2.
    await tester.ensureVisible(find.byKey(const Key('lap')));
    await tester.tap(find.byKey(const Key('lap')));
    await settle(tester);
    expect(
      find.descendant(of: lap, matching: find.text('Volta 2')),
      findsOneWidget,
    );
  });

  testWidgets('split em milha quando a unidade e imperial', (tester) async {
    final source = await pumpScreen(tester, metric: false);
    await feed(tester, source, 5);
    final split = find.byKey(const Key('current_split'));
    expect(
      find.descendant(of: split, matching: find.text('Milha 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: split, matching: find.textContaining('/mi')),
      findsOneWidget,
    );
  });

  testWidgets('Encerrar pela notificacao fecha a tela', (tester) async {
    final service = FakeRecordingService();
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final popped = <Object?>[];
    final source = await pumpScreen(tester, metric: true, service: service, database: db, popped: popped);
    await feed(tester, source, 3);
    expect(find.byType(RecordingScreen), findsOneWidget);

    service.press(RecordingCommand.stop);
    // O encerramento cancela assinaturas e escreve no banco: alterna tempo
    // real e tempo falso ate tudo assentar.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(find.byType(RecordingScreen), findsNothing);
    expect(service.stops, 1);
    // Salvou: devolve o guid para quem abriu avisar "Atividade salva".
    final rows = await db.select(db.activities).get();
    expect(popped, [rows.single.guid]);
  });

  /// Segura o botao (variante hold) ate passar o tempo de confirmacao.
  Future<void> hold(WidgetTester tester, Finder f) async {
    final g = await tester.startGesture(tester.getCenter(f));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
  }

  /// Deixa o encerramento (banco real em memoria) terminar.
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> pauseAndOpenSave(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    expect(find.text('Pausado'), findsOneWidget);
    expect(find.byKey(const Key('resume')), findsOneWidget);
    await hold(tester, find.byKey(const Key('stop')));
    expect(find.byKey(const Key('save_activity_view')), findsOneWidget);
  }

  testWidgets('Encerrar exige segurar: toque curto nao abre Salvar', (
    tester,
  ) async {
    final source = await pumpScreen(tester, metric: true);
    await feed(tester, source, 3);
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('stop')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('save_activity_view')), findsNothing);
    expect(find.byKey(const Key('resume')), findsOneWidget);
  });

  testWidgets('Salvar: titulo sugerido, finaliza no banco e fecha a tela', (
    tester,
  ) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final popped = <Object?>[];
    final source = await pumpScreen(tester, metric: true, database: db, popped: popped);
    await feed(tester, source, 5);
    await pauseAndOpenSave(tester);

    expect(find.byKey(const Key('save_distance')), findsOneWidget);
    final list = find
        .descendant(
          of: find.byKey(const Key('save_activity_view')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('save_title')),
      200,
      scrollable: list,
    );
    final title = tester.widget<TextField>(find.byKey(const Key('save_title')));
    expect(title.controller!.text, startsWith('Pedal da '));
    await tester.scrollUntilVisible(
      find.byKey(const Key('visibility_only_me')),
      200,
      scrollable: list,
    );
    await tester.tap(find.byKey(const Key('visibility_only_me')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_activity')));
    await drain(tester);
    expect(find.byType(RecordingScreen), findsNothing);
    final rows = await db.select(db.activities).get();
    expect(rows, hasLength(1));
    expect(rows.single.isFinished, isTrue);
    expect(popped, [rows.single.guid]);
  });

  testWidgets('Voltar a gravacao sai da tela Salvar e segue pausado', (
    tester,
  ) async {
    final source = await pumpScreen(tester, metric: true);
    await feed(tester, source, 3);
    await pauseAndOpenSave(tester);
    await tester.tap(find.byKey(const Key('save_back')));
    await tester.pump();
    expect(find.byKey(const Key('save_activity_view')), findsNothing);
    expect(find.byKey(const Key('resume')), findsOneWidget);
  });

  testWidgets('Descartar pede confirmacao e apaga a atividade', (
    tester,
  ) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final popped = <Object?>[];
    final source = await pumpScreen(tester, metric: true, database: db, popped: popped);
    await feed(tester, source, 5);
    await pauseAndOpenSave(tester);

    await tester.tap(find.byKey(const Key('discard_activity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discard_dialog')), findsOneWidget);
    // Cancelar mantem a tela Salvar.
    await tester.tap(find.byKey(const Key('discard_cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save_activity_view')), findsOneWidget);

    await tester.tap(find.byKey(const Key('discard_activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discard_confirm')));
    await drain(tester);
    expect(find.byType(RecordingScreen), findsNothing);
    expect(await db.select(db.activities).get(), isEmpty);
    expect(popped, [null]); // nada salvo, nada a avisar
  });

  testWidgets('alterna para o mapa pelo botao', (tester) async {
    final source = await pumpScreen(tester, metric: true);
    await feed(tester, source, 3);
    await tester.tap(find.byKey(const Key('toggle_map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recording_map')), findsOneWidget);
    expect(find.text('Metricas'), findsOneWidget);
  });

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('renderiza gravando, pausado e Salvar no tema $nome', (
      tester,
    ) async {
      final source = await pumpScreen(tester, metric: true, theme: tema);
      await feed(tester, source, 5);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('toggle_map')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_map')));
      await tester.pumpAndSettle();
      await pauseAndOpenSave(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
