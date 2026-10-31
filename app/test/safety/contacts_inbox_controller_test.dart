// Controladores dos contatos e da caixa de entrada contra o servidor falso:
// convidar, aceitar e remover com recarga da lista e mensagens de erro;
// caixa com since incremental, nao lidas, marcar como lida e aviso de nova.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/safety/contacts_controller.dart';
import 'package:strava_estudo_app/safety/inbox_controller.dart';
import 'package:strava_estudo_app/safety/safety_api.dart';
import 'package:strava_estudo_app/safety/safety_models.dart';

import 'fake_safety_server.dart';

void main() {
  late FakeSafetyServer server;
  var nowMs = 1000;
  String token = 'tok-ana';

  SafetyApi api() => SafetyApi(Dio()..httpClientAdapter = server, 'http://srv', token: () async => token);

  setUp(() {
    nowMs = 1000;
    token = 'tok-ana';
    server = FakeSafetyServer(now: () => nowMs);
    server.addUser('tok-ana', 'u_ana', 'ana@x.com', 'Ana');
    server.addUser('tok-bia', 'u_bia', 'bia@x.com', 'Bia');
  });

  group('contatos', () {
    test('convite recarrega a lista; erros voltam como mensagem', () async {
      final c = ContactsController(api());
      await c.load();
      expect(c.state.lists!.outgoing, isEmpty);
      expect(await c.invite('bia@x.com'), isNull);
      expect(c.state.lists!.outgoing.single.status, ContactStatus.pending);
      expect(await c.invite('bia@x.com'), contains('ja foi convidada'));
      expect(await c.invite('zz@x.com'), contains('nao tem conta'));
      expect(await c.invite('sem-arroba'), contains('email valido'));
      expect(c.state.busy, isFalse);
    });

    test('quem recebeu aceita; qualquer lado remove', () async {
      await ContactsController(api()).invite('bia@x.com');
      token = 'tok-bia';
      final c = ContactsController(api());
      await c.load();
      final id = c.state.lists!.incoming.single.id;
      expect(await c.accept(id), isNull);
      expect(c.state.lists!.incoming.single.accepted, isTrue);
      // Contato por sentido: quem aceitou nao ganha a Ana como contato dela.
      expect(c.state.accepted, isEmpty);
      expect(await c.remove(id), isNull);
      expect(c.state.lists!.incoming, isEmpty);
    });

    test('sem login e sem rede: erro de carregar', () async {
      server.tokens.remove('tok-ana');
      final c = ContactsController(api());
      await c.load();
      expect(c.state.signedOut, isTrue);
      server.offline = true;
      await c.load();
      expect(c.state.error, contains('Sem conexao'));
      expect(c.state.signedOut, isFalse);
    });
  });

  group('caixa de entrada', () {
    test('since incremental, sem duplicar, nova avisada uma vez', () async {
      final seen = <String>[];
      final inbox = InboxController(api(), now: () => nowMs, onNew: (n) => seen.add(n.id));
      server.notify('u_ana', 'contact_accepted');
      await inbox.refresh();
      expect(inbox.state.items, hasLength(1));
      expect(inbox.state.unread, 1);
      expect(server.requests.last.query['since'], '0');
      nowMs = 2000;
      server.notify('u_ana', 'safety_check', data: {'sessionId': 'ss_1'});
      await inbox.refresh();
      expect(server.requests.last.query['since'], '999');
      expect(inbox.state.items.first.kind, NotificationKind.safetyCheck);
      expect(inbox.state.items, hasLength(2));
      expect(seen, hasLength(2));
      await inbox.refresh();
      expect(seen, hasLength(2));
    });

    test('marcar como lida zera o contador e avisa o servidor', () async {
      final inbox = InboxController(api(), now: () => nowMs);
      server.notify('u_ana', 'safety_alert', data: {'shareUrl': 'http://x/s/1', 'ownerName': 'Bia', 'reason': 'eta'});
      await inbox.refresh();
      final n = inbox.state.items.single;
      expect(n.isAlert, isTrue);
      expect(n.ownerName, 'Bia');
      expect(n.reason, CheckReason.eta);
      await inbox.markRead(n.id);
      expect(inbox.state.unread, 0);
      expect(server.notifications.single['readAt'], isNotNull);
    });

    test('sem rede mantem a lista; reset esquece', () async {
      final inbox = InboxController(api(), now: () => nowMs);
      server.notify('u_ana', 'contact_invite');
      await inbox.refresh();
      server.offline = true;
      await inbox.refresh();
      expect(inbox.state.items, hasLength(1));
      expect(inbox.state.error, isNotNull);
      inbox.reset();
      expect(inbox.state.items, isEmpty);
    });
  });
}
