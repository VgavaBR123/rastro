/// Banco local isolado da gravacao (Drift/SQLite). Clean room a partir de
/// relatorios/05-persistencia.md: cabecalho `activities` (equivalente a
/// UnsyncedActivity) + fluxo `waypoints` escrito de forma incremental.
///
/// O construtor aceita um QueryExecutor para permitir banco em memoria nos testes
/// (shift-left): `RecordingDatabase(NativeDatabase.memory())`.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../recording/domain/recording_models.dart';
import 'activity_visibility.dart';

export 'activity_visibility.dart';

part 'database.g.dart';

/// Cabecalho da atividade (um registro por gravacao).
class Activities extends Table {
  TextColumn get guid => text()();
  IntColumn get activityType => intEnum<ActivityType>()();
  IntColumn get startTimestampMs => integer()();
  IntColumn get endTimestampMs => integer().nullable()();
  IntColumn get timerTimeMs => integer().withDefault(const Constant(0))();
  RealColumn get distanceMeters => real().withDefault(const Constant(0))();
  RealColumn get calories => real().nullable()();
  BoolColumn get isIndoor => boolean().withDefault(const Constant(false))();
  BoolColumn get isFinished => boolean().withDefault(const Constant(false))();
  IntColumn get syncState => intEnum<SyncState>()();
  IntColumn get startBatteryLevel => integer().nullable()();
  IntColumn get endBatteryLevel => integer().nullable()();
  BoolColumn get autoPauseEnabled => boolean().withDefault(const Constant(true))();

  /// Conta dona da atividade (id do usuario no backend). Null = gravada sem
  /// conta; e reivindicada pela primeira conta que sincronizar. Impede que as
  /// pendentes de uma conta subam na conta de outra no mesmo aparelho.
  TextColumn get ownerUserId => text().nullable()();

  /// Id da atividade no servidor (devolvido pelo upload). Null = nunca subiu
  /// (ou subiu antes de guardarmos o id). Necessario para apagar la tambem.
  TextColumn get remoteId => text().nullable()();

  /// Titulo dado na tela Salvar. Null = sem titulo (a UI mostra o sugerido
  /// pelo horario). Ainda nao sobe para o servidor (o contrato de upload nao
  /// tem esse campo).
  TextColumn get title => text().nullable()();

  /// Descricao livre da tela Salvar. Null = vazia. Tambem nao sobe ainda.
  TextColumn get description => text().nullable()();

  /// Quem pode ver: 'private' | 'followers' | 'everyone' (ver
  /// [ActivityVisibility]). Privacidade automatica (F02): atividade nova
  /// nasce 'private' ("so eu"); o repositorio grava isso explicitamente no
  /// inicio, porque bancos migrados guardam o padrao antigo da coluna. As
  /// atividades antigas mantem o que tinham (a migracao que cria a coluna
  /// grava 'everyone', o padrao de antes). Por enquanto so local.
  TextColumn get visibility =>
      text().withDefault(const Constant('private'))();

  /// Privacidade (F02): ocultar os primeiros e os ultimos X metros desta
  /// atividade no que sai do aparelho (imagem, upload, exportacao). 0 = nao.
  IntColumn get hideEdgesMeters => integer().withDefault(const Constant(0))();

  /// Gravacao blindada (F01): instante (epoch ms) do ultimo batimento salvo
  /// durante a gravacao. Na recuperacao pos-crash, o intervalo dele ate a
  /// retomada vira lacuna. Null = sem batimento (atividades antigas).
  IntColumn get lastHeartbeatMs => integer().nullable()();

  /// True se o ultimo batimento foi salvo com a gravacao pausada (o tempo
  /// parado depois dele nao e lacuna).
  BoolColumn get heartbeatPaused =>
      boolean().withDefault(const Constant(false))();

  /// Pontos descartados pelo filtro de ruido (nao conta os de pausa).
  IntColumn get discardedPointCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {guid};
}

/// Lacunas da gravacao (F01): trechos com mais de 30 s sem batimento ou sem
/// ponto de GPS, gravando e sem pausa. [reason] e o indice de GapReason.
@DataClassName('RecordingGapRow')
class RecordingGaps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityGuid =>
      text().references(Activities, #guid, onDelete: KeyAction.cascade)();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
  IntColumn get reason => integer()();
}

/// Zonas de privacidade (F02): circulos guardados so no aparelho. O que
/// comeca ou termina dentro deles sai cortado do que e compartilhado.
@DataClassName('PrivacyZoneRow')
class PrivacyZones extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radiusMeters => real()();
  TextColumn get label => text()();
  IntColumn get createdAtMs => integer()();
}

/// Sugestoes de zona que a pessoa ignorou (F02): o lugar nao volta a ser
/// sugerido.
@DataClassName('DismissedZoneSuggestionRow')
class DismissedZoneSuggestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get createdAtMs => integer()();
}

/// Exclusoes que ainda precisam chegar ao servidor (apagou no aparelho sem
/// rede, ou a chamada falhou). O sync processa e remove a linha.
class RemoteDeletions extends Table {
  TextColumn get remoteId => text()();
  TextColumn get ownerUserId => text().nullable()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {remoteId};
}

/// Fluxo de pontos de uma atividade, anexado de forma incremental.
class Waypoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityGuid =>
      text().references(Activities, #guid, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitudeMeters => real().nullable()();
  RealColumn get horizontalAccuracyMeters => real().nullable()();
  RealColumn get verticalAccuracyMeters => real().nullable()();
  RealColumn get speedMetersPerSecond => real().nullable()();
  IntColumn get elapsedTimeMs => integer()();
  IntColumn get timerTimeMs => integer()();
  RealColumn get cumulativeDistanceMeters => real()();
  IntColumn get classification => integer()(); // index de WaypointClassification
}

/// Voltas (laps) marcadas pelo usuario durante a gravacao (relatorio 03: acao
/// "lap" no servico). Cada linha e uma volta fechada, em ordem de [number].
class Laps extends Table {
  TextColumn get activityGuid =>
      text().references(Activities, #guid, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()(); // 1-based
  IntColumn get startTimerMs => integer()();
  IntColumn get endTimerMs => integer()();
  IntColumn get endElapsedMs => integer()();
  RealColumn get startDistanceMeters => real()();
  RealColumn get endDistanceMeters => real()();

  @override
  Set<Column> get primaryKey => {activityGuid, number};
}

/// Preferencias do app (linha unica, id=0).
class SettingsRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get useMetric => boolean().withDefault(const Constant(true))();
  BoolColumn get autoPauseEnabled => boolean().withDefault(const Constant(true))();

  /// Peso do usuario em kg, para estimar calorias. Null = nao informado (sem
  /// calorias).
  RealColumn get weightKg => real().nullable()();

  /// Checklist "Gravacao confiavel" ja mostrado antes da primeira gravacao.
  BoolColumn get reliabilityChecklistSeen =>
      boolean().withDefault(const Constant(false))();

  /// Privacidade (F02): o FIT enviado ao servidor sai sem os pontos ocultos.
  BoolColumn get hideOnServer => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
    tables: [
      Activities,
      Waypoints,
      SettingsRows,
      RemoteDeletions,
      Laps,
      RecordingGaps,
      PrivacyZones,
      DismissedZoneSuggestions,
    ])
class RecordingDatabase extends _$RecordingDatabase {
  RecordingDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(settingsRows);
          if (from < 3) await m.addColumn(activities, activities.ownerUserId);
          if (from < 4) {
            await m.addColumn(activities, activities.remoteId);
            await m.createTable(remoteDeletions);
          }
          if (from < 5) {
            await m.createTable(laps);
            await m.addColumn(settingsRows, settingsRows.weightKg);
          }
          if (from < 6) {
            await m.addColumn(activities, activities.title);
            await m.addColumn(activities, activities.description);
            await m.addColumn(activities, activities.visibility);
            // O addColumn usa o padrao atual da coluna ('private', do F02).
            // Antes do F02 o padrao era 'everyone': as atividades que ja
            // existiam mantem esse valor.
            await customStatement("UPDATE activities SET visibility = 'everyone'");
          }
          if (from < 7) {
            await m.addColumn(activities, activities.lastHeartbeatMs);
            await m.addColumn(activities, activities.heartbeatPaused);
            await m.addColumn(activities, activities.discardedPointCount);
            await m.addColumn(
              settingsRows,
              settingsRows.reliabilityChecklistSeen,
            );
            await m.createTable(recordingGaps);
          }
          if (from < 8) {
            await m.addColumn(activities, activities.hideEdgesMeters);
            await m.addColumn(settingsRows, settingsRows.hideOnServer);
            await m.createTable(privacyZones);
            await m.createTable(dismissedZoneSuggestions);
          }
        },
        // O SQLite abre cada conexao com `foreign_keys = OFF` e o Drift nao liga
        // isso por conta propria. Sem este pragma, o `onDelete: cascade`
        // declarado em `waypoints` e apenas decorativo e apagar uma atividade
        // deixaria os pontos orfaos. O pragma vale por conexao, e `beforeOpen`
        // roda em toda abertura (depois das migrations), que e o lugar certo.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // --- Configuracoes ---

  /// Carrega as configuracoes, criando a linha padrao na primeira vez.
  Future<SettingsRow> loadSettings() async {
    final row =
        await (select(settingsRows)..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row != null) return row;
    // insertOrIgnore: duas leituras ao mesmo tempo (ex.: o provider carregando
    // e um save) nao podem estourar a chave unica.
    await into(settingsRows).insert(
      const SettingsRowsCompanion(id: Value(0)),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(settingsRows)..where((t) => t.id.equals(0))).getSingle();
  }

  /// [weightKg] usa Value: `Value(null)` apaga o peso; ausente nao mexe.
  Future<void> saveSettings({
    bool? useMetric,
    bool? autoPauseEnabled,
    Value<double?> weightKg = const Value.absent(),
    bool? reliabilityChecklistSeen,
    bool? hideOnServer,
  }) async {
    await loadSettings(); // garante a linha
    await (update(settingsRows)..where((t) => t.id.equals(0))).write(
      SettingsRowsCompanion(
        useMetric: useMetric == null ? const Value.absent() : Value(useMetric),
        autoPauseEnabled: autoPauseEnabled == null
            ? const Value.absent()
            : Value(autoPauseEnabled),
        weightKg: weightKg,
        reliabilityChecklistSeen: reliabilityChecklistSeen == null
            ? const Value.absent()
            : Value(reliabilityChecklistSeen),
        hideOnServer:
            hideOnServer == null ? const Value.absent() : Value(hideOnServer),
      ),
    );
  }

  // --- Privacidade (F02) ---

  Future<List<PrivacyZoneRow>> allPrivacyZones() =>
      (select(privacyZones)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();

  Future<int> insertPrivacyZone(PrivacyZonesCompanion zone) =>
      into(privacyZones).insert(zone);

  Future<void> deletePrivacyZone(int id) =>
      (delete(privacyZones)..where((t) => t.id.equals(id))).go();

  Future<List<DismissedZoneSuggestionRow>> allDismissedZoneSuggestions() =>
      select(dismissedZoneSuggestions).get();

  Future<void> insertDismissedZoneSuggestion(
    DismissedZoneSuggestionsCompanion row,
  ) => into(dismissedZoneSuggestions).insert(row);

  /// Primeiro e ultimo ponto aceito de cada atividade finalizada, das
  /// [limit] mais recentes. Uma linha por ponta: (guid, seq, lat, lon,
  /// inicio da atividade).
  Future<List<({String guid, int seq, double latitude, double longitude, int startMs})>>
      finishedActivityEndpoints({int limit = 100, int? atOrBeforeMs}) async {
    // O LIMIT vale so para atividades com ponto aceito: as sem GPS (esteira,
    // indoor) nao ocupam lugar na janela.
    final rows = await customSelect(
      'SELECT w.activity_guid AS guid, w.seq AS seq, w.latitude AS lat, '
      'w.longitude AS lon, a.start_timestamp_ms AS start_ms '
      'FROM waypoints w '
      'JOIN (SELECT activity_guid, MIN(seq) AS mn, MAX(seq) AS mx FROM waypoints '
      '      WHERE classification = 0 GROUP BY activity_guid) e '
      '  ON e.activity_guid = w.activity_guid AND (w.seq = e.mn OR w.seq = e.mx) '
      'JOIN (SELECT guid, start_timestamp_ms FROM activities x WHERE is_finished = 1 '
      '      AND (? IS NULL OR start_timestamp_ms <= ?) '
      '      AND EXISTS (SELECT 1 FROM waypoints y WHERE y.activity_guid = x.guid '
      '                  AND y.classification = 0) '
      '      ORDER BY start_timestamp_ms DESC LIMIT ?) a ON a.guid = w.activity_guid '
      'WHERE w.classification = 0 '
      'ORDER BY a.start_timestamp_ms DESC, w.activity_guid, w.seq',
      variables: [
        Variable<int>(atOrBeforeMs),
        Variable<int>(atOrBeforeMs),
        Variable.withInt(limit),
      ],
      readsFrom: {waypoints, activities},
    ).get();
    return [
      for (final r in rows)
        (
          guid: r.read<String>('guid'),
          seq: r.read<int>('seq'),
          latitude: r.read<double>('lat'),
          longitude: r.read<double>('lon'),
          startMs: r.read<int>('start_ms'),
        ),
    ];
  }

  // --- Gravacao blindada (F01) ---

  /// Batimento da gravacao: instante, se estava pausada e os descartes ate
  /// agora.
  Future<void> writeHeartbeat(
    String guid, {
    required int nowMs,
    required bool paused,
    required int discardedPoints,
  }) =>
      (update(activities)..where((t) => t.guid.equals(guid))).write(
        ActivitiesCompanion(
          lastHeartbeatMs: Value(nowMs),
          heartbeatPaused: Value(paused),
          discardedPointCount: Value(discardedPoints),
        ),
      );

  Future<void> insertGap(RecordingGapsCompanion gap) =>
      into(recordingGaps).insert(gap);

  Future<List<RecordingGapRow>> gapsForActivity(String guid) =>
      (select(recordingGaps)
            ..where((t) => t.activityGuid.equals(guid))
            ..orderBy([(t) => OrderingTerm(expression: t.startMs)]))
          .get();

  // --- Voltas ---

  Future<void> insertLap(LapsCompanion lap) => into(laps).insertOnConflictUpdate(lap);

  Future<List<Lap>> lapsForActivity(String guid) => (select(laps)
        ..where((t) => t.activityGuid.equals(guid))
        ..orderBy([(t) => OrderingTerm(expression: t.number)]))
      .get();

  // --- Atividade (cabecalho) ---

  Future<void> upsertActivity(ActivitiesCompanion activity) =>
      into(activities).insertOnConflictUpdate(activity);

  Stream<Activity> watchActivity(String guid) =>
      (select(activities)..where((t) => t.guid.equals(guid))).watchSingle();

  /// Atividades nao finalizadas -- base da recuperacao pos-crash (etapa 05).
  Future<List<Activity>> unfinishedActivities() =>
      (select(activities)..where((t) => t.isFinished.equals(false))).get();

  /// Atividades prontas para upload (fila da sincronizacao, etapa 06). Com
  /// [ownerUserId], so as daquela conta.
  Future<List<Activity>> pendingActivities({String? ownerUserId}) =>
      (select(activities)
            ..where((t) {
              final ready = t.isFinished.equals(true) &
                  t.syncState.equalsValue(SyncState.pending);
              return ownerUserId == null
                  ? ready
                  : ready & t.ownerUserId.equals(ownerUserId);
            }))
          .get();

  /// Atividades finalizadas sem dono passam a ser de [userId] (gravadas antes
  /// de entrar na conta). Devolve quantas.
  Future<int> claimUnownedActivities(String userId) => (update(activities)
        ..where((t) => t.isFinished.equals(true) & t.ownerUserId.isNull()))
      .write(ActivitiesCompanion(ownerUserId: Value(userId)));

  /// Devolve para a fila as atividades que nao chegaram ao servidor: `failed`
  /// (falha anterior) e `uploading` (app morto no meio do envio, que nunca
  /// sairia desse estado sozinho). Seguro porque o backend e idempotente por
  /// guid: reenviar algo que chegou devolve o mesmo upload. Devolve quantas.
  Future<int> requeueStalledUploads() => (update(activities)
        ..where((t) =>
            t.isFinished.equals(true) &
            t.syncState.isInValues([SyncState.failed, SyncState.uploading])))
      .write(const ActivitiesCompanion(syncState: Value(SyncState.pending)));

  /// Upload aceito: guarda o id do servidor e marca synced.
  Future<void> markSynced(String guid, String remoteId) =>
      (update(activities)..where((t) => t.guid.equals(guid))).write(
        ActivitiesCompanion(
          syncState: const Value(SyncState.synced),
          remoteId: Value(remoteId),
        ),
      );

  /// Exclusoes pendentes no servidor. Com [ownerUserId], so as daquela conta
  /// (e as sem dono).
  Future<List<RemoteDeletion>> pendingRemoteDeletions({String? ownerUserId}) =>
      (select(remoteDeletions)
            ..where((t) => ownerUserId == null
                ? const Constant(true)
                : t.ownerUserId.equals(ownerUserId) | t.ownerUserId.isNull()))
          .get();

  Future<void> removeRemoteDeletion(String remoteId) =>
      (delete(remoteDeletions)..where((t) => t.remoteId.equals(remoteId))).go();

  /// Atualiza o estagio de sincronizacao de uma atividade.
  Future<void> setSyncState(String guid, SyncState state) =>
      (update(activities)..where((t) => t.guid.equals(guid)))
          .write(ActivitiesCompanion(syncState: Value(state)));

  /// Atividades finalizadas, mais recentes primeiro (historico).
  Future<List<Activity>> recentActivities({int limit = 50}) =>
      (select(activities)
            ..where((t) => t.isFinished.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.startTimestampMs)])
            ..limit(limit))
          .get();

  /// Grava o que o usuario preencheu na tela Salvar. Titulo e descricao
  /// vazios (ou so espacos) viram null.
  Future<void> saveActivityDetails(
    String guid, {
    String? title,
    String? description,
    required ActivityVisibility visibility,
    int? hideEdgesMeters,
  }) {
    String? clean(String? v) {
      final t = v?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    return (update(activities)..where((t) => t.guid.equals(guid))).write(
      ActivitiesCompanion(
        title: Value(clean(title)),
        description: Value(clean(description)),
        visibility: Value(visibility.dbValue),
        hideEdgesMeters: hideEdgesMeters == null
            ? const Value.absent()
            : Value(hideEdgesMeters < 0 ? 0 : hideEdgesMeters),
      ),
    );
  }

  Future<void> markFinished(
    String guid,
    int endTimestampMs, {
    int? endBattery,
    double? distanceMeters,
    int? timerTimeMs,
    double? calories,
  }) {
    return (update(activities)..where((t) => t.guid.equals(guid))).write(
      ActivitiesCompanion(
        isFinished: const Value(true),
        syncState: const Value(SyncState.pending),
        endTimestampMs: Value(endTimestampMs),
        endBatteryLevel: Value(endBattery),
        distanceMeters:
            distanceMeters == null ? const Value.absent() : Value(distanceMeters),
        timerTimeMs: timerTimeMs == null ? const Value.absent() : Value(timerTimeMs),
        calories: calories == null ? const Value.absent() : Value(calories),
      ),
    );
  }

  /// Apaga uma atividade do historico. Os `waypoints` saem junto pela FK em
  /// cascata (habilitada em `beforeOpen`). Se ela ja estava no servidor, a
  /// exclusao de la entra na fila na mesma transacao: nunca fica uma atividade
  /// apagada aqui e esquecida la.
  Future<void> deleteActivity(String guid, {required int nowMs}) {
    return transaction(() async {
      final a = await (select(activities)..where((t) => t.guid.equals(guid)))
          .getSingleOrNull();
      if (a == null) return;
      if (a.remoteId != null) {
        await into(remoteDeletions).insertOnConflictUpdate(
          RemoteDeletionsCompanion.insert(
            remoteId: a.remoteId!,
            ownerUserId: Value(a.ownerUserId),
            createdAtMs: nowMs,
          ),
        );
      }
      await (delete(activities)..where((t) => t.guid.equals(guid))).go();
    });
  }

  // --- Fluxo de waypoints ---

  Future<void> appendWaypoint(WaypointsCompanion wp) =>
      into(waypoints).insert(wp);

  /// Escrita em lote (eficiente para batching, etapa 05).
  Future<void> appendWaypoints(List<WaypointsCompanion> wps) =>
      batch((b) => b.insertAll(waypoints, wps));

  /// Pontos de uma atividade, em ordem -- usado no replay de recuperacao.
  Future<List<Waypoint>> waypointsForActivity(String guid) =>
      (select(waypoints)
            ..where((t) => t.activityGuid.equals(guid))
            ..orderBy([(t) => OrderingTerm(expression: t.seq)]))
          .get();
}

QueryExecutor _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'recording.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
