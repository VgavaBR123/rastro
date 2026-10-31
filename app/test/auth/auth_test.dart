// Conta: cliente HTTP (formato das requisicoes, contrato do backend), controller
// (offline-first, 401 desloga, 403 nao desloga, trocar/recuperar senha, excluir conta) e o efeito do login no upload e no sync.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/auth/auth_api.dart';
import 'package:strava_estudo_app/auth/auth_controller.dart';
import 'package:strava_estudo_app/auth/auth_models.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/sync/background/background_sync.dart';
import 'package:strava_estudo_app/sync/sync_controller.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/dio_activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

import '../sync/upload/sync_service_test.dart'
    show FakeUploader, seedPendingActivity;

/// Adapter que grava cada requisicao e responde pela rota.
class RouteAdapter implements HttpClientAdapter {
  final Map<String, (int, Object?)> routes;
  final List<RequestOptions> requests = [];
  final List<String> bodies = [];
  bool offline = false;
  Map<String, List<String>> extraHeaders = const {};

  RouteAdapter(this.routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    requests.add(options);
    final chunks = requestStream == null
        ? <Uint8List>[]
        : await requestStream.toList();
    bodies.add(utf8.decode([for (final c in chunks) ...c]));
    final (status, body) =
        routes['${options.method} ${options.uri.path}'] ??
        (404, {'error': 'x'});
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...extraHeaders,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const userJson = {
  'id': 'u1',
  'email': 'ana@exemplo.com',
  'displayName': 'Ana',
  'createdAt': 1700000000000,
};
const sessionJson = {'token': 'tok-1', 'user': userJson};
const meJson = {
  'user': userJson,
  'stats': {'activityCount': 3, 'totalDistanceMeters': 12500.5},
};

AuthApi apiWith(RouteAdapter a) =>
    AuthApi(Dio()..httpClientAdapter = a, 'http://srv');

AuthSession session([String name = 'Ana']) => AuthSession(
  token: 'tok-1',
  user: AppUser(
    id: 'u1',
    email: 'ana@exemplo.com',
    displayName: name,
    createdAtMs: 1,
  ),
);

void main() {
  group('AuthApi', () {
    test('register manda JSON e devolve a sessao', () async {
      final a = RouteAdapter({'POST /auth/register': (201, sessionJson)});
      final s = await apiWith(a).register(
        email: 'ana@exemplo.com',
        password: '12345678',
        displayName: 'Ana',
      );
      expect(s.token, 'tok-1');
      expect(s.user.displayName, 'Ana');
      expect(jsonDecode(a.bodies.single), {
        'email': 'ana@exemplo.com',
        'password': '12345678',
        'displayName': 'Ana',
      });
      expect(a.requests.single.headers['Authorization'], isNull);
    });

    test('login 401 vira mensagem sem dizer se foi e-mail ou senha', () async {
      final a = RouteAdapter({
        'POST /auth/login': (401, {'error': 'x'}),
      });
      await expectLater(
        apiWith(a).login(email: 'a@b.c', password: 'errada'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.isUnauthorized, '401', isTrue)
              .having((e) => e.message, 'msg', 'E-mail ou senha incorretos'),
        ),
      );
    });

    test('register 409 explica que o e-mail ja existe', () async {
      final a = RouteAdapter({
        'POST /auth/register': (409, {'error': 'x'}),
      });
      await expectLater(
        apiWith(a)
            .register(email: 'a@b.c', password: '12345678', displayName: 'A'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'msg',
            'Ja existe uma conta com este e-mail',
          ),
        ),
      );
    });

    test('me e logout mandam o Bearer', () async {
      final a = RouteAdapter({
        'GET /me': (200, meJson),
        'POST /auth/logout': (204, null),
      });
      final p = await apiWith(a).me('tok-1');
      expect(p.stats.activityCount, 3);
      expect(p.stats.totalDistanceMeters, 12500.5);
      await apiWith(a).logout('tok-1');
      expect(
        a.requests.map((r) => r.headers['Authorization']),
        everyElement('Bearer tok-1'),
      );
    });

    test('429 avisa quanto tempo esperar (Retry-After)', () async {
      final a =
          RouteAdapter({
              'POST /auth/login': (429, {'error': 'muitas tentativas'}),
            })
            ..extraHeaders = {
              'retry-after': ['896'],
            };
      await expectLater(
        apiWith(a).login(email: 'a@b.c', password: 'x'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'msg',
            'Muitas tentativas. Tente de novo em 15 min.',
          ),
        ),
      );
      expect(AuthApi.waitHint('30'), 'Tente de novo em 30 s.');
      expect(AuthApi.waitHint(null), 'Tente de novo mais tarde.');
    });

    test('sem rede vira AuthException sem status', () async {
      final a = RouteAdapter({})..offline = true;
      await expectLater(
        apiWith(a).me('t'),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', isNull),
        ),
      );
    });
  });

  group('AuthController', () {
    test('sem sessao guardada: deslogado', () async {
      final c = AuthController(
        apiWith(RouteAdapter({})),
        InMemorySessionStore(),
      );
      await c.load();
      expect(c.state.status, AuthStatus.signedOut);
    });

    test('sessao guardada + /me ok: logado com o usuario atualizado', () async {
      final a = RouteAdapter({
        'GET /me': (
          200,
          {
            ...meJson,
            'user': {...userJson, 'displayName': 'Ana Paula'},
          },
        ),
      });
      final store = InMemorySessionStore(session());
      final c = AuthController(apiWith(a), store);
      await c.load();
      expect(c.state.isSignedIn, isTrue);
      expect(c.state.user!.displayName, 'Ana Paula');
      expect((await store.read())!.user.displayName, 'Ana Paula');
    });

    test(
      'sessao guardada + sem rede: continua logado (offline-first)',
      () async {
        final store = InMemorySessionStore(session());
        final c = AuthController(
          apiWith(RouteAdapter({})..offline = true),
          store,
        );
        await c.load();
        expect(c.state.isSignedIn, isTrue);
        expect(await store.read(), isNotNull);
      },
    );

    test('token recusado (401) no /me: desloga e apaga a sessao', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'GET /me': (401, {'error': 'x'}),
          }),
        ),
        store,
      );
      await c.load();
      expect(c.state.status, AuthStatus.signedOut);
      expect(await store.read(), isNull);
    });

    test('login guarda a sessao e avisa (para agendar o sync)', () async {
      var signedIn = 0;
      final store = InMemorySessionStore();
      final c = AuthController(
        apiWith(RouteAdapter({'POST /auth/login': (200, sessionJson)})),
        store,
        onSignedIn: () => signedIn++,
      );
      expect(await c.login(' ana@exemplo.com ', '12345678'), isTrue);
      expect(c.state.isSignedIn, isTrue);
      expect((await store.read())!.token, 'tok-1');
      expect(signedIn, 1);
    });

    test('login errado mostra o erro e nao guarda nada', () async {
      final store = InMemorySessionStore();
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'POST /auth/login': (401, {'error': 'x'}),
          }),
        ),
        store,
      );
      expect(await c.login('a@b.c', 'x'), isFalse);
      expect(c.state.error, 'E-mail ou senha incorretos');
      expect(await store.read(), isNull);
    });

    test('logout limpa a sessao mesmo sem rede', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(RouteAdapter({})..offline = true),
        store,
      );
      await c.logout();
      expect(c.state.status, AuthStatus.signedOut);
      expect(await store.read(), isNull);
    });

    test('antes de sair, o gancho roda com o token ainda guardado (push e Rastro Seguro)', () async {
      final store = InMemorySessionStore(session());
      final seen = <String?>[];
      final c = AuthController(
        apiWith(RouteAdapter({'POST /auth/logout': (204, null), 'POST /auth/logout-all': (204, null)})),
        store,
        beforeSignOut: () async => seen.add((await store.read())?.token),
      );
      await c.logout();
      expect(seen, ['tok-1']);
      await store.write(session());
      await c.logoutAll();
      expect(seen, ['tok-1', 'tok-1']);
    });

    test('gancho que falha nao impede sair', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(RouteAdapter({'POST /auth/logout': (204, null)})),
        store,
        beforeSignOut: () async => throw StateError('x'),
      );
      await c.logout();
      expect(await store.read(), isNull);
    });

    test('editar nome atualiza estado e sessao', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'PATCH /me': (
              200,
              {
                'user': {...userJson, 'displayName': 'Aninha'},
              },
            ),
          }),
        ),
        store,
      );
      expect(await c.updateDisplayName('  Aninha '), isTrue);
      expect(c.state.user!.displayName, 'Aninha');
      expect((await store.read())!.user.displayName, 'Aninha');
    });
  });

  group('AuthApi: conta', () {
    test(
      'logoutAll faz POST /auth/logout-all com Bearer e sem corpo',
      () async {
        final a = RouteAdapter({'POST /auth/logout-all': (204, null)});
        await apiWith(a).logoutAll('tok-1');
        final r = a.requests.single;
        expect(r.method, 'POST');
        expect(r.uri.path, '/auth/logout-all');
        expect(r.headers['Authorization'], 'Bearer tok-1');
        expect(a.bodies.single, isEmpty);
      },
    );

    test('changePassword manda senha atual e nova com Bearer', () async {
      final a = RouteAdapter({'POST /auth/password/change': (204, null)});
      await apiWith(a).changePassword('tok-1', 'velha1234', 'nova12345');
      expect(a.requests.single.headers['Authorization'], 'Bearer tok-1');
      expect(jsonDecode(a.bodies.single), {
        'currentPassword': 'velha1234',
        'newPassword': 'nova12345',
      });
    });

    test('changePassword 403 = senha atual incorreta (nao e 401)', () async {
      final a = RouteAdapter({
        'POST /auth/password/change': (403, {'error': 'x'}),
      });
      await expectLater(
        apiWith(a).changePassword('tok-1', 'errada', 'nova12345'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'status', 403)
              .having((e) => e.isUnauthorized, '401', isFalse)
              .having((e) => e.message, 'msg', 'Senha atual incorreta'),
        ),
      );
    });

    test(
      'forgotPassword manda so o e-mail, sem Bearer; 202 e sucesso',
      () async {
        final a = RouteAdapter({'POST /auth/password/forgot': (202, null)});
        await apiWith(a).forgotPassword('ana@exemplo.com');
        expect(a.requests.single.headers['Authorization'], isNull);
        expect(jsonDecode(a.bodies.single), {'email': 'ana@exemplo.com'});
      },
    );

    test('forgotPassword 429 avisa quanto esperar', () async {
      final a =
          RouteAdapter({
              'POST /auth/password/forgot': (429, {'error': 'x'}),
            })
            ..extraHeaders = {
              'retry-after': ['120'],
            };
      await expectLater(
        apiWith(a).forgotPassword('ana@exemplo.com'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'msg',
            'Muitas tentativas. Tente de novo em 2 min.',
          ),
        ),
      );
    });

    test(
      'resetPassword manda email, codigo e senha e devolve a sessao',
      () async {
        final a = RouteAdapter({
          'POST /auth/password/reset': (200, sessionJson),
        });
        final s = await apiWith(a).resetPassword(
          email: 'ana@exemplo.com',
          code: '123456',
          newPassword: 'nova12345',
        );
        expect(s.token, 'tok-1');
        expect(a.requests.single.headers['Authorization'], isNull);
        expect(jsonDecode(a.bodies.single), {
          'email': 'ana@exemplo.com',
          'code': '123456',
          'newPassword': 'nova12345',
        });
      },
    );

    test('resetPassword 400 usa a mensagem do servidor ou a padrao', () async {
      final comMsg = RouteAdapter({
        'POST /auth/password/reset': (
          400,
          {'error': 'codigo invalido ou expirado'},
        ),
      });
      await expectLater(
        apiWith(comMsg).resetPassword(
          email: 'a@b.c',
          code: '000000',
          newPassword: '12345678',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'msg',
            'Codigo invalido ou expirado',
          ),
        ),
      );
      final semMsg = RouteAdapter({'POST /auth/password/reset': (400, null)});
      await expectLater(
        apiWith(semMsg).resetPassword(
          email: 'a@b.c',
          code: '000000',
          newPassword: '12345678',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'msg',
            'Codigo invalido ou expirado',
          ),
        ),
      );
    });

    test(
      'deleteAccount faz DELETE /me com a senha e Bearer; 403 = senha errada',
      () async {
        final ok = RouteAdapter({'DELETE /me': (204, null)});
        await apiWith(ok).deleteAccount('tok-1', 'minhasenha');
        final r = ok.requests.single;
        expect(r.method, 'DELETE');
        expect(r.headers['Authorization'], 'Bearer tok-1');
        expect(jsonDecode(ok.bodies.single), {'password': 'minhasenha'});

        final errada = RouteAdapter({
          'DELETE /me': (403, {'error': 'x'}),
        });
        await expectLater(
          apiWith(errada).deleteAccount('tok-1', 'x'),
          throwsA(
            isA<AuthException>()
                .having((e) => e.statusCode, 'status', 403)
                .having((e) => e.message, 'msg', 'Senha incorreta'),
          ),
        );
      },
    );

    test('401 em rota protegida nao fala de e-mail/senha', () async {
      final a = RouteAdapter({
        'POST /auth/logout-all': (401, {'error': 'x'}),
      });
      await expectLater(
        apiWith(a).logoutAll('tok-1'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.isUnauthorized, '401', isTrue)
              .having(
                (e) => e.message,
                'msg',
                isNot('E-mail ou senha incorretos'),
              ),
        ),
      );
    });
  });

  group('AuthController: conta', () {
    test('trocar senha ok: continua logado com a mesma sessao', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(RouteAdapter({'POST /auth/password/change': (204, null)})),
        store,
      );
      expect(await c.changePassword('velha1234', 'nova12345'), isTrue);
      expect(c.state.busy, isFalse);
      expect(c.state.error, isNull);
      expect(c.state.status, isNot(AuthStatus.signedOut));
      expect((await store.read())!.token, 'tok-1');
    });

    test('trocar senha 403: mostra o erro e NAO desloga', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'GET /me': (200, meJson),
            'POST /auth/password/change': (403, {'error': 'x'}),
          }),
        ),
        store,
      );
      await c.load();
      expect(await c.changePassword('errada', 'nova12345'), isFalse);
      expect(c.state.isSignedIn, isTrue);
      expect(c.state.user!.id, 'u1');
      expect(c.state.error, 'Senha atual incorreta');
      expect(await store.read(), isNotNull);
      c.clearError();
      expect(c.state.error, isNull);
      expect(c.state.isSignedIn, isTrue);
    });

    test('trocar senha 401: desloga e apaga a sessao', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'POST /auth/password/change': (401, {'error': 'x'}),
          }),
        ),
        store,
      );
      expect(await c.changePassword('a', 'nova12345'), isFalse);
      expect(c.state.status, AuthStatus.signedOut);
      expect(await store.read(), isNull);
    });

    test('sair de todos: limpa a sessao local e fica deslogado', () async {
      final a = RouteAdapter({'POST /auth/logout-all': (204, null)});
      final store = InMemorySessionStore(session());
      final c = AuthController(apiWith(a), store);
      expect(await c.logoutAll(), isTrue);
      expect(c.state.status, AuthStatus.signedOut);
      expect(await store.read(), isNull);
      expect(a.requests.single.headers['Authorization'], 'Bearer tok-1');
    });

    test('sair de todos sem rede: erro e continua logado', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(RouteAdapter({})..offline = true),
        store,
      );
      await c.load();
      expect(await c.logoutAll(), isFalse);
      expect(c.state.isSignedIn, isTrue);
      expect(c.state.error, 'Sem conexao com o servidor');
      expect(await store.read(), isNotNull);
    });

    test('excluir conta ok: limpa a sessao e fica deslogado', () async {
      final a = RouteAdapter({'DELETE /me': (204, null)});
      final store = InMemorySessionStore(session());
      final c = AuthController(apiWith(a), store);
      expect(await c.deleteAccount('minhasenha'), isTrue);
      expect(c.state.status, AuthStatus.signedOut);
      expect(await store.read(), isNull);
      expect(jsonDecode(a.bodies.single), {'password': 'minhasenha'});
    });

    test('excluir conta 403: erro e continua logado', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'GET /me': (200, meJson),
            'DELETE /me': (403, {'error': 'x'}),
          }),
        ),
        store,
      );
      await c.load();
      expect(await c.deleteAccount('errada'), isFalse);
      expect(c.state.isSignedIn, isTrue);
      expect(c.state.error, 'Senha incorreta');
      expect(await store.read(), isNotNull);
    });

    test('excluir conta 401: desloga', () async {
      final store = InMemorySessionStore(session());
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'DELETE /me': (401, {'error': 'x'}),
          }),
        ),
        store,
      );
      expect(await c.deleteAccount('x'), isFalse);
      expect(c.state.status, AuthStatus.signedOut);
      expect(await store.read(), isNull);
    });

    test('esqueci a senha: pede o codigo e nao mexe na sessao', () async {
      final store = InMemorySessionStore();
      final a = RouteAdapter({'POST /auth/password/forgot': (202, null)});
      final c = AuthController(apiWith(a), store);
      await c.load();
      expect(await c.forgotPassword(' ana@exemplo.com '), isTrue);
      expect(c.state.status, AuthStatus.signedOut);
      expect(c.state.busy, isFalse);
      expect(jsonDecode(a.bodies.single), {'email': 'ana@exemplo.com'});
      expect(await store.read(), isNull);
    });

    test('reset ok: guarda a sessao nova, fica logado e avisa', () async {
      var signedIn = 0;
      final store = InMemorySessionStore();
      final c = AuthController(
        apiWith(
          RouteAdapter({'POST /auth/password/reset': (200, sessionJson)}),
        ),
        store,
        onSignedIn: () => signedIn++,
      );
      expect(
        await c.resetPassword('ana@exemplo.com', ' 123456 ', 'nova12345'),
        isTrue,
      );
      expect(c.state.isSignedIn, isTrue);
      expect((await store.read())!.token, 'tok-1');
      expect(signedIn, 1);
    });

    test('reset com codigo errado: erro e segue deslogado', () async {
      final store = InMemorySessionStore();
      final c = AuthController(
        apiWith(
          RouteAdapter({
            'POST /auth/password/reset': (
              400,
              {'error': 'codigo invalido ou expirado'},
            ),
          }),
        ),
        store,
      );
      expect(await c.resetPassword('a@b.c', '000000', 'nova12345'), isFalse);
      expect(c.state.status, AuthStatus.signedOut);
      expect(c.state.error, 'Codigo invalido ou expirado');
      expect(await store.read(), isNull);
    });
  });

  group('upload e sync com conta', () {
    test('uploader manda o Bearer da sessao atual', () async {
      final a = RouteAdapter({
        'POST /uploads': (201, {'uploadId': 'up1'}),
      });
      final up = DioActivityUploader(
        Dio()..httpClientAdapter = a,
        'http://srv',
        token: () async => 'tok-9',
      );
      await up.upload(Uint8List.fromList([1, 2]), activityGuid: 'g');
      expect(a.requests.single.headers['Authorization'], 'Bearer tok-9');
    });

    test('401 no upload vira UnauthorizedUploadException', () async {
      final a = RouteAdapter({
        'POST /uploads': (401, {'error': 'x'}),
      });
      final up = DioActivityUploader(
        Dio()..httpClientAdapter = a,
        'http://srv',
      );
      await expectLater(
        up.upload(Uint8List.fromList([1]), activityGuid: 'g'),
        throwsA(isA<UnauthorizedUploadException>()),
      );
    });

    test('sync manual sem conta pede login e nao envia nada', () async {
      final db = RecordingDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedPendingActivity(db, 'a1');
      final up = FakeUploader();
      final c = SyncController(
        SyncService(db, up),
        db,
        currentUserId: () async => null,
      );
      await c.syncNow();
      expect(c.state.message, kSignInToSyncMessage);
      expect(up.uploadedGuids, isEmpty);
    });

    test('sync de fundo sem conta: true sem abrir o banco', () async {
      var opened = false;
      final ok = await performBackgroundSync(
        baseUrl: 'http://localhost:8081',
        readSession: () async => null,
        openDatabase: () {
          opened = true;
          return RecordingDatabase(NativeDatabase.memory());
        },
      );
      expect(ok, isTrue);
      expect(opened, isFalse);
    });

    test('sync de fundo usa o token da sessao no uploader', () async {
      final db = RecordingDatabase(NativeDatabase.memory());
      await seedPendingActivity(db, 'a1');
      String? usedToken;
      final ok = await performBackgroundSync(
        baseUrl: 'http://localhost:8081',
        readSession: () async =>
            AuthSession(token: 'tok-bg', user: session().user),
        openDatabase: () => db,
        createUploader: (_, token) {
          usedToken = token;
          return FakeUploader();
        },
      );
      expect(ok, isTrue);
      expect(usedToken, 'tok-bg');
    });
  });
}
