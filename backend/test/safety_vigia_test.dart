// Vigia do Rastro Seguro com relogio falso: silencio 5 min, parada 10 min,
// checagem 2 min (padroes do contrato). Cada teste avanca o relogio e roda
// tick() na mao.
import 'package:test/test.dart';

import 'safety_harness.dart';

void main() {
  late Harness h;
  late Conta ana, bia, caio;
  late String ctBia, ctCaio;
  late String sid;

  Future<Map<String, dynamic>> sessao() =>
      h.json('GET', '/safety/sessions/$sid', token: ana.token);

  /// Mantem a sessao viva (movendo) por [ms], mandando posicao a cada 60 s.
  Future<void> correr(int ms, {bool moving = true, bool paused = false}) async {
    final int fim = h.agora + ms;
    while (h.agora < fim) {
      await h.avancar(minuto);
      await h.posicao(ana, sid, moving: moving, paused: paused);
    }
  }

  setUp(() async {
    h = Harness();
    ana = await h.conta('ana@exemplo.com', nome: 'Ana Souza');
    bia = await h.conta('bia@exemplo.com', nome: 'Bia Lima');
    caio = await h.conta('caio@exemplo.com', nome: 'Caio Reis');
    ctBia = await h.contatoAceito(ana, bia);
    ctCaio = await h.contatoAceito(ana, caio);
    sid = (await h.criarSessao(ana, [ctBia, ctCaio], etaMs: h.agora + hora))['id']
        as String;
  });

  group('silencio', () {
    test('nada antes de 5 min; checagem depois; alerta no prazo', () async {
      await h.avancar(5 * minuto);
      expect((await sessao())['status'], 'active');
      await h.avancar(seg);
      final s = await sessao();
      expect(s['status'], 'checking');
      expect(s['check'],
          {'reason': 'silence', 'startedAt': h.agora, 'deadlineMs': h.agora + 2 * minuto});
      final check = (await h.caixa(ana)).first;
      expect(check['type'], 'safety_check');
      expect(check['data']['sessionId'], sid);
      expect(check['data']['reason'], 'silence');
      expect(await h.tipos(bia), ['contact_invite']);

      await h.avancar(2 * minuto - seg);
      expect((await sessao())['status'], 'checking');
      await h.avancar(seg);
      final a = await sessao();
      expect(a['status'], 'alerted');
      expect(a['alertedAt'], h.agora);
      for (final c in [bia, caio]) {
        final n = (await h.caixa(c)).first;
        expect(n['type'], 'safety_alert');
        expect(n['data']['reason'], 'silence');
        expect(n['data']['shareUrl'], a['shareUrl']);
        expect(n['data']['ownerName'], 'Ana Souza');
        expect(n['data']['sessionId'], sid);
      }
    });

    test('um alerta por checagem, sem repetir a cada tick', () async {
      await h.avancar(6 * minuto);
      await h.avancar(3 * minuto);
      for (var i = 0; i < 10; i++) {
        await h.avancar(15 * seg);
      }
      expect((await h.tipos(bia)).where((t) => t == 'safety_alert').length, 1);
      expect((await h.tipos(ana)).where((t) => t == 'safety_check').length, 1);
    });

    test('batimento (lat/lon null) conta como sinal de vida', () async {
      for (var i = 0; i < 10; i++) {
        await h.avancar(minuto);
        await h.posicao(ana, sid, lat: null, lon: null);
      }
      expect((await sessao())['status'], 'active');
    });

    test('posicao durante a checagem nao resolve: so ok/extend/arrived',
        () async {
      await h.avancar(6 * minuto);
      await h.posicao(ana, sid);
      await h.avancar(2 * minuto);
      expect((await sessao())['status'], 'alerted');
    });
  });

  group('parada', () {
    test('10 min de amostras paradas sem pausa dispara stopped', () async {
      await h.posicao(ana, sid, moving: false);
      await correr(9 * minuto, moving: false);
      expect((await sessao())['status'], 'active');
      await correr(minuto, moving: false);
      final s = await sessao();
      expect(s['status'], 'checking');
      expect(s['check']['reason'], 'stopped');
    });

    test('pausa manual nao dispara', () async {
      await correr(20 * minuto, moving: false, paused: true);
      expect((await sessao())['status'], 'active');
    });

    test('uma amostra em movimento recomeca a janela', () async {
      await h.posicao(ana, sid, moving: false);
      await correr(8 * minuto, moving: false);
      await h.posicao(ana, sid, moving: true);
      // A janela conta da primeira amostra parada depois do movimento.
      await correr(10 * minuto, moving: false);
      expect((await sessao())['status'], 'active');
      await correr(minuto, moving: false);
      expect((await sessao())['check']['reason'], 'stopped');
    });

    test('pausa no meio recomeca a janela', () async {
      await h.posicao(ana, sid, moving: false);
      await correr(8 * minuto, moving: false);
      await h.posicao(ana, sid, moving: false, paused: true);
      await h.posicao(ana, sid, moving: false);
      await correr(9 * minuto, moving: false);
      expect((await sessao())['status'], 'active');
    });

    test('ok depois de stopped recomeca a janela (nao pergunta no tick seguinte)',
        () async {
      await h.posicao(ana, sid, moving: false);
      await correr(10 * minuto, moving: false);
      expect((await sessao())['status'], 'checking');
      await h.json('POST', '/safety/sessions/$sid/ok', token: ana.token);
      await correr(9 * minuto, moving: false);
      expect((await sessao())['status'], 'active');
    });
  });

  group('horario', () {
    test('passar do eta dispara eta; extend volta a active', () async {
      await correr(hora);
      expect((await sessao())['status'], 'active');
      await correr(minuto);
      final s = await sessao();
      expect(s['status'], 'checking');
      expect(s['check']['reason'], 'eta');
      final e = await h.json('POST', '/safety/sessions/$sid/extend',
          body: {'minutes': 15}, token: ana.token);
      expect(e['status'], 'active');
      expect(e['check'], isNull);
      await correr(13 * minuto);
      expect((await sessao())['status'], 'active');
    });

    test('ok com o eta vencido so pergunta de novo apos um intervalo de silencio',
        () async {
      await correr(hora + minuto);
      expect((await sessao())['check']['reason'], 'eta');
      await h.json('POST', '/safety/sessions/$sid/ok', token: ana.token);
      await correr(5 * minuto);
      expect((await sessao())['status'], 'active');
      await correr(minuto);
      expect((await sessao())['check']['reason'], 'eta');
      expect((await h.tipos(ana)).where((t) => t == 'safety_check').length, 2);
    });

    test('pausa manual nao impede a regra do horario', () async {
      await correr(hora + minuto, moving: false, paused: true);
      expect((await sessao())['check']['reason'], 'eta');
    });
  });

  group('respostas antes e depois do prazo', () {
    Future<void> checando() async {
      await h.avancar(6 * minuto);
      expect((await sessao())['status'], 'checking');
    }

    Future<void> alertado() async {
      await checando();
      await h.avancar(2 * minuto);
      expect((await sessao())['status'], 'alerted');
      // Resposta um instante depois (a caixa ordena pelo horario).
      h.agora += seg;
    }

    test('ok antes do prazo: active, sem alerta nem all_clear', () async {
      await checando();
      final r = await h.json('POST', '/safety/sessions/$sid/ok', token: ana.token);
      expect(r['status'], 'active');
      expect(r['check'], isNull);
      expect(r['lastSignalAt'], h.agora);
      await h.avancar(2 * minuto);
      expect((await sessao())['status'], 'active');
      expect(await h.tipos(bia), ['contact_invite']);
    });

    test('extend antes do prazo: active e eta maior', () async {
      await checando();
      final r = await h.json('POST', '/safety/sessions/$sid/extend',
          body: {'minutes': 30}, token: ana.token);
      expect(r['status'], 'active');
      await h.avancar(2 * minuto);
      expect((await sessao())['status'], 'active');
    });

    test('arrived antes do prazo: ended, sem alerta', () async {
      await checando();
      final r = await h.json('POST', '/safety/sessions/$sid/arrived',
          token: ana.token);
      expect(r['status'], 'ended');
      expect(r['check'], isNull);
      await h.avancar(5 * minuto);
      expect(await h.tipos(bia), ['contact_invite']);
    });

    test('ok depois do alerta: active, alertedAt null e safety_all_clear',
        () async {
      await alertado();
      final r = await h.json('POST', '/safety/sessions/$sid/ok', token: ana.token);
      expect(r['status'], 'active');
      expect(r['alertedAt'], isNull);
      expect(r['check'], isNull);
      for (final c in [bia, caio]) {
        final n = (await h.caixa(c)).first;
        expect(n['type'], 'safety_all_clear');
        expect(n['data']['sessionId'], sid);
        expect(n['data']['ownerName'], 'Ana Souza');
      }
    });

    test('extend depois do alerta: active e safety_all_clear', () async {
      await alertado();
      await h.json('POST', '/safety/sessions/$sid/extend',
          body: {'minutes': 15}, token: ana.token);
      expect((await h.caixa(bia)).first['type'], 'safety_all_clear');
    });

    test('arrived depois do alerta: ended e safety_all_clear', () async {
      await alertado();
      final r = await h.json('POST', '/safety/sessions/$sid/arrived',
          token: ana.token);
      expect(r['status'], 'ended');
      expect((await h.caixa(bia)).first['type'], 'safety_all_clear');
    });

    test('nova checagem depois de responder gera novo alerta', () async {
      await alertado();
      await h.json('POST', '/safety/sessions/$sid/ok', token: ana.token);
      await h.avancar(6 * minuto);
      await h.avancar(2 * minuto);
      expect((await h.tipos(bia)).where((t) => t == 'safety_alert').length, 2);
    });
  });

  group('SOS', () {
    test('durante a checagem: avisa na hora e mantem a checagem', () async {
      await h.avancar(6 * minuto);
      final r = await h.json('POST', '/safety/sessions/$sid/sos', token: ana.token);
      expect(r['status'], 'checking');
      expect((await h.caixa(bia)).first['type'], 'safety_sos');
      await h.avancar(2 * minuto);
      expect((await sessao())['status'], 'alerted');
    });
  });

  group('contato removido no meio da sessao', () {
    test('quem saiu nao recebe o alerta; quem ficou recebe', () async {
      expect(
          await h.status('DELETE', '/safety/contacts/$ctCaio', token: caio.token),
          204);
      await h.avancar(6 * minuto);
      await h.avancar(2 * minuto);
      expect((await h.caixa(bia)).first['type'], 'safety_alert');
      expect((await h.tipos(caio)).contains('safety_alert'), isFalse);
    });

    test('sem contatos restantes o vigia segue sem erro', () async {
      await h.status('DELETE', '/safety/contacts/$ctCaio', token: ana.token);
      await h.status('DELETE', '/safety/contacts/$ctBia', token: ana.token);
      await h.avancar(6 * minuto);
      await h.avancar(2 * minuto);
      final s = await sessao();
      expect(s['status'], 'alerted');
      expect(s['contactIds'], isEmpty);
    });
  });

  group('fim automatico e limpeza', () {
    test('encerra sozinha em eta + 6 h e some 24 h depois do fim', () async {
      final link = ((await sessao())['shareUrl'] as String).split('/').last;
      h.agora += hora + 6 * hora - seg;
      await h.service.tick();
      expect((await sessao())['status'], isNot('ended'));
      await h.avancar(seg);
      final s = await sessao();
      expect(s['status'], 'ended');
      expect(s['endedAt'], h.agora);
      // O link ainda vale ate a limpeza.
      expect(await h.status('GET', '/s/$link'), 200);
      expect(await h.status('GET', '/safety/sessions/active', token: ana.token),
          404);
      await h.avancar(24 * hora);
      expect(await h.status('GET', '/s/$link'), 200);
      await h.avancar(seg);
      expect(await h.status('GET', '/safety/sessions/$sid', token: ana.token),
          404);
      expect(await h.status('GET', '/s/$link'), 404);
    });

    test('sessao encerrada por arrived tambem some 24 h depois', () async {
      await h.json('POST', '/safety/sessions/$sid/arrived', token: ana.token);
      await h.avancar(24 * hora + seg);
      expect(h.safety.sessionCount, 0);
    });
  });

  test('start() liga o timer e stop() desliga', () async {
    h.service.start();
    h.service.stop();
  });
}
