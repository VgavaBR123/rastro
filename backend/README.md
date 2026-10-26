# Backend (API de atividades)

API em Dart (shelf) que recebe o arquivo FIT gerado pelo app, guarda o arquivo bruto e
extrai a rota para uma geometria PostGIS. Nada aqui fala com o Strava.

## Contrato

| Rota | Descricao |
| --- | --- |
| `GET /health` | `{"status":"ok"}` |
| `POST /uploads` | corpo = arquivo FIT em `application/octet-stream`, header opcional `x-activity-guid`. Responde 201 com `{id, uploadId, status, receivedAt, sizeBytes, activityGuid}`. **Idempotente por `x-activity-guid`**: reenvio da mesma atividade nao grava de novo e responde 200 com o upload existente (indice unico parcial `uq_uploads_activity_guid`, criado tambem ao conectar). Sem guid nao ha deduplicacao. Corpo vazio = 400. |
| `GET /uploads/<id>` | metadados de um upload (404 se nao existe) |
| `GET /uploads/<id>/route` | rota como Feature GeoJSON. 200 com a rota, **204 sem corpo** se o upload existe mas nao tem rota, 404 se o id nao existe |
| `GET /activities` | ultimos uploads |

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

1. Gere um FIT com o codificador do app (dentro de `app/`):

   ```sh
   dart run tool/gen_sample_fit.dart ../.tmp/exemplo.fit
   ```

2. Envie e confira:

   ```sh
   curl -X POST http://localhost:8081/uploads \
     -H "content-type: application/octet-stream" \
     -H "x-activity-guid: guid-smoke-1" \
     --data-binary @../.tmp/exemplo.fit

   docker exec backend-db-1 psql -U postgres -d atividades -c \
     "SELECT id, point_count, ST_NumPoints(route) pts, ROUND(ST_Length(route::geography)) metros FROM uploads;"
   ```

Resultado esperado para o FIT de exemplo (60 pontos): `point_count = 60`, `pts = 60`,
`metros` por volta de 800.

## Apontando o app para ca

```sh
flutter run --dart-define=SYNC_BASE_URL=http://10.0.2.2:8081   # emulador Android
flutter run --dart-define=SYNC_BASE_URL=http://localhost:8081  # simulador iOS / desktop
```

Sem a flag o app usa `https://example.invalid` de proposito (nenhum upload sai da maquina).

## Esquema

`db/init.sql` roda na primeira subida do container. Ao mudar o esquema, recrie o volume:
`docker compose down -v && docker compose up -d`.

## Testes

```sh
dart analyze && dart test
```
