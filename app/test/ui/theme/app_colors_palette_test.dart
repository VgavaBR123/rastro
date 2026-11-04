import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';

double _contraste(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  final (claro, escuro) = x > y ? (x, y) : (y, x);
  return (claro + 0.05) / (escuro + 0.05);
}

void main() {
  for (final (nome, c) in [
    ('escuro', AppColors.dark),
    ('claro', AppColors.light),
  ]) {
    group('paleta lima e neutros ($nome)', () {
      test('números de métrica usam a cor de texto', () {
        for (final r in [c.dist, c.tempo, c.pace, c.subida]) {
          expect(r.fg, c.text);
        }
      });

      test('todo esporte tem o mesmo chip neutro', () {
        for (final t in ActivityType.values) {
          expect(c.sport(t).fg, c.text);
          expect(c.sport(t).fill, c.primary);
        }
      });

      test('esportes se separam por luminosidade no gráfico', () {
        final tons = ActivityType.values.map(c.sportShade).toList();
        for (var i = 0; i < tons.length; i++) {
          for (var j = i + 1; j < tons.length; j++) {
            expect(_contraste(tons[i], tons[j]), greaterThan(1.3));
          }
        }
      });

      test('texto de função passa 4,5:1 sobre o fundo e a superfície', () {
        final textos = [c.text, c.textMuted, c.ciano.fg, c.extra.fg, c.danger];
        for (final fg in textos) {
          expect(_contraste(fg, c.bg), greaterThanOrEqualTo(4.5));
          expect(_contraste(fg, c.surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('texto sobre botão cheio passa 4,5:1', () {
        expect(_contraste(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
        expect(_contraste(c.onFill, c.dist.fill), greaterThanOrEqualTo(4.5));
      });
    });
  }
}
