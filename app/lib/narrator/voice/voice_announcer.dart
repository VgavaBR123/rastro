// Borda de voz do Narrador (F03). O plugin de TTS fica atras desta interface;
// testes e plataformas sem TTS usam [NoopVoiceAnnouncer].
library;

abstract interface class VoiceAnnouncer {
  /// Fala [text] e completa quando a fala termina (ou e interrompida).
  /// Nunca lanca: falha de TTS so deixa a frase sem som.
  Future<void> speak(String text);

  /// Interrompe a fala corrente (o [speak] pendente completa).
  Future<void> stop();
}

/// Sem voz: completa na hora. Padrao em `flutter test`.
class NoopVoiceAnnouncer implements VoiceAnnouncer {
  const NoopVoiceAnnouncer();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}
