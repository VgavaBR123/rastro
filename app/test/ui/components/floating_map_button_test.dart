// INI-06 (teste no iPhone, 30/10/2026): no Detalhe, Voltar e Compartilhar
// eram lidos como texto estatico e "Compartilhar" saia duplicado. O botao
// sobre o mapa e um unico elemento com papel de botao e rotulo unico.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/ui/components/floating_map_button.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Future<void> pumpButtons(WidgetTester tester, List<String> taps) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Row(
          children: [
            FloatingMapButton(
              key: const Key('back'),
              icon: Icons.arrow_back,
              tooltip: 'Voltar',
              onPressed: () => taps.add('back'),
            ),
            FloatingMapButton(
              key: const Key('share'),
              icon: Icons.ios_share,
              tooltip: 'Compartilhar',
              label: 'Compartilhar',
              onPressed: () => taps.add('share'),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('so icone: botao com o rotulo do tooltip', (tester) async {
    final handle = tester.ensureSemantics();
    final taps = <String>[];
    await pumpButtons(tester, taps);

    expect(
      tester.getSemantics(find.byKey(const Key('back'))),
      matchesSemantics(
        label: 'Voltar',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Voltar'), findsOneWidget);

    // A acao de toque da semantica chama o botao.
    tester.semantics.tap(find.semantics.byLabel('Voltar'));
    expect(taps, ['back']);
    handle.dispose();
  });

  testWidgets('pilula: rotulo unico, sem repetir o tooltip', (tester) async {
    final handle = tester.ensureSemantics();
    final taps = <String>[];
    await pumpButtons(tester, taps);

    expect(
      tester.getSemantics(find.byKey(const Key('share'))),
      matchesSemantics(
        label: 'Compartilhar',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Compartilhar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('share')));
    expect(taps, ['share']);
    handle.dispose();
  });
}
