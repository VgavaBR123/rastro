// Cliente HTTP do Rastro Seguro contra o servidor falso que segue o contrato:
// formato das requisicoes, token Bearer, mensagens para 404/409/400 do
// convite, 404 da sessao ativa (sem sessao) e falha de rede.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/safety/safety_api.dart';
import 'package:strava_estudo_app/safety/safety_models.dart';

import 'fake_safety_server.dart';

void main() {
  late FakeSafetyServer server;
  late SafetyApi api;
  late FakeUser ana;
  late FakeUser bia;
  String? token = 'tok-ana';
  var nowMs = 10 * 60000;

  setUp(() {
    nowMs = 10 * 60000;
    token = 'tok-ana';
    server = FakeSafetyServer(now: () => nowMs);
    ana = server.addUser('tok-ana', 'u_ana', 'ana@x.com', 'Ana');
    bia = server.addUser('tok-bia', 'u_bia', 'bia@x.com', 'Bia');
    api = SafetyApi(Dio()..httpClientAdapter = server, 'http://srv', token: () async => token);
  });

  group('contatos', () {
    test('convite manda o email com Bearer e volta pendente', () async {
      final c = await api.invite(' Bia@x.com ');
      expect(c.status, ContactStatus.pending);
      expect(c.displayName, 'Bia');
      final r = server.requestsTo('POST', '/safety/contacts').single;
      expect(r.body, {'email': 'bia@x.com'});
      expect(r.token, 'tok-ana');
    });

    test('email sem conta, repetido, proprio email e limite viram mensagens claras', () async {
      await expectLater(
        api.invite('ninguem@x.com'),
        throwsA(
          isA<SafetyException>()
              .having((e) => e.kind, 'kind', SafetyErrorKind.notFound)
              .having((e) => e.message, 'msg', contains('nao tem conta no Rastro')),
        ),
      );
      await api.invite('bia@x.com');
      await expectLater(
        api.invite('bia@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.message, 'msg', contains('ja foi convidada'))),
      );
      await expectLater(
        api.invite('ana@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.message, 'msg', contains('proprio email'))),
      );
      for (var i = 0; i < 3; i++) {
        server.linkAccepted(ana, server.addUser('t$i', 'u$i', 'c$i@x.com', 'C$i'));
      }
      server.addUser('t9', 'u9', 'd@x.com', 'D');
      await expectLater(
        api.invite('d@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.message, 'msg', contains('3 contatos'))),
      );
    });

    test('409 do convite pelo texto exato do backend; 429 e 500', () async {
      server.overrides['POST /safety/contacts'] = (409, {'error': 'ja existe 3 algo novo'});
      await expectLater(
        api.invite('bia@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.message, 'msg', contains('ja foi convidada, ou voce ja tem 3'))),
      );
      server.overrides['POST /safety/contacts'] = (409, {'error': 'limite de 3 contatos aceitos'});
      await expectLater(
        api.invite('bia@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.message, 'msg', startsWith('Voce ja tem 3 contatos aceitos'))),
      );
      server.overrides['POST /safety/contacts'] = (409, {'error': 'convite ja existe'});
      await expectLater(
        api.invite('bia@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.message, 'msg', startsWith('Essa pessoa ja foi convidada ('))),
      );
      server.overrides['POST /safety/contacts'] = (429, {'error': 'muitas tentativas'});
      await expectLater(
        api.invite('bia@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.message, 'msg', contains('Muitos convites'))),
      );
      server.overrides['POST /safety/contacts'] = (500, {'error': 'erro interno'});
      await expectLater(
        api.invite('bia@x.com'),
        throwsA(isA<SafetyException>().having((e) => e.kind, 'kind', SafetyErrorKind.server)),
      );
    });

    test('lista enviados e recebidos, aceita e remove', () async {
      final sent = await api.invite('bia@x.com');
      token = 'tok-bia';
      final lists = await api.contacts();
      expect(lists.incoming.single.id, sent.id);
      expect(lists.incoming.single.displayName, 'Ana');
      expect(lists.outgoing, isEmpty);
      final accepted = await api.accept(sent.id);
      expect(accepted.accepted, isTrue);
      token = 'tok-ana';
      expect((await api.contacts()).accepted.single.id, sent.id);
      await api.remove(sent.id);
      expect((await api.contacts()).outgoing, isEmpty);
      expect(server.requestsTo('DELETE', '/safety/contacts/${sent.id}'), hasLength(1));
    });
  });

  group('sessao', () {
    late String contactId;
    setUp(() => contactId = server.linkAccepted(ana, bia));

    test('cria com guid, eta e contatos; posicao, ok, extend, arrived e sos', () async {
      final s = await api.createSession(activityGuid: 'act_1', etaMs: nowMs + 30 * 60000, contactIds: [contactId]);
      expect(s.status, SafetyStatus.active);
      expect(s.shareUrl, isNotNull);
      expect(server.requestsTo('POST', '/safety/sessions').single.body, {
        'activityGuid': 'act_1',
        'etaMs': nowMs + 30 * 60000,
        'contactIds': [contactId],
      });

      await api.postPosition(
        s.id,
        const PositionReport(lat: -23.5, lon: -46.6, accuracyM: 5, recordedAtMs: 123, moving: true, paused: false),
      );
      expect(server.requestsTo('POST', '/positions').last.body, {
        'lat': -23.5,
        'lon': -46.6,
        'accuracyM': 5.0,
        'recordedAtMs': 123,
        'moving': true,
        'paused': false,
      });
      await api.postPosition(s.id, const PositionReport.heartbeat(moving: false, paused: true, recordedAtMs: 200));
      expect(server.requestsTo('POST', '/positions').last.body, {
        'lat': null,
        'lon': null,
        'accuracyM': null,
        'recordedAtMs': 200,
        'moving': false,
        'paused': true,
      });

      server.startCheck(s.id, reason: 'stopped', deadlineMs: nowMs + 60000);
      final checking = await api.session(s.id);
      expect(checking.status, SafetyStatus.checking);
      expect(checking.check!.reason, CheckReason.stopped);
      expect(checking.check!.deadlineMs, nowMs + 60000);
      expect((await api.ok(s.id)).check, isNull);

      final ext = await api.extend(s.id, 15);
      expect(ext.etaMs, nowMs + 45 * 60000);
      expect(server.requestsTo('POST', '/extend').single.body, {'minutes': 15});

      await api.sos(s.id);
      final ended = await api.arrived(s.id);
      expect(ended.ended, isTrue);
    });

    test('sessao ativa: 404 vira null; existente volta', () async {
      expect(await api.activeSession(), isNull);
      final s = await api.createSession(activityGuid: 'act_1', etaMs: nowMs + 3600000, contactIds: [contactId]);
      expect((await api.activeSession())!.id, s.id);
    });

    test('409 de sessao ativa e 400 de horario viram tipos proprios', () async {
      await expectLater(
        api.createSession(activityGuid: 'a', etaMs: nowMs + 60000, contactIds: [contactId]),
        throwsA(isA<SafetyException>().having((e) => e.kind, 'kind', SafetyErrorKind.badRequest)),
      );
      await api.createSession(activityGuid: 'a', etaMs: nowMs + 3600000, contactIds: [contactId]);
      await expectLater(
        api.createSession(activityGuid: 'b', etaMs: nowMs + 3600000, contactIds: [contactId]),
        throwsA(isA<SafetyException>().having((e) => e.kind, 'kind', SafetyErrorKind.conflict)),
      );
    });
  });

  group('notificacoes e erros', () {
    test('since vai na query; marcar como lida', () async {
      server.notify('u_ana', 'contact_accepted');
      final list = await api.notifications(since: 0);
      expect(list.single.kind, NotificationKind.contactAccepted);
      expect(server.requests.last.query['since'], '0');
      await api.markRead(list.single.id);
      expect(server.notifications.single['readAt'], isNotNull);
      expect(await api.notifications(since: nowMs), isEmpty);
    });

    test('sem rede: erro de rede; sem login: nao autenticado sem chamar', () async {
      server.offline = true;
      await expectLater(
        api.contacts(),
        throwsA(isA<SafetyException>().having((e) => e.kind, 'kind', SafetyErrorKind.network)),
      );
      server.offline = false;
      token = null;
      final before = server.requests.length;
      await expectLater(
        api.contacts(),
        throwsA(isA<SafetyException>().having((e) => e.kind, 'kind', SafetyErrorKind.unauthorized)),
      );
      expect(server.requests.length, before);
    });

    test('push: registra e apaga o token', () async {
      await api.registerPushToken('fcm-1', 'android');
      expect(server.requestsTo('POST', '/push/tokens').single.body, {'token': 'fcm-1', 'platform': 'android'});
      await api.deletePushToken('fcm-1');
      expect(server.requestsTo('DELETE', '/push/tokens/fcm-1'), hasLength(1));
    });
  });
}
