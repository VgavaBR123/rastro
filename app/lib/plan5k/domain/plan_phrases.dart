// Falas e rotulos do plano 5 km (F06). Curtas, em portugues, com numeros
// (o TTS le "1 minuto e 30 segundos" naturalmente) e NUNCA com ritmo: o
// plano e por tempo, nao por pace, com ou sem Modo Gentil.
library;

import 'guided_engine.dart';
import 'plan_table.dart';

/// "1 minuto e 30 segundos", "2 minutos", "45 segundos".
String spokenPlanDuration(int ms) {
  final total = (ms / 1000).round();
  final m = total ~/ 60;
  final s = total % 60;
  String unit(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  final parts = [
    if (m > 0) unit(m, 'minuto', 'minutos'),
    if (s > 0 || m == 0) unit(s, 'segundo', 'segundos'),
  ];
  return parts.join(' e ');
}

/// Fala de um evento da sessao guiada.
String? planPhrase(GuidedEvent e) => switch (e) {
  BlockStarted(:final block, :final lastRun, :final resumed, :final remainingMs) =>
    resumed
        ? 'Sessao retomada. ${_verb(block.kind)} por mais '
              '${spokenPlanDuration(remainingMs)}.'
        : switch (block.kind) {
            BlockKind.warmup =>
              'Aquecimento. Caminhe por ${spokenPlanDuration(block.durationMs)}.',
            BlockKind.run =>
              '${lastRun ? 'Ultimo bloco de corrida. ' : ''}'
                  'Corra por ${spokenPlanDuration(block.durationMs)}.',
            _ => 'Caminhe por ${spokenPlanDuration(block.durationMs)}.',
          },
  TenSecondsLeft(:final next) =>
    'Faltam 10 segundos para ${next.kind.isRun ? 'correr' : 'caminhar'}.',
  Halfway() => 'Metade da sessao.',
  RunPhaseDone(:final resumed, :final remainingMs) =>
    resumed
        ? 'Sessao retomada. Caminhe por mais '
              '${spokenPlanDuration(remainingMs)} para desacelerar.'
        : 'Corridas de hoje concluidas. Caminhe '
              '${spokenPlanDuration(remainingMs)} para desacelerar.',
  SessionCompleted() => 'Plano de hoje concluido.',
};

String _verb(BlockKind k) => k.isRun ? 'Corra' : 'Caminhe';

/// Rotulo do bloco no cartao da gravacao.
String blockLabel(BlockKind k) => switch (k) {
  BlockKind.run => 'Correr',
  BlockKind.walk => 'Caminhar',
  BlockKind.warmup => 'Aquecer caminhando',
  BlockKind.cooldown => 'Desacelerar caminhando',
};

/// Rotulo curto do proximo bloco: "Correr 1 min 30 s".
String nextBlockLabel(PlanBlock b) =>
    '${blockLabel(b.kind)} ${formatPlanDuration(b.durationMs)}';
