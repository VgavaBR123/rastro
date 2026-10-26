// Orquestracao da fila de upload (clean room, relatorios/06-sincronizacao.md).
//
// A fila e a propria tabela de atividades: pendentes (isFinished=true,
// syncState=pending) sao lidas de uma vez e processadas uma a uma. O ciclo de
// vida de estado espelha o relatorio 06: pending -> uploading -> synced, ou
// uploading -> failed (fica na fila para o retry/backoff do agendador externo,
// ex.: WorkManager/equivalente). Uma falha isolada nao aborta o lote.
library;

import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/fit_activity_builder.dart';

/// Processa a fila de atividades pendentes, enviando o FIT de cada uma.
class SyncService {
  final RecordingDatabase _db;
  final ActivityUploader _uploader;

  SyncService(RecordingDatabase db, ActivityUploader uploader)
      : _db = db,
        _uploader = uploader;

  /// Prepara uma rodada da conta [userId]: devolve para a fila o que falhou
  /// ou ficou preso em `uploading` e reivindica as atividades gravadas sem
  /// conta. Quem dispara uma rodada (manual ou de fundo) chama isto antes de
  /// [processPending].
  Future<void> prepareRound(String userId) async {
    await _db.requeueStalledUploads();
    await _db.claimUnownedActivities(userId);
  }

  /// Percorre todas as atividades pendentes e tenta enviar cada uma. Devolve
  /// quantas foram sincronizadas com sucesso. Falhas sao marcadas como failed
  /// e nao interrompem o lote.
  ///
  /// Com [ownerUserId], so as atividades daquela conta: as de outra conta que
  /// usou o aparelho ficam paradas ate ela entrar de novo.
  Future<int> processPending({String? ownerUserId}) async {
    final List<Activity> pending =
        await _db.pendingActivities(ownerUserId: ownerUserId);
    int synced = 0;
    for (final Activity activity in pending) {
      try {
        await syncOne(activity);
        synced++;
      } on Object {
        // syncOne ja marcou failed; segue para a proxima da fila.
      }
    }
    return synced;
  }

  /// Envia uma atividade: marca uploading, monta o FIT, envia e marca synced.
  /// Em qualquer falha, marca failed e relanca para o chamador (processPending
  /// apenas conta; um worker avulso pode decidir o retry).
  Future<void> syncOne(Activity a) async {
    await _db.setSyncState(a.guid, SyncState.uploading);
    try {
      final fitBytes = await buildActivityFit(_db, a);
      await _uploader.upload(fitBytes, activityGuid: a.guid);
      await _db.setSyncState(a.guid, SyncState.synced);
    } on Object {
      await _db.setSyncState(a.guid, SyncState.failed);
      rethrow;
    }
  }
}
