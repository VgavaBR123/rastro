// Configuracoes > Gravacao confiavel (F01): o checklist e sempre acessivel.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

void main() {
  testWidgets('item Gravacao confiavel abre o checklist sem Continuar', (
    tester,
  ) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const SettingsScreen(),
        ),
        reliabilityRoute(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const Key('reliability_checklist'));
    expect(tile, findsOneWidget);
    expect(tester.getSize(tile).height, greaterThanOrEqualTo(44));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Gravacao confiavel'), findsWidgets);
    expect(find.byKey(const Key('reliability_summary')), findsOneWidget);
    expect(find.byKey(const Key('reliability_continue')), findsNothing);
  });
}
