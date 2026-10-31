// Mesmo conjunto de testes para os dois SafetyStore. O Postgres so roda com
// PG_TEST_PORT definido (ex.: PG_TEST_PORT=5433 dart test
// test/safety_store_test.dart), contra o banco do docker compose; cada teste
// usa usuarios com prefixo aleatorio e apaga o que criou.
import 'dart:io';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:strava_estudo_backend/src/postgres_store.dart';
import 'package:strava_estudo_backend/src/safety/postgres_safety_store.dart';
import 'package:strava_estudo_backend/src/safety/safety_store.dart';
import 'package:test/test.dart';

SafetySessionRecord _sessao(String id, String owner, {String? token}) =>
    SafetySessionRecord(
      id: id,
      ownerId: owner,
      activityGuid: 'act_1',
      status: 'active',
      etaMs: 5000,
      startedAtMs: 1000,
      lastSignalAtMs: 1000,
      contactIds: ['ct_1'],
      shareToken: token ?? 'tok_$id',
    );

void suite(String nome, Future<SafetyStore> Function() criar,
    {required List<String> Function() usuarios,
    Future<void> Function()? limpar}) {
  group(nome, () {
    late SafetyStore s;
    late String a, b, c;

    setUp(() async {
      s = await criar();
      final u = usuarios();
      a = u[0];
      b = u[1];
      c = u[2];
    });
    if (limpar != null) tearDown(limpar);

    test('contato: cria, recusa repetido, lista dos dois lados, aceita',
        () async {
      final ct = ContactRecord(
          id: '${a}_ct1',
          ownerId: a,
          contactUserId: b,
          status: 'pending',
          createdAtMs: 10);
      expect(await s.createContact(ct), isNotNull);
      expect(
          await s.createContact(ContactRecord(
              id: '${a}_ct2',
              ownerId: a,
              contactUserId: b,
              status: 'pending',
              createdAtMs: 11)),
          isNull);
      expect((await s.contactsOfUser(a)).map((x) => x.id), ['${a}_ct1']);
      expect((await s.contactsOfUser(b)).map((x) => x.id), ['${a}_ct1']);
      expect(await s.contactsOfUser(c), isEmpty);
      expect(await s.countAcceptedContacts(a), 0);
      ct
        ..status = 'accepted'
        ..acceptedAtMs = 20;
      await s.saveContact(ct);
      final lido = await s.findContact(ct.id);
      expect(lido!.status, 'accepted');
      expect(lido.acceptedAtMs, 20);
      expect(await s.countAcceptedContacts(a), 1);
      await s.deleteContact(ct.id);
      expect(await s.findContact(ct.id), isNull);
    });

    test('sessao: uma aberta por dona, salva todos os campos, limpeza',
        () async {
      final ss = _sessao('${a}_ss1', a);
      expect(await s.createSession(ss), isNotNull);
      expect(await s.createSession(_sessao('${a}_ss2', a)), isNull);
      ss
        ..status = 'checking'
        ..lastPosition = const SafetyPosition(
            lat: -23.5, lon: -46.6, accuracyM: 4.5, recordedAtMs: 1500)
        ..stillSinceMs = 1200
        ..checkReason = 'stopped'
        ..checkStartedAtMs = 1600
        ..checkDeadlineMs = 1700
        ..etaRecheckAfterMs = 99
        ..contactIds = ['ct_1', 'ct_2'];
      await s.saveSession(ss);
      final lido = (await s.findSession(ss.id))!;
      expect(lido.status, 'checking');
      expect(lido.lastPosition!.lat, -23.5);
      expect(lido.lastPosition!.accuracyM, 4.5);
      expect(lido.lastPosition!.recordedAtMs, 1500);
      expect(lido.stillSinceMs, 1200);
      expect(lido.checkReason, 'stopped');
      expect(lido.checkDeadlineMs, 1700);
      expect(lido.etaRecheckAfterMs, 99);
      expect(lido.contactIds, ['ct_1', 'ct_2']);
      expect((await s.findOpenSessionOfOwner(a))!.id, ss.id);
      expect((await s.findSessionByShareToken(ss.shareToken))!.id, ss.id);
      expect((await s.openSessions()).map((x) => x.id), contains(ss.id));

      ss
        ..status = 'ended'
        ..endedAtMs = 2000
        ..endReason = 'arrived'
        ..lastPosition = null;
      await s.saveSession(ss);
      expect(await s.findOpenSessionOfOwner(a), isNull);
      expect((await s.findSession(ss.id))!.lastPosition, isNull);
      // Encerrada libera nova sessao.
      expect(await s.createSession(_sessao('${a}_ss3', a)), isNotNull);
      expect(await s.deleteSessionsEndedBefore(2000), 0);
      expect(await s.deleteSessionsEndedBefore(2001), 1);
      expect(await s.findSession(ss.id), isNull);
    });

    test('notificacoes: so do dono, since, ordem, limite e lida', () async {
      for (var i = 1; i <= 3; i++) {
        await s.addNotification(NotificationRecord(
            id: '${a}_nt$i',
            userId: a,
            type: 'safety_check',
            title: 't$i',
            body: 'b',
            data: {'sessionId': 'ss', 'n': i},
            createdAtMs: i * 10));
      }
      final todas = await s.notificationsOf(a, limit: 50);
      expect(todas.map((n) => n.title), ['t3', 't2', 't1']);
      expect(todas.first.data['n'], 3);
      expect((await s.notificationsOf(a, sinceMs: 10, limit: 50)).length, 2);
      expect((await s.notificationsOf(a, limit: 1)).single.title, 't3');
      expect(await s.notificationsOf(b, limit: 50), isEmpty);
      expect(
          await s.markNotificationRead('${a}_nt1', userId: b, nowMs: 5), false);
      expect(
          await s.markNotificationRead('${a}_nt1', userId: a, nowMs: 5), true);
      final lida =
          (await s.notificationsOf(a, limit: 50)).firstWhere((n) => n.title == 't1');
      expect(lida.readAtMs, 5);
    });

    test('tokens: upsert reatribui, delete so do dono', () async {
      final tk = '${a}_tok';
      await s.upsertPushToken(PushTokenRecord(
          token: tk, userId: a, platform: 'android', updatedAtMs: 1));
      await s.upsertPushToken(PushTokenRecord(
          token: tk, userId: a, platform: 'android', updatedAtMs: 2));
      expect((await s.pushTokensOf(a)).length, 1);
      await s.deletePushToken(tk, userId: b);
      expect((await s.pushTokensOf(a)).length, 1);
      await s.upsertPushToken(PushTokenRecord(
          token: tk, userId: b, platform: 'ios', updatedAtMs: 3));
      expect(await s.pushTokensOf(a), isEmpty);
      expect((await s.pushTokensOf(b)).single.platform, 'ios');
      await s.deletePushTokenAnyOwner(tk);
      expect(await s.pushTokensOf(b), isEmpty);
    });

    test('transacao: falha desfaz tudo; sucesso grava', () async {
      final ss = _sessao('${a}_sstx', a);
      await s.createSession(ss);
      await expectLater(
          s.transaction((tx) async {
            ss.status = 'alerted';
            await tx.saveSession(ss);
            await tx.addNotification(NotificationRecord(
                id: '${a}_nttx',
                userId: b,
                type: 'safety_alert',
                title: 't',
                body: 'b',
                data: {},
                createdAtMs: 1));
            throw StateError('falha no meio');
          }),
          throwsStateError);
      expect((await s.findSession(ss.id))!.status, 'active');
      expect(await s.findNotification('${a}_nttx'), isNull);
      await s.transaction((tx) async {
        ss.status = 'alerted';
        await tx.saveSession(ss);
      });
      expect((await s.findSession(ss.id))!.status, 'alerted');
    });

    test('outbox: vencidos em ordem, salva tentativas, apaga', () async {
      await s.addNotification(NotificationRecord(
          id: '${a}_ntob',
          userId: a,
          type: 't',
          title: 't',
          body: 'b',
          data: {'k': 'v'},
          createdAtMs: 1));
      expect((await s.findNotification('${a}_ntob'))!.data, {'k': 'v'});
      for (var i = 1; i <= 2; i++) {
        await s.addPushOutbox(PushOutboxRecord(
            id: '${a}_po$i',
            notificationId: '${a}_ntob',
            userId: a,
            token: 'tk$i',
            createdAtMs: i,
            nextAttemptAtMs: i * 100));
      }
      List<String> ids(List<PushOutboxRecord> l) =>
          [for (final o in l) if (o.id.startsWith(a)) o.id];
      expect(ids(await s.duePushOutbox(150)), ['${a}_po1']);
      expect(ids(await s.duePushOutbox(200)), ['${a}_po1', '${a}_po2']);
      final o = (await s.duePushOutbox(150)).firstWhere((x) => x.id == '${a}_po1');
      o
        ..attempts = 3
        ..nextAttemptAtMs = 1000;
      await s.savePushOutbox(o);
      expect(ids(await s.duePushOutbox(500)), ['${a}_po2']);
      await s.deletePushOutbox('${a}_po2');
      final l = await s.duePushOutbox(1000);
      expect(ids(l), ['${a}_po1']);
      expect(l.firstWhere((x) => x.id == '${a}_po1').attempts, 3);
    });

    test('deleteAllForUser apaga contatos dos dois lados e o resto', () async {
      await s.createContact(ContactRecord(
          id: '${a}_x1',
          ownerId: a,
          contactUserId: b,
          status: 'pending',
          createdAtMs: 1));
      await s.createContact(ContactRecord(
          id: '${c}_x2',
          ownerId: c,
          contactUserId: a,
          status: 'pending',
          createdAtMs: 1));
      await s.createSession(_sessao('${a}_ssx', a));
      await s.addNotification(NotificationRecord(
          id: '${a}_ntx',
          userId: a,
          type: 't',
          title: 't',
          body: 'b',
          data: {},
          createdAtMs: 1));
      await s.deleteAllForUser(a);
      expect(await s.contactsOfUser(b), isEmpty);
      expect(await s.contactsOfUser(c), isEmpty);
      expect(await s.findSession('${a}_ssx'), isNull);
      expect(await s.notificationsOf(a, limit: 50), isEmpty);
    });
  });
}

void main() {
  suite('InMemorySafetyStore', () async => InMemorySafetyStore(),
      usuarios: () => ['ua', 'ub', 'uc']);

  final String? porta = Platform.environment['PG_TEST_PORT'];
  if (porta == null) return;
  late PostgresActivityStore pg;
  late List<String> ids;
  final rnd = Random();
  suite(
    'PostgresSafetyStore',
    () async {
      pg = await PostgresActivityStore.connect(
          host: 'localhost',
          port: int.parse(porta),
          database: 'atividades',
          username: 'postgres',
          password: 'postgres');
      final p = 'tst${rnd.nextInt(1 << 30)}';
      ids = ['${p}a', '${p}b', '${p}c'];
      for (final id in ids) {
        await pg.connection.execute(
            Sql.named('INSERT INTO users (id, email, password_hash, '
                'display_name, created_at) VALUES (@id, @e, @h, @n, 0)'),
            parameters: {'id': id, 'e': '$id@teste.local', 'h': 'x', 'n': id});
      }
      return PostgresSafetyStore(pg.connection);
    },
    usuarios: () => ids,
    limpar: () async {
      for (final id in ids) {
        await pg.connection.execute(Sql.named('DELETE FROM users WHERE id = @id'),
            parameters: {'id': id});
      }
      await pg.close();
    },
  );
}
