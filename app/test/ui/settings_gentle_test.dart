// Modo Gentil (F04) nas Configuracoes: chave que liga e desliga e persiste.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/narrator_settings_screen.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

void main() {
  testWidgets('liga o Modo Gentil e grava no banco', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.dark, home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('gentle_mode'));
    await tester.ensureVisible(toggle);
    expect(find.text('Modo Gentil'), findsOneWidget);
    expect(find.text('Esconde pace e velocidade. Mostra tempo, distancia e esforco.'),
        findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect((await db.loadSettings()).gentleMode, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect((await db.loadSettings()).gentleMode, isFalse);
  });

  testWidgets('Narrador com Modo Gentil: chaves de ritmo desligadas e travadas', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.dark, home: const NarratorSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NarratorSettingsScreen)),
    );
    await tester.runAsync(() async {
      final ctrl = container.read(settingsProvider.notifier);
      await ctrl.ensureLoaded();
      await ctrl.updateNarrator((n) => n.copyWith(enabled: true, sayAvgPace: true));
      await ctrl.setGentleMode(true);
    });
    await tester.pumpAndSettle();

    for (final k in ['narrator_say_avg', 'narrator_say_split', 'narrator_context']) {
      final tile = tester.widget<SwitchListTile>(find.byKey(Key(k)));
      expect(tile.value, isFalse, reason: k);
      expect(tile.onChanged, isNull, reason: k);
    }
    expect(find.text('Desligado pelo Modo Gentil'), findsNWidgets(3));
    // Tempo e distancia seguem livres.
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('narrator_say_time'))).onChanged,
        isNotNull);
    // A preferencia guardada nao e apagada: volta ao desligar o Modo Gentil.
    expect(container.read(settingsProvider).narrator.sayAvgPace, isTrue);
  });
}
