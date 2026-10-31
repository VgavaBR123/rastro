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

    FcmPushSender montar(http.Response Function(http.Request) resp) {
      pedidos = [];
      tokensPedidos = 0;
      return FcmPushSender(
        projectId: 'rastro-teste',
        accessToken: () async {
          tokensPedidos++;
          return 'ya29.falso';
        },
        client: MockClient((req) async {
          pedidos.add(req);
          return resp(req);
        }),
      );
    }

    test('monta o POST do HTTP v1 com token, notification e data em texto',
        () async {
      final s = montar((_) => http.Response('{"name":"projects/x/messages/1"}', 200));
      expect(await s.send(_msg), PushResult.sent);
      final req = pedidos.single;
      expect(req.method, 'POST');
      expect(req.url.toString(),
          'https://fcm.googleapis.com/v1/projects/rastro-teste/messages:send');
      expect(req.headers['authorization'], 'Bearer ya29.falso');
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

    test('reaproveita o token de acesso entre envios', () async {
      final s = montar((_) => http.Response('{}', 200));
      await s.send(_msg);
      await s.send(_msg);
      expect(tokensPedidos, 1);
    });

    test('404 ou UNREGISTERED = token invalido', () async {
      expect(await montar((_) => http.Response('{}', 404)).send(_msg),
          PushResult.invalidToken);
      final unreg = jsonEncode({
        'error': {
          'code': 400,
          'status': 'INVALID_ARGUMENT',
          'details': [
            {
              '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
              'errorCode': 'UNREGISTERED'
            }
          ]
        }
      });
      expect(await montar((_) => http.Response(unreg, 400)).send(_msg),
          PushResult.invalidToken);
    });

    test('400 de payload, 401 e 5xx = falha passageira (token fica)', () async {
      for (final st in [400, 401, 500, 503]) {
        expect(
            await montar((_) => http.Response('{"error":{}}', st)).send(_msg),
            PushResult.failed,
            reason: '$st');
      }
    });

    test('401 descarta o token de acesso em cache', () async {
      var n = 0;
      final s = montar((_) => http.Response('{}', ++n == 1 ? 401 : 200));
      await s.send(_msg);
      await s.send(_msg);
      expect(tokensPedidos, 2);
    });

    test('erro de rede = falha', () async {
      final s = FcmPushSender(
        projectId: 'p',
        accessToken: () async => 't',
        client: MockClient((_) async => throw http.ClientException('caiu')),
      );
      expect(await s.send(_msg), PushResult.failed);
    });

    test('fromServiceAccountJson exige project_id', () {
      expect(() => FcmPushSender.fromServiceAccountJson({'type': 'x'}),
          throwsA(isA<FormatException>()));
    });
  });
}
