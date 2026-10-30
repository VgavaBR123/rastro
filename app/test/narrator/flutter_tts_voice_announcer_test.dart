// Adaptador do flutter_tts (F03) contra um canal falso: configuracao de
// pt-BR e do ducking por plataforma, fim da fala pelo aviso do TTS, timeout de
// seguranca e stop.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:strava_estudo_app/narrator/voice/flutter_tts_voice_announcer.dart';

const _channel = MethodChannel('flutter_tts');

/// O plugin so manda setIosAudioCategory ao canal quando roda em iOS de
/// verdade; o espiao registra a chamada na mesma lista, na ordem certa.
class _TtsSpy extends FlutterTts {
  final List<MethodCall> log;
  _TtsSpy(this.log);

  @override
  Future<dynamic> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, [
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  ]) async {
    log.add(MethodCall('setIosAudioCategory', {'category': category, 'options': options, 'mode': mode}));
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  Object? speakResult;
  var throwOnSpeak = false;

  setUp(() {
    calls = [];
    speakResult = 1;
    throwOnSpeak = false;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (call.method == 'speak' && throwOnSpeak) {
        throw PlatformException(code: 'tts');
      }
      return call.method == 'speak' ? speakResult : 1;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  /// O TTS avisa que terminou a fala (como o plugin nativo faz).
  Future<void> platformSays(String method) async {
    await messenger.handlePlatformMessage(
      'flutter_tts',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, true)),
      (_) {},
    );
  }

  List<String> methods() => calls.map((c) => c.method).toList();

  test('Android: pt-BR, atributos de guia de voz e foco transitorio na fala', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    final done = v.speak('Um quilômetro.');
    await pumpEventQueue();
    expect(methods(), containsAllInOrder(['setLanguage', 'awaitSpeakCompletion', 'setAudioAttributesForNavigation', 'speak']));
    expect(calls.firstWhere((c) => c.method == 'setLanguage').arguments, 'pt-BR');
    expect(calls.firstWhere((c) => c.method == 'awaitSpeakCompletion').arguments, false);
    expect(methods(), isNot(contains('setSharedInstance')));
    await platformSays('speak.onComplete');
    await done;
  });

  // Revisao F03: ativar a sessao (setSharedInstance(true)) antes de trocar a
  // categoria a deixava em soloAmbient e a primeira fala interrompia a musica
  // em vez de abaixa-la. A categoria playback+duckOthers vem antes de tudo e
  // quem ativa a sessao e o proprio sintetizador, ja configurado.
  test('iOS: categoria com ducking antes de qualquer ativacao da sessao', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: _TtsSpy(calls), platform: TargetPlatform.iOS);
    final done = v.speak('Oi');
    await pumpEventQueue();
    expect(methods(), containsAllInOrder(['setLanguage', 'setIosAudioCategory', 'autoStopSharedSession', 'speak']));
    final category = calls.firstWhere((c) => c.method == 'setIosAudioCategory').arguments as Map;
    expect(category['category'], IosTextToSpeechAudioCategory.playback);
    expect(category['options'], contains(IosTextToSpeechAudioCategoryOptions.duckOthers));
    expect(calls.firstWhere((c) => c.method == 'autoStopSharedSession').arguments, true);
    expect(calls.where((c) => c.method == 'setSharedInstance' && c.arguments == true), isEmpty);
    expect(methods(), isNot(contains('setAudioAttributesForNavigation')));
    await platformSays('speak.onComplete');
    await done;
  });

  // Revisao F03: no iOS o plugin so desativa a sessao no fim natural da fala;
  // cancelar (stop) deixava a musica abaixada ate a proxima fala terminar.
  test('iOS: stop no meio da fala desativa a sessao (musica volta)', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: _TtsSpy(calls), platform: TargetPlatform.iOS);
    final a = v.speak('split longo');
    await pumpEventQueue();
    await v.stop();
    await a;
    final stopAt = methods().lastIndexOf('stop');
    final offAt = calls.lastIndexWhere((c) => c.method == 'setSharedInstance' && c.arguments == false);
    expect(stopAt, greaterThanOrEqualTo(0));
    expect(offAt, greaterThan(stopAt));
  });

  test('iOS: eco do cancelamento desativa de novo antes da fala seguinte', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: _TtsSpy(calls), platform: TargetPlatform.iOS);
    final a = v.speak('split longo');
    await pumpEventQueue();
    await v.stop();
    await a;
    final b = v.speak('critica');
    await pumpEventQueue();
    calls.clear();
    // Se o setActive(false) do stop falhou (audio ainda saindo), o aviso de
    // cancelamento tenta de novo; e chega antes da fala seguinte.
    await platformSays('speak.onCancel');
    await pumpEventQueue();
    expect(methods(), containsAllInOrder(['setSharedInstance', 'speak']));
    expect(calls.first.arguments, false);
    await platformSays('speak.onComplete');
    await b;
  });

  test('Android: stop nao mexe em sessao de audio do iOS', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    final a = v.speak('longa');
    await pumpEventQueue();
    await v.stop();
    await a;
    expect(methods(), isNot(contains('setSharedInstance')));
  });

  test('configura uma vez so', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    final a = v.speak('a');
    await pumpEventQueue();
    await platformSays('speak.onComplete');
    await a;
    final b = v.speak('b');
    await pumpEventQueue();
    await platformSays('speak.onComplete');
    await b;
    expect(methods().where((m) => m == 'setLanguage'), hasLength(1));
    expect(methods().where((m) => m == 'speak'), hasLength(2));
  });

  test('cancelamento ou erro do TTS tambem terminam a fala', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    final a = v.speak('a');
    await pumpEventQueue();
    await platformSays('speak.onCancel');
    await a;
    final b = v.speak('b');
    await pumpEventQueue();
    await messenger.handlePlatformMessage(
      'flutter_tts',
      const StandardMethodCodec().encodeMethodCall(const MethodCall('speak.onError', 'x')),
      (_) {},
    );
    await b;
  });

  testWidgets('sem aviso do TTS, o timeout libera a fila', (tester) async {
    final v = FlutterTtsVoiceAnnouncer(
      tts: FlutterTts(),
      platform: TargetPlatform.android,
      maxSpeechDuration: (_) => const Duration(seconds: 3),
    );
    var finished = false;
    unawaited(v.speak('nunca termina').then((_) => finished = true));
    await tester.pump(const Duration(seconds: 2));
    expect(finished, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(finished, isTrue);
  });

  test('speak recusado (0) ou com excecao termina na hora sem lancar', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    speakResult = 0;
    await v.speak('a');
    speakResult = 1;
    throwOnSpeak = true;
    await v.speak('b');
  });

  test('stop chama o TTS e termina a fala pendente', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    final a = v.speak('longa');
    await pumpEventQueue();
    await v.stop();
    await a;
    expect(methods(), contains('stop'));
  });

  test('tempo maximo padrao cresce com o texto', () {
    expect(defaultMaxSpeechDuration('curto'), lessThan(defaultMaxSpeechDuration('x' * 300)));
    expect(defaultMaxSpeechDuration('x' * 5000), const Duration(seconds: 45));
  });

  // Revisao F03: o aviso de cancelamento da fala interrompida chega depois do
  // stop() e sem id. Nao pode terminar a fala seguinte (a critica) antes da
  // hora, e a fala seguinte so comeca depois dele (no Android, esse aviso
  // devolve o foco de audio; se viesse no meio da nova fala, a musica voltaria
  // ao volume cheio).
  test('aviso atrasado do stop nao termina a fala seguinte', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    final a = v.speak('split longo');
    await pumpEventQueue();
    await v.stop();
    await a;
    var bDone = false;
    final b = v.speak('critica').then((_) => bDone = true);
    await pumpEventQueue();
    // Ainda esperando o eco do stop: a fala critica nao foi pedida ao TTS.
    expect(methods().where((m) => m == 'speak'), hasLength(1));
    await platformSays('speak.onCancel'); // eco atrasado do stop
    await pumpEventQueue();
    expect(methods().where((m) => m == 'speak'), hasLength(2));
    expect(bDone, isFalse);
    await platformSays('speak.onComplete'); // fim real da critica
    await b;
    expect(bDone, isTrue);
  });

  testWidgets('sem eco do stop, a fala seguinte sai depois de um prazo curto', (tester) async {
    final v = FlutterTtsVoiceAnnouncer(
      tts: FlutterTts(),
      platform: TargetPlatform.android,
      maxSpeechDuration: (_) => const Duration(seconds: 30),
    );
    unawaited(v.speak('a'));
    await tester.pump();
    await v.stop();
    var bDone = false;
    unawaited(v.speak('b').then((_) => bDone = true));
    await tester.pump();
    expect(methods().where((m) => m == 'speak'), hasLength(1));
    await tester.pump(stopEchoTimeout);
    await tester.pump();
    expect(methods().where((m) => m == 'speak'), hasLength(2));
    // Um aviso que chega agora e o fim da propria fala b.
    await platformSays('speak.onComplete');
    await tester.pump();
    expect(bDone, isTrue);
  });

  test('stop sem fala tocando nao espera eco', () async {
    final v = FlutterTtsVoiceAnnouncer(tts: FlutterTts(), platform: TargetPlatform.android);
    await v.stop();
    final b = v.speak('b');
    await pumpEventQueue();
    expect(methods().where((m) => m == 'speak'), hasLength(1));
    await platformSays('speak.onComplete');
    await b;
  });
}
