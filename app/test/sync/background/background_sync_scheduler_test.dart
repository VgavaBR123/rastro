// Testes do agendador com um Workmanager falso (nao toca o plugin nativo).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/sync/background/background_sync_scheduler.dart';
import 'package:workmanager/workmanager.dart';

/// Registra as chamadas que o agendador faz ao plugin.
class FakeWorkmanager implements Workmanager {
  bool throwOnInit = false;
  int initCalls = 0;
  final List<Map<String, Object?>> periodic = <Map<String, Object?>>[];
  final List<Map<String, Object?>> oneOff = <Map<String, Object?>>[];

  @override
  Future<void> initialize(Function callbackDispatcher,
      {bool isInDebugMode = false}) async {
    initCalls++;
    if (throwOnInit) throw StateError('plugin ausente');
  }

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    periodic.add(<String, Object?>{
      'uniqueName': uniqueName,
      'taskName': taskName,
      'frequency': frequency,
      'network': constraints?.networkType,
      'policy': existingWorkPolicy,
      'backoff': backoffPolicy,
    });
  }

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    ForegroundServiceConfig? foregroundServiceConfig,
    bool expedited = false,
  }) async {
    oneOff.add(<String, Object?>{
      'uniqueName': uniqueName,
      'taskName': taskName,
      'network': constraints?.networkType,
      'policy': existingWorkPolicy,
      'backoff': backoffPolicy,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeWorkmanager wm;
  setUp(() => wm = FakeWorkmanager());

  WorkmanagerBackgroundSyncScheduler scheduler(String url) =>
      WorkmanagerBackgroundSyncScheduler(baseUrl: url, workmanager: () => wm);

  test('com backend: periodico de 1h com rede, keep e backoff exponencial',
      () async {
    final s = scheduler('http://localhost:8081');
    await s.initialize();
    await s.schedulePeriodic();

    expect(wm.initCalls, 1);
    expect(wm.periodic, hasLength(1));
    final p = wm.periodic.single;
    expect(p['uniqueName'], kPeriodicSyncTaskId);
    expect(p['taskName'], kPeriodicSyncTaskId);
    expect(p['frequency'], const Duration(hours: 1));
    expect(p['network'], NetworkType.connected);
    expect(p['policy'], ExistingPeriodicWorkPolicy.keep);
    expect(p['backoff'], BackoffPolicy.exponential);
  });

  test('scheduleSoon: one-off com rede e keep', () async {
    final s = scheduler('http://localhost:8081');
    await s.initialize();
    await s.scheduleSoon();

    final o = wm.oneOff.single;
    expect(o['uniqueName'], kSoonSyncUniqueName);
    expect(o['network'], NetworkType.connected);
    expect(o['policy'], ExistingWorkPolicy.keep);
    expect(o['backoff'], BackoffPolicy.exponential);
  });

  test('sem backend configurado não inicializa nem agenda nada', () async {
    final s = scheduler('https://example.invalid');
    await s.initialize();
    await s.schedulePeriodic();
    await s.scheduleSoon();

    expect(wm.initCalls, 0);
    expect(wm.periodic, isEmpty);
    expect(wm.oneOff, isEmpty);
  });

  test('initialize só uma vez', () async {
    final s = scheduler('http://localhost:8081');
    await s.initialize();
    await s.initialize();
    expect(wm.initCalls, 1);
  });

  test('falha no initialize não lanca e bloqueia os agendamentos', () async {
    wm.throwOnInit = true;
    final s = scheduler('http://localhost:8081');
    await s.initialize();
    await s.schedulePeriodic();
    await s.scheduleSoon();

    expect(wm.periodic, isEmpty);
    expect(wm.oneOff, isEmpty);
  });

  test('no host de testes a fabrica devolve o no-op', () async {
    final s = createPlatformBackgroundSyncScheduler('http://localhost:8081');
    expect(s, isA<NoopBackgroundSyncScheduler>());
    await s.initialize();
    await s.schedulePeriodic();
    await s.scheduleSoon();
  });
}
