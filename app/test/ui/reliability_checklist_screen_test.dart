// Checklist "Gravacao confiavel" (F01): estado real (probe fake), acoes,
// releitura ao voltar ao app, modo antes da primeira gravacao e os dois temas.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/platform/reliability_probe.dart';
import 'package:strava_estudo_app/recording/domain/reliability_checklist.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';
import 'package:strava_estudo_app/ui/reliability_checklist_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

/// Configuracoes cujo "marcar visto" falha (banco fechado, disco cheio).
class FailingSettings extends SettingsController {
  FailingSettings(super.db);

  @override
  Future<void> markReliabilityChecklistSeen() async =>
      throw StateError('disco cheio');
}

class FakeProbe implements ReliabilityProbe {
  ReliabilitySnapshot snapshot;
  final List<ChecklistAction> ran = [];
  int reads = 0;

  /// O que a acao muda no aparelho (simula o usuario ajustando).
  ReliabilitySnapshot Function(ReliabilitySnapshot, ChecklistAction)? effect;

  /// Segura a acao ate o teste liberar (simula o usuario nos ajustes).
  Completer<void>? hold;

  FakeProbe(this.snapshot, {this.effect});

  @override
  Future<ReliabilitySnapshot> read() async {
    reads++;
    return snapshot;
  }

  @override
  Future<bool> run(ChecklistAction action) async {
    ran.add(action);
    if (hold != null) await hold!.future;
    if (effect != null) snapshot = effect!(snapshot, action);
    return true;
  }
}

const _android = ReliabilitySnapshot(
  platform: DevicePlatform.android,
  manufacturer: 'Xiaomi',
  batteryOptimizationIgnored: false,
  location: LocationAccess.whileInUse,
  preciseLocation: true,
  notificationsGranted: true,
);

void main() {
  late RecordingDatabase db;
  setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester,
    FakeProbe probe, {
    bool firstRun = false,
    ThemeData? theme,
    List<Object?>? popped,
    bool failingSettings = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          reliabilityProbeProvider.overrideWithValue(probe),
          if (failingSettings)
            settingsProvider.overrideWith((ref) => FailingSettings(db)),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final r = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => ReliabilityChecklistScreen(
                        beforeFirstRecording: firstRun,
                      ),
                    ),
                  );
                  popped?.add(r);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o estado real e a acao da bateria abre o ajuste', (
    tester,
  ) async {
    final probe = FakeProbe(
      _android,
      effect: (s, a) => a == ChecklistAction.openBatterySettings
          ? s.copyWith(batteryOptimizationIgnored: true)
          : s,
    );
    await pump(tester, probe);

    expect(find.text('Gravacao confiavel'), findsOneWidget);
    expect(find.byKey(const Key('reliability_item_battery')), findsOneWidget);
    expect(
      find.byKey(const Key('reliability_item_manufacturer')),
      findsOneWidget,
    );
    expect(find.text('Ajustes do Xiaomi'), findsOneWidget);
    expect(find.textContaining('Inicio automatico'), findsOneWidget);
    expect(find.byKey(const Key('reliability_summary')), findsOneWidget);
    expect(find.textContaining('1 ajuste'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('reliability_action_battery')),
    );
    await tester.tap(find.byKey(const Key('reliability_action_battery')));
    await tester.pumpAndSettle();
    expect(probe.ran, [ChecklistAction.openBatterySettings]);
    // Releu depois da acao: agora esta ok e o botao sumiu.
    expect(find.byKey(const Key('reliability_action_battery')), findsNothing);
    expect(find.text('Tudo pronto para gravar'), findsOneWidget);
  });

  testWidgets('ao voltar para o app (resumed) relê o estado', (tester) async {
    final probe = FakeProbe(_android);
    await pump(tester, probe);
    final before = probe.reads;
    probe.snapshot = probe.snapshot.copyWith(batteryOptimizationIgnored: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(probe.reads, greaterThan(before));
    expect(find.text('Tudo pronto para gravar'), findsOneWidget);
  });

  testWidgets(
    'antes da primeira gravacao: Continuar marca visto e volta true',
    (tester) async {
      final probe = FakeProbe(_android);
      final popped = <Object?>[];
      await pump(tester, probe, firstRun: true, popped: popped);
      final cont = find.byKey(const Key('reliability_continue'));
      expect(cont, findsOneWidget);
      expect(tester.getSize(cont).height, greaterThanOrEqualTo(44));
      await tester.ensureVisible(cont);
      await tester.tap(cont);
      await tester.pumpAndSettle();
      expect(popped, [true]);
      await tester.runAsync(() async {
        expect((await db.loadSettings()).reliabilityChecklistSeen, isTrue);
      });
    },
  );

  testWidgets('pelas configuracoes nao tem Continuar', (tester) async {
    await pump(tester, FakeProbe(_android));
    expect(find.byKey(const Key('reliability_continue')), findsNothing);
  });

  testWidgets('iOS: so localizacao e precisao, tema claro', (tester) async {
    final probe = FakeProbe(
      const ReliabilitySnapshot(
        platform: DevicePlatform.ios,
        location: LocationAccess.whileInUse,
        preciseLocation: true,
      ),
    );
    await pump(tester, probe, theme: AppTheme.light);
    expect(find.byKey(const Key('reliability_item_battery')), findsNothing);
    expect(
      find.byKey(const Key('reliability_item_notifications')),
      findsNothing,
    );
    expect(find.byKey(const Key('reliability_item_location')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('reliability_action_location')),
    );
    await tester.tap(find.byKey(const Key('reliability_action_location')));
    await tester.pumpAndSettle();
    expect(probe.ran, [ChecklistAction.openAppSettings]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sair da tela durante a acao nao usa o ref depois do dispose', (
    tester,
  ) async {
    final probe = FakeProbe(_android)..hold = Completer<void>();
    await pump(tester, probe);
    await tester.ensureVisible(
      find.byKey(const Key('reliability_action_battery')),
    );
    await tester.tap(find.byKey(const Key('reliability_action_battery')));
    await tester.pump();
    final readsBefore = probe.reads;
    // A pessoa volta antes de a acao terminar: a tela e desmontada.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ReliabilityChecklistScreen), findsNothing);
    probe.hold!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(probe.reads, readsBefore);
  });

  testWidgets('falha ao marcar visto nao trava o Continuar para gravar', (
    tester,
  ) async {
    final popped = <Object?>[];
    await pump(
      tester,
      FakeProbe(_android),
      firstRun: true,
      popped: popped,
      failingSettings: true,
    );
    final cont = find.byKey(const Key('reliability_continue'));
    await tester.ensureVisible(cont);
    await tester.tap(cont);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Salvar o "visto" nao pode impedir a gravacao: segue para gravar (o
    // checklist so volta a aparecer na proxima vez).
    expect(popped, [true]);
  });
}
