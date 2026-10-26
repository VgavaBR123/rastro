# Backend (API de atividades)

API em Dart (shelf) que recebe o arquivo FIT gerado pelo app, guarda o arquivo bruto e
extrai a rota para uma geometria PostGIS. Nada aqui fala com o Strava.

## Contrato

JSON em tudo (exceto o corpo do upload). Rotas marcadas com **(B)** exigem
`Authorization: Bearer <token>` e respondem 401 `{"error"}` sem token, com token
desconhecido, revogado ou expirado.

### Contas

`user` = `{"id": string, "email": string, "displayName": string, "createdAt": epoch ms}`.

| Rota | Descricao |
| --- | --- |
| `POST /auth/register` | body `{"email","password","displayName"}` -> 201 `{"token","user"}`. Email normalizado (trim + lowercase). 400 `{"error"}` se email invalido (precisa de `@` e ponto no dominio), senha com menos de 8 caracteres ou `displayName` vazio apos trim. 409 se o email ja existe (qualquer caixa). |
| `POST /auth/login` | body `{"email","password"}` -> 200 `{"token","user"}`. 401 com a **mesma mensagem** para email inexistente e senha errada. Cada login abre uma sessao nova (o app pode estar logado em mais de um aparelho). |
| `POST /auth/logout` (B) | 204; revoga so o token usado. |
| `GET /me` (B) | 200 `{"user", "stats": {"activityCount": int, "totalDistanceMeters": double}}`. Stats sobre os uploads do proprio usuario; distancia = soma do `lengthMeters` das rotas (0 sem rota). |
| `PATCH /me` (B) | body `{"displayName"}` -> 200 `{"user"}`; 400 se vazio. |

Seguranca:

- Senha: PBKDF2-HMAC-SHA256 (`lib/src/auth/password.dart`, sobre o pacote oficial
  `crypto`), salt aleatorio de 16 bytes por usuario, 120000 iteracoes. Guardada como
  `pbkdf2_sha256$<iter>$<salt_b64>$<hash_b64>`; comparacao em tempo constante. O login
  de email inexistente tambem roda um PBKDF2 para nao revelar, pelo tempo, quais emails
  existem.
- Token: 32 bytes de `Random.secure()` em base64url sem padding. A tabela `sessions` guarda
  so o sha256 (hex) do token; validade de 180 dias.
- Senha e token nunca vao para o log (`logRequests` registra so metodo, caminho e status).

### Atividades

Todas exigem Bearer e so enxergam os uploads do proprio usuario: upload de outro usuario
responde **404, igual a inexistente** (nao revela que o id existe).

| Rota | Descricao |
| --- | --- |
| `GET /health` | publico. `{"status":"ok"}` |
| `POST /uploads` (B) | corpo = arquivo FIT em `application/octet-stream`, header opcional `x-activity-guid`. Responde 201 com `{id, uploadId, status, receivedAt, sizeBytes, activityGuid}`. **Idempotente por (usuario, `x-activity-guid`)**: reenvio da mesma atividade pelo mesmo usuario nao grava de novo e responde 200 com o upload existente; o mesmo guid vindo de outro usuario gera outro upload (indice unico parcial `uq_uploads_user_activity_guid`, criado tambem ao conectar). Sem guid nao ha deduplicacao. Corpo vazio = 400. |
| `GET /uploads/<id>` (B) | metadados de um upload (404 se nao existe ou e de outro usuario) |
| `GET /uploads/<id>/route` (B) | rota como Feature GeoJSON. 200 com a rota, **204 sem corpo** se o upload existe mas nao tem rota, 404 se o id nao existe (ou e de outro usuario) |
| `GET /activities` (B) | ultimos uploads do usuario |

`GET /uploads/<id>` e `GET /activities` devolvem, alem de `id`, `uploadId`, `status`,
`receivedAt`, `sizeBytes` e `activityGuid`, dois campos de metrica que estao **sempre
presentes** (podem vir `null`, para o cliente nao precisar distinguir "campo ausente" de
"sem rota"):

- `pointCount`: pontos com posicao valida lidos do FIT; `null` quando a decodificacao falhou.
- `lengthMeters`: comprimento da rota em metros; `null` quando nao ha rota.

`GET /uploads/<id>/route` responde:

```json
{
  "type": "Feature",
  "geometry": {"type": "LineString", "coordinates": [[-46.656, -23.561], ["..."]]},
  "properties": {"pointCount": 60, "lengthMeters": 1115.07}
}
```

Coordenadas na ordem GeoJSON `[longitude, latitude]`, SRID 4326.

Por que **204** e nao 404 quando nao ha rota: o upload existe e continua acessivel em
`GET /uploads/<id>`. Responder 404 faria o cliente concluir que o upload sumiu ou que o id
esta errado. 204 diz exatamente o que aconteceu — o recurso existe e nao tem representacao
(ainda): o FIT era ilegivel ou tinha menos de 2 pontos, e pode ser reprocessado depois.
Assim o 404 fica reservado para "id desconhecido".

O servidor decodifica o FIT (`lib/src/fit_decoder.dart`) e grava `route`
(`geometry(LineString,4326)`) e `point_count`. Se a decodificacao falhar ou houver menos de
2 pontos validos, o upload continua valendo e `route` fica NULL — o arquivo bruto esta em
`fit` e pode ser reprocessado depois.

No Postgres a rota sai de `ST_AsGeoJSON(route)` e o comprimento de
`ST_Length(route::geography)`. O `InMemoryActivityStore` (testes e `USE_INMEMORY=1`) monta a
mesma resposta decodificando o FIT guardado com `decodeFitRecords` e medindo com haversine
(`comprimentoMetros`); PostGIS mede sobre o elipsoide WGS84, entao os dois valores diferem
em cerca de 0,2%.

## Rodando local

O banco sobe em **5433** no host (a 5432 costuma estar ocupada por outro projeto):

```sh
docker compose up -d
PORT=8081 DB_PORT=5433 dart run bin/server.dart
```

Sem Docker, da para rodar so com store em memoria: `USE_INMEMORY=1 dart run bin/server.dart`.

Variaveis: `PORT`, `USE_INMEMORY`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.

## Smoke test de ponta a ponta

1. Gere um FIT com o codificador do app (dentro de `app/`), num diretorio fora do repo:

   ```sh
   dart run tool/gen_sample_fit.dart /tmp/exemplo.fit
   ```

2. Crie uma conta e guarde o token (se o email ja existir, `POST /auth/login` com
   `{"email","password"}`):

   ```sh
   curl -s -X POST http://localhost:8081/auth/register \
     -H "content-type: application/json" \
     -d '{"email":"eu@exemplo.com","password":"senha-forte-1","displayName":"Eu"}'
   # -> 201 {"token":"...","user":{...}}
   TOKEN=<token devolvido>
   ```

3. Envie e confira:

   ```sh
   curl -X POST http://localhost:8081/uploads \
     -H "authorization: Bearer $TOKEN" \
     -H "content-type: application/octet-stream" \
     -H "x-activity-guid: guid-smoke-1" \
     --data-binary @/tmp/exemplo.fit
   # -> 201; o mesmo comando de novo -> 200 com o mesmo uploadId

   curl -H "authorization: Bearer $TOKEN" http://localhost:8081/me
   # -> stats.activityCount = 1, stats.totalDistanceMeters ~ 809

   docker exec backend-db-1 psql -U postgres -d atividades -c \
     "SELECT id, user_id, point_count, ST_NumPoints(route) pts, ROUND(ST_Length(route::geography)) metros FROM uploads;"
   ```

4. Isolamento e logout: com o token de uma segunda conta, `GET /uploads/<id da primeira>`
   responde 404; `POST /auth/logout` com o primeiro token responde 204 e, depois dele,
   `GET /me` com o mesmo token responde 401.

Resultado esperado para o FIT de exemplo (60 pontos): `point_count = 60`, `pts = 60`,
`metros` por volta de 800.

Conferencia de seguranca no banco:

```sh
docker exec backend-db-1 psql -U postgres -d atividades -c \
  "SELECT email, left(password_hash, 21) FROM users;"    # pbkdf2_sha256$120000
docker exec backend-db-1 psql -U postgres -d atividades -c \
  "SELECT token_hash, user_id, expires_at FROM sessions;" # so o sha256 em hex (64 chars)
```

## Apontando o app para ca

```sh
flutter run --dart-define=SYNC_BASE_URL=http://10.0.2.2:8081   # emulador Android
flutter run --dart-define=SYNC_BASE_URL=http://localhost:8081  # simulador iOS / desktop
```

Sem a flag o app usa `https://example.invalid` de proposito (nenhum upload sai da maquina).

## Esquema

`db/init.sql` roda na primeira subida do container. O servidor aplica as mesmas mudancas
de forma idempotente ao conectar (`_ensureSchema` em `postgres_store.dart`), entao um volume
antigo e migrado sem recriar: cria `users` e `sessions`, adiciona `uploads.user_id`
(NULL = upload anterior as contas, invisivel pela API) e troca o indice unico
`uq_uploads_activity_guid` por `uq_uploads_user_activity_guid (user_id, activity_guid)`.
Para comecar do zero: `docker compose down -v && docker compose up -d`.

## Riscos conhecidos

- Sem rate limit nem bloqueio por tentativas em `/auth/login` e `/auth/register`.
- Sem verificacao de email nem troca/recuperacao de senha.
- Sessoes expiradas so sao apagadas quando alguem tenta usa-las (sem limpeza periodica).
- Sem TLS no servidor: em producao precisa de um proxy HTTPS na frente, senao o token
  trafega em claro.

## Testes

```sh
dart analyze && dart test
```
