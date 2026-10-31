/// Horarios ISO 8601 dos arquivos GPX e TCX. Dart puro.
library;

final RegExp _hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false);

/// Epoch ms (UTC) de um horario ISO 8601 ("2026-03-01T07:00:00-03:00",
/// "...Z", com ou sem fracao de segundo). Sem fuso, vale UTC (o GPX define
/// os horarios em UTC; [DateTime.parse] trataria como hora local). Texto que
/// nao e horario devolve null.
int? parseXmlTime(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return null;
  final withZone = _hasZone.hasMatch(t) ? t : '${t}Z';
  final d = DateTime.tryParse(withZone);
  return d?.millisecondsSinceEpoch;
}
