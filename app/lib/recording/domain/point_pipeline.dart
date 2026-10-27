/// Pipeline de processamento de cada amostra de localizacao.
///
/// Clean room a partir de relatorios/03-gravacao-gps.md (secoes "esteira de
/// processamento", "portao de sanidade" e "filtragem de ruido e classificacao").
/// Reimplementacao propria em Dart, derivada da descricao em prosa -- nao e copia
/// de codigo.
///
/// Ordem dos estagios:
///   1. portao de precisao (rejeita precisao ausente/<=0 ou acima do corte);
///   2. pausa manual (ignora pontos que chegam pausado);
///   3. timestamp duplicado (delta de tempo zero);
///   4. deslocamento minimo (ponto que nao acrescenta trajeto);
///   5. portao de teleporte (velocidade implausivel contra o ponto anterior);
///   6. filtro de aceleracao (salto implausivel entre tres pontos).
/// So pontos ACCEPT somam distancia e entram em splits/polyline.
library;

import 'geo.dart';
import 'location_sample.dart';
import 'waypoint.dart';

/// Corte de qualidade de precisao horizontal (etapa 03: 150 m).
const double kAccuracyThresholdMeters = 150.0;

/// Deslocamento minimo para um ponto acrescentar trajeto (etapa 03: ~3 m).
const double kMinDisplacementMeters = 3.0;

/// Limiar de aceleracao implausivel em m/s^2 (etapa 03: ~11, perto de 1 g).
const double kMaxAccelerationMps2 = 11.0;

/// Velocidade acima da qual um ponto e considerado teleporte e nao um
/// deslocamento real (m/s). 50 m/s = 180 km/h: muito acima de corrida, pedal ou
/// caminhada, mas longe o bastante para nao brigar com ruido de GPS em descida
/// rapida. Serve de portao para o SEGUNDO ponto da gravacao, que o filtro de
/// aceleracao nao alcanca (ele precisa de dois pontos anteriores).
const double kMaxPlausibleSpeedMps = 50.0;

/// Teleportes SEGUIDOS a partir dos quais o problema e a ancora, nao o ponto
/// novo: o ultimo ponto aceito estava errado (fix velho, de antena) e todo fix
/// real cairia longe dele para sempre. Na N-esima rejeicao seguida o ponto novo
/// vira a ancora, sem somar o salto. Um teleporte isolado (1-2 pontos fora e
/// volta ao trajeto) continua rejeitado.
const int kTeleportReanchorCount = 3;

class _AcceptedPoint {
  final GeoPoint position;
  final int monotonicMs;
  const _AcceptedPoint(this.position, this.monotonicMs);
}

class PointPipeline {
  double _cumulativeDistanceMeters = 0.0;

  /// Historico curto de pontos aceitos para o filtro de aceleracao.
  /// Guardamos ate dois: o ultimo (p1) e o anterior (p2).
  _AcceptedPoint? _p1;
  _AcceptedPoint? _p2;

  /// Rejeicoes seguidas pelo portao de teleporte (ver [kTeleportReanchorCount]).
  int _teleportStreak = 0;

  double get cumulativeDistanceMeters => _cumulativeDistanceMeters;

  /// Processa uma amostra e devolve o Waypoint classificado.
  ///
  /// [elapsedTimeMs] tempo total desde o inicio; [timerTimeMs] tempo de
  /// cronometro (sem pausas). Ambos sao fornecidos pelo relogio da gravacao.
  Waypoint process(
    LocationSample sample, {
    required bool manuallyPaused,
    required int elapsedTimeMs,
    required int timerTimeMs,
  }) {
    var cls = _classify(sample, manuallyPaused);

    if (cls == WaypointClassification.ignoreImplausibleSpeed) {
      _teleportStreak++;
      if (_teleportStreak >= kTeleportReanchorCount) {
        // A ancora e que estava errada: recomeca dela sem somar o salto.
        resetRecentBuffer();
        cls = WaypointClassification.accept;
      }
    }
    if (cls == WaypointClassification.accept) {
      _teleportStreak = 0;
      final last = _p1;
      if (last != null) {
        _cumulativeDistanceMeters += haversineMeters(last.position, sample.position);
      }
      _pushAccepted(_AcceptedPoint(sample.position, sample.monotonicMs));
    }

    return Waypoint(
      position: sample.position,
      cumulativeDistanceMeters: _cumulativeDistanceMeters,
      elapsedTimeMs: elapsedTimeMs,
      timerTimeMs: timerTimeMs,
      classification: cls,
      horizontalAccuracyMeters: sample.horizontalAccuracyMeters,
      verticalAccuracyMeters: sample.verticalAccuracyMeters,
      speedMetersPerSecond: sample.speedMetersPerSecond,
    );
  }

  WaypointClassification _classify(LocationSample s, bool manuallyPaused) {
    // 1. portao de precisao
    final acc = s.horizontalAccuracyMeters;
    if (acc == null || acc <= 0 || acc > kAccuracyThresholdMeters) {
      // Nota: pontos com precisao ruim ainda poderiam alimentar o detector de
      // pausa automatica (etapa 03); isso fica na camada de pausa, nao aqui.
      return WaypointClassification.ignoreBadAccuracy;
    }

    // 2. pausa manual
    if (manuallyPaused) return WaypointClassification.ignoreManualPause;

    final last = _p1;
    if (last != null) {
      // 3. timestamp duplicado
      if (s.monotonicMs - last.monotonicMs <= 0) {
        return WaypointClassification.ignoreDuplicateTimestamp;
      }
      // 4. deslocamento minimo
      final disp = haversineMeters(last.position, s.position);
      if (disp < kMinDisplacementMeters) {
        return WaypointClassification.ignoreSampleUpdateFilter;
      }
      // 5. portao de teleporte: vale desde o segundo ponto, onde o filtro de
      // aceleracao ainda nao tem historico suficiente.
      final dt = (s.monotonicMs - last.monotonicMs) / 1000.0;
      if (dt > 0 && disp / dt > kMaxPlausibleSpeedMps) {
        return WaypointClassification.ignoreImplausibleSpeed;
      }
      // 6. filtro de aceleracao (precisa de p1 e p2)
      if (_p2 != null && !_accelerationOk(s, last, _p2!)) {
        return WaypointClassification.ignoreAccelerationFilter;
      }
    }
    return WaypointClassification.accept;
  }

  bool _accelerationOk(LocationSample novo, _AcceptedPoint p1, _AcceptedPoint p2) {
    final dt1 = (novo.monotonicMs - p1.monotonicMs) / 1000.0; // s
    final dt2 = (p1.monotonicMs - p2.monotonicMs) / 1000.0; // s
    if (dt1 <= 0 || dt2 <= 0) return true; // sem como avaliar -> nao reprova
    final v1 = haversineMeters(p1.position, novo.position) / dt1;
    final v2 = haversineMeters(p2.position, p1.position) / dt2;
    final accel = (v1 - v2) / dt1;
    return accel < kMaxAccelerationMps2;
  }

  void _pushAccepted(_AcceptedPoint p) {
    _p2 = _p1;
    _p1 = p;
  }

  /// Retoma uma gravacao interrompida a partir da distancia ja acumulada. O
  /// buffer recente fica vazio: o primeiro ponto depois da retomada nao soma o
  /// trecho percorrido enquanto o app estava fora (mesma regra da pausa).
  void restoreDistance(double cumulativeDistanceMeters) {
    _cumulativeDistanceMeters = cumulativeDistanceMeters;
    resetRecentBuffer();
  }

  /// Zera o buffer de pontos recentes (etapa 03: apos reprovar por aceleracao ou
  /// ao sair de auto-pausa, a referencia recomeca). Nao zera a distancia.
  void resetRecentBuffer() {
    _p1 = null;
    _p2 = null;
    _teleportStreak = 0;
  }
}
