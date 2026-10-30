// Fechamento gentil (F04): 2 ou 3 frases depois de salvar, por regras locais,
// comparando a pessoa so com ela mesma. Sem LLM, sem rede e nunca com outras
// pessoas. Dart puro e deterministico: o "agora" e o inicio da atividade.
//
// Regras, em ordem de prioridade (as 3 primeiras que valerem):
// 1. primeira atividade do esporte;
// 2. voltou depois de 7 ou mais dias sem treinar (qualquer esporte);
// 3. mais longa das ultimas 4 semanas (mesmo esporte);
// 4. mais rapida pelo ritmo medio (mesmo esporte, >= 1 km; nunca no Modo
//    Gentil);
// 5. ritmo mais constante (menor variacao entre splits, >= 3 splits);
// 6. semana com mais treinos do ultimo mes (todos os esportes);
// 7. primeira vez no horario (madrugada, manha, tarde, noite).
// Com menos de 2 frases, completa com a contagem de treinos do esporte nas
// 4 semanas e com o tempo em movimento.
library;

import 'dart:math' as math;

import '../../recording/domain/recording_models.dart';

/// Janela da comparacao.
const int kSelfComparisonDays = 28;

/// Dias sem treino a partir dos quais vale o "voltou".
const int kComebackDays = 7;

/// Distancia minima para comparar o ritmo medio.
const double kFastestMinMeters = 1000;

/// Splits minimos para comparar a constancia.
const int kConstancyMinSplits = 3;

const int _dayMs = 24 * 60 * 60 * 1000;

/// Uma atividade como as frases enxergam.
class SelfEntry {
  final String guid;
  final ActivityType type;
  final int startMs;
  final double distanceMeters;
  final int timerMs;

  /// Duracao dos splits completos (km ou milha), em ordem.
  final List<int> splitDurationsMs;

  const SelfEntry({
    required this.guid,
    required this.type,
    required this.startMs,
    required this.distanceMeters,
    required this.timerMs,
    this.splitDurationsMs = const [],
  });

  double? get _pace => distanceMeters >= kFastestMinMeters && timerMs > 0
      ? timerMs / distanceMeters
      : null;

  /// Coeficiente de variacao dos splits; null com poucos splits.
  double? get _variation {
    final s = [for (final d in splitDurationsMs) if (d > 0) d.toDouble()];
    if (s.length < kConstancyMinSplits) return null;
    final mean = s.reduce((a, b) => a + b) / s.length;
    final variance =
        s.map((d) => (d - mean) * (d - mean)).reduce((a, b) => a + b) / s.length;
    return math.sqrt(variance) / mean;
  }
}

/// Frases do fechamento (2 ou 3). [history] pode conter a propria atividade
/// (e ignorada pelo guid) e atividades de qualquer data.
List<String> selfComparisonPhrases({
  required SelfEntry current,
  required List<SelfEntry> history,
  bool gentle = false,
}) {
  final before = [
    for (final h in history)
      if (h.guid != current.guid && h.startMs < current.startMs) h,
  ]..sort((a, b) => b.startMs.compareTo(a.startMs));
  final windowStart = current.startMs - kSelfComparisonDays * _dayMs;
  final sameSport = [
    for (final h in before)
      if (h.type == current.type && h.startMs >= windowStart) h,
  ];
  final sport = _SportWords(current.type);
  final out = <String>[];

  final firstOfSport = !before.any((h) => h.type == current.type);
  if (firstOfSport) {
    out.add('${sport.seu} primeir${sport.o} ${sport.noun} registrad${sport.o} '
        'aqui. Bom comeco.');
  }

  if (before.isNotEmpty) {
    final days = _calendarDays(before.first.startMs, current.startMs);
    if (days >= kComebackDays) {
      out.add('Voce voltou depois de $days dias. Bom te ver de novo.');
    }
  }

  if (sameSport.isNotEmpty) {
    // Mais longa: por distancia; sem distancia (indoor), pelo tempo.
    final longer = current.distanceMeters > 0
        ? sameSport.every((h) => current.distanceMeters > h.distanceMeters)
        : current.timerMs > 0 && sameSport.every((h) => current.timerMs > h.timerMs);
    if (longer) {
      out.add('${sport.seu} ${sport.noun} mais long${sport.o} das ultimas 4 semanas.');
    }

    final pace = current._pace;
    final paces = [for (final h in sameSport) if (h._pace != null) h._pace!];
    if (!gentle && pace != null && paces.isNotEmpty && paces.every((p) => pace < p)) {
      out.add('${sport.seu} ${sport.noun} mais rapid${sport.o} das ultimas 4 semanas.');
    }

    final cv = current._variation;
    final cvs = [for (final h in sameSport) if (h._variation != null) h._variation!];
    if (cv != null && cvs.isNotEmpty && cvs.every((v) => cv < v)) {
      out.add('Seu ritmo mais constante das ultimas 4 semanas.');
    }
  }

  final week = _busiestWeek(current, before);
  if (week != null) {
    out.add('Sua semana com mais treinos do ultimo mes: $week ate agora.');
  }

  if (sameSport.isNotEmpty) {
    final slot = _slot(current.startMs);
    if (!sameSport.any((h) => _slot(h.startMs) == slot)) {
      out.add('Primeir${sport.o} ${sport.noun} ${_slotWords[slot]} nas ultimas 4 semanas.');
    }
  }

  if (out.length < 2 && !firstOfSport) {
    out.add('Treino numero ${sameSport.length + 1} de ${sport.noun} '
        'nas ultimas 4 semanas.');
  }
  if (out.length < 2) {
    final minutes = (current.timerMs / 60000).round();
    out.add('Foram $minutes min em movimento.');
  }
  return out.length > 3 ? out.sublist(0, 3) : out;
}

/// Treinos da semana atual (segunda a domingo, contando a atividade), se for
/// a maior das ultimas 4 semanas, com pelo menos 2 e com treino nas
/// anteriores. Null senao.
int? _busiestWeek(SelfEntry current, List<SelfEntry> before) {
  final weekStart = _startOfWeekMs(current.startMs);
  int count(int start, int end) =>
      before.where((h) => h.startMs >= start && h.startMs < end).length;
  final thisWeek = count(weekStart, current.startMs) + 1;
  if (thisWeek < 2) return null;
  var bestPrevious = 0;
  var any = false;
  for (var i = 1; i <= 3; i++) {
    final start = _shiftDaysMs(weekStart, -7 * i);
    final end = _shiftDaysMs(weekStart, -7 * (i - 1));
    final n = count(start, end);
    if (n > 0) any = true;
    bestPrevious = math.max(bestPrevious, n);
  }
  return any && thisWeek > bestPrevious ? thisWeek : null;
}

/// Dias de calendario entre duas datas (horario de verao nao tira um dia).
int _calendarDays(int fromMs, int toMs) {
  DateTime day(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.utc(d.year, d.month, d.day);
  }

  return day(toMs).difference(day(fromMs)).inDays;
}

int _startOfWeekMs(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday))
      .millisecondsSinceEpoch;
}

/// Soma dias pelo calendario (horario de verao nao desloca).
int _shiftDaysMs(int ms, int days) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day + days).millisecondsSinceEpoch;
}

/// 0 madrugada (0-5h), 1 manha (5-12h), 2 tarde (12-18h), 3 noite (18-24h).
int _slot(int ms) {
  final h = DateTime.fromMillisecondsSinceEpoch(ms).hour;
  if (h < 5) return 0;
  if (h < 12) return 1;
  if (h < 18) return 2;
  return 3;
}

const List<String> _slotWords = ['de madrugada', 'de manha', 'a tarde', 'a noite'];

/// Palavras do esporte com o genero certo.
class _SportWords {
  final String noun;
  final bool masculine;
  _SportWords(ActivityType t)
    : noun = switch (t) {
        ActivityType.run => 'corrida',
        ActivityType.ride => 'pedal',
        ActivityType.walk => 'caminhada',
      },
      masculine = t == ActivityType.ride;

  String get seu => masculine ? 'Seu' : 'Sua';
  String get o => masculine ? 'o' : 'a';
}
