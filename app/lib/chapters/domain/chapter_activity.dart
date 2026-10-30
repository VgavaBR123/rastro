// Capitulos (F05): a atividade como o capitulo enxerga. De proposito NAO tem
// titulo, descricao, trajeto nem nada que localize a pessoa: o capitulo e a
// imagem compartilhada so podem mostrar numeros agregados e marcos
// (privacidade, critica da seguranca no relatorio 12). O horario de inicio so
// serve para achar o mes, o dia e a semana; nunca e exibido.
library;

import '../../recording/domain/recording_models.dart';

class ChapterActivity {
  final ActivityType type;

  /// Inicio em hora local.
  final DateTime start;
  final double distanceMeters;

  /// Tempo em movimento (ms).
  final int timerMs;

  /// So as finalizadas entram no capitulo.
  final bool finished;

  const ChapterActivity({
    required this.type,
    required this.start,
    required this.distanceMeters,
    required this.timerMs,
    this.finished = true,
  });

  /// Distancia segura para somar (NaN, infinito e negativo viram 0).
  double get safeMeters =>
      distanceMeters.isFinite && distanceMeters > 0 ? distanceMeters : 0;

  /// Tempo seguro para somar (negativo vira 0).
  int get safeTimerMs => timerMs > 0 ? timerMs : 0;
}

/// So as finalizadas com inicio ate [now] (quando dado), em ordem de inicio.
List<ChapterActivity> finishedInOrder(
  Iterable<ChapterActivity> all, {
  DateTime? now,
}) {
  final out = [
    for (final a in all)
      if (a.finished && (now == null || !a.start.isAfter(now))) a,
  ];
  // sort do Dart nao e estavel: desempata pela posicao original.
  final index = {for (var i = 0; i < out.length; i++) out[i]: i};
  out.sort((a, b) {
    final c = a.start.compareTo(b.start);
    return c != 0 ? c : index[a]!.compareTo(index[b]!);
  });
  return out;
}
