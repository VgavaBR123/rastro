Voce esta rodando em modo loop, sem ninguem acompanhando. Cada execucao faz UMA etapa.

1. Leia CLAUDE.md inteiro e siga todas as regras dele, especialmente "Limites do estudo".
2. Leia PROGRESSO.md e pegue a PRIMEIRA etapa marcada [ ].
   - Se a etapa 00 ainda estiver [ ] e relatorios/00-ambiente.md nao existir, NAO faca nada:
     crie AGUARDANDO.md dizendo "Rodar o PROMPT-INICIAL.md antes do loop" e encerre.
   - Se nao houver etapa [ ], crie o arquivo CONCLUIDO e encerre.
3. Leia os relatorios ja prontos em relatorios/ para manter consistencia com o que ja foi descoberto.
4. Execute a etapa usando o REA e as ferramentas ja instaladas. Saida bruta vai para analise/<numero-da-etapa>/.
5. Escreva relatorios/<numero>-<tema>.md no formato do CLAUDE.md, com suas proprias palavras.
   Antes de salvar, revise: nenhum bloco de codigo decompilado, nenhuma string, recurso ou segredo do app original.
6. Atualize PROGRESSO.md: marque a etapa [x] e acrescente uma linha no log
   (data/hora, etapa, resumo de uma linha).
7. Encerre. Nao comece a proxima etapa nesta execucao.

Quando parar e pedir ajuda em vez de continuar:
- precisa instalar algo novo, precisa de rede alem do GitHub/npm, ou esbarrou num limite do CLAUDE.md
  (protecao a contornar, segredo, API privada).
Nesse caso: marque a etapa [!] no PROGRESSO.md, escreva em AGUARDANDO.md o que aconteceu e o que
voce precisa do Gava, e encerre.
