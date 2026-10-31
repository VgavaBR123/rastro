// SplitBar: calculo puro de largura e papel, e a barra desenhada no tema.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/ui/components/split_bar.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

void main() {
  group('splitBarSpecs', () {
    test(
      'largura proporcional entre 55% e 100%, com mais rápida e mais lenta',
      () {
        final specs = splitBarSpecs([3.0, 4.0, 5.0]);
        expect(specs[0], const SplitBarSpec(0.55, SplitRank.slowest));
        expect(specs[1].fraction, closeTo(0.775, 1e-9));
        expect(specs[1].rank, SplitRank.normal);
        expect(specs[2], const SplitBarSpec(1.0, SplitRank.fastest));
      },
    );

    test('todas iguais ou uma só: largura cheia, sem ranking', () {
      expect(splitBarSpecs([4.0, 4.0]), [
        const SplitBarSpec(1.0, SplitRank.normal),
        const SplitBarSpec(1.0, SplitRank.normal),
      ]);
      expect(splitBarSpecs([2.5]), [const SplitBarSpec(1.0, SplitRank.normal)]);
    });

    test('velocidade inválida fica com a minima e fora do ranking', () {
      final specs = splitBarSpecs([0.0, 2.0, double.nan, 4.0]);
      expect(specs[0], const SplitBarSpec(0.55, SplitRank.normal));
      expect(specs[1], const SplitBarSpec(0.55, SplitRank.slowest));
      expect(specs[2], const SplitBarSpec(0.55, SplitRank.normal));
      expect(specs[3], const SplitBarSpec(1.0, SplitRank.fastest));
    });

    test('empates recebem o mesmo papel; lista vazia da vazia', () {
      final specs = splitBarSpecs([5.0, 3.0, 5.0, 3.0]);
      expect(specs.map((s) => s.rank), [
        SplitRank.fastest,
        SplitRank.slowest,
        SplitRank.fastest,
        SplitRank.slowest,
      ]);
      expect(splitBarSpecs(const []), isEmpty);
    });
  });

  test('splitRankRole: rápida = dist, lenta = tempo, demais = pace', () {
    for (final c in [AppColors.dark, AppColors.light]) {
      expect(splitRankRole(c, SplitRank.fastest), c.dist);
      expect(splitRankRole(c, SplitRank.slowest), c.tempo);
      expect(splitRankRole(c, SplitRank.normal), c.pace);
    }
  });

  for (final (nome, theme, colors) in [
    ('escuro', AppTheme.dark, AppColors.dark),
    ('claro', AppTheme.light, AppColors.light),
  ]) {
    testWidgets('barra com 14 de altura, raio 7, largura e cor ($nome)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SplitBar(
                      key: const Key('a'),
                      spec: const SplitBarSpec(0.55, SplitRank.slowest),
                    ),
                    SplitBar(
                      key: const Key('b'),
                      spec: const SplitBarSpec(1.0, SplitRank.fastest),
                    ),
                    const SplitBarLegend(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      Container barra(String k) => tester.widget<Container>(
        find.descendant(
          of: find.byKey(Key(k)),
          matching: find.byType(Container),
        ),
      );
      (double, double) tamanho(String k) {
        final s = tester.getSize(
          find.descendant(
            of: find.byKey(Key(k)),
            matching: find.byType(Container),
          ),
        );
        return (s.width, s.height);
      }

      expect(tamanho('a').$1, closeTo(110, 1e-6));
      expect(tamanho('a').$2, 14);
      expect(tamanho('b'), (200.0, 14.0));
      final deco = barra('a').decoration! as BoxDecoration;
      expect(deco.color, colors.tempo.fill);
      expect(deco.borderRadius, BorderRadius.circular(7));
      expect((barra('b').decoration! as BoxDecoration).color, colors.dist.fill);

      expect(find.text('Mais rápida'), findsOneWidget);
      expect(find.text('Mais lenta'), findsOneWidget);
      expect(find.text('Demais'), findsOneWidget);
    });
  }
}
