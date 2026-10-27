// Contrato de transporte do upload de uma atividade (clean room,
// relatorios/06-sincronizacao.md). Abstrai o "enviar arquivo FIT e receber um
// identificador de upload", para que o SyncService nao dependa de um cliente
// HTTP concreto (facilita teste e troca de backend).
library;

import 'dart:typed_data';

/// Metadados calculados no aparelho que o FIT minimo nao carrega (contrato:
/// headers x-activity-type, x-start-time, x-timer-time-ms, x-distance-meters).
class UploadMetadata {
  final String? activityType; // run | ride | walk
  final int? startTimeMs;
  final int? timerTimeMs;
  final double? distanceMeters;

  const UploadMetadata({
    this.activityType,
    this.startTimeMs,
    this.timerTimeMs,
    this.distanceMeters,
  });
}

/// Transporte do upload de uma atividade ja serializada em FIT.
abstract class ActivityUploader {
  /// Envia o arquivo FIT e devolve o id da atividade no servidor. Lanca em
  /// caso de falha.
  Future<String> upload(
    Uint8List fitBytes, {
    required String activityGuid,
    UploadMetadata? metadata,
  });
}

/// Apaga uma atividade no servidor. Ja apagada (404) conta como sucesso.
/// Separado do upload para os fakes de teste nao precisarem implementar.
abstract class RemoteActivityDeleter {
  Future<void> deleteRemote(String remoteId);
}

/// Falha de upload (rede, status != 2xx, resposta invalida). O SyncService
/// traduz isso para SyncState.failed e deixa a atividade na fila para retry.
class UploadException implements Exception {
  final String message;
  UploadException(this.message);
  @override
  String toString() => 'UploadException: $message';
}

/// O servidor recusou a sessao (sem login, token revogado ou expirado). A
/// atividade continua na fila; volta a subir depois que o usuario entrar.
class UnauthorizedUploadException extends UploadException {
  UnauthorizedUploadException() : super('sessao invalida ou ausente (401)');
}
