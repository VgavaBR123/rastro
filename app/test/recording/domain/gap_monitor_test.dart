// Gravacao blindada (F01): deteccao de lacunas pelo heartbeat. Dominio puro,
// relogio injetado pelos testes (ms de parede).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/gap_monitor.dart';

void main() {
  group('GapMonitor', () {
    test('batimentos e pontos regulares nao geram lacuna', () {
      final m = GapMonitor()..start(0);
      for (var t = 5000; t <= 60000; t += 5000) {
        expect(m.onTick(t), isNull);
        expect(m.onPoint(t + 1000), isNull);
      }
    });

    test('tick depois de mais de 30 s sem batimento: processo parado', () {
      final m = GapMonitor()..start(0);
      expect(m.onTick(5000), isNull);
      final gap = m.onTick(50000);
      expect(gap, isNotNull);
      expect(gap!.reason, GapReason.processStopped);
      expect(gap.startMs, 5000);
      expect(gap.endMs, 50000);
      expect(gap.durationMs, 45000);
      // O proximo tick normal nao repete a lacuna.
      expect(m.onTick(55000), isNull);
    });

    test('exatamente 30 s nao e lacuna (precisa passar do limite)', () {
      final m = GapMonitor()..start(0);
      expect(m.onTick(30000), isNull);
    });

    test(
      'processo vivo sem pontos por mais de 30 s: lacuna de GPS ao voltar',
      () {
        final m = GapMonitor()..start(0);
        expect(m.onPoint(1000), isNull);
        for (var t = 5000; t <= 40000; t += 5000) {
          expect(m.onTick(t), isNull);
        }
        expect(m.gpsSilent(40000), isTrue);
        final gap = m.onPoint(45000);
        expect(gap, isNotNull);
        expect(gap!.reason, GapReason.noGpsSignal);
        expect(gap.startMs, 1000);
        expect(gap.endMs, 45000);
        expect(m.gpsSilent(46000), isFalse);
      },
    );

    test('lacuna de processo nao vira tambem lacuna de GPS', () {
      final m = GapMonitor()..start(0);
      m.onPoint(1000);
      final gap = m.onTick(60000);
      expect(gap?.reason, GapReason.processStopped);
      // O ponto que chega logo depois nao abre outra lacuna sobreposta.
      expect(m.onPoint(61000), isNull);
    });

    test('ponto depois de processo congelado vira lacuna de processo', () {
      final m = GapMonitor()..start(0);
      m.onTick(5000);
      m.onPoint(5000);
      final gap = m.onPoint(70000);
      expect(gap?.reason, GapReason.processStopped);
      expect(gap?.startMs, 5000);
    });

    test('pausado nao detecta; ao retomar o relogio recomeca', () {
      final m = GapMonitor()..start(0);
      m.onTick(5000);
      m.setPaused(true, 6000);
      expect(m.onTick(100000), isNull);
      expect(m.gpsSilent(100000), isFalse);
      m.setPaused(false, 200000);
      expect(m.onTick(205000), isNull);
      expect(m.onPoint(206000), isNull);
    });

    test('setPaused repetido nao reinicia a contagem', () {
      final m = GapMonitor()..start(0);
      m.setPaused(false, 1000);
      m.setPaused(false, 2000);
      expect(m.onTick(40000), isNotNull);
    });

    test('sem start nao detecta nada', () {
      final m = GapMonitor();
      expect(m.onTick(100000), isNull);
      expect(m.onPoint(100000), isNull);
      expect(m.gpsSilent(100000), isFalse);
    });
  });

  group('gapAfterRestart', () {
    test('ultimo batimento antigo vira lacuna de processo encerrado', () {
      final gap = gapAfterRestart(
        lastBeatMs: 10000,
        paused: false,
        nowMs: 100000,
      );
      expect(gap?.reason, GapReason.processStopped);
      expect(gap?.startMs, 10000);
      expect(gap?.endMs, 100000);
    });

    test('pausado na hora do crash: sem lacuna', () {
      expect(
        gapAfterRestart(lastBeatMs: 10000, paused: true, nowMs: 100000),
        isNull,
      );
    });

    test('retomada rapida (ate 30 s): sem lacuna', () {
      expect(
        gapAfterRestart(lastBeatMs: 10000, paused: false, nowMs: 40000),
        isNull,
      );
    });

    test('sem batimento conhecido: sem lacuna', () {
      expect(
        gapAfterRestart(lastBeatMs: null, paused: false, nowMs: 40000),
        isNull,
      );
    });
  });

  group('GapMonitor.closeOpenGap', () {
    test('GPS mudo ao encerrar: fecha a lacuna aberta ate agora', () {
      final m = GapMonitor()..start(0);
      m.onPoint(1000);
      for (var t = 5000; t <= 300000; t += 5000) {
        m.onTick(t);
      }
      final gap = m.closeOpenGap(301000);
      expect(
        gap,
        const RecordingGap(
          startMs: 1000,
          endMs: 301000,
          reason: GapReason.noGpsSignal,
        ),
      );
      // Fechada uma vez: nao repete nem reabre.
      expect(m.gpsSilent(301000), isFalse);
      expect(m.closeOpenGap(302000), isNull);
    });

    test('GPS em dia: nada a fechar', () {
      final m = GapMonitor()..start(0);
      m.onPoint(20000);
      expect(m.closeOpenGap(40000), isNull);
    });

    test('pausado ou nunca iniciado: nada a fechar', () {
      expect(GapMonitor().closeOpenGap(100000), isNull);
      final m = GapMonitor()..start(0);
      m.setPaused(true, 1000);
      expect(m.closeOpenGap(100000), isNull);
    });
  });

  group('RecordingGap', () {
    test('motivo legivel', () {
      expect(gapReasonLabel(GapReason.processStopped), contains('encerrado'));
      expect(gapReasonLabel(GapReason.noGpsSignal), contains('GPS'));
    });
  });
}
