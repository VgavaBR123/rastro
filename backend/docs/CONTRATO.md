# Contrato da API (fonte de verdade)

Backend proprio do app de atividades (clean room; nunca fala com servidores de terceiros).
App e backend sao escritos contra este arquivo. Mudou aqui, muda nos dois.

Convencoes:
- JSON em tudo (exceto upload/download de FIT). Erro = `{"error": "<mensagem>"}`.
- Autenticacao: `Authorization: Bearer <token>` (token opaco, 180 dias).
- **401 significa so "sessao invalida/ausente"** (o app desloga ao receber 401 de rota protegida).
  Senha atual errada em rota protegida = **403**, nunca 401.
- Tempos em epoch ms (int). Distancias em metros (double).
- Recurso de outro usuario = 404 (igual a inexistente).
- Bloqueio por excesso de tentativas = 429 + header `Retry-After` (segundos).

## Saude

| Rota | Resposta |
| --- | --- |
| `GET /health` | 200 `{"status":"ok","db":"ok"}`; 503 `{"status":"degraded","db":"erro"}` se o banco nao responde |

## Conta

| Rota | Corpo | Resposta |
| --- | --- | --- |
| `POST /auth/register` | `{email,password,displayName}` | 201 `{token,user}`; 400; 409 email existe; 429 |
| `POST /auth/login` | `{email,password}` | 200 `{token,user}`; 401; 429 |
| `POST /auth/logout` (Bearer) | - | 204 (revoga o token usado) |
| `POST /auth/logout-all` (Bearer) | - | 204 (revoga TODAS as sessoes do usuario, inclusive a atual) |
| `POST /auth/password/change` (Bearer) | `{currentPassword,newPassword}` | 204 e revoga as OUTRAS sessoes (a atual segue valida); 403 senha atual errada; 400 nova < 8 |
| `POST /auth/password/forgot` | `{email}` | **202 sempre** (nao revela se o email existe). Se existe: gera codigo de 6 digitos, valido 15 min, e envia pelo Mailer. 429 se passar de 3/email/hora ou 10/IP/hora |
| `POST /auth/password/reset` | `{email,code,newPassword}` | 200 `{token,user}` (ja entra) e revoga todas as sessoes anteriores; 400 `"codigo invalido ou expirado"` (generico); 400 nova < 8. Cada codigo aceita no maximo 5 tentativas erradas, depois fica invalido |
| `GET /me` (Bearer) | - | 200 `{user,stats}` |
| `PATCH /me` (Bearer) | `{displayName}` | 200 `{user}`; 400 |
| `DELETE /me` (Bearer) | `{password}` | 204: apaga usuario, sessoes, codigos e TODAS as atividades dele; 403 senha errada |

`user` = `{id, email, displayName, createdAt}`.

Detalhes (definidos na implementacao):
- `password/change` e `DELETE /me`: 5 senhas erradas por usuario em 15 min (somando as duas rotas)
  = 429 + `Retry-After`; impede que um token roubado sirva para adivinhar a senha.
- Corpo que nao e JSON valido = 400 em todas as rotas com corpo.
- No reset, senha nova curta = 400 antes de olhar o codigo (nao gasta tentativa).

`stats` = `{activityCount, totalDistanceMeters, totalTimerTimeMs, byType}` onde
`byType` = `{"run":{"count","distanceMeters"},"ride":{...},"walk":{...}}` (so tipos com atividade;
atividades sem tipo nao entram em byType). `totalDistanceMeters` usa `distanceMeters` da atividade
(informado pelo app) e cai para o comprimento da rota quando ausente.

## Atividades

Upload: `POST /uploads` (Bearer), corpo = FIT em `application/octet-stream`. Headers:
- `x-activity-guid` (idempotencia por usuario + guid; reenvio = 200 com o existente, 201 se novo)
- opcionais, metadados calculados no app (o FIT minimo nao os carrega):
  `x-activity-type` (`run` | `ride` | `walk`; outro valor = ignorado),
  `x-start-time` (epoch ms), `x-timer-time-ms` (tempo em movimento), `x-distance-meters`,
  `x-rpe` (esforco percebido, inteiro de 1 a 10) e
  `x-mood` (`great` | `good` | `ok` | `tired` | `awful`), os dois do Fechamento gentil (F04).
  Valor invalido/negativo = ignorado (nao e erro). `x-activity-type` e `x-mood` nao diferenciam caixa.

Objeto `activity` (mesmo formato em todas as rotas abaixo):

```json
{
  "id": "up_...", "uploadId": "up_...", "status": "received",
  "receivedAt": 0, "sizeBytes": 0, "activityGuid": "act_...",
  "activityType": "run", "name": null,
  "startTime": 0, "elapsedTimeMs": 0, "timerTimeMs": 0,
  "distanceMeters": 0.0, "pointCount": 0, "lengthMeters": 0.0,
  "rpe": null, "mood": null
}
```
- `startTime`: header `x-start-time`, senao timestamp do 1o record do FIT, senao null.
- `elapsedTimeMs`: ultimo menos primeiro timestamp dos records do FIT, senao null.
- campos sem valor vem `null` (sempre presentes).

| Rota | Resposta |
| --- | --- |
| `GET /activities?limit=20&before=<cursor>` (Bearer) | 200 `{"activities":[activity...],"nextCursor":string\|null}`. Ordem: mais recente primeiro por `startTime` (fallback `receivedAt`), desempate por id. `limit` 1..100 (padrao 20; fora disso = 400). `nextCursor` opaco; null na ultima pagina; `before` invalido = 400 |
| `GET /activities/<id>` e `GET /uploads/<id>` (Bearer) | 200 activity; 404 |
| `PATCH /activities/<id>` (Bearer) | corpo `{name}` (string; vazio ou null = remove o nome; trim; max 120 caracteres Unicode senao 400; sem o campo `name` = 400) -> 200 activity |
| `DELETE /activities/<id>` (Bearer) | 204; 404. Apos apagar, reenviar o mesmo guid cria de novo (201) |
| `GET /activities/<id>/route` e `/uploads/<id>/route` (Bearer) | 200 Feature GeoJSON; 204 sem rota; 404 |
| `GET /activities/<id>/fit` (Bearer) | 200 bytes do FIT original, `content-type: application/vnd.ant.fit`, `content-disposition: attachment; filename="<guid ou id>.fit"`; 404 |

## E-mail (recuperacao de senha)

Interface `Mailer` no backend. Selecao por variavel de ambiente:
- `MAILER=console` (padrao): imprime destinatario e codigo no log do servidor (desenvolvimento).
- `MAILER=smtp`: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `SMTP_SSL`.
O provedor real fica para a implantacao.

## IP do cliente (limites por IP)

`TRUST_PROXY=0` (padrao): IP da conexao. `TRUST_PROXY=1`: ultimo endereco do `X-Forwarded-For`,
so atras de proxy que o sobrescreve (o Caddy de `deploy/`). Ver `docs/IMPLANTACAO.md`.
