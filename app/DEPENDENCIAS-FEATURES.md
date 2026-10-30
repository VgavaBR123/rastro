# Dependencias das features do relatorio 12

Pacotes novos do pub.dev adicionados por cada feature (so licencas permissivas:
MIT, BSD ou Apache), com a versao e o motivo.

| Feature | Pacote | Versao | Licenca | Motivo |
|---|---|---|---|---|
| F01 Gravacao blindada | (nenhum) | - | - | Usa o que ja existia: flutter_foreground_task (isencao de bateria e notificacoes), geolocator (permissao e precisao) e um canal nativo proprio (`DeviceSettingsChannel.kt`) para o fabricante e os atalhos de ajuste. |
| F03 Narrador por voz | flutter_tts | ^4.2.5 (4.2.5) | MIT (LICENSE do pacote, Daniel Lutton) | TTS do sistema em pt-BR, offline. No Android pede foco de audio transitorio "may duck" a cada fala (a musica abaixa) e o devolve ao fim; no iOS usa a AVAudioSession compartilhada (playback + duckOthers) e a desativa avisando os outros apps ao terminar. Fica atras de `VoiceAnnouncer` (Noop em `flutter test`). |
