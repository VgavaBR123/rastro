// Alertas do Rastro Seguro fora da tela da caixa: tipos novos do backend,
// notificacao local uma vez por alerta (cursor no banco), rodada de fundo
// (arrived pendente + alertas), link mais novo da sessao, caixa com since =
// max - 1 sem duplicar, pagina cheia busca de novo e reset que descarta a
// busca em voo.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/safety/inbox_controller.dart';
import 'package:strava_estudo_app/safety/safety_alerts.dart';
import 'package:strava_estudo_app/safety/safety_api.dart';
import 'package:strava_estudo_app/safety/safety_local_store.dart';
import 'package:strava_estudo_app/safety/safety_models.dart';

import 'fake_safety_server.dart';

class FakeLocalNotifier implements SafetyLocalNotifier {
  final List<AppNotification> shown = [];
  @override
  Future<void> show(AppNotification n) async => shown.add(n);
}

void main() {
  late FakeSafetyServer server;
  late RecordingDatabase db;
  late SafetyLocalStore store;
  late FakeLocalNotifier notifier;
  var nowMs = 1000;

  SafetyApi api() => SafetyApi(Dio()..httpClientAdapter = server, 'http://srv', token: () async => 'tok');

  setUp(() {
    nowMs = 1000;
    server = FakeSafetyServer(now: () => nowMs);
    server.addUser('tok', 'u_ana', 'ana@x.com', 'Ana');
    db = RecordingDatabase(NativeDatabase.memory());
    store = SafetyLocalStore(db);
    notifier = FakeLocalNotifier();
  });
  tearDown(() => db.close());

  test('tipos novos do backend', () {
    for (final (type, kind, alert) in [
      ('safety_ended', NotificationKind.safetyEnded, false),
      ('safety_ended_unconfirmed', NotificationKind.safetyEndedUnconfirmed, true),
      ('safety_contact_removed', NotificationKind.safetyContactRemoved, false),
      ('safety_no_contacts', NotificationKind.safetyNoContacts, false),
      ('safety_link_updated', NotificationKind.safetyLinkUpdated, true),
      ('safety_alert', NotificationKind.safetyAlert, true),
      ('safety_sos', NotificationKind.safetySos, true),
    ]) {
      final n = AppNotification.fromJson({'id': 'n', 'type': type, 'createdAt': 1});
      expect(n.kind, kind, reason: type);
      expect(n.isAlert, alert, reason: type);
    }
  });

  test('lastPosition le receivedAtMs', () {
    final p = SafetyPosition.fromJson({'lat': 1, 'lon': 2, 'recordedAtMs': 5, 'receivedAtMs': 7})!;
    expect(p.receivedAtMs, 7);
  });

  test('notificacao local: so alertas novos, uma vez cada', () async {
    server.notify('u_ana', 'safety_alert', data: {'ownerName': 'Bia'});
    server.notify('u_ana', 'contact_accepted');
    final list = await api().notifications(since: 0);
    expect(await notifyNewAlerts(list, store, notifier), 1);
    expect(notifier.shown.single.kind, NotificationKind.safetyAlert);
    expect(await notifyNewAlerts(list, store, notifier), 0);
    nowMs = 2000;
    server.notify('u_ana', 'safety_sos', data: {'ownerName': 'Bia'});
    await notifyNewAlerts(await api().notifications(since: 0), store, notifier);
    expect(notifier.shown.map((n) => n.kind), [NotificationKind.safetyAlert, NotificationKind.safetySos]);
  });

  test('rodada de fundo: manda arrived pendente e avisa alerta novo', () async {
    final s = await api().createSession(activityGuid: 'act_1', etaMs: nowMs + 3600000, contactIds: [
      server.linkAccepted(server.tokens['tok']!, server.addUser('t2', 'u_bia', 'bia@x.com', 'Bia')),
    ]);
    await store.created(sessionId: s.id, activityGuid: 'act_1', ownerUserId: 'u_ana', nowMs: 1);
    await store.markPendingArrival(s.id);
    server.notify('u_ana', 'safety_ended_unconfirmed', data: {'ownerName': 'Bia', 'shareUrl': 'http://x/s/1'});
    expect(await runSafetyBackground(api: api(), store: store, notifier: notifier, ownerUserId: 'u_ana'), isTrue);
    expect(server.sessionById(s.id)!['status'], 'ended');
    expect(notifier.shown.single.kind, NotificationKind.safetyEndedUnconfirmed);
    server.offline = true;
    expect(await runSafetyBackground(api: api(), store: store, notifier: notifier, ownerUserId: 'u_ana'), isFalse);
  });

  group('caixa de entrada', () {
    test('since = max - 1 e sem duplicar quem tem o mesmo instante', () async {
      final inbox = InboxController(api(), now: () => nowMs);
      server.notify('u_ana', 'contact_invite');
      await inbox.refresh();
      // Outra no mesmo milissegundo, gravada depois da busca.
      server.notify('u_ana', 'contact_accepted');
      await inbox.refresh();
      expect(server.requests.last.query['since'], '999');
      expect(inbox.state.items, hasLength(2));
    });

    test('pagina cheia (50): busca de novo ate vir menos', () async {
      for (var i = 0; i < 60; i++) {
        nowMs = 1000 + i;
        server.notify('u_ana', 'contact_accepted');
      }
      // O servidor falso devolve as 50 mais novas; a segunda busca traz o
      // resto a partir do maior instante visto.
      final inbox = InboxController(api(), now: () => nowMs);
      await inbox.refresh();
      expect(server.requestsTo('GET', '/notifications').length, greaterThanOrEqualTo(2));
    });

    test('link mais novo da sessao vale para o alerta antigo', () async {
      server.notify('u_ana', 'safety_alert', data: {'sessionId': 'ss_1', 'shareUrl': 'http://x/s/velho'});
      nowMs = 2000;
      server.notify('u_ana', 'safety_link_updated', data: {'sessionId': 'ss_1', 'shareUrl': 'http://x/s/novo'});
      final inbox = InboxController(api(), now: () => nowMs);
      await inbox.refresh();
      expect(inbox.state.shareUrlFor(inbox.state.items.last), 'http://x/s/novo');
    });

    test('reset descarta a busca em voo e zera o since', () async {
      server.notify('u_ana', 'contact_invite');
      final gate = server.gates['/notifications'] = Completer<void>();
      final inbox = InboxController(api(), now: () => nowMs);
      final f = inbox.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      inbox.reset();
      server.gates.clear();
      gate.complete();
      await f;
      expect(inbox.state.items, isEmpty);
      await inbox.refresh();
      expect(server.requests.last.query['since'], '0');
      expect(inbox.state.items, hasLength(1));
    });
  });
}
