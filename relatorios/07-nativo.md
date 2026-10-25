# 07 - Bibliotecas nativas (.so)

## Resumo

O APK carrega 12 bibliotecas nativas (`.so`), todas no split por ABI (`split_config.arm64_v8a.apk`),
porque o manifesto define `extractNativeLibs="false"` (etapa 01). Todas as 12 sao de terceiros ou da
AndroidX: motores de mapa (Mapbox e FatMap), animacao (Rive), transcodificacao de video (LiTr),
observabilidade nativa (Sentry e Embrace), a STL do C++ e alguns utilitarios da AndroidX. O achado
mais importante para o estudo e negativo: nao existe nenhuma biblioteca nativa propria do Strava
para GPS, distancia, filtragem ou elevacao. Isso confirma que a matematica da gravacao (etapas 03 e
04) esta em codigo gerenciado (Kotlin ofuscado), nao em C/C++.

## Como o Strava resolve

### Inventario das bibliotecas nativas (arm64-v8a)

| Biblioteca | Tamanho aprox. | Finalidade | Origem |
| --- | --- | --- | --- |
| `libFatmapSdk.so` | 21 MB | motor de mapa/terreno 3D | FatMap (proprietaria, Strava) |
| `libmapbox-maps.so` | 8,8 MB | renderizacao de mapas 2D | Mapbox (proprietaria) |
| `libmapbox-common.so` | 5,3 MB | base comum do Mapbox (rede, cache, dados) | Mapbox (proprietaria) |
| `librive-android.so` | 5,3 MB | animacao vetorial em tempo real (OpenGL/Vulkan) | Rive (source-available) |
| `libc++_shared.so` | 1,3 MB | STL compartilhada do C++ (NDK) | LLVM/NDK |
| `libsentry.so` | 0,68 MB | captura nativa de crash (NDK) | Sentry (open source) |
| `libembrace-native.so` | 0,63 MB | APM/estabilidade nativa | Embrace (proprietaria) |
| `liblitr-jni.so` | 0,25 MB | transcodificacao de video (JNI) | LinkedIn LiTr |
| `libandroid-tests-support-code.so` | 43 KB | apoio a testes | AndroidX/test (residuo) |
| `libandroidx.graphics.path.so` | 10 KB | parsing nativo de Path (SVG/vetor) | AndroidX Graphics |
| `libdatastore_shared_counter.so` | 7 KB | contador compartilhado multiprocesso do DataStore | AndroidX DataStore |
| `libsentry-android.so` | 17 KB | ponte Android do Sentry nativo | Sentry |

Observacoes:

- **Mapas dominam o peso nativo.** FatMap (21 MB) e Mapbox (14 MB somados) sao de longe as maiores. O
  custo de instalacao/armazenamento do app vem, em boa parte, dos motores de mapa em C++.
- **Rive** com renderizador proprio (OpenGL e Vulkan) explica a exigencia de OpenGL ES 3.0 vista no
  manifesto (etapa 01) e as animacoes ricas da UI.
- **Crash/observabilidade nativa dupla.** Sentry (open source) e Embrace (proprietaria) tem cada um
  sua `.so`, coerente com a etapa 02 (dois produtos de observabilidade convivendo).
- **LiTr** confirma transcodificacao local de video (para compartilhar/anexar midia na atividade).
- **`libc++_shared.so`** e a STL comum exigida pelas demais; nao e funcionalidade, e dependencia de
  runtime do C++.
- **`libandroid-tests-support-code.so`** chama atencao por ser codigo de apoio a testes num build de
  producao; provavelmente residuo de dependencia, sem funcao em runtime normal.

### O que a ausencia revela

Nao ha `libstrava*.so`, `librecording*.so` nem equivalente. Como as etapas 03 e 04 ja mostravam a
logica de `Waypoint`, filtro (`isFiltered`), splits com interpolacao e elevacao em classes Kotlin
(ainda que ofuscadas), o inventario nativo fecha a questao: o nucleo de gravacao e 100% gerenciado.
As unicas pontas nativas que tocam a gravacao sao indiretas -- o altimetro/geoide via AndroidX Core
(etapa 02/04) e os mapas para exibir a rota.

### Limite desta analise

Esta etapa e um levantamento de superficie (nomes, tamanhos, finalidade). Decompilar o conteudo das
`.so` (pseudocodigo, simbolos, strings) exigiria um provedor de analise nativa do REA (Ghidra, Hopper
ou IDA), que nao esta configurado neste ambiente. Para o nosso estudo clean room isso nao e
necessario: nenhuma dessas bibliotecas e candidata a reimplementacao -- sao motores de terceiros que,
no nosso app, seriam substituidos por equivalentes (ver decisao).

## Bibliotecas envolvidas

Ver tabela acima. Em resumo por categoria: mapas (Mapbox, FatMap), animacao (Rive), video (LiTr),
observabilidade (Sentry, Embrace), runtime C++ (libc++_shared) e utilitarios AndroidX (graphics.path,
datastore counter).

## Decisao para o nosso app

- **Mapas**: trocar os motores nativos proprietarios (Mapbox/FatMap) por um motor com licenca aberta
  -- MapLibre Native (fork OSS do Mapbox GL, mesma natureza C++). Sem terreno 3D no inicio.
- **Nucleo de gravacao**: continuar em codigo gerenciado (Kotlin), como o Strava faz; nao ha ganho em
  escrever GPS/distancia em C++.
- **Observabilidade**: se usarmos, Sentry (open source) ja cobre crash nativo e gerenciado; dispensar
  Embrace.
- **Video/animacao**: adiar; LiTr (transcodificacao) e Rive (animacao) nao sao essenciais para gravar
  e analisar atividades. Rive pode ser considerado depois para microinteracoes, por ser
  source-available.
- **Peso do app**: ao evitar FatMap e reduzir motores nativos, nosso APK fica drasticamente menor que
  os ~45 MB so de `.so` do Strava.

## Duvidas em aberto

- Versoes exatas de cada `.so` (build-id/notas ELF nao foram extraidos nesta etapa).
- Se alguma dessas libs faz processamento relevante de localizacao indiretamente (improvavel, mas nao
  verificado por decompilacao nativa).
- Conteudo interno das libs (simbolos/pseudocodigo): fora de escopo sem provedor nativo configurado.
