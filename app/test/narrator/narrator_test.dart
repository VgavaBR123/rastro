// Narrador (F03): API generica de enfileirar frases, uma fala por vez, com
// prioridade, interrupcao pela critica e o gancho do Modo Gentil.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/announcement.dart';
import 'package:strava_estudo_app/narrator/narrator.dart';

import 'fake_voice_announcer.dart';

void main() {
  test('fala na ordem e uma por vez', () async {
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => 0);
    n.say('um');
    n.say('dois');
    await pumpMicrotasks();
    expect(voice.spoken, ['um']);
    voice.finishCurrent();
    await pumpMicrotasks();
    expect(voice.spoken, ['um', 'dois']);
    voice.finishCurrent();
    await n.whenIdle();
    expect(voice.maxConcurrent, 1);
    expect(n.isSpeaking, isFalse);
  });

  test('enquanto fala, a de maior prioridade passa na frente das pendentes', () async {
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => 0);
    n.say('primeira');
    await pumpMicrotasks();
    n.say('baixa', priority: AnnouncementPriority.low);
    n.say('alta', priority: AnnouncementPriority.high);
    voice.finishCurrent();
    await pumpMicrotasks();
    voice.finishCurrent();
    await pumpMicrotasks();
    voice.finishCurrent();
    await n.whenIdle();
    expect(voice.spoken, ['primeira', 'alta', 'baixa']);
    expect(voice.stops, 0);
  });

  test('critica interrompe uma fala menor e toca em seguida', () async {
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => 0);
    n.say('split longo');
    await pumpMicrotasks();
    n.say('frequencia alta', priority: AnnouncementPriority.critical);
    await pumpMicrotasks();
    expect(voice.stops, 1);
    expect(voice.spoken, ['split longo', 'frequencia alta']);
    voice.finishCurrent();
    await n.whenIdle();
  });

  test('a fala interrompida pela critica e descartada; as pendentes seguem', () async {
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => 0);
    n.say('split longo');
    await pumpMicrotasks();
    n.say('pendente');
    n.say('frequencia alta', priority: AnnouncementPriority.critical);
    await pumpMicrotasks();
    voice.finishCurrent(); // critica
    await pumpMicrotasks();
    voice.finishCurrent(); // pendente
    await n.whenIdle();
    expect(voice.spoken, ['split longo', 'frequencia alta', 'pendente']);
  });

  test('critica nao interrompe outra critica', () async {
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => 0);
    n.say('a', priority: AnnouncementPriority.critical);
    await pumpMicrotasks();
    n.say('b', priority: AnnouncementPriority.critical);
    await pumpMicrotasks();
    expect(voice.stops, 0);
    voice.finishCurrent();
    await pumpMicrotasks();
    voice.finishCurrent();
    await n.whenIdle();
    expect(voice.spoken, ['a', 'b']);
  });

  test('fala velha nao toca', () async {
    var now = 0;
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => now);
    n.say('agora');
    await pumpMicrotasks();
    n.enqueue(const Announcement('tempo', priority: AnnouncementPriority.low, maxAgeMs: 1000));
    now = 5000;
    voice.finishCurrent();
    await n.whenIdle();
    expect(voice.spoken, ['agora']);
  });

  test('stop esvazia a fila e cala a fala corrente', () async {
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => 0);
    n.say('um');
    n.say('dois');
    await pumpMicrotasks();
    await n.stop();
    await n.whenIdle();
    expect(voice.spoken, ['um']);
    expect(voice.stops, 1);
  });

  test('falha do TTS nao trava a fila', () async {
    final voice = FakeVoiceAnnouncer()..failSpeak = true;
    final n = Narrator(voice, now: () => 0);
    n.say('um');
    await n.whenIdle();
    voice.failSpeak = false;
    n.say('dois');
    await n.whenIdle();
    expect(voice.spoken, ['dois']);
  });

  test('gancho do Modo Gentil: o filtro pode trocar ou calar a frase', () async {
    final voice = FakeVoiceAnnouncer();
    final n = Narrator(
      voice,
      now: () => 0,
      filter: (a) => a.text.contains('lento') ? null : Announcement('${a.text} Bom trabalho.'),
    );
    n.say('Mais lento que o anterior.');
    n.say('Um quilômetro.');
    await n.whenIdle();
    expect(voice.spoken, ['Um quilômetro. Bom trabalho.']);
  });

  test('dispose: depois disso nada mais fala', () async {
    final voice = FakeVoiceAnnouncer();
    final n = Narrator(voice, now: () => 0);
    await n.dispose();
    n.say('nada');
    await n.whenIdle();
    expect(voice.spoken, isEmpty);
  });

  // Revisao F03: "Ouvir exemplo" nao pode apagar as falas pendentes da
  // gravacao; so troca o exemplo anterior.
  test('replace troca so a fala da mesma chave e preserva a fila', () async {
    final voice = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(voice, now: () => 0);
    n.say('gravacao um');
    n.say('gravacao dois');
    await pumpMicrotasks();
    n.replace(const Announcement('exemplo um', key: 'sample'));
    await pumpMicrotasks();
    expect(voice.stops, 0, reason: 'a fala corrente nao e um exemplo');
    voice.finishCurrent();
    await pumpMicrotasks();
    voice.finishCurrent();
    await pumpMicrotasks();
    expect(voice.spoken, ['gravacao um', 'gravacao dois', 'exemplo um']);
    // Exemplo tocando: um novo exemplo corta o anterior e toca no lugar.
    n.say('gravacao tres');
    n.replace(const Announcement('exemplo dois', key: 'sample'));
    await pumpMicrotasks();
    expect(voice.stops, 1);
    voice.finishCurrent();
    await pumpMicrotasks();
    voice.finishCurrent();
    await n.whenIdle();
    expect(voice.spoken, [
      'gravacao um',
      'gravacao dois',
      'exemplo um',
      'gravacao tres',
      'exemplo dois',
    ]);
  });
}

Future<void> pumpMicrotasks() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
