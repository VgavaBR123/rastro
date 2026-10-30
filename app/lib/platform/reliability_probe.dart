// Borda do checklist "Gravacao confiavel" (F01): le o estado real do aparelho
// (bateria, localizacao, notificacoes, fabricante) e executa a acao de cada
// item. Interface fina para a tela ser testada com fake.
library;

import '../recording/domain/reliability_checklist.dart';

abstract class ReliabilityProbe {
  /// Estado atual. Nunca lanca: o que nao der para ler vem null/unknown.
  Future<ReliabilitySnapshot> read();

  /// Executa a acao de um item. Devolve se abriu/pediu algo.
  Future<bool> run(ChecklistAction action);
}

/// Sem plataforma (testes no host, web): nada a conferir.
class NoopReliabilityProbe implements ReliabilityProbe {
  const NoopReliabilityProbe();

  @override
  Future<ReliabilitySnapshot> read() async =>
      const ReliabilitySnapshot(platform: DevicePlatform.other);

  @override
  Future<bool> run(ChecklistAction action) async => false;
}
