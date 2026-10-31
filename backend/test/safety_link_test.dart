// Link publico do Rastro Seguro: GET /s/<token> (HTML) e /s/<token>.json.
import 'dart:convert';

import 'package:strava_estudo_backend/src/safety/safety_api.dart';
import 'package:strava_estudo_backend/src/safety/safety_service.dart';
import 'package:test/test.dart';

import 'safety_harness.dart';

void main() {
  late Harness h;
  late Conta ana, bia;
  late String sid, token;

  setUp(() async {
    h = Harness();
    ana = await h.conta('ana@exemplo.com', nome: '  <i>Ana</i> Souza ');
    bia = await h.conta('bia@exemplo.com', nome: 'Bia Lima');
    final ct = await h.contatoAceito(ana, bia);
    final s = await h.criarSessao(ana, [ct], etaMs: h.agora + hora);
    sid = s['id'] as String;
    token = (s['shareUrl'] as String).split('/').last;
  });

  Future<Map<String, dynamic>> publico() async {
    final r = await h.chamar('GET', '/s/$token.json');
    expect(r.statusCode, 200);
    return jsonDecode(await r.readAsString()) as Map<String, dynamic>;
  }

  test('token gerado: 32 bytes em base64url sem padding', () {
    final t = gerarTokenLink();
    expect(t, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(base64Url.decode('$t='), hasLength(32));
    expect(gerarTokenLink(), isNot(t));
  });

  test('HTML: cabecalhos, refresh, nome escapado, sem email', () async {
    await h.posicao(ana, sid, lat: -23.5, lon: -46.6);
    h.agora += 2 * minuto;
    final r = await h.chamar('GET', '/s/$token');
    expect(r.statusCode, 200);
    expect(r.headers['content-type'], startsWith('text/html'));
    expect(r.headers['cache-control'], 'no-store');
    expect(r.headers['x-robots-tag'], contains('noindex'));
    expect(r.headers['referrer-policy'], 'no-referrer');
    final html = await r.readAsString();
    expect(html, contains('<meta name="robots" content="noindex'));
    expect(html, contains('<meta http-equiv="refresh" content="30">'));
    expect(html, contains('lang="pt-BR"'));
    // Primeiro nome, escapado; sobrenome e email nunca aparecem.
    expect(html, contains('&lt;i&gt;Ana&lt;/i&gt;'));
    expect(html, isNot(contains('<i>')));
    expect(html, isNot(contains('Souza')));
    expect(html, isNot(contains('ana@exemplo.com')));
    expect(html, contains('Em atividade'));
    expect(html, contains('ha 2 min'));
    expect(
        html,
        contains('https://www.openstreetmap.org/?mlat=-23.500000&amp;'
            'mlon=-46.600000#map=17/-23.500000/-46.600000'));
  });

  test('JSON: mesmos dados, sem email nem trajeto', () async {
    await h.posicao(ana, sid, lat: -23.5, lon: -46.6);
    h.agora += 90 * seg;
    final r = await h.chamar('GET', '/s/$token.json');
    expect(r.headers['cache-control'], 'no-store');
    expect(r.headers['x-robots-tag'], contains('noindex'));
    final j = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
    expect(j['firstName'], '<i>Ana</i>');
    expect(j['state'], 'active');
    expect(j['etaMs'], isA<int>());
    expect(j['lastPosition']['lat'], -23.5);
    expect(j['lastPositionAgeMs'], 90 * seg);
    expect(j['mapUrl'], startsWith('https://www.openstreetmap.org/'));
    expect(jsonEncode(j), isNot(contains('@')));
    expect(j.keys, isNot(contains('route')));
  });

  test('sem posicao ainda: pagina diz isso', () async {
    final html = await (await h.chamar('GET', '/s/$token')).readAsString();
    expect(html, contains('Ainda sem posicao'));
    expect((await publico())['lastPosition'], isNull);
  });

  test('checando ainda aparece como em atividade; alertado = nao respondeu',
      () async {
    await h.avancar(6 * minuto);
    expect((await publico())['state'], 'active');
    final inicioCheck = h.agora;
    await h.avancar(2 * minuto);
    final j = await publico();
    expect(j['state'], 'no_response');
    expect(j['sinceMs'], inicioCheck);
    final html = await (await h.chamar('GET', '/s/$token')).readAsString();
    expect(html, contains('Nao respondeu desde'));
    expect(html, contains('<time datetime='));
  });

  test('arrived: chegou, e o link expira 15 min depois', () async {
    await h.json('POST', '/safety/sessions/$sid/arrived', token: ana.token);
    expect((await publico())['state'], 'arrived');
    final html = await (await h.chamar('GET', '/s/$token')).readAsString();
    expect(html, contains('Chegou'));
    h.agora += 15 * minuto - 1;
    expect(await h.status('GET', '/s/$token'), 200);
    h.agora += 1;
    final r = await h.chamar('GET', '/s/$token');
    expect(r.statusCode, 404);
    expect(r.headers['cache-control'], 'no-store');
    expect(await r.readAsString(), contains(mensagemLinkExpirado));
    final rj = await h.chamar('GET', '/s/$token.json');
    expect(rj.statusCode, 404);
    expect(jsonDecode(await rj.readAsString()), {'error': mensagemLinkExpirado});
  });

  test('desconhecido ou malformado: 404 "Este link expirou"', () async {
    for (final t in ['x' * 43, 'curto', '${'a' * 42}!', '$token.xml']) {
      final r = await h.chamar('GET', '/s/${Uri.encodeComponent(t)}');
      expect(r.statusCode, 404, reason: t);
      expect(await r.readAsString(), contains(mensagemLinkExpirado));
    }
  });

  test('escaparHtml cobre os 5 caracteres', () {
    expect(escaparHtml('<a href="x" onclick=\'y\'>&'),
        '&lt;a href=&quot;x&quot; onclick=&#39;y&#39;&gt;&amp;');
  });
}
