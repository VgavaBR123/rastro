# 11 - Design system

## Resumo

Identidade visual aprovada pelo Gava em 26/10/2026, a partir do prototipo "Prototipo app de treino"
(canvas em https://claude.ai/artifact/PRmNqi5ntGfctU8vsjXhXL, privado). Em 04/11/2026 o Gava trocou a
abordagem de cor pela direcao B, "Lima e neutros" (canvas em
https://claude.ai/artifact/UKbT1eb3PPCT6F5ENxAbKf, privado). O tema e escuro, os numeros ficam em branco,
lima marca acao e selecao, ambar marca pausa e alerta, vermelho marca erro, e a
navegacao e uma capsula flutuante com o botao Gravar separado ao lado. Este arquivo e a fonte de verdade
para `app/lib/ui/theme/` e `app/lib/ui/components/`. Nenhuma tela usa cor, fonte ou tamanho fixo no codigo:
tudo sai daqui.

## Principios

1. Escuro por padrao. O modo claro existe, mas e secundario.
2. Cor carrega significado, e pouca cor: lima e acao, ambar e pausa ou alerta, vermelho e erro. Numero nao
   tem cor propria; o rotulo diz qual metrica e.
3. Icone sempre acompanhado de texto.
4. Numeros em Barlow Semi Condensed, com algarismos tabulares.
5. Alvos de toque com pelo menos 44 dp; na gravacao, pelo menos 64 dp.
6. Salvar e Descartar sempre com cor e forma diferentes. Encerrar a gravacao exige segurar.
7. Nada da marca Strava: nem o laranja, nem icones, fontes, textos ou layouts deles.

## Tokens

### Superficies

| Token | Escuro | Claro | Uso |
|---|---|---|---|
| bg | #0B0D12 | #F4F5F7 | fundo da tela |
| surface | #161922 | #FFFFFF | cartoes, folhas, interior do botao Gravar |
| surface2 | #20242F | #ECEEF2 | botoes neutros, trilhos |
| text | #F4F6FA | #12141A | texto principal |
| textMuted | #A3ACBB | #566072 | rotulos, unidades, abas inativas |
| line | #272C38 | #DDE1E7 | bordas e divisores |
| map | #141820 | #E9ECE6 | fundo do mapa |
| mapRoad | #252C38 | #FFFFFF | ruas |
| mapPark | #16261F | #D6E8D3 | areas verdes |
| danger | #FF6B70 | #C8262E | Descartar, erros |
| navBg | rgba(22,25,34,0.88) | rgba(255,255,255,0.92) | capsula da navegacao, botoes sobre o mapa |
| navLine | rgba(255,255,255,0.08) | #DDE1E7 | borda da capsula |

### Cor primaria (botao principal)

| Token | Valor |
|---|---|
| primary | #C6F432 (lima) |
| onPrimary | #141A06 |
| primaryText | #C6F432 no escuro, #3F6A0A no claro |

Alternativas avaliadas no prototipo, para o caso de trocar a marca: azul #2F6BFF (texto #FFFFFF),
coral #FF5A6E (texto #2A0710) e violeta #7C3AED (texto #FFFFFF). O padrao e lima.

### Cores por funcao

Cada funcao tem quatro valores: cheia (graficos e botoes), texto no escuro, texto no claro e tingida
(fundo de chips, pilulas e blocos). Texto sobre cor cheia usa #0B0D12. Os nomes dos tokens vem da paleta
anterior e foram mantidos para nao quebrar a branch `features/top10`: dist, tempo, pace e subida dizem
qual metrica o widget mostra, e `ciano` hoje e a funcao de acao.

| Token | Onde aparece | Cheia | Texto escuro | Texto claro | Tingida (escuro) |
|---|---|---|---|---|---|
| dist, tempo, pace, subida | numeros de metrica, esportes, rota, Pausar, Retomar | #C6F432 | #F4F6FA | #12141A | rgba(255,255,255,0.06) |
| ciano (acao) | aba ativa, selecao, estado Gravando, GPS pronto, voltar, parcial mais rapida | #C6F432 | #C6F432 | #3F6A0A | rgba(198,244,50,0.14) |
| extra (alerta) | estado Pausado, pendente de envio, parcial mais lenta | #FFC53D | #FFC53D | #946200 | rgba(255,197,61,0.16) |
| neutro | demais parciais, envio em andamento | #A3ACBB (claro #566072) | #F4F6FA | #12141A | rgba(255,255,255,0.06) |
| perigo | sincronizacao que falhou; usa o token danger | #FF6B70 | #FF6B70 | #C8262E | danger a 14% |

Esportes: Corrida, Pedal e Caminhada usam a mesma cor; o rotulo e o icone os distinguem. A cor pinta o
chip neutro com ponto lima, a rota no mapa e o botao "Iniciar". So onde dois esportes dividem o mesmo
grafico (Estatisticas) eles se separam por tom: Corrida #C6F432, Pedal #7F9A2A, Caminhada = cheia de neutro.

Ponto de partida da rota: cor de texto. Anel (botao Gravar e avatar do perfil) e faiscas da splash: lima.

Contraste testado em `test/ui/theme/app_colors_palette_test.dart`. O app hoje roda com tema escuro fixo
(`ThemeMode.dark`); os valores do claro ficam prontos, mas a rota lima sobre o mapa claro tem pouco
contraste e precisa de revisao antes de ligar o tema claro.

### Tipografia

Fontes: Inter para texto e Barlow Semi Condensed (pesos 500 a 700) para numeros. As duas sao OFL.
A forma de incluir (arquivos em `assets/fonts` ou pacote google_fonts) ainda depende do ok do Gava.

| Estilo | Fonte | Tamanho | Peso | Uso |
|---|---|---|---|---|
| metricXL | Barlow | 96 | 700 | tempo e distancia na tela Gravando |
| metricL | Barlow | 40 a 48 | 700 | pace na gravacao |
| metricM | Barlow | 28 a 32 | 700 | resumo da semana, grade do detalhe, totais do perfil |
| metricS | Barlow | 18 a 24 | 700 | linha de metricas do cartao, parciais, recordes |
| screenTitle | Inter | 26 a 28 | 700 | titulo da tela, espacamento -0,02 em |
| sectionTitle | Inter | 17 a 18 | 700 | titulos de secao |
| body | Inter | 14 a 15 | 500 a 600 | texto e botoes secundarios |
| label | Inter | 12 a 13 | 600 | rotulos e unidades, cor textMuted |
| navLabel | Inter | 10,5 a 11 | 600 (700 ativa) | rotulos da navegacao |

Todo numero usa algarismos tabulares (em Flutter, `FontFeature.tabularFigures()`), para nao tremer
enquanto muda.

### Forma, espaco e sombra

- Raios: cartao 22, bloco de metrica e painel 16 a 18, chip e botao em pilula com raio igual a metade
  da altura, capsula da navegacao 32, pilula da aba ativa 28.
- Espacamento em multiplos de 2 e 4: 4, 8, 10, 12, 14, 16, 20, 24. Margem lateral da tela 16.
- Sombras: navegacao 0 16 40 preto a 50%; botao principal 0 10 28 na propria cor a 30-35%.

## Componentes

### AppNavBar

- Flutua sobre o conteudo: 16 da esquerda e da direita, 20 acima da borda inferior (somar a safe area),
  altura 64. E uma linha com a capsula das abas e, 10 ao lado, o botao Gravar.
- Capsula: ocupa o resto da largura, fundo navBg com desfoque (BackdropFilter, sigma em torno de 20),
  borda de 1 navLine, brilho interno fino no topo, raio 32, padding 4, quatro abas de largura igual.
- Aba: icone 22 com rotulo 10,5 embaixo. Inativa: icone em text, rotulo textMuted, sem fundo. Ativa:
  pilula com raio 28, fundo tingido de lima, contorno de 1 lima a 35%, icone e rotulo lima, peso 700.
- Botao Gravar: 84 x 64, anel lima de 2, interior surface com raio 30, circulo
  de 26 na cor primaria com brilho (sombra borrada na propria cor) e ponto central onPrimary de 10,
  rotulo "Gravar" 11 peso 700. Quando a tela atual e Gravar, o rotulo fica em primaryText.
- Aparece em Inicio, Historico, Estatisticas, Voce e Gravar. Nao aparece em Gravando, Salvar e Detalhe.

### Demais componentes

- **MetricTile:** rotulo (label), valor (estilo metric em text) e unidade (label).
  Variante em bloco: fundo tingido neutro, raio 16, padding 12.
- **SportChip:** altura 26 a 28, pilula, fundo tingido neutro, ponto lima de 8 e texto em text.
- **ActivityCard:** surface, borda line, raio 22, padding 16. Ordem: SportChip com data e local, titulo,
  linha de tres metricas (distancia, pace ou velocidade, tempo), miniatura do mapa com a rota lima
  (traco de 4,5 sobre um halo de 12 a 25%), ponto de partida em text, botoes "Ver detalhe"
  (tingido neutro) e "Compartilhar" (contorno).
- **WeekSummaryCard:** titulo "Esta semana" e meta ("3 de 4 treinos") com barra segmentada lima,
  tres metricas (distancia, tempo, subida) e barras por dia em lima.
- **SplitBar:** barra de 14 com raio 7 e largura proporcional a velocidade (55% a 100%). A mais rapida e
  lima, a mais lenta e ambar, as demais sao neutras. Tem legenda.
- **BigActionButton:** altura 64 a 80, pilula, icone e texto 18 a 22 peso 800. Variantes: lima
  (Salvar, Iniciar, Pausar, Retomar), neutra surface2 com borda e
  subtitulo "Segure para confirmar" (Encerrar), contorno danger (Descartar).
- **SegmentedSelector:** fundo surface com borda, opcoes de 44, a selecionada tingida de lima e com texto
  lima.
- **FloatingMapButton:** botao sobre o mapa com fundo navBg, desfoque e borda navLine (Voltar,
  Compartilhar, Camadas, GPS pronto).

## Telas

- **Inicio:** cabecalho com nome do app e titulo, botao Filtrar, WeekSummaryCard e lista de ActivityCard.
- **Gravar:** mapa em tela cheia, chip de GPS (lima) e botao Camadas no topo, folha inferior com seletor
  de esporte (o ultimo usado vem marcado, com a dica), Sensores, Voz e o botao Iniciar lima.
- **Gravando:** sem navegacao. Chip de estado (Gravando em lima, Pausado em ambar), tempo e distancia em
  metricXL, linha com pace atual, pace medio e subida em blocos tingidos, indicador de deslizar para o
  mapa, bloqueio de tela e Pausar. Pausado: Retomar e Encerrar (segurar), e as metricas ficam a 60%.
- **Salvar:** voltar a gravacao, miniatura da rota, quatro metricas, titulo sugerido pelo horario,
  descricao, quem pode ver, Salvar (primaria) e Descartar (danger).
- **Detalhe:** mapa no topo com botoes flutuantes, chip do esporte, titulo, grade 3 x 2 de metricas em
  blocos tingidos, parciais por km com SplitBar e grafico de elevacao em lima.
- **Voce:** avatar com anel lima, totais da semana em blocos tingidos, grafico de 8 semanas
  empilhado (tons de esporte de Estatisticas), recordes pessoais com ponto lima.

## Mapeamento para o Flutter

- `lib/ui/theme/app_colors.dart`: `ThemeExtension<AppColors>` com as superficies e um `RoleColors`
  (fill, text, tint) para cada funcao, com `copyWith` e `lerp`, uma instancia para o escuro e outra para
  o claro.
- `lib/ui/theme/app_theme.dart`: `ThemeData` escuro e claro com `useMaterial3: true` e `ColorScheme`
  montado a mao a partir dos tokens (sem `fromSeed`).
- `lib/ui/theme/app_typography.dart`: estilos de metrica e de texto da tabela acima.
- `main.dart`: `theme`, `darkTheme` e `themeMode: ThemeMode.dark` como padrao.
- `lib/ui/components/`: um arquivo por componente desta lista.
- `lib/app/router.dart`: `StatefulShellRoute.indexedStack` com Inicio, Historico, Estatisticas e Voce.
  Gravar, Gravando, Salvar e Detalhe sao rotas por cima do shell.
- Cada componente e cada tela com teste de widget e golden, no escuro e no claro.

## Referencias

- Prototipo aprovado: canvas "Prototipo app de treino" (link no resumo).
- Barras de abas do iOS 26 (Liquid Glass): capsula flutuante com desfoque e acao principal separada.
  https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/
- `relatorios/10-frontend.md`: padroes de UX do genero e criticas publicas aproveitadas.

## Duvidas em aberto

- Nome e marca do app (hoje e "[Nome do app]").
- Fontes: arquivos em `assets/fonts` ou pacote google_fonts.
- O modo claro fica disponivel nas configuracoes ou so o escuro na primeira versao?
- As telas Historico e Estatisticas ainda nao foram prototipadas.
