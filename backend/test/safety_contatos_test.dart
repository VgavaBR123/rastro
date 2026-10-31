// Contrato do Rastro Seguro (docs/CONTRATO-RASTRO-SEGURO.md): contatos de
// confianca, caixa de entrada de notificacoes e tokens de push.
import 'package:test/test.dart';

import 'safety_harness.dart';

void main() {
  late Harness h;
  late Conta ana, bia, caio;

  setUp(() async {
    h = Harness();
    ana = await h.conta('ana@exemplo.com', nome: 'Ana Souza');
    bia = await h.conta('bia@exemplo.com', nome: 'Bia Lima');
    caio = await h.conta('caio@exemplo.com', nome: 'Caio Reis');
  });

  group('POST /safety/contacts', () {
    test('201 pending e notificacao contact_invite para o convidado',
        () async {
      final c = await h.json('POST', '/safety/contacts',
          body: {'email': ' BIA@exemplo.com '}, token: ana.token, esperado: 201);
      expect(c['id'], startsWith('ct_'));
      expect(c['status'], 'pending');
      expect(c['otherUserId'], bia.id);
      expect(c['displayName'], 'Bia Lima');
      expect(c['email'], 'bia@exemplo.com');
      expect(c['createdAt'], h.agora);
      final caixa = await h.caixa(bia);
      expect(caixa.single['type'], 'contact_invite');
      expect(caixa.single['data']['contactId'], c['id']);
      expect(caixa.single['data']['ownerName'], 'Ana Souza');
      expect(caixa.single['body'], contains('Ana Souza'));
      expect(await h.caixa(ana), isEmpty);
    });

    test('404 sem conta no Rastro', () async {
      final r = await h.chamar('POST', '/safety/contacts',
          body: {'email': 'ninguem@exemplo.com'}, token: ana.token);
      expect(r.statusCode, 404);
      expect(await r.readAsString(), contains('sem conta no Rastro'));
    });

    test('400 proprio email, email invalido ou corpo ruim', () async {
      expect(
          await h.status('POST', '/safety/contacts',
              body: {'email': 'ana@exemplo.com'}, token: ana.token),
          400);
      expect(
          await h.status('POST', '/safety/contacts',
              body: {'email': 'nao-e-email'}, token: ana.token),
          400);
      expect(
          await h.status('POST', '/safety/contacts',
              body: {'x': 1}, token: ana.token),
          400);
    });

    test('409 convite repetido (pendente ou aceito)', () async {
      await h.json('POST', '/safety/contacts',
          body: {'email': bia.email}, token: ana.token, esperado: 201);
      expect(
          await h.status('POST', '/safety/contacts',
              body: {'email': bia.email}, token: ana.token),
          409);
    });

    test('convite no sentido contrario e outra relacao (201)', () async {
      await h.contatoAceito(ana, bia);
      await h.json('POST', '/safety/contacts',
          body: {'email': ana.email}, token: bia.token, esperado: 201);
    });

    test('409 com 3 aceitos (no convite e no aceite)', () async {
      final outras = [
        for (var i = 0; i < 4; i++) await h.conta('x$i@exemplo.com')
      ];
      // Convida a quarta antes de completar 3 aceitos: o aceite dela e que
      // estoura o limite.
      final c4 = await h.json('POST', '/safety/contacts',
          body: {'email': outras[3].email}, token: ana.token, esperado: 201);
      for (var i = 0; i < 3; i++) {
        await h.contatoAceito(ana, outras[i]);
      }
      expect(
          await h.status('POST', '/safety/contacts',
              body: {'email': bia.email}, token: ana.token),
          409);
      expect(
          await h.status('POST', '/safety/contacts/${c4['id']}/accept',
              token: outras[3].token),
          409);
    });

    test('401 sem token', () async {
      expect(
          await h.status('POST', '/safety/contacts', body: {'email': bia.email}),
          401);
    });

    test('429 depois de muitos convites por hora', () async {
      var ultimo = 0;
      for (var i = 0; i < 25; i++) {
        ultimo = await h.status('POST', '/safety/contacts',
            body: {'email': 'n$i@exemplo.com'}, token: ana.token);
      }
      expect(ultimo, 429);
    });
  });

  group('GET /safety/contacts', () {
    test('outgoing e incoming, cada um com o outro lado', () async {
      final idAB = await h.contatoAceito(ana, bia);
      await h.json('POST', '/safety/contacts',
          body: {'email': ana.email}, token: caio.token, esperado: 201);
      final m = await h.json('GET', '/safety/contacts', token: ana.token);
      final out = m['outgoing'] as List;
      final inc = m['incoming'] as List;
      expect(out.single['id'], idAB);
      expect(out.single['otherUserId'], bia.id);
      expect(out.single['status'], 'accepted');
      expect(inc.single['otherUserId'], caio.id);
      expect(inc.single['displayName'], 'Caio Reis');
      expect(inc.single['status'], 'pending');
      final mb = await h.json('GET', '/safety/contacts', token: bia.token);
      expect((mb['incoming'] as List).single['otherUserId'], ana.id);
      expect(mb['outgoing'], isEmpty);
    });

    test('A nao ve contatos de B', () async {
      await h.contatoAceito(bia, caio);
      final m = await h.json('GET', '/safety/contacts', token: ana.token);
      expect(m['outgoing'], isEmpty);
      expect(m['incoming'], isEmpty);
    });
  });

  group('POST /safety/contacts/<id>/accept', () {
    test('200 accepted e contact_accepted para a dona', () async {
      final c = await h.json('POST', '/safety/contacts',
          body: {'email': bia.email}, token: ana.token, esperado: 201);
      final a = await h.json('POST', '/safety/contacts/${c['id']}/accept',
          token: bia.token);
      expect(a['status'], 'accepted');
      expect(a['otherUserId'], ana.id);
      final caixa = await h.caixa(ana);
      expect(caixa.single['type'], 'contact_accepted');
      expect(caixa.single['body'], contains('Bia Lima'));
      // Repetir e idempotente e nao notifica de novo.
      await h.json('POST', '/safety/contacts/${c['id']}/accept',
          token: bia.token);
      expect((await h.caixa(ana)).length, 1);
    });

    test('404 para a dona, para terceiros e para id inexistente', () async {
      final c = await h.json('POST', '/safety/contacts',
          body: {'email': bia.email}, token: ana.token, esperado: 201);
      expect(
          await h.status('POST', '/safety/contacts/${c['id']}/accept',
              token: ana.token),
          404);
      expect(
          await h.status('POST', '/safety/contacts/${c['id']}/accept',
              token: caio.token),
          404);
      expect(
          await h.status('POST', '/safety/contacts/ct_nada/accept',
              token: bia.token),
          404);
    });
  });

  group('DELETE /safety/contacts/<id>', () {
    test('204 por qualquer um dos lados', () async {
      final id1 = await h.contatoAceito(ana, bia);
      expect(await h.status('DELETE', '/safety/contacts/$id1', token: bia.token),
          204);
      final id2 = await h.contatoAceito(ana, bia);
      expect(await h.status('DELETE', '/safety/contacts/$id2', token: ana.token),
          204);
      final m = await h.json('GET', '/safety/contacts', token: ana.token);
      expect(m['outgoing'], isEmpty);
    });

    test('404 para terceiros (e o contato continua)', () async {
      final id = await h.contatoAceito(ana, bia);
      expect(
          await h.status('DELETE', '/safety/contacts/$id', token: caio.token),
          404);
      final m = await h.json('GET', '/safety/contacts', token: ana.token);
      expect((m['outgoing'] as List).length, 1);
    });
  });

  group('notificacoes', () {
    test('mais novas primeiro, since, limite de 50', () async {
      for (var i = 0; i < 55; i++) {
        h.agora += 1000;
        final outra = await h.conta('n$i@exemplo.com', nome: 'N$i');
        await h.json('POST', '/safety/contacts',
            body: {'email': ana.email}, token: outra.token, esperado: 201);
      }
      final todas = await h.caixa(ana);
      expect(todas.length, 50);
      expect(todas.first['body'], contains('N54'));
      final criadas = [for (final n in todas) n['createdAt'] as int];
      expect(criadas, [...criadas]..sort((a, b) => b.compareTo(a)));
      final desde = todas[2]['createdAt'] as int;
      final m = await h.json('GET', '/notifications?since=$desde',
          token: ana.token);
      expect((m['notifications'] as List).length, 2);
      final n = todas.first;
      expect(n.keys, containsAll(
          ['id', 'type', 'title', 'body', 'data', 'createdAt', 'readAt']));
      expect(n['readAt'], isNull);
    });

    test('400 since invalido', () async {
      expect(await h.status('GET', '/notifications?since=abc', token: ana.token),
          400);
    });

    test('read: 204 para o destinatario, 404 para outro', () async {
      await h.json('POST', '/safety/contacts',
          body: {'email': bia.email}, token: ana.token, esperado: 201);
      final id = (await h.caixa(bia)).single['id'];
      expect(await h.status('POST', '/notifications/$id/read', token: ana.token),
          404);
      expect(await h.status('POST', '/notifications/$id/read', token: bia.token),
          204);
      expect((await h.caixa(bia)).single['readAt'], h.agora);
      expect(await h.caixa(ana), isEmpty);
    });

    test('401 sem token', () async {
      expect(await h.status('GET', '/notifications'), 401);
    });
  });

  group('tokens de push', () {
    test('204 idempotente, notificacao vai para o aparelho', () async {
      for (var i = 0; i < 2; i++) {
        expect(
            await h.status('POST', '/push/tokens',
                body: {'token': 'tok-bia', 'platform': 'android'},
                token: bia.token),
            204);
      }
      await h.json('POST', '/safety/contacts',
          body: {'email': bia.email}, token: ana.token, esperado: 201);
      // O push sai depois do commit, sem a rota esperar.
      await h.service.aguardarPush();
      final m = h.push.enviadas.single;
      expect(m.token, 'tok-bia');
      expect(m.type, 'contact_invite');
      expect(m.notificationId, (await h.caixa(bia)).single['id']);
    });

    test('400 plataforma ou token invalidos', () async {
      expect(
          await h.status('POST', '/push/tokens',
              body: {'token': 'x', 'platform': 'windows'}, token: bia.token),
          400);
      expect(
          await h.status('POST', '/push/tokens',
              body: {'token': '', 'platform': 'ios'}, token: bia.token),
          400);
    });

    test('token invalido segundo o provedor e removido', () async {
      await h.status('POST', '/push/tokens',
          body: {'token': 'tok-velho', 'platform': 'android'}, token: bia.token);
      h.push.invalidos.add('tok-velho');
      await h.json('POST', '/safety/contacts',
          body: {'email': bia.email}, token: ana.token, esperado: 201);
      await h.service.aguardarPush();
      expect(h.safety.hasPushToken('tok-velho'), isFalse);
      // A caixa de entrada recebeu mesmo assim.
      expect((await h.caixa(bia)).length, 1);
    });

    test('DELETE: 204; token de outra conta nao e apagado', () async {
      await h.status('POST', '/push/tokens',
          body: {'token': 'tok:bia_1', 'platform': 'ios'}, token: bia.token);
      expect(await h.status('DELETE', '/push/tokens/tok%3Abia_1',
          token: ana.token), 204);
      expect(h.safety.hasPushToken('tok:bia_1'), isTrue);
      expect(await h.status('DELETE', '/push/tokens/tok%3Abia_1',
          token: bia.token), 204);
      expect(h.safety.hasPushToken('tok:bia_1'), isFalse);
    });
  });

  test('DELETE /me apaga contatos, caixa e tokens da conta', () async {
    await h.contatoAceito(ana, bia);
    await h.status('POST', '/push/tokens',
        body: {'token': 'tok-ana', 'platform': 'android'}, token: ana.token);
    expect(
        await h.status('DELETE', '/me',
            body: {'password': 'senha-boa-123'}, token: ana.token),
        204);
    final m = await h.json('GET', '/safety/contacts', token: bia.token);
    expect(m['incoming'], isEmpty);
    expect(h.safety.hasPushToken('tok-ana'), isFalse);
  });
}
