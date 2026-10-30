// Voz do Narrador com o TTS do sistema via flutter_tts (F03), em pt-BR e com
// ducking da musica:
// - Android: cada fala pede foco de audio transitorio "may duck" (o player de
//   musica abaixa o volume) e o devolve ao terminar; a fala sai com o uso de
//   "guia de voz", que o sistema trata como navegacao.
// - iOS: a sessao AVAudioSession do app fica na categoria playback com
//   duckOthers ANTES de ser ativada (quem ativa e o proprio sintetizador, na
//   primeira fala); ativar antes, na categoria padrao soloAmbient, interromperia
//   a musica em vez de abaixa-la. No fim natural da fala o plugin desativa a
//   sessao avisando os outros apps (autoStopSharedSession); no cancelamento
//   (stop) o plugin nao desativa, entao o stop() daqui desativa, e a musica
//   volta ao volume normal.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'voice_announcer.dart';

/// Teto de seguranca para uma fala: se o TTS nunca avisar o fim, a fila do
/// Narrador nao trava. Cresce com o texto, ate 45 s.
Duration defaultMaxSpeechDuration(String text) {
  final ms = 4000 + text.length * 90;
  return Duration(milliseconds: ms > 45000 ? 45000 : ms);
}

/// Quanto a fala seguinte espera o aviso (atrasado) de cancelamento de uma
/// fala interrompida por stop(). Sem aviso nesse prazo, segue assim mesmo.
const Duration stopEchoTimeout = Duration(milliseconds: 400);

class FlutterTtsVoiceAnnouncer implements VoiceAnnouncer {
  final FlutterTts _tts;
  final TargetPlatform _platform;
  final Duration Function(String text) _maxDuration;

  Future<void>? _ready;
  Completer<void>? _speaking;
  Timer? _timeout;

  /// Aviso de fim esperado de uma fala interrompida por [stop]. O TTS manda
  /// esse aviso depois e sem dizer de qual fala e: enquanto ele esta pendente,
  /// o proximo aviso que chegar e dele, e a fala seguinte espera por ele.
  Completer<void>? _stopEcho;
  Timer? _stopEchoTimer;

  FlutterTtsVoiceAnnouncer({
    FlutterTts? tts,
    TargetPlatform? platform,
    Duration Function(String text)? maxSpeechDuration,
  }) : _tts = tts ?? FlutterTts(),
       _platform = platform ?? defaultTargetPlatform,
       _maxDuration = maxSpeechDuration ?? defaultMaxSpeechDuration;

  Future<void> _init() async {
    _tts.setCompletionHandler(_onPlatformEnd);
    _tts.setCancelHandler(_onPlatformEnd);
    _tts.setErrorHandler((_) => _onPlatformEnd());
    await _tts.setLanguage('pt-BR');
    // O fim da fala vem pelos handlers acima (com timeout), nao pelo retorno
    // do speak: assim o stop() tambem libera quem esta esperando.
    await _tts.awaitSpeakCompletion(false);
    switch (_platform) {
      case TargetPlatform.android:
        await _tts.setAudioAttributesForNavigation();
      case TargetPlatform.iOS:
        // Sem setSharedInstance(true): ele ativaria a sessao na hora, ainda
        // na categoria padrao. A categoria vem primeiro.
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
        await _tts.autoStopSharedSession(true);
      default:
        break;
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await (_ready ??= _init());
    } catch (_) {
      _ready = null; // tenta configurar de novo na proxima fala
      return;
    }
    // Fala anterior interrompida: espera o aviso dela antes de comecar. Assim
    // ele nao termina esta fala antes da hora e, no Android, a devolucao do
    // foco de audio dela nao cai no meio desta (a musica voltaria ao volume
    // cheio enquanto o Narrador fala).
    final echo = _stopEcho;
    if (echo != null) await echo.future;
    _finish(); // nunca duas esperas ao mesmo tempo
    final done = _speaking = Completer<void>();
    _timeout = Timer(_maxDuration(text), _finish);
    try {
      final result = await _tts.speak(
        text,
        focus: _platform == TargetPlatform.android,
      );
      if (result != 1) _finish();
    } catch (_) {
      _finish();
    }
    await done.future;
  }

  @override
  Future<void> stop() async {
    // Armado antes do stop nativo: o aviso pode chegar antes do retorno.
    if (_speaking != null && _stopEcho == null) {
      _stopEcho = Completer<void>();
      _stopEchoTimer = Timer(stopEchoTimeout, _consumeStopEcho);
    }
    try {
      await _tts.stop();
    } catch (_) {
      // sem TTS: nada tocando
    } finally {
      _finish();
    }
    await _releaseIosSession();
  }

  /// iOS: desativa a sessao de audio para a musica de outro app voltar ao
  /// volume normal. O plugin so faz isso no fim natural da fala, nao no
  /// cancelamento. Sem efeito nas outras plataformas.
  Future<void> _releaseIosSession() async {
    if (_platform != TargetPlatform.iOS) return;
    try {
      await _tts.setSharedInstance(false);
    } catch (_) {
      // sessao ja inativa ou sem TTS: nada a devolver
    }
  }

  /// Aviso do TTS (fim, cancelamento ou erro). Se ha eco de stop pendente, e
  /// dele; senao, e da fala corrente.
  void _onPlatformEnd() {
    if (_stopEcho != null) {
      // O setActive(false) do stop() pode falhar se o audio ainda estava
      // saindo; agora o cancelamento terminou de fato. Pedido antes de liberar
      // a fala seguinte, para chegar ao nativo antes do speak dela.
      unawaited(_releaseIosSession());
      _consumeStopEcho();
      return;
    }
    _finish();
  }

  void _consumeStopEcho() {
    _stopEchoTimer?.cancel();
    _stopEchoTimer = null;
    final c = _stopEcho;
    _stopEcho = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  void _finish() {
    _timeout?.cancel();
    _timeout = null;
    final c = _speaking;
    _speaking = null;
    if (c != null && !c.isCompleted) c.complete();
  }
}
