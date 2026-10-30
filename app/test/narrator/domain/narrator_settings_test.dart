// Preferencias do Narrador (F03): padroes, JSON tolerante e copias.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';

void main() {
  test('padrao: desligado, gatilho por distancia e volta, tudo no conteudo', () {
    const s = NarratorSettings();
    expect(s.enabled, isFalse);
    expect(s.distanceTrigger, isTrue);
    expect(s.distanceEvery, 1);
    expect(s.timeEveryMinutes, 0);
    expect(s.lapTrigger, isTrue);
    expect(s.statusAnnouncements, isTrue);
    expect(s.sayTime && s.sayDistance && s.sayAvgPace && s.saySplitPace, isTrue);
    expect(s.contextPhrases, isTrue);
    expect(s.essentialOnly, isFalse);
  });

  test('ida e volta pelo JSON', () {
    const s = NarratorSettings(
      enabled: true,
      distanceTrigger: false,
      distanceEvery: 5,
      timeEveryMinutes: 10,
      lapTrigger: false,
      statusAnnouncements: false,
      sayTime: false,
      sayDistance: false,
      sayAvgPace: false,
      saySplitPace: false,
      contextPhrases: false,
      essentialOnly: true,
    );
    expect(NarratorSettings.fromJsonString(s.toJsonString()), s);
  });

  test('JSON nulo, invalido ou incompleto cai nos padroes', () {
    expect(NarratorSettings.fromJsonString(null), const NarratorSettings());
    expect(NarratorSettings.fromJsonString('nao e json'), const NarratorSettings());
    expect(NarratorSettings.fromJsonString('[1,2]'), const NarratorSettings());
    final partial = NarratorSettings.fromJsonString('{"enabled": true}');
    expect(partial, const NarratorSettings(enabled: true));
  });

  test('valores fora das opcoes voltam ao padrao', () {
    final s = NarratorSettings.fromJsonString(
      '{"distanceEvery": 3, "timeEveryMinutes": 7, "sayTime": "sim"}',
    );
    expect(s.distanceEvery, 1);
    expect(s.timeEveryMinutes, 0);
    expect(s.sayTime, isTrue);
  });

  test('copyWith troca so o pedido', () {
    const s = NarratorSettings();
    final t = s.copyWith(enabled: true, timeEveryMinutes: 5);
    expect(t.enabled, isTrue);
    expect(t.timeEveryMinutes, 5);
    expect(t.distanceTrigger, s.distanceTrigger);
    expect(t == s, isFalse);
  });

  test('opcoes oferecidas na tela', () {
    expect(kNarratorDistanceEveryOptions, [1, 2, 5, 10]);
    expect(kNarratorTimeEveryOptions, [0, 5, 10, 15, 30]);
  });
}
