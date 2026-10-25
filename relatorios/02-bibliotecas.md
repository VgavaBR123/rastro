# 02 - Bibliotecas de terceiros

## Resumo

O Strava 486.9 carrega um conjunto grande de SDKs, mas as escolhas tecnicas do nucleo sao
conservadoras e bem definidas: localizacao pelo Fused Location Provider do Google Play Services,
persistencia local em Room (mais de vinte bancos separados, um deles dedicado so a gravacao),
rede em OkHttp mais Retrofit, injecao de dependencia em Hilt, mapas em Mapbox com um SDK 3D proprio
(FatMap) e Kotlin com uma mistura de RxJava3 e corrotinas. Em volta disso ha uma camada espessa de
produtos de negocio: chat, marketing, suporte, atribuicao, dois SDKs de observabilidade ao mesmo
tempo, pagamentos e antiabuso. A maior parte do codigo de terceiros perdeu o nome na ofuscacao, o
que limita a precisao do levantamento e impede determinar versoes.

## Como o Strava resolve

### O que a ofuscacao deixa ver, e o que esconde

Das classes do `base.apk`, 39.984 estao na raiz, sem pacote. Esse e o resultado tipico do R8 em
modo full com repackaging: todo codigo que nao tem regra de keep e achatado em nomes de uma letra
na raiz. Em comparacao, `com.strava` mantem 6.171 classes com nome legivel, porque o proprio app
depende de reflexao em pontos como Room, Hilt e serializacao, e porque R8 nao renomeia o que esta
listado nas regras de keep das bibliotecas.

Consequencia pratica para o estudo: uma biblioteca so e identificavel quando sobra alguma ponta. As
pontas uteis sao (a) classes publicas protegidas por keep rule da propria biblioteca, (b) classes
geradas em tempo de compilacao, que carregam o nome do pacote do app (`*Database_Impl`, `*Dao_Impl`,
`Hilt_*`, `*_Factory`), e (c) nomes de classes do Strava que citam a tecnologia
(`...RetrofitDataSource`). Tudo que nao tem nenhuma dessas pontas e invisivel. Portanto este
relatorio afirma presenca, nunca ausencia, e nao afirma versao de nada.

### Nucleo tecnico

**Localizacao.** O app usa o Fused Location Provider do Google Play Services, nao o
`LocationManager` cru do Android. Aparecem o cliente (`FusedLocationProviderClient`), a fabrica
(`LocationServices`), os objetos de requisicao e resultado, e tambem as APIs de verificacao de
configuracao do aparelho (`LocationSettingsRequest`, `LocationSettingsStates`), que sao o caminho
padrao para pedir ao usuario que ligue o GPS sem sair do app. Alem disso estao presentes:

- Reconhecimento de atividade e transicoes (`ActivityRecognitionClient`, `ActivityTransitionRequest`,
  `DetectedActivity`), insumo plausivel para pausa automatica e para detectar o tipo de esporte.
- Orientacao do aparelho (`DeviceOrientationRequest`), que o Google expoe junto com localizacao.
- Geofencing e deteccao de sono. Ambos parecem ligados a features perifericas, nao a gravacao.
- `androidx.core.location.altitude.AltitudeConverterDatabase`, um banco embarcado da AndroidX Core
  usado para converter altitude elipsoidal (WGS84, o que o GPS entrega) em altitude acima do nivel
  medio do mar. Isso e uma pista forte de como a elevacao e tratada e volta na etapa 04.
- O SDK legado do Google Fit (`gms.fitness`) continua empacotado, ao lado do modulo novo de Health
  Connect visto no manifesto. Convivencia de caminho antigo e novo.

**Persistencia.** Room, de forma intensa e fragmentada. O inventario mostra mais de vinte bancos
distintos, cada um pertencendo a um modulo de feature em vez de um banco unico do app. Entre eles ha
um `StravaDatabase` geral e, separado dele, um `RecordingDatabase` exclusivo da gravacao. Essa
separacao e uma decisao de arquitetura importante: o banco que recebe pontos de GPS durante o treino
nao compete com migracoes, locks nem escritas de feed, mapas ou analytics. Ha ainda bancos proprios
para rotas (com um "legacy" ao lado do atual, sinal de migracao em andamento), mapas offline, cache
de estilos de mapa, zonas de privacidade, experimentos, cache de analytics e log de rede interno.
`androidx.datastore` tambem aparece, provavelmente para preferencias, e WorkManager traz o seu
proprio banco.

**Rede.** OkHttp com praticamente todos os subpacotes internos presentes (HTTP/1, HTTP/2, WebSocket,
cache, TLS, pool de conexoes) e Retrofit por cima, confirmado por nomes de data source do proprio
app e pelos modulos de rede do Zendesk. Convivem tres bibliotecas de JSON: Gson (a maior presenca),
Moshi e um pouco de kotlinx.serialization — tipico de base de codigo longeva, onde cada geracao de
modulo escolheu a sua. Protobuf tambem esta presente, mas em volume compativel com uso interno de
SDKs do Google (datatransport, Firebase) e nao necessariamente pelo Strava.

**Concorrencia.** As duas coisas ao mesmo tempo: RxJava3 (comprovado por `RxWorker` do WorkManager e
pelo RxAndroidBle) e corrotinas Kotlin (comprovadas pelas classes de lambda suspensa espalhadas por
todo o codigo). Leitura mais provavel: codigo antigo em Rx, codigo novo em corrotinas, sem migracao
concluida.

**Injecao de dependencia.** Hilt, visivel pelas classes geradas `Hilt_<Fragment>` e pelos
`HiltWrapper_*EntryPoint` em dezenas de modulos. Sobraram duas classes de `dagger.android`, o
mecanismo anterior ao Hilt — outro resto de migracao.

**UI.** Hibrido. Ha Compose (runtime, foundation, material, material3) e ao mesmo tempo
RecyclerView, AppCompat, Fragments, ConstraintLayout e ViewPager2. A camada propria
(`com.strava.modularframework`, `modularui`, `modularcomponents`, com mais de 500 classes somadas) e
um sistema de renderizacao de telas vindas do servidor: o backend descreve componentes e o app
monta. Isso explica como o Strava muda feed e telas de detalhe sem publicar versao nova. Para o
widget usam `androidx.glance.appwidget`. Graficos ficam com Vico (biblioteca de charts para Compose)
mais uma camada propria, `com.strava.graphing`.

**Mapas.** Mapbox (Maps, Common, GeoJSON, bindgen, module) como motor 2D, com cerca de 880 classes,
e `com.fatmap.sdk` para o mapa 3D — a FatMap foi adquirida pelo Strava, logo e SDK de casa. Em volta
disso o app tem modulos proprios de abstracao (`dynamicmapinterface`, `dynamicmapmapbox`,
`dynamicmapmre`), ou seja, o motor de mapa esta atras de uma interface propria e pode ser trocado.
Vale copiar esse cuidado.

**Sensores.** RxAndroidBle3 para Bluetooth Low Energy, que casa com as permissoes
`BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` vistas no manifesto e com o modulo `deviceconnect`. E uma
biblioteca que embrulha a API BLE do Android, notoriamente desagradavel, em streams Rx.

**Midia.** Media3/ExoPlayer para video, Coil (versoes 2 e 3 ao mesmo tempo) e um residuo de Picasso
para imagens, um cropper de terceiros, e `com.linkedin.android.litr` para transcodificar video,
incluindo processamento de audio via Oboe. Rive aparece como motor de animacao vetorial, com
renderizadores OpenGL e Vulkan proprios.

### Camada de produto e de negocio

| Area | SDK | Observacao |
| --- | --- | --- |
| Chat e mensagens | Stream Chat (`io.getstream`), ~900 classes, com dois bancos Room proprios | o maior SDK de terceiro do app |
| Marketing e engajamento | Braze (`com.braze` + `bo.app`), Iterable, Branch (deep links e atribuicao) | tres produtos com funcoes parcialmente sobrepostas |
| Suporte | Zendesk (core, support, guide, classic messaging), ~600 classes | central de ajuda embutida |
| Social | Facebook SDK (login, share, app events) | login social e eventos |
| Analytics | Firebase Analytics, Google Analytics/measurement, mais a camada propria `com.strava.analytics` | |
| Observabilidade | Sentry (incluindo NDK, Compose e replay de sessao) e Embrace, simultaneos | dois produtos para o mesmo problema; provavelmente migracao ou avaliacao |
| Pagamentos | Play Billing | assinatura |
| Antiabuso | Play Integrity e reCAPTCHA, por tras do modulo `attestation` | verificacao de integridade do app/dispositivo |
| ML | ML Kit Text Recognition (OCR) e um componente de fala generativa do GMS | sustenta a hipotese da etapa 01 sobre OCR; a parte de fala e nova e nao explicada |
| Datas | Joda-Time, mais o `java.time` por desugaring | Joda e legado; `java.time` e o caminho atual |
| Diversos | EventBus (greenrobot), PermissionX, Wear OS | barramento de eventos legado e pedido de permissoes |

Dois padroes se repetem: pares de bibliotecas concorrentes convivendo (Gson/Moshi, Rx/corrotinas,
Coil/Picasso, Sentry/Embrace, Joda/java.time, Views/Compose, Fit/Health Connect) e uma camada propria
de abstracao sobre quase todo SDK pesado. O primeiro padrao e a cicatriz de um app com mais de uma
decada; o segundo e disciplina deliberada.

## Bibliotecas envolvidas

Resumo com finalidade e licenca das que importam para o nosso app:

| Biblioteca | Finalidade | Licenca |
| --- | --- | --- |
| Google Play Services Location | localizacao fundida, reconhecimento de atividade, transicoes | proprietaria (parte do GMS) |
| AndroidX Core Location (altitude) | conversao de altitude WGS84 para nivel do mar | Apache-2.0 |
| AndroidX Room | banco local SQLite com DAOs gerados | Apache-2.0 |
| AndroidX DataStore | preferencias assincronas | Apache-2.0 |
| AndroidX WorkManager | trabalho em background com garantia de execucao | Apache-2.0 |
| OkHttp | cliente HTTP | Apache-2.0 |
| Retrofit | cliente REST declarativo sobre OkHttp | Apache-2.0 |
| Moshi | JSON (geracao de adaptadores) | Apache-2.0 |
| Gson | JSON (reflexao) | Apache-2.0 |
| kotlinx.serialization | JSON (plugin do compilador) | Apache-2.0 |
| kotlinx.coroutines | concorrencia estruturada | Apache-2.0 |
| RxJava3 | streams reativos | Apache-2.0 |
| Hilt / Dagger | injecao de dependencia em tempo de compilacao | Apache-2.0 |
| RxAndroidBle3 | BLE embrulhado em Rx | Apache-2.0 |
| Mapbox Maps SDK | mapas vetoriais | proprietaria, cobranca por uso |
| FatMap SDK | mapas 3D | proprietaria (empresa do grupo Strava) |
| Coil | carregamento de imagens em Kotlin | Apache-2.0 |
| AndroidX Media3 / ExoPlayer | reproducao de video | Apache-2.0 |
| LiTr | transcodificacao de video | BSD-2-Clause |
| Rive | animacoes vetoriais interativas | MIT (runtime) |
| Vico | graficos para Compose | Apache-2.0 |
| AndroidX Glance | widgets com Compose | Apache-2.0 |
| Joda-Time Android | datas e horas (legado) | Apache-2.0 |
| Sentry | erros e performance | MIT |
| Embrace | observabilidade movel | proprietaria |
| Stream Chat | chat | proprietaria com tier gratuito |
| Braze, Iterable, Branch | engajamento, email/push, atribuicao | proprietarias |
| Zendesk | suporte | proprietaria |
| Facebook SDK | login e compartilhamento social | licenca propria do Facebook |
| Play Billing | assinaturas | proprietaria |
| Play Integrity, reCAPTCHA | antiabuso | proprietarias |
| ML Kit Text Recognition | OCR | proprietaria |
| EventBus | barramento de eventos | Apache-2.0 |
| PermissionX | fluxo de pedido de permissao | Apache-2.0 |

## Decisao para o nosso app

**Igual:**

- Localizacao pelo provedor fundido da plataforma, nao pelo `LocationManager` cru, e usar a API de
  configuracao de localizacao para pedir que o usuario ligue o GPS dentro do fluxo. Se a stack for
  Flutter ou React Native, a escolha equivalente e um plugin que fale com o Fused Location Provider
  no Android e com o Core Location no iOS, nunca a API crua.
- Banco local relacional com SQLite, com DAOs e migracoes versionadas.
- **Banco separado so para a gravacao.** Essa e a melhor ideia do levantamento: o armazenamento que
  recebe pontos de GPS a cada segundo nao divide arquivo, lock nem migracao com o resto do app.
  Adotar mesmo que o resto do app use um unico banco.
- Conversao explicita de altitude para nivel do mar, em vez de usar o valor cru do GPS. Precisa de
  uma tabela de geoide; na nossa stack isso pode ser uma dependencia a parte ou calculo no backend.
- O motor de mapa atras de uma interface propria, para poder trocar de provedor sem mexer nas telas.
- Camada propria em volta de qualquer SDK pesado que entre no projeto.
- Reconhecimento de atividade da plataforma como insumo auxiliar de pausa automatica, nunca como
  unica fonte.

**Diferente:**

- Uma biblioteca por problema. Um JSON, um modelo de concorrencia (corrotinas, ou o equivalente da
  stack), um carregador de imagem, uma biblioteca de data e hora. O custo da convivencia aparece em
  tamanho do app, tempo de build e numero de caminhos de codigo a testar.
- Nenhum SDK de marketing, atribuicao, chat ou suporte na primeira versao. Nenhum SDK proprietario
  de observabilidade; se precisarmos de crash reporting, Sentry, que e aberto e auto-hospedavel.
- Mapas: avaliar MapLibre (BSD, fork aberto do Mapbox GL) antes do Mapbox, justamente para nao ficar
  preso a cobranca por carregamento de mapa. O requisito `OpenGL ES 3.0` obrigatorio no manifesto do
  Strava vem desse tipo de SDK; vale saber disso antes de decidir.
- Sem renderizacao de tela vinda do servidor na primeira versao. O framework modular do Strava e uma
  solucao para um problema de escala que nao temos: centenas de telas e ciclo de release de semanas.
- Nada de antiabuso (Play Integrity, reCAPTCHA) enquanto nao houver nada a proteger.
- Preferencias em armazenamento assincrono moderno desde o inicio, nunca em `SharedPreferences`
  sincrono dentro do servico de gravacao.

**A decidir depois:**

- BLE para sensores (cinta cardiaca) fica para depois da versao 1, mas a existencia de uma
  biblioteca madura que embrulha a API BLE pesa na escolha da stack: isso e codigo nativo, nao
  resolvido por plugin generico.
- Integracao com o repositorio de saude do sistema (Health Connect no Android, HealthKit no iOS)
  tambem fica para depois, mas o modelo de dados da atividade precisa nascer compativel com o que
  esses repositorios esperam.

## Duvidas em aberto

- Qual intervalo e prioridade sao pedidos ao provedor fundido durante a gravacao. E o ponto central
  da etapa 03.
- Se o `AltitudeConverterDatabase` da AndroidX e usado de fato na gravacao ou so em alguma tela de
  rota. Verificar na etapa 04.
- Qual e o esquema do `RecordingDatabase` e como se relaciona com o `StravaDatabase`. Etapa 05.
- Se a sincronizacao usa WorkManager com o banco de trabalho proprio dele ou uma fila propria em
  Room. Etapa 06.
- Por que ha dois SDKs de observabilidade ativos ao mesmo tempo. Nao da para responder por analise
  estatica; e provavelmente historia interna.
- Qual o papel do componente de fala generativa do GMS. Nenhuma pista no manifesto nem nos nomes de
  pacote do app.
- Versoes exatas das bibliotecas. Nao sao determinaveis pelo metodo usado aqui; se fizerem falta,
  daria para estimar por marcadores em recursos e assets, o que exigiria `apktool` (hoje ausente no
  ambiente).
