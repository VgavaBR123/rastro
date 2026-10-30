// Imagem do capitulo (F05) com fonte grande do sistema: o cartao tem tamanho
// fixo (vira PNG 1080 x 1920), entao nao pode herdar o textScaler; sem isso
// o PNG saia cortado, sem marcos nem a marca d'agua.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/chapters/domain/chapter_pages.dart';
import 'package:strava_estudo_app/ui/chapters/chapter_share_card.dart';
import 'package:strava_estudo_app/ui/share/share_card.dart' show kShareCardSize;
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

const data = ChapterShareData(
  heading: 'Outubro de 2026',
  subheading: 'Meu capitulo',
  stats: [
    ChapterStat(label: 'Distancia', value: '140.50 km', role: ChapterStatRole.distance),
    ChapterStat(label: 'Tempo', value: '12:41:00', role: ChapterStatRole.time),
    ChapterStat(label: 'Treinos', value: '18', role: ChapterStatRole.count),
    ChapterStat(label: 'Dias ativos', value: '16', role: ChapterStatRole.days),
  ],
  milestones: ['Primeira meia maratona', 'Primeiro pedal de 100 km', '500 km na vida'],
  text: 't',
);

void main() {
  testWidgets('fonte 2x: cartao sem overflow, com marcos e marca d\'agua dentro', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ChapterShareCard(key: Key('card'), data: data),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final card = tester.getRect(find.byKey(const Key('card')));
    expect(card.size, kShareCardSize);
    final brand = find.byKey(const Key('chapter_share_brand'));
    expect(brand, findsOneWidget);
    final b = tester.getRect(brand);
    expect(card.contains(b.topLeft) && card.contains(b.bottomRight - const Offset(1, 1)), isTrue);
    expect(find.byKey(const Key('chapter_share_milestone')), findsNWidgets(3));
    for (final e in find.byKey(const Key('chapter_share_milestone')).evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(r.bottom, lessThanOrEqualTo(card.bottom));
    }
  });
}
