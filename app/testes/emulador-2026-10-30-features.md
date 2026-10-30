# Teste no emulador das features do relatorio 12: 30/10/2026

## Resumo

Registro, feature a feature, dos testes de ponta a ponta no emulador Android das features do
`relatorios/12-ideias-de-features.md`, feitas na branch `features/top10`. Cada secao entra quando a
feature fecha (commit por feature), para que uma queda de energia nao leve o historico junto.

| Feature | Commit | Suites (app / backend) | E2E no emulador |
|---|---|---|---|
| F04 Fechamento gentil | `c3c0b27` + `93394c1` | 782 / 131 | 2 cenarios novos passam; fluxo antigo de sync passa |
| F05 Capitulos mensais com marcos | `8e52f54`..`e4c0d36` + `1f03635`..`b1e41af` | 878 / 131 | 2 cenarios novos passam; F04 e sync passam de novo |

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
