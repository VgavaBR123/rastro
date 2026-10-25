// Widget test da tela de configuracoes (toggle de unidades persiste no estado).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';

void main() {
  testWidgets('alternar unidades reflete na tela', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('km, m, min/km'), findsOneWidget);

    await tester.tap(find.byKey(const Key('metric')));
    await tester.pumpAndSettle();

    expect(find.text('mi, ft, min/mi'), findsOneWidget);
  });
}
