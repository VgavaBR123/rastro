// Tela Gravar (F03): atalho liga/desliga do Narrador por voz na folha, entre
// o esporte e o Iniciar.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/persistence/database.dart';

import 'record_setup_screen_test.dart' show pumpSetup;

void main() {
  testWidgets('atalho mostra o estado e liga/desliga salvando no banco', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    final container = await pumpSetup(tester, db: db);

    final toggle = find.byKey(const Key('narrator_toggle'));
    expect(toggle, findsOneWidget);
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    expect(container.read(settingsProvider).narrator.enabled, isTrue);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    final row = await tester.runAsync(db.loadSettings);
    expect(NarratorSettings.fromJsonString(row!.narratorPrefs).enabled, isTrue);

    await tester.tap(toggle);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    expect(container.read(settingsProvider).narrator.enabled, isFalse);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  testWidgets('cabe na largura de um Pixel 7 (412 dp) sem estourar', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await pumpSetup(tester, db: db);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('narrator_toggle')), findsOneWidget);
  });
}
