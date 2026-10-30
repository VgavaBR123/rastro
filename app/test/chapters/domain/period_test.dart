// Capitulos (F05): mes de calendario e semana de segunda a domingo, sempre
// no horario local.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/chapters/domain/period.dart';

void main() {
  test('MonthKey: anterior e seguinte atravessam a virada do ano', () {
    expect(const MonthKey(2026, 1).previous, const MonthKey(2025, 12));
    expect(const MonthKey(2025, 12).next, const MonthKey(2026, 1));
    expect(MonthKey.of(DateTime(2026, 3, 31, 23, 59)), const MonthKey(2026, 3));
  });

  test('MonthKey: codigo yyyymm vai e volta', () {
    expect(const MonthKey(2026, 10).code, 202610);
    expect(MonthKey.fromCode(202601), const MonthKey(2026, 1));
    expect(const MonthKey(2025, 12).compareTo(const MonthKey(2026, 1)), lessThan(0));
  });

  test('MonthKey: inicio e fim (exclusivo) em hora local', () {
    const m = MonthKey(2026, 12);
    expect(m.start, DateTime(2026, 12));
    expect(m.end, DateTime(2027, 1));
    expect(m.contains(DateTime(2026, 12, 31, 23, 59, 59)), isTrue);
    expect(m.contains(DateTime(2027, 1, 1)), isFalse);
  });

  test('mondayOf: semana de segunda a domingo, inclusive cruzando o mes', () {
    // 1/11/2026 e domingo: pertence a semana que comecou em 26/10.
    expect(mondayOf(DateTime(2026, 11, 1, 22)), DateTime(2026, 10, 26));
    expect(mondayOf(DateTime(2026, 10, 26, 0, 0, 1)), DateTime(2026, 10, 26));
    // Virada do ano: 1/1/2027 e sexta.
    expect(mondayOf(DateTime(2027, 1, 1, 8)), DateTime(2026, 12, 28));
  });

  test('nextMonday soma dias de calendario (horario de verao nao desloca)', () {
    var m = DateTime(2026, 1, 5);
    for (var i = 0; i < 60; i++) {
      final n = nextMonday(m);
      expect(n.weekday, DateTime.monday);
      expect(n.hour, lessThanOrEqualTo(1));
      expect(mondayOf(n.add(const Duration(hours: 12))), n);
      m = n;
    }
  });

  test('nome do mes em portugues', () {
    expect(monthName(1), 'Janeiro');
    expect(monthName(3), 'Marco');
    expect(monthName(12), 'Dezembro');
  });
}
