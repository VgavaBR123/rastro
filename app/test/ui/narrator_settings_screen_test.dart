// Configuracoes > Narrador (F03): ligar/desligar, gatilhos, conteudo, so o
// essencial e "Ouvir exemplo", tudo salvo no banco.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/narrator/narrator_providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/narrator_settings_screen.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../narrator/fake_voice_announcer.dart';

void main() {
  late RecordingDatabase db;
  late FakeVoiceAnnouncer voice;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    voice = FakeVoiceAnnouncer();
  });
  tearDown(() async => db.close());

  Future<void> pumpScreen(WidgetTester tester, {String initial = AppRoutes.narrator}) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
        narratorRoute(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          voiceAnnouncerProvider.overrideWithValue(voice),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<NarratorSettings> saved() async =>
      NarratorSettings.fromJsonString((await db.loadSettings()).narratorPrefs);

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('Configuracoes mostra o item Narrador e abre a tela', (tester) async {
    await pumpScreen(tester, initial: AppRoutes.settings);
    final tile = find.byKey(const Key('narrator'));
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: tile, matching: find.text('Desligado')), findsOneWidget);
    expect(tester.getSize(tile).height, greaterThanOrEqualTo(44));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(NarratorSettingsScreen), findsOneWidget);
  });

  testWidgets('ligar o narrador salva no banco', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Narrador por voz'), findsWidgets);
    await tapKey(tester, 'narrator_enabled');
    expect((await saved()).enabled, isTrue);
  });

  testWidgets('gatilhos: distancia a cada 5, tempo a cada 10 min, sem volta', (tester) async {
    await pumpScreen(tester);
    expect(find.text('A cada km'), findsOneWidget);
    await tapKey(tester, 'narrator_distance_every_5');
    await tapKey(tester, 'narrator_time_10');
    await tapKey(tester, 'narrator_lap');
    final s = await saved();
    expect(s.distanceEvery, 5);
    expect(s.timeEveryMinutes, 10);
    expect(s.lapTrigger, isFalse);
  });

  testWidgets('desligar a distancia esconde o "a cada N"', (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const Key('narrator_distance_every_1')), findsOneWidget);
    await tapKey(tester, 'narrator_distance');
    expect(find.byKey(const Key('narrator_distance_every_1')), findsNothing);
    expect((await saved()).distanceTrigger, isFalse);
  });

  testWidgets('so o essencial desativa as escolhas de conteudo', (tester) async {
    await pumpScreen(tester);
    await tapKey(tester, 'narrator_essential');
    expect((await saved()).essentialOnly, isTrue);
    final tile = tester.widget<SwitchListTile>(find.byKey(const Key('narrator_say_time')));
    expect(tile.onChanged, isNull);
  });

  testWidgets('conteudo: tirar o tempo e as frases de contexto', (tester) async {
    await pumpScreen(tester);
    await tapKey(tester, 'narrator_say_time');
    await tapKey(tester, 'narrator_context');
    final s = await saved();
    expect(s.sayTime, isFalse);
    expect(s.contextPhrases, isFalse);
    expect(s.sayDistance, isTrue);
  });

  testWidgets('ouvir exemplo fala com as preferencias atuais, mesmo desligado', (tester) async {
    await pumpScreen(tester);
    await tapKey(tester, 'narrator_sample');
    await tester.pumpAndSettle();
    expect(voice.spoken, hasLength(1));
    expect(voice.spoken.single, startsWith('Dois quilômetros.'));
    await tapKey(tester, 'narrator_essential');
    await tapKey(tester, 'narrator_sample');
    await tester.pumpAndSettle();
    expect(voice.spoken.last, 'Dois quilômetros. Pace cinco e vinte.');
  });

  testWidgets('ouvir exemplo nao apaga as falas pendentes de outras partes', (tester) async {
    voice = FakeVoiceAnnouncer(autoComplete: false);
    await pumpScreen(tester);
    final ctx = tester.element(find.byType(NarratorSettingsScreen));
    final narrator = ProviderScope.containerOf(ctx).read(narratorProvider);
    narrator.say('Um quilômetro.');
    narrator.say('Cinco minutos.');
    await tester.pump();
    await tapKey(tester, 'narrator_sample');
    expect(voice.stops, 0);
    for (var i = 0; i < 3; i++) {
      voice.finishCurrent();
      await tester.pump();
    }
    expect(voice.spoken, hasLength(3));
    expect(voice.spoken.take(2), ['Um quilômetro.', 'Cinco minutos.']);
    expect(voice.spoken.last, startsWith('Dois quilômetros.'));
  });

  testWidgets('imperial fala de milhas', (tester) async {
    await db.saveSettings(useMetric: false);
    await pumpScreen(tester);
    expect(find.text('A cada milha'), findsOneWidget);
    expect(find.text('5 mi'), findsOneWidget);
  });

  testWidgets('alvos de toque >= 44 dp', (tester) async {
    await pumpScreen(tester);
    for (final k in ['narrator_enabled', 'narrator_distance_every_2', 'narrator_time_5']) {
      final f = find.byKey(Key(k));
      await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
      expect(tester.getSize(f).height, greaterThanOrEqualTo(44), reason: k);
    }
    final sample = find.byKey(const Key('narrator_sample'));
    await tester.scrollUntilVisible(sample, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.getSize(sample).height, greaterThanOrEqualTo(44));
  });
}
