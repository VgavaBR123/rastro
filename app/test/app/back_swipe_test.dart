// INI-01 (teste no iPhone, 30/10/2026): as telas que abrem por cima do shell
// voltam com o gesto da borda esquerda no iOS, como a tela Compartilhar.
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/auth_screen.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Future<GoRouter> pumpApp(WidgetTester tester) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final router = buildAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Arrasta da borda esquerda ate 3/4 da largura (passa da metade, que e onde
/// o iOS decide voltar sem precisar de velocidade).
Future<void> edgeSwipe(WidgetTester tester) async {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final g = await tester.startGesture(const Offset(4, 300));
  for (var i = 0; i < 20; i++) {
    await g.moveBy(Offset(width * 0.75 / 20, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, location, screen) in [
    ('Entrar', AppRoutes.auth, AuthScreen),
    ('Ajustes', AppRoutes.settings, SettingsScreen),
  ]) {
    testWidgets('$name volta com o gesto da borda no iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final router = await pumpApp(tester);
        router.push(location);
        await tester.pumpAndSettle();
        expect(find.byType(screen), findsOneWidget);

        await edgeSwipe(tester);
        expect(find.byType(screen), findsNothing);
        expect(router.state.uri.path, AppRoutes.home);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
