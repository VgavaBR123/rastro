# Nosso app de atividades (Flutter)

App proprio de corrida, pedal e caminhada, escrito do zero (clean room) a partir dos relatorios em
`../relatorios/`. Android + iOS. A parte estudada no Strava foi reimplementada em Dart com as nossas
decisoes (ver `../relatorios/99-proposta-app.md`).

## Stack
- Flutter/Dart; estado com Riverpod.
- Persistencia local: Drift (SQLite), banco dedicado da gravacao.
- Localizacao: geolocator (foreground service no Android, background no iOS).
- Rede/sync: dio + WorkManager; atividade exportada em arquivo FIT (formato aberto).
- Mapas (a plugar): MapLibre (OSS).

## Estrutura de `lib/`
```
recording/
  domain/        # nucleo clean-room (Dart puro, sem I/O): pontos, filtro de ruido,
                 # filtro de aceleracao, splits interpolados (km+milha), elevacao,
                 # relogio (tempo total x cronometro), auto-pause, RecordingSession
  source/        # borda de localizacao (LocationSource + geolocator)
  presentation/  # RecordingController (Riverpod) + estado de UI
persistence/     # Drift: tabelas activities + waypoints, repositorio, recuperacao
sync/
  fit/           # codificador de arquivo FIT (Dart puro)
  upload/        # fila de upload (SyncService, uploader dio), builder de FIT
core/format/     # formatadores de distancia/tempo/pace/velocidade/elevacao
ui/              # telas (Home, RecordingScreen)
app/             # providers (DI) e composicao
main.dart        # ponto de entrada (ProviderScope + Home)
```

## Decisoes do nucleo de gravacao (dos relatorios 03-05)
- Filtro de qualidade: descarta precisao ausente/<=0 ou > ~150 m; filtro de aceleracao de 3 pontos
  (rejeita saltos acima de ~1 g); deslocamento minimo ~3 m; timestamp duplicado.
- Dois relogios: tempo total e tempo de cronometro (exclui pausas). Pace/splits usam o cronometro.
- Splits de km e milha em paralelo, fechados na marca exata por interpolacao linear de tempo.
- Elevacao: altitude (corrigida para o geoide na borda) acumulada com limiar anti-ruido.
- Persistencia incremental + recuperacao pos-crash (atividade `isFinished=false` e replay dos pontos).

## Testes (shift-left)
- Unitarios do dominio, persistencia (banco em memoria), FIT, formatters, location mapping, controller.
- Integracao: `test/integration/recording_flow_test.dart` com fixture de rota
  (`test/fixtures/sample_route.dart`): gravacao -> metricas -> persistencia -> recuperacao.
- Rodar: `flutter test`. Analise estatica: `flutter analyze`.
- Estrategia completa em `TESTING.md`.

## Como rodar
1. Ter o Flutter SDK (neste ambiente: `C:\dev\flutter`; use `export PATH="/c/dev/flutter/bin:$PATH"`).
2. `flutter pub get`
3. `dart run build_runner build` (gera o codigo do Drift)
4. `flutter test`
5. `flutter run` (Android/iOS; para Android e preciso cmdline-tools + aceite de licencas do SDK).
