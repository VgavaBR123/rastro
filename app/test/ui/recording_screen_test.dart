// Widget test da RecordingScreen com providers sobrescritos (fonte fake + DB em
// memoria). Verifica que a tela inicia a gravacao e renderiza metricas e controles.
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
    expect(find.text('Pace'), findsOneWidget);
    expect(find.text('Elevacao'), findsOneWidget);
    expect(find.byKey(const Key('pause')), findsOneWidget);
    expect(find.byKey(const Key('stop')), findsOneWidget);
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
  }) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecordingScreen(
                        activityType: ActivityType.ride,
                      ),
                    ),
                  ),
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
    final source = await pumpScreen(tester, metric: true, service: service);
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
  });
}
