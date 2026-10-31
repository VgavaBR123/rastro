// Relogio do plano 5 km (F06). O plano anda pelo tick, entao o relogio
// precisa contar o tempo em que a CPU dormiu (tela desligada, GPS mudo): o
// Stopwatch do Dart nao conta a CPU suspensa no Android.
//
// - Android: SystemClock.elapsedRealtime() (conta o sono), pelo canal
//   `stravaestudo/clock` (PlanClockChannel.kt).
// - iOS: clock_gettime_nsec_np(CLOCK_MONOTONIC) (conta o sono no Darwin),
//   pelo mesmo canal (ClockChannel no AppDelegate.swift).
// - Sem o canal: relogio de parede (DateTime.now()) com limite de sanidade:
//   salto negativo ou maior que 30 min entre duas leituras nao conta.
// - Em `flutter test`: Stopwatch (FunctionTimeSource).
library;

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String kPlanClockChannel = 'stravaestudo/clock';

/// Limite de sanidade do relogio de parede entre duas leituras.
const int kWallClockMaxStepMs = 30 * 60000;

abstract interface class PlanTimeSource {
  /// Instante atual em ms (base arbitraria, sempre a mesma na sessao).
  Future<int> nowMs();

  /// Limite de sanidade entre duas leituras; null = relogio monotonico.
  int? get maxStepMs;
}

/// Relogio a partir de uma funcao (testes e fallback).
class FunctionTimeSource implements PlanTimeSource {
  final int Function() _now;
  @override
  final int? maxStepMs;
  FunctionTimeSource(this._now, {this.maxStepMs});

  @override
  Future<int> nowMs() => Future.value(_now());
}

/// Relogio de parede com o limite de sanidade.
FunctionTimeSource wallClockTimeSource() => FunctionTimeSource(
  () => DateTime.now().millisecondsSinceEpoch,
  maxStepMs: kWallClockMaxStepMs,
);

/// Relogio nativo que conta o sono; sem canal, cai no [fallback] de vez (a
/// base nao muda no meio de uma sessao).
class NativeElapsedTimeSource implements PlanTimeSource {
  final MethodChannel _channel;
  final PlanTimeSource _fallback;
  bool _useFallback = false;

  NativeElapsedTimeSource({
    MethodChannel channel = const MethodChannel(kPlanClockChannel),
    PlanTimeSource? fallback,
  }) : _channel = channel,
       _fallback = fallback ?? wallClockTimeSource();

  bool get usingFallback => _useFallback;

  @override
  int? get maxStepMs => _useFallback ? _fallback.maxStepMs : null;

  @override
  Future<int> nowMs() async {
    if (!_useFallback) {
      try {
        final v = await _channel.invokeMethod<int>('elapsedRealtime');
        if (v != null) return v;
      } catch (e) {
        debugPrint('Relogio nativo do plano indisponivel, usando o de parede: $e');
      }
      _useFallback = true;
    }
    return _fallback.nowMs();
  }
}
