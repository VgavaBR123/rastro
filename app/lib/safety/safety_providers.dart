// Providers do Rastro Seguro (F08).
//
// Para o E2E (duas contas, tempos curtos), sobrescreva:
// - [safetyPositionIntervalProvider]: intervalo das posicoes (60 s);
// - [safetyTickerProvider]: o tick das posicoes (Periodic no aparelho);
// - [inboxIntervalProvider] e [inboxTickerProvider]: busca da caixa (30 s);
// - [safetyCountdownTickerProvider]: o tick de 1 s da contagem do aviso;
// - [safetyClockProvider]: relogio de parede (epoch ms);
// - [urlOpenerProvider]: quem abre o link "Ver localizacao";
// - [safetyHapticsProvider] e [pushRegistrarProvider].
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../app/providers.dart';
import '../narrator/narrator_providers.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../recording/source/heartbeat_ticker.dart';
import 'contacts_controller.dart';
import 'inbox_controller.dart';
import 'push_registrar.dart';
import 'safety_api.dart';
import 'safety_models.dart';
import 'safety_session_controller.dart';
import 'url_opener.dart';

final bool _underFlutterTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

HeartbeatTicker _defaultTicker() => _underFlutterTest ? const NoHeartbeatTicker() : const PeriodicHeartbeatTicker();

/// Relogio de parede (epoch ms): horario previsto, contagem e validacoes.
final safetyClockProvider = Provider<int Function()>(
  (_) =>
      () => DateTime.now().millisecondsSinceEpoch,
);

final safetyApiProvider = Provider<SafetyApi>((ref) {
  final store = ref.watch(sessionStoreProvider);
  return SafetyApi(ref.watch(dioProvider), kSyncBaseUrl, token: () async => (await store.read())?.token);
});

final safetyPositionIntervalProvider = Provider<Duration>((_) => kSafetyPositionInterval);

/// Tick das posicoes. Em `flutter test` nao bate (testes injetam um falso).
final safetyTickerProvider = Provider<HeartbeatTicker>((_) => _defaultTicker());

/// Tick de 1 s da contagem regressiva do aviso "esta tudo bem?".
final safetyCountdownTickerProvider = Provider<HeartbeatTicker>((_) => _defaultTicker());

final safetyHapticsProvider = Provider<SafetyHaptics>((_) => const SystemSafetyHaptics());

final urlOpenerProvider = Provider<UrlOpener>((_) => const LauncherUrlOpener());

/// Push: Noop ate existir o projeto Firebase (ver push_registrar.dart).
final pushRegistrarProvider = Provider<PushRegistrar>((_) => const NoopPushRegistrar());

/// Escolha da tela Gravar (contatos e chegada) para a proxima gravacao.
/// A tela de gravacao le e limpa ao iniciar.
final safetyPlanProvider = StateProvider<SafetyPlan?>((_) => null);

/// Sessao do Rastro Seguro da gravacao. Encerra (arrived) quando a gravacao
/// termina, por qualquer caminho (Salvar, Descartar, notificacao).
final safetySessionProvider = StateNotifierProvider<SafetySessionController, SafetyUiState>((ref) {
  final recording = ref.read(recordingControllerProvider.notifier);
  final c = SafetySessionController(
    api: ref.watch(safetyApiProvider),
    ticker: ref.watch(safetyTickerProvider),
    interval: ref.watch(safetyPositionIntervalProvider),
    now: ref.watch(safetyClockProvider),
    lastSample: () => recording.lastSample,
    recording: () => ref.read(recordingControllerProvider),
    recordingGuid: () => recording.activityGuid,
    narrator: ref.watch(narratorProvider),
    haptics: ref.watch(safetyHapticsProvider),
  );
  ref.listen<RecordingUiState>(recordingControllerProvider, (_, next) => c.onRecording(next));
  return c;
});

final contactsProvider = StateNotifierProvider<ContactsController, ContactsState>(
  (ref) => ContactsController(ref.watch(safetyApiProvider)),
);

final inboxIntervalProvider = Provider<Duration>((_) => const Duration(seconds: 30));

/// Tick da caixa de entrada. Em `flutter test` nao bate.
final inboxTickerProvider = Provider<HeartbeatTicker>((_) => _defaultTicker());

final inboxProvider = StateNotifierProvider<InboxController, InboxState>((ref) {
  return InboxController(
    ref.watch(safetyApiProvider),
    now: ref.watch(safetyClockProvider),
    onNew: (n) {
      switch (n.kind) {
        case NotificationKind.safetyCheck:
          ref.read(safetySessionProvider.notifier).onInboxCheck(n.sessionId);
        case NotificationKind.contactInvite || NotificationKind.contactAccepted:
          // A lista de contatos aberta (ou a proxima) ja mostra o convite.
          ref.read(contactsProvider.notifier).load();
        default:
          break;
      }
    },
  );
});
