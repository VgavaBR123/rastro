// Porta de agendamento do sync de fundo e implementacao com o pacote
// `workmanager` (WorkManager no Android, BGTaskScheduler no iOS).
//
// O resto do app depende so de [BackgroundSyncScheduler]; testes e
// plataformas sem suporte usam [NoopBackgroundSyncScheduler].
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:strava_estudo_app/sync/background/background_sync.dart';

/// Identificador da tarefa periodica. No iOS e o identificador do
/// BGAppRefreshTask e PRECISA bater com `BGTaskSchedulerPermittedIdentifiers`
/// no Info.plist e com o registro no AppDelegate.swift.
const String kPeriodicSyncTaskId =
    'com.stravaestudo.stravaEstudoApp.backgroundSync';

/// Nome unico da tarefa avulsa disparada ao encerrar uma atividade.
const String kSoonSyncUniqueName = 'background-sync-soon';

/// Nome da tarefa avulsa (chega ao callbackDispatcher; hoje ele ignora).
const String kSoonSyncTaskName = 'backgroundSyncSoon';

/// Agenda o envio das atividades pendentes fora da UI.
abstract class BackgroundSyncScheduler {
  /// Registra o callbackDispatcher no plugin. Chamar uma vez no boot, antes
  /// de agendar qualquer coisa.
  Future<void> initialize();

  /// Garante a tarefa periodica (a cada ~1h, so com rede). Idempotente: se ja
  /// existe, mantem o agendamento atual.
  Future<void> schedulePeriodic();

  /// Pede uma rodada assim que houver rede (ex.: logo apos encerrar uma
  /// atividade). Se ja ha uma rodada avulsa enfileirada, mantem a existente —
  /// ela le a fila inteira quando roda.
  Future<void> scheduleSoon();
}

/// Nao faz nada. Para testes e plataformas sem agendador de fundo.
class NoopBackgroundSyncScheduler implements BackgroundSyncScheduler {
  const NoopBackgroundSyncScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedulePeriodic() async {}

  @override
  Future<void> scheduleSoon() async {}
}

/// Implementacao com o pacote `workmanager`.
///
/// Sem backend configurado (`SYNC_BASE_URL` no placeholder) nao agenda nada:
/// nao ha porque acordar o aparelho. Erros do plugin sao registrados e
/// engolidos — agendamento de fundo e best effort e nunca deve derrubar o app;
/// o sync manual continua disponivel.
class WorkmanagerBackgroundSyncScheduler implements BackgroundSyncScheduler {
  final String baseUrl;
  final Duration periodicFrequency;
  final Duration backoffDelay;
  final Workmanager Function() _workmanager;

  bool _initialized = false;

  WorkmanagerBackgroundSyncScheduler({
    required this.baseUrl,
    this.periodicFrequency = const Duration(hours: 1),
    this.backoffDelay = const Duration(minutes: 2),
    Workmanager Function()? workmanager,
  }) : _workmanager = workmanager ?? Workmanager.new;

  bool get _enabled => isSyncBackendConfigured(baseUrl);

  Constraints get _constraints =>
      Constraints(networkType: NetworkType.connected);

  @override
  Future<void> initialize() async {
    if (!_enabled || _initialized) return;
    try {
      await _workmanager().initialize(callbackDispatcher);
      _initialized = true;
    } on Object catch (e) {
      debugPrint('[background-sync] initialize falhou: $e');
    }
  }

  @override
  Future<void> schedulePeriodic() async {
    if (!_enabled || !_initialized) return;
    try {
      // No iOS o handler recebe o uniqueName como nome da tarefa; usamos o
      // mesmo identificador nos dois campos para nao haver divergencia.
      await _workmanager().registerPeriodicTask(
        kPeriodicSyncTaskId,
        kPeriodicSyncTaskId,
        frequency: periodicFrequency,
        // No iOS a frequencia e ignorada; o initialDelay vira o
        // earliestBeginDate do BGAppRefreshTask.
        initialDelay: periodicFrequency,
        constraints: _constraints,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: backoffDelay,
      );
    } on Object catch (e) {
      debugPrint('[background-sync] schedulePeriodic falhou: $e');
    }
  }

  @override
  Future<void> scheduleSoon() async {
    if (!_enabled || !_initialized) return;
    try {
      await _workmanager().registerOneOffTask(
        kSoonSyncUniqueName,
        kSoonSyncTaskName,
        constraints: _constraints,
        // keep: se ja ha uma rodada enfileirada (inclusive em backoff), ela
        // pega esta atividade tambem; replace poderia interromper um upload
        // em andamento e deixar o header preso em `uploading`.
        existingWorkPolicy: ExistingWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: backoffDelay,
      );
    } on Object catch (e) {
      debugPrint('[background-sync] scheduleSoon falhou: $e');
    }
  }
}

/// Diz se a plataforma atual tem agendador de fundo suportado (Android/iOS).
/// Usa o SO real (`Platform`), nao `defaultTargetPlatform`, que vale android
/// em `flutter test` no host; assim os testes nunca tocam o plugin.
bool get isBackgroundSyncSupportedPlatform =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Cria o agendador adequado a plataforma atual.
BackgroundSyncScheduler createPlatformBackgroundSyncScheduler(String baseUrl) {
  if (!isBackgroundSyncSupportedPlatform) {
    return const NoopBackgroundSyncScheduler();
  }
  return WorkmanagerBackgroundSyncScheduler(baseUrl: baseUrl);
}
