// Widget test da tela inicial: mostra as tres opcoes de atividade.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/home_screen.dart';

void main() {
  testWidgets('Home mostra as tres atividades', (tester) async {
    // A Home consulta o banco na abertura (recuperacao pos-crash).
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Correr'), findsOneWidget);
    expect(find.text('Pedalar'), findsOneWidget);
    expect(find.text('Caminhar'), findsOneWidget);
    expect(find.text('Escolha a atividade'), findsOneWidget);
  });
}
