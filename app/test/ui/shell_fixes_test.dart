// Correcoes achadas no teste manual no emulador: editar o nome derrubava a
// tela (controller descartado com o dialogo ainda saindo), a navegacao subia
// com o teclado e os avisos passavam de uma aba para outra.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/ui/components/app_nav_bar.dart';
import 'package:strava_estudo_app/ui/profile_screen.dart';

import '../auth/auth_test.dart' show RouteAdapter, meJson, session;
import 'auth_flow_test.dart' show openProfile, pumpApp;

void main() {
  testWidgets('editar o nome e salvar nao quebra a tela', (tester) async {
    final adapter = RouteAdapter({
      'GET /me': (200, meJson),
      'PATCH /me': (200, meJson),
    });
    await pumpApp(tester, adapter, store: InMemorySessionStore(session()));
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('profile_edit_name')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile_name_field')), 'Ana Nova');
    await tester.tap(find.byKey(const Key('profile_name_save')));
    // Inclui a animacao de saida do dialogo, onde o erro acontecia.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byKey(const Key('profile_name_field')), findsNothing);
  });

  testWidgets('a navegacao some com o teclado aberto', (tester) async {
    await pumpApp(tester, RouteAdapter({}));
    expect(find.byType(AppNavBar), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(AppNavBar), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(AppNavBar), findsOneWidget);
  });

  testWidgets('trocar de aba fecha o aviso da aba anterior', (tester) async {
    await pumpApp(tester, RouteAdapter({}));
    final messenger = ScaffoldMessenger.of(
      tester.element(find.byType(AppNavBar)),
    );
    messenger.showSnackBar(const SnackBar(content: Text('aviso do inicio')));
    await tester.pumpAndSettle();
    expect(find.text('aviso do inicio'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_stats')));
    await tester.pumpAndSettle();
    expect(find.text('aviso do inicio'), findsNothing);
  });

  testWidgets('aviso nas abas fica acima da navegacao', (tester) async {
    await pumpApp(tester, RouteAdapter({}));
    final ctx = tester.element(find.byKey(const Key('home_empty')));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('acima')));
    await tester.pumpAndSettle();

    // O widget SnackBar inclui a propria margem; mede o conteudo.
    final snackBottom = tester.getBottomLeft(find.text('acima')).dy;
    final navTop = tester.getTopLeft(find.byType(AppNavBar)).dy;
    expect(snackBottom, lessThanOrEqualTo(navTop));
  });
}
