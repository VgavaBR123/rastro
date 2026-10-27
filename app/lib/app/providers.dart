// Injecao de dependencias com Riverpod. Ponto de composicao do app.
library;

import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../auth/session_store.dart';
import '../persistence/database.dart';
import '../sync/background/background_sync_provider.dart';
import '../sync/sync_controller.dart';
import '../sync/upload/activity_uploader.dart';
import '../sync/upload/dio_activity_uploader.dart';
import '../sync/upload/sync_service.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/splits.dart';
import '../recording/domain/splits_from_waypoints.dart';
import '../recording/domain/waypoint.dart' as dom;
import '../recording/presentation/recording_controller.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../platform/msl_altitude.dart';
import '../platform/msl_altitude_provider.dart';
import '../recording/service/foreground_task_recording_service.dart';
import '../recording/service/recording_service.dart';
import '../recording/source/accelerometer_source.dart';
import '../recording/source/battery_level_source.dart';
import '../recording/source/geolocator_location_source.dart';
import '../recording/source/location_source.dart';
import '../recording/source/monotonic_clock.dart';
import '../settings/app_settings.dart';
import '../settings/settings_controller.dart';

final recordingDatabaseProvider = Provider<RecordingDatabase>((ref) {
  final db = RecordingDatabase();
  ref.onDispose(db.close);
  return db;
});

final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepository(ref.watch(recordingDatabaseProvider));
});

/// No emulador, as posicoes de `adb emu geo fix` entram no provedor `gps` cru e
/// o FusedLocationProvider nao as repassa. Ligue este flag para testar a
/// gravacao no emulador:
///   flutter run --dart-define=FORCE_LOCATION_MANAGER=true
/// Em aparelho real deixe desligado (padrao), para usar o fused.
const bool kForceLocationManager = bool.fromEnvironment(
  'FORCE_LOCATION_MANAGER',
);

/// True dentro de `flutter test`: as bordas que dependem de plugin (servico,
/// sensores, bateria) caem nas versoes vazias, para os testes de widget que
/// nao sobrescrevem esses providers nao chamarem canais nativos inexistentes.
final bool _underFlutterTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// Plataforma com o servico em primeiro plano do flutter_foreground_task. No
/// iOS a gravacao em segundo plano vem das background modes de localizacao
/// (geolocator), sem servico nem botoes na notificacao.
bool get _isAndroidDevice =>
    !_underFlutterTest &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android;

/// Relogio monotonico compartilhado por GPS e acelerometro.
final monotonicClockProvider = Provider<MonotonicClock>(
  (ref) => MonotonicClock(),
);

/// Conversor de altitude MSL usado pela fonte de GPS (relatorio 03). Quando a
/// conversao falha, a fonte usa a altitude crua.
final recordingMslConverterProvider = Provider<MslAltitudeConverter>(
  // Android: conversor da AndroidX via MethodChannel; demais plataformas e
  // testes no host: sem conversao (altitude crua).
  (ref) => ref.watch(mslAltitudeConverterProvider),
);

final locationSourceProvider = Provider<LocationSource>((ref) {
  return GeolocatorLocationSource(
    forceLocationManager: kForceLocationManager,
    mslConverter: ref.watch(recordingMslConverterProvider),
    clock: ref.watch(monotonicClockProvider),
  );
});

/// Servico em primeiro plano com a notificacao e seus botoes.
final recordingServiceProvider = Provider<RecordingService>((ref) {
  return _isAndroidDevice
      ? ForegroundTaskRecordingService()
      : const NoopRecordingService();
});

/// Acelerometro para a pausa automatica da corrida.
final accelerometerSourceProvider = Provider<AccelerometerSource>((ref) {
  return _underFlutterTest || kIsWeb
      ? const NoAccelerometerSource()
      : SensorsPlusAccelerometerSource(ref.watch(monotonicClockProvider));
});

/// Nivel de bateria no inicio e no fim da atividade.
final batteryLevelSourceProvider = Provider<BatteryLevelSource>((ref) {
  return _underFlutterTest
      ? const NoBatteryLevelSource()
      : BatteryPlusLevelSource();
});

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingUiState>((ref) {
      return RecordingController(
        source: ref.watch(locationSourceProvider),
        repo: ref.watch(recordingRepositoryProvider),
        service: ref.watch(recordingServiceProvider),
        accelerometer: ref.watch(accelerometerSourceProvider),
        battery: ref.watch(batteryLevelSourceProvider),
        currentUserId: () => ref.read(authControllerProvider).user?.id,
        weightKg: () => ref.read(settingsProvider).weightKg,
        useMetric: () => ref.read(settingsProvider).useMetric,
      );
    });

/// Configuracoes do app (unidades, auto-pause), persistidas no banco.
final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) {
    return SettingsController(ref.watch(recordingDatabaseProvider))
    ..ensureLoaded();
  },
);

/// Endpoint de upload do NOSSO backend (`backend/`); NUNCA o Strava.
///
/// Configuravel em tempo de build:
///   flutter run --dart-define=SYNC_BASE_URL=http://10.0.2.2:8081
/// (10.0.2.2 e como o emulador Android alcanca o localhost da maquina; no
/// simulador iOS use http://localhost:8081). Sem a flag, aponta para um host
/// invalido de proposito, para nao vazar upload para lugar nenhum.
const String kSyncBaseUrl = String.fromEnvironment(
  'SYNC_BASE_URL',
  defaultValue: 'https://example.invalid',
);

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  ),
);

// --- Conta (login so e necessario para sincronizar) ---

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider), kSyncBaseUrl);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authApiProvider),
      ref.watch(sessionStoreProvider),
      // Entrou: o que ficou pendente enquanto estava deslogado pode subir.
      onSignedIn: () =>
          ref.read(backgroundSyncSchedulerProvider).scheduleSoon(),
    )..load();
  },
);

/// Perfil com os totais do servidor. Exige sessao e rede.
final profileProvider = FutureProvider.autoDispose<Profile>((ref) async {
  ref.watch(authControllerProvider.select((s) => s.user));
  final session = await ref.watch(sessionStoreProvider).read();
  if (session == null) {
    throw const AuthException('Entre na sua conta', statusCode: 401);
  }
  return ref.watch(authApiProvider).me(session.token);
});

final activityUploaderProvider = Provider<ActivityUploader>((ref) {
  final store = ref.watch(sessionStoreProvider);
  return DioActivityUploader(
    ref.watch(dioProvider),
    kSyncBaseUrl,
    token: () async => (await store.read())?.token,
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(recordingDatabaseProvider),
    ref.watch(activityUploaderProvider),
  );
});

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncUiState>((ref) {
      return SyncController(
        ref.watch(syncServiceProvider),
        ref.watch(recordingDatabaseProvider),
        currentUserId: () async =>
            (await ref.read(sessionStoreProvider).read())?.user.id,
      );
    });

/// Quantidade de atividades pendentes de upload (para badge/indicador).
/// Conta so as que sobem nesta conta: as dela e as gravadas sem conta.
final pendingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  final list = await ref.watch(recordingDatabaseProvider).pendingActivities();
  return list
      .where((a) => a.ownerUserId == null || a.ownerUserId == userId)
      .length;
});

/// Historico: atividades finalizadas, mais recentes primeiro.
final recentActivitiesProvider = FutureProvider.autoDispose<List<Activity>>((
  ref,
) {
  return ref.watch(recordingRepositoryProvider).recent();
});

/// Trajeto de uma atividade (por guid), para o detalhe.
final activityRouteProvider = FutureProvider.autoDispose
    .family<List<GeoPoint>, String>((ref, guid) {
      return ref.watch(recordingRepositoryProvider).routePoints(guid);
    });

/// Splits (km ou milha, conforme a configuracao de unidade) de uma atividade
/// ja gravada. Replay dos pontos aceitos sobre a SplitList do dominio.
final activitySplitsProvider = FutureProvider.autoDispose
    .family<List<ActiveSplit>, String>((ref, guid) async {
      final repo = ref.watch(recordingRepositoryProvider);
      final rows = await repo.waypoints(guid);
      final header = await repo.activity(guid);
      final metric = ref.watch(settingsProvider).useMetric;
      return splitsFromPoints(
        [
          for (final w in rows)
            if (w.classification == dom.WaypointClassification.accept.index)
              SplitSourcePoint(
                cumulativeDistanceMeters: w.cumulativeDistanceMeters,
                timerTimeMs: w.timerTimeMs,
              ),
        ],
        metric: metric,
        finalTimerMs: header?.timerTimeMs,
      );
    });
