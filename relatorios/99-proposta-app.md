# 99 - Proposta de arquitetura do nosso app

> Base: sintese dos relatorios 01-08. Abordagem clean room -- a proposta vem do entendimento
> registrado em `relatorios/`, nunca de codigo decompilado. A fase de construcao em `app/` so comeca
> quando o Gava pedir, com a stack confirmada.

## Resumo

Proponho um app multiplataforma (Android + iOS) em **Flutter/Dart**, offline-first, modularizado por
feature, com o nucleo de gravacao (pipeline de pontos, filtro, metricas, persistencia) em Dart puro e
uma borda fina de localizacao nativa por plugin em cada SO. Metricas calculadas no cliente e
sincronizacao por fila (WorkManager no Android, BGTaskScheduler no iOS) enviando arquivos FIT para um
backend proprio (PostgreSQL/PostGIS em Docker). As dependencias de terceiros proprietarias do Strava
sao trocadas por equivalentes open source (mapas em MapLibre, crash em Sentry) ou simplesmente
omitidas (marketing, atribuicao, chat, suporte). O nucleo imita as decisoes tecnicas boas do Strava
(um servico de localizacao em primeiro plano, filtro de qualidade por precisao e aceleracao, splits
com interpolacao, recuperacao de crash) e evita o que nao nos serve (monoproceso, nuvem de SDKs, UI
100% server-driven).

## Principios

1. **Clean room**: implementar a partir destes relatorios, sem consultar `analise/`.
2. **Offline-first**: a atividade e completa e recuperavel no aparelho antes de qualquer rede.
3. **Privacidade**: dados de localizacao sao sensiveis; minimizar coleta, sem SDKs de ads/atribuicao,
   backup seletivo, zonas de privacidade no futuro.
4. **Open source primeiro**: preferir libs com licenca permissiva; sem motores proprietarios.
5. **Resiliencia**: a gravacao nao pode se perder por crash da UI.

## Stack recomendada

Requisito do Gava: a ferramenta precisa rodar em **Android e iOS**. Com isso firme, a recomendacao e:

- **Cliente: Flutter + Dart.** Um unico codigo para os dois SOs. O miolo que estudamos (modelo de
  ponto, filtros, dois relogios, splits com interpolacao, elevacao, persistencia, fila) e logica pura
  e vira **Dart portavel 1:1**. UI, mapas e navegacao sao pontos fortes do Flutter.
- **Borda de localizacao nativa por plugin.** A gravacao em si continua especifica de plataforma: no
  Android e um foreground service `location`; no iOS e Core Location com *background location updates*
  (regras diferentes e mais restritivas, sem equivalente a FGS). A matematica fica em Dart; so a
  captura e nativa. **Opcao primaria OSS: `geolocator`** -- a doc atual (verificada via Context7)
  mostra que ele ja traz `ForegroundNotificationConfig` com `enableWakeLock` no Android e
  `AppleSettings(activityType: fitness)` no iOS de fabrica, cobrindo a gravacao em background nos dois
  SOs sem lib paga. **Plano B: `flutter_background_geolocation`** (mais robusto em cenarios extremos,
  mas licenca de release paga no Android). Para o nosso alvo da etapa 03, configurar o geolocator com
  `distanceFilter: 0` e intervalo de 1 s (o exemplo da doc usa 100 m / 10 s -- precisa ajustar).
- **Backend: PostgreSQL + PostGIS em Docker**, conforme o CLAUDE.md, com uma API REST propria.
- **Transporte de atividade: arquivo FIT** (formato aberto), como o Strava.

Plano B, se a gravacao exigir controle de background mais fino do que os plugins entregam: **Kotlin
Multiplatform** (logica compartilhada, gravacao e UI nativas). Mas o ponto de partida e Flutter.

Mapeamento de bibliotecas Flutter por camada:

| Camada (etapa) | Flutter |
| --- | --- |
| Gravacao/localizacao (03) | `geolocator` (OSS, com `ForegroundNotificationConfig`/`AppleSettings`) -- primario; `flutter_background_geolocation` como plano B |
| Pipeline, filtro, metricas (03-04) | Dart puro, portavel |
| Persistencia (05) | `drift` (SQLite): `batch`+`insertAll` para append de pontos, `.watch()` para stats reativas |
| Sincronizacao/FIT (06) | `dio` (HTTP) + `workmanager`(Android)/BGTaskScheduler(iOS); lib FIT em Dart ou ponte nativa |
| Mapas (07) | `maplibre_gl` (OSS): `addLine`/`updateLine` para a polyline da rota ao vivo |
| Sensores BLE | `flutter_blue_plus` |
| Saude | `health` (Health Connect + HealthKit) |
| DI/estado | Riverpod ou Bloc |

> Libs marcadas acima foram verificadas na doc atual via Context7: `geolocator`
> (`ForegroundNotificationConfig`/`AppleSettings`), `drift` (`batch`/`insertAll` e `.watch()`) e
> `maplibre_gl` (`addLine`/`updateLine`). Confirmam o mapeamento 1:1 das decisoes das etapas 03-07
> para a stack Flutter.

A escolha da stack e o que destrava a fase de construcao; o resto abaixo independe dela.

## Arquitetura do cliente

Modularizacao por feature com camadas, espelhando o padrao bom do Strava (etapa 08), mas enxuta:

```
app/                 # projeto Flutter
  lib/
    core/            # design system proprio, utilitarios, rede base, DI
    feature/
      recording/     # pipeline de gravacao em Dart + binding com o plugin de localizacao
      activity/      # salvar, listar, detalhar atividade
      maps/          # abstracao sobre o motor de mapa (MapLibre atras de interface)
      profile/
      auth/
    sync/            # fila de upload (workmanager/BGTask) e geracao de FIT
  android/           # foreground service location (plugin/platform channel)
  ios/               # Core Location background (plugin/platform channel)
```

- **DI/estado**: Riverpod (ou Bloc) como ponto de composicao; sem `Application`/Hilt (isso era do
  mundo Android nativo).
- **UI**: widgets Flutter + design system proprio pequeno; navegacao tipada (go_router). Sem UI
  server-driven no MVP.
- **Borda nativa**: a captura de localizacao e o servico em primeiro plano ficam em `android/` e
  `ios/`, expostos ao Dart por um plugin; todo o processamento acontece em Dart.
- **Mapa atras de interface** (`maps`), para trocar o motor sem tocar features.
- **Concorrencia**: `async`/`Stream` do Dart (sem o legado Rx que o Strava carrega).

## O modulo de gravacao (nucleo)

Deriva direto das etapas 03-05. Em Flutter, a captura e nativa (por plugin) e o processamento e Dart.

- **Servico/captura**: no Android, um foreground service `location` com notificacao persistente e
  wake lock; no iOS, Core Location com *background location updates*. Em ambos, controle por acoes
  (start/stop/pause/resume/lap). Entregue por plugin (`flutter_background_geolocation` ou
  `geolocator`+`flutter_foreground_task`/Core Location).
- **Fonte**: alta precisao, intervalo alvo de 1 s, deslocamento minimo 0 (filtrar e decisao nossa,
  nao do provedor); no Android isso mapeia para `FusedLocationProviderClient`
  (`PRIORITY_HIGH_ACCURACY`), no iOS para `CLLocationManager` com `kCLLocationAccuracyBest`.
- **Pipeline serial em Dart** (um unico consumidor de um `Stream`/fila, para ordem e sem corrida),
  em estagios:
  1. correcao de altitude elipsoidal -> geoide (MSL), opcional e tolerante a falha;
  2. montagem de um ponto rico (lat/lon, altitude, precisao horizontal e vertical, velocidade,
     bearing, dois relogios: total e cronometro);
  3. portao de sanidade (rejeitar precisao <= 0 ou absurda);
  4. classificacao (aceitar / ignorar por pausa manual / timestamp duplicado / deslocamento minimo /
     aceleracao implausivel).
- **Filtro de qualidade**: corte de precisao horizontal (ordem de 100-150 m, calibrar) e filtro de
  **aceleracao** comparando a variacao de velocidade entre pontos consecutivos (rejeitar saltos que
  exigiriam aceleracao acima de ~1 g), em vez de um teto fixo de velocidade.
- **Pausa automatica** por esporte: corrida por movimento (acelerometro/activity recognition), pedal
  por velocidade de GPS; estados distintos de auto e manual.
- **Dois relogios**: tempo total e tempo de movimento desde o modelo do ponto; pace e splits usam o
  cronometro.

## Metricas (etapa 04)

- Distancia acumulada no proprio ponto (fonte unica), a partir de amostras aceitas (grande circulo).
- Splits de km e milha em paralelo, fechados na marca exata por interpolacao linear de tempo, com
  piso de tempo/distancia para o pace ao vivo.
- Elevacao: ganho/perda da altitude corrigida para o geoide, ponderada pela precisao vertical, com
  limiar anti-ruido; barometro quando disponivel.
- Polyline e perfil de elevacao so com pontos aceitos, em estruturas imutaveis (facilita
  undo/recuperacao).

## Persistencia (etapa 05)

- Banco local isolado da gravacao (Drift/sqflite sobre SQLite; alternativa Isar).
- Cabecalho de atividade com `guid` local, tipo, tempos, `timerTime`, distancia, calorias,
  `isFinished`, `syncState`, niveis de bateria inicio/fim.
- Tabelas de fluxo (pontos, sensores) com escrita incremental (append) a cada amostra; avaliar
  batching leve para poupar I/O/bateria.
- Recuperacao: `isFinished=false` desde o inicio; na subida, detectar atividade interrompida e
  reconstruir por replay dos pontos persistidos, mostrando um resumo do recuperado.
- Identidade gerada no aparelho, independente do servidor.

## Sincronizacao (etapa 06)

- Fila = tabela local de atividades com `syncState` pendente (offline-first).
- Agendamento por `workmanager` (Android) e BGTaskScheduler (iOS), com restricao de rede e backoff;
  trabalho separado para midia.
- Gera arquivo FIT por atividade e envia em fluxo assincrono (enviar -> id -> consultar/callback ->
  id final). Nunca falar com a API privada do Strava; integracao com Strava, se houver, so pela API
  publica oficial.

## Backend

- **PostgreSQL + PostGIS** em Docker: tabelas de atividade e de pontos geograficos
  (geometria/linha), consultas espaciais (proximidade, segmentos, heatmap) no servidor.
- **API REST** propria: endpoint de upload de FIT (aceita e processa async), consulta de status,
  recursos de atividade/feed.
- **Processamento no servidor**: parse do FIT, derivacao de rota/segmentos, deduplicacao -- tirando
  peso do cliente (igual ao Strava, que so manda o arquivo).
- **Auth**: OAuth/JWT proprio.

## Seguranca e privacidade (etapas 01-02)

- Sem SDKs de ads, atribuicao, marketing ou chat de terceiros.
- Crash/telemetria opcional e minima (Sentry, se usada).
- `FileProvider` com `grant-uri-permission` para compartilhar arquivos; componentes internos
  `exported=false`; `networkSecurityConfig` proprio; avaliar `allowBackup=false` ou backup seletivo
  por conter localizacao.
- Permissoes pedidas em contexto e no minimo. No Android: localizacao, FGS location, notificacoes,
  wake lock; ACTIVITY_RECOGNITION, Bluetooth e Health Connect so quando a feature chegar. No iOS: as
  usage descriptions do `Info.plist` (localizacao "when in use"/"always", background modes,
  Bluetooth, HealthKit) com os textos de justificativa exigidos pela App Store.
- Equivalentes de plataforma do que estudamos no Android: no iOS, seguranca de rede e o App Transport
  Security (ATS) no lugar do `networkSecurityConfig`; nao ha `allowBackup` (o iCloud backup e
  controlado por atributo de arquivo); compartilhamento de arquivo nao usa `FileProvider`.

## Comparacao de decisoes (Strava x nosso app)

| Tema | Strava | Nosso app |
| --- | --- | --- |
| Plataforma | Android nativo (iOS e app separado) | Flutter unico para Android + iOS |
| Processo | monoproceso | no Android, captura em servico (possivel processo separado); iOS e monoproceso por natureza |
| Mapa | Mapbox + FatMap (proprietario) | MapLibre (OSS) atras de interface |
| UI | Compose + Fragments + server-driven | widgets Flutter + design system proprio |
| Concorrencia | Rx + corrotinas (legado + novo) | async/Stream do Dart |
| DI/estado | Hilt | Riverpod (ou Bloc) |
| Gravacao | FGS location, filtro por precisao+aceleracao | pipeline em Dart + captura nativa por plugin; mesmo filtro |
| Metricas | splits km+milha interpolados, elevacao geoide | igual (em Dart) |
| Persistencia | Room, banco de gravacao isolado, recuperacao | Drift/sqflite, banco isolado, recuperacao |
| Sync | fila + WorkManager + FIT async | fila + workmanager/BGTask + FIT async |
| SDKs de produto | chat, marketing, suporte, atribuicao | nenhum no MVP |

## Roadmap de MVP

1. Esqueleto Flutter: `core` + DI (Riverpod) + design system minimo + navegacao (go_router).
2. `recording`: captura nativa por plugin (Android FGS / iOS background), pipeline em Dart, filtro,
   dois relogios, persistencia incremental. Validar cedo nos dois SOs (o background do iOS e o maior
   risco tecnico).
3. `activity`: salvar, listar, detalhar; metricas (distancia, pace, splits, elevacao) e polyline.
4. `maps`: exibir a rota (MapLibre atras de interface).
5. Recuperacao de crash/reboot.
6. `sync`: geracao de FIT + upload (workmanager/BGTask) + backend PostGIS basico.
7. `auth` e perfil.
8. Extras depois: sensores BLE, Health Connect/HealthKit, pausa automatica avancada, segmentos.

## Duvidas em aberto

- Stack confirmada: Flutter (recomendado e alinhado ao requisito Android+iOS). Falta so o aval final
  do Gava para destravar a construcao.
- Plugin de localizacao de fundo: inclinacao atual e `geolocator` (OSS, ja cobre FGS Android e
  background iOS pela doc verificada via Context7), com `flutter_background_geolocation` como plano B
  pago se o geolocator nao der conta de cenarios extremos. Confirmar em teste de campo.
- Limites reais do background do iOS para gravacao continua (teste de campo: tela apagada, app
  suspenso, duracao) -- o maior risco tecnico do multiplataforma.
- Formato do FIT que vamos gerar (perfil de mensagens) e se usaremos uma lib FIT pronta em Dart.
- Modelo de dados do backend (tabelas, indices espaciais) -- merece um documento proprio na
  construcao.
- Estrategia de testes (unidade para metricas/filtro em Dart; integrado para a captura nos dois SOs).
