// Sync automatico em segundo plano (clean room, relatorios/06-sincronizacao.md).
//
// O agendador do sistema (WorkManager no Android, BGTaskScheduler no iOS, via
// pacote `workmanager`) acorda o app num isolate de fundo e chama
// [callbackDispatcher]. Ali abrimos o banco local, processamos a fila de
// pendentes com o mesmo SyncService do sync manual e devolvemos true/false.
// Retornar false faz o WorkManager re-tentar com backoff.
//
// A logica testavel ([runBackgroundSync] e [performBackgroundSync]) nao
// depende do plugin: os testes usam banco em memoria e uploader falso.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:strava_estudo_app/app/providers.dart' show kSyncBaseUrl;
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/dio_activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

/// Valor padrao de `SYNC_BASE_URL` quando nenhum backend foi configurado no
/// build. Com ele nao ha para onde enviar, entao nada e agendado.
const String kUnconfiguredSyncBaseUrl = 'https://example.invalid';

/// Diz se ha um backend de verdade configurado para receber os uploads.
bool isSyncBackendConfigured(String baseUrl) =>
    baseUrl.isNotEmpty && baseUrl != kUnconfiguredSyncBaseUrl;

/// Uma rodada de sync de fundo sobre um banco ja aberto.
///
/// Re-enfileira o que falhou ou ficou preso em `uploading`, processa todos os pendentes e devolve
/// true se tudo foi enviado (ou se nao havia nada), false se alguma atividade
/// falhou ou se houve erro inesperado — nesse caso o agendador re-tenta com
/// backoff. Nunca lanca.
Future<bool> runBackgroundSync(RecordingDatabase db, SyncService service) async {
  try {
    await service.requeueStalled();
    final int pending = (await db.pendingActivities()).length;
    if (pending == 0) return true;
    final int synced = await service.processPending();
    return synced == pending;
  } on Object catch (e) {
    debugPrint('[background-sync] erro inesperado: $e');
    return false;
  }
}

/// Executa uma rodada completa: abre o banco, sincroniza e fecha o banco,
/// mesmo em caso de erro. As fabricas existem para os testes injetarem banco
/// em memoria e uploader falso; em producao abrem o arquivo real e o Dio.
///
/// Sem backend configurado, ou sem usuario logado, devolve true sem tocar no
/// banco: nao ha o que re-tentar ate o usuario entrar na conta (o login
/// agenda uma rodada).
Future<bool> performBackgroundSync({
  String baseUrl = kSyncBaseUrl,
  Future<String?> Function()? readToken,
  RecordingDatabase Function()? openDatabase,
  ActivityUploader Function(String baseUrl, String token)? createUploader,
}) async {
  if (!isSyncBackendConfigured(baseUrl)) return true;

  RecordingDatabase? db;
  try {
    final String? token = await (readToken ?? _readStoredToken)();
    if (token == null) return true;
    db = (openDatabase ?? RecordingDatabase.new)();
    final ActivityUploader uploader = createUploader != null
        ? createUploader(baseUrl, token)
        : DioActivityUploader(Dio(), baseUrl, token: () async => token);
    return await runBackgroundSync(db, SyncService(db, uploader));
  } on Object catch (e) {
    debugPrint('[background-sync] falha ao preparar o sync: $e');
    return false;
  } finally {
    try {
      await db?.close();
    } on Object catch (e) {
      debugPrint('[background-sync] falha ao fechar o banco: $e');
    }
  }
}

Future<String?> _readStoredToken() async =>
    (await SecureSessionStore().read())?.token;

/// Ponto de entrada chamado pelo sistema no isolate de fundo. Precisa ser
/// top-level e marcado como entry point para nao ser removido pelo tree
/// shaking do build AOT.
///
/// So existe um tipo de trabalho (sincronizar a fila), entao o nome da tarefa
/// e ignorado: periodico, one-off e o fetch do iOS fazem a mesma coisa.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) {
    return performBackgroundSync();
  });
}
