// Relogio do plano (F06): o relogio nativo que conta o sono do aparelho
// (Android SystemClock.elapsedRealtime, iOS CLOCK_MONOTONIC) e o fallback no
// relogio de parede com limite de sanidade.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_clock.dart';
import 'package:strava_estudo_app/plan5k/plan_time_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(kPlanClockChannel);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('usa o elapsedRealtime nativo, sem limite de salto', () async {
    var t = 1000;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'elapsedRealtime');
      return t;
    });
    final src = NativeElapsedTimeSource(fallback: FunctionTimeSource(() => -1));
    expect(await src.nowMs(), 1000);
    t = 5000000; // CPU dormiu ~83 min: conta
    expect(await src.nowMs(), 5000000);
    expect(src.maxStepMs, isNull);
    expect(src.usingFallback, isFalse);
  });

  test('sem canal nativo cai no relogio de parede com limite de 30 min', () async {
    // Sem handler: MissingPluginException.
    final src = NativeElapsedTimeSource(fallback: FunctionTimeSource(() => 42, maxStepMs: kWallClockMaxStepMs));
    expect(await src.nowMs(), 42);
    expect(src.usingFallback, isTrue);
    expect(src.maxStepMs, kWallClockMaxStepMs);
    expect(kWallClockMaxStepMs, 30 * 60000);
    // Continua no fallback mesmo se o canal aparecer depois (a base nao muda
    // no meio da sessao).
    messenger.setMockMethodCallHandler(channel, (call) async => 999999);
    expect(await src.nowMs(), 42);
  });

  test('relogio do plano: salto negativo ou acima do limite nao conta e e registrado', () {
    final c = PlanClock();
    c.observe(0, paused: false, maxStepMs: kWallClockMaxStepMs);
    c.observe(60000, paused: false, maxStepMs: kWallClockMaxStepMs);
    expect(c.elapsedMs, 60000);
    // Ajuste do relogio para tras: nao desconta.
    c.observe(10000, paused: false, maxStepMs: kWallClockMaxStepMs);
    expect(c.elapsedMs, 60000);
    expect(c.ignoredSteps, 1);
    // Daqui conta a partir do novo instante.
    c.observe(20000, paused: false, maxStepMs: kWallClockMaxStepMs);
    expect(c.elapsedMs, 70000);
    // Salto de 2 h para frente: nao conta.
    c.observe(20000 + 2 * 3600000, paused: false, maxStepMs: kWallClockMaxStepMs);
    expect(c.elapsedMs, 70000);
    expect(c.ignoredSteps, 2);
    c.observe(20000 + 2 * 3600000 + 1000, paused: false, maxStepMs: kWallClockMaxStepMs);
    expect(c.elapsedMs, 71000);
  });

  test('sem limite (relogio nativo), um salto grande conta inteiro', () {
    final c = PlanClock();
    c.observe(0, paused: false);
    c.observe(2 * 3600000, paused: false);
    expect(c.elapsedMs, 2 * 3600000);
    expect(c.ignoredSteps, 0);
  });
}
