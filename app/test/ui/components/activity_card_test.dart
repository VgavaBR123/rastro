// Widget tests do ActivityCard, no tema escuro e no claro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/core/format/activity_labels.dart';
import 'package:strava_estudo_app/core/format/measures.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/components/activity_card.dart';
import 'package:strava_estudo_app/ui/components/sport_chip.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Activity activity(ActivityType t, {int hour = 7, String? title, String visibility = 'everyone'}) => Activity(
      guid: 'g1',
      title: title,
      activityType: t,
      startTimestampMs: DateTime(2026, 10, 26, hour, 5).millisecondsSinceEpoch,
      timerTimeMs: 1500000, // 25:00
      distanceMeters: 5000,
      isIndoor: false,
      isFinished: true,
      syncState: SyncState.pending,
      autoPauseEnabled: true,
      visibility: visibility,
    );

const route = [
  GeoPoint(latitude: 0, longitude: 0),
  GeoPoint(latitude: 0.001, longitude: 0.001),
];

Future<void> pump(WidgetTester tester, Widget card, {ThemeData? theme}) => tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: card)),
      ),
    );

void main() {
  test('titulo sugerido pelo horario', () {
    DateTime at(int h) => DateTime(2026, 10, 26, h);
    expect(suggestedActivityTitle(ActivityType.run, at(7)), 'Corrida da manha');
    expect(suggestedActivityTitle(ActivityType.ride, at(14)), 'Pedal da tarde');
    expect(suggestedActivityTitle(ActivityType.walk, at(21)), 'Caminhada da noite');
    expect(suggestedActivityTitle(ActivityType.walk, at(2)), 'Caminhada da noite');
  });

  test('separa valor e unidade', () {
    expect(splitMeasure('1,20 km'), ('1,20', 'km'));
    expect(splitMeasure('5:00 /km'), ('5:00', '/km'));
    expect(splitMeasure('25:00'), ('25:00', null));
  });

  for (final (name, theme) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('corrida mostra chip, titulo, metricas, rota e acoes ($name)', (tester) async {
      var opened = 0, shared = 0;
      await pump(
        tester,
        ActivityCard(
          activity: activity(ActivityType.run),
          useMetric: true,
          route: route,
          onOpen: () => opened++,
          onShare: () => shared++,
        ),
        theme: theme,
      );

      expect(find.byType(SportChip), findsOneWidget);
      expect(find.text('Corrida'), findsOneWidget);
      expect(find.text('26/10/2026 07:05'), findsOneWidget);
      expect(find.text('Corrida da manha'), findsOneWidget);
      expect(find.text('Distancia'), findsOneWidget);
      expect(find.text('Pace'), findsOneWidget);
      expect(find.text('Tempo'), findsOneWidget);
      expect(find.textContaining('5,00'), findsOneWidget);
      expect(find.text('5:00 /km'), findsOneWidget); // 25 min em 5 km
      expect(find.text('25:00'), findsOneWidget);

      // Rota na cor do esporte, com halo e ponto de partida.
      final preview = tester.widget<RoutePreview>(find.byType(RoutePreview));
      final colors = theme.extension<AppColors>() ?? AppColors.dark;
      expect(preview.color, colors.sport(ActivityType.run).fill);
      expect(preview.halo, isTrue);
      expect(preview.showStart, isTrue);

      await tester.tap(find.text('Ver detalhe'));
      await tester.tap(find.text('Compartilhar'));
      expect(opened, 1);
      expect(shared, 1);
    });
  }

  testWidgets('pedal mostra velocidade; unidade imperial respeitada', (tester) async {
    await pump(
      tester,
      ActivityCard(activity: activity(ActivityType.ride, hour: 15), useMetric: false, route: route),
      theme: AppTheme.light,
    );
    expect(find.text('Velocidade'), findsOneWidget);
    expect(find.text('Pace'), findsNothing);
    expect(find.textContaining('mph'), findsOneWidget); // 12 km/h = 7.5 mph
    expect(find.textContaining('7,5'), findsOneWidget);
    expect(find.textContaining('3,11'), findsOneWidget); // 5 km em milhas
    expect(find.text('Pedal da tarde'), findsOneWidget);
  });

  testWidgets('compacto: sem miniatura e sem botoes, toque abre', (tester) async {
    var opened = 0;
    await pump(
      tester,
      ActivityCard(
        activity: activity(ActivityType.walk),
        useMetric: true,
        compact: true,
        onOpen: () => opened++,
        trailing: const Icon(Icons.more_horiz, key: Key('extra')),
      ),
    );
    expect(find.byType(RoutePreview), findsNothing);
    expect(find.text('Ver detalhe'), findsNothing);
    expect(find.byKey(const Key('extra')), findsOneWidget);
    await tester.tap(find.text('Caminhada da manha'));
    expect(opened, 1);
  });

  // E2E-05: quem pode ver aparece quando nao e publica, inclusive no compacto.
  for (final (db, label, compact) in [
    ('private', 'So eu', false),
    ('followers', 'Seguidores', false),
    ('private', 'So eu', true),
  ]) {
    testWidgets('visibilidade $db aparece no cartao (compacto: $compact)', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(
        tester,
        ActivityCard(
          activity: activity(ActivityType.run, visibility: db),
          useMetric: true,
          route: route,
          compact: compact,
        ),
      );
      expect(find.byKey(const Key('visibility_badge')), findsOneWidget);
      // No compacto o cartao inteiro e um botao e junta os rotulos num no so.
      expect(find.bySemanticsLabel(RegExp('Quem pode ver: $label')), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('publica nao mostra selo de visibilidade', (tester) async {
    await pump(tester, ActivityCard(activity: activity(ActivityType.run), useMetric: true, route: route));
    expect(find.byKey(const Key('visibility_badge')), findsNothing);
  });

  testWidgets('titulo salvo pelo usuario substitui o sugerido', (tester) async {
    await pump(
      tester,
      ActivityCard(
        activity: activity(ActivityType.run, title: 'Longao de domingo'),
        useMetric: true,
        route: route,
      ),
    );
    expect(find.text('Longao de domingo'), findsOneWidget);
    expect(find.text('Corrida da manha'), findsNothing);
  });

  testWidgets('titulo salvo em branco cai no sugerido', (tester) async {
    await pump(
      tester,
      ActivityCard(activity: activity(ActivityType.run, title: '  '), useMetric: true, compact: true),
    );
    expect(find.text('Corrida da manha'), findsOneWidget);
  });

  testWidgets('sem pontos gravados mostra aviso na miniatura', (tester) async {
    await pump(
      tester,
      ActivityCard(activity: activity(ActivityType.run), useMetric: true, route: const []),
    );
    expect(find.text('Sem rota gravada'), findsOneWidget);
  });
}
