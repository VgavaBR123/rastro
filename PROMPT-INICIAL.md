# Prompt inicial para o Claude Code

Abra o PowerShell em D:\dev\strava-estudo, rode `claude` e cole o texto abaixo.

---

Leia o CLAUDE.md desta pasta inteiro antes de qualquer acao e siga as regras dele em tudo.

Tarefa desta sessao: preparar o ambiente e fazer a etapa 0 do roteiro.

1. Inicialize um repositorio git nesta pasta (se ainda nao existir). Confira se o .gitignore
   mantem apk/, tools/rea/ e analise/ fora do versionamento.

2. Clone o REA:
   git clone https://github.com/morluto/rea.git tools/rea
   Em seguida confirme a origem com `git -C tools/rea remote get-url origin` e registre o commit
   com `git -C tools/rea rev-parse HEAD`. Se a URL nao for exatamente a oficial, pare e me avise.

3. Leia tools/rea/README.md e o arquivo de politica de seguranca do repositorio. Me apresente,
   antes de executar:
   - como o REA deve ser instalado e integrado ao Claude Code (comandos exatos do README),
   - quais dependencias externas ele exige para analisar um APK Android (JDK, jadx, apktool etc.),
   - quais delas ja existem nesta maquina (verifique com `java -version`, `node -v`, `where.exe jadx`,
     `where.exe apktool`, `adb version`) e quais faltam.
   Espere meu ok antes de instalar qualquer coisa.

4. Depois do meu ok, faca a instalacao seguindo o README e valide que o REA esta funcionando.

5. Etapa 0 do roteiro: crie relatorios/00-ambiente.md com
   - versoes de Node, Git, Java, adb e REA, e o commit do REA,
   - SHA-256 de cada arquivo em apk/ (Get-FileHash -Algorithm SHA256),
   - conteudo de apk/versao.txt.

6. Me mostre o plano de como voce vai usar o REA na etapa 1 (manifesto) e pare. Nao comece a
   etapa 1 sem meu ok.

Lembre: saida bruta e trechos decompilados ficam so em analise/. Nada de codigo, recurso ou
segredo do Strava em relatorios/ ou app/. Sem requisicoes aos servidores do Strava.
