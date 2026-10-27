// Testes da pausa automatica por acelerometro (corrida), com sinais
// sinteticos: corrida = senoide de ~2,8 Hz com alguns m/s^2 + ruido; parado =
// ruido pequeno; tremor = ruido + vibracao fraca de ~9 Hz.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/motion_auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

const double g = 9.80665;

/// Fallback controlavel: devolve [valor] e conta as chamadas.
class FallbackFixo implements AutoPauseDetector {
  bool valor;
  int chamadas = 0;
  int resets = 0;
  FallbackFixo(this.valor);
  @override
  bool shouldBePaused(LocationSample sample) {
    chamadas++;
    return valor;
  }

  @override
  void reset() => resets++;
}

LocationSample loc(int t, {double? speed}) => LocationSample(
  position: const GeoPoint(latitude: 0, longitude: 0),
  wallClockMs: t,
  monotonicMs: t,
  horizontalAccuracyMeters: 5,
  speedMetersPerSecond: speed,
);

typedef Sinal = AccelSample Function(int t);

/// Corrida: eixo vertical com gravidade + impacto de passada; lateral com
/// metade da frequencia; ruido em todos os eixos.
Sinal corrida(math.Random r, {double hz = 2.8, double amp = 4.0}) => (int t) {
  final double s = t / 1000.0;
  return AccelSample(
    t,
    1.5 * math.sin(2 * math.pi * hz / 2 * s) + _ruido(r, 0.3),
    g + amp * math.sin(2 * math.pi * hz * s) + _ruido(r, 0.3),
    _ruido(r, 0.3),
  );
};

/// Telefone apoiado: so ruido do sensor, com um pequeno vies de calibracao.
Sinal parado(math.Random r) =>
    (int t) => AccelSample(
      t,
      _ruido(r, 0.03),
      g + 0.12 + _ruido(r, 0.03),
      _ruido(r, 0.03),
    );

/// Telefone na mao, pessoa parada: tremor fisiologico (~9 Hz) + balanco.
Sinal tremor(math.Random r) => (int t) {
  final double s = t / 1000.0;
  final double v = 0.2 * math.sin(2 * math.pi * 9 * s);
  return AccelSample(
    t,
    0.3 + v + _ruido(r, 0.1),
    g * 0.95 + v + _ruido(r, 0.1),
    2.0 + 0.1 * math.sin(2 * math.pi * 0.3 * s) + _ruido(r, 0.1),
  );
};

double _ruido(math.Random r, double a) => (r.nextDouble() * 2 - 1) * a;

/// Instantes de amostragem em [de, ate) com periodo medio [periodoMs] e
/// jitter relativo [jitter] (0,3 = +-30%).
List<int> instantes(
  int de,
  int ate,
  int periodoMs,
  math.Random r, {
  double jitter = 0,
}) {
  final List<int> ts = [];
  double t = de.toDouble();
  while (t < ate) {
    ts.add(t.round());
    t += periodoMs * (1 + (r.nextDouble() * 2 - 1) * jitter);
  }
  return ts;
}

/// Uma fase do cenario: de [de] ate [ate] ms com o sinal dado (null = sem
/// acelerometro).
class Fase {
  final int de;
  final int ate;
  final Sinal? sinal;
  Fase(this.de, this.ate, this.sinal);
}

/// Roda o cenario; consulta o detector a cada [consultaMs] (como se chegasse
/// um ponto de GPS) e devolve o mapa instante -> pausado.
Map<int, bool> simular(
  MotionAutoPauseDetector d,
  List<Fase> fases, {
  int periodoMs = 20,
  double jitter = 0,
  int consultaMs = 250,
  int seed = 7,
}) {
  final math.Random r = math.Random(seed);
  final List<AccelSample> amostras = [];
  for (final Fase f in fases) {
    final Sinal? s = f.sinal;
    if (s == null) continue;
    for (final int t in instantes(f.de, f.ate, periodoMs, r, jitter: jitter)) {
      amostras.add(s(t));
    }
  }
  final int fim = fases.map((f) => f.ate).reduce(math.max);
  final Map<int, bool> saida = {};
  int i = 0;
  for (int q = consultaMs; q <= fim; q += consultaMs) {
    while (i < amostras.length && amostras[i].monotonicMs <= q) {
      d.addAccel(amostras[i++]);
    }
    saida[q] = d.shouldBePaused(loc(q));
  }
  return saida;
}

/// Primeiro instante >= [desde] com o valor [v], ou null.
int? primeiro(Map<int, bool> m, bool v, {int desde = 0}) {
  for (final MapEntry<int, bool> e in m.entries) {
    if (e.key >= desde && e.value == v) return e.key;
  }
  return null;
}

void main() {
  group('decisao pelo acelerometro', () {
    test('corrida continua nao pausa (fallback diria pausado)', () {
      final d = MotionAutoPauseDetector(fallback: FallbackFixo(true));
      final m = simular(d, [Fase(0, 120000, corrida(math.Random(1)))]);
      // Depois do aquecimento (1 s + folga), so vale o acelerometro.
      final pausas = m.entries.where((e) => e.key >= 2000 && e.value);
      expect(pausas, isEmpty);
    });

    test('parado pausa apos o tempo minimo, nao antes', () {
      final d = MotionAutoPauseDetector(fallback: FallbackFixo(false));
      final m = simular(d, [
        Fase(0, 30000, corrida(math.Random(1))),
        Fase(30000, 60000, parado(math.Random(2))),
      ]);
      expect(primeiro(m, true), isNotNull);
      final int t = primeiro(m, true)!;
      // Pelo menos o tempo de espera (4 s), e no maximo ~8 s apos parar.
      expect(
        t - 30000,
        greaterThanOrEqualTo(MotionAutoPauseDetector.stillHoldMs),
      );
      expect(t - 30000, lessThanOrEqualTo(8000));
      // E fica pausado.
      expect(m.entries.where((e) => e.key >= t && !e.value), isEmpty);
    });

    test('retoma rapido ao voltar a correr', () {
      final d = MotionAutoPauseDetector(fallback: FallbackFixo(true));
      final m = simular(d, [
        Fase(0, 20000, corrida(math.Random(1))),
        Fase(20000, 50000, parado(math.Random(2))),
        Fase(50000, 70000, corrida(math.Random(3))),
      ]);
      expect(m[49750], isTrue);
      final int? volta = primeiro(m, false, desde: 50000);
      expect(volta, isNotNull);
      expect(volta! - 50000, lessThanOrEqualTo(2500));
      expect(m.entries.where((e) => e.key >= volta && e.value), isEmpty);
    });

    test('taxa irregular: 5 Hz e 50 Hz dao a mesma decisao', () {
      Map<int, bool> rodar(int periodo) => simular(
        MotionAutoPauseDetector(fallback: FallbackFixo(false)),
        [
          Fase(0, 30000, corrida(math.Random(1))),
          Fase(30000, 60000, parado(math.Random(2))),
          Fase(60000, 90000, corrida(math.Random(3))),
        ],
        periodoMs: periodo,
        jitter: 0.3,
        seed: periodo,
      );
      final lento = rodar(200); // ~5 Hz
      final rapido = rodar(20); // ~50 Hz

      for (final m in [lento, rapido]) {
        expect(
          m.entries.where((e) => e.key >= 2000 && e.key < 30000 && e.value),
          isEmpty,
        );
        expect(m[59750], isTrue);
        expect(m[89750], isFalse);
      }
      final int pl = primeiro(lento, true)!;
      final int pr = primeiro(rapido, true)!;
      expect((pl - pr).abs(), lessThanOrEqualTo(1000));
      final int rl = primeiro(lento, false, desde: 60000)!;
      final int rr = primeiro(rapido, false, desde: 60000)!;
      expect((rl - rr).abs(), lessThanOrEqualTo(1000));
      // Fora das transicoes, as decisoes coincidem.
      final int diferentes = lento.keys
          .where((k) => k >= 2000 && lento[k] != rapido[k])
          .length;
      expect(diferentes, lessThanOrEqualTo(8)); // <= 2 s de 90 s
    });

    test('telefone parado na mao com tremor nao conta como corrida', () {
      final d = MotionAutoPauseDetector(fallback: FallbackFixo(false));
      final m = simular(d, [Fase(0, 60000, tremor(math.Random(4)))]);
      final int? t = primeiro(m, true);
      expect(t, isNotNull);
      expect(t!, lessThanOrEqualTo(8000));
      expect(m.entries.where((e) => e.key >= t && !e.value), isEmpty);
    });

    test(
      'para de correr segurando o telefone com tremor: pausa e nao retoma',
      () {
        final d = MotionAutoPauseDetector(fallback: FallbackFixo(false));
        final m = simular(d, [
          Fase(0, 30000, corrida(math.Random(1))),
          Fase(30000, 90000, tremor(math.Random(4))),
        ]);
        final int t = primeiro(m, true, desde: 30000)!;
        expect(t - 30000, lessThanOrEqualTo(8000));
        expect(m.entries.where((e) => e.key >= t && !e.value), isEmpty);
      },
    );

    test('vies de calibracao do sensor nao vira movimento', () {
      // Sensor que le 10,4 m/s^2 parado: o passa-alta absorve o vies.
      final d = MotionAutoPauseDetector(fallback: FallbackFixo(false));
      final r = math.Random(5);
      final m = simular(d, [
        Fase(
          0,
          30000,
          (t) => AccelSample(t, _ruido(r, 0.03), 10.4 + _ruido(r, 0.03), 0),
        ),
      ]);
      expect(m[29750], isTrue);
    });
  });

  group('fallback por velocidade', () {
    test('sem acelerometro, a decisao e do fallback', () {
      final f = FallbackFixo(false);
      final d = MotionAutoPauseDetector(fallback: f);
      expect(d.shouldBePaused(loc(1000)), isFalse);
      f.valor = true;
      expect(d.shouldBePaused(loc(2000)), isTrue);
      expect(f.chamadas, 2);
    });

    test('o fallback e alimentado mesmo quando o acelerometro decide', () {
      final f = FallbackFixo(true);
      final d = MotionAutoPauseDetector(fallback: f);
      final m = simular(d, [
        Fase(0, 10000, corrida(math.Random(1))),
      ], consultaMs: 1000);
      expect(f.chamadas, m.length);
    });

    test('durante o aquecimento vale o fallback', () {
      final f = FallbackFixo(true);
      final d = MotionAutoPauseDetector(fallback: f);
      d.addAccel(const AccelSample(0, 0, g, 0));
      d.addAccel(const AccelSample(500, 0, g + 3, 0));
      expect(d.shouldBePaused(loc(500)), isTrue);
    });

    test('acelerometro que para de chegar volta ao fallback', () {
      final f = FallbackFixo(true);
      final d = MotionAutoPauseDetector(fallback: f);
      final m = simular(d, [
        Fase(0, 20000, corrida(math.Random(1))),
        Fase(20000, 40000, null),
      ]);
      expect(m[20000], isFalse); // ainda o acelerometro (corrida)
      expect(m[21500], isFalse); // 1,5 s sem accel: ainda confia
      expect(m[22500], isTrue); // > 2 s sem accel: fallback
      expect(m[40000], isTrue);
    });

    test('accel que volta depois do buraco reaquece e herda o estado', () {
      final f = FallbackFixo(true);
      final d = MotionAutoPauseDetector(fallback: f);
      final m = simular(d, [
        Fase(0, 10000, corrida(math.Random(1))),
        Fase(10000, 20000, null),
        Fase(20000, 40000, corrida(math.Random(2))),
      ]);
      expect(m[15000], isTrue); // fallback
      // Volta: herdou "pausado" do fallback e retoma pela corrida.
      final int volta = primeiro(m, false, desde: 20000)!;
      expect(volta - 20000, lessThanOrEqualTo(2500));
    });

    test('reset limpa o estado e repassa ao fallback', () {
      final f = FallbackFixo(false);
      final d = MotionAutoPauseDetector(fallback: f);
      final m = simular(d, [Fase(0, 20000, parado(math.Random(2)))]);
      expect(m[20000], isTrue);
      d.reset();
      expect(f.resets, 1);
      expect(d.shouldBePaused(loc(20250)), isFalse); // sem accel -> fallback
    });
  });

  group('autoPauseFor', () {
    test('corrida usa acelerometro com fallback por velocidade', () {
      final d = autoPauseFor(ActivityType.run);
      expect(d, isA<MotionAutoPauseDetector>());
      expect(
        (d as MotionAutoPauseDetector).fallback,
        isA<SpeedAutoPauseDetector>(),
      );
    });

    test('corrida sem acelerometro pausa pela velocidade', () {
      final d = autoPauseFor(ActivityType.run);
      expect(d.shouldBePaused(loc(0, speed: 0)), isFalse);
      expect(d.shouldBePaused(loc(3000, speed: 0)), isTrue);
      expect(d.shouldBePaused(loc(4000, speed: 3)), isFalse);
    });

    test('pedal e caminhada continuam por velocidade', () {
      expect(autoPauseFor(ActivityType.ride), isA<SpeedAutoPauseDetector>());
      expect(autoPauseFor(ActivityType.walk), isA<SpeedAutoPauseDetector>());
    });
  });
}
