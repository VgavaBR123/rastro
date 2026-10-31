# Dependencias das features do relatorio 12

Pacotes novos do pub.dev adicionados por cada feature (so licencas permissivas:
MIT, BSD ou Apache), com a versao e o motivo.

| Feature | Pacote | Versao | Licenca | Motivo |
|---|---|---|---|---|
| F01 Gravacao blindada | (nenhum) | - | - | Usa o que ja existia: flutter_foreground_task (isencao de bateria e notificacoes), geolocator (permissao e precisao) e um canal nativo proprio (`DeviceSettingsChannel.kt`) para o fabricante e os atalhos de ajuste. |
| F03 Narrador por voz | flutter_tts | ^4.2.5 (4.2.5) | MIT (LICENSE do pacote, Daniel Lutton) | TTS do sistema em pt-BR, offline. No Android pede foco de audio transitorio "may duck" a cada fala (a musica abaixa) e o devolve ao fim; no iOS usa a AVAudioSession compartilhada (playback + duckOthers) e a desativa avisando os outros apps ao terminar. Fica atras de `VoiceAnnouncer` (Noop em `flutter test`). |
| F05 Capitulos mensais e anuais | (nenhum) | - | - | Tudo no aparelho com o que ja existia: drift (coluna `chapter_month_seen`), Riverpod, go_router e o pipeline de imagem de `ui/share/` (RepaintBoundary para PNG e a folha nativa do canal `stravaestudo/share`). Sem pacote de notificacao: a entrada e o cartao no Inicio. |
| F06 Plano Do Zero aos 5 km | (nenhum) | - | - | Tudo com o que ja existia: drift (tabelas `plan5k_states` e `plan5k_sessions`, coluna `plan5k_voice`), Riverpod, go_router, a fila do Narrador (F03) para a voz e `HapticFeedback` do proprio Flutter para a vibracao. |
