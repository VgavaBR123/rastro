/// Textos e ritmo dos anuncios ao leitor de tela da tela Seus dados (F07).
/// O progresso e anunciado em degraus (a cada 10% ou a cada 5 s), nunca a
/// cada item; o fim sempre. Dart puro.
library;

import 'import_service.dart';

/// Intervalo maximo entre dois anuncios de progresso.
const Duration kAnnounceEvery = Duration(seconds: 5);

class ProgressAnnouncer {
  final String label;
  int _lastBucket = 0;
  DateTime? _lastAt;

  ProgressAnnouncer(this.label);

  /// Texto a anunciar agora, ou null. Chame a cada mudanca de progresso.
  String? next(int done, int total, DateTime now) {
    if (total <= 0) return null;
    final bucket = (done * 10) ~/ total;
    _lastAt ??= now;
    final due = now.difference(_lastAt!) >= kAnnounceEvery;
    if (bucket > _lastBucket || (due && done > 0)) {
      _lastBucket = bucket;
      _lastAt = now;
      return '$label: $done de $total';
    }
    return null;
  }
}

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// "Importacao concluida: 2 importadas, 1 com erro" (ou cancelada/interrompida).
String importEndAnnouncement(ImportSummary s) {
  final head = s.interrupted
      ? 'Importacao interrompida'
      : s.cancelled
      ? 'Importacao cancelada'
      : 'Importacao concluida';
  return '$head: ${_plural(s.imported, 'importada', 'importadas')}, ${s.errors.length} com erro';
}
