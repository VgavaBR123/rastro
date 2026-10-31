// Atomicidade (status + caixa de entrada na mesma transacao) e push pela
// outbox: sai depois do commit, best-effort, com reenvio nos ticks seguintes.
import 'dart:async';

import 'package:test/test.dart';

import 'safety_harness.dart';

void main() {
  late Harness h;
  late Conta ana, bia, caio, duda;
  late String sid;

  Future<Map<String, dynamic>> sessao() =>
      h.json('GET', '/safety/sessions/$sid', token: ana.token);

  Future<int> alertas(Conta c) async =>
      (await h.tipos(c)).where((t) => t == 'safety_alert').length;

  /// Avanca ate o fim do prazo da checagem por silencio, sem o ultimo tick.
  Future<void> ateOPrazo() async {
    for (var i = 0; i < 6; i++) {
      await h.avancar(minuto);
    }
    expect((await sessao())['status'], 'checking');
    h.agora += 2 * minuto;
  }

  setUp(() async {
    h = Harness();
    ana = await h.conta('ana@exemplo.com', nome: 'Ana Souza');
    bia = await h.conta('bia@exemplo.com', nome: 'Bia Lima');
    caio = await h.conta('caio@exemplo.com', nome: 'Caio Reis');
    duda = await h.conta('duda@exemplo.com', nome: 'Duda Melo');
    final ids = [
      await h.contatoAceito(ana, bia),
      await h.contatoAceito(ana, caio),
      await h.contatoAceito(ana, duda),
    ];
    sid = (await h.criarSessao(ana, ids))['id'] as String;
  });

  test('falha no INSERT do 2o contato: nada gravado; o proximo tick avisa os 3',
      () async {
    await ateOPrazo();
    h.safety.falharNaGravacao(2);
    await h.service.tick();
    expect((await sessao())['status'], 'checking');
    for (final c in [bia, caio, duda]) {
      expect(await alertas(c), 0, reason: c.email);
    }
    await h.avancar(15 * seg);
    expect((await sessao())['status'], 'alerted');
    for (final c in [bia, caio, duda]) {
      expect(await alertas(c), 1, reason: c.email);
    }
  });

  test('falha de push: caixa gravada e push reenviado no tick seguinte',
      () async {
    await h.status('POST', '/push/tokens',
        body: {'token': 'tok-bia', 'platform': 'android'}, token: bia.token);
    await ateOPrazo();
    h.push.falhasPassageiras = 1;
    await h.service.tick();
    expect(await alertas(bia), 1);
    final paraBia = h.push.enviadas.where((m) => m.token == 'tok-bia');
    expect(paraBia.length, 1);
    await h.avancar(15 * seg);
    expect(paraBia.length, 2);
    expect(paraBia.last.type, 'safety_alert');
    await h.avancar(15 * seg);
    expect(paraBia.length, 2, reason: 'entregue: sai da fila');
  });

  test('push desiste depois de 5 tentativas, com espera crescente', () async {
    await h.status('POST', '/push/tokens',
        body: {'token': 'tok-bia', 'platform': 'android'}, token: bia.token);
    await ateOPrazo();
    h.push.falhasPassageiras = 1000;
    final instantes = <int>[];
    var antes = 0;
    for (var i = 0; i < 200; i++) {
      await h.avancar(15 * seg);
      final n = h.push.enviadas.where((m) => m.token == 'tok-bia').length;
      if (n != antes) instantes.add(h.agora);
      antes = n;
    }
    expect(antes, 5);
    final esperas = [
      for (var i = 1; i < instantes.length; i++) instantes[i] - instantes[i - 1]
    ];
    for (var i = 1; i < esperas.length; i++) {
      expect(esperas[i], greaterThan(esperas[i - 1]), reason: '$esperas');
    }
    // O token nao e apagado por falha passageira.
    expect(h.safety.hasPushToken('tok-bia'), isTrue);
  });

  test('a rota responde sem esperar o push', () async {
    await h.status('POST', '/push/tokens',
        body: {'token': 'tok-bia', 'platform': 'android'}, token: bia.token);
    h.push.travar = Completer<void>();
    h.agora += seg;
    final r = await h
        .chamar('POST', '/safety/sessions/$sid/sos', token: ana.token)
        .timeout(const Duration(seconds: 2));
    expect(r.statusCode, 200);
    expect((await h.caixa(bia)).first['type'], 'safety_sos');
    h.push.travar!.complete();
  });

  test('falha ao gravar a caixa no arrived apos alerta: 500 e nada muda',
      () async {
    await ateOPrazo();
    await h.service.tick();
    expect((await sessao())['status'], 'alerted');
    h.safety.falharNaGravacao(2);
    final r = await h.chamar('POST', '/safety/sessions/$sid/arrived',
        token: ana.token);
    expect(r.statusCode, 500);
    expect((await sessao())['status'], 'alerted');
    expect((await h.tipos(bia)).first, 'safety_alert');
    // De novo, agora sem falha: encerra e avisa os 3.
    await h.json('POST', '/safety/sessions/$sid/arrived', token: ana.token);
    for (final c in [bia, caio, duda]) {
      expect((await h.tipos(c)).first, 'safety_all_clear');
    }
  });
}
