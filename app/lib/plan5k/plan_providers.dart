// Providers do plano 5 km (F06).
//
// Para testes de ponta a ponta acelerarem o tempo, sobrescreva:
// - [plan5kTableProvider]: tabela curta (ex.: blocos de 15 s);
// - [planMonotonicNowProvider]: relogio do plano (ex.: Stopwatch x 30);
// - [planTickerProvider]: o tick que faz o plano andar (1 s por padrao).
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../app/providers.dart';
import '../narrator/narrator_providers.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../recording/source/heartbeat_ticker.dart';
import 'domain/plan_progress.dart';
import 'domain/plan_table.dart';
import 'guided_session.dart';
import 'plan_repository.dart';
import 'plan_service.dart';

final bool _underFlutterTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// Tabela do plano. Padrao: a fixa de 30 sessoes.
final plan5kTableProvider = Provider<List<PlanSession>>((_) => kPlan5k);

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(recordingDatabaseProvider)),
);

final planServiceProvider = Provider<PlanService>(
  (ref) => PlanService(
    ref.watch(planRepositoryProvider),
    table: ref.watch(plan5kTableProvider),
  ),
);

/// Vibracao das trocas de bloco.
final planHapticsProvider = Provider<PlanHaptics>((_) => const SystemPlanHaptics());

/// Relogio monotonico do plano (ms).
final planMonotonicNowProvider = Provider<int Function()>((_) {
  final sw = Stopwatch()..start();
  return () => sw.elapsedMilliseconds;
});

/// Tick do plano. Em `flutter test` nao bate (sem Timer pendente nos testes
/// de widget); os testes do plano injetam um falso.
final planTickerProvider = Provider<HeartbeatTicker>(
  (_) => _underFlutterTest ? const NoHeartbeatTicker() : const PeriodicHeartbeatTicker(),
);

/// Progresso do plano para as telas. Invalide depois de mudar o plano.
final planProgressProvider = FutureProvider.autoDispose<PlanProgress>((ref) {
  final rec = ref.read(recordingControllerProvider);
  final guid = rec.isActive ? ref.read(recordingControllerProvider.notifier).activityGuid : null;
  return ref.watch(planServiceProvider).progress(activeGuid: guid);
});

/// Sessao guiada durante a gravacao. Null = gravacao comum.
final guidedSessionProvider =
    StateNotifierProvider<GuidedSessionController, GuidedUiState?>((ref) {
      final recording = ref.read(recordingControllerProvider.notifier);
      final g = GuidedSessionController(
        repo: ref.watch(planRepositoryProvider),
        narrator: ref.watch(narratorProvider),
        voiceOn: () => ref.read(settingsProvider).plan5kVoice,
        haptics: ref.watch(planHapticsProvider),
        monotonicNow: ref.watch(planMonotonicNowProvider),
        wallNow: () => DateTime.now().millisecondsSinceEpoch,
        ticker: ref.watch(planTickerProvider),
        closeLap: recording.lap,
        setNotice: recording.setGuidedNotice,
        activityGuid: () => recording.activityGuid,
        recording: () => ref.read(recordingControllerProvider),
        table: () => ref.read(plan5kTableProvider),
      );
      ref.listen<RecordingUiState>(
        recordingControllerProvider,
        (_, next) => g.onRecording(next),
      );
      return g;
    });
