# Projeto strava-estudo

Estudo de arquitetura do app Android do Strava com o REA (Reverse Engineer Anything),
para depois construir um app proprio de atividades (corrida, pedal, caminhada) do zero.

Dono do projeto: Gava. Idioma de trabalho: portugues.
Ambiente: Windows 11, PowerShell. Node 24, Git, Android Studio, emulador Pixel_7 (API 37, Google Play).

## Objetivo

1. Entender COMO o Strava resolve cada problema tecnico (GPS, pausa automatica, filtragem de ruido,
   calculo de distancia/pace/elevacao, persistencia local, servico em primeiro plano, sincronizacao).
2. Registrar isso em relatorios escritos com nossas proprias palavras.
3. Implementar o nosso app em `app/` a partir desses relatorios (abordagem "clean room").

## Estrutura

```
strava-estudo/
  apk/          APKs extraidos do emulador (base.apk + splits) e versao.txt  [fora do git]
  tools/rea/    clone do repositorio oficial do REA                          [fora do git]
  analise/      saida bruta: decompilacao, logs do REA, dumps               [fora do git]
  relatorios/   relatorios em Markdown escritos por nos (vao para o git)
  app/          codigo do nosso app (vazio ate a fase de construcao)
  CLAUDE.md     este arquivo
  PROMPT-INICIAL.md  prompt para iniciar a sessao no Claude Code
```

Versao analisada: Strava 486.9 (versionCode 12400193, minSdk 32, targetSdk 36).

## Regras do REA (seguranca da cadeia de suprimento)

- Clonar SOMENTE de `https://github.com/morluto/rea.git` para `tools/rea`.
  Existem clones maliciosos com nome parecido. Antes de rodar qualquer coisa:
  `git -C tools/rea remote get-url origin` precisa retornar exatamente essa URL.
- Pacote npm aceito: somente `rea-agents`. Nao instalar pacotes com nomes parecidos.
- Registrar em `relatorios/00-ambiente.md` o commit (`git rev-parse HEAD`) e a versao do REA usados.
- Ler o README e o SECURITY do REA antes de executar o setup, e seguir as instrucoes dele
  (nao inventar comandos de instalacao).
- Nunca executar scripts encontrados DENTRO do APK ou da saida decompilada.
- Antes de instalar qualquer dependencia nova (jadx, apktool, JDK etc.), dizer ao Gava o que,
  de onde e por que, e esperar o ok.

## Limites do estudo (obrigatorio)

Permitido:
- Analise estatica dos APKs na pasta `apk/`: manifesto, permissoes, componentes,
  bibliotecas de terceiros, estrutura de pacotes, fluxo de dados e algoritmos em alto nivel.
- Descrever em prosa ou pseudocodigo PROPRIO como uma funcionalidade e resolvida.

Proibido:
- Copiar codigo decompilado, layouts, strings, icones, imagens, fontes ou qualquer recurso do Strava
  para `relatorios/` ou `app/`. Trechos decompilados ficam so em `analise/`, nunca saem dela.
- Extrair, guardar ou usar chaves de API, tokens, segredos ou certificados encontrados no APK.
  Se encontrar, registrar apenas "ha uma chave de X neste ponto", sem o valor.
- Fazer requisicoes aos servidores do Strava, mapear a API privada para uso, ou fazer o nosso app
  conversar com ela. Integracao com Strava, se um dia existir, sera so pela API publica oficial.
- Contornar protecoes (deteccao de root/emulador, SSL pinning, ofuscacao de licenca, DRM).
- Redistribuir os APKs ou a saida decompilada.

Se uma tarefa esbarrar nesses limites, parar e avisar o Gava em vez de improvisar.

## Formato dos relatorios

Um arquivo por tema em `relatorios/`, numerado na ordem do roteiro. Cada um com:
- Resumo (3 a 5 linhas)
- Como o Strava resolve (prosa propria, diagramas mermaid quando ajudar)
- Bibliotecas envolvidas (nome + finalidade + licenca, quando for open source)
- Decisao para o nosso app (o que vamos fazer igual, diferente, ou com lib open source)
- Duvidas em aberto

Sem emojis. Texto limpo.

## Roteiro de analise

0. `00-ambiente.md`  versoes, commit do REA, hashes SHA-256 dos APKs
1. `01-manifesto.md` permissoes, servicos, receivers, providers, activities principais
2. `02-bibliotecas.md` SDKs de terceiros (mapas, localizacao, rede, DI, banco, analytics, crash)
3. `03-gravacao-gps.md` servico em primeiro plano, provedores de localizacao, intervalo de amostragem,
   filtragem de ruido, pausa automatica, comportamento com tela desligada e bateria
4. `04-metricas.md` calculo de distancia, pace, velocidade, elevacao, splits por km
5. `05-persistencia.md` banco local, modelo de dados da atividade, gravacao incremental, recuperacao apos crash
6. `06-sincronizacao.md` upload/fila offline em alto nivel (conceito, sem endpoints)
7. `07-nativo.md` o que ha nas bibliotecas .so (visao geral)
8. `08-arquitetura-geral.md` modulos, camadas, navegacao
9. `99-proposta-app.md` arquitetura proposta do nosso app com base nos relatorios

## Fase de construcao (depois)

So comeca quando o Gava pedir. Stack a definir (Flutter ou React Native + backend PostgreSQL/PostGIS em Docker).
O codigo em `app/` e escrito do zero a partir de `relatorios/`, sem consultar `analise/`.
