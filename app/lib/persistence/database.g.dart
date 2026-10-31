// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityType, int> activityType =
      GeneratedColumn<int>(
        'activity_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ActivityType>($ActivitiesTable.$converteractivityType);
  static const VerificationMeta _startTimestampMsMeta = const VerificationMeta(
    'startTimestampMs',
  );
  @override
  late final GeneratedColumn<int> startTimestampMs = GeneratedColumn<int>(
    'start_timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimestampMsMeta = const VerificationMeta(
    'endTimestampMs',
  );
  @override
  late final GeneratedColumn<int> endTimestampMs = GeneratedColumn<int>(
    'end_timestamp_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timerTimeMsMeta = const VerificationMeta(
    'timerTimeMs',
  );
  @override
  late final GeneratedColumn<int> timerTimeMs = GeneratedColumn<int>(
    'timer_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isIndoorMeta = const VerificationMeta(
    'isIndoor',
  );
  @override
  late final GeneratedColumn<bool> isIndoor = GeneratedColumn<bool>(
    'is_indoor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_indoor" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFinishedMeta = const VerificationMeta(
    'isFinished',
  );
  @override
  late final GeneratedColumn<bool> isFinished = GeneratedColumn<bool>(
    'is_finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<SyncState>($ActivitiesTable.$convertersyncState);
  static const VerificationMeta _startBatteryLevelMeta = const VerificationMeta(
    'startBatteryLevel',
  );
  @override
  late final GeneratedColumn<int> startBatteryLevel = GeneratedColumn<int>(
    'start_battery_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endBatteryLevelMeta = const VerificationMeta(
    'endBatteryLevel',
  );
  @override
  late final GeneratedColumn<int> endBatteryLevel = GeneratedColumn<int>(
    'end_battery_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoPauseEnabledMeta = const VerificationMeta(
    'autoPauseEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoPauseEnabled = GeneratedColumn<bool>(
    'auto_pause_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_pause_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('private'),
  );
  static const VerificationMeta _hideEdgesMetersMeta = const VerificationMeta(
    'hideEdgesMeters',
  );
  @override
  late final GeneratedColumn<int> hideEdgesMeters = GeneratedColumn<int>(
    'hide_edges_meters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastHeartbeatMsMeta = const VerificationMeta(
    'lastHeartbeatMs',
  );
  @override
  late final GeneratedColumn<int> lastHeartbeatMs = GeneratedColumn<int>(
    'last_heartbeat_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartbeatPausedMeta = const VerificationMeta(
    'heartbeatPaused',
  );
  @override
  late final GeneratedColumn<bool> heartbeatPaused = GeneratedColumn<bool>(
    'heartbeat_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("heartbeat_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _discardedPointCountMeta =
      const VerificationMeta('discardedPointCount');
  @override
  late final GeneratedColumn<int> discardedPointCount = GeneratedColumn<int>(
    'discarded_point_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<int> rpe = GeneratedColumn<int>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importSourceMeta = const VerificationMeta(
    'importSource',
  );
  @override
  late final GeneratedColumn<String> importSource = GeneratedColumn<String>(
    'import_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    guid,
    activityType,
    startTimestampMs,
    endTimestampMs,
    timerTimeMs,
    distanceMeters,
    calories,
    isIndoor,
    isFinished,
    syncState,
    startBatteryLevel,
    endBatteryLevel,
    autoPauseEnabled,
    ownerUserId,
    remoteId,
    title,
    description,
    visibility,
    hideEdgesMeters,
    lastHeartbeatMs,
    heartbeatPaused,
    discardedPointCount,
    rpe,
    mood,
    importSource,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Activity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('start_timestamp_ms')) {
      context.handle(
        _startTimestampMsMeta,
        startTimestampMs.isAcceptableOrUnknown(
          data['start_timestamp_ms']!,
          _startTimestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startTimestampMsMeta);
    }
    if (data.containsKey('end_timestamp_ms')) {
      context.handle(
        _endTimestampMsMeta,
        endTimestampMs.isAcceptableOrUnknown(
          data['end_timestamp_ms']!,
          _endTimestampMsMeta,
        ),
      );
    }
    if (data.containsKey('timer_time_ms')) {
      context.handle(
        _timerTimeMsMeta,
        timerTimeMs.isAcceptableOrUnknown(
          data['timer_time_ms']!,
          _timerTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('is_indoor')) {
      context.handle(
        _isIndoorMeta,
        isIndoor.isAcceptableOrUnknown(data['is_indoor']!, _isIndoorMeta),
      );
    }
    if (data.containsKey('is_finished')) {
      context.handle(
        _isFinishedMeta,
        isFinished.isAcceptableOrUnknown(data['is_finished']!, _isFinishedMeta),
      );
    }
    if (data.containsKey('start_battery_level')) {
      context.handle(
        _startBatteryLevelMeta,
        startBatteryLevel.isAcceptableOrUnknown(
          data['start_battery_level']!,
          _startBatteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('end_battery_level')) {
      context.handle(
        _endBatteryLevelMeta,
        endBatteryLevel.isAcceptableOrUnknown(
          data['end_battery_level']!,
          _endBatteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('auto_pause_enabled')) {
      context.handle(
        _autoPauseEnabledMeta,
        autoPauseEnabled.isAcceptableOrUnknown(
          data['auto_pause_enabled']!,
          _autoPauseEnabledMeta,
        ),
      );
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('hide_edges_meters')) {
      context.handle(
        _hideEdgesMetersMeta,
        hideEdgesMeters.isAcceptableOrUnknown(
          data['hide_edges_meters']!,
          _hideEdgesMetersMeta,
        ),
      );
    }
    if (data.containsKey('last_heartbeat_ms')) {
      context.handle(
        _lastHeartbeatMsMeta,
        lastHeartbeatMs.isAcceptableOrUnknown(
          data['last_heartbeat_ms']!,
          _lastHeartbeatMsMeta,
        ),
      );
    }
    if (data.containsKey('heartbeat_paused')) {
      context.handle(
        _heartbeatPausedMeta,
        heartbeatPaused.isAcceptableOrUnknown(
          data['heartbeat_paused']!,
          _heartbeatPausedMeta,
        ),
      );
    }
    if (data.containsKey('discarded_point_count')) {
      context.handle(
        _discardedPointCountMeta,
        discardedPointCount.isAcceptableOrUnknown(
          data['discarded_point_count']!,
          _discardedPointCountMeta,
        ),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('import_source')) {
      context.handle(
        _importSourceMeta,
        importSource.isAcceptableOrUnknown(
          data['import_source']!,
          _importSourceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {guid};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      activityType: $ActivitiesTable.$converteractivityType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}activity_type'],
        )!,
      ),
      startTimestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_timestamp_ms'],
      )!,
      endTimestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_timestamp_ms'],
      ),
      timerTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timer_time_ms'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      ),
      isIndoor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_indoor'],
      )!,
      isFinished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_finished'],
      )!,
      syncState: $ActivitiesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      startBatteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_battery_level'],
      ),
      endBatteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_battery_level'],
      ),
      autoPauseEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_pause_enabled'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      hideEdgesMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hide_edges_meters'],
      )!,
      lastHeartbeatMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_heartbeat_ms'],
      ),
      heartbeatPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}heartbeat_paused'],
      )!,
      discardedPointCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discarded_point_count'],
      )!,
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      importSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_source'],
      ),
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ActivityType, int, int> $converteractivityType =
      const EnumIndexConverter<ActivityType>(ActivityType.values);
  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class Activity extends DataClass implements Insertable<Activity> {
  final String guid;
  final ActivityType activityType;
  final int startTimestampMs;
  final int? endTimestampMs;
  final int timerTimeMs;
  final double distanceMeters;
  final double? calories;
  final bool isIndoor;
  final bool isFinished;
  final SyncState syncState;
  final int? startBatteryLevel;
  final int? endBatteryLevel;
  final bool autoPauseEnabled;

  /// Conta dona da atividade (id do usuario no backend). Null = gravada sem
  /// conta; e reivindicada pela primeira conta que sincronizar. Impede que as
  /// pendentes de uma conta subam na conta de outra no mesmo aparelho.
  final String? ownerUserId;

  /// Id da atividade no servidor (devolvido pelo upload). Null = nunca subiu
  /// (ou subiu antes de guardarmos o id). Necessario para apagar la tambem.
  final String? remoteId;

  /// Titulo dado na tela Salvar. Null = sem titulo (a UI mostra o sugerido
  /// pelo horario). Ainda nao sobe para o servidor (o contrato de upload nao
  /// tem esse campo).
  final String? title;

  /// Descricao livre da tela Salvar. Null = vazia. Tambem nao sobe ainda.
  final String? description;

  /// Quem pode ver: 'private' | 'followers' | 'everyone' (ver
  /// [ActivityVisibility]). Privacidade automatica (F02): atividade nova
  /// nasce 'private' ("so eu"); o repositorio grava isso explicitamente no
  /// inicio, porque bancos migrados guardam o padrao antigo da coluna. As
  /// atividades antigas mantem o que tinham (a migracao que cria a coluna
  /// grava 'everyone', o padrao de antes). Por enquanto so local.
  final String visibility;

  /// Privacidade (F02): ocultar os primeiros e os ultimos X metros desta
  /// atividade no que sai do aparelho (imagem, upload, exportacao). 0 = nao.
  final int hideEdgesMeters;

  /// Gravacao blindada (F01): instante (epoch ms) do ultimo batimento salvo
  /// durante a gravacao. Na recuperacao pos-crash, o intervalo dele ate a
  /// retomada vira lacuna. Null = sem batimento (atividades antigas).
  final int? lastHeartbeatMs;

  /// True se o ultimo batimento foi salvo com a gravacao pausada (o tempo
  /// parado depois dele nao e lacuna).
  final bool heartbeatPaused;

  /// Pontos descartados pelo filtro de ruido (nao conta os de pausa).
  final int discardedPointCount;

  /// Fechamento gentil (F04): esforco percebido de 1 a 10. Null = nao
  /// informado (e opcional).
  final int? rpe;

  /// Fechamento gentil (F04): humor ('great' | 'good' | 'ok' | 'tired' |
  /// 'awful', ver Mood). Null = nao informado.
  final String? mood;

  /// Seus dados (F07): formato do arquivo de onde a atividade foi importada
  /// ('fit' | 'gpx' | 'tcx', ver ImportFormat). Null = gravada no app.
  final String? importSource;
  const Activity({
    required this.guid,
    required this.activityType,
    required this.startTimestampMs,
    this.endTimestampMs,
    required this.timerTimeMs,
    required this.distanceMeters,
    this.calories,
    required this.isIndoor,
    required this.isFinished,
    required this.syncState,
    this.startBatteryLevel,
    this.endBatteryLevel,
    required this.autoPauseEnabled,
    this.ownerUserId,
    this.remoteId,
    this.title,
    this.description,
    required this.visibility,
    required this.hideEdgesMeters,
    this.lastHeartbeatMs,
    required this.heartbeatPaused,
    required this.discardedPointCount,
    this.rpe,
    this.mood,
    this.importSource,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['guid'] = Variable<String>(guid);
    {
      map['activity_type'] = Variable<int>(
        $ActivitiesTable.$converteractivityType.toSql(activityType),
      );
    }
    map['start_timestamp_ms'] = Variable<int>(startTimestampMs);
    if (!nullToAbsent || endTimestampMs != null) {
      map['end_timestamp_ms'] = Variable<int>(endTimestampMs);
    }
    map['timer_time_ms'] = Variable<int>(timerTimeMs);
    map['distance_meters'] = Variable<double>(distanceMeters);
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<double>(calories);
    }
    map['is_indoor'] = Variable<bool>(isIndoor);
    map['is_finished'] = Variable<bool>(isFinished);
    {
      map['sync_state'] = Variable<int>(
        $ActivitiesTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || startBatteryLevel != null) {
      map['start_battery_level'] = Variable<int>(startBatteryLevel);
    }
    if (!nullToAbsent || endBatteryLevel != null) {
      map['end_battery_level'] = Variable<int>(endBatteryLevel);
    }
    map['auto_pause_enabled'] = Variable<bool>(autoPauseEnabled);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['visibility'] = Variable<String>(visibility);
    map['hide_edges_meters'] = Variable<int>(hideEdgesMeters);
    if (!nullToAbsent || lastHeartbeatMs != null) {
      map['last_heartbeat_ms'] = Variable<int>(lastHeartbeatMs);
    }
    map['heartbeat_paused'] = Variable<bool>(heartbeatPaused);
    map['discarded_point_count'] = Variable<int>(discardedPointCount);
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<int>(rpe);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    if (!nullToAbsent || importSource != null) {
      map['import_source'] = Variable<String>(importSource);
    }
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      guid: Value(guid),
      activityType: Value(activityType),
      startTimestampMs: Value(startTimestampMs),
      endTimestampMs: endTimestampMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endTimestampMs),
      timerTimeMs: Value(timerTimeMs),
      distanceMeters: Value(distanceMeters),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      isIndoor: Value(isIndoor),
      isFinished: Value(isFinished),
      syncState: Value(syncState),
      startBatteryLevel: startBatteryLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(startBatteryLevel),
      endBatteryLevel: endBatteryLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(endBatteryLevel),
      autoPauseEnabled: Value(autoPauseEnabled),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      visibility: Value(visibility),
      hideEdgesMeters: Value(hideEdgesMeters),
      lastHeartbeatMs: lastHeartbeatMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeartbeatMs),
      heartbeatPaused: Value(heartbeatPaused),
      discardedPointCount: Value(discardedPointCount),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      importSource: importSource == null && nullToAbsent
          ? const Value.absent()
          : Value(importSource),
    );
  }

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      guid: serializer.fromJson<String>(json['guid']),
      activityType: $ActivitiesTable.$converteractivityType.fromJson(
        serializer.fromJson<int>(json['activityType']),
      ),
      startTimestampMs: serializer.fromJson<int>(json['startTimestampMs']),
      endTimestampMs: serializer.fromJson<int?>(json['endTimestampMs']),
      timerTimeMs: serializer.fromJson<int>(json['timerTimeMs']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      calories: serializer.fromJson<double?>(json['calories']),
      isIndoor: serializer.fromJson<bool>(json['isIndoor']),
      isFinished: serializer.fromJson<bool>(json['isFinished']),
      syncState: $ActivitiesTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      startBatteryLevel: serializer.fromJson<int?>(json['startBatteryLevel']),
      endBatteryLevel: serializer.fromJson<int?>(json['endBatteryLevel']),
      autoPauseEnabled: serializer.fromJson<bool>(json['autoPauseEnabled']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      visibility: serializer.fromJson<String>(json['visibility']),
      hideEdgesMeters: serializer.fromJson<int>(json['hideEdgesMeters']),
      lastHeartbeatMs: serializer.fromJson<int?>(json['lastHeartbeatMs']),
      heartbeatPaused: serializer.fromJson<bool>(json['heartbeatPaused']),
      discardedPointCount: serializer.fromJson<int>(
        json['discardedPointCount'],
      ),
      rpe: serializer.fromJson<int?>(json['rpe']),
      mood: serializer.fromJson<String?>(json['mood']),
      importSource: serializer.fromJson<String?>(json['importSource']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'guid': serializer.toJson<String>(guid),
      'activityType': serializer.toJson<int>(
        $ActivitiesTable.$converteractivityType.toJson(activityType),
      ),
      'startTimestampMs': serializer.toJson<int>(startTimestampMs),
      'endTimestampMs': serializer.toJson<int?>(endTimestampMs),
      'timerTimeMs': serializer.toJson<int>(timerTimeMs),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'calories': serializer.toJson<double?>(calories),
      'isIndoor': serializer.toJson<bool>(isIndoor),
      'isFinished': serializer.toJson<bool>(isFinished),
      'syncState': serializer.toJson<int>(
        $ActivitiesTable.$convertersyncState.toJson(syncState),
      ),
      'startBatteryLevel': serializer.toJson<int?>(startBatteryLevel),
      'endBatteryLevel': serializer.toJson<int?>(endBatteryLevel),
      'autoPauseEnabled': serializer.toJson<bool>(autoPauseEnabled),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
      'visibility': serializer.toJson<String>(visibility),
      'hideEdgesMeters': serializer.toJson<int>(hideEdgesMeters),
      'lastHeartbeatMs': serializer.toJson<int?>(lastHeartbeatMs),
      'heartbeatPaused': serializer.toJson<bool>(heartbeatPaused),
      'discardedPointCount': serializer.toJson<int>(discardedPointCount),
      'rpe': serializer.toJson<int?>(rpe),
      'mood': serializer.toJson<String?>(mood),
      'importSource': serializer.toJson<String?>(importSource),
    };
  }

  Activity copyWith({
    String? guid,
    ActivityType? activityType,
    int? startTimestampMs,
    Value<int?> endTimestampMs = const Value.absent(),
    int? timerTimeMs,
    double? distanceMeters,
    Value<double?> calories = const Value.absent(),
    bool? isIndoor,
    bool? isFinished,
    SyncState? syncState,
    Value<int?> startBatteryLevel = const Value.absent(),
    Value<int?> endBatteryLevel = const Value.absent(),
    bool? autoPauseEnabled,
    Value<String?> ownerUserId = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? visibility,
    int? hideEdgesMeters,
    Value<int?> lastHeartbeatMs = const Value.absent(),
    bool? heartbeatPaused,
    int? discardedPointCount,
    Value<int?> rpe = const Value.absent(),
    Value<String?> mood = const Value.absent(),
    Value<String?> importSource = const Value.absent(),
  }) => Activity(
    guid: guid ?? this.guid,
    activityType: activityType ?? this.activityType,
    startTimestampMs: startTimestampMs ?? this.startTimestampMs,
    endTimestampMs: endTimestampMs.present
        ? endTimestampMs.value
        : this.endTimestampMs,
    timerTimeMs: timerTimeMs ?? this.timerTimeMs,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    calories: calories.present ? calories.value : this.calories,
    isIndoor: isIndoor ?? this.isIndoor,
    isFinished: isFinished ?? this.isFinished,
    syncState: syncState ?? this.syncState,
    startBatteryLevel: startBatteryLevel.present
        ? startBatteryLevel.value
        : this.startBatteryLevel,
    endBatteryLevel: endBatteryLevel.present
        ? endBatteryLevel.value
        : this.endBatteryLevel,
    autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    visibility: visibility ?? this.visibility,
    hideEdgesMeters: hideEdgesMeters ?? this.hideEdgesMeters,
    lastHeartbeatMs: lastHeartbeatMs.present
        ? lastHeartbeatMs.value
        : this.lastHeartbeatMs,
    heartbeatPaused: heartbeatPaused ?? this.heartbeatPaused,
    discardedPointCount: discardedPointCount ?? this.discardedPointCount,
    rpe: rpe.present ? rpe.value : this.rpe,
    mood: mood.present ? mood.value : this.mood,
    importSource: importSource.present ? importSource.value : this.importSource,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      guid: data.guid.present ? data.guid.value : this.guid,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      startTimestampMs: data.startTimestampMs.present
          ? data.startTimestampMs.value
          : this.startTimestampMs,
      endTimestampMs: data.endTimestampMs.present
          ? data.endTimestampMs.value
          : this.endTimestampMs,
      timerTimeMs: data.timerTimeMs.present
          ? data.timerTimeMs.value
          : this.timerTimeMs,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      calories: data.calories.present ? data.calories.value : this.calories,
      isIndoor: data.isIndoor.present ? data.isIndoor.value : this.isIndoor,
      isFinished: data.isFinished.present
          ? data.isFinished.value
          : this.isFinished,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      startBatteryLevel: data.startBatteryLevel.present
          ? data.startBatteryLevel.value
          : this.startBatteryLevel,
      endBatteryLevel: data.endBatteryLevel.present
          ? data.endBatteryLevel.value
          : this.endBatteryLevel,
      autoPauseEnabled: data.autoPauseEnabled.present
          ? data.autoPauseEnabled.value
          : this.autoPauseEnabled,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      hideEdgesMeters: data.hideEdgesMeters.present
          ? data.hideEdgesMeters.value
          : this.hideEdgesMeters,
      lastHeartbeatMs: data.lastHeartbeatMs.present
          ? data.lastHeartbeatMs.value
          : this.lastHeartbeatMs,
      heartbeatPaused: data.heartbeatPaused.present
          ? data.heartbeatPaused.value
          : this.heartbeatPaused,
      discardedPointCount: data.discardedPointCount.present
          ? data.discardedPointCount.value
          : this.discardedPointCount,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      mood: data.mood.present ? data.mood.value : this.mood,
      importSource: data.importSource.present
          ? data.importSource.value
          : this.importSource,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('guid: $guid, ')
          ..write('activityType: $activityType, ')
          ..write('startTimestampMs: $startTimestampMs, ')
          ..write('endTimestampMs: $endTimestampMs, ')
          ..write('timerTimeMs: $timerTimeMs, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('calories: $calories, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('isFinished: $isFinished, ')
          ..write('syncState: $syncState, ')
          ..write('startBatteryLevel: $startBatteryLevel, ')
          ..write('endBatteryLevel: $endBatteryLevel, ')
          ..write('autoPauseEnabled: $autoPauseEnabled, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('remoteId: $remoteId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('visibility: $visibility, ')
          ..write('hideEdgesMeters: $hideEdgesMeters, ')
          ..write('lastHeartbeatMs: $lastHeartbeatMs, ')
          ..write('heartbeatPaused: $heartbeatPaused, ')
          ..write('discardedPointCount: $discardedPointCount, ')
          ..write('rpe: $rpe, ')
          ..write('mood: $mood, ')
          ..write('importSource: $importSource')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    guid,
    activityType,
    startTimestampMs,
    endTimestampMs,
    timerTimeMs,
    distanceMeters,
    calories,
    isIndoor,
    isFinished,
    syncState,
    startBatteryLevel,
    endBatteryLevel,
    autoPauseEnabled,
    ownerUserId,
    remoteId,
    title,
    description,
    visibility,
    hideEdgesMeters,
    lastHeartbeatMs,
    heartbeatPaused,
    discardedPointCount,
    rpe,
    mood,
    importSource,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.guid == this.guid &&
          other.activityType == this.activityType &&
          other.startTimestampMs == this.startTimestampMs &&
          other.endTimestampMs == this.endTimestampMs &&
          other.timerTimeMs == this.timerTimeMs &&
          other.distanceMeters == this.distanceMeters &&
          other.calories == this.calories &&
          other.isIndoor == this.isIndoor &&
          other.isFinished == this.isFinished &&
          other.syncState == this.syncState &&
          other.startBatteryLevel == this.startBatteryLevel &&
          other.endBatteryLevel == this.endBatteryLevel &&
          other.autoPauseEnabled == this.autoPauseEnabled &&
          other.ownerUserId == this.ownerUserId &&
          other.remoteId == this.remoteId &&
          other.title == this.title &&
          other.description == this.description &&
          other.visibility == this.visibility &&
          other.hideEdgesMeters == this.hideEdgesMeters &&
          other.lastHeartbeatMs == this.lastHeartbeatMs &&
          other.heartbeatPaused == this.heartbeatPaused &&
          other.discardedPointCount == this.discardedPointCount &&
          other.rpe == this.rpe &&
          other.mood == this.mood &&
          other.importSource == this.importSource);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<String> guid;
  final Value<ActivityType> activityType;
  final Value<int> startTimestampMs;
  final Value<int?> endTimestampMs;
  final Value<int> timerTimeMs;
  final Value<double> distanceMeters;
  final Value<double?> calories;
  final Value<bool> isIndoor;
  final Value<bool> isFinished;
  final Value<SyncState> syncState;
  final Value<int?> startBatteryLevel;
  final Value<int?> endBatteryLevel;
  final Value<bool> autoPauseEnabled;
  final Value<String?> ownerUserId;
  final Value<String?> remoteId;
  final Value<String?> title;
  final Value<String?> description;
  final Value<String> visibility;
  final Value<int> hideEdgesMeters;
  final Value<int?> lastHeartbeatMs;
  final Value<bool> heartbeatPaused;
  final Value<int> discardedPointCount;
  final Value<int?> rpe;
  final Value<String?> mood;
  final Value<String?> importSource;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.guid = const Value.absent(),
    this.activityType = const Value.absent(),
    this.startTimestampMs = const Value.absent(),
    this.endTimestampMs = const Value.absent(),
    this.timerTimeMs = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.calories = const Value.absent(),
    this.isIndoor = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.syncState = const Value.absent(),
    this.startBatteryLevel = const Value.absent(),
    this.endBatteryLevel = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.visibility = const Value.absent(),
    this.hideEdgesMeters = const Value.absent(),
    this.lastHeartbeatMs = const Value.absent(),
    this.heartbeatPaused = const Value.absent(),
    this.discardedPointCount = const Value.absent(),
    this.rpe = const Value.absent(),
    this.mood = const Value.absent(),
    this.importSource = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String guid,
    required ActivityType activityType,
    required int startTimestampMs,
    this.endTimestampMs = const Value.absent(),
    this.timerTimeMs = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.calories = const Value.absent(),
    this.isIndoor = const Value.absent(),
    this.isFinished = const Value.absent(),
    required SyncState syncState,
    this.startBatteryLevel = const Value.absent(),
    this.endBatteryLevel = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.visibility = const Value.absent(),
    this.hideEdgesMeters = const Value.absent(),
    this.lastHeartbeatMs = const Value.absent(),
    this.heartbeatPaused = const Value.absent(),
    this.discardedPointCount = const Value.absent(),
    this.rpe = const Value.absent(),
    this.mood = const Value.absent(),
    this.importSource = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : guid = Value(guid),
       activityType = Value(activityType),
       startTimestampMs = Value(startTimestampMs),
       syncState = Value(syncState);
  static Insertable<Activity> custom({
    Expression<String>? guid,
    Expression<int>? activityType,
    Expression<int>? startTimestampMs,
    Expression<int>? endTimestampMs,
    Expression<int>? timerTimeMs,
    Expression<double>? distanceMeters,
    Expression<double>? calories,
    Expression<bool>? isIndoor,
    Expression<bool>? isFinished,
    Expression<int>? syncState,
    Expression<int>? startBatteryLevel,
    Expression<int>? endBatteryLevel,
    Expression<bool>? autoPauseEnabled,
    Expression<String>? ownerUserId,
    Expression<String>? remoteId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? visibility,
    Expression<int>? hideEdgesMeters,
    Expression<int>? lastHeartbeatMs,
    Expression<bool>? heartbeatPaused,
    Expression<int>? discardedPointCount,
    Expression<int>? rpe,
    Expression<String>? mood,
    Expression<String>? importSource,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (activityType != null) 'activity_type': activityType,
      if (startTimestampMs != null) 'start_timestamp_ms': startTimestampMs,
      if (endTimestampMs != null) 'end_timestamp_ms': endTimestampMs,
      if (timerTimeMs != null) 'timer_time_ms': timerTimeMs,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (calories != null) 'calories': calories,
      if (isIndoor != null) 'is_indoor': isIndoor,
      if (isFinished != null) 'is_finished': isFinished,
      if (syncState != null) 'sync_state': syncState,
      if (startBatteryLevel != null) 'start_battery_level': startBatteryLevel,
      if (endBatteryLevel != null) 'end_battery_level': endBatteryLevel,
      if (autoPauseEnabled != null) 'auto_pause_enabled': autoPauseEnabled,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (remoteId != null) 'remote_id': remoteId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (visibility != null) 'visibility': visibility,
      if (hideEdgesMeters != null) 'hide_edges_meters': hideEdgesMeters,
      if (lastHeartbeatMs != null) 'last_heartbeat_ms': lastHeartbeatMs,
      if (heartbeatPaused != null) 'heartbeat_paused': heartbeatPaused,
      if (discardedPointCount != null)
        'discarded_point_count': discardedPointCount,
      if (rpe != null) 'rpe': rpe,
      if (mood != null) 'mood': mood,
      if (importSource != null) 'import_source': importSource,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith({
    Value<String>? guid,
    Value<ActivityType>? activityType,
    Value<int>? startTimestampMs,
    Value<int?>? endTimestampMs,
    Value<int>? timerTimeMs,
    Value<double>? distanceMeters,
    Value<double?>? calories,
    Value<bool>? isIndoor,
    Value<bool>? isFinished,
    Value<SyncState>? syncState,
    Value<int?>? startBatteryLevel,
    Value<int?>? endBatteryLevel,
    Value<bool>? autoPauseEnabled,
    Value<String?>? ownerUserId,
    Value<String?>? remoteId,
    Value<String?>? title,
    Value<String?>? description,
    Value<String>? visibility,
    Value<int>? hideEdgesMeters,
    Value<int?>? lastHeartbeatMs,
    Value<bool>? heartbeatPaused,
    Value<int>? discardedPointCount,
    Value<int?>? rpe,
    Value<String?>? mood,
    Value<String?>? importSource,
    Value<int>? rowid,
  }) {
    return ActivitiesCompanion(
      guid: guid ?? this.guid,
      activityType: activityType ?? this.activityType,
      startTimestampMs: startTimestampMs ?? this.startTimestampMs,
      endTimestampMs: endTimestampMs ?? this.endTimestampMs,
      timerTimeMs: timerTimeMs ?? this.timerTimeMs,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      calories: calories ?? this.calories,
      isIndoor: isIndoor ?? this.isIndoor,
      isFinished: isFinished ?? this.isFinished,
      syncState: syncState ?? this.syncState,
      startBatteryLevel: startBatteryLevel ?? this.startBatteryLevel,
      endBatteryLevel: endBatteryLevel ?? this.endBatteryLevel,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      hideEdgesMeters: hideEdgesMeters ?? this.hideEdgesMeters,
      lastHeartbeatMs: lastHeartbeatMs ?? this.lastHeartbeatMs,
      heartbeatPaused: heartbeatPaused ?? this.heartbeatPaused,
      discardedPointCount: discardedPointCount ?? this.discardedPointCount,
      rpe: rpe ?? this.rpe,
      mood: mood ?? this.mood,
      importSource: importSource ?? this.importSource,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<int>(
        $ActivitiesTable.$converteractivityType.toSql(activityType.value),
      );
    }
    if (startTimestampMs.present) {
      map['start_timestamp_ms'] = Variable<int>(startTimestampMs.value);
    }
    if (endTimestampMs.present) {
      map['end_timestamp_ms'] = Variable<int>(endTimestampMs.value);
    }
    if (timerTimeMs.present) {
      map['timer_time_ms'] = Variable<int>(timerTimeMs.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (isIndoor.present) {
      map['is_indoor'] = Variable<bool>(isIndoor.value);
    }
    if (isFinished.present) {
      map['is_finished'] = Variable<bool>(isFinished.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $ActivitiesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (startBatteryLevel.present) {
      map['start_battery_level'] = Variable<int>(startBatteryLevel.value);
    }
    if (endBatteryLevel.present) {
      map['end_battery_level'] = Variable<int>(endBatteryLevel.value);
    }
    if (autoPauseEnabled.present) {
      map['auto_pause_enabled'] = Variable<bool>(autoPauseEnabled.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (hideEdgesMeters.present) {
      map['hide_edges_meters'] = Variable<int>(hideEdgesMeters.value);
    }
    if (lastHeartbeatMs.present) {
      map['last_heartbeat_ms'] = Variable<int>(lastHeartbeatMs.value);
    }
    if (heartbeatPaused.present) {
      map['heartbeat_paused'] = Variable<bool>(heartbeatPaused.value);
    }
    if (discardedPointCount.present) {
      map['discarded_point_count'] = Variable<int>(discardedPointCount.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<int>(rpe.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (importSource.present) {
      map['import_source'] = Variable<String>(importSource.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('guid: $guid, ')
          ..write('activityType: $activityType, ')
          ..write('startTimestampMs: $startTimestampMs, ')
          ..write('endTimestampMs: $endTimestampMs, ')
          ..write('timerTimeMs: $timerTimeMs, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('calories: $calories, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('isFinished: $isFinished, ')
          ..write('syncState: $syncState, ')
          ..write('startBatteryLevel: $startBatteryLevel, ')
          ..write('endBatteryLevel: $endBatteryLevel, ')
          ..write('autoPauseEnabled: $autoPauseEnabled, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('remoteId: $remoteId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('visibility: $visibility, ')
          ..write('hideEdgesMeters: $hideEdgesMeters, ')
          ..write('lastHeartbeatMs: $lastHeartbeatMs, ')
          ..write('heartbeatPaused: $heartbeatPaused, ')
          ..write('discardedPointCount: $discardedPointCount, ')
          ..write('rpe: $rpe, ')
          ..write('mood: $mood, ')
          ..write('importSource: $importSource, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaypointsTable extends Waypoints
    with TableInfo<$WaypointsTable, Waypoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaypointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityGuidMeta = const VerificationMeta(
    'activityGuid',
  );
  @override
  late final GeneratedColumn<String> activityGuid = GeneratedColumn<String>(
    'activity_guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (guid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMetersMeta = const VerificationMeta(
    'altitudeMeters',
  );
  @override
  late final GeneratedColumn<double> altitudeMeters = GeneratedColumn<double>(
    'altitude_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _horizontalAccuracyMetersMeta =
      const VerificationMeta('horizontalAccuracyMeters');
  @override
  late final GeneratedColumn<double> horizontalAccuracyMeters =
      GeneratedColumn<double>(
        'horizontal_accuracy_meters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _verticalAccuracyMetersMeta =
      const VerificationMeta('verticalAccuracyMeters');
  @override
  late final GeneratedColumn<double> verticalAccuracyMeters =
      GeneratedColumn<double>(
        'vertical_accuracy_meters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _speedMetersPerSecondMeta =
      const VerificationMeta('speedMetersPerSecond');
  @override
  late final GeneratedColumn<double> speedMetersPerSecond =
      GeneratedColumn<double>(
        'speed_meters_per_second',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _elapsedTimeMsMeta = const VerificationMeta(
    'elapsedTimeMs',
  );
  @override
  late final GeneratedColumn<int> elapsedTimeMs = GeneratedColumn<int>(
    'elapsed_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timerTimeMsMeta = const VerificationMeta(
    'timerTimeMs',
  );
  @override
  late final GeneratedColumn<int> timerTimeMs = GeneratedColumn<int>(
    'timer_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cumulativeDistanceMetersMeta =
      const VerificationMeta('cumulativeDistanceMeters');
  @override
  late final GeneratedColumn<double> cumulativeDistanceMeters =
      GeneratedColumn<double>(
        'cumulative_distance_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _classificationMeta = const VerificationMeta(
    'classification',
  );
  @override
  late final GeneratedColumn<int> classification = GeneratedColumn<int>(
    'classification',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityGuid,
    seq,
    latitude,
    longitude,
    altitudeMeters,
    horizontalAccuracyMeters,
    verticalAccuracyMeters,
    speedMetersPerSecond,
    elapsedTimeMs,
    timerTimeMs,
    cumulativeDistanceMeters,
    classification,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waypoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<Waypoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_guid')) {
      context.handle(
        _activityGuidMeta,
        activityGuid.isAcceptableOrUnknown(
          data['activity_guid']!,
          _activityGuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityGuidMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('altitude_meters')) {
      context.handle(
        _altitudeMetersMeta,
        altitudeMeters.isAcceptableOrUnknown(
          data['altitude_meters']!,
          _altitudeMetersMeta,
        ),
      );
    }
    if (data.containsKey('horizontal_accuracy_meters')) {
      context.handle(
        _horizontalAccuracyMetersMeta,
        horizontalAccuracyMeters.isAcceptableOrUnknown(
          data['horizontal_accuracy_meters']!,
          _horizontalAccuracyMetersMeta,
        ),
      );
    }
    if (data.containsKey('vertical_accuracy_meters')) {
      context.handle(
        _verticalAccuracyMetersMeta,
        verticalAccuracyMeters.isAcceptableOrUnknown(
          data['vertical_accuracy_meters']!,
          _verticalAccuracyMetersMeta,
        ),
      );
    }
    if (data.containsKey('speed_meters_per_second')) {
      context.handle(
        _speedMetersPerSecondMeta,
        speedMetersPerSecond.isAcceptableOrUnknown(
          data['speed_meters_per_second']!,
          _speedMetersPerSecondMeta,
        ),
      );
    }
    if (data.containsKey('elapsed_time_ms')) {
      context.handle(
        _elapsedTimeMsMeta,
        elapsedTimeMs.isAcceptableOrUnknown(
          data['elapsed_time_ms']!,
          _elapsedTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elapsedTimeMsMeta);
    }
    if (data.containsKey('timer_time_ms')) {
      context.handle(
        _timerTimeMsMeta,
        timerTimeMs.isAcceptableOrUnknown(
          data['timer_time_ms']!,
          _timerTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timerTimeMsMeta);
    }
    if (data.containsKey('cumulative_distance_meters')) {
      context.handle(
        _cumulativeDistanceMetersMeta,
        cumulativeDistanceMeters.isAcceptableOrUnknown(
          data['cumulative_distance_meters']!,
          _cumulativeDistanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cumulativeDistanceMetersMeta);
    }
    if (data.containsKey('classification')) {
      context.handle(
        _classificationMeta,
        classification.isAcceptableOrUnknown(
          data['classification']!,
          _classificationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classificationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Waypoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Waypoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_guid'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      altitudeMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_meters'],
      ),
      horizontalAccuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}horizontal_accuracy_meters'],
      ),
      verticalAccuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vertical_accuracy_meters'],
      ),
      speedMetersPerSecond: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_meters_per_second'],
      ),
      elapsedTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_time_ms'],
      )!,
      timerTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timer_time_ms'],
      )!,
      cumulativeDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cumulative_distance_meters'],
      )!,
      classification: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}classification'],
      )!,
    );
  }

  @override
  $WaypointsTable createAlias(String alias) {
    return $WaypointsTable(attachedDatabase, alias);
  }
}

class Waypoint extends DataClass implements Insertable<Waypoint> {
  final int id;
  final String activityGuid;
  final int seq;
  final double latitude;
  final double longitude;
  final double? altitudeMeters;
  final double? horizontalAccuracyMeters;
  final double? verticalAccuracyMeters;
  final double? speedMetersPerSecond;
  final int elapsedTimeMs;
  final int timerTimeMs;
  final double cumulativeDistanceMeters;
  final int classification;
  const Waypoint({
    required this.id,
    required this.activityGuid,
    required this.seq,
    required this.latitude,
    required this.longitude,
    this.altitudeMeters,
    this.horizontalAccuracyMeters,
    this.verticalAccuracyMeters,
    this.speedMetersPerSecond,
    required this.elapsedTimeMs,
    required this.timerTimeMs,
    required this.cumulativeDistanceMeters,
    required this.classification,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_guid'] = Variable<String>(activityGuid);
    map['seq'] = Variable<int>(seq);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || altitudeMeters != null) {
      map['altitude_meters'] = Variable<double>(altitudeMeters);
    }
    if (!nullToAbsent || horizontalAccuracyMeters != null) {
      map['horizontal_accuracy_meters'] = Variable<double>(
        horizontalAccuracyMeters,
      );
    }
    if (!nullToAbsent || verticalAccuracyMeters != null) {
      map['vertical_accuracy_meters'] = Variable<double>(
        verticalAccuracyMeters,
      );
    }
    if (!nullToAbsent || speedMetersPerSecond != null) {
      map['speed_meters_per_second'] = Variable<double>(speedMetersPerSecond);
    }
    map['elapsed_time_ms'] = Variable<int>(elapsedTimeMs);
    map['timer_time_ms'] = Variable<int>(timerTimeMs);
    map['cumulative_distance_meters'] = Variable<double>(
      cumulativeDistanceMeters,
    );
    map['classification'] = Variable<int>(classification);
    return map;
  }

  WaypointsCompanion toCompanion(bool nullToAbsent) {
    return WaypointsCompanion(
      id: Value(id),
      activityGuid: Value(activityGuid),
      seq: Value(seq),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitudeMeters: altitudeMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(altitudeMeters),
      horizontalAccuracyMeters: horizontalAccuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(horizontalAccuracyMeters),
      verticalAccuracyMeters: verticalAccuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(verticalAccuracyMeters),
      speedMetersPerSecond: speedMetersPerSecond == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMetersPerSecond),
      elapsedTimeMs: Value(elapsedTimeMs),
      timerTimeMs: Value(timerTimeMs),
      cumulativeDistanceMeters: Value(cumulativeDistanceMeters),
      classification: Value(classification),
    );
  }

  factory Waypoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Waypoint(
      id: serializer.fromJson<int>(json['id']),
      activityGuid: serializer.fromJson<String>(json['activityGuid']),
      seq: serializer.fromJson<int>(json['seq']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      altitudeMeters: serializer.fromJson<double?>(json['altitudeMeters']),
      horizontalAccuracyMeters: serializer.fromJson<double?>(
        json['horizontalAccuracyMeters'],
      ),
      verticalAccuracyMeters: serializer.fromJson<double?>(
        json['verticalAccuracyMeters'],
      ),
      speedMetersPerSecond: serializer.fromJson<double?>(
        json['speedMetersPerSecond'],
      ),
      elapsedTimeMs: serializer.fromJson<int>(json['elapsedTimeMs']),
      timerTimeMs: serializer.fromJson<int>(json['timerTimeMs']),
      cumulativeDistanceMeters: serializer.fromJson<double>(
        json['cumulativeDistanceMeters'],
      ),
      classification: serializer.fromJson<int>(json['classification']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityGuid': serializer.toJson<String>(activityGuid),
      'seq': serializer.toJson<int>(seq),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'altitudeMeters': serializer.toJson<double?>(altitudeMeters),
      'horizontalAccuracyMeters': serializer.toJson<double?>(
        horizontalAccuracyMeters,
      ),
      'verticalAccuracyMeters': serializer.toJson<double?>(
        verticalAccuracyMeters,
      ),
      'speedMetersPerSecond': serializer.toJson<double?>(speedMetersPerSecond),
      'elapsedTimeMs': serializer.toJson<int>(elapsedTimeMs),
      'timerTimeMs': serializer.toJson<int>(timerTimeMs),
      'cumulativeDistanceMeters': serializer.toJson<double>(
        cumulativeDistanceMeters,
      ),
      'classification': serializer.toJson<int>(classification),
    };
  }

  Waypoint copyWith({
    int? id,
    String? activityGuid,
    int? seq,
    double? latitude,
    double? longitude,
    Value<double?> altitudeMeters = const Value.absent(),
    Value<double?> horizontalAccuracyMeters = const Value.absent(),
    Value<double?> verticalAccuracyMeters = const Value.absent(),
    Value<double?> speedMetersPerSecond = const Value.absent(),
    int? elapsedTimeMs,
    int? timerTimeMs,
    double? cumulativeDistanceMeters,
    int? classification,
  }) => Waypoint(
    id: id ?? this.id,
    activityGuid: activityGuid ?? this.activityGuid,
    seq: seq ?? this.seq,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitudeMeters: altitudeMeters.present
        ? altitudeMeters.value
        : this.altitudeMeters,
    horizontalAccuracyMeters: horizontalAccuracyMeters.present
        ? horizontalAccuracyMeters.value
        : this.horizontalAccuracyMeters,
    verticalAccuracyMeters: verticalAccuracyMeters.present
        ? verticalAccuracyMeters.value
        : this.verticalAccuracyMeters,
    speedMetersPerSecond: speedMetersPerSecond.present
        ? speedMetersPerSecond.value
        : this.speedMetersPerSecond,
    elapsedTimeMs: elapsedTimeMs ?? this.elapsedTimeMs,
    timerTimeMs: timerTimeMs ?? this.timerTimeMs,
    cumulativeDistanceMeters:
        cumulativeDistanceMeters ?? this.cumulativeDistanceMeters,
    classification: classification ?? this.classification,
  );
  Waypoint copyWithCompanion(WaypointsCompanion data) {
    return Waypoint(
      id: data.id.present ? data.id.value : this.id,
      activityGuid: data.activityGuid.present
          ? data.activityGuid.value
          : this.activityGuid,
      seq: data.seq.present ? data.seq.value : this.seq,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitudeMeters: data.altitudeMeters.present
          ? data.altitudeMeters.value
          : this.altitudeMeters,
      horizontalAccuracyMeters: data.horizontalAccuracyMeters.present
          ? data.horizontalAccuracyMeters.value
          : this.horizontalAccuracyMeters,
      verticalAccuracyMeters: data.verticalAccuracyMeters.present
          ? data.verticalAccuracyMeters.value
          : this.verticalAccuracyMeters,
      speedMetersPerSecond: data.speedMetersPerSecond.present
          ? data.speedMetersPerSecond.value
          : this.speedMetersPerSecond,
      elapsedTimeMs: data.elapsedTimeMs.present
          ? data.elapsedTimeMs.value
          : this.elapsedTimeMs,
      timerTimeMs: data.timerTimeMs.present
          ? data.timerTimeMs.value
          : this.timerTimeMs,
      cumulativeDistanceMeters: data.cumulativeDistanceMeters.present
          ? data.cumulativeDistanceMeters.value
          : this.cumulativeDistanceMeters,
      classification: data.classification.present
          ? data.classification.value
          : this.classification,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Waypoint(')
          ..write('id: $id, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('seq: $seq, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitudeMeters: $altitudeMeters, ')
          ..write('horizontalAccuracyMeters: $horizontalAccuracyMeters, ')
          ..write('verticalAccuracyMeters: $verticalAccuracyMeters, ')
          ..write('speedMetersPerSecond: $speedMetersPerSecond, ')
          ..write('elapsedTimeMs: $elapsedTimeMs, ')
          ..write('timerTimeMs: $timerTimeMs, ')
          ..write('cumulativeDistanceMeters: $cumulativeDistanceMeters, ')
          ..write('classification: $classification')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityGuid,
    seq,
    latitude,
    longitude,
    altitudeMeters,
    horizontalAccuracyMeters,
    verticalAccuracyMeters,
    speedMetersPerSecond,
    elapsedTimeMs,
    timerTimeMs,
    cumulativeDistanceMeters,
    classification,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Waypoint &&
          other.id == this.id &&
          other.activityGuid == this.activityGuid &&
          other.seq == this.seq &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitudeMeters == this.altitudeMeters &&
          other.horizontalAccuracyMeters == this.horizontalAccuracyMeters &&
          other.verticalAccuracyMeters == this.verticalAccuracyMeters &&
          other.speedMetersPerSecond == this.speedMetersPerSecond &&
          other.elapsedTimeMs == this.elapsedTimeMs &&
          other.timerTimeMs == this.timerTimeMs &&
          other.cumulativeDistanceMeters == this.cumulativeDistanceMeters &&
          other.classification == this.classification);
}

class WaypointsCompanion extends UpdateCompanion<Waypoint> {
  final Value<int> id;
  final Value<String> activityGuid;
  final Value<int> seq;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> altitudeMeters;
  final Value<double?> horizontalAccuracyMeters;
  final Value<double?> verticalAccuracyMeters;
  final Value<double?> speedMetersPerSecond;
  final Value<int> elapsedTimeMs;
  final Value<int> timerTimeMs;
  final Value<double> cumulativeDistanceMeters;
  final Value<int> classification;
  const WaypointsCompanion({
    this.id = const Value.absent(),
    this.activityGuid = const Value.absent(),
    this.seq = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitudeMeters = const Value.absent(),
    this.horizontalAccuracyMeters = const Value.absent(),
    this.verticalAccuracyMeters = const Value.absent(),
    this.speedMetersPerSecond = const Value.absent(),
    this.elapsedTimeMs = const Value.absent(),
    this.timerTimeMs = const Value.absent(),
    this.cumulativeDistanceMeters = const Value.absent(),
    this.classification = const Value.absent(),
  });
  WaypointsCompanion.insert({
    this.id = const Value.absent(),
    required String activityGuid,
    required int seq,
    required double latitude,
    required double longitude,
    this.altitudeMeters = const Value.absent(),
    this.horizontalAccuracyMeters = const Value.absent(),
    this.verticalAccuracyMeters = const Value.absent(),
    this.speedMetersPerSecond = const Value.absent(),
    required int elapsedTimeMs,
    required int timerTimeMs,
    required double cumulativeDistanceMeters,
    required int classification,
  }) : activityGuid = Value(activityGuid),
       seq = Value(seq),
       latitude = Value(latitude),
       longitude = Value(longitude),
       elapsedTimeMs = Value(elapsedTimeMs),
       timerTimeMs = Value(timerTimeMs),
       cumulativeDistanceMeters = Value(cumulativeDistanceMeters),
       classification = Value(classification);
  static Insertable<Waypoint> custom({
    Expression<int>? id,
    Expression<String>? activityGuid,
    Expression<int>? seq,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitudeMeters,
    Expression<double>? horizontalAccuracyMeters,
    Expression<double>? verticalAccuracyMeters,
    Expression<double>? speedMetersPerSecond,
    Expression<int>? elapsedTimeMs,
    Expression<int>? timerTimeMs,
    Expression<double>? cumulativeDistanceMeters,
    Expression<int>? classification,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityGuid != null) 'activity_guid': activityGuid,
      if (seq != null) 'seq': seq,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitudeMeters != null) 'altitude_meters': altitudeMeters,
      if (horizontalAccuracyMeters != null)
        'horizontal_accuracy_meters': horizontalAccuracyMeters,
      if (verticalAccuracyMeters != null)
        'vertical_accuracy_meters': verticalAccuracyMeters,
      if (speedMetersPerSecond != null)
        'speed_meters_per_second': speedMetersPerSecond,
      if (elapsedTimeMs != null) 'elapsed_time_ms': elapsedTimeMs,
      if (timerTimeMs != null) 'timer_time_ms': timerTimeMs,
      if (cumulativeDistanceMeters != null)
        'cumulative_distance_meters': cumulativeDistanceMeters,
      if (classification != null) 'classification': classification,
    });
  }

  WaypointsCompanion copyWith({
    Value<int>? id,
    Value<String>? activityGuid,
    Value<int>? seq,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? altitudeMeters,
    Value<double?>? horizontalAccuracyMeters,
    Value<double?>? verticalAccuracyMeters,
    Value<double?>? speedMetersPerSecond,
    Value<int>? elapsedTimeMs,
    Value<int>? timerTimeMs,
    Value<double>? cumulativeDistanceMeters,
    Value<int>? classification,
  }) {
    return WaypointsCompanion(
      id: id ?? this.id,
      activityGuid: activityGuid ?? this.activityGuid,
      seq: seq ?? this.seq,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      horizontalAccuracyMeters:
          horizontalAccuracyMeters ?? this.horizontalAccuracyMeters,
      verticalAccuracyMeters:
          verticalAccuracyMeters ?? this.verticalAccuracyMeters,
      speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
      elapsedTimeMs: elapsedTimeMs ?? this.elapsedTimeMs,
      timerTimeMs: timerTimeMs ?? this.timerTimeMs,
      cumulativeDistanceMeters:
          cumulativeDistanceMeters ?? this.cumulativeDistanceMeters,
      classification: classification ?? this.classification,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityGuid.present) {
      map['activity_guid'] = Variable<String>(activityGuid.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitudeMeters.present) {
      map['altitude_meters'] = Variable<double>(altitudeMeters.value);
    }
    if (horizontalAccuracyMeters.present) {
      map['horizontal_accuracy_meters'] = Variable<double>(
        horizontalAccuracyMeters.value,
      );
    }
    if (verticalAccuracyMeters.present) {
      map['vertical_accuracy_meters'] = Variable<double>(
        verticalAccuracyMeters.value,
      );
    }
    if (speedMetersPerSecond.present) {
      map['speed_meters_per_second'] = Variable<double>(
        speedMetersPerSecond.value,
      );
    }
    if (elapsedTimeMs.present) {
      map['elapsed_time_ms'] = Variable<int>(elapsedTimeMs.value);
    }
    if (timerTimeMs.present) {
      map['timer_time_ms'] = Variable<int>(timerTimeMs.value);
    }
    if (cumulativeDistanceMeters.present) {
      map['cumulative_distance_meters'] = Variable<double>(
        cumulativeDistanceMeters.value,
      );
    }
    if (classification.present) {
      map['classification'] = Variable<int>(classification.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaypointsCompanion(')
          ..write('id: $id, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('seq: $seq, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitudeMeters: $altitudeMeters, ')
          ..write('horizontalAccuracyMeters: $horizontalAccuracyMeters, ')
          ..write('verticalAccuracyMeters: $verticalAccuracyMeters, ')
          ..write('speedMetersPerSecond: $speedMetersPerSecond, ')
          ..write('elapsedTimeMs: $elapsedTimeMs, ')
          ..write('timerTimeMs: $timerTimeMs, ')
          ..write('cumulativeDistanceMeters: $cumulativeDistanceMeters, ')
          ..write('classification: $classification')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _useMetricMeta = const VerificationMeta(
    'useMetric',
  );
  @override
  late final GeneratedColumn<bool> useMetric = GeneratedColumn<bool>(
    'use_metric',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_metric" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoPauseEnabledMeta = const VerificationMeta(
    'autoPauseEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoPauseEnabled = GeneratedColumn<bool>(
    'auto_pause_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_pause_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reliabilityChecklistSeenMeta =
      const VerificationMeta('reliabilityChecklistSeen');
  @override
  late final GeneratedColumn<bool> reliabilityChecklistSeen =
      GeneratedColumn<bool>(
        'reliability_checklist_seen',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reliability_checklist_seen" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _hideOnServerMeta = const VerificationMeta(
    'hideOnServer',
  );
  @override
  late final GeneratedColumn<bool> hideOnServer = GeneratedColumn<bool>(
    'hide_on_server',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hide_on_server" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _narratorPrefsMeta = const VerificationMeta(
    'narratorPrefs',
  );
  @override
  late final GeneratedColumn<String> narratorPrefs = GeneratedColumn<String>(
    'narrator_prefs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gentleModeMeta = const VerificationMeta(
    'gentleMode',
  );
  @override
  late final GeneratedColumn<bool> gentleMode = GeneratedColumn<bool>(
    'gentle_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gentle_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _chapterMonthSeenMeta = const VerificationMeta(
    'chapterMonthSeen',
  );
  @override
  late final GeneratedColumn<int> chapterMonthSeen = GeneratedColumn<int>(
    'chapter_month_seen',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plan5kVoiceMeta = const VerificationMeta(
    'plan5kVoice',
  );
  @override
  late final GeneratedColumn<bool> plan5kVoice = GeneratedColumn<bool>(
    'plan5k_voice',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("plan5k_voice" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    useMetric,
    autoPauseEnabled,
    weightKg,
    reliabilityChecklistSeen,
    hideOnServer,
    narratorPrefs,
    gentleMode,
    chapterMonthSeen,
    plan5kVoice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('use_metric')) {
      context.handle(
        _useMetricMeta,
        useMetric.isAcceptableOrUnknown(data['use_metric']!, _useMetricMeta),
      );
    }
    if (data.containsKey('auto_pause_enabled')) {
      context.handle(
        _autoPauseEnabledMeta,
        autoPauseEnabled.isAcceptableOrUnknown(
          data['auto_pause_enabled']!,
          _autoPauseEnabledMeta,
        ),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('reliability_checklist_seen')) {
      context.handle(
        _reliabilityChecklistSeenMeta,
        reliabilityChecklistSeen.isAcceptableOrUnknown(
          data['reliability_checklist_seen']!,
          _reliabilityChecklistSeenMeta,
        ),
      );
    }
    if (data.containsKey('hide_on_server')) {
      context.handle(
        _hideOnServerMeta,
        hideOnServer.isAcceptableOrUnknown(
          data['hide_on_server']!,
          _hideOnServerMeta,
        ),
      );
    }
    if (data.containsKey('narrator_prefs')) {
      context.handle(
        _narratorPrefsMeta,
        narratorPrefs.isAcceptableOrUnknown(
          data['narrator_prefs']!,
          _narratorPrefsMeta,
        ),
      );
    }
    if (data.containsKey('gentle_mode')) {
      context.handle(
        _gentleModeMeta,
        gentleMode.isAcceptableOrUnknown(data['gentle_mode']!, _gentleModeMeta),
      );
    }
    if (data.containsKey('chapter_month_seen')) {
      context.handle(
        _chapterMonthSeenMeta,
        chapterMonthSeen.isAcceptableOrUnknown(
          data['chapter_month_seen']!,
          _chapterMonthSeenMeta,
        ),
      );
    }
    if (data.containsKey('plan5k_voice')) {
      context.handle(
        _plan5kVoiceMeta,
        plan5kVoice.isAcceptableOrUnknown(
          data['plan5k_voice']!,
          _plan5kVoiceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      useMetric: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_metric'],
      )!,
      autoPauseEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_pause_enabled'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      reliabilityChecklistSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reliability_checklist_seen'],
      )!,
      hideOnServer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_on_server'],
      )!,
      narratorPrefs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrator_prefs'],
      ),
      gentleMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gentle_mode'],
      )!,
      chapterMonthSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_month_seen'],
      ),
      plan5kVoice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}plan5k_voice'],
      )!,
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final bool useMetric;
  final bool autoPauseEnabled;

  /// Peso do usuario em kg, para estimar calorias. Null = nao informado (sem
  /// calorias).
  final double? weightKg;

  /// Checklist "Gravacao confiavel" ja mostrado antes da primeira gravacao.
  final bool reliabilityChecklistSeen;

  /// Privacidade (F02): o FIT enviado ao servidor sai sem os pontos ocultos.
  final bool hideOnServer;

  /// Narrador por voz (F03): preferencias em JSON (NarratorSettings). Null =
  /// padrao (desligado). JSON para crescer sem nova migracao.
  final String? narratorPrefs;

  /// Modo Gentil (F04): esconde pace e velocidade (gravacao, detalhe, imagem
  /// compartilhada e Narrador).
  final bool gentleMode;

  /// Capitulos (F05): `yyyymm` do ultimo mes cujo capitulo foi aberto ou
  /// dispensado. O cartao do Inicio so oferece meses depois deste. Null =
  /// nenhum ainda.
  final int? chapterMonthSeen;

  /// Plano 5 km (F06): "Voz do plano", independente do Narrador geral.
  /// Padrao ligada.
  final bool plan5kVoice;
  const SettingsRow({
    required this.id,
    required this.useMetric,
    required this.autoPauseEnabled,
    this.weightKg,
    required this.reliabilityChecklistSeen,
    required this.hideOnServer,
    this.narratorPrefs,
    required this.gentleMode,
    this.chapterMonthSeen,
    required this.plan5kVoice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['use_metric'] = Variable<bool>(useMetric);
    map['auto_pause_enabled'] = Variable<bool>(autoPauseEnabled);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['reliability_checklist_seen'] = Variable<bool>(
      reliabilityChecklistSeen,
    );
    map['hide_on_server'] = Variable<bool>(hideOnServer);
    if (!nullToAbsent || narratorPrefs != null) {
      map['narrator_prefs'] = Variable<String>(narratorPrefs);
    }
    map['gentle_mode'] = Variable<bool>(gentleMode);
    if (!nullToAbsent || chapterMonthSeen != null) {
      map['chapter_month_seen'] = Variable<int>(chapterMonthSeen);
    }
    map['plan5k_voice'] = Variable<bool>(plan5kVoice);
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      useMetric: Value(useMetric),
      autoPauseEnabled: Value(autoPauseEnabled),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      reliabilityChecklistSeen: Value(reliabilityChecklistSeen),
      hideOnServer: Value(hideOnServer),
      narratorPrefs: narratorPrefs == null && nullToAbsent
          ? const Value.absent()
          : Value(narratorPrefs),
      gentleMode: Value(gentleMode),
      chapterMonthSeen: chapterMonthSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterMonthSeen),
      plan5kVoice: Value(plan5kVoice),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      useMetric: serializer.fromJson<bool>(json['useMetric']),
      autoPauseEnabled: serializer.fromJson<bool>(json['autoPauseEnabled']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      reliabilityChecklistSeen: serializer.fromJson<bool>(
        json['reliabilityChecklistSeen'],
      ),
      hideOnServer: serializer.fromJson<bool>(json['hideOnServer']),
      narratorPrefs: serializer.fromJson<String?>(json['narratorPrefs']),
      gentleMode: serializer.fromJson<bool>(json['gentleMode']),
      chapterMonthSeen: serializer.fromJson<int?>(json['chapterMonthSeen']),
      plan5kVoice: serializer.fromJson<bool>(json['plan5kVoice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'useMetric': serializer.toJson<bool>(useMetric),
      'autoPauseEnabled': serializer.toJson<bool>(autoPauseEnabled),
      'weightKg': serializer.toJson<double?>(weightKg),
      'reliabilityChecklistSeen': serializer.toJson<bool>(
        reliabilityChecklistSeen,
      ),
      'hideOnServer': serializer.toJson<bool>(hideOnServer),
      'narratorPrefs': serializer.toJson<String?>(narratorPrefs),
      'gentleMode': serializer.toJson<bool>(gentleMode),
      'chapterMonthSeen': serializer.toJson<int?>(chapterMonthSeen),
      'plan5kVoice': serializer.toJson<bool>(plan5kVoice),
    };
  }

  SettingsRow copyWith({
    int? id,
    bool? useMetric,
    bool? autoPauseEnabled,
    Value<double?> weightKg = const Value.absent(),
    bool? reliabilityChecklistSeen,
    bool? hideOnServer,
    Value<String?> narratorPrefs = const Value.absent(),
    bool? gentleMode,
    Value<int?> chapterMonthSeen = const Value.absent(),
    bool? plan5kVoice,
  }) => SettingsRow(
    id: id ?? this.id,
    useMetric: useMetric ?? this.useMetric,
    autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    reliabilityChecklistSeen:
        reliabilityChecklistSeen ?? this.reliabilityChecklistSeen,
    hideOnServer: hideOnServer ?? this.hideOnServer,
    narratorPrefs: narratorPrefs.present
        ? narratorPrefs.value
        : this.narratorPrefs,
    gentleMode: gentleMode ?? this.gentleMode,
    chapterMonthSeen: chapterMonthSeen.present
        ? chapterMonthSeen.value
        : this.chapterMonthSeen,
    plan5kVoice: plan5kVoice ?? this.plan5kVoice,
  );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      useMetric: data.useMetric.present ? data.useMetric.value : this.useMetric,
      autoPauseEnabled: data.autoPauseEnabled.present
          ? data.autoPauseEnabled.value
          : this.autoPauseEnabled,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      reliabilityChecklistSeen: data.reliabilityChecklistSeen.present
          ? data.reliabilityChecklistSeen.value
          : this.reliabilityChecklistSeen,
      hideOnServer: data.hideOnServer.present
          ? data.hideOnServer.value
          : this.hideOnServer,
      narratorPrefs: data.narratorPrefs.present
          ? data.narratorPrefs.value
          : this.narratorPrefs,
      gentleMode: data.gentleMode.present
          ? data.gentleMode.value
          : this.gentleMode,
      chapterMonthSeen: data.chapterMonthSeen.present
          ? data.chapterMonthSeen.value
          : this.chapterMonthSeen,
      plan5kVoice: data.plan5kVoice.present
          ? data.plan5kVoice.value
          : this.plan5kVoice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('useMetric: $useMetric, ')
          ..write('autoPauseEnabled: $autoPauseEnabled, ')
          ..write('weightKg: $weightKg, ')
          ..write('reliabilityChecklistSeen: $reliabilityChecklistSeen, ')
          ..write('hideOnServer: $hideOnServer, ')
          ..write('narratorPrefs: $narratorPrefs, ')
          ..write('gentleMode: $gentleMode, ')
          ..write('chapterMonthSeen: $chapterMonthSeen, ')
          ..write('plan5kVoice: $plan5kVoice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    useMetric,
    autoPauseEnabled,
    weightKg,
    reliabilityChecklistSeen,
    hideOnServer,
    narratorPrefs,
    gentleMode,
    chapterMonthSeen,
    plan5kVoice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.useMetric == this.useMetric &&
          other.autoPauseEnabled == this.autoPauseEnabled &&
          other.weightKg == this.weightKg &&
          other.reliabilityChecklistSeen == this.reliabilityChecklistSeen &&
          other.hideOnServer == this.hideOnServer &&
          other.narratorPrefs == this.narratorPrefs &&
          other.gentleMode == this.gentleMode &&
          other.chapterMonthSeen == this.chapterMonthSeen &&
          other.plan5kVoice == this.plan5kVoice);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<bool> useMetric;
  final Value<bool> autoPauseEnabled;
  final Value<double?> weightKg;
  final Value<bool> reliabilityChecklistSeen;
  final Value<bool> hideOnServer;
  final Value<String?> narratorPrefs;
  final Value<bool> gentleMode;
  final Value<int?> chapterMonthSeen;
  final Value<bool> plan5kVoice;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.useMetric = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reliabilityChecklistSeen = const Value.absent(),
    this.hideOnServer = const Value.absent(),
    this.narratorPrefs = const Value.absent(),
    this.gentleMode = const Value.absent(),
    this.chapterMonthSeen = const Value.absent(),
    this.plan5kVoice = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    this.useMetric = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reliabilityChecklistSeen = const Value.absent(),
    this.hideOnServer = const Value.absent(),
    this.narratorPrefs = const Value.absent(),
    this.gentleMode = const Value.absent(),
    this.chapterMonthSeen = const Value.absent(),
    this.plan5kVoice = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? useMetric,
    Expression<bool>? autoPauseEnabled,
    Expression<double>? weightKg,
    Expression<bool>? reliabilityChecklistSeen,
    Expression<bool>? hideOnServer,
    Expression<String>? narratorPrefs,
    Expression<bool>? gentleMode,
    Expression<int>? chapterMonthSeen,
    Expression<bool>? plan5kVoice,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (useMetric != null) 'use_metric': useMetric,
      if (autoPauseEnabled != null) 'auto_pause_enabled': autoPauseEnabled,
      if (weightKg != null) 'weight_kg': weightKg,
      if (reliabilityChecklistSeen != null)
        'reliability_checklist_seen': reliabilityChecklistSeen,
      if (hideOnServer != null) 'hide_on_server': hideOnServer,
      if (narratorPrefs != null) 'narrator_prefs': narratorPrefs,
      if (gentleMode != null) 'gentle_mode': gentleMode,
      if (chapterMonthSeen != null) 'chapter_month_seen': chapterMonthSeen,
      if (plan5kVoice != null) 'plan5k_voice': plan5kVoice,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<bool>? useMetric,
    Value<bool>? autoPauseEnabled,
    Value<double?>? weightKg,
    Value<bool>? reliabilityChecklistSeen,
    Value<bool>? hideOnServer,
    Value<String?>? narratorPrefs,
    Value<bool>? gentleMode,
    Value<int?>? chapterMonthSeen,
    Value<bool>? plan5kVoice,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      useMetric: useMetric ?? this.useMetric,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      weightKg: weightKg ?? this.weightKg,
      reliabilityChecklistSeen:
          reliabilityChecklistSeen ?? this.reliabilityChecklistSeen,
      hideOnServer: hideOnServer ?? this.hideOnServer,
      narratorPrefs: narratorPrefs ?? this.narratorPrefs,
      gentleMode: gentleMode ?? this.gentleMode,
      chapterMonthSeen: chapterMonthSeen ?? this.chapterMonthSeen,
      plan5kVoice: plan5kVoice ?? this.plan5kVoice,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (useMetric.present) {
      map['use_metric'] = Variable<bool>(useMetric.value);
    }
    if (autoPauseEnabled.present) {
      map['auto_pause_enabled'] = Variable<bool>(autoPauseEnabled.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (reliabilityChecklistSeen.present) {
      map['reliability_checklist_seen'] = Variable<bool>(
        reliabilityChecklistSeen.value,
      );
    }
    if (hideOnServer.present) {
      map['hide_on_server'] = Variable<bool>(hideOnServer.value);
    }
    if (narratorPrefs.present) {
      map['narrator_prefs'] = Variable<String>(narratorPrefs.value);
    }
    if (gentleMode.present) {
      map['gentle_mode'] = Variable<bool>(gentleMode.value);
    }
    if (chapterMonthSeen.present) {
      map['chapter_month_seen'] = Variable<int>(chapterMonthSeen.value);
    }
    if (plan5kVoice.present) {
      map['plan5k_voice'] = Variable<bool>(plan5kVoice.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('useMetric: $useMetric, ')
          ..write('autoPauseEnabled: $autoPauseEnabled, ')
          ..write('weightKg: $weightKg, ')
          ..write('reliabilityChecklistSeen: $reliabilityChecklistSeen, ')
          ..write('hideOnServer: $hideOnServer, ')
          ..write('narratorPrefs: $narratorPrefs, ')
          ..write('gentleMode: $gentleMode, ')
          ..write('chapterMonthSeen: $chapterMonthSeen, ')
          ..write('plan5kVoice: $plan5kVoice')
          ..write(')'))
        .toString();
  }
}

class $RemoteDeletionsTable extends RemoteDeletions
    with TableInfo<$RemoteDeletionsTable, RemoteDeletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteDeletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [remoteId, ownerUserId, createdAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteDeletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteId};
  @override
  RemoteDeletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteDeletion(
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $RemoteDeletionsTable createAlias(String alias) {
    return $RemoteDeletionsTable(attachedDatabase, alias);
  }
}

class RemoteDeletion extends DataClass implements Insertable<RemoteDeletion> {
  final String remoteId;
  final String? ownerUserId;
  final int createdAtMs;
  const RemoteDeletion({
    required this.remoteId,
    this.ownerUserId,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_id'] = Variable<String>(remoteId);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  RemoteDeletionsCompanion toCompanion(bool nullToAbsent) {
    return RemoteDeletionsCompanion(
      remoteId: Value(remoteId),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory RemoteDeletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteDeletion(
      remoteId: serializer.fromJson<String>(json['remoteId']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteId': serializer.toJson<String>(remoteId),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  RemoteDeletion copyWith({
    String? remoteId,
    Value<String?> ownerUserId = const Value.absent(),
    int? createdAtMs,
  }) => RemoteDeletion(
    remoteId: remoteId ?? this.remoteId,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  RemoteDeletion copyWithCompanion(RemoteDeletionsCompanion data) {
    return RemoteDeletion(
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteDeletion(')
          ..write('remoteId: $remoteId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(remoteId, ownerUserId, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteDeletion &&
          other.remoteId == this.remoteId &&
          other.ownerUserId == this.ownerUserId &&
          other.createdAtMs == this.createdAtMs);
}

class RemoteDeletionsCompanion extends UpdateCompanion<RemoteDeletion> {
  final Value<String> remoteId;
  final Value<String?> ownerUserId;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const RemoteDeletionsCompanion({
    this.remoteId = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteDeletionsCompanion.insert({
    required String remoteId,
    this.ownerUserId = const Value.absent(),
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : remoteId = Value(remoteId),
       createdAtMs = Value(createdAtMs);
  static Insertable<RemoteDeletion> custom({
    Expression<String>? remoteId,
    Expression<String>? ownerUserId,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteId != null) 'remote_id': remoteId,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteDeletionsCompanion copyWith({
    Value<String>? remoteId,
    Value<String?>? ownerUserId,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return RemoteDeletionsCompanion(
      remoteId: remoteId ?? this.remoteId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteDeletionsCompanion(')
          ..write('remoteId: $remoteId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LapsTable extends Laps with TableInfo<$LapsTable, Lap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _activityGuidMeta = const VerificationMeta(
    'activityGuid',
  );
  @override
  late final GeneratedColumn<String> activityGuid = GeneratedColumn<String>(
    'activity_guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (guid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimerMsMeta = const VerificationMeta(
    'startTimerMs',
  );
  @override
  late final GeneratedColumn<int> startTimerMs = GeneratedColumn<int>(
    'start_timer_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimerMsMeta = const VerificationMeta(
    'endTimerMs',
  );
  @override
  late final GeneratedColumn<int> endTimerMs = GeneratedColumn<int>(
    'end_timer_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endElapsedMsMeta = const VerificationMeta(
    'endElapsedMs',
  );
  @override
  late final GeneratedColumn<int> endElapsedMs = GeneratedColumn<int>(
    'end_elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDistanceMetersMeta =
      const VerificationMeta('startDistanceMeters');
  @override
  late final GeneratedColumn<double> startDistanceMeters =
      GeneratedColumn<double>(
        'start_distance_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _endDistanceMetersMeta = const VerificationMeta(
    'endDistanceMeters',
  );
  @override
  late final GeneratedColumn<double> endDistanceMeters =
      GeneratedColumn<double>(
        'end_distance_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    activityGuid,
    number,
    startTimerMs,
    endTimerMs,
    endElapsedMs,
    startDistanceMeters,
    endDistanceMeters,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'laps';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('activity_guid')) {
      context.handle(
        _activityGuidMeta,
        activityGuid.isAcceptableOrUnknown(
          data['activity_guid']!,
          _activityGuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityGuidMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('start_timer_ms')) {
      context.handle(
        _startTimerMsMeta,
        startTimerMs.isAcceptableOrUnknown(
          data['start_timer_ms']!,
          _startTimerMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startTimerMsMeta);
    }
    if (data.containsKey('end_timer_ms')) {
      context.handle(
        _endTimerMsMeta,
        endTimerMs.isAcceptableOrUnknown(
          data['end_timer_ms']!,
          _endTimerMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endTimerMsMeta);
    }
    if (data.containsKey('end_elapsed_ms')) {
      context.handle(
        _endElapsedMsMeta,
        endElapsedMs.isAcceptableOrUnknown(
          data['end_elapsed_ms']!,
          _endElapsedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endElapsedMsMeta);
    }
    if (data.containsKey('start_distance_meters')) {
      context.handle(
        _startDistanceMetersMeta,
        startDistanceMeters.isAcceptableOrUnknown(
          data['start_distance_meters']!,
          _startDistanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startDistanceMetersMeta);
    }
    if (data.containsKey('end_distance_meters')) {
      context.handle(
        _endDistanceMetersMeta,
        endDistanceMeters.isAcceptableOrUnknown(
          data['end_distance_meters']!,
          _endDistanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endDistanceMetersMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {activityGuid, number};
  @override
  Lap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lap(
      activityGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_guid'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      startTimerMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_timer_ms'],
      )!,
      endTimerMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_timer_ms'],
      )!,
      endElapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_elapsed_ms'],
      )!,
      startDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_distance_meters'],
      )!,
      endDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_distance_meters'],
      )!,
    );
  }

  @override
  $LapsTable createAlias(String alias) {
    return $LapsTable(attachedDatabase, alias);
  }
}

class Lap extends DataClass implements Insertable<Lap> {
  final String activityGuid;
  final int number;
  final int startTimerMs;
  final int endTimerMs;
  final int endElapsedMs;
  final double startDistanceMeters;
  final double endDistanceMeters;
  const Lap({
    required this.activityGuid,
    required this.number,
    required this.startTimerMs,
    required this.endTimerMs,
    required this.endElapsedMs,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['activity_guid'] = Variable<String>(activityGuid);
    map['number'] = Variable<int>(number);
    map['start_timer_ms'] = Variable<int>(startTimerMs);
    map['end_timer_ms'] = Variable<int>(endTimerMs);
    map['end_elapsed_ms'] = Variable<int>(endElapsedMs);
    map['start_distance_meters'] = Variable<double>(startDistanceMeters);
    map['end_distance_meters'] = Variable<double>(endDistanceMeters);
    return map;
  }

  LapsCompanion toCompanion(bool nullToAbsent) {
    return LapsCompanion(
      activityGuid: Value(activityGuid),
      number: Value(number),
      startTimerMs: Value(startTimerMs),
      endTimerMs: Value(endTimerMs),
      endElapsedMs: Value(endElapsedMs),
      startDistanceMeters: Value(startDistanceMeters),
      endDistanceMeters: Value(endDistanceMeters),
    );
  }

  factory Lap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lap(
      activityGuid: serializer.fromJson<String>(json['activityGuid']),
      number: serializer.fromJson<int>(json['number']),
      startTimerMs: serializer.fromJson<int>(json['startTimerMs']),
      endTimerMs: serializer.fromJson<int>(json['endTimerMs']),
      endElapsedMs: serializer.fromJson<int>(json['endElapsedMs']),
      startDistanceMeters: serializer.fromJson<double>(
        json['startDistanceMeters'],
      ),
      endDistanceMeters: serializer.fromJson<double>(json['endDistanceMeters']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'activityGuid': serializer.toJson<String>(activityGuid),
      'number': serializer.toJson<int>(number),
      'startTimerMs': serializer.toJson<int>(startTimerMs),
      'endTimerMs': serializer.toJson<int>(endTimerMs),
      'endElapsedMs': serializer.toJson<int>(endElapsedMs),
      'startDistanceMeters': serializer.toJson<double>(startDistanceMeters),
      'endDistanceMeters': serializer.toJson<double>(endDistanceMeters),
    };
  }

  Lap copyWith({
    String? activityGuid,
    int? number,
    int? startTimerMs,
    int? endTimerMs,
    int? endElapsedMs,
    double? startDistanceMeters,
    double? endDistanceMeters,
  }) => Lap(
    activityGuid: activityGuid ?? this.activityGuid,
    number: number ?? this.number,
    startTimerMs: startTimerMs ?? this.startTimerMs,
    endTimerMs: endTimerMs ?? this.endTimerMs,
    endElapsedMs: endElapsedMs ?? this.endElapsedMs,
    startDistanceMeters: startDistanceMeters ?? this.startDistanceMeters,
    endDistanceMeters: endDistanceMeters ?? this.endDistanceMeters,
  );
  Lap copyWithCompanion(LapsCompanion data) {
    return Lap(
      activityGuid: data.activityGuid.present
          ? data.activityGuid.value
          : this.activityGuid,
      number: data.number.present ? data.number.value : this.number,
      startTimerMs: data.startTimerMs.present
          ? data.startTimerMs.value
          : this.startTimerMs,
      endTimerMs: data.endTimerMs.present
          ? data.endTimerMs.value
          : this.endTimerMs,
      endElapsedMs: data.endElapsedMs.present
          ? data.endElapsedMs.value
          : this.endElapsedMs,
      startDistanceMeters: data.startDistanceMeters.present
          ? data.startDistanceMeters.value
          : this.startDistanceMeters,
      endDistanceMeters: data.endDistanceMeters.present
          ? data.endDistanceMeters.value
          : this.endDistanceMeters,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lap(')
          ..write('activityGuid: $activityGuid, ')
          ..write('number: $number, ')
          ..write('startTimerMs: $startTimerMs, ')
          ..write('endTimerMs: $endTimerMs, ')
          ..write('endElapsedMs: $endElapsedMs, ')
          ..write('startDistanceMeters: $startDistanceMeters, ')
          ..write('endDistanceMeters: $endDistanceMeters')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    activityGuid,
    number,
    startTimerMs,
    endTimerMs,
    endElapsedMs,
    startDistanceMeters,
    endDistanceMeters,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lap &&
          other.activityGuid == this.activityGuid &&
          other.number == this.number &&
          other.startTimerMs == this.startTimerMs &&
          other.endTimerMs == this.endTimerMs &&
          other.endElapsedMs == this.endElapsedMs &&
          other.startDistanceMeters == this.startDistanceMeters &&
          other.endDistanceMeters == this.endDistanceMeters);
}

class LapsCompanion extends UpdateCompanion<Lap> {
  final Value<String> activityGuid;
  final Value<int> number;
  final Value<int> startTimerMs;
  final Value<int> endTimerMs;
  final Value<int> endElapsedMs;
  final Value<double> startDistanceMeters;
  final Value<double> endDistanceMeters;
  final Value<int> rowid;
  const LapsCompanion({
    this.activityGuid = const Value.absent(),
    this.number = const Value.absent(),
    this.startTimerMs = const Value.absent(),
    this.endTimerMs = const Value.absent(),
    this.endElapsedMs = const Value.absent(),
    this.startDistanceMeters = const Value.absent(),
    this.endDistanceMeters = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LapsCompanion.insert({
    required String activityGuid,
    required int number,
    required int startTimerMs,
    required int endTimerMs,
    required int endElapsedMs,
    required double startDistanceMeters,
    required double endDistanceMeters,
    this.rowid = const Value.absent(),
  }) : activityGuid = Value(activityGuid),
       number = Value(number),
       startTimerMs = Value(startTimerMs),
       endTimerMs = Value(endTimerMs),
       endElapsedMs = Value(endElapsedMs),
       startDistanceMeters = Value(startDistanceMeters),
       endDistanceMeters = Value(endDistanceMeters);
  static Insertable<Lap> custom({
    Expression<String>? activityGuid,
    Expression<int>? number,
    Expression<int>? startTimerMs,
    Expression<int>? endTimerMs,
    Expression<int>? endElapsedMs,
    Expression<double>? startDistanceMeters,
    Expression<double>? endDistanceMeters,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (activityGuid != null) 'activity_guid': activityGuid,
      if (number != null) 'number': number,
      if (startTimerMs != null) 'start_timer_ms': startTimerMs,
      if (endTimerMs != null) 'end_timer_ms': endTimerMs,
      if (endElapsedMs != null) 'end_elapsed_ms': endElapsedMs,
      if (startDistanceMeters != null)
        'start_distance_meters': startDistanceMeters,
      if (endDistanceMeters != null) 'end_distance_meters': endDistanceMeters,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LapsCompanion copyWith({
    Value<String>? activityGuid,
    Value<int>? number,
    Value<int>? startTimerMs,
    Value<int>? endTimerMs,
    Value<int>? endElapsedMs,
    Value<double>? startDistanceMeters,
    Value<double>? endDistanceMeters,
    Value<int>? rowid,
  }) {
    return LapsCompanion(
      activityGuid: activityGuid ?? this.activityGuid,
      number: number ?? this.number,
      startTimerMs: startTimerMs ?? this.startTimerMs,
      endTimerMs: endTimerMs ?? this.endTimerMs,
      endElapsedMs: endElapsedMs ?? this.endElapsedMs,
      startDistanceMeters: startDistanceMeters ?? this.startDistanceMeters,
      endDistanceMeters: endDistanceMeters ?? this.endDistanceMeters,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (activityGuid.present) {
      map['activity_guid'] = Variable<String>(activityGuid.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (startTimerMs.present) {
      map['start_timer_ms'] = Variable<int>(startTimerMs.value);
    }
    if (endTimerMs.present) {
      map['end_timer_ms'] = Variable<int>(endTimerMs.value);
    }
    if (endElapsedMs.present) {
      map['end_elapsed_ms'] = Variable<int>(endElapsedMs.value);
    }
    if (startDistanceMeters.present) {
      map['start_distance_meters'] = Variable<double>(
        startDistanceMeters.value,
      );
    }
    if (endDistanceMeters.present) {
      map['end_distance_meters'] = Variable<double>(endDistanceMeters.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LapsCompanion(')
          ..write('activityGuid: $activityGuid, ')
          ..write('number: $number, ')
          ..write('startTimerMs: $startTimerMs, ')
          ..write('endTimerMs: $endTimerMs, ')
          ..write('endElapsedMs: $endElapsedMs, ')
          ..write('startDistanceMeters: $startDistanceMeters, ')
          ..write('endDistanceMeters: $endDistanceMeters, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordingGapsTable extends RecordingGaps
    with TableInfo<$RecordingGapsTable, RecordingGapRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingGapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityGuidMeta = const VerificationMeta(
    'activityGuid',
  );
  @override
  late final GeneratedColumn<String> activityGuid = GeneratedColumn<String>(
    'activity_guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (guid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<int> reason = GeneratedColumn<int>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityGuid,
    startMs,
    endMs,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recording_gaps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordingGapRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_guid')) {
      context.handle(
        _activityGuidMeta,
        activityGuid.isAcceptableOrUnknown(
          data['activity_guid']!,
          _activityGuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityGuidMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordingGapRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingGapRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_guid'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $RecordingGapsTable createAlias(String alias) {
    return $RecordingGapsTable(attachedDatabase, alias);
  }
}

class RecordingGapRow extends DataClass implements Insertable<RecordingGapRow> {
  final int id;
  final String activityGuid;
  final int startMs;
  final int endMs;
  final int reason;
  const RecordingGapRow({
    required this.id,
    required this.activityGuid,
    required this.startMs,
    required this.endMs,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_guid'] = Variable<String>(activityGuid);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['reason'] = Variable<int>(reason);
    return map;
  }

  RecordingGapsCompanion toCompanion(bool nullToAbsent) {
    return RecordingGapsCompanion(
      id: Value(id),
      activityGuid: Value(activityGuid),
      startMs: Value(startMs),
      endMs: Value(endMs),
      reason: Value(reason),
    );
  }

  factory RecordingGapRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingGapRow(
      id: serializer.fromJson<int>(json['id']),
      activityGuid: serializer.fromJson<String>(json['activityGuid']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      reason: serializer.fromJson<int>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityGuid': serializer.toJson<String>(activityGuid),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'reason': serializer.toJson<int>(reason),
    };
  }

  RecordingGapRow copyWith({
    int? id,
    String? activityGuid,
    int? startMs,
    int? endMs,
    int? reason,
  }) => RecordingGapRow(
    id: id ?? this.id,
    activityGuid: activityGuid ?? this.activityGuid,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    reason: reason ?? this.reason,
  );
  RecordingGapRow copyWithCompanion(RecordingGapsCompanion data) {
    return RecordingGapRow(
      id: data.id.present ? data.id.value : this.id,
      activityGuid: data.activityGuid.present
          ? data.activityGuid.value
          : this.activityGuid,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingGapRow(')
          ..write('id: $id, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, activityGuid, startMs, endMs, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingGapRow &&
          other.id == this.id &&
          other.activityGuid == this.activityGuid &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.reason == this.reason);
}

class RecordingGapsCompanion extends UpdateCompanion<RecordingGapRow> {
  final Value<int> id;
  final Value<String> activityGuid;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<int> reason;
  const RecordingGapsCompanion({
    this.id = const Value.absent(),
    this.activityGuid = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.reason = const Value.absent(),
  });
  RecordingGapsCompanion.insert({
    this.id = const Value.absent(),
    required String activityGuid,
    required int startMs,
    required int endMs,
    required int reason,
  }) : activityGuid = Value(activityGuid),
       startMs = Value(startMs),
       endMs = Value(endMs),
       reason = Value(reason);
  static Insertable<RecordingGapRow> custom({
    Expression<int>? id,
    Expression<String>? activityGuid,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<int>? reason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityGuid != null) 'activity_guid': activityGuid,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (reason != null) 'reason': reason,
    });
  }

  RecordingGapsCompanion copyWith({
    Value<int>? id,
    Value<String>? activityGuid,
    Value<int>? startMs,
    Value<int>? endMs,
    Value<int>? reason,
  }) {
    return RecordingGapsCompanion(
      id: id ?? this.id,
      activityGuid: activityGuid ?? this.activityGuid,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityGuid.present) {
      map['activity_guid'] = Variable<String>(activityGuid.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (reason.present) {
      map['reason'] = Variable<int>(reason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingGapsCompanion(')
          ..write('id: $id, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }
}

class $PrivacyZonesTable extends PrivacyZones
    with TableInfo<$PrivacyZonesTable, PrivacyZoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrivacyZonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMetersMeta = const VerificationMeta(
    'radiusMeters',
  );
  @override
  late final GeneratedColumn<double> radiusMeters = GeneratedColumn<double>(
    'radius_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    latitude,
    longitude,
    radiusMeters,
    label,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'privacy_zones';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrivacyZoneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius_meters')) {
      context.handle(
        _radiusMetersMeta,
        radiusMeters.isAcceptableOrUnknown(
          data['radius_meters']!,
          _radiusMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_radiusMetersMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrivacyZoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrivacyZoneRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      radiusMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_meters'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $PrivacyZonesTable createAlias(String alias) {
    return $PrivacyZonesTable(attachedDatabase, alias);
  }
}

class PrivacyZoneRow extends DataClass implements Insertable<PrivacyZoneRow> {
  final int id;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String label;
  final int createdAtMs;
  const PrivacyZoneRow({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.label,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_meters'] = Variable<double>(radiusMeters);
    map['label'] = Variable<String>(label);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  PrivacyZonesCompanion toCompanion(bool nullToAbsent) {
    return PrivacyZonesCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusMeters: Value(radiusMeters),
      label: Value(label),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory PrivacyZoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrivacyZoneRow(
      id: serializer.fromJson<int>(json['id']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusMeters: serializer.fromJson<double>(json['radiusMeters']),
      label: serializer.fromJson<String>(json['label']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusMeters': serializer.toJson<double>(radiusMeters),
      'label': serializer.toJson<String>(label),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  PrivacyZoneRow copyWith({
    int? id,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? label,
    int? createdAtMs,
  }) => PrivacyZoneRow(
    id: id ?? this.id,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    label: label ?? this.label,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  PrivacyZoneRow copyWithCompanion(PrivacyZonesCompanion data) {
    return PrivacyZoneRow(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusMeters: data.radiusMeters.present
          ? data.radiusMeters.value
          : this.radiusMeters,
      label: data.label.present ? data.label.value : this.label,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrivacyZoneRow(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('label: $label, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, latitude, longitude, radiusMeters, label, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrivacyZoneRow &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusMeters == this.radiusMeters &&
          other.label == this.label &&
          other.createdAtMs == this.createdAtMs);
}

class PrivacyZonesCompanion extends UpdateCompanion<PrivacyZoneRow> {
  final Value<int> id;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radiusMeters;
  final Value<String> label;
  final Value<int> createdAtMs;
  const PrivacyZonesCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusMeters = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAtMs = const Value.absent(),
  });
  PrivacyZonesCompanion.insert({
    this.id = const Value.absent(),
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String label,
    required int createdAtMs,
  }) : latitude = Value(latitude),
       longitude = Value(longitude),
       radiusMeters = Value(radiusMeters),
       label = Value(label),
       createdAtMs = Value(createdAtMs);
  static Insertable<PrivacyZoneRow> custom({
    Expression<int>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusMeters,
    Expression<String>? label,
    Expression<int>? createdAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
      if (label != null) 'label': label,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
    });
  }

  PrivacyZonesCompanion copyWith({
    Value<int>? id,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? radiusMeters,
    Value<String>? label,
    Value<int>? createdAtMs,
  }) {
    return PrivacyZonesCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      label: label ?? this.label,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusMeters.present) {
      map['radius_meters'] = Variable<double>(radiusMeters.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrivacyZonesCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('label: $label, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }
}

class $DismissedZoneSuggestionsTable extends DismissedZoneSuggestions
    with TableInfo<$DismissedZoneSuggestionsTable, DismissedZoneSuggestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DismissedZoneSuggestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, latitude, longitude, createdAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dismissed_zone_suggestions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DismissedZoneSuggestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DismissedZoneSuggestionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DismissedZoneSuggestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $DismissedZoneSuggestionsTable createAlias(String alias) {
    return $DismissedZoneSuggestionsTable(attachedDatabase, alias);
  }
}

class DismissedZoneSuggestionRow extends DataClass
    implements Insertable<DismissedZoneSuggestionRow> {
  final int id;
  final double latitude;
  final double longitude;
  final int createdAtMs;
  const DismissedZoneSuggestionRow({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  DismissedZoneSuggestionsCompanion toCompanion(bool nullToAbsent) {
    return DismissedZoneSuggestionsCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory DismissedZoneSuggestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DismissedZoneSuggestionRow(
      id: serializer.fromJson<int>(json['id']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  DismissedZoneSuggestionRow copyWith({
    int? id,
    double? latitude,
    double? longitude,
    int? createdAtMs,
  }) => DismissedZoneSuggestionRow(
    id: id ?? this.id,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  DismissedZoneSuggestionRow copyWithCompanion(
    DismissedZoneSuggestionsCompanion data,
  ) {
    return DismissedZoneSuggestionRow(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DismissedZoneSuggestionRow(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, latitude, longitude, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DismissedZoneSuggestionRow &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAtMs == this.createdAtMs);
}

class DismissedZoneSuggestionsCompanion
    extends UpdateCompanion<DismissedZoneSuggestionRow> {
  final Value<int> id;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> createdAtMs;
  const DismissedZoneSuggestionsCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAtMs = const Value.absent(),
  });
  DismissedZoneSuggestionsCompanion.insert({
    this.id = const Value.absent(),
    required double latitude,
    required double longitude,
    required int createdAtMs,
  }) : latitude = Value(latitude),
       longitude = Value(longitude),
       createdAtMs = Value(createdAtMs);
  static Insertable<DismissedZoneSuggestionRow> custom({
    Expression<int>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? createdAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
    });
  }

  DismissedZoneSuggestionsCompanion copyWith({
    Value<int>? id,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? createdAtMs,
  }) {
    return DismissedZoneSuggestionsCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DismissedZoneSuggestionsCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }
}

class $Plan5kStatesTable extends Plan5kStates
    with TableInfo<$Plan5kStatesTable, Plan5kStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $Plan5kStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedMeta = const VerificationMeta(
    'started',
  );
  @override
  late final GeneratedColumn<bool> started = GeneratedColumn<bool>(
    'started',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("started" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startWeekMeta = const VerificationMeta(
    'startWeek',
  );
  @override
  late final GeneratedColumn<int> startWeek = GeneratedColumn<int>(
    'start_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currentWeekMeta = const VerificationMeta(
    'currentWeek',
  );
  @override
  late final GeneratedColumn<int> currentWeek = GeneratedColumn<int>(
    'current_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _repeatsMeta = const VerificationMeta(
    'repeats',
  );
  @override
  late final GeneratedColumn<String> repeats = GeneratedColumn<String>(
    'repeats',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedMeta = const VerificationMeta(
    'finished',
  );
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
    'finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    started,
    startWeek,
    currentWeek,
    repeats,
    finished,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan5k_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plan5kStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started')) {
      context.handle(
        _startedMeta,
        started.isAcceptableOrUnknown(data['started']!, _startedMeta),
      );
    }
    if (data.containsKey('start_week')) {
      context.handle(
        _startWeekMeta,
        startWeek.isAcceptableOrUnknown(data['start_week']!, _startWeekMeta),
      );
    }
    if (data.containsKey('current_week')) {
      context.handle(
        _currentWeekMeta,
        currentWeek.isAcceptableOrUnknown(
          data['current_week']!,
          _currentWeekMeta,
        ),
      );
    }
    if (data.containsKey('repeats')) {
      context.handle(
        _repeatsMeta,
        repeats.isAcceptableOrUnknown(data['repeats']!, _repeatsMeta),
      );
    }
    if (data.containsKey('finished')) {
      context.handle(
        _finishedMeta,
        finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan5kStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan5kStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      started: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}started'],
      )!,
      startWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_week'],
      )!,
      currentWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_week'],
      )!,
      repeats: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeats'],
      ),
      finished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finished'],
      )!,
    );
  }

  @override
  $Plan5kStatesTable createAlias(String alias) {
    return $Plan5kStatesTable(attachedDatabase, alias);
  }
}

class Plan5kStateRow extends DataClass implements Insertable<Plan5kStateRow> {
  final int id;
  final bool started;
  final int startWeek;
  final int currentWeek;

  /// Repeticoes por semana em JSON ({"3": 1}). Null = nenhuma.
  final String? repeats;
  final bool finished;
  const Plan5kStateRow({
    required this.id,
    required this.started,
    required this.startWeek,
    required this.currentWeek,
    this.repeats,
    required this.finished,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started'] = Variable<bool>(started);
    map['start_week'] = Variable<int>(startWeek);
    map['current_week'] = Variable<int>(currentWeek);
    if (!nullToAbsent || repeats != null) {
      map['repeats'] = Variable<String>(repeats);
    }
    map['finished'] = Variable<bool>(finished);
    return map;
  }

  Plan5kStatesCompanion toCompanion(bool nullToAbsent) {
    return Plan5kStatesCompanion(
      id: Value(id),
      started: Value(started),
      startWeek: Value(startWeek),
      currentWeek: Value(currentWeek),
      repeats: repeats == null && nullToAbsent
          ? const Value.absent()
          : Value(repeats),
      finished: Value(finished),
    );
  }

  factory Plan5kStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan5kStateRow(
      id: serializer.fromJson<int>(json['id']),
      started: serializer.fromJson<bool>(json['started']),
      startWeek: serializer.fromJson<int>(json['startWeek']),
      currentWeek: serializer.fromJson<int>(json['currentWeek']),
      repeats: serializer.fromJson<String?>(json['repeats']),
      finished: serializer.fromJson<bool>(json['finished']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'started': serializer.toJson<bool>(started),
      'startWeek': serializer.toJson<int>(startWeek),
      'currentWeek': serializer.toJson<int>(currentWeek),
      'repeats': serializer.toJson<String?>(repeats),
      'finished': serializer.toJson<bool>(finished),
    };
  }

  Plan5kStateRow copyWith({
    int? id,
    bool? started,
    int? startWeek,
    int? currentWeek,
    Value<String?> repeats = const Value.absent(),
    bool? finished,
  }) => Plan5kStateRow(
    id: id ?? this.id,
    started: started ?? this.started,
    startWeek: startWeek ?? this.startWeek,
    currentWeek: currentWeek ?? this.currentWeek,
    repeats: repeats.present ? repeats.value : this.repeats,
    finished: finished ?? this.finished,
  );
  Plan5kStateRow copyWithCompanion(Plan5kStatesCompanion data) {
    return Plan5kStateRow(
      id: data.id.present ? data.id.value : this.id,
      started: data.started.present ? data.started.value : this.started,
      startWeek: data.startWeek.present ? data.startWeek.value : this.startWeek,
      currentWeek: data.currentWeek.present
          ? data.currentWeek.value
          : this.currentWeek,
      repeats: data.repeats.present ? data.repeats.value : this.repeats,
      finished: data.finished.present ? data.finished.value : this.finished,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan5kStateRow(')
          ..write('id: $id, ')
          ..write('started: $started, ')
          ..write('startWeek: $startWeek, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('repeats: $repeats, ')
          ..write('finished: $finished')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, started, startWeek, currentWeek, repeats, finished);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan5kStateRow &&
          other.id == this.id &&
          other.started == this.started &&
          other.startWeek == this.startWeek &&
          other.currentWeek == this.currentWeek &&
          other.repeats == this.repeats &&
          other.finished == this.finished);
}

class Plan5kStatesCompanion extends UpdateCompanion<Plan5kStateRow> {
  final Value<int> id;
  final Value<bool> started;
  final Value<int> startWeek;
  final Value<int> currentWeek;
  final Value<String?> repeats;
  final Value<bool> finished;
  const Plan5kStatesCompanion({
    this.id = const Value.absent(),
    this.started = const Value.absent(),
    this.startWeek = const Value.absent(),
    this.currentWeek = const Value.absent(),
    this.repeats = const Value.absent(),
    this.finished = const Value.absent(),
  });
  Plan5kStatesCompanion.insert({
    this.id = const Value.absent(),
    this.started = const Value.absent(),
    this.startWeek = const Value.absent(),
    this.currentWeek = const Value.absent(),
    this.repeats = const Value.absent(),
    this.finished = const Value.absent(),
  });
  static Insertable<Plan5kStateRow> custom({
    Expression<int>? id,
    Expression<bool>? started,
    Expression<int>? startWeek,
    Expression<int>? currentWeek,
    Expression<String>? repeats,
    Expression<bool>? finished,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (started != null) 'started': started,
      if (startWeek != null) 'start_week': startWeek,
      if (currentWeek != null) 'current_week': currentWeek,
      if (repeats != null) 'repeats': repeats,
      if (finished != null) 'finished': finished,
    });
  }

  Plan5kStatesCompanion copyWith({
    Value<int>? id,
    Value<bool>? started,
    Value<int>? startWeek,
    Value<int>? currentWeek,
    Value<String?>? repeats,
    Value<bool>? finished,
  }) {
    return Plan5kStatesCompanion(
      id: id ?? this.id,
      started: started ?? this.started,
      startWeek: startWeek ?? this.startWeek,
      currentWeek: currentWeek ?? this.currentWeek,
      repeats: repeats ?? this.repeats,
      finished: finished ?? this.finished,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (started.present) {
      map['started'] = Variable<bool>(started.value);
    }
    if (startWeek.present) {
      map['start_week'] = Variable<int>(startWeek.value);
    }
    if (currentWeek.present) {
      map['current_week'] = Variable<int>(currentWeek.value);
    }
    if (repeats.present) {
      map['repeats'] = Variable<String>(repeats.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('Plan5kStatesCompanion(')
          ..write('id: $id, ')
          ..write('started: $started, ')
          ..write('startWeek: $startWeek, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('repeats: $repeats, ')
          ..write('finished: $finished')
          ..write(')'))
        .toString();
  }
}

class $Plan5kSessionsTable extends Plan5kSessions
    with TableInfo<$Plan5kSessionsTable, Plan5kSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $Plan5kSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weekMeta = const VerificationMeta('week');
  @override
  late final GeneratedColumn<int> week = GeneratedColumn<int>(
    'week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
    'round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMsMeta = const VerificationMeta(
    'plannedMs',
  );
  @override
  late final GeneratedColumn<int> plannedMs = GeneratedColumn<int>(
    'planned_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movingMsMeta = const VerificationMeta(
    'movingMs',
  );
  @override
  late final GeneratedColumn<int> movingMs = GeneratedColumn<int>(
    'moving_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activityGuidMeta = const VerificationMeta(
    'activityGuid',
  );
  @override
  late final GeneratedColumn<String> activityGuid = GeneratedColumn<String>(
    'activity_guid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMsMeta = const VerificationMeta(
    'endedAtMs',
  );
  @override
  late final GeneratedColumn<int> endedAtMs = GeneratedColumn<int>(
    'ended_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    week,
    number,
    round,
    status,
    plannedMs,
    movingMs,
    activityGuid,
    startedAtMs,
    endedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan5k_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plan5kSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week')) {
      context.handle(
        _weekMeta,
        week.isAcceptableOrUnknown(data['week']!, _weekMeta),
      );
    } else if (isInserting) {
      context.missing(_weekMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
        _roundMeta,
        round.isAcceptableOrUnknown(data['round']!, _roundMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('planned_ms')) {
      context.handle(
        _plannedMsMeta,
        plannedMs.isAcceptableOrUnknown(data['planned_ms']!, _plannedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedMsMeta);
    }
    if (data.containsKey('moving_ms')) {
      context.handle(
        _movingMsMeta,
        movingMs.isAcceptableOrUnknown(data['moving_ms']!, _movingMsMeta),
      );
    }
    if (data.containsKey('activity_guid')) {
      context.handle(
        _activityGuidMeta,
        activityGuid.isAcceptableOrUnknown(
          data['activity_guid']!,
          _activityGuidMeta,
        ),
      );
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('ended_at_ms')) {
      context.handle(
        _endedAtMsMeta,
        endedAtMs.isAcceptableOrUnknown(data['ended_at_ms']!, _endedAtMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan5kSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan5kSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      week: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      round: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      plannedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_ms'],
      )!,
      movingMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_ms'],
      )!,
      activityGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_guid'],
      ),
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      endedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_ms'],
      ),
    );
  }

  @override
  $Plan5kSessionsTable createAlias(String alias) {
    return $Plan5kSessionsTable(attachedDatabase, alias);
  }
}

class Plan5kSessionRow extends DataClass
    implements Insertable<Plan5kSessionRow> {
  final int id;
  final int week;
  final int number;

  /// Rodada da semana (0 = primeira vez; sobe a cada repeticao).
  final int round;

  /// 'inProgress' | 'done' | 'partial' (SessionStatus).
  final String status;

  /// Tempo de plano necessario para a sessao contar como concluida (ate o
  /// desaquecimento; ver PlanSession.requiredMs).
  final int plannedMs;

  /// Tempo de plano andado (salvo durante a sessao e no fim).
  final int movingMs;
  final String? activityGuid;
  final int startedAtMs;
  final int? endedAtMs;
  const Plan5kSessionRow({
    required this.id,
    required this.week,
    required this.number,
    required this.round,
    required this.status,
    required this.plannedMs,
    required this.movingMs,
    this.activityGuid,
    required this.startedAtMs,
    this.endedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week'] = Variable<int>(week);
    map['number'] = Variable<int>(number);
    map['round'] = Variable<int>(round);
    map['status'] = Variable<String>(status);
    map['planned_ms'] = Variable<int>(plannedMs);
    map['moving_ms'] = Variable<int>(movingMs);
    if (!nullToAbsent || activityGuid != null) {
      map['activity_guid'] = Variable<String>(activityGuid);
    }
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || endedAtMs != null) {
      map['ended_at_ms'] = Variable<int>(endedAtMs);
    }
    return map;
  }

  Plan5kSessionsCompanion toCompanion(bool nullToAbsent) {
    return Plan5kSessionsCompanion(
      id: Value(id),
      week: Value(week),
      number: Value(number),
      round: Value(round),
      status: Value(status),
      plannedMs: Value(plannedMs),
      movingMs: Value(movingMs),
      activityGuid: activityGuid == null && nullToAbsent
          ? const Value.absent()
          : Value(activityGuid),
      startedAtMs: Value(startedAtMs),
      endedAtMs: endedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMs),
    );
  }

  factory Plan5kSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan5kSessionRow(
      id: serializer.fromJson<int>(json['id']),
      week: serializer.fromJson<int>(json['week']),
      number: serializer.fromJson<int>(json['number']),
      round: serializer.fromJson<int>(json['round']),
      status: serializer.fromJson<String>(json['status']),
      plannedMs: serializer.fromJson<int>(json['plannedMs']),
      movingMs: serializer.fromJson<int>(json['movingMs']),
      activityGuid: serializer.fromJson<String?>(json['activityGuid']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      endedAtMs: serializer.fromJson<int?>(json['endedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'week': serializer.toJson<int>(week),
      'number': serializer.toJson<int>(number),
      'round': serializer.toJson<int>(round),
      'status': serializer.toJson<String>(status),
      'plannedMs': serializer.toJson<int>(plannedMs),
      'movingMs': serializer.toJson<int>(movingMs),
      'activityGuid': serializer.toJson<String?>(activityGuid),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'endedAtMs': serializer.toJson<int?>(endedAtMs),
    };
  }

  Plan5kSessionRow copyWith({
    int? id,
    int? week,
    int? number,
    int? round,
    String? status,
    int? plannedMs,
    int? movingMs,
    Value<String?> activityGuid = const Value.absent(),
    int? startedAtMs,
    Value<int?> endedAtMs = const Value.absent(),
  }) => Plan5kSessionRow(
    id: id ?? this.id,
    week: week ?? this.week,
    number: number ?? this.number,
    round: round ?? this.round,
    status: status ?? this.status,
    plannedMs: plannedMs ?? this.plannedMs,
    movingMs: movingMs ?? this.movingMs,
    activityGuid: activityGuid.present ? activityGuid.value : this.activityGuid,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    endedAtMs: endedAtMs.present ? endedAtMs.value : this.endedAtMs,
  );
  Plan5kSessionRow copyWithCompanion(Plan5kSessionsCompanion data) {
    return Plan5kSessionRow(
      id: data.id.present ? data.id.value : this.id,
      week: data.week.present ? data.week.value : this.week,
      number: data.number.present ? data.number.value : this.number,
      round: data.round.present ? data.round.value : this.round,
      status: data.status.present ? data.status.value : this.status,
      plannedMs: data.plannedMs.present ? data.plannedMs.value : this.plannedMs,
      movingMs: data.movingMs.present ? data.movingMs.value : this.movingMs,
      activityGuid: data.activityGuid.present
          ? data.activityGuid.value
          : this.activityGuid,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      endedAtMs: data.endedAtMs.present ? data.endedAtMs.value : this.endedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan5kSessionRow(')
          ..write('id: $id, ')
          ..write('week: $week, ')
          ..write('number: $number, ')
          ..write('round: $round, ')
          ..write('status: $status, ')
          ..write('plannedMs: $plannedMs, ')
          ..write('movingMs: $movingMs, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    week,
    number,
    round,
    status,
    plannedMs,
    movingMs,
    activityGuid,
    startedAtMs,
    endedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan5kSessionRow &&
          other.id == this.id &&
          other.week == this.week &&
          other.number == this.number &&
          other.round == this.round &&
          other.status == this.status &&
          other.plannedMs == this.plannedMs &&
          other.movingMs == this.movingMs &&
          other.activityGuid == this.activityGuid &&
          other.startedAtMs == this.startedAtMs &&
          other.endedAtMs == this.endedAtMs);
}

class Plan5kSessionsCompanion extends UpdateCompanion<Plan5kSessionRow> {
  final Value<int> id;
  final Value<int> week;
  final Value<int> number;
  final Value<int> round;
  final Value<String> status;
  final Value<int> plannedMs;
  final Value<int> movingMs;
  final Value<String?> activityGuid;
  final Value<int> startedAtMs;
  final Value<int?> endedAtMs;
  const Plan5kSessionsCompanion({
    this.id = const Value.absent(),
    this.week = const Value.absent(),
    this.number = const Value.absent(),
    this.round = const Value.absent(),
    this.status = const Value.absent(),
    this.plannedMs = const Value.absent(),
    this.movingMs = const Value.absent(),
    this.activityGuid = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
  });
  Plan5kSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int week,
    required int number,
    this.round = const Value.absent(),
    required String status,
    required int plannedMs,
    this.movingMs = const Value.absent(),
    this.activityGuid = const Value.absent(),
    required int startedAtMs,
    this.endedAtMs = const Value.absent(),
  }) : week = Value(week),
       number = Value(number),
       status = Value(status),
       plannedMs = Value(plannedMs),
       startedAtMs = Value(startedAtMs);
  static Insertable<Plan5kSessionRow> custom({
    Expression<int>? id,
    Expression<int>? week,
    Expression<int>? number,
    Expression<int>? round,
    Expression<String>? status,
    Expression<int>? plannedMs,
    Expression<int>? movingMs,
    Expression<String>? activityGuid,
    Expression<int>? startedAtMs,
    Expression<int>? endedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (week != null) 'week': week,
      if (number != null) 'number': number,
      if (round != null) 'round': round,
      if (status != null) 'status': status,
      if (plannedMs != null) 'planned_ms': plannedMs,
      if (movingMs != null) 'moving_ms': movingMs,
      if (activityGuid != null) 'activity_guid': activityGuid,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (endedAtMs != null) 'ended_at_ms': endedAtMs,
    });
  }

  Plan5kSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? week,
    Value<int>? number,
    Value<int>? round,
    Value<String>? status,
    Value<int>? plannedMs,
    Value<int>? movingMs,
    Value<String?>? activityGuid,
    Value<int>? startedAtMs,
    Value<int?>? endedAtMs,
  }) {
    return Plan5kSessionsCompanion(
      id: id ?? this.id,
      week: week ?? this.week,
      number: number ?? this.number,
      round: round ?? this.round,
      status: status ?? this.status,
      plannedMs: plannedMs ?? this.plannedMs,
      movingMs: movingMs ?? this.movingMs,
      activityGuid: activityGuid ?? this.activityGuid,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (week.present) {
      map['week'] = Variable<int>(week.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (plannedMs.present) {
      map['planned_ms'] = Variable<int>(plannedMs.value);
    }
    if (movingMs.present) {
      map['moving_ms'] = Variable<int>(movingMs.value);
    }
    if (activityGuid.present) {
      map['activity_guid'] = Variable<String>(activityGuid.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (endedAtMs.present) {
      map['ended_at_ms'] = Variable<int>(endedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('Plan5kSessionsCompanion(')
          ..write('id: $id, ')
          ..write('week: $week, ')
          ..write('number: $number, ')
          ..write('round: $round, ')
          ..write('status: $status, ')
          ..write('plannedMs: $plannedMs, ')
          ..write('movingMs: $movingMs, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs')
          ..write(')'))
        .toString();
  }
}

class $SafetyLocalSessionsTable extends SafetyLocalSessions
    with TableInfo<$SafetyLocalSessionsTable, SafetyLocalSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SafetyLocalSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityGuidMeta = const VerificationMeta(
    'activityGuid',
  );
  @override
  late final GeneratedColumn<String> activityGuid = GeneratedColumn<String>(
    'activity_guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingArrivalMeta = const VerificationMeta(
    'pendingArrival',
  );
  @override
  late final GeneratedColumn<bool> pendingArrival = GeneratedColumn<bool>(
    'pending_arrival',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_arrival" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    activityGuid,
    ownerUserId,
    createdAtMs,
    pendingArrival,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'safety_local_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SafetyLocalSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('activity_guid')) {
      context.handle(
        _activityGuidMeta,
        activityGuid.isAcceptableOrUnknown(
          data['activity_guid']!,
          _activityGuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityGuidMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('pending_arrival')) {
      context.handle(
        _pendingArrivalMeta,
        pendingArrival.isAcceptableOrUnknown(
          data['pending_arrival']!,
          _pendingArrivalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  SafetyLocalSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SafetyLocalSessionRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      activityGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_guid'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      pendingArrival: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_arrival'],
      )!,
    );
  }

  @override
  $SafetyLocalSessionsTable createAlias(String alias) {
    return $SafetyLocalSessionsTable(attachedDatabase, alias);
  }
}

class SafetyLocalSessionRow extends DataClass
    implements Insertable<SafetyLocalSessionRow> {
  final String sessionId;
  final String activityGuid;
  final String? ownerUserId;
  final int createdAtMs;
  final bool pendingArrival;
  const SafetyLocalSessionRow({
    required this.sessionId,
    required this.activityGuid,
    this.ownerUserId,
    required this.createdAtMs,
    required this.pendingArrival,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['activity_guid'] = Variable<String>(activityGuid);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['pending_arrival'] = Variable<bool>(pendingArrival);
    return map;
  }

  SafetyLocalSessionsCompanion toCompanion(bool nullToAbsent) {
    return SafetyLocalSessionsCompanion(
      sessionId: Value(sessionId),
      activityGuid: Value(activityGuid),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      createdAtMs: Value(createdAtMs),
      pendingArrival: Value(pendingArrival),
    );
  }

  factory SafetyLocalSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SafetyLocalSessionRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      activityGuid: serializer.fromJson<String>(json['activityGuid']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      pendingArrival: serializer.fromJson<bool>(json['pendingArrival']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'activityGuid': serializer.toJson<String>(activityGuid),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'pendingArrival': serializer.toJson<bool>(pendingArrival),
    };
  }

  SafetyLocalSessionRow copyWith({
    String? sessionId,
    String? activityGuid,
    Value<String?> ownerUserId = const Value.absent(),
    int? createdAtMs,
    bool? pendingArrival,
  }) => SafetyLocalSessionRow(
    sessionId: sessionId ?? this.sessionId,
    activityGuid: activityGuid ?? this.activityGuid,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    pendingArrival: pendingArrival ?? this.pendingArrival,
  );
  SafetyLocalSessionRow copyWithCompanion(SafetyLocalSessionsCompanion data) {
    return SafetyLocalSessionRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      activityGuid: data.activityGuid.present
          ? data.activityGuid.value
          : this.activityGuid,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      pendingArrival: data.pendingArrival.present
          ? data.pendingArrival.value
          : this.pendingArrival,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SafetyLocalSessionRow(')
          ..write('sessionId: $sessionId, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('pendingArrival: $pendingArrival')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    activityGuid,
    ownerUserId,
    createdAtMs,
    pendingArrival,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SafetyLocalSessionRow &&
          other.sessionId == this.sessionId &&
          other.activityGuid == this.activityGuid &&
          other.ownerUserId == this.ownerUserId &&
          other.createdAtMs == this.createdAtMs &&
          other.pendingArrival == this.pendingArrival);
}

class SafetyLocalSessionsCompanion
    extends UpdateCompanion<SafetyLocalSessionRow> {
  final Value<String> sessionId;
  final Value<String> activityGuid;
  final Value<String?> ownerUserId;
  final Value<int> createdAtMs;
  final Value<bool> pendingArrival;
  final Value<int> rowid;
  const SafetyLocalSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.activityGuid = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.pendingArrival = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SafetyLocalSessionsCompanion.insert({
    required String sessionId,
    required String activityGuid,
    this.ownerUserId = const Value.absent(),
    required int createdAtMs,
    this.pendingArrival = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       activityGuid = Value(activityGuid),
       createdAtMs = Value(createdAtMs);
  static Insertable<SafetyLocalSessionRow> custom({
    Expression<String>? sessionId,
    Expression<String>? activityGuid,
    Expression<String>? ownerUserId,
    Expression<int>? createdAtMs,
    Expression<bool>? pendingArrival,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (activityGuid != null) 'activity_guid': activityGuid,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (pendingArrival != null) 'pending_arrival': pendingArrival,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SafetyLocalSessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? activityGuid,
    Value<String?>? ownerUserId,
    Value<int>? createdAtMs,
    Value<bool>? pendingArrival,
    Value<int>? rowid,
  }) {
    return SafetyLocalSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      activityGuid: activityGuid ?? this.activityGuid,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      pendingArrival: pendingArrival ?? this.pendingArrival,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (activityGuid.present) {
      map['activity_guid'] = Variable<String>(activityGuid.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (pendingArrival.present) {
      map['pending_arrival'] = Variable<bool>(pendingArrival.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SafetyLocalSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('activityGuid: $activityGuid, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('pendingArrival: $pendingArrival, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SafetyMetaTable extends SafetyMeta
    with TableInfo<$SafetyMetaTable, SafetyMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SafetyMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intValueMeta = const VerificationMeta(
    'intValue',
  );
  @override
  late final GeneratedColumn<int> intValue = GeneratedColumn<int>(
    'int_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, intValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'safety_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SafetyMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('int_value')) {
      context.handle(
        _intValueMeta,
        intValue.isAcceptableOrUnknown(data['int_value']!, _intValueMeta),
      );
    } else if (isInserting) {
      context.missing(_intValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SafetyMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SafetyMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      intValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}int_value'],
      )!,
    );
  }

  @override
  $SafetyMetaTable createAlias(String alias) {
    return $SafetyMetaTable(attachedDatabase, alias);
  }
}

class SafetyMetaRow extends DataClass implements Insertable<SafetyMetaRow> {
  /// Ex.: 'alerts_seen_ms' (ate onde os alertas viraram notificacao local).
  final String key;
  final int intValue;
  const SafetyMetaRow({required this.key, required this.intValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['int_value'] = Variable<int>(intValue);
    return map;
  }

  SafetyMetaCompanion toCompanion(bool nullToAbsent) {
    return SafetyMetaCompanion(key: Value(key), intValue: Value(intValue));
  }

  factory SafetyMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SafetyMetaRow(
      key: serializer.fromJson<String>(json['key']),
      intValue: serializer.fromJson<int>(json['intValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'intValue': serializer.toJson<int>(intValue),
    };
  }

  SafetyMetaRow copyWith({String? key, int? intValue}) =>
      SafetyMetaRow(key: key ?? this.key, intValue: intValue ?? this.intValue);
  SafetyMetaRow copyWithCompanion(SafetyMetaCompanion data) {
    return SafetyMetaRow(
      key: data.key.present ? data.key.value : this.key,
      intValue: data.intValue.present ? data.intValue.value : this.intValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SafetyMetaRow(')
          ..write('key: $key, ')
          ..write('intValue: $intValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, intValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SafetyMetaRow &&
          other.key == this.key &&
          other.intValue == this.intValue);
}

class SafetyMetaCompanion extends UpdateCompanion<SafetyMetaRow> {
  final Value<String> key;
  final Value<int> intValue;
  final Value<int> rowid;
  const SafetyMetaCompanion({
    this.key = const Value.absent(),
    this.intValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SafetyMetaCompanion.insert({
    required String key,
    required int intValue,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       intValue = Value(intValue);
  static Insertable<SafetyMetaRow> custom({
    Expression<String>? key,
    Expression<int>? intValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (intValue != null) 'int_value': intValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SafetyMetaCompanion copyWith({
    Value<String>? key,
    Value<int>? intValue,
    Value<int>? rowid,
  }) {
    return SafetyMetaCompanion(
      key: key ?? this.key,
      intValue: intValue ?? this.intValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (intValue.present) {
      map['int_value'] = Variable<int>(intValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SafetyMetaCompanion(')
          ..write('key: $key, ')
          ..write('intValue: $intValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RecordingDatabase extends GeneratedDatabase {
  _$RecordingDatabase(QueryExecutor e) : super(e);
  $RecordingDatabaseManager get managers => $RecordingDatabaseManager(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $WaypointsTable waypoints = $WaypointsTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  late final $RemoteDeletionsTable remoteDeletions = $RemoteDeletionsTable(
    this,
  );
  late final $LapsTable laps = $LapsTable(this);
  late final $RecordingGapsTable recordingGaps = $RecordingGapsTable(this);
  late final $PrivacyZonesTable privacyZones = $PrivacyZonesTable(this);
  late final $DismissedZoneSuggestionsTable dismissedZoneSuggestions =
      $DismissedZoneSuggestionsTable(this);
  late final $Plan5kStatesTable plan5kStates = $Plan5kStatesTable(this);
  late final $Plan5kSessionsTable plan5kSessions = $Plan5kSessionsTable(this);
  late final $SafetyLocalSessionsTable safetyLocalSessions =
      $SafetyLocalSessionsTable(this);
  late final $SafetyMetaTable safetyMeta = $SafetyMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    activities,
    waypoints,
    settingsRows,
    remoteDeletions,
    laps,
    recordingGaps,
    privacyZones,
    dismissedZoneSuggestions,
    plan5kStates,
    plan5kSessions,
    safetyLocalSessions,
    safetyMeta,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('waypoints', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('laps', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recording_gaps', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  required String guid,
  required ActivityType activityType,
  required int startTimestampMs,
  Value<int?> endTimestampMs,
  Value<int> timerTimeMs,
  Value<double> distanceMeters,
  Value<double?> calories,
  Value<bool> isIndoor,
  Value<bool> isFinished,
  required SyncState syncState,
  Value<int?> startBatteryLevel,
  Value<int?> endBatteryLevel,
  Value<bool> autoPauseEnabled,
  Value<String?> ownerUserId,
  Value<String?> remoteId,
  Value<String?> title,
  Value<String?> description,
  Value<String> visibility,
  Value<int> hideEdgesMeters,
  Value<int?> lastHeartbeatMs,
  Value<bool> heartbeatPaused,
  Value<int> discardedPointCount,
  Value<int?> rpe,
  Value<String?> mood,
  Value<String?> importSource,
  Value<int> rowid,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<String> guid,
  Value<ActivityType> activityType,
  Value<int> startTimestampMs,
  Value<int?> endTimestampMs,
  Value<int> timerTimeMs,
  Value<double> distanceMeters,
  Value<double?> calories,
  Value<bool> isIndoor,
  Value<bool> isFinished,
  Value<SyncState> syncState,
  Value<int?> startBatteryLevel,
  Value<int?> endBatteryLevel,
  Value<bool> autoPauseEnabled,
  Value<String?> ownerUserId,
  Value<String?> remoteId,
  Value<String?> title,
  Value<String?> description,
  Value<String> visibility,
  Value<int> hideEdgesMeters,
  Value<int?> lastHeartbeatMs,
  Value<bool> heartbeatPaused,
  Value<int> discardedPointCount,
  Value<int?> rpe,
  Value<String?> mood,
  Value<String?> importSource,
  Value<int> rowid,
});

final class $$ActivitiesTableReferences
    extends BaseReferences<_$RecordingDatabase, $ActivitiesTable, Activity> {
  $$ActivitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WaypointsTable, List<Waypoint>>
  _waypointsRefsTable(_$RecordingDatabase db) => MultiTypedResultKey.fromTable(
    db.waypoints,
    aliasName: 'activities__guid__waypoints__activity_guid',
  );

  $$WaypointsTableProcessedTableManager get waypointsRefs {
    final manager = $$WaypointsTableTableManager($_db, $_db.waypoints).filter(
      (f) => f.activityGuid.guid.sqlEquals($_itemColumn<String>('guid')!),
    );

    final cache = $_typedResult.readTableOrNull(_waypointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LapsTable, List<Lap>> _lapsRefsTable(
    _$RecordingDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.laps,
    aliasName: 'activities__guid__laps__activity_guid',
  );

  $$LapsTableProcessedTableManager get lapsRefs {
    final manager = $$LapsTableTableManager($_db, $_db.laps).filter(
      (f) => f.activityGuid.guid.sqlEquals($_itemColumn<String>('guid')!),
    );

    final cache = $_typedResult.readTableOrNull(_lapsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecordingGapsTable, List<RecordingGapRow>>
  _recordingGapsRefsTable(_$RecordingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recordingGaps,
        aliasName: 'activities__guid__recording_gaps__activity_guid',
      );

  $$RecordingGapsTableProcessedTableManager get recordingGapsRefs {
    final manager = $$RecordingGapsTableTableManager($_db, $_db.recordingGaps)
        .filter(
          (f) => f.activityGuid.guid.sqlEquals($_itemColumn<String>('guid')!),
        );

    final cache = $_typedResult.readTableOrNull(_recordingGapsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ActivitiesTableFilterComposer
    extends Composer<_$RecordingDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActivityType, ActivityType, int>
  get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get startTimestampMs => $composableBuilder(
    column: $table.startTimestampMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTimestampMs => $composableBuilder(
    column: $table.endTimestampMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timerTimeMs => $composableBuilder(
    column: $table.timerTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get startBatteryLevel => $composableBuilder(
    column: $table.startBatteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endBatteryLevel => $composableBuilder(
    column: $table.endBatteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPauseEnabled => $composableBuilder(
    column: $table.autoPauseEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hideEdgesMeters => $composableBuilder(
    column: $table.hideEdgesMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastHeartbeatMs => $composableBuilder(
    column: $table.lastHeartbeatMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get heartbeatPaused => $composableBuilder(
    column: $table.heartbeatPaused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discardedPointCount => $composableBuilder(
    column: $table.discardedPointCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importSource => $composableBuilder(
    column: $table.importSource,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> waypointsRefs(
    Expression<bool> Function($$WaypointsTableFilterComposer f) f,
  ) {
    final $$WaypointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guid,
      referencedTable: $db.waypoints,
      getReferencedColumn: (t) => t.activityGuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaypointsTableFilterComposer(
            $db: $db,
            $table: $db.waypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lapsRefs(
    Expression<bool> Function($$LapsTableFilterComposer f) f,
  ) {
    final $$LapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guid,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.activityGuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableFilterComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recordingGapsRefs(
    Expression<bool> Function($$RecordingGapsTableFilterComposer f) f,
  ) {
    final $$RecordingGapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guid,
      referencedTable: $db.recordingGaps,
      getReferencedColumn: (t) => t.activityGuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingGapsTableFilterComposer(
            $db: $db,
            $table: $db.recordingGaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$RecordingDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTimestampMs => $composableBuilder(
    column: $table.startTimestampMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTimestampMs => $composableBuilder(
    column: $table.endTimestampMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timerTimeMs => $composableBuilder(
    column: $table.timerTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startBatteryLevel => $composableBuilder(
    column: $table.startBatteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endBatteryLevel => $composableBuilder(
    column: $table.endBatteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPauseEnabled => $composableBuilder(
    column: $table.autoPauseEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hideEdgesMeters => $composableBuilder(
    column: $table.hideEdgesMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastHeartbeatMs => $composableBuilder(
    column: $table.lastHeartbeatMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get heartbeatPaused => $composableBuilder(
    column: $table.heartbeatPaused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discardedPointCount => $composableBuilder(
    column: $table.discardedPointCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importSource => $composableBuilder(
    column: $table.importSource,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityType, int> get activityType =>
      $composableBuilder(
        column: $table.activityType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get startTimestampMs => $composableBuilder(
    column: $table.startTimestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endTimestampMs => $composableBuilder(
    column: $table.endTimestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timerTimeMs => $composableBuilder(
    column: $table.timerTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<bool> get isIndoor =>
      $composableBuilder(column: $table.isIndoor, builder: (column) => column);

  GeneratedColumn<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<int> get startBatteryLevel => $composableBuilder(
    column: $table.startBatteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endBatteryLevel => $composableBuilder(
    column: $table.endBatteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPauseEnabled => $composableBuilder(
    column: $table.autoPauseEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hideEdgesMeters => $composableBuilder(
    column: $table.hideEdgesMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastHeartbeatMs => $composableBuilder(
    column: $table.lastHeartbeatMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get heartbeatPaused => $composableBuilder(
    column: $table.heartbeatPaused,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discardedPointCount => $composableBuilder(
    column: $table.discardedPointCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get importSource => $composableBuilder(
    column: $table.importSource,
    builder: (column) => column,
  );

  Expression<T> waypointsRefs<T extends Object>(
    Expression<T> Function($$WaypointsTableAnnotationComposer a) f,
  ) {
    final $$WaypointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guid,
      referencedTable: $db.waypoints,
      getReferencedColumn: (t) => t.activityGuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaypointsTableAnnotationComposer(
            $db: $db,
            $table: $db.waypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lapsRefs<T extends Object>(
    Expression<T> Function($$LapsTableAnnotationComposer a) f,
  ) {
    final $$LapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guid,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.activityGuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableAnnotationComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recordingGapsRefs<T extends Object>(
    Expression<T> Function($$RecordingGapsTableAnnotationComposer a) f,
  ) {
    final $$RecordingGapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guid,
      referencedTable: $db.recordingGaps,
      getReferencedColumn: (t) => t.activityGuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingGapsTableAnnotationComposer(
            $db: $db,
            $table: $db.recordingGaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $ActivitiesTable,
          Activity,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (Activity, $$ActivitiesTableReferences),
          Activity,
          PrefetchHooks Function({
            bool waypointsRefs,
            bool lapsRefs,
            bool recordingGapsRefs,
          })
        > {
  $$ActivitiesTableTableManager(_$RecordingDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> guid = const Value.absent(),
                Value<ActivityType> activityType = const Value.absent(),
                Value<int> startTimestampMs = const Value.absent(),
                Value<int?> endTimestampMs = const Value.absent(),
                Value<int> timerTimeMs = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double?> calories = const Value.absent(),
                Value<bool> isIndoor = const Value.absent(),
                Value<bool> isFinished = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int?> startBatteryLevel = const Value.absent(),
                Value<int?> endBatteryLevel = const Value.absent(),
                Value<bool> autoPauseEnabled = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<int> hideEdgesMeters = const Value.absent(),
                Value<int?> lastHeartbeatMs = const Value.absent(),
                Value<bool> heartbeatPaused = const Value.absent(),
                Value<int> discardedPointCount = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<String?> importSource = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion(
                guid: guid,
                activityType: activityType,
                startTimestampMs: startTimestampMs,
                endTimestampMs: endTimestampMs,
                timerTimeMs: timerTimeMs,
                distanceMeters: distanceMeters,
                calories: calories,
                isIndoor: isIndoor,
                isFinished: isFinished,
                syncState: syncState,
                startBatteryLevel: startBatteryLevel,
                endBatteryLevel: endBatteryLevel,
                autoPauseEnabled: autoPauseEnabled,
                ownerUserId: ownerUserId,
                remoteId: remoteId,
                title: title,
                description: description,
                visibility: visibility,
                hideEdgesMeters: hideEdgesMeters,
                lastHeartbeatMs: lastHeartbeatMs,
                heartbeatPaused: heartbeatPaused,
                discardedPointCount: discardedPointCount,
                rpe: rpe,
                mood: mood,
                importSource: importSource,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String guid,
                required ActivityType activityType,
                required int startTimestampMs,
                Value<int?> endTimestampMs = const Value.absent(),
                Value<int> timerTimeMs = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double?> calories = const Value.absent(),
                Value<bool> isIndoor = const Value.absent(),
                Value<bool> isFinished = const Value.absent(),
                required SyncState syncState,
                Value<int?> startBatteryLevel = const Value.absent(),
                Value<int?> endBatteryLevel = const Value.absent(),
                Value<bool> autoPauseEnabled = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<int> hideEdgesMeters = const Value.absent(),
                Value<int?> lastHeartbeatMs = const Value.absent(),
                Value<bool> heartbeatPaused = const Value.absent(),
                Value<int> discardedPointCount = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<String?> importSource = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                guid: guid,
                activityType: activityType,
                startTimestampMs: startTimestampMs,
                endTimestampMs: endTimestampMs,
                timerTimeMs: timerTimeMs,
                distanceMeters: distanceMeters,
                calories: calories,
                isIndoor: isIndoor,
                isFinished: isFinished,
                syncState: syncState,
                startBatteryLevel: startBatteryLevel,
                endBatteryLevel: endBatteryLevel,
                autoPauseEnabled: autoPauseEnabled,
                ownerUserId: ownerUserId,
                remoteId: remoteId,
                title: title,
                description: description,
                visibility: visibility,
                hideEdgesMeters: hideEdgesMeters,
                lastHeartbeatMs: lastHeartbeatMs,
                heartbeatPaused: heartbeatPaused,
                discardedPointCount: discardedPointCount,
                rpe: rpe,
                mood: mood,
                importSource: importSource,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTable, Activity>(table),
                  $$ActivitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                waypointsRefs = false,
                lapsRefs = false,
                recordingGapsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (waypointsRefs) db.waypoints,
                    if (lapsRefs) db.laps,
                    if (recordingGapsRefs) db.recordingGaps,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (waypointsRefs)
                        await $_getPrefetchedDataByColumns<
                          Activity,
                          $ActivitiesTable,
                          Waypoint,
                          $WaypointsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ActivitiesTableReferences
                              ._waypointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).waypointsRefs,
                          currentColumn: 'guid',
                          referencedColumn: 'activity_guid',
                          typedResults: items,
                        ),
                      if (lapsRefs)
                        await $_getPrefetchedDataByColumns<
                          Activity,
                          $ActivitiesTable,
                          Lap,
                          $LapsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ActivitiesTableReferences
                              ._lapsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).lapsRefs,
                          currentColumn: 'guid',
                          referencedColumn: 'activity_guid',
                          typedResults: items,
                        ),
                      if (recordingGapsRefs)
                        await $_getPrefetchedDataByColumns<
                          Activity,
                          $ActivitiesTable,
                          RecordingGapRow,
                          $RecordingGapsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ActivitiesTableReferences
                              ._recordingGapsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).recordingGapsRefs,
                          currentColumn: 'guid',
                          referencedColumn: 'activity_guid',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $ActivitiesTable,
      Activity,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (Activity, $$ActivitiesTableReferences),
      Activity,
      PrefetchHooks Function({
        bool waypointsRefs,
        bool lapsRefs,
        bool recordingGapsRefs,
      })
    >;
typedef $$WaypointsTableCreateCompanionBuilder = WaypointsCompanion Function({
  Value<int> id,
  required String activityGuid,
  required int seq,
  required double latitude,
  required double longitude,
  Value<double?> altitudeMeters,
  Value<double?> horizontalAccuracyMeters,
  Value<double?> verticalAccuracyMeters,
  Value<double?> speedMetersPerSecond,
  required int elapsedTimeMs,
  required int timerTimeMs,
  required double cumulativeDistanceMeters,
  required int classification,
});
typedef $$WaypointsTableUpdateCompanionBuilder = WaypointsCompanion Function({
  Value<int> id,
  Value<String> activityGuid,
  Value<int> seq,
  Value<double> latitude,
  Value<double> longitude,
  Value<double?> altitudeMeters,
  Value<double?> horizontalAccuracyMeters,
  Value<double?> verticalAccuracyMeters,
  Value<double?> speedMetersPerSecond,
  Value<int> elapsedTimeMs,
  Value<int> timerTimeMs,
  Value<double> cumulativeDistanceMeters,
  Value<int> classification,
});

final class $$WaypointsTableReferences
    extends BaseReferences<_$RecordingDatabase, $WaypointsTable, Waypoint> {
  $$WaypointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActivitiesTable _activityGuidTable(_$RecordingDatabase db) =>
      db.activities.createAlias('waypoints__activity_guid__activities__guid');

  $$ActivitiesTableProcessedTableManager get activityGuid {
    final $_column = $_itemColumn<String>('activity_guid')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.guid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityGuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WaypointsTableFilterComposer
    extends Composer<_$RecordingDatabase, $WaypointsTable> {
  $$WaypointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeMeters => $composableBuilder(
    column: $table.altitudeMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get horizontalAccuracyMeters => $composableBuilder(
    column: $table.horizontalAccuracyMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get verticalAccuracyMeters => $composableBuilder(
    column: $table.verticalAccuracyMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMetersPerSecond => $composableBuilder(
    column: $table.speedMetersPerSecond,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedTimeMs => $composableBuilder(
    column: $table.elapsedTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timerTimeMs => $composableBuilder(
    column: $table.timerTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cumulativeDistanceMeters => $composableBuilder(
    column: $table.cumulativeDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityGuid {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaypointsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $WaypointsTable> {
  $$WaypointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeMeters => $composableBuilder(
    column: $table.altitudeMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get horizontalAccuracyMeters => $composableBuilder(
    column: $table.horizontalAccuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get verticalAccuracyMeters => $composableBuilder(
    column: $table.verticalAccuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMetersPerSecond => $composableBuilder(
    column: $table.speedMetersPerSecond,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedTimeMs => $composableBuilder(
    column: $table.elapsedTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timerTimeMs => $composableBuilder(
    column: $table.timerTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cumulativeDistanceMeters => $composableBuilder(
    column: $table.cumulativeDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityGuid {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaypointsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $WaypointsTable> {
  $$WaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitudeMeters => $composableBuilder(
    column: $table.altitudeMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get horizontalAccuracyMeters => $composableBuilder(
    column: $table.horizontalAccuracyMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get verticalAccuracyMeters => $composableBuilder(
    column: $table.verticalAccuracyMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speedMetersPerSecond => $composableBuilder(
    column: $table.speedMetersPerSecond,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedTimeMs => $composableBuilder(
    column: $table.elapsedTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timerTimeMs => $composableBuilder(
    column: $table.timerTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cumulativeDistanceMeters => $composableBuilder(
    column: $table.cumulativeDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => column,
  );

  $$ActivitiesTableAnnotationComposer get activityGuid {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaypointsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $WaypointsTable,
          Waypoint,
          $$WaypointsTableFilterComposer,
          $$WaypointsTableOrderingComposer,
          $$WaypointsTableAnnotationComposer,
          $$WaypointsTableCreateCompanionBuilder,
          $$WaypointsTableUpdateCompanionBuilder,
          (Waypoint, $$WaypointsTableReferences),
          Waypoint,
          PrefetchHooks Function({bool activityGuid})
        > {
  $$WaypointsTableTableManager(_$RecordingDatabase db, $WaypointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activityGuid = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> altitudeMeters = const Value.absent(),
                Value<double?> horizontalAccuracyMeters = const Value.absent(),
                Value<double?> verticalAccuracyMeters = const Value.absent(),
                Value<double?> speedMetersPerSecond = const Value.absent(),
                Value<int> elapsedTimeMs = const Value.absent(),
                Value<int> timerTimeMs = const Value.absent(),
                Value<double> cumulativeDistanceMeters = const Value.absent(),
                Value<int> classification = const Value.absent(),
              }) => WaypointsCompanion(
                id: id,
                activityGuid: activityGuid,
                seq: seq,
                latitude: latitude,
                longitude: longitude,
                altitudeMeters: altitudeMeters,
                horizontalAccuracyMeters: horizontalAccuracyMeters,
                verticalAccuracyMeters: verticalAccuracyMeters,
                speedMetersPerSecond: speedMetersPerSecond,
                elapsedTimeMs: elapsedTimeMs,
                timerTimeMs: timerTimeMs,
                cumulativeDistanceMeters: cumulativeDistanceMeters,
                classification: classification,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String activityGuid,
                required int seq,
                required double latitude,
                required double longitude,
                Value<double?> altitudeMeters = const Value.absent(),
                Value<double?> horizontalAccuracyMeters = const Value.absent(),
                Value<double?> verticalAccuracyMeters = const Value.absent(),
                Value<double?> speedMetersPerSecond = const Value.absent(),
                required int elapsedTimeMs,
                required int timerTimeMs,
                required double cumulativeDistanceMeters,
                required int classification,
              }) => WaypointsCompanion.insert(
                id: id,
                activityGuid: activityGuid,
                seq: seq,
                latitude: latitude,
                longitude: longitude,
                altitudeMeters: altitudeMeters,
                horizontalAccuracyMeters: horizontalAccuracyMeters,
                verticalAccuracyMeters: verticalAccuracyMeters,
                speedMetersPerSecond: speedMetersPerSecond,
                elapsedTimeMs: elapsedTimeMs,
                timerTimeMs: timerTimeMs,
                cumulativeDistanceMeters: cumulativeDistanceMeters,
                classification: classification,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WaypointsTable, Waypoint>(table),
                  $$WaypointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityGuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityGuid) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityGuid,
                        referencedTable: $$WaypointsTableReferences
                            ._activityGuidTable(db),
                        referencedColumn: $$WaypointsTableReferences
                            ._activityGuidTable(db)
                            .guid,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WaypointsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $WaypointsTable,
      Waypoint,
      $$WaypointsTableFilterComposer,
      $$WaypointsTableOrderingComposer,
      $$WaypointsTableAnnotationComposer,
      $$WaypointsTableCreateCompanionBuilder,
      $$WaypointsTableUpdateCompanionBuilder,
      (Waypoint, $$WaypointsTableReferences),
      Waypoint,
      PrefetchHooks Function({bool activityGuid})
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<bool> useMetric,
      Value<bool> autoPauseEnabled,
      Value<double?> weightKg,
      Value<bool> reliabilityChecklistSeen,
      Value<bool> hideOnServer,
      Value<String?> narratorPrefs,
      Value<bool> gentleMode,
      Value<int?> chapterMonthSeen,
      Value<bool> plan5kVoice,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<bool> useMetric,
      Value<bool> autoPauseEnabled,
      Value<double?> weightKg,
      Value<bool> reliabilityChecklistSeen,
      Value<bool> hideOnServer,
      Value<String?> narratorPrefs,
      Value<bool> gentleMode,
      Value<int?> chapterMonthSeen,
      Value<bool> plan5kVoice,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$RecordingDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useMetric => $composableBuilder(
    column: $table.useMetric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPauseEnabled => $composableBuilder(
    column: $table.autoPauseEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reliabilityChecklistSeen => $composableBuilder(
    column: $table.reliabilityChecklistSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hideOnServer => $composableBuilder(
    column: $table.hideOnServer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narratorPrefs => $composableBuilder(
    column: $table.narratorPrefs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gentleMode => $composableBuilder(
    column: $table.gentleMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterMonthSeen => $composableBuilder(
    column: $table.chapterMonthSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get plan5kVoice => $composableBuilder(
    column: $table.plan5kVoice,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useMetric => $composableBuilder(
    column: $table.useMetric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPauseEnabled => $composableBuilder(
    column: $table.autoPauseEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reliabilityChecklistSeen => $composableBuilder(
    column: $table.reliabilityChecklistSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hideOnServer => $composableBuilder(
    column: $table.hideOnServer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narratorPrefs => $composableBuilder(
    column: $table.narratorPrefs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gentleMode => $composableBuilder(
    column: $table.gentleMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterMonthSeen => $composableBuilder(
    column: $table.chapterMonthSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get plan5kVoice => $composableBuilder(
    column: $table.plan5kVoice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get useMetric =>
      $composableBuilder(column: $table.useMetric, builder: (column) => column);

  GeneratedColumn<bool> get autoPauseEnabled => $composableBuilder(
    column: $table.autoPauseEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<bool> get reliabilityChecklistSeen => $composableBuilder(
    column: $table.reliabilityChecklistSeen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hideOnServer => $composableBuilder(
    column: $table.hideOnServer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get narratorPrefs => $composableBuilder(
    column: $table.narratorPrefs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get gentleMode => $composableBuilder(
    column: $table.gentleMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chapterMonthSeen => $composableBuilder(
    column: $table.chapterMonthSeen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get plan5kVoice => $composableBuilder(
    column: $table.plan5kVoice,
    builder: (column) => column,
  );
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<
              _$RecordingDatabase,
              $SettingsRowsTable,
              SettingsRow
            >,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(
    _$RecordingDatabase db,
    $SettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> useMetric = const Value.absent(),
                Value<bool> autoPauseEnabled = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<bool> reliabilityChecklistSeen = const Value.absent(),
                Value<bool> hideOnServer = const Value.absent(),
                Value<String?> narratorPrefs = const Value.absent(),
                Value<bool> gentleMode = const Value.absent(),
                Value<int?> chapterMonthSeen = const Value.absent(),
                Value<bool> plan5kVoice = const Value.absent(),
              }) => SettingsRowsCompanion(
                id: id,
                useMetric: useMetric,
                autoPauseEnabled: autoPauseEnabled,
                weightKg: weightKg,
                reliabilityChecklistSeen: reliabilityChecklistSeen,
                hideOnServer: hideOnServer,
                narratorPrefs: narratorPrefs,
                gentleMode: gentleMode,
                chapterMonthSeen: chapterMonthSeen,
                plan5kVoice: plan5kVoice,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> useMetric = const Value.absent(),
                Value<bool> autoPauseEnabled = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<bool> reliabilityChecklistSeen = const Value.absent(),
                Value<bool> hideOnServer = const Value.absent(),
                Value<String?> narratorPrefs = const Value.absent(),
                Value<bool> gentleMode = const Value.absent(),
                Value<int?> chapterMonthSeen = const Value.absent(),
                Value<bool> plan5kVoice = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                useMetric: useMetric,
                autoPauseEnabled: autoPauseEnabled,
                weightKg: weightKg,
                reliabilityChecklistSeen: reliabilityChecklistSeen,
                hideOnServer: hideOnServer,
                narratorPrefs: narratorPrefs,
                gentleMode: gentleMode,
                chapterMonthSeen: chapterMonthSeen,
                plan5kVoice: plan5kVoice,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsRowsTable, SettingsRow>(table),
                  BaseReferences<
                    _$RecordingDatabase,
                    $SettingsRowsTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$RecordingDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$RemoteDeletionsTableCreateCompanionBuilder =
    RemoteDeletionsCompanion Function({
      required String remoteId,
      Value<String?> ownerUserId,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$RemoteDeletionsTableUpdateCompanionBuilder =
    RemoteDeletionsCompanion Function({
      Value<String> remoteId,
      Value<String?> ownerUserId,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

class $$RemoteDeletionsTableFilterComposer
    extends Composer<_$RecordingDatabase, $RemoteDeletionsTable> {
  $$RemoteDeletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteDeletionsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $RemoteDeletionsTable> {
  $$RemoteDeletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteDeletionsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $RemoteDeletionsTable> {
  $$RemoteDeletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$RemoteDeletionsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $RemoteDeletionsTable,
          RemoteDeletion,
          $$RemoteDeletionsTableFilterComposer,
          $$RemoteDeletionsTableOrderingComposer,
          $$RemoteDeletionsTableAnnotationComposer,
          $$RemoteDeletionsTableCreateCompanionBuilder,
          $$RemoteDeletionsTableUpdateCompanionBuilder,
          (
            RemoteDeletion,
            BaseReferences<
              _$RecordingDatabase,
              $RemoteDeletionsTable,
              RemoteDeletion
            >,
          ),
          RemoteDeletion,
          PrefetchHooks Function()
        > {
  $$RemoteDeletionsTableTableManager(
    _$RecordingDatabase db,
    $RemoteDeletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteDeletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteDeletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteDeletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> remoteId = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteDeletionsCompanion(
                remoteId: remoteId,
                ownerUserId: ownerUserId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remoteId,
                Value<String?> ownerUserId = const Value.absent(),
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => RemoteDeletionsCompanion.insert(
                remoteId: remoteId,
                ownerUserId: ownerUserId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemoteDeletionsTable, RemoteDeletion>(table),
                  BaseReferences<
                    _$RecordingDatabase,
                    $RemoteDeletionsTable,
                    RemoteDeletion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteDeletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $RemoteDeletionsTable,
      RemoteDeletion,
      $$RemoteDeletionsTableFilterComposer,
      $$RemoteDeletionsTableOrderingComposer,
      $$RemoteDeletionsTableAnnotationComposer,
      $$RemoteDeletionsTableCreateCompanionBuilder,
      $$RemoteDeletionsTableUpdateCompanionBuilder,
      (
        RemoteDeletion,
        BaseReferences<
          _$RecordingDatabase,
          $RemoteDeletionsTable,
          RemoteDeletion
        >,
      ),
      RemoteDeletion,
      PrefetchHooks Function()
    >;
typedef $$LapsTableCreateCompanionBuilder = LapsCompanion Function({
  required String activityGuid,
  required int number,
  required int startTimerMs,
  required int endTimerMs,
  required int endElapsedMs,
  required double startDistanceMeters,
  required double endDistanceMeters,
  Value<int> rowid,
});
typedef $$LapsTableUpdateCompanionBuilder = LapsCompanion Function({
  Value<String> activityGuid,
  Value<int> number,
  Value<int> startTimerMs,
  Value<int> endTimerMs,
  Value<int> endElapsedMs,
  Value<double> startDistanceMeters,
  Value<double> endDistanceMeters,
  Value<int> rowid,
});

final class $$LapsTableReferences
    extends BaseReferences<_$RecordingDatabase, $LapsTable, Lap> {
  $$LapsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActivitiesTable _activityGuidTable(_$RecordingDatabase db) =>
      db.activities.createAlias('laps__activity_guid__activities__guid');

  $$ActivitiesTableProcessedTableManager get activityGuid {
    final $_column = $_itemColumn<String>('activity_guid')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.guid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityGuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LapsTableFilterComposer
    extends Composer<_$RecordingDatabase, $LapsTable> {
  $$LapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTimerMs => $composableBuilder(
    column: $table.startTimerMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTimerMs => $composableBuilder(
    column: $table.endTimerMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endElapsedMs => $composableBuilder(
    column: $table.endElapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startDistanceMeters => $composableBuilder(
    column: $table.startDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endDistanceMeters => $composableBuilder(
    column: $table.endDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityGuid {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $LapsTable> {
  $$LapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTimerMs => $composableBuilder(
    column: $table.startTimerMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTimerMs => $composableBuilder(
    column: $table.endTimerMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endElapsedMs => $composableBuilder(
    column: $table.endElapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startDistanceMeters => $composableBuilder(
    column: $table.startDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endDistanceMeters => $composableBuilder(
    column: $table.endDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityGuid {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $LapsTable> {
  $$LapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get startTimerMs => $composableBuilder(
    column: $table.startTimerMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endTimerMs => $composableBuilder(
    column: $table.endTimerMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endElapsedMs => $composableBuilder(
    column: $table.endElapsedMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get startDistanceMeters => $composableBuilder(
    column: $table.startDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endDistanceMeters => $composableBuilder(
    column: $table.endDistanceMeters,
    builder: (column) => column,
  );

  $$ActivitiesTableAnnotationComposer get activityGuid {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $LapsTable,
          Lap,
          $$LapsTableFilterComposer,
          $$LapsTableOrderingComposer,
          $$LapsTableAnnotationComposer,
          $$LapsTableCreateCompanionBuilder,
          $$LapsTableUpdateCompanionBuilder,
          (Lap, $$LapsTableReferences),
          Lap,
          PrefetchHooks Function({bool activityGuid})
        > {
  $$LapsTableTableManager(_$RecordingDatabase db, $LapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> activityGuid = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<int> startTimerMs = const Value.absent(),
                Value<int> endTimerMs = const Value.absent(),
                Value<int> endElapsedMs = const Value.absent(),
                Value<double> startDistanceMeters = const Value.absent(),
                Value<double> endDistanceMeters = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LapsCompanion(
                activityGuid: activityGuid,
                number: number,
                startTimerMs: startTimerMs,
                endTimerMs: endTimerMs,
                endElapsedMs: endElapsedMs,
                startDistanceMeters: startDistanceMeters,
                endDistanceMeters: endDistanceMeters,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String activityGuid,
                required int number,
                required int startTimerMs,
                required int endTimerMs,
                required int endElapsedMs,
                required double startDistanceMeters,
                required double endDistanceMeters,
                Value<int> rowid = const Value.absent(),
              }) => LapsCompanion.insert(
                activityGuid: activityGuid,
                number: number,
                startTimerMs: startTimerMs,
                endTimerMs: endTimerMs,
                endElapsedMs: endElapsedMs,
                startDistanceMeters: startDistanceMeters,
                endDistanceMeters: endDistanceMeters,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LapsTable, Lap>(table),
                  $$LapsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityGuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityGuid) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityGuid,
                        referencedTable: $$LapsTableReferences
                            ._activityGuidTable(db),
                        referencedColumn: $$LapsTableReferences
                            ._activityGuidTable(db)
                            .guid,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LapsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $LapsTable,
      Lap,
      $$LapsTableFilterComposer,
      $$LapsTableOrderingComposer,
      $$LapsTableAnnotationComposer,
      $$LapsTableCreateCompanionBuilder,
      $$LapsTableUpdateCompanionBuilder,
      (Lap, $$LapsTableReferences),
      Lap,
      PrefetchHooks Function({bool activityGuid})
    >;
typedef $$RecordingGapsTableCreateCompanionBuilder =
    RecordingGapsCompanion Function({
      Value<int> id,
      required String activityGuid,
      required int startMs,
      required int endMs,
      required int reason,
    });
typedef $$RecordingGapsTableUpdateCompanionBuilder =
    RecordingGapsCompanion Function({
      Value<int> id,
      Value<String> activityGuid,
      Value<int> startMs,
      Value<int> endMs,
      Value<int> reason,
    });

final class $$RecordingGapsTableReferences
    extends
        BaseReferences<
          _$RecordingDatabase,
          $RecordingGapsTable,
          RecordingGapRow
        > {
  $$RecordingGapsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ActivitiesTable _activityGuidTable(_$RecordingDatabase db) => db
      .activities
      .createAlias('recording_gaps__activity_guid__activities__guid');

  $$ActivitiesTableProcessedTableManager get activityGuid {
    final $_column = $_itemColumn<String>('activity_guid')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.guid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityGuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecordingGapsTableFilterComposer
    extends Composer<_$RecordingDatabase, $RecordingGapsTable> {
  $$RecordingGapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityGuid {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordingGapsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $RecordingGapsTable> {
  $$RecordingGapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityGuid {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordingGapsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $RecordingGapsTable> {
  $$RecordingGapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<int> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  $$ActivitiesTableAnnotationComposer get activityGuid {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityGuid,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.guid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordingGapsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $RecordingGapsTable,
          RecordingGapRow,
          $$RecordingGapsTableFilterComposer,
          $$RecordingGapsTableOrderingComposer,
          $$RecordingGapsTableAnnotationComposer,
          $$RecordingGapsTableCreateCompanionBuilder,
          $$RecordingGapsTableUpdateCompanionBuilder,
          (RecordingGapRow, $$RecordingGapsTableReferences),
          RecordingGapRow,
          PrefetchHooks Function({bool activityGuid})
        > {
  $$RecordingGapsTableTableManager(
    _$RecordingDatabase db,
    $RecordingGapsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingGapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingGapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingGapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activityGuid = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
                Value<int> reason = const Value.absent(),
              }) => RecordingGapsCompanion(
                id: id,
                activityGuid: activityGuid,
                startMs: startMs,
                endMs: endMs,
                reason: reason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String activityGuid,
                required int startMs,
                required int endMs,
                required int reason,
              }) => RecordingGapsCompanion.insert(
                id: id,
                activityGuid: activityGuid,
                startMs: startMs,
                endMs: endMs,
                reason: reason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecordingGapsTable, RecordingGapRow>(table),
                  $$RecordingGapsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityGuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityGuid) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityGuid,
                        referencedTable: $$RecordingGapsTableReferences
                            ._activityGuidTable(db),
                        referencedColumn: $$RecordingGapsTableReferences
                            ._activityGuidTable(db)
                            .guid,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecordingGapsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $RecordingGapsTable,
      RecordingGapRow,
      $$RecordingGapsTableFilterComposer,
      $$RecordingGapsTableOrderingComposer,
      $$RecordingGapsTableAnnotationComposer,
      $$RecordingGapsTableCreateCompanionBuilder,
      $$RecordingGapsTableUpdateCompanionBuilder,
      (RecordingGapRow, $$RecordingGapsTableReferences),
      RecordingGapRow,
      PrefetchHooks Function({bool activityGuid})
    >;
typedef $$PrivacyZonesTableCreateCompanionBuilder =
    PrivacyZonesCompanion Function({
      Value<int> id,
      required double latitude,
      required double longitude,
      required double radiusMeters,
      required String label,
      required int createdAtMs,
    });
typedef $$PrivacyZonesTableUpdateCompanionBuilder =
    PrivacyZonesCompanion Function({
      Value<int> id,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> radiusMeters,
      Value<String> label,
      Value<int> createdAtMs,
    });

class $$PrivacyZonesTableFilterComposer
    extends Composer<_$RecordingDatabase, $PrivacyZonesTable> {
  $$PrivacyZonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrivacyZonesTableOrderingComposer
    extends Composer<_$RecordingDatabase, $PrivacyZonesTable> {
  $$PrivacyZonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrivacyZonesTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $PrivacyZonesTable> {
  $$PrivacyZonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$PrivacyZonesTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $PrivacyZonesTable,
          PrivacyZoneRow,
          $$PrivacyZonesTableFilterComposer,
          $$PrivacyZonesTableOrderingComposer,
          $$PrivacyZonesTableAnnotationComposer,
          $$PrivacyZonesTableCreateCompanionBuilder,
          $$PrivacyZonesTableUpdateCompanionBuilder,
          (
            PrivacyZoneRow,
            BaseReferences<
              _$RecordingDatabase,
              $PrivacyZonesTable,
              PrivacyZoneRow
            >,
          ),
          PrivacyZoneRow,
          PrefetchHooks Function()
        > {
  $$PrivacyZonesTableTableManager(
    _$RecordingDatabase db,
    $PrivacyZonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrivacyZonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrivacyZonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrivacyZonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> radiusMeters = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
              }) => PrivacyZonesCompanion(
                id: id,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                label: label,
                createdAtMs: createdAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double latitude,
                required double longitude,
                required double radiusMeters,
                required String label,
                required int createdAtMs,
              }) => PrivacyZonesCompanion.insert(
                id: id,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                label: label,
                createdAtMs: createdAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrivacyZonesTable, PrivacyZoneRow>(table),
                  BaseReferences<
                    _$RecordingDatabase,
                    $PrivacyZonesTable,
                    PrivacyZoneRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrivacyZonesTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $PrivacyZonesTable,
      PrivacyZoneRow,
      $$PrivacyZonesTableFilterComposer,
      $$PrivacyZonesTableOrderingComposer,
      $$PrivacyZonesTableAnnotationComposer,
      $$PrivacyZonesTableCreateCompanionBuilder,
      $$PrivacyZonesTableUpdateCompanionBuilder,
      (
        PrivacyZoneRow,
        BaseReferences<_$RecordingDatabase, $PrivacyZonesTable, PrivacyZoneRow>,
      ),
      PrivacyZoneRow,
      PrefetchHooks Function()
    >;
typedef $$DismissedZoneSuggestionsTableCreateCompanionBuilder =
    DismissedZoneSuggestionsCompanion Function({
      Value<int> id,
      required double latitude,
      required double longitude,
      required int createdAtMs,
    });
typedef $$DismissedZoneSuggestionsTableUpdateCompanionBuilder =
    DismissedZoneSuggestionsCompanion Function({
      Value<int> id,
      Value<double> latitude,
      Value<double> longitude,
      Value<int> createdAtMs,
    });

class $$DismissedZoneSuggestionsTableFilterComposer
    extends Composer<_$RecordingDatabase, $DismissedZoneSuggestionsTable> {
  $$DismissedZoneSuggestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DismissedZoneSuggestionsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $DismissedZoneSuggestionsTable> {
  $$DismissedZoneSuggestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DismissedZoneSuggestionsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $DismissedZoneSuggestionsTable> {
  $$DismissedZoneSuggestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$DismissedZoneSuggestionsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $DismissedZoneSuggestionsTable,
          DismissedZoneSuggestionRow,
          $$DismissedZoneSuggestionsTableFilterComposer,
          $$DismissedZoneSuggestionsTableOrderingComposer,
          $$DismissedZoneSuggestionsTableAnnotationComposer,
          $$DismissedZoneSuggestionsTableCreateCompanionBuilder,
          $$DismissedZoneSuggestionsTableUpdateCompanionBuilder,
          (
            DismissedZoneSuggestionRow,
            BaseReferences<
              _$RecordingDatabase,
              $DismissedZoneSuggestionsTable,
              DismissedZoneSuggestionRow
            >,
          ),
          DismissedZoneSuggestionRow,
          PrefetchHooks Function()
        > {
  $$DismissedZoneSuggestionsTableTableManager(
    _$RecordingDatabase db,
    $DismissedZoneSuggestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DismissedZoneSuggestionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DismissedZoneSuggestionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DismissedZoneSuggestionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
              }) => DismissedZoneSuggestionsCompanion(
                id: id,
                latitude: latitude,
                longitude: longitude,
                createdAtMs: createdAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double latitude,
                required double longitude,
                required int createdAtMs,
              }) => DismissedZoneSuggestionsCompanion.insert(
                id: id,
                latitude: latitude,
                longitude: longitude,
                createdAtMs: createdAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $DismissedZoneSuggestionsTable,
                    DismissedZoneSuggestionRow
                  >(table),
                  BaseReferences<
                    _$RecordingDatabase,
                    $DismissedZoneSuggestionsTable,
                    DismissedZoneSuggestionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DismissedZoneSuggestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $DismissedZoneSuggestionsTable,
      DismissedZoneSuggestionRow,
      $$DismissedZoneSuggestionsTableFilterComposer,
      $$DismissedZoneSuggestionsTableOrderingComposer,
      $$DismissedZoneSuggestionsTableAnnotationComposer,
      $$DismissedZoneSuggestionsTableCreateCompanionBuilder,
      $$DismissedZoneSuggestionsTableUpdateCompanionBuilder,
      (
        DismissedZoneSuggestionRow,
        BaseReferences<
          _$RecordingDatabase,
          $DismissedZoneSuggestionsTable,
          DismissedZoneSuggestionRow
        >,
      ),
      DismissedZoneSuggestionRow,
      PrefetchHooks Function()
    >;
typedef $$Plan5kStatesTableCreateCompanionBuilder =
    Plan5kStatesCompanion Function({
      Value<int> id,
      Value<bool> started,
      Value<int> startWeek,
      Value<int> currentWeek,
      Value<String?> repeats,
      Value<bool> finished,
    });
typedef $$Plan5kStatesTableUpdateCompanionBuilder =
    Plan5kStatesCompanion Function({
      Value<int> id,
      Value<bool> started,
      Value<int> startWeek,
      Value<int> currentWeek,
      Value<String?> repeats,
      Value<bool> finished,
    });

class $$Plan5kStatesTableFilterComposer
    extends Composer<_$RecordingDatabase, $Plan5kStatesTable> {
  $$Plan5kStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startWeek => $composableBuilder(
    column: $table.startWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentWeek => $composableBuilder(
    column: $table.currentWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeats => $composableBuilder(
    column: $table.repeats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnFilters(column),
  );
}

class $$Plan5kStatesTableOrderingComposer
    extends Composer<_$RecordingDatabase, $Plan5kStatesTable> {
  $$Plan5kStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startWeek => $composableBuilder(
    column: $table.startWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentWeek => $composableBuilder(
    column: $table.currentWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeats => $composableBuilder(
    column: $table.repeats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$Plan5kStatesTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $Plan5kStatesTable> {
  $$Plan5kStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get started =>
      $composableBuilder(column: $table.started, builder: (column) => column);

  GeneratedColumn<int> get startWeek =>
      $composableBuilder(column: $table.startWeek, builder: (column) => column);

  GeneratedColumn<int> get currentWeek => $composableBuilder(
    column: $table.currentWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeats =>
      $composableBuilder(column: $table.repeats, builder: (column) => column);

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);
}

class $$Plan5kStatesTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $Plan5kStatesTable,
          Plan5kStateRow,
          $$Plan5kStatesTableFilterComposer,
          $$Plan5kStatesTableOrderingComposer,
          $$Plan5kStatesTableAnnotationComposer,
          $$Plan5kStatesTableCreateCompanionBuilder,
          $$Plan5kStatesTableUpdateCompanionBuilder,
          (
            Plan5kStateRow,
            BaseReferences<
              _$RecordingDatabase,
              $Plan5kStatesTable,
              Plan5kStateRow
            >,
          ),
          Plan5kStateRow,
          PrefetchHooks Function()
        > {
  $$Plan5kStatesTableTableManager(
    _$RecordingDatabase db,
    $Plan5kStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$Plan5kStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$Plan5kStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$Plan5kStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> started = const Value.absent(),
                Value<int> startWeek = const Value.absent(),
                Value<int> currentWeek = const Value.absent(),
                Value<String?> repeats = const Value.absent(),
                Value<bool> finished = const Value.absent(),
              }) => Plan5kStatesCompanion(
                id: id,
                started: started,
                startWeek: startWeek,
                currentWeek: currentWeek,
                repeats: repeats,
                finished: finished,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> started = const Value.absent(),
                Value<int> startWeek = const Value.absent(),
                Value<int> currentWeek = const Value.absent(),
                Value<String?> repeats = const Value.absent(),
                Value<bool> finished = const Value.absent(),
              }) => Plan5kStatesCompanion.insert(
                id: id,
                started: started,
                startWeek: startWeek,
                currentWeek: currentWeek,
                repeats: repeats,
                finished: finished,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$Plan5kStatesTable, Plan5kStateRow>(table),
                  BaseReferences<
                    _$RecordingDatabase,
                    $Plan5kStatesTable,
                    Plan5kStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$Plan5kStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $Plan5kStatesTable,
      Plan5kStateRow,
      $$Plan5kStatesTableFilterComposer,
      $$Plan5kStatesTableOrderingComposer,
      $$Plan5kStatesTableAnnotationComposer,
      $$Plan5kStatesTableCreateCompanionBuilder,
      $$Plan5kStatesTableUpdateCompanionBuilder,
      (
        Plan5kStateRow,
        BaseReferences<_$RecordingDatabase, $Plan5kStatesTable, Plan5kStateRow>,
      ),
      Plan5kStateRow,
      PrefetchHooks Function()
    >;
typedef $$Plan5kSessionsTableCreateCompanionBuilder =
    Plan5kSessionsCompanion Function({
      Value<int> id,
      required int week,
      required int number,
      Value<int> round,
      required String status,
      required int plannedMs,
      Value<int> movingMs,
      Value<String?> activityGuid,
      required int startedAtMs,
      Value<int?> endedAtMs,
    });
typedef $$Plan5kSessionsTableUpdateCompanionBuilder =
    Plan5kSessionsCompanion Function({
      Value<int> id,
      Value<int> week,
      Value<int> number,
      Value<int> round,
      Value<String> status,
      Value<int> plannedMs,
      Value<int> movingMs,
      Value<String?> activityGuid,
      Value<int> startedAtMs,
      Value<int?> endedAtMs,
    });

class $$Plan5kSessionsTableFilterComposer
    extends Composer<_$RecordingDatabase, $Plan5kSessionsTable> {
  $$Plan5kSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedMs => $composableBuilder(
    column: $table.plannedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingMs => $composableBuilder(
    column: $table.movingMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityGuid => $composableBuilder(
    column: $table.activityGuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$Plan5kSessionsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $Plan5kSessionsTable> {
  $$Plan5kSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedMs => $composableBuilder(
    column: $table.plannedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingMs => $composableBuilder(
    column: $table.movingMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityGuid => $composableBuilder(
    column: $table.activityGuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$Plan5kSessionsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $Plan5kSessionsTable> {
  $$Plan5kSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get week =>
      $composableBuilder(column: $table.week, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get plannedMs =>
      $composableBuilder(column: $table.plannedMs, builder: (column) => column);

  GeneratedColumn<int> get movingMs =>
      $composableBuilder(column: $table.movingMs, builder: (column) => column);

  GeneratedColumn<String> get activityGuid => $composableBuilder(
    column: $table.activityGuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMs =>
      $composableBuilder(column: $table.endedAtMs, builder: (column) => column);
}

class $$Plan5kSessionsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $Plan5kSessionsTable,
          Plan5kSessionRow,
          $$Plan5kSessionsTableFilterComposer,
          $$Plan5kSessionsTableOrderingComposer,
          $$Plan5kSessionsTableAnnotationComposer,
          $$Plan5kSessionsTableCreateCompanionBuilder,
          $$Plan5kSessionsTableUpdateCompanionBuilder,
          (
            Plan5kSessionRow,
            BaseReferences<
              _$RecordingDatabase,
              $Plan5kSessionsTable,
              Plan5kSessionRow
            >,
          ),
          Plan5kSessionRow,
          PrefetchHooks Function()
        > {
  $$Plan5kSessionsTableTableManager(
    _$RecordingDatabase db,
    $Plan5kSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$Plan5kSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$Plan5kSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$Plan5kSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> week = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<int> round = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> plannedMs = const Value.absent(),
                Value<int> movingMs = const Value.absent(),
                Value<String?> activityGuid = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
              }) => Plan5kSessionsCompanion(
                id: id,
                week: week,
                number: number,
                round: round,
                status: status,
                plannedMs: plannedMs,
                movingMs: movingMs,
                activityGuid: activityGuid,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int week,
                required int number,
                Value<int> round = const Value.absent(),
                required String status,
                required int plannedMs,
                Value<int> movingMs = const Value.absent(),
                Value<String?> activityGuid = const Value.absent(),
                required int startedAtMs,
                Value<int?> endedAtMs = const Value.absent(),
              }) => Plan5kSessionsCompanion.insert(
                id: id,
                week: week,
                number: number,
                round: round,
                status: status,
                plannedMs: plannedMs,
                movingMs: movingMs,
                activityGuid: activityGuid,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$Plan5kSessionsTable, Plan5kSessionRow>(table),
                  BaseReferences<
                    _$RecordingDatabase,
                    $Plan5kSessionsTable,
                    Plan5kSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$Plan5kSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $Plan5kSessionsTable,
      Plan5kSessionRow,
      $$Plan5kSessionsTableFilterComposer,
      $$Plan5kSessionsTableOrderingComposer,
      $$Plan5kSessionsTableAnnotationComposer,
      $$Plan5kSessionsTableCreateCompanionBuilder,
      $$Plan5kSessionsTableUpdateCompanionBuilder,
      (
        Plan5kSessionRow,
        BaseReferences<
          _$RecordingDatabase,
          $Plan5kSessionsTable,
          Plan5kSessionRow
        >,
      ),
      Plan5kSessionRow,
      PrefetchHooks Function()
    >;
typedef $$SafetyLocalSessionsTableCreateCompanionBuilder =
    SafetyLocalSessionsCompanion Function({
      required String sessionId,
      required String activityGuid,
      Value<String?> ownerUserId,
      required int createdAtMs,
      Value<bool> pendingArrival,
      Value<int> rowid,
    });
typedef $$SafetyLocalSessionsTableUpdateCompanionBuilder =
    SafetyLocalSessionsCompanion Function({
      Value<String> sessionId,
      Value<String> activityGuid,
      Value<String?> ownerUserId,
      Value<int> createdAtMs,
      Value<bool> pendingArrival,
      Value<int> rowid,
    });

class $$SafetyLocalSessionsTableFilterComposer
    extends Composer<_$RecordingDatabase, $SafetyLocalSessionsTable> {
  $$SafetyLocalSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityGuid => $composableBuilder(
    column: $table.activityGuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingArrival => $composableBuilder(
    column: $table.pendingArrival,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SafetyLocalSessionsTableOrderingComposer
    extends Composer<_$RecordingDatabase, $SafetyLocalSessionsTable> {
  $$SafetyLocalSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityGuid => $composableBuilder(
    column: $table.activityGuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingArrival => $composableBuilder(
    column: $table.pendingArrival,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SafetyLocalSessionsTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $SafetyLocalSessionsTable> {
  $$SafetyLocalSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get activityGuid => $composableBuilder(
    column: $table.activityGuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingArrival => $composableBuilder(
    column: $table.pendingArrival,
    builder: (column) => column,
  );
}

class $$SafetyLocalSessionsTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $SafetyLocalSessionsTable,
          SafetyLocalSessionRow,
          $$SafetyLocalSessionsTableFilterComposer,
          $$SafetyLocalSessionsTableOrderingComposer,
          $$SafetyLocalSessionsTableAnnotationComposer,
          $$SafetyLocalSessionsTableCreateCompanionBuilder,
          $$SafetyLocalSessionsTableUpdateCompanionBuilder,
          (
            SafetyLocalSessionRow,
            BaseReferences<
              _$RecordingDatabase,
              $SafetyLocalSessionsTable,
              SafetyLocalSessionRow
            >,
          ),
          SafetyLocalSessionRow,
          PrefetchHooks Function()
        > {
  $$SafetyLocalSessionsTableTableManager(
    _$RecordingDatabase db,
    $SafetyLocalSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SafetyLocalSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SafetyLocalSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SafetyLocalSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> activityGuid = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<bool> pendingArrival = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SafetyLocalSessionsCompanion(
                sessionId: sessionId,
                activityGuid: activityGuid,
                ownerUserId: ownerUserId,
                createdAtMs: createdAtMs,
                pendingArrival: pendingArrival,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String activityGuid,
                Value<String?> ownerUserId = const Value.absent(),
                required int createdAtMs,
                Value<bool> pendingArrival = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SafetyLocalSessionsCompanion.insert(
                sessionId: sessionId,
                activityGuid: activityGuid,
                ownerUserId: ownerUserId,
                createdAtMs: createdAtMs,
                pendingArrival: pendingArrival,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SafetyLocalSessionsTable, SafetyLocalSessionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$RecordingDatabase,
                    $SafetyLocalSessionsTable,
                    SafetyLocalSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SafetyLocalSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $SafetyLocalSessionsTable,
      SafetyLocalSessionRow,
      $$SafetyLocalSessionsTableFilterComposer,
      $$SafetyLocalSessionsTableOrderingComposer,
      $$SafetyLocalSessionsTableAnnotationComposer,
      $$SafetyLocalSessionsTableCreateCompanionBuilder,
      $$SafetyLocalSessionsTableUpdateCompanionBuilder,
      (
        SafetyLocalSessionRow,
        BaseReferences<
          _$RecordingDatabase,
          $SafetyLocalSessionsTable,
          SafetyLocalSessionRow
        >,
      ),
      SafetyLocalSessionRow,
      PrefetchHooks Function()
    >;
typedef $$SafetyMetaTableCreateCompanionBuilder = SafetyMetaCompanion Function({
  required String key,
  required int intValue,
  Value<int> rowid,
});
typedef $$SafetyMetaTableUpdateCompanionBuilder = SafetyMetaCompanion Function({
  Value<String> key,
  Value<int> intValue,
  Value<int> rowid,
});

class $$SafetyMetaTableFilterComposer
    extends Composer<_$RecordingDatabase, $SafetyMetaTable> {
  $$SafetyMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intValue => $composableBuilder(
    column: $table.intValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SafetyMetaTableOrderingComposer
    extends Composer<_$RecordingDatabase, $SafetyMetaTable> {
  $$SafetyMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intValue => $composableBuilder(
    column: $table.intValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SafetyMetaTableAnnotationComposer
    extends Composer<_$RecordingDatabase, $SafetyMetaTable> {
  $$SafetyMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get intValue =>
      $composableBuilder(column: $table.intValue, builder: (column) => column);
}

class $$SafetyMetaTableTableManager
    extends
        RootTableManager<
          _$RecordingDatabase,
          $SafetyMetaTable,
          SafetyMetaRow,
          $$SafetyMetaTableFilterComposer,
          $$SafetyMetaTableOrderingComposer,
          $$SafetyMetaTableAnnotationComposer,
          $$SafetyMetaTableCreateCompanionBuilder,
          $$SafetyMetaTableUpdateCompanionBuilder,
          (
            SafetyMetaRow,
            BaseReferences<
              _$RecordingDatabase,
              $SafetyMetaTable,
              SafetyMetaRow
            >,
          ),
          SafetyMetaRow,
          PrefetchHooks Function()
        > {
  $$SafetyMetaTableTableManager(_$RecordingDatabase db, $SafetyMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SafetyMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SafetyMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SafetyMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<int> intValue = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SafetyMetaCompanion(key: key, intValue: intValue, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required int intValue,
                Value<int> rowid = const Value.absent(),
              }) => SafetyMetaCompanion.insert(
                key: key,
                intValue: intValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SafetyMetaTable, SafetyMetaRow>(table),
                  BaseReferences<
                    _$RecordingDatabase,
                    $SafetyMetaTable,
                    SafetyMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SafetyMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$RecordingDatabase,
      $SafetyMetaTable,
      SafetyMetaRow,
      $$SafetyMetaTableFilterComposer,
      $$SafetyMetaTableOrderingComposer,
      $$SafetyMetaTableAnnotationComposer,
      $$SafetyMetaTableCreateCompanionBuilder,
      $$SafetyMetaTableUpdateCompanionBuilder,
      (
        SafetyMetaRow,
        BaseReferences<_$RecordingDatabase, $SafetyMetaTable, SafetyMetaRow>,
      ),
      SafetyMetaRow,
      PrefetchHooks Function()
    >;

class $RecordingDatabaseManager {
  final _$RecordingDatabase _db;
  $RecordingDatabaseManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$WaypointsTableTableManager get waypoints =>
      $$WaypointsTableTableManager(_db, _db.waypoints);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
  $$RemoteDeletionsTableTableManager get remoteDeletions =>
      $$RemoteDeletionsTableTableManager(_db, _db.remoteDeletions);
  $$LapsTableTableManager get laps => $$LapsTableTableManager(_db, _db.laps);
  $$RecordingGapsTableTableManager get recordingGaps =>
      $$RecordingGapsTableTableManager(_db, _db.recordingGaps);
  $$PrivacyZonesTableTableManager get privacyZones =>
      $$PrivacyZonesTableTableManager(_db, _db.privacyZones);
  $$DismissedZoneSuggestionsTableTableManager get dismissedZoneSuggestions =>
      $$DismissedZoneSuggestionsTableTableManager(
        _db,
        _db.dismissedZoneSuggestions,
      );
  $$Plan5kStatesTableTableManager get plan5kStates =>
      $$Plan5kStatesTableTableManager(_db, _db.plan5kStates);
  $$Plan5kSessionsTableTableManager get plan5kSessions =>
      $$Plan5kSessionsTableTableManager(_db, _db.plan5kSessions);
  $$SafetyLocalSessionsTableTableManager get safetyLocalSessions =>
      $$SafetyLocalSessionsTableTableManager(_db, _db.safetyLocalSessions);
  $$SafetyMetaTableTableManager get safetyMeta =>
      $$SafetyMetaTableTableManager(_db, _db.safetyMeta);
}
