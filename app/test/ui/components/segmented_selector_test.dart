// SegmentedSelector na largura de um iPhone (390 pt): os rotulos cabem
// inteiros, sem reticencias, tambem com a fonte do sistema maior (GRA-08).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/ui/components/segmented_selector.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

/// Retangulo pintado na tela (ja com a escala de um FittedBox acima).
Rect _painted(WidgetTester tester, Finder f) {
  final box = tester.renderObject<RenderBox>(f);
  return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
}

void main() {
  // Os rotulos mais longos do app: esporte no preparo e visibilidade na Salvar.
  const sports = ['Corrida', 'Pedal', 'Caminhada'];
  const visibility = ['Só eu', 'Seguidores', 'Todos'];

  Future<void> pump(WidgetTester tester, List<String> labels, double scale) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(builder: (context) {
          final c = AppColors.of(context);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppShape.gutter),
            child: Center(
              child: SegmentedSelector<String>(
                options: [
                  for (final l in labels)
                    SegmentOption(value: l, label: l, role: c.ciano, icon: Icons.circle),
                ],
                selected: labels.last,
                onChanged: (_) {},
              ),
            ),
          );
        }),
      ),
    ));
  }

  for (final scale in [1.0, 1.3, 2.0]) {
    for (final labels in [sports, visibility]) {
      testWidgets('rotulos inteiros em 390 pt com fonte x$scale: ${labels.join(', ')}', (tester) async {
        await pump(tester, labels, scale);
        expect(tester.takeException(), isNull);
        for (final l in labels) {
          final text = find.text(l);
          final p = tester.renderObject<RenderParagraph>(text);
          expect(p.didExceedMaxLines, isFalse, reason: '"$l" truncado');
          // O texto pintado cabe dentro do proprio segmento.
          final seg = _painted(tester, find.ancestor(of: text, matching: find.byType(InkWell)));
          final r = _painted(tester, text);
          expect(r.left, greaterThanOrEqualTo(seg.left - 0.5), reason: '"$l" sai pela esquerda');
          expect(r.right, lessThanOrEqualTo(seg.right + 0.5), reason: '"$l" sai pela direita');
        }
      });
    }
  }
}
