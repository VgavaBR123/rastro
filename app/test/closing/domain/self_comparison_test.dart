// Fechamento gentil (F04): frases por regras locais que comparam a pessoa com
// ela mesma (ultimas 4 semanas do mesmo esporte), sem LLM e sem comparar com
// outras pessoas. Dart puro, sem relogio: o "agora" e o inicio da atividade.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/closing/domain/self_comparison.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

// Quinta-feira, 22/10/2026 07:00 (hora local): manha.
final DateTime now = DateTime(2026, 10, 22, 7);

int _n = 0;
SelfEntry e(
  DateTime start, {
  ActivityType type = ActivityType.run,
  double km = 5,
  int min = 30,
  List<int> splitsS = const [],
}) => SelfEntry(
  guid: 'g${_n++}',
  type: type,
  startMs: start.millisecondsSinceEpoch,
  distanceMeters: km * 1000,
  timerMs: min * 60000,
  splitDurationsMs: [for (final s in splitsS) s * 1000],
);

DateTime daysAgo(int d, {int hour = 7}) =>
    DateTime(now.year, now.month, now.day - d, hour);

List<String> phrases(SelfEntry current, List<SelfEntry> history, {bool gentle = false}) =>
    selfComparisonPhrases(current: current, history: history, gentle: gentle);

void main() {
  test('sempre de 2 a 3 frases', () {
    final current = e(now);
    expect(phrases(current, []).length, inInclusiveRange(2, 3));
    final rich = [
      for (var i = 1; i <= 10; i++) e(daysAgo(i * 2), km: 3, min: 30),
    ];
    final out = phrases(e(now, km: 10, min: 50), rich);
    expect(out.length, inInclusiveRange(2, 3));
  });

  test('primeira atividade do esporte', () {
    final out = phrases(e(now, type: ActivityType.ride), [e(daysAgo(2))]);
    expect(out.first, 'Seu primeiro pedal registrado aqui. Bom comeco.');
  });

  test('mais longa das ultimas 4 semanas (mesmo esporte)', () {
    final history = [
      e(daysAgo(3), km: 5),
      e(daysAgo(10), km: 8),
      // Outro esporte nao entra na comparacao.
      e(daysAgo(4), type: ActivityType.ride, km: 40),
      // Fora da janela de 4 semanas nao conta.
      e(daysAgo(40), km: 21),
    ];
    final out = phrases(e(now, km: 9, min: 60), history);
    expect(out, contains('Sua corrida mais longa das ultimas 4 semanas.'));
  });

  test('nao e a mais longa: sem a frase', () {
    final out = phrases(e(now, km: 4), [e(daysAgo(3), km: 5)]);
    expect(out.any((p) => p.contains('mais longa')), isFalse);
  });

  test('mais rapida pelo ritmo medio; pedal no masculino', () {
    final history = [e(daysAgo(2), km: 5, min: 30), e(daysAgo(5), km: 5, min: 28)];
    final out = phrases(e(now, km: 5, min: 26), history);
    expect(out, contains('Sua corrida mais rapida das ultimas 4 semanas.'));

    final rides = [e(daysAgo(2), type: ActivityType.ride, km: 20, min: 60)];
    final r = phrases(e(now, type: ActivityType.ride, km: 20, min: 50), rides);
    expect(r, contains('Seu pedal mais rapido das ultimas 4 semanas.'));
  });

  test('mais rapida exige pelo menos 1 km', () {
    final history = [e(daysAgo(2), km: 5, min: 30)];
    final out = phrases(e(now, km: 0.5, min: 2), history);
    expect(out.any((p) => p.contains('mais rapid')), isFalse);
  });

  test('Modo Gentil nunca fala de rapidez', () {
    final history = [e(daysAgo(2), km: 5, min: 30)];
    final out = phrases(e(now, km: 5, min: 20), history, gentle: true);
    expect(out.any((p) => p.contains('rapid')), isFalse);
  });

  test('mais constante: menor variacao entre os splits', () {
    final history = [e(daysAgo(2), splitsS: [300, 330, 290, 350])];
    final out = phrases(
      e(now, km: 4, min: 21, splitsS: [310, 312, 309, 311]),
      history,
    );
    expect(out, contains('Seu ritmo mais constante das ultimas 4 semanas.'));
  });

  test('constancia precisa de 3 splits dos dois lados', () {
    final history = [e(daysAgo(2), splitsS: [300, 330])];
    final out = phrases(e(now, splitsS: [310, 311, 309]), history);
    expect(out.any((p) => p.contains('constante')), isFalse);
  });

  test('voltou depois de X dias parado (qualquer esporte)', () {
    final history = [e(daysAgo(12), km: 3)];
    final out = phrases(e(now, km: 2), history);
    expect(out.first, 'Voce voltou depois de 12 dias. Bom te ver de novo.');
  });

  test('menos de 7 dias nao e "voltou"', () {
    final out = phrases(e(now), [e(daysAgo(6))]);
    expect(out.any((p) => p.startsWith('Voce voltou')), isFalse);
  });

  test('semana com mais atividades do ultimo mes', () {
    // Semana atual (seg 19/10): terca, quarta e agora = 3 treinos.
    final history = [
      e(daysAgo(2), km: 1),
      e(daysAgo(1), type: ActivityType.walk, km: 1),
      // Semanas anteriores: no maximo 2.
      e(daysAgo(8), km: 1),
      e(daysAgo(9), km: 1),
      e(daysAgo(16), km: 1),
    ];
    final out = phrases(e(now, km: 1, min: 5), history);
    expect(out, contains('Sua semana com mais treinos do ultimo mes: 3 ate agora.'));
  });

  test('primeira vez no horario', () {
    final history = [e(daysAgo(2, hour: 7)), e(daysAgo(5, hour: 8))];
    final night = DateTime(now.year, now.month, now.day, 20);
    final out = phrases(e(night, km: 1), history);
    expect(out, contains('Primeira corrida a noite nas ultimas 4 semanas.'));
  });

  test('a atividade atual no historico e ignorada', () {
    final current = e(now, km: 9);
    final out = phrases(current, [current, e(daysAgo(3), km: 5)]);
    expect(out, contains('Sua corrida mais longa das ultimas 4 semanas.'));
  });

  test('complemento quando nao ha destaque: contagem e tempo', () {
    final history = [e(daysAgo(2, hour: 7), km: 10, min: 50)];
    final out = phrases(e(now, km: 5, min: 32), history);
    expect(out, [
      'Treino numero 2 de corrida nas ultimas 4 semanas.',
      'Foram 32 min em movimento.',
    ]);
  });

  test('prioridade: voltou, mais longa, mais rapida; corta em 3', () {
    final history = [e(daysAgo(9), km: 3, min: 20)];
    final night = DateTime(now.year, now.month, now.day, 21);
    final out = phrases(e(night, km: 6, min: 30), history);
    expect(out, [
      'Voce voltou depois de 9 dias. Bom te ver de novo.',
      'Sua corrida mais longa das ultimas 4 semanas.',
      'Sua corrida mais rapida das ultimas 4 semanas.',
    ]);
  });

  test('frases nunca citam outras pessoas', () {
    final history = [for (var i = 1; i < 20; i++) e(daysAgo(i), km: i.toDouble())];
    final out = phrases(e(now, km: 30, min: 200), history);
    for (final p in out) {
      expect(p.toLowerCase(), isNot(contains('outros')));
      expect(p.toLowerCase(), isNot(contains('media dos')));
    }
  });
}
