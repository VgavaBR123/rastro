// Modo Gentil (F04) nas Configuracoes: chave que liga e desliga e persiste.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
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
}
