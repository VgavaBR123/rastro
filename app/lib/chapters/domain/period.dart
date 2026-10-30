// Capitulos (F05): mes de calendario e semana de segunda a domingo. Tudo em
// DateTime LOCAL e por datas de calendario (nunca somando 7 x 24 h), para a
// mudanca de horario de verao nao deslocar semanas nem meses. Dart puro.
library;

/// Um mes de calendario (ano + mes 1..12).
class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month;

  const MonthKey(this.year, this.month);

  factory MonthKey.of(DateTime d) => MonthKey(d.year, d.month);

  /// A partir de `yyyymm` (ex.: 202610).
  factory MonthKey.fromCode(int code) => MonthKey(code ~/ 100, code % 100);

  /// `yyyymm`, o formato guardado no banco.
  int get code => year * 100 + month;

  /// Dia 1 a 00:00 local.
  DateTime get start => DateTime(year, month);

  /// Dia 1 do mes seguinte a 00:00 local (exclusivo).
  DateTime get end => DateTime(year, month + 1);

  MonthKey get previous => MonthKey.of(DateTime(year, month - 1));
  MonthKey get next => MonthKey.of(DateTime(year, month + 1));

  bool contains(DateTime d) => d.year == year && d.month == month;

  @override
  int compareTo(MonthKey other) => code.compareTo(other.code);

  @override
  bool operator ==(Object other) =>
      other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'MonthKey($code)';
}

/// Segunda-feira 00:00 local da semana de [d].
DateTime mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

/// A segunda-feira seguinte a [monday] (por data de calendario).
DateTime nextMonday(DateTime monday) =>
    DateTime(monday.year, monday.month, monday.day + 7);

const List<String> _months = [
  'Janeiro',
  'Fevereiro',
  'Marco',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Nome do mes [month] (1..12), com inicial maiuscula.
String monthName(int month) => _months[(month - 1) % 12];
