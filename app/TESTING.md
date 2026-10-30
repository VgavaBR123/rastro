# Estrategia de testes (shift-left)

Testar cedo e em todas as camadas. A piramide do projeto:

## 1. Testes unitarios (base, rapidos, sem I/O)
Cobrem o nucleo de dominio em Dart puro, deterministico (sem relogio de sistema,
sem rede, sem plugins):
- `recording/domain/geo.dart` -- haversine.
- `point_pipeline.dart` -- portao de precisao (150 m), timestamp duplicado,
  deslocamento minimo (3 m), filtro de aceleracao (3 pontos, ~11 m/s^2).
- `splits.dart` -- fechamento de split na marca com tempo interpolado; multiplos
  splits por update; km e milha.
- `elevation.dart` -- limiar anti-ruido; descarte por precisao vertical.
- `recording_clock.dart` -- tempo total x tempo de cronometro (pausas).
- `recording_session.dart` -- agregacao, auto-pause, contagem de pontos.
- `auto_pause.dart` -- histerese de pausa por velocidade.

Rodar: `flutter test` (ou `dart test` para o que nao importa Flutter).

## 2. Testes de widget (UI isolada)
Quando a UI existir: cada tela/componente testado com `flutter_test` +
`WidgetTester`, com os casos de uso mockados. Verificam render, estados
(gravando/pausado), e formatacao de pace/distancia/elevacao.

## 3. Testes de integracao (fluxo real de ponta a ponta)
Com `integration_test`:
- **Gravacao -> persistencia**: injetar um fluxo de `LocationSample` gravado
  (fixture de rota real), rodar a sessao e verificar que distancia, splits,
  elevacao e pontos batem com valores esperados, e que a persistencia incremental
  (Drift) gravou tudo.
- **Recuperacao de crash**: gravar parcial, simular morte do processo, reabrir e
  conferir que a atividade e reconstruida por replay (etapa 05).
- **Sincronizacao**: atividade finalizada -> fila -> geracao de FIT -> upload
  (backend fake) -> estado `synced` (etapa 06).
- **Borda de localizacao**: smoke test nos dois SOs (Android FGS, iOS background)
  com o plugin de localizacao, validando que o stream chega ao pipeline com a
  tela apagada. Este e o maior risco tecnico (etapa 99).

## Gravacao blindada (F01)
- Unit: `recording/domain/gap_monitor_test.dart` (lacuna de processo x de GPS,
  pausa, retomada apos crash), `recording_health_test.dart` (resumo do cartao)
  e `reliability_checklist_test.dart` (itens por estado real e por fabricante).
- Persistencia: `persistence/recording_health_persistence_test.dart`
  (batimento, lacunas, saude e migracao 6 -> 7 sobre arquivo real).
- Controller: `recording/presentation/recording_controller_heartbeat_test.dart`
  com `FakeHeartbeatTicker` (o teste dispara cada batimento) e relogio injetado.
- Widget: `ui/recording_screen_shield_test.dart` (banner, GPS mudo, cadeado),
  `ui/reliability_checklist_screen_test.dart`, `ui/settings_reliability_test.dart`,
  `ui/recording_health_section_test.dart` e o portao do checklist em
  `ui/record_setup_screen_test.dart`.
- Integracao: `integration/recording_shield_flow_test.dart` (GPS some, app
  morre, recuperacao, saude final).
- Em `flutter test` o heartbeat e o probe do checklist caem nas versoes Noop
  (`heartbeatTickerProvider`, `reliabilityProbeProvider`).

## Privacidade automatica (F02)
- Unit (dominio puro em `lib/privacy/domain`): `privacy/domain/route_trim_test.dart`
  (raio de 200 a 600 m pelo guid, corte do inicio/fim por zona e por metros,
  meio da rota intacto, rota toda oculta), `zone_detection_test.dart`
  (agrupamento de ~150 m, >= 3 ocorrencias, casa x trabalho, zona existente e
  sugestao ignorada nao voltam) e `routine_test.dart` (4 de 6 no mesmo lugar e
  +-30 min, virada da meia-noite, janela de 6; `isRoutinePredictableFor` so
  avisa se a atividade compartilhada faz parte da rotina).
- Persistencia: `persistence/privacy_persistence_test.dart` (zonas, ignoradas,
  pontas das atividades, "so eu" por padrao, corte por atividade, waypoints de
  upload/exportacao, atividades sem GPS fora da janela da rotina, aviso por
  atividade, migracao 7 -> 8 e 5 -> 8 sobre arquivo real; as antigas mantem
  "todos").
- Sync: `sync/upload/privacy_upload_test.dart` (FIT sem as pontas com "Ocultar
  tambem no servidor", completo sem ele, totais nos metadados).
- Widget: `ui/save_activity_privacy_test.dart`, `ui/share_privacy_test.dart`
  (etiqueta, alavanca, trecho completo com confirmacao, dica de rotina),
  `ui/privacy_zones_screen_test.dart` (Configuracoes > Privacidade, sugestoes,
  adicionar no mapa/por atividade so com rota, sem nome vira "Local
  protegido", falha ao salvar libera o botao, toque duplo),
  `ui/add_zone_screen_test.dart` (gestos do mapa ganham da lista que rola,
  salvar exige ponto escolhido de perto), `ui/home_zone_suggestion_test.dart`
  (sugestao de casa/trabalho na Inicio) e o Salvar em
  `ui/recording_screen_extras_test.dart` (inicio do cabecalho, falha da
  consulta de rotina nao quebra a tela).
- Integracao: `integration/privacy_flow_test.dart` (tres gravacoes saindo de
  casa -> sugestao -> aceitar -> imagem e upload cortados).
- Fora do celular o mapa de "Adicionar no mapa" vira campos de latitude e
  longitude; o mapa nativo (mira no centro) fica para o E2E no emulador.

## Fixtures
Rotas gravadas (sequencias de `LocationSample`) viram fixtures versionadas em
`test/fixtures/`, inclusive casos dificeis: tunel (perda de sinal), salto de GPS,
parada longa (auto-pause), subida/descida (elevacao). Servem para unit e
integracao.

## Meta de cobertura
O nucleo de dominio (pasta `recording/domain`) deve ficar perto de 100%, por ser
a parte critica e barata de testar. UI e bordas: cobertura pragmatica + smoke
tests de integracao.
