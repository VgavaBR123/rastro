// Alertas do Rastro Seguro (F08) fora da tela da caixa de entrada: textos
// comuns, a notificacao local do sistema (canal Android de alta importancia
// "Alertas do Rastro Seguro"), o cursor que garante uma notificacao por
// alerta e a rodada do sync de fundo (WorkManager, ~15 min) que manda os
// "arrived" pendentes e avisa os alertas novos com o app fechado.
//
// Sem push configurado (FCM), o contato so e avisado com o app aberto (busca a
// cada 30 s) ou na rodada de fundo; ver [kNoPushNotice].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'safety_api.dart';
import 'safety_local_store.dart';
import 'safety_models.dart';
import 'safety_session_controller.dart' show sendPendingArrivals;

/// Aviso honesto enquanto o push real nao existe.
const String kNoPushNotice =
    'Sem as notificacoes push configuradas, voce so e avisado com o app aberto ou em ate 15 minutos.';

/// Titulo do alerta para a caixa, o dialogo e a notificacao do sistema.
String alertTitle(AppNotification n) {
  final who = n.ownerName ?? 'Um contato';
  return switch (n.kind) {
    NotificationKind.safetyAlert => '$who pode precisar de ajuda',
    NotificationKind.safetySos => '$who pediu ajuda',
    NotificationKind.safetyEndedUnconfirmed => '$who nao confirmou que esta bem',
    NotificationKind.safetyLinkUpdated => '$who ainda nao respondeu: link novo',
    NotificationKind.safetyAllClear => '${n.ownerName ?? 'Seu contato'} respondeu que esta bem',
    NotificationKind.safetyEnded => 'O acompanhamento terminou',
    NotificationKind.safetyNoContacts => 'Ninguem vai ser avisado se voce nao responder',
    NotificationKind.safetyContactRemoved => '${n.data['contactName'] ?? 'Um contato'} saiu do seu Rastro Seguro',
    _ => n.title.isEmpty ? 'Notificacao' : n.title,
  };
}

/// Texto do alerta (motivo).
String alertDetail(AppNotification n) => switch (n.kind) {
  NotificationKind.safetyAlert =>
    'Motivo: ${checkReasonLabel(n.reason)}. Nao respondeu a checagem do Rastro Seguro.',
  NotificationKind.safetySos => 'Mandou a posicao pelo Rastro Seguro.',
  NotificationKind.safetyEndedUnconfirmed =>
    'O acompanhamento terminou sem confirmacao de que esta tudo bem. Veja a ultima posicao.',
  NotificationKind.safetyLinkUpdated => 'O link anterior parou de funcionar. Use o novo para ver a posicao.',
  _ => n.body,
};

/// Notificacao local do sistema.
abstract interface class SafetyLocalNotifier {
  Future<void> show(AppNotification n);
}

class NoopSafetyLocalNotifier implements SafetyLocalNotifier {
  const NoopSafetyLocalNotifier();
  @override
  Future<void> show(AppNotification n) async {}
}

const String kSafetyAlertChannelId = 'rastro_seguro_alertas';
const String kSafetyAlertChannelName = 'Alertas do Rastro Seguro';

/// flutter_local_notifications (BSD-3). Inicializa na primeira vez; pede a
/// permissao no iOS (no Android a POST_NOTIFICATIONS ja e do app).
class FlutterSafetyLocalNotifier implements SafetyLocalNotifier {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  FlutterSafetyLocalNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _ready = true;
  }

  @override
  Future<void> show(AppNotification n) async {
    try {
      await _init();
      await _plugin.show(
        id: n.id.hashCode & 0x7fffffff,
        title: alertTitle(n),
        body: alertDetail(n),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            kSafetyAlertChannelId,
            kSafetyAlertChannelName,
            channelDescription: 'Quando um contato de confianca pode precisar de ajuda',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.active),
        ),
        payload: n.id,
      );
    } catch (e) {
      debugPrint('Notificacao local do alerta falhou: $e');
    }
  }
}

/// Mostra a notificacao local dos alertas de [list] ainda nao avisados
/// (createdAt acima do cursor no banco). Devolve quantos mostrou.
Future<int> notifyNewAlerts(List<AppNotification> list, SafetyLocalStore store, SafetyLocalNotifier notifier) async {
  final cursor = await store.alertsSeenMs();
  final fresh = [
    for (final n in list)
      if (n.isAlert && n.unread && n.createdAt > cursor) n,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  for (final n in fresh) {
    await notifier.show(n);
  }
  if (fresh.isNotEmpty) await store.setAlertsSeenMs(fresh.last.createdAt);
  return fresh.length;
}

/// Rodada do Rastro Seguro no sync de fundo: "arrived" pendentes desta conta
/// e notificacao local dos alertas novos. Devolve false se algo ficou para
/// tras (o WorkManager tenta de novo). Nunca lanca.
Future<bool> runSafetyBackground({
  required SafetyApi api,
  required SafetyLocalStore store,
  required SafetyLocalNotifier notifier,
  required String ownerUserId,
}) async {
  var ok = true;
  try {
    if (await sendPendingArrivals(api, store, ownerUserId: ownerUserId) > 0) ok = false;
  } on Object catch (e) {
    debugPrint('[background-safety] arrived pendente falhou: $e');
    ok = false;
  }
  try {
    final cursor = await store.alertsSeenMs();
    final list = await api.notifications(since: cursor > 0 ? cursor - 1 : 0);
    await notifyNewAlerts(list, store, notifier);
  } on Object catch (e) {
    debugPrint('[background-safety] caixa de entrada falhou: $e');
    ok = false;
  }
  return ok;
}

/// Fila dos alertas que aparecem por cima de qualquer tela (o primeiro e o
/// mostrado; fechar ou abrir o link tira da fila).
class SafetyAlertQueue extends StateNotifier<List<AppNotification>> {
  SafetyAlertQueue() : super(const []);

  /// Entra se ainda nao esta na fila. Devolve se entrou.
  bool add(AppNotification n) {
    if (state.any((m) => m.id == n.id)) return false;
    state = [...state, n];
    return true;
  }

  void dismiss(String id) => state = [
    for (final m in state)
      if (m.id != id) m,
  ];

  void clear() => state = const [];
}
