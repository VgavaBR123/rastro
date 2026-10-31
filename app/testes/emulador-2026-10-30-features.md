# Teste no emulador das features do relatorio 12: 30/10/2026

## Resumo

Registro, feature a feature, dos testes de ponta a ponta no emulador Android das features do
`relatorios/12-ideias-de-features.md`, feitas na branch `features/top10`. Cada secao entra quando a
feature fecha (commit por feature), para que uma queda de energia nao leve o historico junto.

| Feature | Commit | Suites (app / backend) | E2E no emulador |
|---|---|---|---|
| F04 Fechamento gentil | `c3c0b27` + `93394c1` | 782 / 131 | 2 cenarios novos passam; fluxo antigo de sync passa |
| F05 Capitulos mensais com marcos | `8e52f54`..`e4c0d36` + `1f03635`..`b1e41af` | 878 / 131 | 2 cenarios novos passam; F04 e sync passam de novo |
| F06 Plano Do Zero aos 5 km | `195aa74`..`023a8e9` + `8493499`..`1c5df4d` | 982 / 131 | 1 cenario longo passa (parcial, concluidas, voltas, segundo plano, repetir semana); F04, F05 e sync passam de novo |
| F07 Seus dados | `775fa9b`..`3ec738e` + `a500dac`..`4f54ed4` | 1101 / 131 | 1 cenario passa (importar exportacao de conta, duplicata, exportar com privacidade); F04, F05, F06 e sync passam de novo; CI do .ipa verde |

## Como foi testado

- **Aparelho:** emulador `Pixel_7` (Android API 37, Google Play), desbloqueado a mao pelo Gava
  (o AVD tem PIN e fica em `RUNNING_LOCKED` ate o primeiro desbloqueio).
- **Backend de verdade:** Postgres/PostGIS do `docker compose` na porta 5433 e a API com
  `PORT=8081 DB_PORT=5433 dart run bin/server.dart`, alcancada pelo app com
  `adb reverse tcp:8081 tcp:8081`.
- **Comando:** `flutter test integration_test/<arquivo> -d emulator-5554 --dart-define=SYNC_BASE_URL=http://localhost:8081`.
- **GPS:** rota sintetica deterministica (`RotaFakeSource`, 30 pontos a cerca de 13 m), sem `adb emu geo fix`.
- **Contas:** uma conta nova por execucao (`f04-<epoch>@teste.dev`, `e2e<epoch>@teste.dev`), so no banco local do Docker.

## F04 Fechamento gentil

Arquivo novo: `app/integration_test/fechamento_gentil_test.dart`.

| Cenario | Resultado | Evidencia |
|---|---|---|
| Corrida com esforco 7 e humor "cansado" na tela Salvar: fechamento com 2 frases e o bloco de esforco; sync; `GET /activities/<id>` devolve `rpe` e `mood` | Passou | Frases: "Sua primeira corrida registrada aqui. Bom comeco." e "Foram 29 s em movimento." Servidor: `rpe=7 mood=tired` (upload `up_hnpg831dwt_2`), conferido tambem direto na tabela `uploads`. |
| Modo Gentil ligado: sem pace na gravacao, no Salvar, no fechamento e no Perfil (nenhum texto com "/km", "pace", "rapid", "ritmo" ou "km/h") | Passou | Esforco 3 gravado no aparelho; recorde de pace ausente no Perfil. |
| Regressao: `fluxo_sync_test.dart` (conta, corrida, sync, total no Perfil, exclusao no servidor) | Passou depois de ajustar o teste | Perfil: 1 atividade, e 0 depois de excluir. |

### Achados

| Id | Gravidade | O que | Situacao |
|---|---|---|---|
| F04-E2E-01 | Baixa (so teste) | `fluxo_sync_test` tocava em Concluir logo depois do Salvar, mas o fechamento so aparece depois das consultas ao banco (I/O real, que o `pumpAndSettle` nao espera). | Corrigido: o teste espera o botao aparecer. |
| F04-E2E-02 | Baixa (so teste) | O mesmo teste lia o total do Perfil assim que o widget aparecia; a aba fica viva no shell e mostra o 0 de antes ate a releitura que vem depois do sync. | Corrigido: espera o valor 1, como ja fazia no passo da exclusao. O app atualiza sozinho em menos de 1 s. |
| F04-E2E-03 | Confirmacao | A correcao de treino curto da revisao (segundos em vez de "0 min") apareceu no aparelho: "Foram 29 s em movimento." | Ok. |

Antes do E2E, a revisao independente do commit `c3c0b27` apontou 8 itens (2 medios), corrigidos em
`93394c1`. O mais importante: o Salvar gravava esforco, humor e corte das pontas depois de a
atividade entrar na fila de upload, e um sync em andamento subia sem eles.

## F05 Capitulos mensais com marcos

Arquivo novo: `app/integration_test/capitulos_test.dart`. Sem backend (a F05 e so local). O relogio e o do
aparelho (30/10/2026): o teste semeia o mes anterior (setembro) com uma corrida de 5,1 km, uma de 10,2 km e um
pedal de 25 km, todos com titulo e descricao que citam um lugar ("Treino perto de casa", "Saindo da Rua das
Flores"), para provar que eles nao vazam.

| Cenario | Resultado | Evidencia |
|---|---|---|
| Cartao do Inicio abre o capitulo de setembro; 6 paginas ate o Compartilhar; Voltar recua; previa da imagem; ao fechar, o cartao some e o mes fica na lista das Estatisticas | Passou | Paginas: totais 40,30 km, 2:39:00, 3 treinos, 3 dias ativos, pace medio da corrida 5:49 /km; por esporte; "O treino mais longo: foi um pedal, 25,00 km"; 6 primeiras vezes (corrida, 5 km, 10 km, pedal, 20 km, 1 hora); sequencia de 3 semanas com 1 coringa. Imagem: totais, 3 marcos, marca "Rastro", sem pace. Nenhum titulo, descricao ou horario em pagina ou imagem. |
| Modo Gentil, capitulo aberto pela lista das Estatisticas | Passou | Nenhum texto com "/km", "/mi", "pace", "km/h" ou "rapid" em pagina nenhuma. |
| Regressao: `fechamento_gentil_test` e `fluxo_sync_test` contra o backend | Passou | Servidor `rpe=7 mood=tired`; Perfil 1 e depois 0. |

A sequencia bate com o calendario: semanas de 31/08, 07/09 e 14/09 ativas (a de 14/09 pelo pedal de domingo
20/09), semana de 21/09 vazia coberta pelo coringa de setembro, e a de 28/09 ainda aberta no fim do mes.

### Achados

| Id | Gravidade | O que | Situacao |
|---|---|---|---|
| F05-REV-01 | Media | Cartao do Inicio, lista e sequencia nao viravam o dia com o app aberto ou em segundo plano (aberto em 31/10, sem cartao de outubro em 01/11). | Corrigido em `0099bac`: dia atual com Timer na meia-noite e releitura ao voltar do segundo plano. |
| F05-REV-02 | Media-baixa | A lista das Estatisticas lia o relogio de novo e misturava com calculos feitos em outro instante ("Coringa de novembro" calculado sobre outubro). | Corrigido em `0099bac`: tudo calculado no provider com o mesmo instante. |
| F05-REV-03 | Baixa | O capitulo era marcado como visto antes de carregar; com erro, o cartao sumia. | Corrigido em `b94b96a`. |
| F05-REV-04 | Baixa | Com fonte do sistema em 2x, a imagem de 360x640 saia cortada, sem a marca d'agua. | Corrigido em `b1e41af`: a imagem ignora a escala de fonte. |
| F05-REV-05 | Baixa | "Maior sequencia do ano" somava semanas do ano anterior. | Corrigido em `1f03635`. |
| F05-E2E-01 | Baixa (so teste) | O teste rolava o grafico das Estatisticas em vez da lista, e o toque caia fora da tela. | Corrigido no teste: rola a lista vertical e centraliza o item. |

### Nao verificado no aparelho

- A virada da meia-noite e a volta do segundo plano (F05-REV-01) so foram provadas em `flutter test`, com relogio
  falso. No emulador exigiria mudar a data do sistema.
- Leitor de tela (TalkBack): as paginas tem rotulo de semantica conferido em teste de widget, nao com TalkBack.

## F06 Plano Do Zero aos 5 km

Arquivo novo: `app/integration_test/plano_5k_test.dart`. Sem backend. Tabela curta (30 sessoes de 17 s:
aquecimento 3 s, corre 4, caminha 3, corre 4, desaquece 3) com o relogio e o tick REAIS do aparelho, para provar
que o plano anda sozinho. A posicao da tela Gravar e falsa (ver F06-E2E-03).

| Cenario | Resultado | Evidencia |
|---|---|---|
| Comecar o plano: o Gravar da proxima sessao fica dentro da tela | Passou (depois da correcao) | Antes de `1c5df4d` o botao ficava fora da tela (F06-E2E-01). |
| Encerrar aos 5 s (no 2o bloco) | Parcial; a proxima continua sendo a semana 1, sessao 1 | `partial 5577 ms`. |
| Encerrar no meio do desaquecimento | Concluida (regra nova: corridas terminadas = concluida) | `done 16906 ms, 4 voltas`. |
| Sessao inteira | Concluida, uma volta por bloco, todos os blocos na tela | `done 20704 ms, 5 voltas`; blocos: aquecer, correr, caminhar, correr, desacelerar, concluido. |
| App em segundo plano por ~9 s no meio da sessao (HOME e volta por `adb`) | O plano seguiu andando sem GPS e fechou a volta do bloco que terminou fora da tela | `done 27592 ms, 5 voltas`; o 2o "Correr" nao foi visto na tela porque aconteceu em segundo plano. |
| Semana 1 com um RPE 9: fim da 3a sessao | Sugeriu repetir (padrao); repetir volta para a semana 1 | Estado: `currentWeek: 1, repeats: {"1":1}`. |
| Regressao: capitulos, fechamento gentil e sync | Passou | Servidor `rpe=7 mood=tired`; Perfil 1 e depois 0. |

O segundo plano e disparado de fora: o teste imprime `[e2e-f06] SEGUNDO_PLANO` e um script no PC, lendo a
saida do `flutter test`, manda `adb shell input keyevent 3` e traz o app de volta com `monkey` 8 s depois.

### Achados

| Id | Gravidade | O que | Situacao |
|---|---|---|---|
| F06-REV-01 | Alta | A voz dizia "Sessao concluida" no inicio do desaquecimento, mas a regra de 90% fazia quem encerrava ali ficar com sessao parcial (repetida). | Corrigido em `8493499`. Decisao de produto: a sessao conta como concluida quando as corridas terminam; o desaquecimento e recomendado. Frase nova: "Corridas de hoje concluidas. Caminhe 5 minutos para desacelerar." |
| F06-REV-02 | Media | Encerrar pela notificacao: a reconciliacao regravava como parcial uma sessao concluida. | Corrigido em `0c48498`. |
| F06-REV-03 | Media | O relogio do plano (Stopwatch) para com a CPU suspensa: tela desligada e GPS mudo congelariam o plano. | Corrigido em `a0b497d`: `SystemClock.elapsedRealtime` no Android e `CLOCK_MONOTONIC` no iOS por canal nativo, com reserva no relogio de parede. **Nao verificado com a CPU suspensa de verdade.** |
| F06-REV-04 | Media | Com o Narrador geral ligado, os splits falavam pace durante a sessao guiada. | Corrigido em `72e7a26`; a troca de bloco agora interrompe a fala do Narrador. |
| F06-REV-05 a 10 | Baixa | Instante lido fora do evento, ticks andando durante o Encerrar, voltas de 0 s em salto grande, excecao que segurava o fechamento por 5 s, volta duplicada apos crash, rota guiada sem sessao gravando em silencio. | Corrigidos em `a0b497d` e `14bc315`. |
| F06-E2E-01 | Baixa | Depois de "Comecar o plano" a lista ficava rolada para baixo e o Gravar da 1a sessao ficava fora da tela. | Corrigido em `1c5df4d`; o E2E confere o botao dentro da tela. |
| F06-E2E-02 | So teste | `debugPrint` do teste de integracao nao vai para o logcat; o gatilho do segundo plano le a saida do `flutter test`. | Ok. |
| F06-E2E-03 | So ambiente | A tela Gravar pede a permissao de localizacao ao abrir; no emulador ela nunca foi concedida e o dialogo do sistema ficava atras do app. Ao voltar do segundo plano ele ficava por cima e o Flutter parava de desenhar, travando o teste. | O teste usa uma posicao falsa. No uso real a gravacao exige a permissao concedida. |

### Nao verificado no aparelho

- Plano com a CPU suspensa (tela desligada por varios minutos, Doze). O canal nativo compila no Android; no iOS
  o Swift so sera compilado pelo CI do `.ipa`.
- Vibracao com a tela desligada: o `HapticFeedback` do Flutter depende da tela ligada; provavelmente nao vibra.
- Voz real (TTS) e TalkBack: no teste a voz e Noop.
- Fora do escopo da F06, confirmado pelo agente: o tempo em movimento da gravacao comum nao anda sem ponto de
  GPS (GRA-01 do teste no iPhone). O plano tem relogio proprio; a gravacao comum continua com o problema.

## F07 Seus dados

Arquivo novo: `app/integration_test/seus_dados_test.dart`. Sem backend. As entradas sao montadas no proprio teste,
de forma independente dos geradores dos testes de unidade: GPX (horario em -03:00) e TCX escritos a mao, FIT pelo
`fit_writer` do upload e o ZIP pelo pacote `archive`. O seletor de arquivos e o compartilhar do sistema sao trocados
por versoes do teste (o dialogo do sistema ficaria por cima do app).

| Cenario | Resultado | Evidencia |
|---|---|---|
| ZIP no formato da exportacao de conta: `activities.csv` + GPX, TCX.gz, FIT.gz, uma natacao, uma linha sem arquivo e um GPX quebrado | Passou | "3 importadas", "1 de natacao ignorada, 1 de sem arquivo ignorada", erro "activities/105.gpx: XML mal formado". Corrida GPX 1739 m em 599 s, pedal TCX 6101 m em 899 s, corrida FIT 1298 m em 479 s; todas "so eu" e na fila de sync. |
| GPX com horario em -03:00 | Passou | Inicio 2026-03-01 10:00 UTC (07:00 local). |
| Titulo | Passou | Vem do CSV ("Corrida no parque"), com prioridade sobre o `<name>` do GPX. |
| Reimportar o mesmo GPX solto | Passou | "1 duplicada", nenhuma atividade nova. |
| Exportar tudo com corte de privacidade (300 m nas pontas da corrida) | Passou | ZIP com 3 GPX, `atividades.csv` e `LEIA-ME.txt`; 1o ponto exportado a 302 m do original; titulo `Parque & lagoa <manhã>` escapado no XML e sem `<>` no nome do arquivo; o CSV nao leva a rota. |
| Regressao: plano 5 km (com segundo plano), capitulos, fechamento gentil e sync | Passou | Servidor `rpe=7 mood=tired`; Perfil 1 e depois 0. |
| CI do `.ipa` (Swift do `shareFile` e `file_picker_darwin`) | Passou | Execucao `41161217858` no commit `4f54ed4`. |

As distancias cerca de 3% abaixo do "esperado" vieram do gerador do teste (usei 111.320 m por grau tambem na
longitude, que em BH vale cerca de 6% menos): o app mediu certo. A subida alta vem da elevacao sintetica em
dente de serra.

### Achados

| Id | Gravidade | O que | Situacao |
|---|---|---|---|
| F07-REV-01 | Critica | Gzip bomb: um `.gz` de 2 MB virava ~2 GB na memoria antes do teto de tamanho e derrubava o app. | Corrigido em `a500dac`: descompressao por partes com teto; entradas maiores que o declarado e diretorio central gigante tambem falham. |
| F07-REV-02 | Alta | Exportacao de conta em portugues: todos os pedais seriam ignorados ("pedalada" desconhecido). | Corrigido em `5e5d232`; tipo do CSV fora das tabelas cai no esporte do arquivo. |
| F07-REV-03 | Warning | GPX/TCX lido como arvore DOM inteira (OOM com arquivo grande). | Corrigido em `e2034d4`: leitura por eventos. |
| F07-REV-04 a 08 | Media | `routes/` do ZIP entrando como erros; exportacao apagando arquivo em uso; inicio do GPX pela data do `<metadata>`; duplicata falha com tipo inferido; tempo em movimento do TCX. | Corrigidos em `e2034d4`, `5e5d232` e `6870f5d`. |
| F07-REV-09 a 14 | Baixa e notas | Fim abrupto do isolate parecia sucesso; caracteres invalidos no GPX; CSV sem protecao para tab/CR; copia do seletor sem progresso; anuncio por item e fim sem anuncio no leitor de tela. | Corrigidos em `6870f5d`, `a7fab80` e `b42b640`. |

### Nao verificado no aparelho

- Exportacao real do Strava (formato e nomes das colunas do CSV, inclusive em portugues): os testes usam arquivos
  montados a partir da documentacao publica.
- ZIP grande (1 a 2 GB): o `file_picker` copia o arquivo para o cache antes de devolver o caminho, dobrando o espaco
  ocupado por um tempo. Seletor nativo sem copia ficou como pendencia.
- TalkBack real nos anuncios de progresso e de fim.
