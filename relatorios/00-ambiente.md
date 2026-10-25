# 00 - Ambiente

## Resumo

Registro do ambiente usado no estudo: versoes das ferramentas, identidade e commit do REA,
e as somas SHA-256 dos APKs analisados. Serve de referencia reproduzivel para as etapas
seguintes do roteiro. Data de preparo: 2026-10-24.

## Versoes das ferramentas

| Ferramenta | Versao | Observacao |
| --- | --- | --- |
| Node.js | v24.22.1 | atualizado de 24.15.0 para atender ao `engines` do REA (`^22.23.4 \|\| ^24.22.1 \|\| >=26.12.1`) |
| npm | 11.19.1 | |
| Git | 2.54.0.windows.1 | |
| Java (PATH) | OpenJDK 17.0.19 (Temurin, full JDK) | disponivel, nao usado pelo REA |
| Java usado pelo REA | OpenJDK 17.0.14 (JetBrains Runtime) | selecionado via `JAVA_HOME=C:\Users\gavad\.jdks\jbr-17.0.14`; tem o modulo `jdk.compiler` |
| adb | 1.0.41 (platform-tools 37.0.0-14910828) | nao necessario para a analise estatica |

## REA (Reverse Engineer Anything)

| Item | Valor |
| --- | --- |
| Pacote npm | `rea-agents` 6.7.0 (registrado como MCP no Claude Code; comando `npx -y rea-agents@6.7.0 mcp`) |
| Clone local | `tools/rea` (fora do git) |
| Remote origin | `https://github.com/morluto/rea.git` (conferido, URL oficial) |
| Commit (HEAD) | `a834ed1cab5327485fdd8845108b63ffcd8654fe` |
| Provider de analise Android | JADX via `jadx-headless-mcp` 0.7.1 |
| JAR do JADX | `C:\Users\gavad\.local\share\rea\android\jadx-headless-mcp-0.7.1-all.jar` |
| SHA-256 do JAR | `6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75` (confere com `src/android/JadxRelease.ts` do REA) |
| Variavel de ambiente | `REA_JADX_MCP_JAR` apontando para o JAR acima |

Validacao funcional: `inspect-android-package` executado com sucesso sobre `apk/base.apk`,
retornando pacote, versao e contagens coerentes (ver secao seguinte). A saida bruta ficou em
`analise/` e nao e versionada.

## APKs analisados (apk/)

SHA-256 de cada arquivo (algoritmo SHA256, `Get-FileHash`):

| Arquivo | Tamanho (bytes) | SHA-256 |
| --- | --- | --- |
| base.apk | 100622945 | `6303224273b68799020339a8d79513e546f92fb92c25e5c3b9f19043729da074` |
| split_config.arm64_v8a.apk | 43574359 | `68e5d989b436a897f405bf4933b9799241ef76d0763750a0342dbb06aecfddce` |
| split_config.en.apk | 110802 | `9d0b805896fc813915c8c4e5b0d2b86da9fc3080c6ecbbbfb44dd929951cefe2` |
| split_config.xxhdpi.apk | 12340844 | `98cce7bdd78c6d959061d51365e789133ec625b687c5abeaa1b7194e8e222b93` |

## Conteudo de apk/versao.txt

```
versionCode=12400193 minSdk=32 targetSdk=36
versionName=486.9
```

Confirmado pela leitura do `base.apk` com o REA: `package=com.strava`, `versionName=486.9`,
`versionCode=12400193`, `minSdk=32`, `targetSdk=36`. Estes valores batem com a versao declarada
no CLAUDE.md. A verificacao de assinatura nao foi executada nesta etapa (`not_performed`).

## Duvidas em aberto

- Nenhuma. Ambiente pronto para a etapa 1 (manifesto).
