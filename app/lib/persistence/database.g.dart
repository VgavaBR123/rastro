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
    defaultValue: const Constant('everyone'),
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
    lastHeartbeatMs,
    heartbeatPaused,
    discardedPointCount,
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
  /// [ActivityVisibility]). Padrao 'everyone', o mesmo da tela Salvar; as
  /// atividades antigas ganham esse valor na migracao. Por enquanto so local.
  final String visibility;

  /// Gravacao blindada (F01): instante (epoch ms) do ultimo batimento salvo
  /// durante a gravacao. Na recuperacao pos-crash, o intervalo dele ate a
  /// retomada vira lacuna. Null = sem batimento (atividades antigas).
  final int? lastHeartbeatMs;

  /// True se o ultimo batimento foi salvo com a gravacao pausada (o tempo
  /// parado depois dele nao e lacuna).
  final bool heartbeatPaused;

  /// Pontos descartados pelo filtro de ruido (nao conta os de pausa).
  final int discardedPointCount;
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
    this.lastHeartbeatMs,
    required this.heartbeatPaused,
    required this.discardedPointCount,
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
    if (!nullToAbsent || lastHeartbeatMs != null) {
      map['last_heartbeat_ms'] = Variable<int>(lastHeartbeatMs);
    }
    map['heartbeat_paused'] = Variable<bool>(heartbeatPaused);
    map['discarded_point_count'] = Variable<int>(discardedPointCount);
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
      lastHeartbeatMs: lastHeartbeatMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeartbeatMs),
      heartbeatPaused: Value(heartbeatPaused),
      discardedPointCount: Value(discardedPointCount),
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
      lastHeartbeatMs: serializer.fromJson<int?>(json['lastHeartbeatMs']),
      heartbeatPaused: serializer.fromJson<bool>(json['heartbeatPaused']),
      discardedPointCount: serializer.fromJson<int>(
        json['discardedPointCount'],
      ),
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
      'lastHeartbeatMs': serializer.toJson<int?>(lastHeartbeatMs),
      'heartbeatPaused': serializer.toJson<bool>(heartbeatPaused),
      'discardedPointCount': serializer.toJson<int>(discardedPointCount),
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
    Value<int?> lastHeartbeatMs = const Value.absent(),
    bool? heartbeatPaused,
    int? discardedPointCount,
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
    lastHeartbeatMs: lastHeartbeatMs.present
        ? lastHeartbeatMs.value
        : this.lastHeartbeatMs,
    heartbeatPaused: heartbeatPaused ?? this.heartbeatPaused,
    discardedPointCount: discardedPointCount ?? this.discardedPointCount,
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
      lastHeartbeatMs: data.lastHeartbeatMs.present
          ? data.lastHeartbeatMs.value
          : this.lastHeartbeatMs,
      heartbeatPaused: data.heartbeatPaused.present
          ? data.heartbeatPaused.value
          : this.heartbeatPaused,
      discardedPointCount: data.discardedPointCount.present
          ? data.discardedPointCount.value
          : this.discardedPointCount,
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
          ..write('lastHeartbeatMs: $lastHeartbeatMs, ')
          ..write('heartbeatPaused: $heartbeatPaused, ')
          ..write('discardedPointCount: $discardedPointCount')
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
    lastHeartbeatMs,
    heartbeatPaused,
    discardedPointCount,
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
          other.lastHeartbeatMs == this.lastHeartbeatMs &&
          other.heartbeatPaused == this.heartbeatPaused &&
          other.discardedPointCount == this.discardedPointCount);
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
  final Value<int?> lastHeartbeatMs;
  final Value<bool> heartbeatPaused;
  final Value<int> discardedPointCount;
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
    this.lastHeartbeatMs = const Value.absent(),
    this.heartbeatPaused = const Value.absent(),
    this.discardedPointCount = const Value.absent(),
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
    this.lastHeartbeatMs = const Value.absent(),
    this.heartbeatPaused = const Value.absent(),
    this.discardedPointCount = const Value.absent(),
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
    Expression<int>? lastHeartbeatMs,
    Expression<bool>? heartbeatPaused,
    Expression<int>? discardedPointCount,
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
      if (lastHeartbeatMs != null) 'last_heartbeat_ms': lastHeartbeatMs,
      if (heartbeatPaused != null) 'heartbeat_paused': heartbeatPaused,
      if (discardedPointCount != null)
        'discarded_point_count': discardedPointCount,
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
    Value<int?>? lastHeartbeatMs,
    Value<bool>? heartbeatPaused,
    Value<int>? discardedPointCount,
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
      lastHeartbeatMs: lastHeartbeatMs ?? this.lastHeartbeatMs,
      heartbeatPaused: heartbeatPaused ?? this.heartbeatPaused,
      discardedPointCount: discardedPointCount ?? this.discardedPointCount,
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
    if (lastHeartbeatMs.present) {
      map['last_heartbeat_ms'] = Variable<int>(lastHeartbeatMs.value);
    }
    if (heartbeatPaused.present) {
      map['heartbeat_paused'] = Variable<bool>(heartbeatPaused.value);
    }
    if (discardedPointCount.present) {
      map['discarded_point_count'] = Variable<int>(discardedPointCount.value);
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
          ..write('lastHeartbeatMs: $lastHeartbeatMs, ')
          ..write('heartbeatPaused: $heartbeatPaused, ')
          ..write('discardedPointCount: $discardedPointCount, ')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    useMetric,
    autoPauseEnabled,
    weightKg,
    reliabilityChecklistSeen,
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
  const SettingsRow({
    required this.id,
    required this.useMetric,
    required this.autoPauseEnabled,
    this.weightKg,
    required this.reliabilityChecklistSeen,
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
    };
  }

  SettingsRow copyWith({
    int? id,
    bool? useMetric,
    bool? autoPauseEnabled,
    Value<double?> weightKg = const Value.absent(),
    bool? reliabilityChecklistSeen,
  }) => SettingsRow(
    id: id ?? this.id,
    useMetric: useMetric ?? this.useMetric,
    autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    reliabilityChecklistSeen:
        reliabilityChecklistSeen ?? this.reliabilityChecklistSeen,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('useMetric: $useMetric, ')
          ..write('autoPauseEnabled: $autoPauseEnabled, ')
          ..write('weightKg: $weightKg, ')
          ..write('reliabilityChecklistSeen: $reliabilityChecklistSeen')
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.useMetric == this.useMetric &&
          other.autoPauseEnabled == this.autoPauseEnabled &&
          other.weightKg == this.weightKg &&
          other.reliabilityChecklistSeen == this.reliabilityChecklistSeen);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<bool> useMetric;
  final Value<bool> autoPauseEnabled;
  final Value<double?> weightKg;
  final Value<bool> reliabilityChecklistSeen;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.useMetric = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reliabilityChecklistSeen = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    this.useMetric = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reliabilityChecklistSeen = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? useMetric,
    Expression<bool>? autoPauseEnabled,
    Expression<double>? weightKg,
    Expression<bool>? reliabilityChecklistSeen,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (useMetric != null) 'use_metric': useMetric,
      if (autoPauseEnabled != null) 'auto_pause_enabled': autoPauseEnabled,
      if (weightKg != null) 'weight_kg': weightKg,
      if (reliabilityChecklistSeen != null)
        'reliability_checklist_seen': reliabilityChecklistSeen,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<bool>? useMetric,
    Value<bool>? autoPauseEnabled,
    Value<double?>? weightKg,
    Value<bool>? reliabilityChecklistSeen,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      useMetric: useMetric ?? this.useMetric,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      weightKg: weightKg ?? this.weightKg,
      reliabilityChecklistSeen:
          reliabilityChecklistSeen ?? this.reliabilityChecklistSeen,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('useMetric: $useMetric, ')
          ..write('autoPauseEnabled: $autoPauseEnabled, ')
          ..write('weightKg: $weightKg, ')
          ..write('reliabilityChecklistSeen: $reliabilityChecklistSeen')
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
  Value<int?> lastHeartbeatMs,
  Value<bool> heartbeatPaused,
  Value<int> discardedPointCount,
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
  Value<int?> lastHeartbeatMs,
  Value<bool> heartbeatPaused,
  Value<int> discardedPointCount,
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
                Value<int?> lastHeartbeatMs = const Value.absent(),
                Value<bool> heartbeatPaused = const Value.absent(),
                Value<int> discardedPointCount = const Value.absent(),
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
                lastHeartbeatMs: lastHeartbeatMs,
                heartbeatPaused: heartbeatPaused,
                discardedPointCount: discardedPointCount,
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
                Value<int?> lastHeartbeatMs = const Value.absent(),
                Value<bool> heartbeatPaused = const Value.absent(),
                Value<int> discardedPointCount = const Value.absent(),
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
                lastHeartbeatMs: lastHeartbeatMs,
                heartbeatPaused: heartbeatPaused,
                discardedPointCount: discardedPointCount,
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
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<bool> useMetric,
      Value<bool> autoPauseEnabled,
      Value<double?> weightKg,
      Value<bool> reliabilityChecklistSeen,
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
              }) => SettingsRowsCompanion(
                id: id,
                useMetric: useMetric,
                autoPauseEnabled: autoPauseEnabled,
                weightKg: weightKg,
                reliabilityChecklistSeen: reliabilityChecklistSeen,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> useMetric = const Value.absent(),
                Value<bool> autoPauseEnabled = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<bool> reliabilityChecklistSeen = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                useMetric: useMetric,
                autoPauseEnabled: autoPauseEnabled,
                weightKg: weightKg,
                reliabilityChecklistSeen: reliabilityChecklistSeen,
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
}
