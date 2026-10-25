// Widget test da tela inicial: mostra as tres opcoes de atividade.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/ui/home_screen.dart';

void main() {
  testWidgets('Home mostra as tres atividades', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: HomeScreen()),
    ));

    expect(find.text('Correr'), findsOneWidget);
    expect(find.text('Pedalar'), findsOneWidget);
    expect(find.text('Caminhar'), findsOneWidget);
    expect(find.text('Escolha a atividade'), findsOneWidget);
  });
}
