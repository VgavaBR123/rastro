Leia o CLAUDE.md, o LOOP.md, o PROGRESSO.md e o loop.ps1 desta pasta antes de qualquer acao. Siga as regras do CLAUDE.md em tudo.

Objetivo: deixar o loop pronto e validado, e rodar uma primeira iteracao de teste.

1. Pre-requisitos. Verifique e me mostre num quadro (ok / falta):
   - relatorios/00-ambiente.md existe
   - tools/rea existe e `git -C tools/rea remote get-url origin` retorna exatamente https://github.com/morluto/rea.git
   - REA instalado e integrado ao Claude Code (conforme o README dele)
   - java, jadx, apktool, adb, node e claude no PATH (where.exe / --version)
   - arquivos apk/base.apk e apk/versao.txt presentes
   Se algo faltar, pare aqui e me diga o que falta e como resolver. Nao instale nada sem meu ok.

2. PROGRESSO.md: se relatorios/00-ambiente.md existir, marque a etapa 00 como [x] e acrescente
   uma linha no log.

3. Ferramentas do loop. Descubra o nome exato das ferramentas do REA nesta sessao
   (servidor MCP, comandos ou skills que ele registrou). Atualize a lista $ferramentas do loop.ps1
   incluindo somente o que o REA precisa para analise estatica de APK, mais as ferramentas ja listadas.
   Nao use --dangerously-skip-permissions nem libere Bash de forma generica. Me mostre o diff.

4. Revise o loop.ps1 para Windows PowerShell 5.1: sintaxe, caminhos, o parametro --allowedTools
   e as flags do `claude -p` (confira com `claude --help`). Corrija o que estiver errado e me mostre o diff.

5. Teste: rode
   powershell -ExecutionPolicy Bypass -File .\loop.ps1 -MaxIteracoes 1
   em segundo plano e acompanhe o log em analise\loop-logs ate terminar.
   Depois me diga: qual etapa rodou, se o relatorio foi criado, se o PROGRESSO.md foi atualizado,
   e se houve algum pedido de permissao bloqueado (ferramenta que faltou liberar).

6. Revise o relatorio gerado contra a secao "Limites do estudo" do CLAUDE.md: nenhum codigo
   decompilado, string, recurso ou segredo do app original. Aponte qualquer problema.

7. Pare e me passe o comando para eu rodar o loop completo. Nao rode o loop completo sozinho.
