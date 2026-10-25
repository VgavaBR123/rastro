# Progresso do estudo

Estado das etapas do roteiro (definido no CLAUDE.md). O loop pega sempre a primeira etapa [ ] da lista.
Marcacoes: [ ] pendente  [x] concluida  [!] bloqueada (ver AGUARDANDO.md)

- [x] 00 Ambiente (feita manualmente com o PROMPT-INICIAL.md; marcar [x] quando 00-ambiente.md existir)
- [x] 01 Manifesto
- [x] 02 Bibliotecas
- [x] 03 Gravacao GPS
- [!] 04 Metricas (BLOQUEADA: o REA nao esta acessivel pelo loop - MCP nao conecta e o CLI exige
      aprovacao interativa. Ver AGUARDANDO.md. O relatorio ja foi revisado contra os dumps
      existentes; faltam as 3 consultas listadas em analise/04/notas-evidencias.txt.)
- [ ] 05 Persistencia
- [ ] 06 Sincronizacao
- [ ] 07 Nativo
- [ ] 08 Arquitetura geral
- [ ] 99 Proposta do app

## Log das iteracoes

(cada iteracao acrescenta uma linha: data/hora, etapa, resultado)

- 2026-10-24 | 00 Ambiente | relatorios/00-ambiente.md verificado e presente; REA conectado como MCP (rea-agents 6.7.0, commit a834ed1c); apktool ausente no PATH (limitacao aceita, so afeta decode_android_resources). Etapa marcada [x].
- 2026-10-24 | 01 Manifesto | relatorios/01-manifesto.md escrito a partir do manifesto decodificado (analise/01/). App monoproceso, 402 activities / 24 services / 30 receivers / 16 providers; gravacao concentrada em um unico foreground service de tipo location mais receiver de BOOT_COMPLETED e JobService de retomada; 38 permissoes agrupadas por funcionalidade; 106 activities exportadas por causa dos deep links. Nenhum valor de chave ou recurso do app copiado.
- 2026-10-24 | 02 Bibliotecas | relatorios/02-bibliotecas.md escrito a partir do inventario de classes (analise/02/notas-evidencias.txt). Nucleo: Fused Location Provider do GMS (mais ActivityRecognition/ActivityTransition), Room com 20+ bancos separados incluindo um RecordingDatabase exclusivo da gravacao, OkHttp+Retrofit, Hilt, Mapbox+FatMap, RxJava3 e corrotinas convivendo, AltitudeConverterDatabase da AndroidX para altitude acima do nivel do mar. Em volta: Stream Chat, Braze/Iterable/Branch, Zendesk, Sentry+Embrace, Play Billing, Play Integrity. 39984 classes em defpackage (R8 repackage) limitam o metodo: presenca sim, ausencia e versao nao. Nenhum codigo decompilado lido ou copiado.
- 2026-10-24 | 03 Gravacao GPS | relatorios/03-gravacao-gps.md revisado e completado (evidencias em analise/03/notas-evidencias.txt). Resolvido: LocationRequest = alta precisao + 1 s + 0 m + waitForAccurateLocation, usando so a ultima amostra de cada lote; esteira serial por canal/corrotina com conversao de altitude elipsoidal para MSL (AndroidX, atras de feature switch); corte de precisao horizontal em 150 m; classificacao do ponto por motivo (duplicado, aceleracao >= ~11 m/s2 com limpeza do buffer de 5 pontos, deslocamento < 3 m); pausa automatica com DUAS implementacoes escolhidas por esporte - corrida usa acelerometro a 50 ms com duas medias exponenciais (meia vida 0,4 s x 10 s) e decisao relativa por fator 3, pedal usa relogio de guarda de 10 s com piso de 0,33 m/s, demais esportes sem auto pausa. Nenhum codigo, string ou recurso do app copiado para relatorios/.
- 2026-10-24 | 04 Metricas | BLOQUEADA [!]. REA inacessivel nesta sessao do loop: servidor MCP "rea" nunca termina de conectar (nenhuma ferramenta mcp__rea__*) e o CLI npx e barrado pelo hook de permissao, que exige aprovacao interativa inexistente no loop; setar env var inline tambem e barrado. Sem consultas novas ao APK. Feito o que era possivel: relatorios/04-metricas.md reconferido contra os dumps ja salvos em analise/ (ActiveActivity, ElevationStats, ActivitySplits, ActiveSplitList, ActiveSplit, ActiveActivityMetaStats, Waypoint) - confirmados os splits km+milha com fechamento interpolado na marca e o MIN_SPLIT_PACE_TIME_MS; corrigida a secao de elevacao (o metodo nao filtra nada, so repassa altitude+precisao vertical a uma classe calculadora separada e substitui o acumulado imutavel - a "filtragem contra ruido" era inferencia, agora marcada como hipotese); corrigida a distancia (chega pronta via TimedDistancePoint, o Waypoint nao expoe getter de distancia, e o local do calculo ainda nao foi lido); fechada a duvida da origem da altitude (GPS corrigido para o geoide pela AndroidX, etapa 03). Restam 3 consultas anotadas em analise/04/notas-evidencias.txt. Nenhum codigo ou recurso do app copiado para relatorios/.
