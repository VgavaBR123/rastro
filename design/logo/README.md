# Rastro — propostas de marca

Três símbolos autorais, desenhados manualmente em SVG com curvas e formas básicas. Paleta do documento `relatorios/11-design-system.md`: fundo **#0B0D12**, lima **#C6F432** e texto **#F4F6FA**. Formas amplas, terminais suaves e contraste alto acompanham o tom do aplicativo.

## 01 — Dobra (recomendado)

Um percurso contínuo sobe, faz uma volta e muda de direção, sugerindo discretamente um **R**. O ponto separado representa a próxima posição: o trajeto continua. A combinação entre dobra interna e ponto cria uma assinatura reconhecível sem escolher um esporte específico.

Recomendo esta opção pela associação com o nome, pela silhueta simples e pela leitura nas reduções de 24, 32 e 48 px do comparativo. Tem mais vínculo com Rastro do que uma representação genérica de mapa.

## 02 — Passagem

Uma massa lima é atravessada por um caminho escuro sinuoso. O ponto vazado é um vestígio ao lado do percurso. Trabalha a rota pelo espaço negativo e produz o ícone mais compacto e preenchido das três propostas. É mais abstrato; o ponto perde destaque na menor escala.

## 03 — Vestígios

Três marcas curvas de comprimentos diferentes sugerem registros sucessivos de movimento. A repetição traduz ritmo de corrida, pedal ou caminhada sem usar pictogramas esportivos. É a proposta mais gestual, embora menos diretamente ligada à inicial do nome.

## Arquivos

- `01-dobra.svg` e `01-dobra-1024.png`
- `02-passagem.svg` e `02-passagem-1024.png`
- `03-vestigios.svg` e `03-vestigios-1024.png`
- `rastro-completo.svg`: assinatura horizontal da opção Dobra, com **Rastro desenhado em traços vetoriais próprios**; não depende de fontes instaladas nem contém elemento `<text>`.
- `comparativo.png`: visão conjunta e reduções de 24, 32 e 48 px.
- `gerar.py`: fonte reproduzível das artes e exportador local usando Pillow já disponível; executar da raiz com `python design/logo/gerar.py`.
- `README.md`: este documento.

Os três PNGs de aplicativo têm **1024 × 1024**, modo **RGB**, fundo totalmente opaco e cantos externos quadrados. O arredondamento pertence à máscara do iOS. Os SVGs também incluem fundo; os símbolos não contêm texto. Não aplicar sombras, degradês ou contornos extras. Preservar as proporções e o respiro do desenho.

## Escopo e originalidade

O ícone atual foi observado somente como inventário; as propostas usam geometria nova. Nenhum conteúdo de `analise/` ou `apk/` foi utilizado. Não foram usados símbolos de bibliotecas, marcas de referência, triângulos esportivos ou laranja. A paleta vem exclusivamente do design system solicitado. A criação é autoral; não foi realizada pesquisa de anterioridade de marcas e não é possível garantir ausência de coincidência com toda marca existente.

Todos os quatro itens solicitados foram entregues. Nada foi integrado ao aplicativo; nenhum arquivo preexistente foi modificado, nenhuma dependência global foi instalada e não houve commit ou push.
