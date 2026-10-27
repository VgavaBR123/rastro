// Servico de gravacao em primeiro plano (relatorio 03: um unico foreground
// service de tipo `location`, notificacao persistente, controle por acoes
// start/stop/pause/resume/lap reaproveitado pela notificacao).
//
// Interface fina para o RecordingController: o servico so mantem o processo
// vivo e traduz toques da notificacao em comandos. A gravacao em si (GPS,
// dominio, banco) continua no isolate principal.
library;

/// Acoes que a notificacao (ou outro controle externo) pode pedir.
enum RecordingCommand { pause, resume, lap, stop }

/// Conteudo da notificacao da gravacao.
class RecordingNotification {
  final String title;
  final String text;

  /// Define o botao alternado: "Retomar" quando pausado, "Pausar" senao.
  final bool paused;

  const RecordingNotification({
    required this.title,
    required this.text,
    required this.paused,
  });

  @override
  bool operator ==(Object other) =>
      other is RecordingNotification &&
      other.title == title &&
      other.text == text &&
      other.paused == paused;

  @override
  int get hashCode => Object.hash(title, text, paused);
}

abstract class RecordingService {
  /// Comandos vindos da notificacao.
  Stream<RecordingCommand> get commands;

  /// Sobe o servico em primeiro plano com a notificacao inicial. Nunca lanca:
  /// sem servico a gravacao continua (so perde a garantia em segundo plano).
  Future<void> start(RecordingNotification notification);

  /// Atualiza texto e botoes da notificacao.
  Future<void> update(RecordingNotification notification);

  /// Derruba o servico e remove a notificacao.
  Future<void> stop();
}

/// Sem servico (iOS, que usa as background modes de localizacao; testes).
class NoopRecordingService implements RecordingService {
  const NoopRecordingService();

  @override
  Stream<RecordingCommand> get commands => const Stream.empty();

  @override
  Future<void> start(RecordingNotification notification) async {}

  @override
  Future<void> update(RecordingNotification notification) async {}

  @override
  Future<void> stop() async {}
}
