/// Pausa automatica por movimento (acelerometro), para corrida. Clean room a
/// partir de relatorios/03 (duas medias exponenciais, curta x longa, decisao
/// relativa por fator ~3, que dispensa calibracao por aparelho).
///
/// Algoritmo (escrito por nos a partir da prosa do relatorio):
///
/// 1. Intensidade do movimento: `din = | |a| - gEst |`, onde `|a|` e a norma
///    do vetor do acelerometro (independe da orientacao do telefone) e `gEst`
///    e uma media exponencial lenta de `|a|` (passa-alta). Usar `gEst` em vez
///    de 9,81 fixo absorve o vies de calibracao de cada sensor.
/// 2. Duas medias exponenciais de `din` com meia-vida em TEMPO:
///    `alpha = 1 - 2^(-dt/meiaVida)`. Como o peso depende do intervalo real
///    entre amostras, 5 Hz e 50 Hz convergem para o mesmo nivel.
///    - curta (0,5 s): "o que esta acontecendo agora";
///    - longa (10 s): "o normal recente" desta pessoa neste bolso.
/// 3. Maquina de estados com histerese:
///    - EM MOVIMENTO -> candidato a parado quando `3*curta < longa` (queda
///      relativa) OU `curta < pisoParado` (as duas medias baixas: nunca correu,
///      ou parou ha muito). O candidato precisa se manter por [stillHoldMs]
///      para virar PARADO.
///    - Ao entrar em PARADO, a media longa e rebaseada para a curta (o "normal"
///      passa a ser o silencio), senao a retomada exigiria 3x o nivel da
///      corrida.
///    - PARADO -> candidato a movimento quando `curta > 3*longa` E
///      `curta > pisoMovimento`; precisa se manter por [moveHoldMs] (curto:
///      retomar rapido e mais importante que pausar rapido).
/// 4. Sem acelerometro recente (nunca chegou, ou > [staleMs] sem amostra), a
///    decisao vem do [fallback] (velocidade de GPS). O fallback e alimentado
///    sempre, para que o estado dele esteja atualizado na hora da troca.
library;

import 'dart:math' as math;

import 'auto_pause.dart';
import 'geo.dart';
import 'location_sample.dart';

/// Amostra do acelerometro (m/s^2) com tempo monotonico (ms).
class AccelSample {
  final int monotonicMs;
  final double x;
  final double y;
  final double z;
  const AccelSample(this.monotonicMs, this.x, this.y, this.z);
}

/// Detector que decide parado/em movimento pelo acelerometro. Enquanto nao
/// recebe amostras do sensor (aparelho sem acelerometro, emulador), cai no
/// detector por velocidade [fallback].
class MotionAutoPauseDetector implements AutoPauseDetector {
  // ---- Constantes (com o porque) ----

  /// Meia-vida da estimativa da gravidade (passa-alta). 1 s e ~3 passadas de
  /// corrida (2,5-3 Hz): suaviza bem a oscilacao, mas acompanha uma troca de
  /// orientacao/vies em poucos segundos.
  static const double gravityHalfLifeS = 1.0;

  /// Meia-vida da media curta. 0,5 s cobre pouco mais de uma passada: reage
  /// em menos de 1 s quando a pessoa para ou volta a correr.
  static const double fastHalfLifeS = 0.5;

  /// Meia-vida da media longa (mesma ordem de grandeza do relatorio). 10 s
  /// representa o "normal recente" sem esquecer a corrida em poucos passos.
  static const double slowHalfLifeS = 10.0;

  /// Fator da decisao relativa (do relatorio). 3x para entrar em movimento e
  /// 1/3 para sair: a assimetria ja e uma histerese.
  static const double ratio = 3.0;

  /// Piso absoluto de "parado" (m/s^2 de intensidade media). Tremor de mao e
  /// ruido do sensor ficam em ~0,05-0,25; caminhada lenta ja passa de ~0,6 e
  /// corrida de ~2. 0,5 separa com folga para os dois lados.
  static const double stillFloor = 0.5;

  /// Piso absoluto para retomar: a curta precisa passar disto alem do fator
  /// relativo, para que um silencio muito limpo (longa ~0) nao faca um tremor
  /// virar "3x o normal".
  static const double moveFloor = 1.0;

  /// Tempo continuo como candidato a parado antes de pausar. Somado ao ~1 s
  /// que a media curta leva para cair, a pausa acontece ~5 s apos parar (o
  /// detector por velocidade do relatorio usa 10 s; o acelerometro e mais
  /// confiavel que o GPS, entao podemos ser mais rapidos sem falsos positivos
  /// em semaforo com trote no lugar).
  static const int stillHoldMs = 4000;

  /// Tempo continuo como candidato a movimento antes de retomar. Curto para
  /// nao perder metros; longo o bastante para ignorar um esbarrao isolado.
  static const int moveHoldMs = 1000;

  /// Acelerometro sem amostra ha mais que isto = sensor indisponivel; volta
  /// ao fallback e reinicia os filtros (estado velho nao vale mais).
  static const int staleMs = 2000;

  /// Dados minimos de um fluxo novo antes de confiar nele (aquecimento das
  /// medias). Durante o aquecimento vale o fallback.
  static const int warmupMs = 1000;

  /// Velocidade de GPS que desmente o acelerometro "parado" (GRA-02: celular
  /// preso no guidao, no carrinho de bebe ou parado na mesa com o GPS
  /// andando). 1,5 m/s e uma caminhada rapida; deriva de GPS parado fica
  /// abaixo disso quase sempre, e ainda exigimos que se mantenha.
  static const double gpsMovingSpeedMps = 1.5;

  /// Abaixo disto o GPS deixa de desmentir o acelerometro (histerese).
  static const double gpsReleaseSpeedMps = 1.0;

  /// Tempo continuo acima de [gpsMovingSpeedMps] antes de confiar no GPS.
  static const int gpsMovingHoldMs = 3000;

  /// Precisao minima (m) do fix para ele desmentir o acelerometro.
  static const double gpsMaxAccuracyMeters = 25.0;

  final AutoPauseDetector fallback;

  MotionAutoPauseDetector({required this.fallback});

  // ---- Estado ----

  int? _streamStartMs; // inicio do fluxo continuo atual de accel
  int? _lastAccelMs;
  double _gravity = 0;
  double _fast = 0;
  double _slow = 0;
  bool _still = false;
  int? _candidateSinceMs;
  bool _lastFallbackDecision = false;
  int? _gpsFastSinceMs; // inicio da sequencia de fixes rapidos
  int? _lastGpsMs;
  GeoPoint? _lastGpsPosition;
  bool _gpsSaysMoving = false;

  /// Alimenta o detector com uma amostra do acelerometro.
  void addAccel(AccelSample s) {
    final double mag = math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z);
    final int? last = _lastAccelMs;

    if (last == null || s.monotonicMs - last > staleMs) {
      // Inicio de um fluxo novo: semeia a gravidade com a leitura atual e
      // herda o estado do fallback, para nao "despausar" so por trocar de
      // fonte.
      _startStream(s.monotonicMs, mag);
      return;
    }
    final int dtMs = s.monotonicMs - last;
    if (dtMs <= 0) return; // duplicada ou fora de ordem: ignora
    _lastAccelMs = s.monotonicMs;

    final double dt = dtMs / 1000.0;
    _gravity += _alpha(dt, gravityHalfLifeS) * (mag - _gravity);
    final double din = (mag - _gravity).abs();
    _fast += _alpha(dt, fastHalfLifeS) * (din - _fast);
    _slow += _alpha(dt, slowHalfLifeS) * (din - _slow);

    _step(s.monotonicMs);
  }

  void _startStream(int nowMs, double mag) {
    _streamStartMs = nowMs;
    _lastAccelMs = nowMs;
    _gravity = mag;
    _fast = 0;
    _slow = 0;
    _still = _lastFallbackDecision;
    _candidateSinceMs = null;
  }

  static double _alpha(double dtS, double halfLifeS) =>
      1 - math.pow(2, -dtS / halfLifeS).toDouble();

  void _step(int nowMs) {
    final bool candidate;
    if (!_still) {
      candidate = ratio * _fast < _slow || _fast < stillFloor;
    } else {
      candidate = _fast > ratio * _slow && _fast > moveFloor;
    }
    if (!candidate) {
      _candidateSinceMs = null;
      return;
    }
    _candidateSinceMs ??= nowMs;
    final int hold = _still ? moveHoldMs : stillHoldMs;
    if (nowMs - _candidateSinceMs! < hold) return;

    _still = !_still;
    _candidateSinceMs = null;
    if (_still) {
      // O "normal" passa a ser o silencio atual.
      _slow = _fast;
    }
  }

  /// true quando ha accel recente e o fluxo ja aqueceu, no instante [nowMs].
  bool _accelUsable(int nowMs) {
    final int? last = _lastAccelMs;
    final int? start = _streamStartMs;
    if (last == null || start == null) return false;
    if ((nowMs - last).abs() > staleMs) return false;
    return last - start >= warmupMs;
  }

  /// Decisao do acelerometro no instante [nowMs], sem precisar de fix de GPS
  /// (o relogio da gravacao pergunta a cada segundo). null = sem acelerometro
  /// recente; quem decide e o GPS.
  bool? accelDecision(int nowMs) {
    if (!_accelUsable(nowMs)) return null;
    final int? lastGps = _lastGpsMs;
    final bool gpsFresh = lastGps != null && nowMs - lastGps <= staleMs;
    if (_gpsSaysMoving && gpsFresh) return false;
    return _still;
  }

  /// Acompanha se o GPS mostra deslocamento firme (para desmentir o
  /// acelerometro). Usa a velocidade informada ou, sem ela, a derivada do
  /// deslocamento desde o fix anterior.
  void _trackGps(LocationSample s) {
    final int? lastMs = _lastGpsMs;
    final GeoPoint? lastPos = _lastGpsPosition;
    double? speed = s.speedMetersPerSecond;
    if (speed == null && lastMs != null && lastPos != null) {
      final double dt = (s.monotonicMs - lastMs) / 1000.0;
      if (dt > 0) speed = haversineMeters(lastPos, s.position) / dt;
    }
    _lastGpsMs = s.monotonicMs;
    _lastGpsPosition = s.position;

    final double? acc = s.horizontalAccuracyMeters;
    final bool precise = acc != null && acc > 0 && acc <= gpsMaxAccuracyMeters;
    if (speed == null || !precise) {
      _gpsFastSinceMs = null;
      return;
    }
    if (speed >= gpsMovingSpeedMps) {
      _gpsFastSinceMs ??= s.monotonicMs;
      if (s.monotonicMs - _gpsFastSinceMs! >= gpsMovingHoldMs) {
        _gpsSaysMoving = true;
      }
    } else {
      _gpsFastSinceMs = null;
      if (speed < gpsReleaseSpeedMps) _gpsSaysMoving = false;
    }
  }

  @override
  bool shouldBePaused(LocationSample sample) {
    // O fallback e alimentado sempre (ex.: guarda a posicao anterior para
    // derivar velocidade), mesmo quando quem decide e o acelerometro.
    final bool byFallback = fallback.shouldBePaused(sample);
    _trackGps(sample);
    final bool? byAccel = accelDecision(sample.monotonicMs);
    if (byAccel != null) {
      _lastFallbackDecision = byAccel;
      return byAccel;
    }
    _lastFallbackDecision = byFallback;
    if (_lastAccelMs != null &&
        (sample.monotonicMs - _lastAccelMs!).abs() > staleMs) {
      // Sensor parou de chegar: esquece o fluxo; o proximo recomeca do zero.
      _lastAccelMs = null;
      _streamStartMs = null;
    }
    return byFallback;
  }

  @override
  void reset() {
    fallback.reset();
    _streamStartMs = null;
    _lastAccelMs = null;
    _gravity = 0;
    _fast = 0;
    _slow = 0;
    _still = false;
    _candidateSinceMs = null;
    _lastFallbackDecision = false;
    _gpsFastSinceMs = null;
    _lastGpsMs = null;
    _lastGpsPosition = null;
    _gpsSaysMoving = false;
  }
}
