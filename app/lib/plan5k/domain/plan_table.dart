// Plano Do Zero aos 5 km (F06): tabela FIXA de 10 semanas x 3 sessoes,
// escrita por nos (progressao propria, nao copiada de programa existente).
//
// Toda sessao: 5 min de caminhada para aquecer, blocos alternados de correr
// e caminhar (abrindo e fechando com corrida) e 5 min de caminhada para
// desacelerar. A corrida cresce aos poucos (nunca cai mais de 10% de uma
// sessao para a seguinte) ate 30 min continuos na ultima sessao. Dart puro.
library;

/// Tipo do bloco. Aquecimento e desaquecimento sao caminhada.
enum BlockKind {
  warmup,
  run,
  walk,
  cooldown;

  bool get isRun => this == BlockKind.run;
}

class PlanBlock {
  final BlockKind kind;
  final int durationMs;
  const PlanBlock(this.kind, this.durationMs);

  @override
  String toString() => 'PlanBlock($kind, $durationMs)';
}

/// Uma sessao do plano: semana 1..10, sessao 1..3 e os blocos em ordem.
class PlanSession {
  final int week;
  final int number;
  final List<PlanBlock> blocks;

  const PlanSession({
    required this.week,
    required this.number,
    required this.blocks,
  });

  /// Posicao na tabela (0..29).
  int get index => (week - 1) * 3 + (number - 1);

  int get totalMs => blocks.fold(0, (a, b) => a + b.durationMs);

  /// Tempo de plano para a sessao contar como concluida: todos os blocos de
  /// corrida e caminhada terminados, isto e, a chegada no desaquecimento. O
  /// desaquecimento e recomendado, mas nao obrigatorio.
  int get requiredMs {
    final last = blocks.isEmpty ? null : blocks.last;
    return last != null && last.kind == BlockKind.cooldown
        ? totalMs - last.durationMs
        : totalMs;
  }

  int get runMs => blocks
      .where((b) => b.kind.isRun)
      .fold(0, (a, b) => a + b.durationMs);

  String get label => 'Semana $week, sessao $number';

  /// Resumo dos blocos de corrida, sem o aquecimento e o desaquecimento.
  /// Ex.: "8 x (1 min correndo + 1 min 30 s caminhando)".
  String get summary {
    final runs = [for (final b in blocks) if (b.kind == BlockKind.run) b.durationMs];
    final walks = [for (final b in blocks) if (b.kind == BlockKind.walk) b.durationMs];
    if (runs.length == 1) {
      return '${formatPlanDuration(runs.single)} correndo sem parar';
    }
    final sameRuns = runs.every((r) => r == runs.first);
    final walk = formatPlanDuration(walks.first);
    if (sameRuns) {
      return '${runs.length} x (${formatPlanDuration(runs.first)} correndo + '
          '$walk caminhando)';
    }
    return '${runs.map(formatPlanDuration).join(' + ')} correndo, com $walk '
        'caminhando entre elas';
  }
}

/// "1 min 30 s", "5 min", "45 s".
String formatPlanDuration(int ms) {
  final total = ms ~/ 1000;
  final m = total ~/ 60;
  final s = total % 60;
  if (m == 0) return '$s s';
  if (s == 0) return '$m min';
  return '$m min $s s';
}

const int _warmMs = 5 * 60000;

/// Monta a sessao: aquecimento, corridas de [runsS] segundos separadas por
/// [walkS] segundos caminhando, e desaquecimento.
PlanSession _session(int week, int number, List<int> runsS, int walkS) {
  final blocks = <PlanBlock>[const PlanBlock(BlockKind.warmup, _warmMs)];
  for (var i = 0; i < runsS.length; i++) {
    if (i > 0) blocks.add(PlanBlock(BlockKind.walk, walkS * 1000));
    blocks.add(PlanBlock(BlockKind.run, runsS[i] * 1000));
  }
  blocks.add(const PlanBlock(BlockKind.cooldown, _warmMs));
  return PlanSession(week: week, number: number, blocks: List.unmodifiable(blocks));
}

List<int> _times(int n, int s) => List.filled(n, s);

/// As 30 sessoes. Corrida total por sessao (min): 8, 8, 9 | 9, 10.5, 12 |
/// 12, 14, 15 | 15, 18, 20 | 20, 20, 24 | 24, 24, 25 | 26, 24, 25 |
/// 27, 26, 27 | 27, 28, 28 | 27, 28, 30.
final List<PlanSession> kPlan5k = List.unmodifiable([
  _session(1, 1, _times(8, 60), 90),
  _session(1, 2, _times(8, 60), 90),
  _session(1, 3, _times(9, 60), 90),
  _session(2, 1, _times(6, 90), 120),
  _session(2, 2, _times(7, 90), 90),
  _session(2, 3, _times(8, 90), 90),
  _session(3, 1, _times(6, 120), 90),
  _session(3, 2, _times(7, 120), 90),
  _session(3, 3, _times(6, 150), 90),
  _session(4, 1, _times(5, 180), 90),
  _session(4, 2, _times(6, 180), 90),
  _session(4, 3, _times(5, 240), 90),
  _session(5, 1, _times(4, 300), 90),
  _session(5, 2, _times(4, 300), 60),
  _session(5, 3, _times(4, 360), 90),
  _session(6, 1, _times(3, 480), 90),
  _session(6, 2, _times(3, 480), 60),
  _session(6, 3, [600, 600, 300], 90),
  _session(7, 1, [600, 600, 360], 90),
  _session(7, 2, [720, 720], 120),
  _session(7, 3, [900, 600], 120),
  _session(8, 1, [900, 720], 120),
  _session(8, 2, [1080, 480], 120),
  _session(8, 3, [1200, 420], 120),
  _session(9, 1, [1320, 300], 120),
  _session(9, 2, [1500, 180], 90),
  _session(9, 3, [1560, 120], 60),
  _session(10, 1, [1620], 0),
  _session(10, 2, [1680], 0),
  _session(10, 3, [1800], 0),
]);

const int kPlanWeeks = 10;
const int kSessionsPerWeek = 3;

/// Sessao [number] (1..3) da semana [week] (1..10).
PlanSession sessionAt(int week, int number) => kPlan5k[(week - 1) * 3 + (number - 1)];
