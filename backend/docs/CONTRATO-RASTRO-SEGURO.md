# Contrato do Rastro Seguro (F08)

Fonte de verdade entre o app e o backend para a chegada combinada. Complementa `CONTRATO.md` (mesmo estilo:
JSON, erros `{"error": "..."}`, tempos em epoch ms, `Authorization: Bearer <token>` salvo onde dito).

## Ideia

A pessoa que vai treinar (a **dona**) escolhe contatos de confianca (outras contas do Rastro) e um horario
previsto de chegada. Durante a gravacao o app manda a posicao a cada 60 s. O **backend** vigia: se o app ficar
em silencio, se a pessoa ficar parada sem pausa ou se passar do horario sem chegar, ele primeiro pergunta a dona
"esta tudo bem?" e so depois, sem resposta, avisa os contatos com um link temporario da ultima posicao. Nada de
SMS e nada de deteccao de queda (relatorio 12).

## Contatos de confianca

Um contato e outra conta do Rastro, com consentimento: quem e convidado precisa aceitar. No maximo 3 contatos
aceitos por dona.

| Rota | Corpo | Resposta |
| --- | --- | --- |
| `POST /safety/contacts` | `{"email": "..."}` | 201 `contact` com `status: "pending"`. 404 `sem conta no Rastro` se o email nao tem conta; 409 se ja existe o convite ou se a dona ja tem 3 aceitos; 400 se for o proprio email. |
| `GET /safety/contacts` | | 200 `{"outgoing": [contact], "incoming": [contact]}` (`outgoing`: quem eu convidei; `incoming`: quem me convidou). |
| `POST /safety/contacts/<id>/accept` | | 200 `contact` com `status: "accepted"`. So quem foi convidado; senao 404. |
| `DELETE /safety/contacts/<id>` | | 204. Qualquer um dos dois lados. Tira o contato das sessoes ativas. |

`contact`: `{"id": "ct_...", "otherUserId": "usr_...", "displayName": "...", "email": "...", "status": "pending" | "accepted", "createdAt": 0}`.
O convite gera uma notificacao `contact_invite` para o convidado; aceitar gera `contact_accepted` para a dona.

## Sessao do Rastro Seguro

| Rota | Corpo | Resposta |
| --- | --- | --- |
| `POST /safety/sessions` | `{"activityGuid": "act_...", "etaMs": 0, "contactIds": ["ct_..."]}` | 201 `session`. 400 se `etaMs` nao estiver entre agora + 5 min e agora + 12 h, ou se `contactIds` for vazio ou tiver contato nao aceito. 409 se ja ha sessao ativa da dona (o app encerra a anterior antes). |
| `GET /safety/sessions/active` | | 200 `session` ou 404 (recuperacao apos crash). |
| `GET /safety/sessions/<id>` | | 200 `session` (so a dona). |
| `POST /safety/sessions/<id>/positions` | `{"lat": 0, "lon": 0, "accuracyM": 5, "recordedAtMs": 0, "moving": true, "paused": false}` | 200 `session` (o app le `check` daqui). `lat`/`lon` podem ser null (batimento sem posicao nova: conta como sinal de vida). |
| `POST /safety/sessions/<id>/ok` | | 200 `session`: responde "estou bem"; zera a checagem. |
| `POST /safety/sessions/<id>/extend` | `{"minutes": 15}` | 200 `session` com `etaMs` + minutos (5 a 120). Tambem zera a checagem. |
| `POST /safety/sessions/<id>/arrived` | | 200 `session` com `status: "ended"`. O link expira 15 min depois. |
| `POST /safety/sessions/<id>/sos` | | 200 `session`: alerta imediato `safety_sos` para os contatos, com a posicao atual. Nao encerra a sessao. |

`session`:

```json
{
  "id": "ss_...", "activityGuid": "act_...", "status": "active",
  "etaMs": 0, "startedAt": 0, "endedAt": null,
  "lastSignalAt": 0, "lastPosition": {"lat": 0, "lon": 0, "accuracyM": 5, "recordedAtMs": 0} ,
  "contactIds": ["ct_..."],
  "check": null,
  "alertedAt": null,
  "shareUrl": "https://<PUBLIC_BASE_URL>/s/<token>"
}
```

- `status`: `active` | `checking` (perguntou "esta tudo bem?") | `alerted` (avisou os contatos) | `ended`.
- `check`: `null` ou `{"reason": "silence" | "stopped" | "eta", "startedAt": 0, "deadlineMs": 0}`.
- Depois de `alerted`, `ok` ou `extend` volta a `active` e os contatos recebem `safety_all_clear` ("ela respondeu que esta bem").
- `lastPosition` pode ser null. `shareUrl` usa `PUBLIC_BASE_URL` (padrao `http://localhost:8081`).

## Regras do vigia (backend)

Um timer no servidor roda a cada `SAFETY_TICK_MS` (padrao 15000) sobre as sessoes nao encerradas:

1. **Silencio:** `agora - lastSignalAt > SAFETY_SILENCE_MS` (padrao 5 min).
2. **Parada:** as posicoes dos ultimos `SAFETY_STOP_MS` (padrao 10 min) vieram todas com `moving: false` e
   `paused: false` (pausa manual nao dispara).
3. **Horario:** `agora > etaMs` sem `arrived`.

Ao disparar (so com `status: active`): `status: checking`, `check` preenchido com `deadlineMs = agora + SAFETY_CHECK_MS`
(padrao 2 min) e notificacao `safety_check` para a dona. Se a dona nao responder (`ok`, `extend` ou `arrived`)
ate o prazo: `status: alerted`, `alertedAt` e notificacao `safety_alert` para cada contato aceito da sessao, com
o motivo e o `shareUrl`. Um alerta por checagem (sem repetir a cada tick). A sessao encerra sozinha em `etaMs + 6 h`.
Posicoes e o link somem 24 h depois do fim (LGPD).

## Link publico (sem conta)

- `GET /s/<token>`: pagina HTML minima, sem login, sem indexacao (`noindex`, `Cache-Control: no-store`), que se
  atualiza a cada 30 s: primeiro nome da dona, situacao ("em atividade", "nao respondeu desde 07:42", "chegou"),
  horario previsto, ultima posicao com a idade ("ha 2 min") e um link para abrir no mapa
  (`https://www.openstreetmap.org/?mlat=..&mlon=..#map=17/../..`). Sem trajeto, sem historico, sem email.
- `GET /s/<token>.json`: os mesmos dados em JSON.
- Token aleatorio de 32 bytes em base64url. Expirado ou desconhecido: 404 com a pagina "Este link expirou".

## Notificacoes (caixa de entrada + push)

Toda notificacao vai para a caixa de entrada do destinatario no banco e, se houver push configurado, tambem
para os aparelhos dele. Sem push configurado (desenvolvimento, testes, iPhone sem conta paga da Apple), o app
busca a caixa de entrada.

| Rota | Corpo | Resposta |
| --- | --- | --- |
| `GET /notifications?since=<ms>` | | 200 `{"notifications": [notification]}` (mais novas primeiro, ate 50). |
| `POST /notifications/<id>/read` | | 204. |
| `POST /push/tokens` | `{"token": "...", "platform": "android" \| "ios"}` | 204 (idempotente). |
| `DELETE /push/tokens/<token>` | | 204. |

`notification`: `{"id": "nt_...", "type": "...", "title": "...", "body": "...", "data": {...}, "createdAt": 0, "readAt": null}`.

Tipos: `contact_invite`, `contact_accepted`, `safety_check`, `safety_alert`, `safety_sos`, `safety_all_clear`.
`data` traz `sessionId`, `shareUrl`, `reason` e `ownerName` quando fizer sentido.

### Enviador de push (plugavel)

`PushSender` no backend com duas implementacoes: `LogPushSender` (padrao: so registra) e `FcmPushSender`
(Firebase Cloud Messaging HTTP v1), ativado so quando `FIREBASE_SERVICE_ACCOUNT` (caminho do JSON da conta de
servico) estiver definido. A caixa de entrada sempre recebe, com ou sem push. iOS (APNs) fica para quando houver
conta paga da Apple.

## Variaveis de ambiente

`SAFETY_TICK_MS`, `SAFETY_SILENCE_MS`, `SAFETY_STOP_MS`, `SAFETY_CHECK_MS`, `PUBLIC_BASE_URL`,
`FIREBASE_SERVICE_ACCOUNT`. Os testes e o E2E usam tempos curtos (ex.: tick 1 s, silencio 20 s, checagem 15 s).

## Decisoes do backend

Lacunas do contrato resolvidas na implementacao (sempre do jeito mais conservador). O app pode contar com elas.

**Contatos**
- O convite e por sentido: A convidar B e B convidar A sao duas relacoes diferentes (cada uma e a lista de
  contatos de confianca de quem convidou). 409 so para convite repetido no mesmo sentido.
- O limite de 3 aceitos tambem vale no aceite: `accept` responde 409 se a dona ja tem 3 aceitos.
- `accept` de um contato ja aceito responde 200 com o contato e nao notifica de novo.
- Convites por conta: no maximo 20 por hora (com sucesso ou nao) -> 429 `muitas tentativas`. Barra o uso do
  404 `sem conta no Rastro` para descobrir quais emails tem conta.
- Excluir a conta (`DELETE /me`) apaga contatos (dos dois lados), sessoes, caixa de entrada e tokens de push, e
  tira a pessoa das sessoes ativas de quem a tinha como contato.

**Sessoes**
- `contactIds` repetidos viram um so. Os contatos precisam ser `outgoing` aceitos da dona.
- `activityGuid` e obrigatorio (texto nao vazio, ate 200 caracteres).
- `positions`, `ok`, `extend` e `sos` em sessao encerrada: 409 `sessao encerrada`. `arrived` em sessao
  encerrada e idempotente: 200 com a sessao sem mudar nada.
- `positions`: `lat`/`lon` precisam vir os dois numeros (na faixa) ou os dois null; `accuracyM` >= 0 ou null;
  `recordedAtMs` inteiro ou null (padrao: agora); `moving`/`paused` booleanos ou ausentes. Uma posicao com
  `recordedAtMs` mais antigo que a atual (fila offline) conta como sinal de vida mas nao troca `lastPosition`.
- Posicoes durante a checagem NAO resolvem a checagem; so `ok`, `extend` ou `arrived`.
- `ok`, `extend` e `sos` contam como sinal de vida (atualizam `lastSignalAt`). `ok` e `extend` tambem reiniciam
  a janela de parada.
- Depois de um alerta, `ok`/`extend` voltam a `active` com `alertedAt: null` (e `check: null`).
- `arrived` depois do alerta tambem manda `safety_all_clear` aos contatos ("confirmou que chegou bem").
- `ok` com o horario ja vencido: a regra do horario so pergunta de novo depois de `SAFETY_SILENCE_MS`
  (senao perguntaria no tick seguinte). Para adiar de verdade, o app usa `extend`.
- SOS nao muda o `status` nem a checagem em curso; cada chamada manda um `safety_sos`. O `data` do SOS traz
  tambem `lat` e `lon` da ultima posicao (quando houver).
- Se todos os contatos sairem no meio da sessao, ela continua; o alerta nao tem para quem ir (so a dona recebe
  o `safety_check`).

**Vigia**
- Ordem das regras quando mais de uma vale: silencio, parada, horario. Parada usa `>=` (10 min de amostras
  paradas completos); silencio usa `>` como no contrato.
- Janela de parada: conta do instante (relogio do servidor) da primeira amostra com `moving: false` e
  `paused: false` depois de uma amostra em movimento ou pausada. Pode disparar ate um intervalo de envio
  (60 s) depois do minimo teorico. Amostra sem `moving`/`paused` nao mexe na janela.
- Nao ha historico de posicoes: o banco guarda so a ultima posicao e o inicio da parada.
- Fim automatico em `etaMs + 6 h`: a sessao fica `ended` sem notificacao; o link continua valendo ate a
  limpeza (se ela nao respondeu, os contatos ainda precisam dele).
- Limpeza: a sessao inteira (posicao e link) e apagada quando `agora > endedAt + 24 h`. As notificacoes ficam
  na caixa de entrada (o link delas deixa de funcionar).
- A trava contra corrida entre o vigia e as rotas e por processo: vale para uma instancia so do servidor.

**Link publico**
- Situacao no JSON (`state`): `active` (inclusive durante a checagem: os contatos so sao avisados no alerta),
  `no_response` (alertada; `sinceMs` = inicio da checagem), `arrived` (`sinceMs` = chegada) e `ended` (fim
  automatico sem alerta).
- Campos do JSON: `firstName`, `state`, `sinceMs`, `etaMs`, `lastPosition`, `lastPositionAgeMs`,
  `lastSignalAt`, `mapUrl`, `generatedAt`.
- Horarios no HTML saem em UTC dentro de `<time datetime>`; um script inline troca pela hora local de quem abre.
  Sem script, aparece "07:42 UTC".
- Cabecalhos: `Cache-Control: no-store`, `X-Robots-Tag: noindex, nofollow`, `Referrer-Policy: no-referrer`
  (o token nao vaza para o OpenStreetMap), CSP sem nada externo, `X-Frame-Options: DENY`.
- O token fica em claro no banco (precisa voltar no `shareUrl`). O log de requisicoes troca o token do link e
  o de push por `<token>`.

**Notificacoes e push**
- `GET /notifications?since=<ms>` devolve as de `createdAt > since`; `since` invalido = 400.
- `POST /notifications/<id>/read` de notificacao alheia ou inexistente = 404.
- `POST /push/tokens` de um token ja registrado por outra conta passa o token para a conta atual (aparelho
  trocou de conta). Token: texto nao vazio de ate 4096 caracteres.
- `DELETE /push/tokens/<token>` (token codificado na URL) responde 204 sempre, mas so apaga se o token for da
  conta autenticada.
- FCM: `data` vai com todos os valores em texto (numeros viram texto, objetos viram JSON), mais `type` e
  `notificationId`; `android.priority: high`. Token removido em 404 ou `errorCode: UNREGISTERED`; 400 de
  payload, 401 e 5xx contam como falha passageira (o token fica). Falha de push nunca derruba a operacao.

**Variavel extra**
- `SAFETY_ETA_MIN_MS` (padrao 300000 = 5 min): o minimo de `etaMs - agora` na criacao da sessao. Existe para o
  E2E testar a regra do horario sem esperar 5 min. Em producao, nao definir.
