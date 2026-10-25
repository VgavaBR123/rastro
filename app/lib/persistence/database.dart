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

  @override
  Set<Column> get primaryKey => {guid};
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

/// Preferencias do app (linha unica, id=0).
class SettingsRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get useMetric => boolean().withDefault(const Constant(true))();
  BoolColumn get autoPauseEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Activities, Waypoints, SettingsRows])
class RecordingDatabase extends _$RecordingDatabase {
  RecordingDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(settingsRows);
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
    await into(settingsRows).insert(const SettingsRowsCompanion(id: Value(0)));
    return (select(settingsRows)..where((t) => t.id.equals(0))).getSingle();
  }

  Future<void> saveSettings({bool? useMetric, bool? autoPauseEnabled}) async {
    await loadSettings(); // garante a linha
    await (update(settingsRows)..where((t) => t.id.equals(0))).write(
      SettingsRowsCompanion(
        useMetric: useMetric == null ? const Value.absent() : Value(useMetric),
        autoPauseEnabled: autoPauseEnabled == null
            ? const Value.absent()
            : Value(autoPauseEnabled),
      ),
    );
  }

  // --- Atividade (cabecalho) ---

  Future<void> upsertActivity(ActivitiesCompanion activity) =>
      into(activities).insertOnConflictUpdate(activity);

  Stream<Activity> watchActivity(String guid) =>
      (select(activities)..where((t) => t.guid.equals(guid))).watchSingle();

  /// Atividades nao finalizadas -- base da recuperacao pos-crash (etapa 05).
  Future<List<Activity>> unfinishedActivities() =>
      (select(activities)..where((t) => t.isFinished.equals(false))).get();

  /// Atividades prontas para upload (fila da sincronizacao, etapa 06).
  Future<List<Activity>> pendingActivities() => (select(activities)
        ..where((t) =>
            t.isFinished.equals(true) & t.syncState.equalsValue(SyncState.pending)))
      .get();

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

  Future<void> markFinished(
    String guid,
    int endTimestampMs, {
    int? endBattery,
    double? distanceMeters,
    int? timerTimeMs,
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
      ),
    );
  }

  /// Apaga uma atividade do historico. Os `waypoints` saem junto pela FK em
  /// cascata (habilitada em `beforeOpen`); a transacao garante que cabecalho e
  /// pontos saiam de uma vez.
  Future<void> deleteActivity(String guid) {
    return transaction(() async {
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
