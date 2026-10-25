// Contrato de transporte do upload de uma atividade (clean room,
// relatorios/06-sincronizacao.md). Abstrai o "enviar arquivo FIT e receber um
// identificador de upload", para que o SyncService nao dependa de um cliente
// HTTP concreto (facilita teste e troca de backend).
library;

import 'dart:typed_data';

/// Transporte do upload de uma atividade ja serializada em FIT.
abstract class ActivityUploader {
  /// Envia o arquivo FIT e devolve um uploadId. Lanca em caso de falha.
  Future<String> upload(Uint8List fitBytes, {required String activityGuid});
}

/// Falha de upload (rede, status != 2xx, resposta invalida). O SyncService
/// traduz isso para SyncState.failed e deixa a atividade na fila para retry.
class UploadException implements Exception {
  final String message;
  UploadException(this.message);
  @override
  String toString() => 'UploadException: $message';
}
