// Saude do vigia: prazo por sessao e por tick, /health com o ultimo tick e
// recuperacao quando o banco cai e volta.
import 'dart:async';
import 'dart:convert';

import 'package:strava_estudo_backend/src/safety/safety_service.dart';
import 'package:test/test.dart';

import 'safety_harness.dart';

const SafetyConfig _rapida = SafetyConfig(
  tickMs: 20,
  silenceMs: 5 * minuto,
  stopMs: 10 * minuto,
  checkMs: 2 * minuto,
  publicBaseUrl: 'https://rastro.exemplo',
  sessionTimeoutMs: 50,
  tickTimeoutMs: 100,
);

void main() {
  Future<Map<String, dynamic>> saude(Harness h, {int esperado = 200}) async {
    final r = await h.chamar('GET', '/health');
    expect(r.statusCode, esperado);
    return jsonDecode(await r.readAsString()) as Map<String, dynamic>;
  }

  /// Uma dona com sessao aberta (e um contato).
  Future<String> sessaoDe(Harness h, String email) async {
    final dona = await h.conta(email);
    final ct = await h.contatoAceito(dona, await h.conta('c.$email'));
    return (await h.criarSessao(dona, [ct]))['id'] as String;
  }

  group('/health', () {
    test('mostra o ultimo tick; ok enquanto tiver menos de 3 intervalos',
        () async {
      final h = Harness();
      var j = await saude(h);
      expect(j['status'], 'ok');
      expect(j['safety'], {'lastTickAt': null, 'ok': false});
      await h.service.tick();
      j = await saude(h);
      expect(j['safety'], {'lastTickAt': h.agora, 'ok': true});
      h.agora += 3 * 15 * seg;
      expect((await saude(h))['safety']['ok'], isTrue);
      h.agora += 1;
      expect((await saude(h))['safety']['ok'], isFalse);
    });

    test('vigia ligado e sem tick ha mais de 3 intervalos: 503', () async {
      final h = Harness();
      h.service.start();
      addTearDown(h.service.stop);
      expect((await saude(h))['safety']['ok'], isTrue, reason: 'acabou de ligar');
      h.agora += 3 * 15 * seg + 1;
      final j = await saude(h, esperado: 503);
      expect(j['status'], 'degraded');
      expect(j['safety']['ok'], isFalse);
    });
  });

  group('prazos', () {
    test('sessao travada estoura o prazo e o tick segue com as outras',
        () async {
      final h = Harness(config: _rapida);
      final travada = await sessaoDe(h, 'a@exemplo.com');
      final livre = await sessaoDe(h, 'b@exemplo.com');
      h.safety
        ..sessaoTravada = travada
        ..travarSessao = Completer<void>();
      h.agora += 6 * minuto;
      await h.service.tick().timeout(const Duration(seconds: 2));
      expect((await h.safety.findSession(livre))!.status, 'checking');
      h.safety.travarSessao!.complete();
    });

    test('tick travado estoura o prazo e os ticks seguintes voltam', () async {
      final h = Harness(config: _rapida);
      h.safety.travarListagem = Completer<void>();
      h.service.start();
      addTearDown(h.service.stop);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(h.service.lastTickAtMs, isNotNull);
      h.safety.travarListagem?.complete();
    });
  });

  test('banco cai e volta: tick nao quebra e retoma as regras', () async {
    final h = Harness();
    final sid = await sessaoDe(h, 'a@exemplo.com');
    await h.service.tick();
    final ultimo = h.service.lastTickAtMs;
    h.safety.falharListagens = 2;
    h.agora += 3 * minuto;
    await h.service.tick();
    h.agora += minuto;
    await h.service.tick();
    expect(h.service.lastTickAtMs, ultimo, reason: 'tick que falhou nao conta');
    // Volta: o tick conclui. Com o banco fora o app tambem nao conseguia
    // gravar posicao, entao a carencia de silencio conta da volta.
    h.agora += 2 * minuto;
    await h.service.tick();
    expect(h.service.lastTickAtMs, h.agora);
    expect((await h.safety.findSession(sid))!.status, 'active');
    await h.avancar(5 * minuto + seg);
    expect((await h.safety.findSession(sid))!.status, 'checking');
  });
}
