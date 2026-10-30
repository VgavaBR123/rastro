// Narrador na tela de gravacao (F03, revisao): descartar a gravacao nao fala o
// resumo de fim; salvar fala. Tela real + banco em memoria + GPS e voz falsos.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/narrator/narrator_providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/settings/app_settings.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';

import '../fixtures/sample_route.dart';
import '../narrator/fake_voice_announcer.dart';
import '../recording/fakes.dart';

class _FixedSettings extends SettingsController {
  _FixedSettings(super.db, AppSettings s) {
    state = s;
  }
  @override
  Future<void> load() async {}
}

void main() {
  late RecordingDatabase db;
  late FakeVoiceAnnouncer voice;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    voice = FakeVoiceAnnouncer();
  });
  tearDown(() async => db.close());

  Future<FakeLocationSource> pumpScreen(WidgetTester tester) async {
    final source = FakeLocationSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
          voiceAnnouncerProvider.overrideWithValue(voice),
          settingsProvider.overrideWith(
            (ref) => _FixedSettings(
              db,
              const AppSettings(narrator: NarratorSettings(enabled: true)),
            ),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
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
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return source;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> hold(WidgetTester tester, Finder f) async {
    final g = await tester.startGesture(tester.getCenter(f));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
  }

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> recordPauseAndOpenSave(WidgetTester tester) async {
    final source = await pumpScreen(tester);
    for (final s in sampleRoute().take(5)) {
      source.add(s);
    }
    await settle(tester);
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await hold(tester, find.byKey(const Key('stop')));
    expect(find.byKey(const Key('save_activity_view')), findsOneWidget);
  }

  testWidgets('descartar a gravacao nao fala o resumo de fim', (tester) async {
    await recordPauseAndOpenSave(tester);
    expect(voice.spoken, ['Corrida iniciada.', 'Gravação pausada.']);

    await tester.tap(find.byKey(const Key('discard_activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discard_confirm')));
    await drain(tester);

    expect(find.byType(RecordingScreen), findsNothing);
    expect(await db.select(db.activities).get(), isEmpty);
    expect(voice.spoken.where((t) => t.contains('encerrad')), isEmpty);
  });

  testWidgets('salvar a gravacao fala o resumo de fim', (tester) async {
    await recordPauseAndOpenSave(tester);
    await tester.tap(find.byKey(const Key('save_activity')));
    await drain(tester);
    // Fechamento gentil (F04): Salvar mostra as frases; Concluir fecha.
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    await tester.tap(find.byKey(const Key('closing_done')));
    await drain(tester);

    expect(find.byType(RecordingScreen), findsNothing);
    expect(voice.spoken.last, startsWith('Corrida encerrada.'));
  });
}
