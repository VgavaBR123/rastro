# Teste no emulador das features do relatorio 12: 30/10/2026

## Resumo

Registro, feature a feature, dos testes de ponta a ponta no emulador Android das features do
`relatorios/12-ideias-de-features.md`, feitas na branch `features/top10`. Cada secao entra quando a
feature fecha (commit por feature), para que uma queda de energia nao leve o historico junto.

| Feature | Commit | Suites (app / backend) | E2E no emulador |
|---|---|---|---|
| F04 Fechamento gentil | `c3c0b27` + `93394c1` | 782 / 131 | 2 cenarios novos passam; fluxo antigo de sync passa |

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
