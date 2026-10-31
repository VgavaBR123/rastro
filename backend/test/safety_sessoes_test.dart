// Contrato das rotas de sessao do Rastro Seguro (sem o vigia; ver
// safety_vigia_test.dart).
import 'package:test/test.dart';

import 'safety_harness.dart';

void main() {
  late Harness h;
  late Conta ana, bia, caio;
  late String ctBia;

  setUp(() async {
    h = Harness();
    ana = await h.conta('ana@exemplo.com', nome: 'Ana Souza');
    bia = await h.conta('bia@exemplo.com', nome: 'Bia Lima');
    caio = await h.conta('caio@exemplo.com', nome: 'Caio Reis');
    ctBia = await h.contatoAceito(ana, bia);
  });

  Future<int> criar(Map<String, dynamic> body, {Conta? quem}) =>
      h.status('POST', '/safety/sessions', body: body, token: (quem ?? ana).token);

  group('POST /safety/sessions', () {
    test('201 com o formato do contrato', () async {
      final s = await h.criarSessao(ana, [ctBia], etaMs: h.agora + hora);
      expect(s['id'], startsWith('ss_'));
      expect(s['activityGuid'], 'act_1');
      expect(s['status'], 'active');
      expect(s['etaMs'], h.agora + hora);
      expect(s['startedAt'], h.agora);
      expect(s['endedAt'], isNull);
      expect(s['lastSignalAt'], h.agora);
      expect(s['lastPosition'], isNull);
      expect(s['contactIds'], [ctBia]);
      expect(s['check'], isNull);
      expect(s['alertedAt'], isNull);
      expect(s['shareUrl'], matches(RegExp(r'^https://rastro\.exemplo/s/.{43}$')));
    });

    test('400 eta fora de agora+5 min .. agora+12 h', () async {
      for (final eta in [
        h.agora + 5 * minuto - 1,
        h.agora + 12 * hora + 1,
        'amanha',
        null
      ]) {
        expect(
            await criar({
              'activityGuid': 'act_1',
              'etaMs': eta,
              'contactIds': [ctBia]
            }),
            400,
            reason: '$eta');
      }
      expect(
          await criar({
            'activityGuid': 'act_1',
            'etaMs': h.agora + 5 * minuto,
            'contactIds': [ctBia]
          }),
          201);
    });

    test('400 contactIds vazio, alheio, pendente ou de outra dona', () async {
      final pendente = await h.json('POST', '/safety/contacts',
          body: {'email': caio.email}, token: ana.token, esperado: 201);
      final daBia = await h.contatoAceito(bia, caio);
      for (final ids in [
        <String>[],
        ['ct_nada'],
        [pendente['id']],
        [daBia],
        [ctBia, daBia],
      ]) {
        expect(
            await criar({
              'activityGuid': 'act_1',
              'etaMs': h.agora + hora,
              'contactIds': ids
            }),
            400,
            reason: '$ids');
      }
    });

    test('400 sem activityGuid', () async {
      expect(
          await criar({
            'etaMs': h.agora + hora,
            'contactIds': [ctBia]
          }),
          400);
    });

    test('400 corpo que nao e objeto JSON', () async {
      expect(
          await h.status('POST', '/safety/sessions',
              body: [1, 2], token: ana.token),
          400);
    });

    test('409 com sessao ativa; encerrar libera', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      expect(
          await criar({
            'activityGuid': 'act_2',
            'etaMs': h.agora + hora,
            'contactIds': [ctBia]
          }),
          409);
      await h.json('POST', '/safety/sessions/${s['id']}/arrived',
          token: ana.token);
      await h.criarSessao(ana, [ctBia]);
    });

    test('ids repetidos viram um so', () async {
      final s = await h.criarSessao(ana, [ctBia, ctBia]);
      expect(s['contactIds'], [ctBia]);
    });
  });

  group('GET active e GET <id>', () {
    test('active: 404 sem sessao, 200 com, 404 depois de arrived', () async {
      expect(await h.status('GET', '/safety/sessions/active', token: ana.token),
          404);
      final s = await h.criarSessao(ana, [ctBia]);
      final a = await h.json('GET', '/safety/sessions/active', token: ana.token);
      expect(a['id'], s['id']);
      await h.json('POST', '/safety/sessions/${s['id']}/arrived',
          token: ana.token);
      expect(await h.status('GET', '/safety/sessions/active', token: ana.token),
          404);
      // A sessao encerrada continua legivel pelo id.
      final e = await h.json('GET', '/safety/sessions/${s['id']}',
          token: ana.token);
      expect(e['status'], 'ended');
      expect(e['endedAt'], h.agora);
    });

    test('A nao ve nada da sessao de B (404 em todas as rotas)', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      final id = s['id'];
      // bia e contato da ana, mas nao e dona: tambem nao ve.
      for (final quem in [bia, caio]) {
        expect(await h.status('GET', '/safety/sessions/$id', token: quem.token),
            404);
        expect(
            await h.status('GET', '/safety/sessions/active', token: quem.token),
            404);
        for (final acao in ['ok', 'arrived', 'sos']) {
          expect(
              await h.status('POST', '/safety/sessions/$id/$acao',
                  token: quem.token),
              404,
              reason: acao);
        }
        expect(
            await h.status('POST', '/safety/sessions/$id/extend',
                body: {'minutes': 15}, token: quem.token),
            404);
        expect(
            await h.status('POST', '/safety/sessions/$id/positions',
                body: {'lat': 1, 'lon': 1, 'moving': true, 'paused': false},
                token: quem.token),
            404);
      }
      // Nada mudou na sessao da ana.
      final depois =
          await h.json('GET', '/safety/sessions/$id', token: ana.token);
      expect(depois['status'], 'active');
      expect(depois['lastPosition'], isNull);
      expect(await h.tipos(bia), ['contact_invite']);
    });

    test('401 sem token', () async {
      expect(await h.status('GET', '/safety/sessions/active'), 401);
      expect(await h.status('POST', '/safety/sessions', body: {}), 401);
    });
  });

  group('POST positions', () {
    test('atualiza lastSignalAt e lastPosition', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      h.agora += 30 * seg;
      final r = await h.posicao(ana, s['id'], lat: -23.5, lon: -46.6);
      expect(r['lastSignalAt'], h.agora);
      expect(r['lastPosition'],
          {'lat': -23.5, 'lon': -46.6, 'accuracyM': 5, 'recordedAtMs': h.agora});
    });

    test('lat/lon null = batimento: sinal de vida sem trocar a posicao',
        () async {
      final s = await h.criarSessao(ana, [ctBia]);
      await h.posicao(ana, s['id'], lat: 1, lon: 2);
      final antes = h.agora;
      h.agora += minuto;
      final r = await h.posicao(ana, s['id'], lat: null, lon: null);
      expect(r['lastSignalAt'], h.agora);
      expect(r['lastPosition']['recordedAtMs'], antes);
    });

    test('posicao atrasada (mais antiga) nao troca a mais recente', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      await h.posicao(ana, s['id'], lat: 1, lon: 1);
      h.agora += minuto;
      final r = await h.json('POST', '/safety/sessions/${s['id']}/positions',
          body: {
            'lat': 9,
            'lon': 9,
            'recordedAtMs': h.agora - 2 * minuto,
            'moving': true,
            'paused': false
          },
          token: ana.token);
      expect(r['lastPosition']['lat'], 1);
      expect(r['lastSignalAt'], h.agora);
    });

    test('400 com dados invalidos', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      for (final b in [
        {'lat': 91, 'lon': 0},
        {'lat': 0, 'lon': -181},
        {'lat': 0, 'lon': null},
        {'lat': '1', 'lon': '2'},
        {'lat': 0, 'lon': 0, 'accuracyM': -1},
        {'lat': 0, 'lon': 0, 'moving': 'sim'},
        {'lat': 0, 'lon': 0, 'recordedAtMs': 1.5},
      ]) {
        expect(
            await h.status('POST', '/safety/sessions/${s['id']}/positions',
                body: b, token: ana.token),
            400,
            reason: '$b');
      }
    });

    test('409 em sessao encerrada', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      await h.json('POST', '/safety/sessions/${s['id']}/arrived',
          token: ana.token);
      expect(
          await h.status('POST', '/safety/sessions/${s['id']}/positions',
              body: {'lat': 1, 'lon': 1}, token: ana.token),
          409);
    });
  });

  group('extend, ok, arrived, sos', () {
    test('extend soma minutos; 400 fora de 5..120', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      final r = await h.json('POST', '/safety/sessions/${s['id']}/extend',
          body: {'minutes': 15}, token: ana.token);
      expect(r['etaMs'], (s['etaMs'] as int) + 15 * minuto);
      for (final m in [4, 121, 10.5, 'dez', null]) {
        expect(
            await h.status('POST', '/safety/sessions/${s['id']}/extend',
                body: {'minutes': m}, token: ana.token),
            400,
            reason: '$m');
      }
    });

    test('arrived encerra, e idempotente; ok/extend/sos depois = 409',
        () async {
      final s = await h.criarSessao(ana, [ctBia]);
      final r = await h.json('POST', '/safety/sessions/${s['id']}/arrived',
          token: ana.token);
      expect(r['status'], 'ended');
      expect(r['endedAt'], h.agora);
      final fim = h.agora;
      h.agora += minuto;
      final r2 = await h.json('POST', '/safety/sessions/${s['id']}/arrived',
          token: ana.token);
      expect(r2['endedAt'], fim);
      expect(await h.status('POST', '/safety/sessions/${s['id']}/ok',
          token: ana.token), 409);
      expect(await h.status('POST', '/safety/sessions/${s['id']}/sos',
          token: ana.token), 409);
      expect(
          await h.status('POST', '/safety/sessions/${s['id']}/extend',
              body: {'minutes': 10}, token: ana.token),
          409);
    });

    test('sos: safety_sos imediato para os contatos, com posicao; nao encerra',
        () async {
      final s = await h.criarSessao(ana, [ctBia]);
      await h.posicao(ana, s['id'], lat: -23.5, lon: -46.6);
      final r = await h.json('POST', '/safety/sessions/${s['id']}/sos',
          token: ana.token);
      expect(r['status'], 'active');
      final n = (await h.caixa(bia)).first;
      expect(n['type'], 'safety_sos');
      expect(n['data']['sessionId'], s['id']);
      expect(n['data']['shareUrl'], s['shareUrl']);
      expect(n['data']['ownerName'], 'Ana Souza');
      expect(n['data']['lat'], -23.5);
      expect(n['data']['lon'], -46.6);
      // A dona nao recebe o proprio SOS; terceiros tambem nao.
      expect(await h.tipos(ana), ['contact_accepted']);
      expect(await h.caixa(caio), isEmpty);
    });
  });

  group('contato removido', () {
    test('DELETE do contato tira o id da sessao ativa', () async {
      final ctCaio = await h.contatoAceito(ana, caio);
      final s = await h.criarSessao(ana, [ctBia, ctCaio]);
      expect(await h.status('DELETE', '/safety/contacts/$ctBia', token: bia.token),
          204);
      final r = await h.json('GET', '/safety/sessions/${s['id']}',
          token: ana.token);
      expect(r['contactIds'], [ctCaio]);
    });

    test('excluir a conta do contato tira o id da sessao da dona', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      expect(
          await h.status('DELETE', '/me',
              body: {'password': 'senha-boa-123'}, token: bia.token),
          204);
      final r = await h.json('GET', '/safety/sessions/${s['id']}',
          token: ana.token);
      expect(r['contactIds'], isEmpty);
    });

    test('excluir a conta da dona apaga a sessao e o link', () async {
      final s = await h.criarSessao(ana, [ctBia]);
      final token = (s['shareUrl'] as String).split('/').last;
      await h.status('DELETE', '/me',
          body: {'password': 'senha-boa-123'}, token: ana.token);
      expect(await h.status('GET', '/s/$token'), 404);
      expect(h.safety.sessionCount, 0);
    });
  });
}
