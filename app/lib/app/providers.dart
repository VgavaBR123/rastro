// Injecao de dependencias com Riverpod. Ponto de composicao do app.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../persistence/database.dart';
import '../sync/sync_controller.dart';
import '../sync/upload/activity_uploader.dart';
import '../sync/upload/dio_activity_uploader.dart';
import '../sync/upload/sync_service.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/geo.dart';
import '../recording/presentation/recording_controller.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../recording/source/geolocator_location_source.dart';
import '../recording/source/location_source.dart';
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
const bool kForceLocationManager =
    bool.fromEnvironment('FORCE_LOCATION_MANAGER');

final locationSourceProvider = Provider<LocationSource>((ref) {
  return GeolocatorLocationSource(
    forceLocationManager: kForceLocationManager,
  );
});

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingUiState>((ref) {
  return RecordingController(
    source: ref.watch(locationSourceProvider),
    repo: ref.watch(recordingRepositoryProvider),
  );
});

/// Configuracoes do app (unidades, auto-pause), persistidas no banco.
final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(recordingDatabaseProvider))..load();
});

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

final activityUploaderProvider = Provider<ActivityUploader>((ref) {
  return DioActivityUploader(Dio(), kSyncBaseUrl);
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
  );
});

/// Quantidade de atividades pendentes de upload (para badge/indicador).
final pendingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await ref.watch(recordingDatabaseProvider).pendingActivities();
  return list.length;
});

/// Historico: atividades finalizadas, mais recentes primeiro.
final recentActivitiesProvider = FutureProvider.autoDispose<List<Activity>>((ref) {
  return ref.watch(recordingRepositoryProvider).recent();
});

/// Trajeto de uma atividade (por guid), para o detalhe.
final activityRouteProvider =
    FutureProvider.autoDispose.family<List<GeoPoint>, String>((ref, guid) {
  return ref.watch(recordingRepositoryProvider).routePoints(guid);
});
