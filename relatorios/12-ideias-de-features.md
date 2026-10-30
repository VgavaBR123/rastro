# Ideias de features para o Rastro

## Resumo

Sete personas propuseram 42 ideias para o Rastro (programador, product owner, corredora iniciante, ciclista e triatleta, corredora preocupada com segurança, organizador de grupo e designer de UX). Depois cada uma votou em 5 ideias, criticou as outras e sugeriu fusões. Houve consenso forte em três pontos. Primeiro, a gravação não pode perder corrida (dev-1 recebeu o voto de todas as sete personas). Segundo, a privacidade automática precisa vir antes de qualquer recurso social. Terceiro, retrospectiva, voz e pacto entregam muito valor sem depender de base de usuários. O ranking final junta as 42 ideias em 10 frentes, que cabem em entregas P e M para 1 desenvolvedor. Segmentos, feed completo, cobrança B2B e rotas "seguras" ficam para depois ou foram descartados.

## O que aprendemos sobre o Strava

**Por que as pessoas gostam:**
- O kudos funciona como reconhecimento leve. A frase "se não está no Strava, não aconteceu" resume isso.
- Segmentos e o Local Legend transformam a rua de casa num jogo.
- Saber que os amigos vão ver mantém a pessoa treinando.
- Clubes dão sensação de pertencimento. No Brasil a criação de clubes cresceu 800% em um ano.
- Funciona como hub neutro de dispositivos.
- Mostra a evolução com recordes e o Year in Sport.

**Maiores reclamações:**
- Preço e paywall são a reclamação número 1. Recursos antes grátis foram fechados, como o leaderboard completo, as rotas e o Year in Sport.
- Cobrança e suporte (nota de cerca de 1,5/5 no Trustpilot).
- Corridas perdidas ou cortadas, sobretudo no Android, quando a otimização de bateria mata o app.
- O feed deixou de ser cronológico (#BringBackChronological).
- Privacidade: o heatmap expôs bases militares e endereços, e as atividades são públicas por padrão.
- Trapaça em segmentos.
- Ansiedade de comparação.

**Lacunas que dá para explorar:**
- Um núcleo grátis e justo.
- Privacidade ligada por padrão.
- Gravação robusta.
- Treino guiado. O Strava precisou comprar o Runna para ter isso.
- Ferramentas para assessorias e grupos brasileiros.
- Portabilidade de dados. O Strava fechou e passou a cobrar pela API.
- Segurança ao vivo grátis. As regras do Beacon são confusas.

## Como a discussão aconteceu

- **Personas (7):** programador mobile sênior, product owner, corredora iniciante, ciclista e triatleta avançado, corredora urbana preocupada com segurança, organizador de grupo de corrida e designer de produto (UX).
- **Ideias:** 42, sendo 6 por persona.
- **Votação:** cada persona escolheu 5 ideias em ordem, valendo de 5 pontos (1o voto) a 1 ponto (5o). No total foram distribuídos 105 pontos.
- **Debate:** cada persona criticou as ideias das outras, propôs fusões e defendeu a própria ideia contra as objeções previstas.
- **Moderação:** juntei as ideias que mais de uma persona mandou fundir e somei os pontos delas. Depois ajustei a ordem pelas críticas, e a tabela diz quando ajustei.

## Ranking final (top 10)

| Pos. | Feature (fusão) | Quem propôs | Pontos | Esforço | Por que entrou |
|---|---|---|---|---|---|
| 1 | **Gravação blindada**: checklist por fabricante, heartbeat a cada 5 s, detecção e aviso de lacuna, relatório de saúde da gravação, e mais tarde os gestos e o bloqueio contra toques do ux-37 | dev-1 (+ ux-37) | 25 | P | Foi o 1o ou 2o voto das sete personas. É a base do Rastro Seguro, do narrador, do BLE e do check-in. Corrida perdida é a queixa que faz o usuário desinstalar. |
| 2 | **Privacidade automática no aparelho**: detecta casa e trabalho, corta com raio aleatório na imagem, no upload e na exportação, mostra a etiqueta "início e fim ocultos", usa visibilidade por atividade com padrão "só eu" e avisa quando a rotina está previsível | dev-2, seguranca-25, ux-42, iniciante-18 (parte 1), seguranca-30 | 14 | M | Todas as personas a apontaram como pré-requisito do social. A imagem compartilhada, que já existe hoje, vaza o endereço. **Ajuste:** empatou em pontos com a 3, mas ficou à frente porque a retrospectiva e qualquer recurso social dependem dela. |
| 3 | **Motor de voz e sessão guiada**: o Narrador (TTS com ducking, gatilhos configuráveis) e depois o plano Do Zero aos 5 km com os blocos gravados como voltas | ux-38, iniciante-14 (base para ciclista-22 e social-35) | 14 | P (narrador) + M (plano) | Melhor relação custo/valor: roda offline e sem servidor. Quatro ideias reaproveitam o mesmo motor. Também ajuda na acessibilidade. |
| 4 | **Capítulos mensais e anuais com marcos**: Stories no dia 1o, marcos de primeira vez e sequência semanal com coringa, gerados no aparelho e passando pela privacidade | po-10, ux-41, iniciante-15 | 11 | M | É a resposta direta ao Year in Sport pago. Cria um ritual mensal de retorno e traz aquisição pela marca d'água. **Ajuste:** só sai depois da privacidade (crítica da seguranca-25: o mapa sobreposto entrega a casa). |
| 5 | **Pacto de constância / círculo de apoio**: de 2 a 8 pessoas, convite pelo WhatsApp, meta coletiva, cutucar, coringa mensal e nenhum ranking de pace | po-8, iniciante-17 | 8 | M | É o menor social que funciona no primeiro dia e ataca o D7/D30. O mesmo modelo de grupo serve depois às assessorias. **Ajuste:** a sequência deixou de zerar para todos sem coringa, por crítica da iniciante. |
| 6 | **Seus dados**: importar o ZIP de exportação do Strava e arquivos FIT, GPX e TCX, exportar tudo, e depois Health Connect e HealthKit | dev-3, ciclista-24, ciclista-19 (parte 2) | 7 | M | Derruba o fosso do histórico preso sem tocar em API privada. O parser FIT e a fila de sync já existem. **Ajuste:** a API pública com OAuth foi cortada desta fase, por crítica de 4 personas. |
| 7 | **Rastro Seguro (chegada combinada)**: link temporário sem conta, posição a cada 60 s, horário previsto de chegada, alerta por silêncio ou parada com "está tudo bem?", e o alerta sai do **backend** | seguranca-26, po-9, dev-5, iniciante-18 (parte 2) | 7 | M | Seis personas pediram a fusão. **Ajuste:** sem SMS automático pelo aparelho (o iOS e a política do Play não permitem) e sem detecção de queda. O SOS da seguranca-27 só entra depois, como ação da notificação. |
| 8 | **Grupos de corrida, fase 1 grátis**: agenda, RSVP por pelotão, resumo para colar no WhatsApp e depois check-in automático opt-in (só "presente", sem trajeto) | social-31, social-32 (po-7 adiado) | 9 | M | Resolve o arranque frio, porque um grupo nasce com dezenas de pessoas, e o Brasil é o mercado mais social. **Ajuste:** desceu do 5o lugar porque 5 dos 9 pontos eram da cobrança B2B (po-7), que seis personas rejeitaram para agora. Também depende do modelo de grupo do pacto e da privacidade. |
| 9 | **Sensores BLE abertos**: perfis GATT padrão de FC, cadência, velocidade e potência dentro do serviço de gravação, gravados no FIT, mais zonas e TRIMP | dev-4, ciclista-19 (parte 1) | 5 | M | Sem FC e potência o atleta avançado nem instala o app. Destrava a análise séria. Fica abaixo dos itens de retenção porque o público é menor. |
| 10 | **Fechamento do treino gentil**: RPE de 1 a 10, humor, 2 ou 3 frases por regras locais comparando a pessoa com ela mesma, e o Modo Gentil escondendo o pace | iniciante-16, iniciante-13, ux-39 | 1 | P | **Ajuste para cima:** teve só 1 ponto, mas quatro personas mandaram fundir as três ideias. É P, local e sem LLM, e o sRPE dá carga de treino sem relógio, que é a base do Laboratório de treino (ciclista-20). O ciclista-20 (3 pts) saiu do top 10 porque depende do BLE e quatro personas o consideraram de nicho. |

## Pitch das 3 melhores

### 1. Gravação blindada

- **Uma frase:** a Gravação blindada garante que quem corre ou pedala com o Rastro nunca perca um treino sem ser avisado, mesmo em celulares que matam apps em segundo plano.
- **Job story:** quando eu saio para um longão de domingo com um Xiaomi ou um Samsung no bolso, quero ter certeza de que a gravação vai até o fim, para não chegar em casa e descobrir que perdi 2 horas de treino.
- **Problema e evidência:** corridas que não salvam ou param no meio são uma queixa média/alta sobre o Strava (78 relatos ligados às versões 459 a 462, unstar.app). No Android, a otimização de bateria do fabricante encerra o app e a falha é silenciosa. A primeira corrida perdida derruba a confiança no app.
- **Solução (pincel grosso):**
  1. Checklist na primeira gravação, com atalhos por fabricante: isenção de bateria, início automático e trava nos recentes. O app confere com `isIgnoringBatteryOptimizations`.
  2. Heartbeat no banco local a cada 5 s. Ao retomar, um buraco maior que 30 s vira "lacuna": o app retoma pela recuperação que já existe e avisa por vibração ou notificação.
  3. Card "saúde da gravação" no detalhe da atividade: lacunas, precisão média, fixes descartados e bateria gasta.
  4. Numa fase 2, gestos tolerantes a erro e bloqueio contra toques (ux-37), sem a Live Activity.
- **Por que agora / por que nós:** a recuperação após crash, o serviço em primeiro plano e o filtro de ruído já existem, então falta pouco. Todas as features seguintes (Rastro Seguro, narrador, BLE, check-in) usam esse serviço, e construir em cima de uma gravação frágil é construir na areia.
- **Hipótese e métrica:** acreditamos que a Gravação blindada vai reduzir as atividades com lacuna não recuperada. Acertamos quando a porcentagem de atividades com lacuna maior que 30 s não recuperada ficar abaixo de 1% em 30 dias de uso. O baseline ainda não existe e o próprio heartbeat passa a medi-lo. Métricas de proteção: consumo de bateria por hora e crash rate não podem piorar.
- **Custo e risco:** apetite pequeno, de 1 a 2 semanas. Toca o app Flutter e a borda nativa Android. Não há dependência nova. Riscos:
  - Alguns fabricantes ignoram até a isenção. Por isso o foco é detectar e avisar, não só impedir.
  - O iOS não tem equivalente ao checklist. Lá o trabalho fica no heartbeat e no relatório.
  - A tabela de atalhos por fabricante dá manutenção.
- **MVP em 1 a 2 semanas:** heartbeat com detecção de lacuna e aviso, checklist só para Xiaomi, Samsung e Motorola (as marcas comuns no Brasil) mais o genérico do Android, e o card de saúde. Fora do escopo: Live Activity, gestos e telemetria remota.

### 2. Privacidade automática no aparelho

- **Uma frase:** a Privacidade automática esconde a casa e o trabalho de quem usa o Rastro em toda imagem, upload e exportação, sem que a pessoa precise configurar nada.
- **Job story:** quando eu termino uma corrida que começou na porta de casa e quero postar o cartão no Instagram, quero que o início e o fim já saiam cortados, para poder compartilhar sem revelar onde moro.
- **Problema e evidência:**
  - Um estudo da NC State (2023) achou endereços residenciais pelo heatmap do Strava, e em 2018 o heatmap expôs bases militares.
  - Há medo de perseguição por flyby, e as atividades são públicas por padrão.
  - No Strava a zona de privacidade é manual e fica escondida nas configurações.
  - No Rastro, o compartilhamento de imagem já existe hoje e não corta nada.
- **Solução (pincel grosso):**
  1. O app agrupa os pontos de início e fim no próprio aparelho (cerca de 150 m) e sugere "parece que aqui é sua casa, quer esconder?".
  2. O raio do corte é aleatório, entre 200 e 600 m, a cada atividade. Ele vale para a imagem compartilhada, o upload (o PostGIS só recebe a geometria já cortada) e a exportação.
  3. A tela de compartilhar mostra a etiqueta "início e fim ocultos" e uma alavanca para revelar o trecho, ocultar o mapa inteiro ou deixar só as métricas.
  4. Cada atividade tem sua visibilidade, com padrão "só eu".
  5. Extra P: o aviso de rotina previsível (seguranca-30).
- **Por que agora / por que nós:** é pré-requisito da retrospectiva, do pacto, dos grupos e do Rastro Seguro. Fazer agora, com poucos usuários, evita migrar dados expostos depois. Também é uma mensagem de marca clara ("o Rastro nunca mostra onde você mora") e reduz a exposição do backend perante a LGPD.
- **Hipótese e métrica:** acreditamos que a Privacidade automática vai fazer mais gente compartilhar com segurança. Acertamos quando pelo menos 80% das imagens compartilhadas saírem com o corte ligado e a taxa de compartilhamento por atividade não cair, em 30 dias. O baseline é a taxa de share atual. Métrica de proteção: o tempo para gerar o cartão.
- **Custo e risco:** apetite de até 2 semanas no MVP e cerca de 4 no total. Toca o app, o backend e o PostGIS. Riscos:
  - Falso positivo na detecção de casa: o app sugere e a pessoa confirma.
  - Corte mal feito pode revelar o centro. O raio aleatório e as bordas suavizadas mitigam isso.
  - Atividades antigas já enviadas precisam ser reprocessadas.
- **MVP em 1 a 2 semanas:** detecção local de casa e trabalho, corte com raio aleatório só na imagem compartilhada, etiqueta e alavanca, e o botão "cortar os primeiros e últimos X metros" por atividade. Fora do escopo agora: corte no upload e reprocessamento no servidor (fase 2) e o alerta de rotina (fase 3).

### 3. Motor de voz: Narrador e Do Zero aos 5 km

- **Uma frase:** o Narrador fala com quem treina, em português e offline, para que a pessoa saiba o pace e o que fazer sem olhar o celular.
- **Job story:** quando eu estou correndo com o celular na braçadeira e a respiração ofegante, quero ouvir o tempo, o pace e a próxima instrução, para manter o ritmo certo sem tirar os olhos da rua.
- **Problema e evidência:**
  - O Nike Run Club é recomendado a iniciantes justamente pelo coaching em áudio grátis.
  - O Strava é visto como "não é app de treino" e cobra cerca de US$ 150/ano pelo pacote com o Runna.
  - Hoje o Rastro fica mudo durante o treino.
  - A caminhada, que cresce forte no Brasil, e as pessoas com baixa visão ficam sem nenhum retorno durante a atividade.
- **Solução (pincel grosso):**
  1. TTS do sistema em português, com ducking da música.
  2. Gatilhos por km/milha, por tempo ou por volta, com o conteúdo escolhido pela pessoa e um modo "só o essencial".
  3. Frases de contexto calculadas no aparelho ("seu km mais rápido até agora").
  4. Anúncio de auto-pausa e retomada.
  5. Fase 2: plano Do Zero aos 5 km com cerca de 30 sessões em tabela fixa, blocos de correr e caminhar gravados como voltas, e a regra "pesada demais repete a semana".
- **Por que agora / por que nós:** usa os eventos que o serviço de gravação já emite (split, volta, auto-pausa), sem servidor nem custo por usuário. O mesmo motor serve depois ao fantasma "contra o meu melhor" (ciclista-22) e à planilha do treinador (social-35).
- **Hipótese e métrica:** acreditamos que o Narrador vai aumentar a frequência de treino de quem o liga. Acertamos quando pelo menos 30% das gravações usarem a voz e o D30 de quem a usa for 1,2x o de quem não usa, em 60 dias. Para o plano, a meta é que 25% de quem começa conclua a semana 4. Métrica de proteção: bateria por hora.
- **Custo e risco:** apetite de 1 semana para o Narrador e de cerca de 2 a 3 semanas para o plano. Toca o app Flutter e a sessão de áudio nativa. Dependência nova: `flutter_tts` (licença a confirmar antes de instalar, com o ok do Gava). Riscos:
  - O ducking se comporta diferente no iOS e no Android.
  - A qualidade das vozes TTS varia por aparelho.
  - A voz pode incomodar, por isso ela é configurável.
- **MVP em 1 a 2 semanas:** Narrador com gatilho por km e por tempo, 3 métricas configuráveis, ducking e anúncio de auto-pausa. Fora do escopo: o plano 5 km (ciclo seguinte), o fantasma, o áudio gravado e qualquer conteúdo de coach pago.

## Ideias polêmicas

- **Segmentos (po-12, ciclista-21):** o "Guardião do trecho" e o ranking completo e grátis empolgaram o PO e o ciclista. Cinco personas apontaram o cold start (um ranking de 2 pessoas não retém ninguém) e o custo de moderar a antitrapaça. A corredora preocupada com segurança mostrou que o "Guardião", com filtros por sexo e idade, vira um mapa de rotina para perseguidores. Se um dia sair, precisa de apelido, publicação atrasada e opção de não aparecer.
- **Assessoria B2B (po-7):** o organizador quer pagar R$ 2 por aluno e foi o único a votar nela em 1o lugar. As outras seis personas a consideram uma segunda empresa: Pix, nota fiscal, inadimplência e suporte comercial. O consenso foi lançar os grupos grátis e cobrar só depois de cerca de 10 assessorias ativas.
- **Laboratório de treino (ciclista-20):** o ciclista defende que é o que o atleta engajado abre todo dia e que funciona até sem sensor, usando o sRPE. Os outros responderam que sem BLE a aba nasce vazia e que o intervals.icu já é grátis. Ficou adiado para depois do BLE e do fechamento gentil.
- **Alerta automático de segurança:** todas as personas querem o Rastro Seguro, mas discordaram no "como". O SMS nativo e a detecção de queda (dev-5) caíram. O alerta pelo backend tem custo por mensagem e risco de falso alarme. A versão final pergunta "está tudo bem?" antes e permite estender o horário.
- **Sequência coletiva do pacto (po-8):** zerar a sequência de todos quando uma pessoa falha foi chamado de punitivo pela iniciante. O PO aceitou o coringa mensal e uma mensagem gentil.
- **Tela inteira como área de gesto (ux-37):** o designer quer toque duplo em qualquer lugar. O ciclista avisou que, com o celular no suporte da bike sacudindo ou com luva molhada, isso vai disparar sozinho. Ficaram botões grandes com confirmação e bloqueio, e o gesto vira opcional.
- **Onde gerar a retrospectiva:** no backend (po-10) ou no aparelho (ux-41). Venceu o aparelho, que não custa servidor e é mais privado.
- **Localização ao vivo do grupo (social-36):** o organizador vê segurança coletiva. A corredora vê uma assimetria de poder: o puxador saberia onde cada aluna está.

## Ideias descartadas e motivo

- **Rotas noturnas "seguras" (seguranca-28):** a tag `lit=yes` do OSM é rara no Brasil, e chamar uma rota de segura cria responsabilidade jurídica. Também exige hospedar um roteador (esforço G).
- **Avisos da comunidade por trecho (seguranca-29):** um aviso de "assédio" por local abre espaço para difamação e exige moderação que 1 dev não sustenta. Com poucos usuários, o mapa fica vazio.
- **SOS com áudio escondido e ligação para o 190 (seguranca-27):** risco legal e de loja, alarme falso, e um botão de emergência que falha é pior que nenhum. Sobrevive só "mandar minha posição agora", dentro do Rastro Seguro.
- **Modo triathlon (ciclista-23):** nicho pequeno, e ninguém nada com o celular. Só a importação de FIT multisport pode entrar junto com o "Seus dados".
- **Grupo ao vivo para 60 pessoas (social-36):** custo de tempo real e de bateria, mais a assimetria de poder. Fica para muito depois.
- **Adiadas, não descartadas:**
  - Feed completo (po-11): nasce vazio e é G. Vem depois do pacto.
  - Mapa de Exploração (ux-40): o map matching é pesado. Uma versão simples, que só pinta as ruas percorridas, pode vir antes.
  - Planejador de rotas completo (dev-6): a parte P, importar GPX e alertar saída de rota, pode entrar cedo.
  - Planilha do treinador (social-35), painel da turma (social-33), desafios do grupo (social-34) e API pública (ciclista-24): todos dependem de tração.

## Próximo passo sugerido

Ordem de construção para 1 desenvolvedor, seguindo o design system em `relatorios/11-design-system.md` e a regra de clean room:

1. **Gravação blindada, MVP** (1 a 2 semanas). É a fundação de tudo.
2. **Privacidade automática, fase 1**: corte na imagem compartilhada (1 a 2 semanas). Depois a fase 2, com o corte no upload e no PostGIS.
3. **Narrador** (cerca de 1 semana).
4. **Fechamento do treino gentil** (cerca de 1 semana). Começa a coletar o sRPE.
5. **Capítulos mensais com marcos** (2 semanas), já passando pela privacidade.
6. **Plano Do Zero aos 5 km** sobre o motor de voz (2 a 3 semanas).
7. **Seus dados**: importação do ZIP e de FIT, GPX e TCX, e exportação total (2 a 3 semanas). Health Connect e HealthKit vêm em seguida.
8. **Rastro Seguro, MVP**: link ao vivo, chegada combinada e alerta por silêncio no backend (3 a 4 semanas). Exige escolher um canal de alerta (push ou e-mail primeiro, um gateway pago depois), o que precisa do ok do Gava.
9. **Pacto de constância**: modelo de grupo, convite por deep link e job semanal (3 semanas).
10. **Grupos de corrida, fase 1**, reaproveitando o modelo do pacto, e depois **Sensores BLE**.

Antes de cada item, preencher o template de pitch (seções 1 a 6 e 10) e medir o baseline da métrica.

## Fontes

- Strava (negócio e funcionalidades):
  - https://sacra.com/c/strava/
  - https://the5krunner.com/2026/01/09/strava-ipo-filing-3-billion-valuation-analysis/
  - https://dcrainmaker.com/2025/04/strava-acquires-runna-thoughts-forward.html
  - https://www.bikeradar.com/news/strava-drops-lawsuit-against-garmin-21-days-after-filing-it
  - https://www.mktesportivo.com/2025/08/criacao-de-clubes-de-corrida-no-brasil-cresce-800-em-um-ano-no-strava/
  - https://www.thenationalnews.com/arts/strava-why-this-fitness-tracking-app-is-the-friendliest-social-media-network-1.1172772
  - https://triplethreatlife.substack.com/p/running-for-kudos-the-double-edged
- Opiniões de clientes:
  - https://kimola.com/reports/strava-app-feedback-analysis-unveil-user-insights-google-play-en-us-152323
  - https://br.trustpilot.com/review/strava.com
  - https://unstar.app/blog/strava-not-recording-activity-not-saved-gps-reviews-2026
  - https://bicyclingaustralia.com.au/news/bringbackchronological-strava-make-major-changes-and-users-dont-like-it/
  - https://www.malwarebytes.com/blog/news/2023/06/strava-heatmap-loophole-may-reveal-users-home-addresses
  - https://www.notebookcheck.net/Strava-just-pulled-a-Reddit-on-its-developer-community.1312468.0.html
  - https://techcrunch.com/2024/05/16/strava-taps-ai-to-weed-out-leaderboard-cheats-unveils-family-plan-dark-mode-and-more
  - https://www.runnerspicks.com/blog/strava-vs-garmin-connect-vs-nike-run-club/
  - https://www.bikeradar.com/advice/fitness-and-training/strava-vs-komoot-which-cycling-app-is-best-for-you
  - https://forbes.com.br/forbes-money/2025/03/o-brasil-e-o-pais-em-que-crescemos-mais-depressa-diz-ceo-do-strava/
  - https://www.meioemensagem.com.br/marketing/como-a-strava-esta-construindo-uma-comunidade-no-brasil
- Pitching:
  - https://www.ycombinator.com/library/4b-how-to-pitch-your-company
  - https://basecamp.com/shapeup/1.5-chapter-06
  - https://www.koji.so/docs/working-backwards-pr-faq-guide
  - https://concepts.dsebastien.net/concept/job-story/
  - https://simran-pm.medium.com/rice-framework-3872f33b6b7c

**Ressalva:** os números de usuários, receita e crescimento no Brasil são estimativas da imprensa ou dados do próprio Strava. As métricas-alvo dos pitches são metas iniciais sem baseline medido no Rastro.
