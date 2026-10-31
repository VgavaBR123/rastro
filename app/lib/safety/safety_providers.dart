// Providers do Rastro Seguro (F08).
//
// Para o E2E (duas contas, tempos curtos), sobrescreva:
// - [safetyPositionIntervalProvider]: intervalo das posicoes (60 s);
// - [safetyTickerProvider]: o tick das posicoes (Periodic no aparelho);
// - [inboxIntervalProvider] e [inboxTickerProvider]: busca da caixa (30 s);
// - [safetyCountdownTickerProvider]: o tick de 1 s da contagem do aviso;
// - [safetyClockProvider]: relogio de parede (epoch ms);
// - [urlOpenerProvider]: quem abre o link "Ver localizacao";
// - [safetyHapticsProvider], [pushRegistrarProvider] e [safetyLocalNotifierProvider]
//   (notificacao local dos alertas; Noop em `flutter test`).
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../app/providers.dart';
import '../narrator/domain/announcement.dart';
import '../narrator/narrator_providers.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../recording/source/heartbeat_ticker.dart';
import 'contacts_controller.dart';
import 'safety_alerts.dart';
import 'inbox_controller.dart';
import 'push_registrar.dart';
import 'safety_api.dart';
import 'safety_local_store.dart';
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

final urlOpenerProvider = Provider<UrlOpener>((_) => LauncherUrlOpener(backendBaseUrl: kSyncBaseUrl));

/// Notificacao local do sistema para os alertas (canal "Alertas do Rastro
/// Seguro"). Em `flutter test`: Noop.
final safetyLocalNotifierProvider = Provider<SafetyLocalNotifier>(
  (_) => _underFlutterTest || kIsWeb ? const NoopSafetyLocalNotifier() : FlutterSafetyLocalNotifier(),
);

/// Alertas mostrados por cima de qualquer tela (ver SafetyAlertHost).
final safetyAlertQueueProvider = StateNotifierProvider<SafetyAlertQueue, List<AppNotification>>(
  (_) => SafetyAlertQueue(),
);

/// Alertas mais velhos que isto nao abrem o dialogo (so ficam na caixa).
const int kSafetyAlertPopupMaxAgeMs = 24 * 3600000;

/// Push: Noop ate existir o projeto Firebase (ver push_registrar.dart).
final pushRegistrarProvider = Provider<PushRegistrar>((_) => const NoopPushRegistrar());

/// Escolha da tela Gravar (contatos e chegada) para a proxima gravacao.
/// A tela de gravacao le e limpa ao iniciar.
final safetyPlanProvider = StateProvider<SafetyPlan?>((_) => null);

/// Sessao do Rastro Seguro da gravacao. Encerra (arrived) quando a gravacao
/// termina, por qualquer caminho (Salvar, Descartar, notificacao).
/// Registro local das sessoes criadas neste aparelho (banco da gravacao).
final safetyLocalStoreProvider = Provider<SafetyLocalStore>(
  (ref) => SafetyLocalStore(ref.watch(recordingDatabaseProvider)),
);

final StateNotifierProvider<SafetySessionController, SafetyUiState> safetySessionProvider =
    StateNotifierProvider<SafetySessionController, SafetyUiState>((ref) {
      final recording = ref.read(recordingControllerProvider.notifier);
      final c = SafetySessionController(
        api: ref.watch(safetyApiProvider),
        local: ref.watch(safetyLocalStoreProvider),
        ticker: ref.watch(safetyTickerProvider),
        interval: ref.watch(safetyPositionIntervalProvider),
        now: ref.watch(safetyClockProvider),
        lastSample: () => recording.lastSample,
        recentAccepted: (since) => recording.recentAccepted(sinceWallMs: since),
        currentUserId: () => ref.read(authControllerProvider).user?.id,
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
      if (n.isAlert && n.unread) _onAlert(ref, n);
      switch (n.kind) {
        case NotificationKind.safetyCheck || NotificationKind.safetyEnded || NotificationKind.safetyContactRemoved:
          // Rele a sessao (checagem nova, fim automatico, link novo).
          ref.read(safetySessionProvider.notifier).onInboxCheck(n.sessionId);
        case NotificationKind.safetyNoContacts:
          ref.read(safetySessionProvider.notifier).onNoContacts(n.sessionId);
        case NotificationKind.contactInvite || NotificationKind.contactAccepted:
          // A lista de contatos aberta (ou a proxima) ja mostra o convite.
          ref.read(contactsProvider.notifier).load();
        default:
          break;
      }
    },
  );
});

/// Alerta novo de um contato: dialogo por cima de tudo (inclusive durante a
/// propria gravacao), fala critica, vibracao e notificacao local (uma vez por
/// alerta, com o mesmo cursor do sync de fundo).
void _onAlert(Ref ref, AppNotification n) {
  final notifier = ref.read(safetyLocalNotifierProvider);
  final store = ref.read(safetyLocalStoreProvider);
  notifyNewAlerts([n], store, notifier).catchError((Object _) => 0);
  final age = ref.read(safetyClockProvider)() - n.createdAt;
  if (age > kSafetyAlertPopupMaxAgeMs) return;
  if (!ref.read(safetyAlertQueueProvider.notifier).add(n)) return;
  ref
      .read(narratorProvider)
      .enqueue(
        Announcement(
          'Alerta do Rastro Seguro. ${alertTitle(n)}.',
          priority: AnnouncementPriority.critical,
          key: 'safety_alert',
          maxAgeMs: 120000,
        ),
      );
  ref.read(safetyHapticsProvider).alert().catchError((Object _) {});
}
