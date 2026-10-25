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
          ..write('autoPauseEnabled: $autoPauseEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  );
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
          other.autoPauseEnabled == this.autoPauseEnabled);
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
  @override
  List<GeneratedColumn> get $columns => [id, useMetric, autoPauseEnabled];
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
  const SettingsRow({
    required this.id,
    required this.useMetric,
    required this.autoPauseEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['use_metric'] = Variable<bool>(useMetric);
    map['auto_pause_enabled'] = Variable<bool>(autoPauseEnabled);
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      useMetric: Value(useMetric),
      autoPauseEnabled: Value(autoPauseEnabled),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'useMetric': serializer.toJson<bool>(useMetric),
      'autoPauseEnabled': serializer.toJson<bool>(autoPauseEnabled),
    };
  }

  SettingsRow copyWith({int? id, bool? useMetric, bool? autoPauseEnabled}) =>
      SettingsRow(
        id: id ?? this.id,
        useMetric: useMetric ?? this.useMetric,
        autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      useMetric: data.useMetric.present ? data.useMetric.value : this.useMetric,
      autoPauseEnabled: data.autoPauseEnabled.present
          ? data.autoPauseEnabled.value
          : this.autoPauseEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('useMetric: $useMetric, ')
          ..write('autoPauseEnabled: $autoPauseEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, useMetric, autoPauseEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.useMetric == this.useMetric &&
          other.autoPauseEnabled == this.autoPauseEnabled);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<bool> useMetric;
  final Value<bool> autoPauseEnabled;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.useMetric = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    this.useMetric = const Value.absent(),
    this.autoPauseEnabled = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? useMetric,
    Expression<bool>? autoPauseEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (useMetric != null) 'use_metric': useMetric,
      if (autoPauseEnabled != null) 'auto_pause_enabled': autoPauseEnabled,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<bool>? useMetric,
    Value<bool>? autoPauseEnabled,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      useMetric: useMetric ?? this.useMetric,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('useMetric: $useMetric, ')
          ..write('autoPauseEnabled: $autoPauseEnabled')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    activities,
    waypoints,
    settingsRows,
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
          PrefetchHooks Function({bool waypointsRefs})
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
          prefetchHooksCallback: ({waypointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (waypointsRefs) db.waypoints],
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
      PrefetchHooks Function({bool waypointsRefs})
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
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<bool> useMetric,
      Value<bool> autoPauseEnabled,
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
              }) => SettingsRowsCompanion(
                id: id,
                useMetric: useMetric,
                autoPauseEnabled: autoPauseEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> useMetric = const Value.absent(),
                Value<bool> autoPauseEnabled = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                useMetric: useMetric,
                autoPauseEnabled: autoPauseEnabled,
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

class $RecordingDatabaseManager {
  final _$RecordingDatabase _db;
  $RecordingDatabaseManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$WaypointsTableTableManager get waypoints =>
      $$WaypointsTableTableManager(_db, _db.waypoints);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
}
