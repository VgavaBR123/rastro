// INI-16 (teste no iPhone, 30/10/2026): no iOS os dialogos de confirmacao
// sao os do sistema (Cupertino) e o icone de voltar e o mesmo chevron em
// todas as telas; no Android segue o Material.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/ui/activity_detail_screen.dart';
import 'package:strava_estudo_app/ui/history_screen.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../auth/auth_test.dart' show RouteAdapter, meJson, session;
import 'account_flow_test.dart' show tapProfileItem;
import 'auth_flow_test.dart' show openProfile, pumpApp;
import 'history_screen_test.dart' show seededDb;

/// Roda [body] com a plataforma dada e devolve a original no fim.
Future<void> naPlataforma(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<void> abrirHistorico(WidgetTester tester) async {
  final db = await seededDb();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: AppTheme.dark, home: const HistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('menu-a')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('delete-a')));
  await tester.pumpAndSettle();
}

Future<void> abrirDetalhe(WidgetTester tester) async {
  final db = await seededDb();
  addTearDown(db.close);
  final activity = (await RecordingRepository(db).recent()).first;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: ActivityDetailScreen(activity: activity),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

IconData iconeDe(WidgetTester tester, Key key) => tester
    .widget<Icon>(
      find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
    )
    .icon!;

/// AlertDialog.adaptive cria uma subclasse; byType so acha o tipo exato.
final alertDialog = find.byWidgetPredicate((w) => w is AlertDialog);

void main() {
  testWidgets('iOS: excluir atividade usa o dialogo do sistema', (
    tester,
  ) async {
    await naPlataforma(TargetPlatform.iOS, () async {
      await abrirHistorico(tester);
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Excluir atividade?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.text('Excluir atividade?'), findsNothing);
    });
  });

  testWidgets('Android: excluir atividade segue no AlertDialog', (
    tester,
  ) async {
    await abrirHistorico(tester);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(alertDialog, findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-delete')));
    await tester.pumpAndSettle();
    expect(alertDialog, findsNothing);
  });

  testWidgets('iOS: sair de todos os aparelhos usa o dialogo do sistema', (
    tester,
  ) async {
    await naPlataforma(TargetPlatform.iOS, () async {
      await pumpApp(
        tester,
        RouteAdapter({'GET /me': (200, meJson)}),
        store: InMemorySessionStore(session()),
      );
      await openProfile(tester);
      await tapProfileItem(tester, 'profile_logout_all');
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);

      await tester.tap(find.byKey(const Key('logout_all_cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.byKey(const Key('profile_name')), findsOneWidget);
    });
  });

  testWidgets('iOS: voltar do Detalhe e o mesmo chevron do AppBar', (
    tester,
  ) async {
    await naPlataforma(TargetPlatform.iOS, () async {
      await abrirDetalhe(tester);
      expect(
        iconeDe(tester, const Key('detailBack')),
        Icons.arrow_back_ios_new_rounded,
      );
    });
  });

  testWidgets('Android: voltar do Detalhe e a seta do AppBar', (tester) async {
    await abrirDetalhe(tester);
    expect(iconeDe(tester, const Key('detailBack')), Icons.arrow_back);
  });

  testWidgets('iOS: switch da pausa automática continua alternando', (
    tester,
  ) async {
    await naPlataforma(TargetPlatform.iOS, () async {
      final db = await seededDb();
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recordingDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final antes = (await db.loadSettings()).autoPauseEnabled;
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect((await db.loadSettings()).autoPauseEnabled, !antes);
    });
  });
}
