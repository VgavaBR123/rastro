# rastro

App open source de **corrida, pedal e caminhada** com GPS — Flutter (Android/iOS) e backend
PostgreSQL/PostGIS. Construído do zero, em abordagem **clean room**: primeiro estudamos como um app
de referência resolve cada problema técnico e registramos em relatórios próprios; depois
implementamos o nosso app a partir desses relatórios, sem copiar código, recursos ou segredos de
terceiros.

## Estrutura do repositório

```
relatorios/   Estudo técnico (manifesto, bibliotecas, gravação GPS, métricas,
              persistência, sincronização, nativo, arquitetura, proposta do app)
app/          Aplicativo Flutter (Android + iOS)
backend/      API em Dart (shelf) + PostgreSQL/PostGIS em Docker
```

> As pastas `apk/`, `analise/` e `tools/rea/` (APKs, saída bruta de análise e ferramentas) ficam
> fora do versionamento de propósito.

## App (`app/`)

Núcleo de gravação em Dart puro e testável: pipeline de pontos com filtro de ruído (corte de
precisão + filtro de aceleração), splits por km/milha com interpolação na marca, elevação,
pausa automática por esporte, dois relógios (tempo total x cronômetro), persistência incremental
com recuperação pós-crash, exportação em arquivo **FIT** e fila de upload. UI em Flutter + Riverpod.

- Rodar os testes: `cd app && flutter test`
- Análise estática: `cd app && flutter analyze`
- Detalhes de arquitetura em [`app/README.md`](app/README.md) e [`relatorios/99-proposta-app.md`](relatorios/99-proposta-app.md).

## Backend (`backend/`)

API que recebe o arquivo FIT da atividade e guarda em PostgreSQL/PostGIS.

- Testes: `cd backend && dart test`
- Subir o banco: `cd backend && docker compose up -d`
- Rodar a API: `cd backend && dart run bin/server.dart`

## Licença

A definir (sugestão: MIT ou Apache-2.0).
