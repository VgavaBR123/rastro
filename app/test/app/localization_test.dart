// INI-06 (teste no iPhone, 30/10/2026): os rotulos que vem do Material (o
// voltar dos Ajustes era lido "Back") saem em portugues do Brasil.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/main.dart';
import 'package:strava_estudo_app/persistence/database.dart';

void main() {
  testWidgets('App usa pt-BR e o voltar dos Ajustes se chama Voltar', (
    tester,
  ) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordingDatabaseProvider.overrideWithValue(db)],
        child: const StravaEstudoApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Navigator).first);
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Voltar');

    final container = ProviderScope.containerOf(context);
    final GoRouter router = container.read(appRouterProvider);
    router.push(AppRoutes.settings);
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });
}
