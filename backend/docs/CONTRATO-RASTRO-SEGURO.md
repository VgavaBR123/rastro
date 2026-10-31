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
