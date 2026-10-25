# Backend (API de atividades)

API em Dart (shelf) que recebe o arquivo FIT gerado pelo app, guarda o arquivo bruto e
extrai a rota para uma geometria PostGIS. Nada aqui fala com o Strava.

## Contrato

| Rota | Descricao |
| --- | --- |
| `GET /health` | `{"status":"ok"}` |
| `POST /uploads` | corpo = arquivo FIT em `application/octet-stream`, header opcional `x-activity-guid`. Responde 201 com `{id, uploadId, status, receivedAt, sizeBytes, activityGuid}`. Corpo vazio = 400. |
| `GET /uploads/<id>` | metadados de um upload (404 se nao existe) |
| `GET /activities` | ultimos uploads |

O servidor decodifica o FIT (`lib/src/fit_decoder.dart`) e grava `route`
(`geometry(LineString,4326)`) e `point_count`. Se a decodificacao falhar ou houver menos de
2 pontos validos, o upload continua valendo e `route` fica NULL — o arquivo bruto esta em
`fit` e pode ser reprocessado depois.

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
