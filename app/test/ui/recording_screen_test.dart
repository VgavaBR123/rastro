// Widget test da RecordingScreen com providers sobrescritos (fonte fake + DB em
// memoria). Verifica que a tela inicia a gravacao e renderiza metricas e controles.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';

class _FakeSource implements LocationSource {
  final _c = StreamController<LocationSample>();
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Stream<LocationSample> positions() => _c.stream;
  @override
  Future<void> stop() async => _c.close();
}

void main() {
  testWidgets('RecordingScreen inicia e mostra metricas e controles', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        locationSourceProvider.overrideWithValue(_FakeSource()),
        recordingDatabaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(
        home: RecordingScreen(activityType: ActivityType.run),
      ),
    ));

    // Deixa o postFrameCallback iniciar a gravacao.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Rotulos das metricas e controles presentes.
    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Pace'), findsOneWidget);
    expect(find.text('Elevacao'), findsOneWidget);
    expect(find.byKey(const Key('pause')), findsOneWidget);
    expect(find.byKey(const Key('stop')), findsOneWidget);
  });
}
