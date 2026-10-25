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

## Fixtures
Rotas gravadas (sequencias de `LocationSample`) viram fixtures versionadas em
`test/fixtures/`, inclusive casos dificeis: tunel (perda de sinal), salto de GPS,
parada longa (auto-pause), subida/descida (elevacao). Servem para unit e
integracao.

## Meta de cobertura
O nucleo de dominio (pasta `recording/domain`) deve ficar perto de 100%, por ser
a parte critica e barata de testar. UI e bordas: cobertura pragmatica + smoke
tests de integracao.
