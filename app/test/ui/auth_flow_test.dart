// Fluxo de conta pela UI: entrar pela aba Voce, ver o perfil com os totais e
// sair (a aba volta ao convite para entrar).
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/auth/auth_api.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../auth/auth_test.dart' show RouteAdapter, meJson, session, sessionJson;

/// Abre a aba Voce pela navegacao.
Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav_profile')));
  await tester.pumpAndSettle();
}

/// Deslogado: aba Voce e o convite para entrar.
Future<void> openSignIn(WidgetTester tester) async {
  await openProfile(tester);
  await tester.tap(find.byKey(const Key('profile_signin')));
  await tester.pumpAndSettle();
}

Future<InMemorySessionStore> pumpApp(
  WidgetTester tester,
  RouteAdapter adapter, {
  InMemorySessionStore? store,
}) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final s = store ?? InMemorySessionStore();
  final router = buildAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        sessionStoreProvider.overrideWithValue(s),
        authApiProvider.overrideWithValue(
          AuthApi(Dio()..httpClientAdapter = adapter, 'http://srv'),
        ),
      ],
      // Grafo de navegacao real (go_router): as telas navegam por AppRoutes.
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return s;
}

void main() {
  testWidgets('entrar pela aba Voce mostra o perfil', (tester) async {
    final store = await pumpApp(
      tester,
      RouteAdapter({
        'POST /auth/login': (200, sessionJson),
        'GET /me': (200, meJson),
      }),
    );
    await openSignIn(tester);
    await tester.enterText(
      find.byKey(const Key('auth_email')),
      'ana@exemplo.com',
    );
    await tester.enterText(find.byKey(const Key('auth_password')), '12345678');
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_submit')), findsNothing);
    expect(find.byKey(const Key('profile_signin')), findsNothing);
    expect(find.text('Ana'), findsOneWidget);
    expect((await store.read())!.token, 'tok-1');
  });

  testWidgets('senha errada mostra o erro e fica na tela', (tester) async {
    await pumpApp(
      tester,
      RouteAdapter({
        'POST /auth/login': (401, {'error': 'x'}),
      }),
    );
    await openSignIn(tester);
    await tester.enterText(
      find.byKey(const Key('auth_email')),
      'ana@exemplo.com',
    );
    await tester.enterText(find.byKey(const Key('auth_password')), 'errada');
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    expect(find.byKey(const Key('auth_submit')), findsOneWidget);
  });

  testWidgets('criar conta valida nome e senha curta antes de enviar', (
    tester,
  ) async {
    final adapter = RouteAdapter({});
    await pumpApp(tester, adapter);
    await openSignIn(tester);
    await tester.tap(find.byKey(const Key('auth_toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth_email')),
      'ana@exemplo.com',
    );
    await tester.enterText(find.byKey(const Key('auth_password')), '123');
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome'), findsOneWidget);
    expect(find.text('Minimo de 8 caracteres'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('perfil mostra os totais e sair volta a pedir login', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      RouteAdapter({
        'GET /me': (200, meJson),
        'POST /auth/logout': (204, null),
      }),
      store: InMemorySessionStore(session()),
    );
    await openProfile(tester);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('ana@exemplo.com'), findsOneWidget);
    expect(find.byKey(const Key('profile_count')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('12,50 km'), findsOneWidget);

    final logout = find.byKey(const Key('profile_logout'));
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_signin')), findsOneWidget);
    expect(find.byKey(const Key('profile_name')), findsNothing);
    expect(await store.read(), isNull);
  });
}
