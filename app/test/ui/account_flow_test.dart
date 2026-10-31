// Funcoes de conta pela UI, a partir da aba Voce: esqueci a senha (2 passos,
// entra logado), trocar senha (403 mostra erro e segue logado), sair de todos
// e excluir conta (a aba fica no estado deslogado).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/ui/profile_screen.dart';

import '../auth/auth_test.dart' show RouteAdapter, meJson, session, sessionJson;
import 'auth_flow_test.dart' show openProfile, openSignIn, pumpApp;

/// Lista da aba Voce (as outras abas tambem tem rolagem).
Finder profileScrollable() => find
    .descendant(
      of: find.byKey(const Key('profile_list')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> tapProfileItem(WidgetTester tester, String key) async {
  final item = find.byKey(Key(key));
  await tester.scrollUntilVisible(item, 200, scrollable: profileScrollable());
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Iterable<String> paths(RouteAdapter a) =>
    a.requests.map((r) => '${r.method} ${r.uri.path}');

void main() {
  testWidgets('esqueci a senha: e-mail, código e nova senha, entra logado', (
    tester,
  ) async {
    final adapter = RouteAdapter({
      'POST /auth/password/forgot': (202, null),
      'POST /auth/password/reset': (200, sessionJson),
      'GET /me': (200, meJson),
    });
    final store = await pumpApp(tester, adapter);
    await openSignIn(tester);
    await tester.enterText(
      find.byKey(const Key('auth_email')),
      'ana@exemplo.com',
    );
    await tester.tap(find.byKey(const Key('auth_forgot')));
    await tester.pumpAndSettle();

    // Passo 1: o e-mail ja vem preenchido da tela de login.
    expect(find.text('ana@exemplo.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset_send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reset_info')), findsOneWidget);
    expect(
      find.textContaining(
        'Enviamos um código de 6 dígitos se o e-mail tiver conta',
      ),
      findsOneWidget,
    );

    // Passo 2: validacao local antes de enviar.
    await tester.enterText(find.byKey(const Key('reset_code')), '123');
    await tester.enterText(
      find.byKey(const Key('reset_new_password')),
      'nova12345',
    );
    await tester.enterText(
      find.byKey(const Key('reset_confirm_password')),
      'outra1234',
    );
    await tester.tap(find.byKey(const Key('reset_submit')));
    await tester.pumpAndSettle();
    expect(find.text('O código tem 6 dígitos'), findsOneWidget);
    expect(find.text('As senhas não conferem'), findsOneWidget);
    expect(paths(adapter), ['POST /auth/password/forgot']);

    await tester.enterText(find.byKey(const Key('reset_code')), '123456');
    await tester.enterText(
      find.byKey(const Key('reset_confirm_password')),
      'nova12345',
    );
    await tester.tap(find.byKey(const Key('reset_submit')));
    await tester.pumpAndSettle();

    // Voltou para a aba Voce ja logado (as duas telas fecharam).
    expect(find.byKey(const Key('auth_submit')), findsNothing);
    expect(find.byKey(const Key('profile_name')), findsOneWidget);
    expect(find.byKey(const Key('profile_signin')), findsNothing);
    expect((await store.read())!.token, 'tok-1');
    final resetIndex = paths(adapter)
        .toList()
        .indexOf('POST /auth/password/reset');
    expect(jsonDecode(adapter.bodies[resetIndex]), {
      'email': 'ana@exemplo.com',
      'code': '123456',
      'newPassword': 'nova12345',
    });
  });

  testWidgets('esqueci a senha: código errado mostra o erro e segue na tela', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      RouteAdapter({
        'POST /auth/password/forgot': (202, null),
        'POST /auth/password/reset': (
          400,
          {'error': 'código inválido ou expirado'},
        ),
      }),
    );
    await openSignIn(tester);
    await tester.tap(find.byKey(const Key('auth_forgot')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reset_email')),
      'ana@exemplo.com',
    );
    await tester.tap(find.byKey(const Key('reset_send')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reset_code')), '000000');
    await tester.enterText(
      find.byKey(const Key('reset_new_password')),
      'nova12345',
    );
    await tester.enterText(
      find.byKey(const Key('reset_confirm_password')),
      'nova12345',
    );
    await tester.tap(find.byKey(const Key('reset_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Código inválido ou expirado'), findsOneWidget);
    expect(find.byKey(const Key('reset_submit')), findsOneWidget);
    expect(await store.read(), isNull);
  });

  testWidgets('VOC-04: erro da recuperacao some ao editar o campo', (
    tester,
  ) async {
    await pumpApp(
      tester,
      RouteAdapter({
        'POST /auth/password/forgot': (202, null),
        'POST /auth/password/reset': (
          400,
          {'error': 'código inválido ou expirado'},
        ),
      }),
    );
    await openSignIn(tester);
    await tester.tap(find.byKey(const Key('auth_forgot')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reset_email')),
      'ana@exemplo.com',
    );
    await tester.tap(find.byKey(const Key('reset_send')));
    await tester.pumpAndSettle();
    Future<void> submitWrongCode() async {
      await tester.enterText(find.byKey(const Key('reset_code')), '000000');
      await tester.enterText(
        find.byKey(const Key('reset_new_password')),
        'nova12345',
      );
      await tester.enterText(
        find.byKey(const Key('reset_confirm_password')),
        'nova12345',
      );
      await tester.tap(find.byKey(const Key('reset_submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reset_error')), findsOneWidget);
    }

    await submitWrongCode();
    await tester.enterText(find.byKey(const Key('reset_code')), '111111');
    await tester.pump();
    expect(find.byKey(const Key('reset_error')), findsNothing);

    // Reenviar o codigo tambem limpa o erro anterior.
    await submitWrongCode();
    await tester.tap(find.byKey(const Key('reset_resend')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reset_error')), findsNothing);

    // Barrado na validacao: o erro antigo do servidor nao fica ao lado.
    await submitWrongCode();
    final confirm = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('reset_confirm_password')),
        matching: find.byType(TextField),
      ),
    );
    confirm.controller!.text = 'diferente';
    await tester.tap(find.byKey(const Key('reset_submit')));
    await tester.pumpAndSettle();
    expect(find.text('As senhas não conferem'), findsOneWidget);
    expect(find.byKey(const Key('reset_error')), findsNothing);
  });

  testWidgets(
    'trocar senha com a atual errada mostra o erro e continua logado',
    (tester) async {
      final adapter = RouteAdapter({
        'GET /me': (200, meJson),
        'POST /auth/password/change': (403, {'error': 'x'}),
      });
      final store = await pumpApp(
        tester,
        adapter,
        store: InMemorySessionStore(session()),
      );
      await openProfile(tester);
      await tapProfileItem(tester, 'profile_change_password');

      // Validacao local: nova curta e confirmacao diferente nao enviam nada.
      await tester.enterText(
        find.byKey(const Key('change_current')),
        'errada12',
      );
      await tester.enterText(find.byKey(const Key('change_new')), '123');
      await tester.enterText(find.byKey(const Key('change_confirm')), '456');
      await tester.tap(find.byKey(const Key('change_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Mínimo de 8 caracteres'), findsOneWidget);
      expect(find.text('As senhas não conferem'), findsOneWidget);
      expect(paths(adapter), isNot(contains('POST /auth/password/change')));

      await tester.enterText(find.byKey(const Key('change_new')), 'nova12345');
      await tester.enterText(
        find.byKey(const Key('change_confirm')),
        'nova12345',
      );
      await tester.tap(find.byKey(const Key('change_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('change_error')), findsOneWidget);
      expect(find.text('Senha atual incorreta'), findsOneWidget);
      final change = adapter.requests.lastWhere(
        (r) => r.uri.path == '/auth/password/change',
      );
      expect(change.headers['Authorization'], 'Bearer tok-1');

      await tester.tap(find.byKey(const Key('change_cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_name')), findsOneWidget);
      expect(await store.read(), isNotNull);
    },
  );

  testWidgets('trocar senha ok fecha o dialogo e segue no perfil', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      RouteAdapter({
        'GET /me': (200, meJson),
        'POST /auth/password/change': (204, null),
      }),
      store: InMemorySessionStore(session()),
    );
    await openProfile(tester);
    await tapProfileItem(tester, 'profile_change_password');
    await tester.enterText(
      find.byKey(const Key('change_current')),
      'velha1234',
    );
    await tester.enterText(find.byKey(const Key('change_new')), 'nova12345');
    await tester.enterText(
      find.byKey(const Key('change_confirm')),
      'nova12345',
    );
    await tester.tap(find.byKey(const Key('change_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('change_submit')), findsNothing);
    expect(find.text('Senha alterada'), findsOneWidget);
    expect(find.byKey(const Key('profile_name')), findsOneWidget);
    expect((await store.read())!.token, 'tok-1');
  });

  testWidgets('excluir conta pede a senha e volta deslogado', (tester) async {
    final adapter = RouteAdapter({
      'GET /me': (200, meJson),
      'DELETE /me': (204, null),
    });
    final store = await pumpApp(
      tester,
      adapter,
      store: InMemorySessionStore(session()),
    );
    await openProfile(tester);
    await tapProfileItem(tester, 'profile_delete_account');

    expect(find.byKey(const Key('delete_warning')), findsOneWidget);
    expect(find.textContaining('no servidor'), findsWidgets);
    expect(
      find.text('As atividades gravadas neste aparelho continuam nele.'),
      findsOneWidget,
    );

    // Sem senha nao envia.
    await tester.tap(find.byKey(const Key('delete_confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(paths(adapter), isNot(contains('DELETE /me')));

    await tester.enterText(
      find.byKey(const Key('delete_password')),
      'minhasenha',
    );
    await tester.tap(find.byKey(const Key('delete_confirm')));
    await tester.pumpAndSettle();

    // A aba Voce fica no estado deslogado.
    expect(find.byKey(const Key('delete_confirm')), findsNothing);
    expect(find.byKey(const Key('profile_signin')), findsOneWidget);
    expect(find.byKey(const Key('profile_name')), findsNothing);
    expect(await store.read(), isNull);
    final del = adapter.requests.lastWhere((r) => r.method == 'DELETE');
    expect(del.headers['Authorization'], 'Bearer tok-1');
  });

  testWidgets('excluir conta com senha errada mostra o erro e segue logado', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      RouteAdapter({
        'GET /me': (200, meJson),
        'DELETE /me': (403, {'error': 'x'}),
      }),
      store: InMemorySessionStore(session()),
    );
    await openProfile(tester);
    await tapProfileItem(tester, 'profile_delete_account');
    await tester.enterText(find.byKey(const Key('delete_password')), 'errada');
    await tester.tap(find.byKey(const Key('delete_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('delete_error')), findsOneWidget);
    expect(find.text('Senha incorreta'), findsOneWidget);
    expect(await store.read(), isNotNull);

    // Cancelar volta ao perfil, ainda logado.
    await tester.tap(find.byKey(const Key('delete_cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_name')), findsOneWidget);
  });

  testWidgets('sair de todos os aparelhos pede confirmacao e volta deslogado', (
    tester,
  ) async {
    final adapter = RouteAdapter({
      'GET /me': (200, meJson),
      'POST /auth/logout-all': (204, null),
    });
    final store = await pumpApp(
      tester,
      adapter,
      store: InMemorySessionStore(session()),
    );
    await openProfile(tester);

    // Cancelar nao faz nada.
    await tapProfileItem(tester, 'profile_logout_all');
    await tester.tap(find.byKey(const Key('logout_all_cancel')));
    await tester.pumpAndSettle();
    expect(paths(adapter), isNot(contains('POST /auth/logout-all')));
    expect(find.byKey(const Key('profile_name')), findsOneWidget);

    await tapProfileItem(tester, 'profile_logout_all');
    await tester.tap(find.byKey(const Key('logout_all_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_signin')), findsOneWidget);
    expect(find.byKey(const Key('profile_name')), findsNothing);
    expect(await store.read(), isNull);
    expect(paths(adapter), contains('POST /auth/logout-all'));
  });

  testWidgets('aba Você viva rele os totais quando a lista local muda', (
    tester,
  ) async {
    final adapter = RouteAdapter({'GET /me': (200, meJson)});
    await pumpApp(tester, adapter, store: InMemorySessionStore(session()));
    await openProfile(tester);
    int meCalls() => paths(adapter).where((p) => p == 'GET /me').length;
    final before = meCalls();

    // Salvar, apagar ou sincronizar invalida os recentes; o perfil segue.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    container.invalidate(recentActivitiesProvider);
    await tester.pumpAndSettle();

    expect(meCalls(), before + 1);
    expect(find.byKey(const Key('profile_count')), findsOneWidget);
  });
}
