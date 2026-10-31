# Dependencias das features do relatorio 12

Pacotes novos do pub.dev adicionados por cada feature (so licencas permissivas:
MIT, BSD ou Apache), com a versao e o motivo.

| Feature | Pacote | Versao | Licenca | Motivo |
|---|---|---|---|---|
| F01 Gravacao blindada | (nenhum) | - | - | Usa o que ja existia: flutter_foreground_task (isencao de bateria e notificacoes), geolocator (permissao e precisao) e um canal nativo proprio (`DeviceSettingsChannel.kt`) para o fabricante e os atalhos de ajuste. |
| F03 Narrador por voz | flutter_tts | ^4.2.5 (4.2.5) | MIT (LICENSE do pacote, Daniel Lutton) | TTS do sistema em pt-BR, offline. No Android pede foco de audio transitorio "may duck" a cada fala (a musica abaixa) e o devolve ao fim; no iOS usa a AVAudioSession compartilhada (playback + duckOthers) e a desativa avisando os outros apps ao terminar. Fica atras de `VoiceAnnouncer` (Noop em `flutter test`). |
| F05 Capitulos mensais e anuais | (nenhum) | - | - | Tudo no aparelho com o que ja existia: drift (coluna `chapter_month_seen`), Riverpod, go_router e o pipeline de imagem de `ui/share/` (RepaintBoundary para PNG e a folha nativa do canal `stravaestudo/share`). Sem pacote de notificacao: a entrada e o cartao no Inicio. |
| F06 Plano Do Zero aos 5 km | (nenhum) | - | - | Tudo com o que ja existia: drift (tabelas `plan5k_states` e `plan5k_sessions`, coluna `plan5k_voice`), Riverpod, go_router, a fila do Narrador (F03) para a voz e `HapticFeedback` do proprio Flutter para a vibracao. |
| F07 Seus dados | file_picker | ^13.3.0 (13.3.0; federados android_file_picker 2.1.2 e file_picker_darwin 2.4.0) | MIT (LICENSE do pacote, Miguel Ruivo; os federados tambem MIT) | Seletor de documentos do sistema (Android e iOS) para escolher um ou varios arquivos da importacao. Sem filtro de extensao no seletor (o .fit e o .gz nao tem tipo MIME confiavel no Android); o app recusa no resumo o que nao aceita. O seletor copia o arquivo escolhido para o cache do app; a copia e apagada ao fim da importacao (`clearTemporaryFiles`). Fica atras de `ImportFilePicker` (troca nos testes e no E2E). |
| F07 Seus dados | xml | ^7.1.0 (7.1.0) | MIT (LICENSE do pacote, Lukas Renggli) | Leitura de GPX e TCX. Ja vinha como dependencia transitiva; virou direta. |
| F07 Seus dados (so testes) | archive | ^4.5.2 (4.5.2), dev_dependency | MIT (LICENSE do pacote, Brendan Duncan) | Monta ZIPs nos testes com um gerador independente do nosso, para conferir o nosso leitor e o nosso escritor de ZIP. Nao entra no app: o ZIP (leitura por partes e escrita) e o gzip usam so `dart:io`. |
