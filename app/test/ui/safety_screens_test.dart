// Telas do Rastro Seguro (F08) contra o servidor falso: contatos (deslogado,
// convidar, erros, aceitar, remover com confirmacao), opcao no Gravar
// (deslogado, sem contato, escolha de contatos e horario), sino com contador
// e caixa de entrada (alerta com Ver localizacao, convite leva aos contatos,
// marcar como lida) e a busca periodica da caixa. Temas claro e escuro.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/safety/safety_providers.dart';
import 'package:strava_estudo_app/ui/safety/inbox_poller.dart';
import 'package:strava_estudo_app/ui/safety/inbox_screen.dart';
import 'package:strava_estudo_app/ui/safety/safety_setup.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../safety/fake_safety_server.dart';
import '../safety/safety_harness.dart';

void main() {
  late SafetyHarness h;
  late ProviderContainer container;

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// App minimo: uma tela inicial com o sino e a opcao do Gravar, mais as
  /// rotas do Rastro Seguro, dentro do InboxPoller.
  Future<void> pump(WidgetTester tester, {FakeUser? signedInAs, String initial = '/', ThemeData? theme}) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) {
            container = ProviderScope.containerOf(context);
            return const Scaffold(
              body: SafeArea(child: Column(children: [InboxBell(), SafetyEntry()])),
            );
          },
        ),
        ...safetyRoutes(),
        GoRoute(
          path: AppRoutes.auth,
          builder: (_, _) => const Scaffold(body: Text('tela de login')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: h.overrides(signedInAs: signedInAs),
        child: MaterialApp.router(
          theme: theme ?? AppTheme.dark,
          routerConfig: router,
          builder: (_, child) => InboxPoller(child: child!),
        ),
      ),
    );
    await drain(tester);
  }

  setUp(() => h = SafetyHarness(nowMs: 1000000));

  group('contatos', () {
    testWidgets('deslogado: convida a entrar', (tester) async {
      await pump(tester, initial: AppRoutes.safety);
      expect(find.byKey(const Key('safety_signed_out')), findsOneWidget);
      await tester.tap(find.byKey(const Key('safety_sign_in')));
      await drain(tester);
      expect(find.text('tela de login'), findsOneWidget);
    });

    testWidgets('convidar: pendente na lista; sem conta e repetido explicam', (tester) async {
      await pump(tester, signedInAs: h.ana, initial: AppRoutes.safety);
      await tester.enterText(find.byKey(const Key('safety_invite_email')), 'zz@x.com');
      await tester.tap(find.byKey(const Key('safety_invite_send')));
      await drain(tester);
      expect(find.textContaining('nao tem conta no Rastro'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('safety_invite_email')), 'bia@x.com');
      await tester.tap(find.byKey(const Key('safety_invite_send')));
      await drain(tester);
      expect(find.byKey(const Key('safety_invite_done')), findsOneWidget);
      final id = h.server.contacts.single['id'] as String;
      expect(find.byKey(Key('contact_$id')), findsOneWidget);
      expect(find.textContaining('Pendente'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('safety_invite_email')), 'bia@x.com');
      await tester.tap(find.byKey(const Key('safety_invite_send')));
      await drain(tester);
      expect(find.textContaining('ja foi convidada'), findsOneWidget);
    });

    testWidgets('limite de 3 aceitos desliga o convite', (tester) async {
      for (var i = 0; i < 3; i++) {
        h.server.linkAccepted(h.ana, h.server.addUser('t$i', 'u$i', 'c$i@x.com', 'C$i'));
      }
      await pump(tester, signedInAs: h.ana, initial: AppRoutes.safety, theme: AppTheme.light);
      expect(find.textContaining('3 contatos aceitos'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('safety_invite_send'))).onPressed, isNull);
    });

    testWidgets('convite recebido: aceitar; remover pede confirmacao', (tester) async {
      h.server.contacts.add({
        'id': 'ct_9',
        'ownerId': h.bia.id,
        'otherId': h.ana.id,
        'status': 'pending',
        'createdAt': 1,
      });
      await pump(tester, signedInAs: h.ana, initial: AppRoutes.safety);
      expect(find.byKey(const Key('contact_ct_9')), findsOneWidget);
      await tester.tap(find.byKey(const Key('contact_accept_ct_9')));
      await drain(tester);
      expect(h.server.contacts.single['status'], 'accepted');
      expect(find.textContaining('Aceito'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('contact_remove_ct_9'))).height, greaterThanOrEqualTo(44));

      await tester.tap(find.byKey(const Key('contact_remove_ct_9')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contact_remove_cancel')));
      await tester.pumpAndSettle();
      expect(h.server.contacts, hasLength(1));
      await tester.tap(find.byKey(const Key('contact_remove_ct_9')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contact_remove_confirm')));
      await drain(tester);
      expect(h.server.contacts, isEmpty);
      expect(find.byKey(const Key('contact_ct_9')), findsNothing);
    });
  });

  group('opcao no Gravar', () {
    testWidgets('deslogado e sem contato aceito: explica e deixa gravar sem', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('safety_entry')));
      await drain(tester);
      expect(find.byKey(const Key('safety_setup_signed_out')), findsOneWidget);
    });

    testWidgets('sem contato aceito leva a convidar', (tester) async {
      await pump(tester, signedInAs: h.ana);
      await tester.tap(find.byKey(const Key('safety_entry')));
      await drain(tester);
      expect(find.byKey(const Key('safety_setup_no_contacts')), findsOneWidget);
      await tester.tap(find.byKey(const Key('safety_setup_contacts')));
      await drain(tester);
      expect(find.byKey(const Key('safety_invite_email')), findsOneWidget);
    });

    testWidgets('sem rede: explica', (tester) async {
      await pump(tester, signedInAs: h.ana);
      h.server.offline = true;
      await tester.tap(find.byKey(const Key('safety_entry')));
      await drain(tester);
      expect(find.byKey(const Key('safety_setup_offline')), findsOneWidget);
    });

    testWidgets('escolhe contato e 45 min; sem contato marcado pede um', (tester) async {
      final id = h.server.linkAccepted(h.ana, h.bia);
      await pump(tester, signedInAs: h.ana, theme: AppTheme.light);
      await tester.tap(find.byKey(const Key('safety_entry')));
      await drain(tester);
      await tester.tap(find.byKey(const Key('safety_plan_confirm')));
      await tester.pump();
      expect(find.byKey(const Key('safety_plan_error')), findsOneWidget);
      await tester.tap(find.byKey(Key('safety_pick_$id')));
      await tester.tap(find.byKey(const Key('safety_eta_45')));
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('safety_eta_45'))).height, greaterThanOrEqualTo(44));
      await tester.tap(find.byKey(const Key('safety_plan_confirm')));
      await drain(tester);
      final plan = container.read(safetyPlanProvider)!;
      expect(plan.contactIds, [id]);
      expect(plan.minutes, 45);
      expect(find.text('Bia - chegada em 45 min'), findsOneWidget);
      await tester.tap(find.byKey(const Key('safety_entry_clear')));
      await tester.pump();
      expect(container.read(safetyPlanProvider), isNull);
    });
  });

  group('caixa de entrada', () {
    testWidgets('alerta: sino conta, destaque com nome e motivo, Ver localizacao abre e marca lida', (tester) async {
      h.server.notify(
        h.ana.id,
        'safety_alert',
        data: {'sessionId': 'ss_1', 'shareUrl': 'http://localhost:8081/s/abc', 'reason': 'eta', 'ownerName': 'Bia'},
      );
      await pump(tester, signedInAs: h.ana);
      expect(find.descendant(of: find.byKey(const Key('inbox_badge')), matching: find.text('1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('inbox_bell')));
      await drain(tester);
      final id = h.server.notifications.single['id'] as String;
      expect(find.text('Bia pode precisar de ajuda'), findsOneWidget);
      expect(find.textContaining('passou do horario previsto'), findsOneWidget);
      await tester.tap(find.byKey(Key('notification_location_$id')));
      await drain(tester);
      expect(h.opener.opened, ['http://localhost:8081/s/abc']);
      expect(h.server.notifications.single['readAt'], isNotNull);
      expect(container.read(inboxProvider).unread, 0);
    });

    testWidgets('convite: abrir leva aos contatos para aceitar', (tester) async {
      h.server.contacts.add({
        'id': 'ct_5',
        'ownerId': h.bia.id,
        'otherId': h.ana.id,
        'status': 'pending',
        'createdAt': 1,
      });
      h.server.notify(h.ana.id, 'contact_invite', title: 'Bia convidou voce');
      await pump(tester, signedInAs: h.ana, initial: AppRoutes.inbox, theme: AppTheme.light);
      final id = h.server.notifications.single['id'] as String;
      await tester.tap(find.byKey(Key('notification_accept_$id')));
      await drain(tester);
      expect(find.byKey(const Key('contact_accept_ct_5')), findsOneWidget);
    });

    testWidgets('deslogado: convida a entrar', (tester) async {
      await pump(tester, initial: AppRoutes.inbox);
      expect(find.byKey(const Key('inbox_signed_out')), findsOneWidget);
    });

    testWidgets('busca a cada tick e o sino atualiza', (tester) async {
      await pump(tester, signedInAs: h.ana);
      expect(find.byKey(const Key('inbox_badge')), findsNothing);
      expect(h.inboxTicker.intervals, [const Duration(seconds: 30)]);
      h.nowMs += 1000;
      h.server.notify(h.ana.id, 'safety_sos', data: {'ownerName': 'Bia', 'shareUrl': 'http://x/s/1'});
      h.inboxTicker.tick();
      await drain(tester);
      expect(find.byKey(const Key('inbox_badge')), findsOneWidget);
      expect(h.server.requestsTo('GET', '/notifications').last.query['since'], isNotNull);
    });
  });
}
