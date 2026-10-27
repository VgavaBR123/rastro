# Backend (API de atividades)

API em Dart (shelf) que recebe o arquivo FIT gerado pelo app, guarda o arquivo bruto e
extrai a rota para uma geometria PostGIS. Nada aqui fala com o Strava.

## Contrato

**A fonte de verdade e [`docs/CONTRATO.md`](docs/CONTRATO.md)**: rotas, status, formatos
do `user`, do `activity` e do `stats`. App e backend sao escritos contra ele. A tabela
abaixo e so um indice; em caso de divergencia vale o CONTRATO.

| Rota | Resumo |
| --- | --- |
| `GET /health` | 200 `{"status":"ok","db":"ok"}`; 503 `{"status":"degraded","db":"erro"}` |
| `POST /auth/register` | 201 `{token,user}`; 400; 409; 429 |
| `POST /auth/login` | 200 `{token,user}`; 401; 429 |
| `POST /auth/logout` (B) | 204, revoga o token usado |
| `POST /auth/logout-all` (B) | 204, revoga todas as sessoes do usuario |
| `POST /auth/password/change` (B) | 204, revoga as outras sessoes; 403 senha atual errada; 400 |
| `POST /auth/password/forgot` | 202 sempre; codigo de 6 digitos pelo Mailer; 429 |
| `POST /auth/password/reset` | 200 `{token,user}`; 400 `codigo invalido ou expirado` |
| `GET /me` (B) | 200 `{user,stats}` (stats com `totalTimerTimeMs` e `byType`) |
| `PATCH /me` (B) | 200 `{user}`; 400 |
| `DELETE /me` (B) | body `{password}`; 204 apaga tudo do usuario; 403 |
| `POST /uploads` (B) | FIT no corpo; headers `x-activity-guid`, `x-activity-type`, `x-start-time`, `x-timer-time-ms`, `x-distance-meters`; 201 novo, 200 reenvio |
| `GET /activities?limit&before` (B) | 200 `{activities,nextCursor}` (keyset, cursor opaco) |
| `GET /activities/<id>`, `GET /uploads/<id>` (B) | 200 activity; 404 |
| `PATCH /activities/<id>` (B) | `{name}` ate 120 caracteres; 200 activity; 400; 404 |
| `DELETE /activities/<id>` (B) | 204; 404 |
| `GET /activities/<id>/route`, `GET /uploads/<id>/route` (B) | 200 Feature; 204 sem rota; 404 |
| `GET /activities/<id>/fit` (B) | 200 bytes originais (`application/vnd.ant.fit`); 404 |

(B) = exige `Authorization: Bearer <token>`; sem token, com token desconhecido, revogado ou
expirado responde 401. 401 so significa sessao invalida: senha atual errada e 403.

Detalhes de implementacao que o CONTRATO deixa em aberto:

- Metadados invalidos no upload (tipo fora de `run|ride|walk`, numero negativo ou que
  nao parseia) sao ignorados. O tipo aceita caixa diferente (`RUN` vira `run`).
  `startTime`/`elapsedTimeMs` derivados do FIT usam os records com posicao valida
  (os que o decodificador devolve). O reenvio do mesmo guid devolve o registro existente
  e ignora os metadados novos.
- Listagem: ordem `COALESCE(startTime, receivedAt) DESC, id DESC` (id comparado byte a
  byte). O cursor e o par (chave, id) do ultimo item em base64url; cursor que a API nao
  emitiu = 400. `limit` fora de 1..100 = 400.
- `PATCH /activities/<id>`: o nome e trimado; o limite de 120 conta caracteres Unicode
  (code points). Corpo sem o campo `name`, ou `name` que nao e texto nem null = 400.
- `/fit`: o `filename` usa o guid (ou o id) com tudo fora de `[A-Za-z0-9._-]` trocado
  por `_`, para nao quebrar o header.
- `forgot` com corpo que nao e JSON = 400 (qualquer JSON valido = 202). O envio do email
  e disparado sem esperar (a demora do SMTP revelaria que o email existe); falha de envio
  vai para o log, sem o codigo.
- `reset`: senha nova curta responde 400 antes de olhar o codigo (nao gasta tentativa).
  A tentativa e consumida ANTES de conferir o codigo (UPDATE atomico), entao tentativas
  simultaneas nao passam de 5. Sucesso troca a senha, revoga todas as sessoes e zera o
  limite de falhas de login daquele email.
- `change` e `DELETE /me`: alem do 403, 5 senhas erradas por usuario em 15 min geram
  429 + `Retry-After` (as duas rotas somam), para um token roubado nao servir de
  oraculo de senha.
- `stats.totalTimerTimeMs` soma so o `timerTimeMs` informado (sem fallback).

Seguranca:

- Senha: PBKDF2-HMAC-SHA256 (`lib/src/auth/password.dart`, sobre o pacote oficial
  `crypto`), salt aleatorio de 16 bytes por usuario, 120000 iteracoes. Guardada como
  `pbkdf2_sha256$<iter>$<salt_b64>$<hash_b64>`; comparacao em tempo constante. O login
  de email inexistente tambem roda um PBKDF2 para nao revelar, pelo tempo, quais emails
  existem.
- Token: 32 bytes de `Random.secure()` em base64url sem padding. A tabela `sessions` guarda
  so o sha256 (hex) do token; validade de 180 dias.
- Senha e token nunca vao para o log (`logRequests` registra so metodo, caminho e status).
- Codigo de recuperacao: 6 digitos de `Random.secure()`, valido 15 min, 5 tentativas.
  A tabela `password_resets` guarda so o hash (PBKDF2 com salt, 1000 iteracoes, mesmo
  formato das senhas); pedido novo substitui o anterior. Conferencia em tempo constante.
  O codigo so aparece em log com `MAILER=console`.

Limite de tentativas (`lib/src/auth/rate_limiter.dart`, janela deslizante):

| Rota | Limite |
| --- | --- |
| `POST /auth/login` | 5 falhas por email (normalizado: trim + lowercase) em 15 min. Email inexistente conta igual a senha errada. Login bem-sucedido zera o contador daquele email. |
| `POST /auth/login` | 20 falhas por IP em 15 min (qualquer email; o sucesso nao zera este). |
| `POST /auth/register` | 10 tentativas por IP por hora, com sucesso ou nao (400 e 409 contam). |
| `POST /auth/password/forgot` | 3 pedidos por email e 10 por IP por hora (email existente ou nao). |
| `POST /auth/password/change`, `DELETE /me` | 5 senhas erradas por usuario em 15 min. |

Bloqueado, a rota responde **429** `{"error": "muitas tentativas"}` com o header
**`Retry-After`** = segundos inteiros (arredondados para cima, >= 1) ate a tentativa mais
antiga sair da janela. No login o 429 sai antes de olhar a senha: nem a senha correta
passa e nao roda PBKDF2. Tentativa bloqueada nao conta. As demais rotas nao tem limite
(o `reset` e limitado pelas 5 tentativas do codigo).

O IP vem da conexao TCP (`shelf.io.connection_info`); `X-Forwarded-For` e ignorado por
padrao porque o cliente pode inventa-lo. Atras de um proxy reverso confiavel, passe
`clientIp: extratorDeIp(confiarEmForwardedFor: true)` ao `createApi` (usa o ultimo
endereco da lista, o que o proxy acrescentou). Os limites sao injetaveis por
`rateLimits: AuthRateLimits(...)`.

O estado fica **em memoria do processo**: serve para uma instancia unica. Reiniciar o
servidor zera os contadores, e com varias instancias cada uma teria o seu (o limite efetivo
se multiplica); nesse cenario precisaria de armazenamento compartilhado (tabela no Postgres
ou Redis). Chaves antigas sao podadas na escrita, no maximo uma varredura por janela.

### Atividades

Todas exigem Bearer e so enxergam os uploads do proprio usuario: upload de outro usuario
responde **404, igual a inexistente** (nao revela que o id existe). Formato do objeto
`activity` no CONTRATO; todos os campos sempre presentes (podem vir `null`).

`GET /activities/<id>/route` (e o alias `/uploads/<id>/route`) responde:

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

Variaveis:

| Variavel | Uso |
| --- | --- |
| `PORT` | porta HTTP (padrao 8080; localmente use 8081) |
| `USE_INMEMORY` | `1` = stores em memoria, sem banco |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | conexao com o Postgres |
| `MAILER` | `console` (padrao: codigo de recuperacao no log, so para desenvolvimento) ou `smtp` |
| `SMTP_HOST`, `SMTP_FROM` | obrigatorias com `MAILER=smtp` (o servidor nao sobe sem elas) |
| `SMTP_PORT` | padrao 587 (ou 465 com `SMTP_SSL`) |
| `SMTP_USER`, `SMTP_PASSWORD` | credenciais do servidor SMTP (opcionais) |
| `SMTP_SSL` | `true`/`1` = TLS direto (465). Senao STARTTLS; o pacote `mailer` recusa enviar sem TLS |

`MAILER` com outro valor derruba a subida com erro.

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

4. Metadados, nome, download e recuperacao de senha:

   ```sh
   curl -X POST http://localhost:8081/uploads -H "authorization: Bearer $TOKEN" \
     -H "x-activity-guid: guid-smoke-2" -H "x-activity-type: run" \
     -H "x-timer-time-ms: 540000" -H "x-distance-meters: 812.5" --data-binary @/tmp/exemplo.fit
   curl -H "authorization: Bearer $TOKEN" "http://localhost:8081/activities?limit=20"
   curl -X PATCH http://localhost:8081/activities/<id> -H "authorization: Bearer $TOKEN" \
     -H "content-type: application/json" -d '{"name":"Corrida"}'
   curl -o baixado.fit -H "authorization: Bearer $TOKEN" http://localhost:8081/activities/<id>/fit
   cmp /tmp/exemplo.fit baixado.fit   # identicos
   curl -X POST http://localhost:8081/auth/password/forgot \
     -H "content-type: application/json" -d '{"email":"eu@exemplo.com"}'   # 202
   # com MAILER=console o codigo aparece no log do servidor:
   # [mailer:console] codigo de recuperacao para eu@exemplo.com: 123456 (valido por 15 min)
   curl -X POST http://localhost:8081/auth/password/reset -H "content-type: application/json" \
     -d '{"email":"eu@exemplo.com","code":"123456","newPassword":"senha-nova-1"}'  # 200 {token,user}
   ```

5. Isolamento e logout: com o token de uma segunda conta, `GET /uploads/<id da primeira>`
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
docker exec backend-db-1 psql -U postgres -d atividades -c \
  "SELECT user_id, left(code_hash, 19), attempts FROM password_resets;" # pbkdf2_sha256$1000
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
Depois vieram: FK `uploads.user_id` com `ON DELETE CASCADE` (a antiga e trocada so se
ainda nao for cascata), colunas de metadados (`activity_type`, `name`, `start_time`,
`elapsed_time_ms`, `timer_time_ms`, `distance_meters`), o indice de paginacao
`idx_uploads_user_sort` e a tabela `password_resets` (FK em cascata para `users`).

Correcao de dados: ate esta versao o INSERT passava o FIT sem tipo explicito e o driver
gravava no `bytea` o TEXTO do array (`{14,32,...}`), nao os bytes. O INSERT agora usa
`Type.byteArray`, e `_ensureSchema` converte de volta as linhas antigas nesse formato (um
FIT de verdade nunca comeca com `{`). Rotas e `point_count` antigos nao foram afetados
porque eram calculados em Dart antes do INSERT.
Para comecar do zero: `docker compose down -v && docker compose up -d`.

## Riscos conhecidos

- Limite de tentativas so em memoria (zera ao reiniciar; nao compartilhado entre
  instancias). Atras de NAT/proxy sem `confiarEmForwardedFor`, todos os clientes
  dividem o mesmo limite por IP. Bloqueio por email permite a um atacante travar o login
  de uma conta conhecida por ate 15 min (trade-off aceito contra forca bruta).
- Sem verificacao de email no cadastro. A recuperacao de senha depende de um provedor
  SMTP real em producao (`MAILER=smtp`); com `console` o codigo vai para o log.
- Codigo de 6 digitos: com o banco vazado, o hash de um pedido ativo e quebravel por
  forca bruta (1 milhao de candidatos); a protecao real e a validade curta (15 min) e o
  limite de 5 tentativas.
- Uploads antigos (antes dos metadados) ficam com `startTime`/`elapsedTimeMs` null e sao
  ordenados por `receivedAt`; nao ha backfill a partir do FIT guardado.
- Sessoes expiradas so sao apagadas quando alguem tenta usa-las (sem limpeza periodica).
- Sem TLS no servidor: em producao precisa de um proxy HTTPS na frente, senao o token
  trafega em claro.

## Testes

```sh
dart analyze && dart test
```
