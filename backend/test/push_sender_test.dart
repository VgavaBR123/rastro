// PushSender: LogPushSender e a montagem da requisicao do FcmPushSender com
// um cliente HTTP falso (o FCM de verdade nao e chamado nos testes).
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:strava_estudo_backend/src/safety/fcm_push_sender.dart';
import 'package:strava_estudo_backend/src/safety/push_sender.dart';
import 'package:test/test.dart';

const PushMessage _msg = PushMessage(
  token: 'tok:abc-123_xyz',
  platform: 'android',
  notificationId: 'nt_1',
  type: 'safety_alert',
  title: 'Ana nao respondeu',
  body: 'Veja a ultima posicao no link.',
  data: {
    'sessionId': 'ss_1',
    'shareUrl': 'https://x/s/t',
    'reason': 'silence',
    'lat': -23.5,
    'extra': {'a': 1},
  },
);

void main() {
  test('LogPushSender registra tipo e inicio do token, sem o corpo', () async {
    final linhas = <String>[];
    final r = await LogPushSender(escrever: linhas.add).send(_msg);
    expect(r, PushResult.sent);
    expect(linhas.single, contains('safety_alert'));
    expect(linhas.single, contains('tok:abc-'));
    expect(linhas.single, isNot(contains('tok:abc-123_xyz')));
    expect(linhas.single, isNot(contains('ultima posicao')));
  });

  group('FcmPushSender', () {
    late List<http.Request> pedidos;
    late int tokensPedidos;
    late DateTime relogio;

    /// [validade]: quanto cada token de acesso novo vale.
    FcmPushSender montar(http.Response Function(http.Request) resp,
        {Duration validade = const Duration(hours: 1)}) {
      pedidos = [];
      tokensPedidos = 0;
      relogio = DateTime.utc(2026, 10, 30, 12);
      return FcmPushSender(
        projectId: 'rastro-teste',
        accessToken: () async {
          tokensPedidos++;
          return FcmAccessToken('ya29.falso$tokensPedidos', relogio.add(validade));
        },
        client: MockClient((req) async {
          pedidos.add(req);
          return resp(req);
        }),
        agora: () => relogio,
      );
    }

    String erroFcm(String status, {String? errorCode, String? campo}) =>
        jsonEncode({
          'error': {
            'status': status,
            'details': [
              if (errorCode != null)
                {
                  '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
                  'errorCode': errorCode
                },
              if (campo != null)
                {
                  '@type': 'type.googleapis.com/google.rpc.BadRequest',
                  'fieldViolations': [
                    {'field': campo, 'description': 'invalido'}
                  ]
                },
            ]
          }
        });

    test('monta o POST do HTTP v1 com token, notification e data em texto',
        () async {
      final s = montar((_) => http.Response('{"name":"projects/x/messages/1"}', 200));
      expect(await s.send(_msg), PushResult.sent);
      final req = pedidos.single;
      expect(req.method, 'POST');
      expect(req.url.toString(),
          'https://fcm.googleapis.com/v1/projects/rastro-teste/messages:send');
      expect(req.headers['authorization'], 'Bearer ya29.falso1');
      expect(req.headers['content-type'], startsWith('application/json'));
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      final m = corpo['message'] as Map<String, dynamic>;
      expect(m['token'], 'tok:abc-123_xyz');
      expect(m['notification'],
          {'title': 'Ana nao respondeu', 'body': 'Veja a ultima posicao no link.'});
      expect(m['data'], {
        'type': 'safety_alert',
        'notificationId': 'nt_1',
        'sessionId': 'ss_1',
        'shareUrl': 'https://x/s/t',
        'reason': 'silence',
        'lat': '-23.5',
        'extra': '{"a":1}',
      });
      expect((m['data'] as Map).values, everyElement(isA<String>()));
      expect(m['android'], {'priority': 'high'});
    });

    test('reaproveita o token de acesso enquanto vale', () async {
      final s = montar((_) => http.Response('{}', 200));
      await s.send(_msg);
      relogio = relogio.add(const Duration(minutes: 50));
      await s.send(_msg);
      expect(tokensPedidos, 1);
    });

    test('renova o token de acesso perto de expirar', () async {
      final s = montar((_) => http.Response('{}', 200));
      await s.send(_msg);
      relogio = relogio.add(const Duration(minutes: 59, seconds: 30));
      await s.send(_msg);
      expect(tokensPedidos, 2);
      expect(pedidos.last.headers['authorization'], 'Bearer ya29.falso2');
    });

    test('401: renova o token e tenta de novo uma vez na hora', () async {
      var n = 0;
      final s = montar((_) => http.Response('{}', ++n == 1 ? 401 : 200));
      expect(await s.send(_msg), PushResult.sent);
      expect(pedidos.length, 2);
      expect(tokensPedidos, 2);
      expect(pedidos.last.headers['authorization'], 'Bearer ya29.falso2');
    });

    test('401 de novo depois de renovar = falha, sem terceira tentativa',
        () async {
      final s = montar((_) => http.Response('{}', 401));
      expect(await s.send(_msg), PushResult.failed);
      expect(pedidos.length, 2);
    });

    test('UNREGISTERED ou INVALID_ARGUMENT no message.token = token invalido',
        () async {
      expect(
          await montar((_) => http.Response(
                  erroFcm('NOT_FOUND', errorCode: 'UNREGISTERED'), 404))
              .send(_msg),
          PushResult.invalidToken);
      expect(
          await montar((_) => http.Response(
                  erroFcm('INVALID_ARGUMENT', campo: 'message.token'), 400))
              .send(_msg),
          PushResult.invalidToken);
    });

    test('404 sem UNREGISTERED e 400 de payload nao apagam o token', () async {
      expect(await montar((_) => http.Response('{}', 404)).send(_msg),
          PushResult.failed);
      expect(
          await montar((_) => http.Response(
                  erroFcm('INVALID_ARGUMENT', campo: 'message.data'), 400))
              .send(_msg),
          PushResult.failed);
      expect(
          await montar((_) => http.Response(
                  erroFcm('INVALID_ARGUMENT', errorCode: 'INVALID_ARGUMENT'), 400))
              .send(_msg),
          PushResult.failed);
    });

    test('5xx = falha passageira', () async {
      for (final st in [500, 503]) {
        expect(
            await montar((_) => http.Response('{"error":{}}', st)).send(_msg),
            PushResult.failed,
            reason: '$st');
      }
    });

    test('erro de rede = falha', () async {
      final s = FcmPushSender(
        projectId: 'p',
        accessToken: () async =>
            FcmAccessToken('t', DateTime.now().toUtc().add(const Duration(hours: 1))),
        client: MockClient((_) async => throw http.ClientException('caiu')),
      );
      expect(await s.send(_msg), PushResult.failed);
    });

    test('erro ao obter o token de acesso = falha', () async {
      final s = FcmPushSender(
        projectId: 'p',
        accessToken: () async => throw StateError('sem rede'),
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      expect(await s.send(_msg), PushResult.failed);
    });

    test('fromServiceAccountJson exige project_id', () {
      expect(() => FcmPushSender.fromServiceAccountJson({'type': 'x'}),
          throwsA(isA<FormatException>()));
    });
  });
}
