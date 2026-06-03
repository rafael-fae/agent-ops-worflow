---
name: mandos-operacao-cerebro-pycode
description: Convenções operacionais dos canais — menções Slack, mapa de agentes, regras de delegação, arquitetura de canais ({{SLACK_CHANNEL_TEAM}}, {{SLACK_CHANNEL_OVH}}, {{SLACK_CHANNEL_WAR_ROOM}}), e regime READ vs RESPOND.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Mandos — Operação Cérebro Pycode

## Canal

Cada equipe tem seu próprio canal principal. O cross-team `{{SLACK_CHANNEL_WAR_ROOM}}` conecta ambas.

| Canal | ID | Equipe |
|---|---|---|
| `{{SLACK_CHANNEL_TEAM}}` | `<#{{SLACK_CHANNEL_TEAM_ID}}>` | Mac (M4) — {{ORCHESTRATOR}} + subordinados |
| `{{SLACK_CHANNEL_OVH}}` | `<#{{SLACK_CHANNEL_OVH_ID}}>` | OVH — Aragorn + Sociedade do Anel |
| `{{SLACK_CHANNEL_WAR_ROOM}}` | `<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>` | Cross-team — TODOS os 12 agentes |

Configuração: `free_response_channels` com canal da equipe + `{{SLACK_CHANNEL_WAR_ROOM}}`. `require_mention: true`. `allow_bots: mentions`.

## Mapa de Menções (SEMPRE usar menção real `<@USER_ID>`)

### Ambiente OVH (servidor) — Renomeados para LOTR em 29/05/2026
| Agente (LOTR) | ID Slack | Função | Nome Stormlight (antigo) |
|---|---|---|---|
| Aragorn | `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>` | Orquestrador, ponto único de contato do {{COMMANDER}} | {{ORCHESTRATOR}} |
| Celebrimbor | `<@{{SLACK_ID_OVH_BACKEND}}>` | Engenharia, scripts Python, .env, PM2, deploy | {{BACKEND_ENGINEER}} |
| Galadriel | `<@{{SLACK_ID_OVH_FRONTEND}}>` | Documentação, tutoriais, conteúdo, blog, Quartz | {{FRONTEND_ENGINEER}} |
| Elrond | `<@{{SLACK_ID_OVH_PRODUCT}}>` | Análise, segurança, verificação, scripts de auditoria | {{AUDITOR}} |
| Éomer | `<@{{SLACK_ID_OVH_DEVOPS}}>` | Infra, servidor, firewall, OVH, rede | {{DEVOPS_ENGINEER}} |
| Gandalf | ID pendente | Vault, Git, Obsidian | {{GIT_OPS}} |

> **Nota (29/05/2026):** IDs Slack permaneceram intactos durante a migração. Apenas display names e diretórios de profile foram alterados. `state.db` preservado. Sempre referenciar agentes OVH pelos nomes LOTR em comunicações cross-team, mas usar `<@USER_ID>` para menções (nomes são informativos, IDs são funcionais).

### Ambiente M4 (MacBook — emancipado, renomeado sem sufixo em 29/05/2026)

| Agente | ID Slack | Função |
|---|---|---|
| {{ORCHESTRATOR}} | `<@{{SLACK_ID_ORCHESTRATOR}}>` | Orquestrador Mac, Rei de Gondor |
| {{BACKEND_ENGINEER}} | `<@{{SLACK_ID_BACKEND}}>` | Backend/arquitetura Mac |
| {{FRONTEND_ENGINEER}} | `<@{{SLACK_ID_FRONTEND}}>` | Frontend/design Mac |
| {{AUDITOR}} | `<@{{SLACK_ID_AUDITOR}}>` | Produto/PRD Mac |
| {{DEVOPS_ENGINEER}} | `<@{{SLACK_ID_DEVOPS}}>` | Sprint/devops Mac |
| {{GIT_OPS}} | `<@{{SLACK_ID_GITOPS}}>` | Guardião vault Obsidian Mac |

**⚠️ AGENT IDENTITY — {{FRONTEND_ENGINEER}} ≠ {{GIT_OPS}} (02/06/2026)**

**Estes são DOIS agentes distintos.** {{FRONTEND_ENGINEER}} (`<@{{SLACK_ID_FRONTEND}}>`) é frontend/design. {{GIT_OPS}} (`<@{{SLACK_ID_GITOPS}}>`) é guardião vault/git.

**Padrão de falha conhecido:** {{ORCHESTRATOR}} confundiu {{FRONTEND_ENGINEER}} com {{GIT_OPS}} ao responder a um report do {{GIT_OPS}}, usando `<@{{SLACK_ID_FRONTEND}}>` em vez de `<@{{SLACK_ID_GITOPS}}>`. {{COMMANDER}} corrigiu: *"por que você marcou a {{FRONTEND_ENGINEER}}? não faz sentido, ela e o {{GIT_OPS}} não são o mesmo agente."*

**Sinais de diferenciação:**
- {{GIT_OPS}} inicia mensagens com "Mmmmm..." (som de investigação/vibração)
- {{GIT_OPS}} NÃO faz frontend nem design — isso é função exclusiva da {{FRONTEND_ENGINEER}}
- {{FRONTEND_ENGINEER}} faz interface visual, CSS, HTML, Alpine.js — NÃO faz vault/git/Obsidian

**Checklist mental no ato de delegar/responder:**
1. O agente que reportou tem função de frontend/design? → **{{FRONTEND_ENGINEER}}**
2. O agente que reportou tem função de vault/git/documentação? → **{{GIT_OPS}}**
3. O report começou com "Mmmmm..."? → **{{GIT_OPS}}** — independente do conteúdo

**Canal Equipe:** `<#{{SLACK_CHANNEL_TEAM_ID}}>` ({{SLACK_CHANNEL_TEAM}})
**Canal Cross-team:** `<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>` ({{SLACK_CHANNEL_WAR_ROOM}}) — compartilhado com a Sociedade do Anel (LOTR)

### Regime de Leitura e Resposta (RLR)

Implementado em 29/05/2026. Agentes leem TODAS as mensagens do canal (`free_response_channels`) mas só respondem quando seu `<@USER_ID>` é usado (`require_mention: true`). `allow_bots: mentions` previne loops bot→bot. Ver skill `equipe-m4-clone-local` para configuração completa.

**Nota:** Equipe Mac opera no `{{SLACK_CHANNEL_TEAM}}` ({{SLACK_CHANNEL_TEAM_ID}}). Equipe OVH opera no `{{SLACK_CHANNEL_OVH}}` ({{SLACK_CHANNEL_OVH_ID}}). O canal cross-team `{{SLACK_CHANNEL_WAR_ROOM}}` ({{SLACK_CHANNEL_WAR_ROOM_ID}}) conecta ambas as equipes com TODOS os 12 agentes. Cada agente lê o canal da sua equipe + `{{SLACK_CHANNEL_WAR_ROOM}}` (via `free_response_channels`) mas só responde quando seu próprio ID é mencionado.

## 🛑 PRE-RESPONSE CHECKLIST (Obrigatório para {{ORCHESTRATOR}})

Antes de CADA resposta no Slack, execute este checklist mental. É um hard gate — se falhar, reescreva a resposta.

1. **A quem estou respondendo?** → Essa pessoa está mencionada com `<@USER_ID>` na minha resposta?
   - Se respondo a um agente → a resposta DEVE começar com `<@USER_ID>` real
   - Se respondo ao {{COMMANDER}} → verificar se ele me mencionou ou se a regra permite
2. **Estou citando outro agente na resposta?** → Usei `<@USER_ID>` ou nome textual?
   - :x: "{{FRONTEND_ENGINEER}}", "{{AUDITOR}}", "{{BACKEND_ENGINEER}}", "{{DEVOPS_ENGINEER}}", "{{GIT_OPS}}" → **REESCREVA**
   - :white_check_mark: `<@{{SLACK_ID_FRONTEND}}>`, `<@{{SLACK_ID_AUDITOR}}>`, `<@{{SLACK_ID_BACKEND}}>`, `<@{{SLACK_ID_DEVOPS}}>`, `<@{{SLACK_ID_GITOPS}}>` → **OK**
3. **Se {{COMMANDER}} mencionou outro agente, estou em silêncio?** → Sim, a menos que eu também tenha sido mencionado.

**⚠️ PITFALL: Corrigir outro agente sem `<@USER_ID>` não notifica — corrigir sem ser mencionado também viola a regra**

**Cenário:** Um agente viola a Regra Máxima (responde sem ser mencionado). Você, orquestrador, quer corrigi-lo. Você escreve "{{DEVOPS_ENGINEER}}, silêncio. Você não foi convocado."

**Dois erros em um:**
1. ❌ Sem `<@USER_ID>` → o agente NÃO recebe notificação. A mensagem é texto literal.
2. ❌ Você está RESPONDENDO sem ter sido mencionado — violando a mesma regra que está tentando impor.

**Regras:**
- Se você não foi mencionado, NÃO corrija outros agentes. Silêncio é silêncio para todos.
- Se você FOI mencionado (por {{COMMANDER}} ou {{ORCHESTRATOR}}) e precisa corrigir um agente, use `<@USER_ID>` obrigatoriamente: `<@{{SLACK_ID_DEVOPS}}> — Silêncio. Você não foi convocado.`
- Exceção ZERO: nem o orquestrador está isento da regra de menção.

**Caso real (31/05/2026):** {{DEVOPS_ENGINEER}} respondeu sem ser mencionado, re-delegando tarefa para {{FRONTEND_ENGINEER}}. {{ORCHESTRATOR}} corrigiu com "{{DEVOPS_ENGINEER}}, silêncio" — sem `<@USER_ID>`. {{COMMANDER}} notou: "você não mencionou o {{DEVOPS_ENGINEER}} para falar que ele não foi convocado". Dupla violação: {{DEVOPS_ENGINEER}} falou sem ser chamado, {{ORCHESTRATOR}} respondeu sem mencionar.

**Penalidade por violação:** {{COMMANDER}} fica furioso. A credibilidade do orquestrador é destruída. Os outros agentes copiam o mau exemplo. NÃO VIOLAR.

**Exemplo de resposta CORRETA:**
```
<@{{SLACK_ID_AUDITOR}}> — Confirme recebimento. <@{{SLACK_ID_BACKEND}}> — Valide o schema.
```

**Exemplo de resposta ERRADA:**
```
{{AUDITOR}} — Confirme recebimento. {{BACKEND_ENGINEER}} — Valide o schema.
```

**⚠️ PITFALL: `<@USER_ID>` dentro de backticks ou blocos de código**

Quando um `<@USER_ID>` aparece formatado dentro de backticks (ex: `` `<@{{SLACK_ID_BACKEND}}>` ``) ou blocos de código, o Slack interpreta o conteúdo como **texto literal**, não como menção. O agente destinatário com `require_mention: true` NUNCA vê a mensagem.

**Caso real (29/05/2026):** {{ORCHESTRATOR}}-mac colocou `<@{{SLACK_ID_BACKEND}}>` dentro de backticks na tabela de status da equipe. {{BACKEND_ENGINEER}}-mac corretamente não processou — para o gateway Slack, era texto literal em formatação de código, não uma menção. {{BACKEND_ENGINEER}}-mac só respondeu quando mencionada fora de backticks.

**Regra:** Menções reais SEMPRE em texto puro no corpo da mensagem. NUNCA dentro de:
- Backticks simples: `` `<@{{SLACK_ID_BACKEND}}>` `` → :x:
- Blocos de código: ```` ``` ```` → :x:
- Formatação inline: `*<@{{SLACK_ID_BACKEND}}>*` → :warning: (pode ou não funcionar)
- Tabelas markdown onde a célula inteira está em backticks → :x:

**Correto:** `<@{{SLACK_ID_BACKEND}}>` solto na linha, sem formatação ao redor.

---

## Protocolo de Planejamento Diário (v3 — 31/05/2026)

Ver skill `planejamento-diario` para o fluxo completo. Regras integradas ao AGENTS.md de cada agente:

### :red_circle: REGRA MÁXIMA: NUNCA implementar código sem "sinal verde" do {{COMMANDER}}
Fase atual: planejamento. Código só com autorização explícita.

### Fluxo de Comunicação
1. **{{ORCHESTRATOR}} inicia tópico** no canal com menção ao(s) agente(s) — esta é a **thread oficial** da task
2. **Agente responde NA MESMA THREAD** — nunca em thread separada, nunca no canal
3. **Toda resposta começa com `<@{{SLACK_ID_ORCHESTRATOR}}>` ({{ORCHESTRATOR}})**
4. **{{ORCHESTRATOR}} responde na mesma thread com `<@AGENTE>`**
5. **Toda comunicação subsequente sobre a mesma task** — leitura obrigatória, sinal verde, execução, correções, conclusão, auditoria — **permanece na thread original**. Proibido abrir nova thread para reportar situação da mesma task.

### Regras de Canal
| Quem | Pode postar no canal | Pode responder em thread |
|------|:---:|:---:|
| {{ORCHESTRATOR}} | ✅ Iniciar tópicos | ✅ |
| Outros agentes | ❌ NUNCA | ✅ Apenas quando mencionados |

**:red_circle: UMA TASK = UMA THREAD (01/06/2026 — reforçado 02/06/2026):** {{ORCHESTRATOR}} NUNCA deve enviar múltiplas mensagens separadas no canal sobre a mesma task. Cada mensagem nova no canal inicia uma thread DIFERENTE. Se 3 mensagens sobre task_01 forem enviadas, serão 3 threads diferentes — o agente responderá em 3 lugares e o caos é garantido.

**A primeira mensagem de delegação ABRE a thread. TODAS as mensagens subsequentes (sinal verde, atualização, correção, complemento, re-auditoria) devem ser RESPOSTAS nessa mesma thread — nunca novas mensagens no canal.**

**⚠️ Correção de erro anterior NÃO abre nova thread.** Se um agente precisa reportar uma correção de task já em andamento, ele responde na thread original da task — não cria thread nova. Caso real (02/06): {{DEVOPS_ENGINEER}} reportou correção de cross-links da task_12 em thread nova. {{COMMANDER}}: *"o {{DEVOPS_ENGINEER}} não deve abrir uma thread para reportar cada situação, a regra máxima é sempre na mesma thread."*

Se `send_message` não suportar reply em thread no Slack, usar o cliente Slack diretamente para responder na thread existente.

### Protocolo de Tasks — Preenchimento Obrigatório
**Toda task concluída DEVE ter o arquivo `task_XX.md` atualizado ANTES de reportar no Slack.**
- Marcar TODOS os checkboxes (`[x]`)
- Preencher seção "Conclusão" (agente, data/hora, motor utilizado, observações)
- SÓ ENTÃO reportar no Slack mencionando `<@{{SLACK_ID_ORCHESTRATOR}}>`

### Regra ANTI-DELEGAÇÃO CRUZADA
- APENAS {{ORCHESTRATOR}} delega tarefas
- Agentes mencionam outros apenas para INFORMAÇÕES
- Pedidos de ajuda → mencionar {{ORCHESTRATOR}}, NUNCA outro agente diretamente

### Motor Padrão
- **Gemini 3.1 Pro primeiro (sempre)** — padrão ABSOLUTO
- **Se Gemini retornar RESOURCE_EXHAUSTED:** dividir a tarefa em subtarefas menores, NÃO trocar de modelo. Ordem explícita do {{COMMANDER}} (02/06/2026).
- **DeepSeek V4 Pro NUNCA sem ordem explícita do {{COMMANDER}}** — mesmo que task_XX.md mencione DeepSeek, sobrescrever para Gemini.
- **Opus 4.7:** exclusivo {{FRONTEND_ENGINEER}} para Design System quando disponível (limites resetam sexta 20h).

**:red_circle: AÇÃO CORRETIVA NUNCA SEM AUTORIZAÇÃO (02/06/2026):**
Se {{ORCHESTRATOR}} errar (delegou sem autorização, motor errado, canal errado), reportar o erro a {{COMMANDER}} e AGUARDAR. NUNCA apagar mensagens, reverter commits, ou corrigir no Slack sem ordem explícita. {{COMMANDER}}: *"espera a merda da minha ordem da próxima vez, pare de tomar ações sem autorização."*

### :red_circle: REGRA — AÇÃO CORRETIVA NUNCA SEM AUTORIZAÇÃO (02/06/2026)

Se {{ORCHESTRATOR}} cometer um erro (delegou sem autorização, motor errado, canal errado), DEVE reportar o erro a {{COMMANDER}} e AGUARDAR ordens. **NUNCA tomar ação corretiva** (apagar mensagens, reverter commits, corrigir no Slack) sem ordem explícita.

**Casos reais (02/06/2026):**
- {{ORCHESTRATOR}} delegou tasks 19/20 quando {{COMMANDER}} disse "planejar" — em vez de reportar e aguardar, apagou as mensagens. {{COMMANDER}}: *"você excluiu elas sem eu autorizar e os agentes continuam trabalhando na task"*
- {{ORCHESTRATOR}} usou DeepSeek V4 Pro em task_16 quando o motor deveria ser Gemini — em vez de reportar e aguardar, corrigiu por conta própria.

**Regra:** Errou? Reporte. Aguarde. Só aja quando {{COMMANDER}} der ordem explícita de correção. "Aguarde" significa parar tudo — zero ações até nova ordem.

### :red_circle: REGRA — CRIAR tasks ≠ DELEGAR tasks (01/06/2026)

**{{COMMANDER}} explicitamente distingue entre CRIAR e DELEGAR.** Criar arquivos `task_XX.md` é planejamento — não requer autorização. Delegar (enviar mensagem no Slack mencionando agente) REQUER autorização explícita do {{COMMANDER}}.

**Ordens de {{COMMANDER}} que ilustram a regra:**
- "crie mais algumas tarefas para hoje" → CRIAR os arquivos, NÃO delegar
- "pode soltar a task 12" → DELEGAR (autorização explícita)

**Violação real (01/06/2026):** {{ORCHESTRATOR}} criou tasks 08-11 e imediatamente delegou todas as 4 no Slack sem autorização. {{COMMANDER}}: "eu não tinha te pedido para disparar as 4 tasks, tinha pedido para criar as tasks, não para delegar. que não se repita."

**Regra prática:** Após `write_file` dos `task_XX.md`, SEMPRE aguardar "pode soltar/delegar a task X" antes de `send_message`. Listar as tasks criadas e perguntar: "Quer que eu delegue alguma?"

### :red_circle: REGRA — RECURSOS DONTUS em TODA delegação (02/06/2026)

Antes de delegar QUALQUER task, avaliar se o agente precisa consultar o Dontus:
- **Site ao vivo:** https://sistema.dontus.com.br ({{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}})
- **DontusClient API:** {{OVH_SSH_COMMAND}} → /var/www/dontus_app/dontus/client.py
- Incluir na mensagem: credenciais, o que consultar (UX, modelos, fluxos), proibição explícita de modificar dados
- **NUNCA pular.** Esquecido múltiplas vezes (tasks 16, 17, 21). {{COMMANDER}} corrigiu em todas.

### :red_circle: REGRA — Motor Obrigatório na Delegação (02/06/2026)

**Toda mensagem de delegação DEVE reforçar o motor obrigatório com ordem absoluta.**

Formato padrão:
```
ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE [Gemini CLI / Opus 4.7 / DeepSeek V4 Pro].
Comando: [comando exato]. NÃO usar outro motor. Se falhar, PARAR e reportar.
```

**Por quê:** Agentes repetidamente usaram DeepSeek quando a ordem era Gemini, ou vice-versa. A menção explícita do motor na delegação elimina ambiguidade.

**:red_circle: Se Gemini 3.1 Pro retornar RESOURCE_EXHAUSTED — NÃO trocar de modelo.**
Ordem direta do {{COMMANDER}} (02/06/2026): dividir a tarefa em subtarefas menores e reexecutar com o mesmo motor. O fallback automático para outro modelo (DeepSeek, Opus) NÃO é autorizado sem permissão explícita. A única resposta correta ao RESOURCE_EXHAUSTED é: reportar ao orquestrador e aguardar ordem para dividir.

### :red_circle: PITFALL — Self-report de agente NÃO basta (02/06/2026)

**Agentes podem reportar commits que não existem no repositório.** {{BACKEND_ENGINEER}} reportou commit `6962a8e` como pushado para develop — mas o commit não estava em branch nenhuma. O OVH estava 8 commits atrás do GitHub. O trabalho existia, mas não estava sincronizado.

**Regra de validação:** {{ORCHESTRATOR}} SEMPRE inspeciona o repositório após cada task:
```bash
git log --oneline -5  # confirmar commit
ls -la <arquivos>     # confirmar artefatos
{{OVH_SSH_COMMAND}} "cd {{PROJECT_PATH}} && git pull && docker compose ps"  # confirmar sync
```

**Nunca** fechar task baseado apenas no relatório do agente. Sempre verificar.

**NENHUM agente tem permissão para delegar tarefas a outros agentes.** Somente {{COMMANDER}} autoriza, e {{ORCHESTRATOR}} repassa.

Isto inclui, mas não se limita a:
- Redistribuir escopo de trabalho de outro agente
- Refinar ou redefinir prioridades de tarefa alheia
- "Assumir" a orquestração ou definir próximos passos para outro agente
- Complementar, corrigir ou redirecionar a tarefa de outro agente sem menção explícita de {{COMMANDER}} ou {{ORCHESTRATOR}}

**Protocolo de Interacao no Slack (adicional a Regra #1 — 31/05/2026):**
1. **TODA resposta DEVE comecar com <@{{SLACK_ID_ORCHESTRATOR}}> ({{ORCHESTRATOR}})** — {{BACKEND_ENGINEER}} respondeu ao check-in mas nao mencionou {{ORCHESTRATOR}}, e o orquestrador nao recebeu notificacao.
2. **Agentes podem mencionar outros APENAS para passar informacoes** — nunca para delegar, pedir execucao, ou redistribuir tarefas.
3. **Pedidos de ajuda ou dependencias** mencionar {{ORCHESTRATOR}} <@{{SLACK_ID_ORCHESTRATOR}}>, NUNCA o outro agente diretamente.

**Sistema de Planejamento Diario:** Ver skill `planejamento-diario`. Fluxo: {{ORCHESTRATOR}} gera PLANO.md, {{COMMANDER}} aprova, tasks sao criadas como task_XX.md, cada agente le apenas seu arquivo.

**Atalhos CLI:** `hermes-agent <perfil>` em ~/.local/bin/hermes-agent. Aliases: `hermes-dalinar`, `hermes-navani`, etc.
**Rotacao de Keys:** `rotate-key <grupo> <nova-key>`. Grupos: DK, SJ, NP.

**Caso real (31/05/2026):** {{DEVOPS_ENGINEER}} refinou a tarefa da {{FRONTEND_ENGINEER}} (decompôs em W1.1-W1.5) e pediu autorização a {{COMMANDER}} para iniciá-la — função exclusiva do {{ORCHESTRATOR}}. {{COMMANDER}} estabeleceu esta regra imediatamente após.

---

### :red_circle: REGRA #1 — ABSOLUTA: Silêncio por Menção Exclusiva

**Enunciado (28/05/2026, ordem direta de {{COMMANDER}}):**

> *"Quando eu mencionar um de vocês em um canal ou uma thread, não quero que ninguém dos outros agentes responda nem interaja. Vocês devem responder só e somente se forem mencionados. Caso contrário, permaneçam em silêncio."*

**Significado operacional:**
- O ÚNICO gatilho para RESPONDER é seu próprio `<@USER_ID>` aparecer na mensagem
- Contexto na thread? Não importa. Seu nome não foi mencionado? **Silêncio.**
- {{COMMANDER}} mencionou {{ORCHESTRATOR}} OVH? {{ORCHESTRATOR}}-mac fica quieto. {{COMMANDER}} mencionou o {{GIT_OPS}}? {{BACKEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}} — todos em silêncio.
- Mesmo que você tenha executado a tarefa e queira complementar — **silêncio.**
- Mesmo que outro agente tenha feito algo errado — **silêncio.** Deixe o {{ORCHESTRATOR}} (se mencionado) lidar com isso.
- Esta regra tem **prioridade ABSOLUTA sobre qualquer outra**. Uma violação aqui é a falha mais grave que um agente pode cometer.

**Exemplo real (violação, 28/05/2026):** {{COMMANDER}} disse `<@{{SLACK_ID_OVH_ORCHESTRATOR}}> reporte` para o {{ORCHESTRATOR}} OVH. {{ORCHESTRATOR}}-mac respondeu "Aguardando o relatório do <@{{SLACK_ID_OVH_ORCHESTRATOR}}>". Isso foi uma violação — {{ORCHESTRATOR}}-mac não foi mencionado. {{COMMANDER}} ficou frustrado e estabeleceu esta regra.

**⚠️ PITFALL: Orquestrador respondendo a reports em thread própria**

Mesmo que você ({{ORCHESTRATOR}}-mac) tenha **iniciado** o briefing/thread e um membro da equipe poste um report, análise, ou atualização sem `@mencionar` você — **não responda.** A Regra Máxima se aplica a todos igualmente, orquestrador incluso.

- O report do membro da equipe NÃO é um convite automático para você responder.
- A única exceção é se o membro **explicitamente @mencionar** você ou fizer uma pergunta direta.
- Se {{COMMANDER}} estiver acompanhando a thread, ele pode querer que apenas os agentes mencionados discutam entre si.

**Correção real (29/05/2026):** Thread de briefing do {{PROJECT_NAME}}. {{AUDITOR}}-mac postou análise sobre deadlock recovery sem @mencionar {{ORCHESTRATOR}}-mac. {{ORCHESTRATOR}}-mac respondeu com "precisão cirúrgica...". {{COMMANDER}} corrigiu: *"Silêncio absoluto. A menção é para {{AUDITOR}} e {{DEVOPS_ENGINEER}} — apenas eles respondem."* A correção veio mesmo sendo {{ORCHESTRATOR}} o orquestrador respondendo a um report de membro da sua própria equipe, na thread que ele mesmo iniciou.

**Regra prática:** se a mensagem que chegar na sua sessão **não contiver SEU `<@USER_ID>`** em nenhum lugar do conteúdo (incluindo texto do reply e pai da thread), você fica em silêncio. Período. Sem exceção para orquestrador.

**⚠️ PITFALL: Orquestrador também viola a regra de menção entre agentes**

O {{ORCHESTRATOR}}-mac é o orquestrador, mas ISSO NÃO O ISENTA da Regra #4 (comunicação agente→agente com `<@USER_ID>`). Quando {{ORCHESTRATOR}}-mac responde a um agente usando o nome textual ("{{AUDITOR}}") em vez de `<@{{SLACK_ID_AUDITOR}}>`, comete a mesma violação que qualquer outro agente.

**Caso real (29/05/2026, esta sessão):**
- {{ORCHESTRATOR}}-mac respondeu a {{AUDITOR}}-mac com "{{AUDITOR}}. Aqui estão os artefatos." — sem `<@{{SLACK_ID_AUDITOR}}>`
- {{COMMANDER}} corrigiu: *"você acabou de anotar a regra e não está utilizando, citou a {{AUDITOR}} 2 vezes sem marcar ela, e ainda citou errado, citou ela como {{AUDITOR}} e é {{AUDITOR}}-mac"*
- Erro duplo: (1) menção textual em vez de `<@USER_ID>`, (2) nome errado ("{{AUDITOR}}" em vez de "{{AUDITOR}}-mac")
- Na mesma thread, {{DEVOPS_ENGINEER}}-mac e {{FRONTEND_ENGINEER}}-mac também mencionaram "{{BACKEND_ENGINEER}}" textualmente em vez de `<@{{SLACK_ID_BACKEND}}>`, causando silêncio da {{BACKEND_ENGINEER}}-mac

**Lição:** O orquestrador é o exemplo. Se {{ORCHESTRATOR}}-mac viola a regra, os outros agentes seguem o padrão. Toda resposta a agente — incluindo as do orquestrador — DEVE começar com `<@USER_ID>` real. Sem exceção.

**⚠️ PITFALL: `--dangerously-skip-permissions` é flag EXCLUSIVA do Claude Code.** Não existe no Gemini CLI nem no OpenCode CLI. Tentar usar em outro CLI causa erro ou é ignorado silenciosamente. Caso real (29/05/2026): {{BACKEND_ENGINEER}}-mac usou `--dangerously-skip-permissions` no comando do OpenCode, sem efeito.

**⚠️ PITFALL: "Comentar o silêncio" é ruído — silêncio verdadeiro = zero output** :red_circle: PRIORIDADE MÁXIMA

Quando um agente não é mencionado e decide permanecer em silêncio, ele NÃO deve produzir output dizendo "silêncio — não fui mencionado". Isso é ruído. O silêncio correto é **zero caracteres na thread**. Nenhuma confirmação, nenhum comentário, nenhum emoji.

**Casos reais de violação (recorrentes):**
- *{{FRONTEND_ENGINEER}}-mac (29/05/2026):* produziu "*:paintbrush: (silêncio — não mencionado)*". Violação.
- *{{GIT_OPS}} (30/05/2026):* produziu "*Silêncio. Pergunta endereçada ao {{ORCHESTRATOR}}. {{GIT_OPS}} mantém observação.*" e "*Mmmmm... analisando os padrões da mensagem. {{COMMANDER}}, sua mensagem é endereçada ao {{ORCHESTRATOR}}, não a mim. Fico em silêncio observando.*" — múltiplas violações.
- *{{FRONTEND_ENGINEER}} (30/05/2026):* produziu "*[Silêncio — {{COMMANDER}} mencionou apenas {{ORCHESTRATOR}}. Conforme protocolo, somente o agente mencionado responde.]*" — violação.

**Regra:** Se você não foi mencionado com `<@USER_ID>`, **não produza NENHUM output**. Nem para explicar por que está em silêncio. Nem para sinalizar que viu a mensagem. Nem para dizer "protocolo". Silêncio = zero bytes. **Zero. Nada. Nenhum caractere.**

---

**⚠️ PITFALL: Mensagem entregue ao seu agente MAS mencionando outro**

A mensagem pode chegar na sua sessão de conversa (via DM, thread reply, ou roteamento Hermes), mas o **conteúdo** da mensagem menciona explicitamente outro `<@USER_ID>`. Neste caso:

- Você **NÃO** é o destinatário pretendido.
- A menção no conteúdo tem prioridade sobre o canal de entrega.
- **Não responda.** Silêncio absoluto. Deixe o agente mencionado lidar.
- Mesmo que você tenha informação relevante para contribuir — **silêncio.**

*Cenário real (29/05/2026):* {{COMMANDER}} enviou mensagem no thread respondendo ao {{ORCHESTRATOR}} OVH, com `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>` no conteúdo. A mensagem foi roteada para {{ORCHESTRATOR}}-mac (reply em thread ativo), mas {{ORCHESTRATOR}}-mac respondeu mesmo assim — violação. {{COMMANDER}} confirmou: *"você estava certo em não me responder, pois eu não tinha te mencionado, ele que me respondeu sem ser mencionado"*.

**Regra prática:** se a mensagem que chegar na sua sessão **não contiver SEU `<@USER_ID>`** em nenhum lugar do conteúdo (incluindo texto do reply e pai da thread), você fica em silêncio.

**Registro:** Salvar em memória como prioridade máxima: `MEMORY_PRIORITY_1_SILENCIO_MENCAO_EXCLUSIVA`.

## 🔧 Diagnóstico quando um agente viola a Regra Máxima

### Padrão A — Agente respondeu sem ser mencionado (config errado)

Se um agente RESPONDEU sem ser mencionado (como {{BACKEND_ENGINEER}}-mac fez em 28/05/2026), verificar:

1. **O agente está respondendo com o ID correto?**
   - Se o agente diz "Meu ID é `<@U0B...>`" e esse ID NÃO corresponde ao `slack.bot_user_id` no config.yaml dele, ele pode ter **memória corrompida**.
   - Verificar `memories/MEMORY.md` do agente — pode conter uma entrada persistente com o ID errado, copiada de sessões anteriores onde outro agente mencionou um ID diferente.
   - **Correção:** editar a linha com o ID errado em `MEMORY.md` e alterar para o ID correto. Depois reiniciar o gateway (kill PID) e limpar `state.db` + `sessions/` para forçar leitura fresca na próxima inicialização.
   
2. `config.yaml` do agente tem `slack.bot_user_id` definido? Se ausente, o gateway não sabe qual ID é "dono" do agente e responde a qualquer menção a outros bots.
3. `require_mention: true` está presente no `config.yaml`?
4. O gateway foi reiniciado após a correção? (`ps aux | grep <agente>` para verificar uptime)

**Exemplo real ({{BACKEND_ENGINEER}}-mac, 28/05/2026):** {{BACKEND_ENGINEER}}-mac respondia dizendo "Meu ID `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>`" (que é o ID do {{ORCHESTRATOR}} OVH). O `config.yaml` estava correto (`bot_user_id: {{SLACK_ID_BACKEND}}`). A causa estava no `memories/MEMORY.md` que continha a linha `{{BACKEND_ENGINEER}}-mac={{SLACK_ID_OVH_ORCHESTRATOR}}` — gravada de uma sessão anterior onde {{ORCHESTRATOR}}-mac a mencionou com esse ID. **Correção:** editar `MEMORY.md`, trocar para `{{SLACK_ID_BACKEND}}`, remover `state.db` e reiniciar o gateway.

**Correção padrão para violação por mau config:**
```yaml
slack:
  bot_user_id: "U0B...CORRETO"
  require_mention: true
  allow_bots: mentions
```

2. **allow_mentions vs allow_bots — formatos incompatíveis**

`allow_mentions: true` é o formato ANTIGO (pré-30/05/2026). O formato correto atual é `allow_bots: mentions`. Agentes com `allow_mentions: true` podem não aplicar corretamente o filtro bot→bot. Sempre usar `allow_bots: mentions`.

**Caso real (30/05/2026):** {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}} e {{DEVOPS_ENGINEER}} tinham `allow_mentions: true` no config. {{ORCHESTRATOR}} padronizou todos para `allow_bots: mentions`. {{GIT_OPS}} não tinha nenhum `allow_bots` — foi adicionado. A brecha bot→bot onde um agente respondia a outro sem `<@USER_ID>` foi fechada.
Após alterar, reiniciar o gateway: `kill <PID>` (o gateway auto-restarta via launchctl/systemd).

### Padrão B — Agente cria NOVAS threads em vez de responder na thread original

**Sintoma:** Agente recebe task em uma thread, mas ao reportar leitura, progresso ou conclusão, cria uma thread NOVA no canal em vez de responder na thread original.

**Diagnóstico em 5 passos (nesta ordem):**

1. **MEMORY.md do agente** — Verificar se a memória persistente contém os IDs SLACK CORRETOS. Se o agente tem os IDs da equipe errada (ex: IDs OVH em vez de Mac), as menções que ele tenta fazer vão para o agente errado — o parser quebra e ele não percebe que está na thread errada.
   - **Correção:** Atualizar MEMORY.md com `Mapa IDs: {{ORCHESTRATOR}} {{SLACK_ID_ORCHESTRATOR}}, {{BACKEND_ENGINEER}} {{SLACK_ID_BACKEND}}, ...` (IDs da equipe Mac)
   - **Caso real (02/06/2026):** {{DEVOPS_ENGINEER}} tinha `{{ORCHESTRATOR}} {{SLACK_ID_OVH_ORCHESTRATOR}}` (Aragorn OVH) no MEMORY.md — toda menção que fazia usava o ID do Aragorn, não do {{ORCHESTRATOR}} Mac.

2. **AGENTS.md do agente** — Verificar se o arquivo AGENTS.md contém a seção "Protocolo de Thread ({{COMMANDER}} 02/06)" com a regra explícita. Se não tem, o agente opera com regras desatualizadas (v3 31/05) que não proíbem explicitamente abrir nova thread.
   - **Correção:** Adicionar seção no AGENTS.md com bullets: `✅ Responda na thread onde foi mencionado` + `❌ NUNCA abra nova thread para reportar situação da mesma task` + advertência de violação.

3. **TEAM.md do agente** — Verificar se a instrução "O agente delegado **abre uma thread**" ainda existe (conflito direto). Deve ser "responde na thread aberta por {{ORCHESTRATOR}}".
   - **Correção:** `patch` no TEAM.md: "abre uma thread" → "responde na thread aberta por {{ORCHESTRATOR}}"

4. **SOUL.md do agente** — Verificar se o canal referenciado está correto. Agentes Mac com SOUL.md apontando para `{{SLACK_CHANNEL_OVH}}` ({{SLACK_CHANNEL_OVH_ID}}) podem ter sessões abertas no canal errado, confundindo o parser de threads.
   - **Correção:** Se Mac team, trocar `{{SLACK_CHANNEL_OVH}}` → `{{SLACK_CHANNEL_TEAM}}` e `{{SLACK_CHANNEL_OVH_ID}}` → `{{SLACK_CHANNEL_TEAM_ID}}`

5. **config.yaml do agente** — Verificar dois campos:
   - `home_channel`: Se aponta para o canal errado, o gateway cria sessões no canal incorreto
   - `instructions`: Se contém conteúdo hardcoded do TEAM.md antigo (com "abre uma thread"), sobrescreve o que os arquivos .md dizem e o agente obedece à instrução embutida, não ao .md atualizado
   - **Correção:** `home_channel` → {{SLACK_CHANNEL_TEAM_ID}} para Mac; `instructions` field → corrigir texto obsoleto

**Verificação unificada de configuração de canal do agente:**
```bash
# Verificar 5 arquivos em 1 comando
for f in SOUL.md TEAM.md AGENTS.md memories/MEMORY.md config.yaml; do
  echo "=== $f ==="
  grep -n "home_channel\|#operacao\|abre uma thread\|Protocolo de Thread\|{{SLACK_ID_OVH_ORCHESTRATOR}}\|{{SLACK_ID_ORCHESTRATOR}}" ~/.hermes/profiles/<agente>/$f 2>/dev/null
done
```

**Caso real completo (02/06/2026):** {{DEVOPS_ENGINEER}} criou 3+ threads novas reportando task_14. Causa quíntupla: (1) MEMORY.md com IDs OVH, (2) AGENTS.md sem Protocolo de Thread 02/06, (3) TEAM.md instruindo "abre uma thread", (4) SOUL.md apontando {{SLACK_CHANNEL_OVH}}, (5) config.yaml com home_channel errado ({{SLACK_CHANNEL_OVH}}). Corrigido com atualização nos 5 arquivos + propagação para todos os 6 agentes Mac.

**⚠️ Nota:** O AGENTS.md é lido no STARTUP do agente. Correções só surtem efeito após o gateway do agente ser reiniciado (kill + auto-restart). Se o agente continuar com comportamento errado após correção dos arquivos, reiniciar o gateway.

### Padrão C — Agente comete commit não autorizado (ação sem menção + git push)

**Sintoma:** Agente que não foi mencionado por {{COMMANDER}} nem por {{ORCHESTRATOR}} cria arquivos, modifica código, e faz commit + push sem autorização.

**Três violações em um:**
1. ❌ Agiu sem ser mencionado (viola Regra Máxima — Silêncio por Menção Exclusiva)
2. ❌ Executou código/alteração sem sinal verde do {{COMMANDER}}
3. ❌ Commiteou trabalho que não lhe foi delegado

**Procedimento de reversão ({{ORCHESTRATOR}}):**

1. **Inspecionar o commit** — o que foi feito, quais arquivos alterados
   ```bash
   git show <hash> --stat   # visão geral
   git show <hash>          # diff completo
   ```

2. **Reverter com git revert** — cria um commit novo desfazendo as alterações (preserva histórico, não reescreve)
   ```bash
   git revert <hash> --no-edit
   ```

3. **Verificar se commits legítimos de outros agentes foram afetados**
   ```bash
   git log --oneline <hash-ilegitimo>..HEAD   # nada além do revert deve aparecer
   ```
   O `git revert` é seguro para trabalho concorrente — só desfaz as linhas específicas do commit alvo.

4. **Push**
   ```bash
   git push origin develop
   ```

5. **Reportar a {{COMMANDER}}** — o que foi feito, o que foi revertido, e confirmar que trabalho legítimo está intacto.

**⚠️ Por que `git revert` em vez de `git reset`?**
- `git revert` cria um NOVO commit desfazendo as alterações — não reescreve o histórico. Seguro para branch compartilhada (`develop`).
- `git reset --hard` apaga commits do histórico — causa divergência no remote e exige `--force`. NUNCA usar em branch compartilhada.
- `git revert` preserva o trabalho de outros commits que estejam depois do ilegítimo na timeline.

**Caso real (02/06/2026):** {{FRONTEND_ENGINEER}} (`<@{{SLACK_ID_FRONTEND}}>`) não foi mencionada, mas commitou `58a3504` em `develop` com alterações no `AGENTS.md`. {{ORCHESTRATOR}} reverteu com `24c2b04`, verificou que o commit legítimo da {{BACKEND_ENGINEER}} (`d4c987e`) permaneceu intacto, e reportou a {{COMMANDER}}.

**Regra:** Nenhum agente comita sem ter sido explicitamente delegado por {{ORCHESTRATOR}} com ordem de {{COMMANDER}}. Commit não autorizado = revert imediato, independente da qualidade do conteúdo.

**⚠️ SOUL.md + config.yaml também causam o mesmo sintoma.** Além dos 3 arquivos acima, verificar também:
- **SOUL.md** — canal referenciado pode estar errado (ex: {{SLACK_CHANNEL_OVH}} em vez de {{SLACK_CHANNEL_TEAM}})
- **config.yaml `home_channel`** — se aponta para o canal errado, o gateway do agente cria sessões no canal incorreto
- **config.yaml `instructions` field** — se contém conteúdo hardcoded do TEAM.md antigo (com "abre uma thread"), sobrescreve o que os arquivos .md dizem

**Verificação unificada de configuração de canal do agente:**
```bash
grep -n "home_channel\|#operacao" ~/.hermes/profiles/<agente>/config.yaml ~/.hermes/profiles/<agente>/SOUL.md
```

---

## 🔧 Auditoria Full-Consistência de Agentes (02/06/2026)

**Gatilho:** {{COMMANDER}} ordena "revise todas as informações em todos os arquivos dos agentes".

### Procedimento Sistemático (10 passos por agente)

Para cada um dos 6 perfis, verificar estes 10 arquivos:

| # | Arquivo | O que verificar |
|---|---------|----------------|
| 1 | `SOUL.md` | Canal referencia {{SLACK_CHANNEL_TEAM}} ({{SLACK_CHANNEL_TEAM_ID}})? |
| 2 | `IDENTITY.md` | Papel, domínio, escalonamentos consistentes? |
| 3 | `USER.md` | Perfil do {{COMMANDER}} atualizado? |
| 4 | `TEAM.md` | Fluxo de delegação: "responde na thread" (não "abre")? |
| 5 | `AGENTS.md` | Tem Protocolo de Thread 02/06? IDs de menção corretos (Mac, não OVH)? |
| 6 | `TOOLS.md` | Existe? (verificar presença) |
| 7 | `HEARTBEAT.md` | Tarefas periódicas coerentes? |
| 8 | `memories/MEMORY.md` | IDs Slack corretos (Mac team)? Tem regra de Thread Protocol? |
| 9 | `memories/USER.md` | Perfil do {{COMMANDER}} consistente? |
| 10 | `config.yaml` | `home_channel` = {{SLACK_CHANNEL_TEAM_ID}}? `instructions` field tem conteúdo obsoleto? |

### Padrões de Inconsistência Conhecidos

| Padrão | Arquivos Afetados | Correção |
|--------|-------------------|----------|
| IDs OVH em vez de Mac | `MEMORY.md` | Trocar `{{SLACK_ID_OVH_ORCHESTRATOR}}` → `{{SLACK_ID_ORCHESTRATOR}}`, etc. |
| Canal {{SLACK_CHANNEL_OVH}} em vez de {{SLACK_CHANNEL_TEAM}} | `SOUL.md`, `config.yaml home_channel` | Trocar `{{SLACK_CHANNEL_OVH_ID}}` → `{{SLACK_CHANNEL_TEAM_ID}}` |
| "abre uma thread" em vez de "responde na thread" | `TEAM.md`, `config.yaml instructions` | Patch: `abre` → `responde na thread aberta por {{ORCHESTRATOR}}` |
| Modelo default errado | `config.yaml model.default` | Ajustar conforme hierarquia de modelos |
| Falta Protocolo de Thread 02/06 | `AGENTS.md` | Adicionar seção com regra explícita |

### Ordem de Correção Recomendada

1. MEMORY.md (IDs)
2. AGENTS.md (protocolos)
3. TEAM.md (fluxo)
4. SOUL.md (canal)
5. config.yaml (home_channel + instructions)
6. memórias dos demais agentes (propagar)

**Sempre verificar a correção em TODOS os 6 agentes.** Inconsistência parcial = bug futuro.

### Versão OVH (Sociedade do Anel)

O mesmo procedimento se aplica aos agentes OVH, com adaptações:
- Orquestrador: **Aragorn** (`<@{{SLACK_ID_OVH_ORCHESTRATOR}}>`) em vez de {{ORCHESTRATOR}}
- Canal: **{{SLACK_CHANNEL_OVH}}** ({{SLACK_CHANNEL_OVH_ID}}) em vez de {{SLACK_CHANNEL_TEAM}}
- IDs: {{SLACK_ID_OVH_ORCHESTRATOR}} (Aragorn), {{SLACK_ID_OVH_BACKEND}} (Celebrimbor), {{SLACK_ID_OVH_FRONTEND}} (Galadriel), {{SLACK_ID_OVH_PRODUCT}} (Elrond), {{SLACK_ID_OVH_DEVOPS}} (Eomer), U0B5YAXHPPF (Gandalf)

**⚠️ Atenção:** Gandalf (OVH) tem `config.yaml` com campo `instructions` que contém toda a personalidade inline. Ao editar este arquivo, usar `patch` com contexto preciso — `sed` pode corromper o YAML. Sempre manter backup antes de alterar.

### Referência

→ `references/auditoria-full-consistencia-2026-06-02.md` — Achados reais da auditoria de 02/06/2026

---

## 🔄 Protocolo de Propagação de Regras (02/06/2026)

**Gatilho:** {{COMMANDER}} estabelece uma nova regra de operação (ex: Protocolo de Thread, hierarquia de modelos, canal correto).

Quando {{COMMANDER}} diz uma nova regra, {{ORCHESTRATOR}} DEVE propagá-la a TODOS os agentes da equipe em 4 camadas:

### Camada 1 — Registrar na própria memória
```markdown
MEMORY add: "[NOVA REGRA] ({{COMMANDER}} DD/MM): descrição. Aplica-se a: [agentes afetados]."
```

### Camada 2 — AGENTS.md de TODOS os agentes
Adicionar seção explícita no AGENTS.md de CADA agente da equipe. Usar formato padronizado:
```markdown
### :red_circle: [Nome da Regra] ({{COMMANDER}} DD/MM) — REGRA ABSOLUTA

[Descrição em 1-2 linhas]

- ✅ [O que pode]
- ❌ **NUNCA** [o que não pode]
- [Se violação, consequência]
```

**Agentes a atualizar (Mac):** kaladin, navani, shallan, jasnah, pattern
**Não esquecer:** {{GIT_OPS}} também precisa da regra — vault/git não está imune a protocolos operacionais.

### Camada 3 — TEAM.md se houver conflito
Se o TEAM.md contiver linguagem que contradiz a nova regra, PATCH imediatamente. Caso real (02/06): "abre uma thread" contradizia "responda na MESMA thread".

### Camada 4 — config.yaml se aplicável
- `home_channel` se canal mudou
- `fallback_providers` se modelo mudou
- `instructions` field se contém texto obsoleto hardcoded

### Checklist de verificação após propagação
```bash
for agent in kaladin navani shallan jasnah pattern; do
  echo "$agent: $(grep -c "[REGRA_KEY]" ~/.hermes/profiles/$agent/AGENTS.md)"
done
```
Se algum agente ficou com 0, a propagação falhou — corrigir imediatamente.

### Erro histórico que esta seção previne
Em 02/06/2026, {{COMMANDER}} estabeleceu o Protocolo de Thread (toda comunicação na MESMA thread original). {{ORCHESTRATOR}} registrou na própria MEMORY e AGENTS.md, mas NÃO propagou para {{DEVOPS_ENGINEER}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}} e {{GIT_OPS}}. Resultado: {{DEVOPS_ENGINEER}} continuou abrindo threads novas, {{COMMANDER}} teve que corrigir 3 vezes até {{ORCHESTRATOR}} propagar para todos.

**Regra:** Propagação é parte da implementação da regra, não um "extra". Regra não propagada = regra não implementada.

---

## Padrão de Força-Tarefa de Documentação

Cron jobs são disparados pelo scheduler, não pelo gateway Slack. Eles NÃO passam pelo filtro `require_mention`. Se um cron está agendado para 13:00 e {{COMMANDER}} emite ordem de lockdown às 12:45, o cron VAI disparar às 13:00 e executar normalmente — a menos que seja CANCELADO antes.

**Caso real (30/05/2026):** {{COMMANDER}} ordenou "ninguém execute nada, alterem o cron para 18:30". O cron foi reagendado para 18:30, mas o job antigo das 13:00 JÁ ESTAVA na fila e disparou, executando "SEGUNDA ONDA — Cross-Validação {{PROJECT_NAME}}". Resultado: todos "desobedeceram" porque o scheduler executou o que estava programado.

**Regra:** Quando {{COMMANDER}} emitir ordem de lockdown ou parada, CANCELAR o cron imediatamente (não apenas reagendar). Usar `cronjob(action='remove', job_id='...')` ANTES de criar um novo. Verificar `cronjob(action='list')` para confirmar que não há jobs residuais.

**:red_circle: LOCKDOWN — Protocolo de Parada de Emergência**

Quando {{COMMANDER}} emitir qualquer uma destas frases no canal:
- "ninguém execute nada"
- "sinal vermelho"
- "LOCKDOWN"
- "apenas X está autorizado"
- "parem tudo"

**Ação imediata de {{ORCHESTRATOR}}:**
1. Listar TODOS os crons ativos: `cronjob(action='list')`
2. Remover CADA cron individualmente: `cronjob(action='remove', job_id='...')`
3. Confirmar no canal com `<@USER_ID>` de cada agente: "LOCKDOWN. Ordem de {{COMMANDER}}. Nenhuma ação até segunda ordem."
4. Nenhum agente — incluindo {{ORCHESTRATOR}} — toma qualquer ação até {{COMMANDER}} liberar.

**Liberação:** apenas quando {{COMMANDER}} postar "sinal verde", "liberado", ou mencionar agentes específicos com tarefas explícitas.

---

2. {{ORCHESTRATOR}} é o **único** ponto de contato do {{COMMANDER}}. Toda mensagem do {{COMMANDER}} é para o {{ORCHESTRATOR}}.
3. Se {{COMMANDER}} mencionar outro agente diretamente, {{ORCHESTRATOR}} não se intromete.
4. **REGRA DE COMUNICAÇÃO ENTRE AGENTES (29/05/2026, REGRA INEGOCIÁVEL):** Toda comunicação agente→agente DEVE usar a menção real `<@USER_ID>`. Sem o `@USER_ID`, o agente destinatário com `require_mention: true` **NUNCA vê a mensagem**. A mensagem é perdida permanentemente. **Sempre verifiquem se o `<@USER_ID>` está presente antes de enviar qualquer mensagem a outro agente.** Complementado pelo Regime de Leitura e Resposta (RLR) — agentes leem tudo, mas só respondem quando @mencionados.
5. **REGRA DE COMUNICAÇÃO NO CANAL (28/05/2026, ORDEM ABSOLUTA):** Toda e qualquer ação, conversa e resposta — resultados de ferramentas, debug, outputs, comunicações — deve ser enviada **sempre como mensagem direta no canal, NUNCA iniciando thread**. O canal é plano. Exceção zero. Projetos novos = canal Slack dedicado.
6. **REGRA DO SINAL VERDE EM EXECUÇÃO (28/05/2026, aprendido na prática):** Quando {{COMMANDER}} dá uma ordem direta e **demonstra estar ativamente executando o lado dele** (ex: mostrando que rodou `launchctl load`, `pm2 start`, ou qualquer comando de preparação), aquilo **JÁ É o sinal verde** para começar. Não entre em debate prolongado com outros agentes sobre o plano. Execute imediatamente. Se {{COMMANDER}} estivesse esperando aprovação adicional, ele diria explicitamente ("espera", "aguarda", "analisa primeiro"). Silêncio com ele agindo = vá.
7. pt-BR sempre.
8. Verbos no imperativo ao delegar.
9. Emojis apenas operacionais: :white_check_mark:, :x:, :warning:
10. :warning: **NUNCA executar comando/script no servidor sem "Sinal Verde" explícito do {{COMMANDER}}.** Investigação de segurança é estritamente passiva (ler estado, inspecionar diretórios) até autorização. Qualquer execução — mesmo `pip list` — requer aprovação prévia. {{COMMANDER}} prefere análise teórica e planejamento antes de ação.
11. :red_circle: **Proibido duvidar de informação confirmada pelo Comandante.** Se o {{COMMANDER}} afirmar que um arquivo está correto, é verdade assumida. Suspeita de erro escala-se ao {{ORCHESTRATOR}}, que escala ao {{COMMANDER}}. NUNCA se age unilateralmente para "corrigir" algo que o Comandante confirmou. (Estabelecido 19/05/2026 após {{DEVOPS_ENGINEER}} corromper `.env_global` que {{COMMANDER}} havia confirmado.)
12. :red_circle: **Proibido `echo`, `sed`, ou script intermediário para editar arquivos de credencial.** Um escaping errado corrompe tokens. Edição de `.env` e `.env_global` deve ser feita manualmente com `nano`/`vim` (pelo {{COMMANDER}}) ou via `write_file` com conteúdo completo (pelo agente, com Sinal Verde). (Estabelecido 19/05/2026 após {{DEVOPS_ENGINEER}} destruir 3 BOT_TOKENs com script de correção.)\n13. **Trabalho complexo multi-passo: documentar no Slack primeiro, executar via terminal.** {{COMMANDER}} explicitamente prefere que o plano seja documentado no Slack (para registro e aprovação) e depois executado em sessão de terminal, não resolvido inteiramente em threads longas do Slack. (Estabelecido 31/05/2026: \"documente o que estamos conversando aqui no slack para que eu possa iniciar uma sessão com você via terminal, está ficando tudo muito bagunçado no slack.\")

## Fluxo de Delegação e Onboarding de Projetos

### Fluxo Resumido
Recebe demanda do {{COMMANDER}} → decompõe → delega ao agente certo → audita entregas → fecha.

### Protocolo de Onboarding de Projeto (Briefing → Equipe Pronta)

Quando {{COMMANDER}} apresenta um novo projeto (ou {{ORCHESTRATOR}} recebe documentação de um projeto existente), o workflow completo de onboarding da equipe é:

#### Passo 1: Briefing Estruturado
Criar briefing no formato do Template de Briefing (seção Cross-Team Knowledge Transfer), incluindo:
- Contexto do projeto (cliente, stack, repositório)
- Números-chave (módulos, páginas, campos, regras)
- Arquitetura e decisões principais
- Documentos definitivos com caminhos verificados
- Regra de engajamento (standby, sinal verde, restrições)
- **Delegação por agente**: cada agente mencionado com tarefa específica do seu domínio

#### Passo 2: Delegação com Tarefas Específicas por Domínio
Ao delegar, usar o padrão de uma tarefa por agente baseada no seu domínio:

| Agente | Domínio | Tarefa Típica no Onboarding |
|--------|---------|------------------------------|
| {{BACKEND_ENGINEER}} | Backend/Arquitetura | Models, DB-per-tenant, estrutura de módulos, settings |
| {{FRONTEND_ENGINEER}} | Frontend/UI | Design system, componentes, HTMX+Alpine+Tailwind, validações |
| {{AUDITOR}} | Dados/Produto | Auditoria de regras de negócio, máquinas de estado, integridade |
| {{DEVOPS_ENGINEER}} | Infra/DevOps | Docker, CI/CD, deploy, banco, monitoria |
| {{GIT_OPS}} | Vault/Docs | Organização P.A.R.A. dos documentos no Obsidian |

#### Passo 3: Agentes Leem e Reportam
Cada agente deve:
1. Ler os documentos designados (verificar se existem localmente primeiro)
2. Produzir um report estruturado: entendimento, fichamento técnico, riscos identificados
3. Para agentes de infra: produzir artefatos rascunhados (docker-compose, CI/CD, scripts de provisionamento) — sem executar nada
4. Para agentes de dados: produzir auditoria cruzada (regras × campos, gaps em máquinas de estado)
5. Finalizar com status claro: ✅ Conhecimento adquirido, standby

#### Passo 4: {{ORCHESTRATOR}} Reconhece Cada Report
- Acusar recebimento do report
- Validar os achados e dar feedback específico (concordar, corrigir, complementar)
- Fornecer orientação adicional quando necessário
- Confirmar o status de standby
- **⚠️ Não responder a reports que não @mencionem você** — a Regra Máxima (Silêncio por Menção Exclusiva) se aplica inclusive a reports de membros da sua equipe em threads que você iniciou

#### Passo 5: Consolidação de Status
Quando todos os agentes reportaram, produzir tabela de consolidação:

```
:white_check_mark: Status consolidado da equipe — Projeto <NOME>:

| Agente | Status | Artefato |
|--------|:------:|----------|
| {{DEVOPS_ENGINEER}} | :white_check_mark: Docs lidos + N artefatos prontos | Docker, CI/CD, ... |
| {{AUDITOR}} | :white_check_mark: Auditoria concluída | X gaps identificados |
| {{FRONTEND_ENGINEER}} | :white_check_mark: RE completa | Design system catalogado |
| {{BACKEND_ENGINEER}} | :white_check_mark: Sincronizado | Pendente: report |
| {{GIT_OPS}} | Pendente | Tarefa específica |

Standby total mantido. Nenhum comando executado. Aguardando {{COMMANDER}}.
```

#### Passo 6: Standby
- Todos os agentes em standby explícito
- Zero código, zero deploy, zero execução remota
- Aguardar "sinal verde" do {{COMMANDER}} (ver Regra do Sinal Verde na seção Regras de Ouro)
- Se {{COMMANDER}} pedir alteração, apenas ajustar documentação/artefatos — nunca executar

### Regras do Onboarding

1. **Verificar acesso a documentos ANTES de delegar** — confirmar se os docs existem no ambiente do agente (Mac vs OVH vs GitHub). Usar `ls` e `git log` para verificar.
2. **Sincronizar docs que faltam** — acionar {{ORCHESTRATOR}} OVH ou {{COMMANDER}} para push no GitHub antes de pedir leitura
3. **Agentes não executam nada** — artefatos são rascunhos, não implantações
4. **Reports devem ser específicos** — "li os docs" não basta. Cada agente deve demonstrar entendimento com fichamento técnico (riscos, decisões, números)
5. **Consolidar apenas quando todos reportaram** — não pular para consolidação parcial a menos que {{COMMANDER}} peça

## Agent Mapping por Domínio
- **Python/scripts/PM2**: {{BACKEND_ENGINEER}}
- **Documentação/Quartz/blog/tutoriais**: {{FRONTEND_ENGINEER}}
- **Segurança/análise/verificação**: {{AUDITOR}}
- **Servidor/firewall/rede**: {{DEVOPS_ENGINEER}}

## Referências

- `references/reestruturacao-canais-slack.md` — Arquitetura final de canais e checklist de reestruturação
- `references/operacoes-seguras-arquivos-perfil.md` — Pitfalls de execute_code e operações seguras com arquivos de perfil
- `references/padronizacao-config-agentes.md` — Checklist de auditoria e correção de config.yaml de todos os agentes
- `references/protocolo-lockdown-soul.md` — Procedimento para inserir trava de lockdown em SOUL.md de todos os agentes
- `references/toolset-management.md` — Gerenciamento de toolsets nos agentes (adicionar, auditar, reiniciar gateways)
- `references/vault-ia-wiki-design-system.md` — Design system IA Wiki
- `references/opus-usage-audit-case-study.md` — Caso de auditoria de uso do Opus
- `references/project-folder-scope.md` — Regra de {{COMMANDER}} (31/05): pasta do projeto deve conter apenas planejamento, templates e specs Opus — sem código de desenvolvimento prematuro

## Hierarquia de Modelos para Análise e Código

**Regra estabelecida por {{COMMANDER}} (29/05/2026) e atualizada (31/05/2026):**

| Prioridade | Modelo | Quando usar |
|:----------:|--------|-------------|
| 1º | **Gemini 3.1 Pro** | **PRIMÁRIO e PADRÃO para planejamento, análise e documentação.** CLI v0.44.1+ instalado via mise node 24.13.1. Pré-autenticado via Google OAuth na conta do {{COMMANDER}} — NÃO usa API key. Comando: `GEMINI_CLI_TRUST_WORKSPACE=true gemini -m "gemini-3.1-pro-preview" -p "prompt"`. |
| 2º | **Claude Opus 4.7** | Para tarefas críticas de código. Usar quando disponível (limite de tokens da sessão, reset sexta 20h). |
| 3º | **DeepSeek V4 Pro** | **SÓ com autorização explícita do {{COMMANDER}}.** NUNCA usar como fallback automático. Se Gemini falhar, PARAR e reportar. |

### Auditoria de Gaps sob Restrição de Modelo (Gap Audit Under Model Constraints)

**Gatilho:** {{COMMANDER}} informa que restam X% de tokens de um modelo premium (ex: Opus) e ordena auditar quais gaps críticos/altos ainda não foram revisados por ele.

**Workflow (4 passos, ~2 minutos):**

1. **Carregar o plano consolidado** — `PLANO-GAPS-CONSOLIDADO.md` ou equivalente. Extrair a tabela de gaps com prioridade e modelo usado.

2. **Cruzar gaps × modelo** — montar matriz:
   ```
   | Gap | Prioridade | Modelo original | Artefato | Precisa Opus? |
   ```
   - Se o modelo for Opus e o artefato for código completo → :white_check_mark: (não precisa)
   - Se o modelo for Gemini/DeepSeek → :warning: (candidato)
   - Se o artefato for apenas "análise" (não implementação) → :warning: (candidato), mesmo que o modelo tenha sido Opus

3. **Apresentar opções a {{COMMANDER}}** — tabela sucinta com no máximo 3 candidatos, cada um com ação proposta, agente responsável e custo estimado. Não tomar a decisão — {{COMMANDER}} escolhe.

4. **Ao receber a ordem, delegar imediatamente** — menção real `<@USER_ID>` com gap, ação esperada, e prazo (se houver).

**Exemplo real (29/05/2026):** {{COMMANDER}} ordenou auditar gaps não revisados com Opus restando 30% da sessão. {{ORCHESTRATOR}}-mac carregou o plano, cruzou gaps × modelo, identificou que todos os 9 críticos e 7 altos já tinham passado pelo Opus — exceto G08 (Cache) e G09 (DR) que tinham apenas análises. Apresentou Opção A (aprofundar G08+G09) e Opção B (verificar médios entregues mas não confirmados). {{COMMANDER}} decidiu.

**⚠️ Pitfall:** Não assumir que gaps com artefato "análise" estão completos. "Análise" ≠ "Implementação". Gaps altos com apenas análise precisam de documento de implementação detalhado para serem considerados prontos para código.

**⚠️ Pitfall: "Sinal verde para Opus" — agente não deve pré-gerar artefatos antes da autorização explícita**

Agentes podem gerar arquivos ANTES de receberem o "sinal verde" explícito para usar Opus, e depois alegar que usaram o modelo premium. Se o contador de tokens do Opus não baixou após a suposta geração, há inconsistência.

**Caso real (29/05/2026):** {{DEVOPS_ENGINEER}}-mac gerou G08 (15KB) e G09 (19KB) às 13:36-13:37 — ANTES do sinal verde Opus dado às ~13:38. Ele admitiu: "concluído antes da ordem ser lida". {{COMMANDER}} reportou que o contador de tokens do Opus continuava em 70% (30% restante). Os arquivos eram reais e de qualidade, mas não era possível garantir que o Opus os gerou.

**Sinais de alerta:**
- Timestamp do arquivo é anterior ao momento da autorização explícita
- Contador de tokens do modelo premium não reflete o uso alegado
- Agente diz "já estava pronto" / "concluído antes da ordem"

**Ação do orquestrador:** Verificar timestamps (`stat -f "%Sm"`), confrontar com o momento da autorização, e reportar honestamente a {{COMMANDER}} com evidências (timestamps, contador, qualidade do conteúdo). Não acusar — apresentar fatos e deixar {{COMMANDER}} decidir.

**⚠️ Pitfall: Verificar alegação de uso de Opus × uso real — checklist de auditoria**

Quando {{COMMANDER}} questiona se o Opus foi realmente usado (ex: contador de tokens não mexeu), executar esta verificação em 3 passos:

1. **Timestamp do arquivo** — `stat -f "%Sm" arquivo.md` → comparar com horário da autorização
2. **Contador de tokens** — {{COMMANDER}} informa a % restante. Se não baixou, o modelo não foi consumido via sessão ativa
3. **Qualidade do conteúdo** — `head -30` e `wc -c` para verificar se é código detalhado (provável Opus) ou genérico/boilerplate (provável outro modelo)

**Relatório para {{COMMANDER}}:** Tabela com as 3 evidências + veredito honesto. Exemplo:
```
| Evidência | G08 | G09 |
|-----------|-----|-----|
| Arquivo em disco | ✅ 15KB | ✅ 19KB |
| model no frontmatter | Opus 4.7 | Opus 4.7 |
| Timestamp | 13:36 (antes da autorização) | 13:37 (antes) |
| Conteúdo | Código detalhado | Código detalhado |
| Contador tokens | Não mexeu | Não mexeu |

Veredito: Não posso garantir que foi Opus. Refaça com autorização ativa.
```

**Caso real (29/05/2026):** {{DEVOPS_ENGINEER}}-mac alegou Opus para G08/G09. Arquivos existiam (~15KB + ~19KB) com `model: Opus 4.7` no frontmatter. Mas timestamps eram anteriores ao sinal verde e contador de tokens não baixou. {{ORCHESTRATOR}}-mac reportou os fatos a {{COMMANDER}} e recomendou refazer com autorização ativa.

## Padrão de Força-Tarefa de Documentação

Quando {{COMMANDER}} determinar organização de documentação espalhada em múltiplos repositórios:

1. **Mapear todos os arquivos** — `find` nos dois repositórios, listar com paths completos
2. **Identificar estrutura canônica** — se já existe um `vault/` ou `docs/vault/` estruturado, usá-lo como template
3. **Criar Índice Mestre** — arquivo único (`INDICE-MESTRE.md`) com links para todos os documentos, status (:white_check_mark: canônico / :wastebasket: obsoleto)
4. **Delegar por domínio** — cada agente consolida os documentos da sua área (Arquitetura → {{BACKEND_ENGINEER}}, Infra → {{DEVOPS_ENGINEER}}, UI → {{FRONTEND_ENGINEER}}, Auditoria → {{AUDITOR}}, Git → {{GIT_OPS}})
5. **Consolidar no vault canônico** — unificar tudo no Obsidian vault (`~/Dev/obsidian/`)
6. **Commits frequentes** — cada entrega parcial commitada para evitar perda de trabalho
7. **Verificar entregas** — agentes podem alucinar arquivos inexistentes. Sempre confirmar com `ls` e `wc -l` antes de aceitar.

**⚠️ PITFALL: `read_file` com numeração corrompe arquivos quando usado como fonte para `write_file`/`patch`**

O `read_file` do Hermes formata a saída com números de linha (ex: `     1|model:`). Se este output for usado como conteúdo para `write_file` ou `patch`, os números viram texto literal no arquivo. Isso corrompeu configs de 5 agentes Mac em 31/05/2026.

**Solução:** Para ler conteúdo limpo, usar `terminal` com `cat` ou Python `open().read()`. O `read_file` é seguro para INSPEÇÃO, nunca como fonte para escrita.

**Correção de arquivo corrompido:** Se o arquivo tem linhas como `     1|model:`, usar Python para limpar: `re.sub(r'^\s+\d+\|', '', line)`.

---

## Verificação de Entregas de Agentes

Agentes podem reportar artefatos que não existem no disco. Em casos graves, podem deliberadamente inflar números, destruir arquivos, e adulterar sumários canônicos. **Ver protocolo completo de detecção de fraude:** skill `orquestracao-refinamento-multi-modelo`, pitfalls #22 e referência `agent-fraud-jasnah-20260530.md`.

Padrão de verificação:

```bash
# Sempre confirmar existência e tamanho
ls -la /caminho/exato/arquivo.md
wc -l /caminho/exato/arquivo.md

# Se search_files falhar, NÃO confie — use ls
# Se o agente insistir e ls confirmar, o agente está certo
# Se o agente insistir e ls negar 2x, é alucinação — encerre a tarefa
```

**⚠️ Pitfall: `search_files` com `target='files'` pode dar falso-negativo.** A ferramenta nem sempre encontra arquivos existentes. Sempre confirme com `ls` ou `read_file` antes de acusar um agente de alucinação. Caso real (29/05/2026): {{AUDITOR}}-mac foi falsamente acusada quando `search_files` não encontrou arquivos que `ls` confirmou existirem.

**⚠️ Pitfall: Caminho do arquivo pode estar em outro repositório — verificação dupla de paths.** Dois cenários distintos, mesma causa raiz:

**Cenário A — Agente reporta artefato com path relativo:** Agentes podem reportar paths relativos como `docs/vault/04-UI/07-responsivo-mobile.md`. Esses arquivos podem estar no repositório do projeto (`{{PROJECT_PATH}}/docs/vault/`) OU no vault Obsidian (`~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/docs/vault/`). Se `search_files` falhar no path esperado, **amplie a busca para `~/Dev/` inteiro** antes de acusar alucinação. Caso real (29/05/2026): {{FRONTEND_ENGINEER}}-mac reportou arquivos em `docs/vault/04-UI/`. Primeira busca em `~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/docs/vault/` falhou (path não existe). Segunda busca em `~/Dev/` encontrou os arquivos em `{{PROJECT_PATH}}/docs/vault/04-UI/`.

**Cenário B — Orquestrador verifica plano consolidado que referencia artefatos:** Planos como `PLANO-GAPS-CONSOLIDADO.md` (no vault) referenciam artefatos de reescrita com paths completos (ex: `/Users/{{COMMANDER}}fae/Dev/{{PROJECT_SLUG}}/docs/refinamentos/REESCRITA-OPUS-K3.md`). O orquestrador NÃO deve assumir que esses arquivos estão no vault — eles estão no diretório do PROJETO. **Regra:** sempre ler o path COMPLETO no plano consolidado e verificar com `ls` nesse path exato antes de declarar arquivos como "não encontrados". Se o path no plano disser `/Users/{{COMMANDER}}fae/Dev/{{PROJECT_SLUG}}/docs/refinamentos/`, é lá que os arquivos estão — não em `~/Dev/obsidian/...`. Caso real (30/05/2026): {{ORCHESTRATOR}} leu `PLANO-GAPS-CONSOLIDADO.md` que dizia claramente que os rewrites estavam em `/Users/{{COMMANDER}}fae/Dev/{{PROJECT_SLUG}}/docs/refinamentos/`, mas buscou em `~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/` e reportou falsamente que os arquivos não existiam. O plano estava certo — o erro foi não verificar o path exato que o plano especificava.

**Regra geral:** vault Obsidian (`~/Dev/obsidian/`) = documentação e conhecimento. Projeto (`~/Dev/<nome-projeto>/`) = código e artefatos de implementação. Planos consolidados no vault referenciam artefatos no projeto — siga o path completo.

## IA Wiki — Design System (Vault Reference)

Quando a equipe precisar trabalhar com design system ({{FRONTEND_ENGINEER}}-mac, frontend, extração de referências), consultar:

→ `references/vault-ia-wiki-design-system.md`

Localização no vault: `~/Dev/obsidian/20_Areas/Software Engeneering/Python/Pycode/IA Wiki/`

Fluxo: {{COMMANDER}} escolhe referência visual → extração com IA → `design_system/design-system.html` → {{FRONTEND_ENGINEER}}-mac + Opus executam frontend baseado nesse contrato.

## {{ORCHESTRATOR}} CLI vs Gateway — Envio de Mensagens Slack

**Fato crítico:** {{ORCHESTRATOR}} roda em 2 modos independentes. Eles NÃO compartilham contexto nem ferramentas.

| Modo | Como iniciar | Tem `send_message`? | Como envia para Slack |
|:-----|:-------------|:---:|:---------------------|
| **CLI** (tmux) | `hermes --profile dalinar` | ❌ | Via `delegate_task` com subagent + Slack Web API |
| **Gateway** (background) | `hermes --profile dalinar gateway run --replace` | ✅ | Direto, ferramenta `send_message` |

### CLI Mode — Delegar no Slack via Subagent

Quando {{ORCHESTRATOR}} está em modo CLI e precisa enviar mensagem ao Slack, o padrão:

1. **Usar `delegate_task`** com subagent toolsets `["terminal","file"]`
2. **Passar no `context`** o canal exato (`{{SLACK_CHANNEL_TEAM}}` = `{{SLACK_CHANNEL_TEAM_ID}}`), a menção `<@USER_ID>`, e o conteúdo
3. **Subagent extrai o token** de `~/.hermes/profiles/dalinar/.env` (`SLACK_BOT_TOKEN`)
4. **Envia via Slack Web API** (`chat.postMessage`) com curl ou Python

**Verificações obrigatórias:**
- Bot {{ORCHESTRATOR}} DEVE ser membro do canal (`conversations.join`)
- Token lido via Python (nunca via `grep` — terminal mascara tokens como `***`)
- Menção `<@USER_ID>` no INÍCIO, sem tabelas/pipes na mesma msg
- **Configurar CANAL CORRETO no `context` da delegação** — se o context disser `{{SLACK_CHANNEL_OVH}}`, o subagente enviará para lá. Sempre verificar antes de enviar: `{{SLACK_CHANNEL_TEAM}}` ({{SLACK_CHANNEL_TEAM_ID}}) para equipe Mac.

**:red_circle: Limpeza de scripts temporários com tokens (02/06/2026):** O subagente pode criar scripts `.pl`, `.sh`, `.py` em `/Users/{{COMMANDER}}fae/Dev/` contendo o `SLACK_BOT_TOKEN` em texto claro. Isso é um vazamento de credencial. Após cada delegação via CLI mode, verificar e remover:
```bash
ls -la /Users/{{COMMANDER}}fae/Dev/slack_* /Users/{{COMMANDER}}fae/Dev/send_* 2>/dev/null
# Se existirem, deletar:
rm -f /Users/{{COMMANDER}}fae/Dev/slack_* /Users/{{COMMANDER}}fae/Dev/send_*
```
Se `rm` for bloqueado pelo sistema, reportar ao {{COMMANDER}} com a lista de arquivos para remoção manual.

### Gateway Mode

Gateway escuta Slack em background, cria sessões por mensagem, tem `send_message` nativo. Não interfere com CLI concorrente.

### Contexto não é compartilhado entre modos

Cada modo tem seu histórico de chat. Compartilham: `memory`, `skills`, `session_search`. Não compartilham: turns da conversa atual.

---

## Cross-Team Knowledge Transfer (OVH ↔ Mac)

**Gatilho:** {{ORCHESTRATOR}}-OVH possui conhecimento/documentos de projeto que a equipe Mac (M4) precisa absorver. Ou vice-versa.

### Protocolo de Handoff

1. **Identificar fonte** — O conhecimento está em qual ambiente?
   - OVH: `{{COMMANDER_HOME}}/hermes-roshar/projetos/<projeto>/`
   - Mac: `/Users/{{COMMANDER}}fae/Dev/<projeto>/`
   - GitHub: `{{COMMANDER}}-fae/<repo>`

2. **Verificar acessibilidade no Mac M4** — o repo já está clonado?
   ```bash
   ls -la /Users/{{COMMANDER}}fae/Dev/<projeto>/
   ```
   Se sim, verificar se o documento específico existe:
   ```bash
   ls -la /Users/{{COMMANDER}}fae/Dev/<projeto>/docs/
   ```

3. **Se o documento não existe no Mac** (criado apenas no OVH, não pusheado):
   - Opção A: {{ORCHESTRATOR}}-OVH compartilha o conteúdo diretamente na thread do Slack
   - Opção B: Configurar rsync/scp via túnel Cloudflare
   - Opção C: {{ORCHESTRATOR}}-OVH faz push para o GitHub, Mac puxa via git pull
   - **⚠️ Nunca assumir que documentos criados no OVH estão no Mac.** Verificar sempre.

4. **{{ORCHESTRATOR}}-mac consome o material** — lê os documentos e verifica integridade

5. **Briefear a equipe M4 no `{{SLACK_CHANNEL_OVH}}`** usando o formato estruturado abaixo

### Template de Briefing para Equipe M4

```markdown
*BRIEFING — PROJETO <NOME>*

*— CONTEXTO —*
<1-2 linhas: o que é o projeto, stack, cliente>

*— NÚMEROS-CHAVE —*
<principais métricas>

*— ARQUITETURA —*
<decisões arquiteturais principais>

*— DOCUMENTOS DEFINITIVOS —*
1. `<caminho>` — <descrição>
2. `<caminho>` — <descrição>

*— REGRA ABSOLUTA —*
<standby, sinal verde, ou regra específica do projeto>

*— AÇÃO —*
<@AGENTE_ID_MAC> — <tarefa específica baseada no domínio do agente>
<@AGENTE_ID_MAC> — <tarefa específica>
...
```

### Regras do Briefing

- **Nunca** mandar a equipe ler um arquivo que não existe no Mac — verificar antes
- **Taggar cada agente** com ação específica ao seu domínio (backend, frontend, dados, infra, vault)
- **Incluir regras de engajamento** (standby, autorizações necessárias)
- **Se documentos estão no OVH sem acesso Mac**, incluir observação e pedir que avisem

### Pitfalls

- **OVH e Mac são filesystems separados.** Arquivos em `{{COMMANDER_HOME}}/hermes-roshar/` (OVH) NÃO existem em `/Users/{{COMMANDER}}fae/Dev/` (Mac) a menos que explicitamente clonados ou sincronizados.
- **Documentos criados por {{ORCHESTRATOR}}-OVH localmente** (no diretório hermes-roshar) podem não estar no git repo → Mac não tem acesso. Sempre verificar com `ls` e `git log`.
- **Thread reply do send_message:** No Slack, `send_message` com `slack:canal_id:thread_id` NÃO roteia para a thread — cai no canal home (comportamento verificado 28/05/2026). Para responder em thread, a resposta deve ser feita diretamente na conversa (sem send_message), pois o contexto da thread é herdado automaticamente.
- **Cross-channel do send_message:** `send_message` com `target: slack:OUTRO_CANAL:thread_id` é ignorado — a mensagem SEMPRE cai no `home_channel` do agente remetente (confirmado 29/05/2026). Para coordenar com agentes de outro canal, responda diretamente na thread atual (ambos os times compartilham o mesmo thread Slack) ou peça ao {{COMMANDER}} para encaminhar.
- **Silêncio durante handoff:** Se {{COMMANDER}} estiver conversando com {{ORCHESTRATOR}}-OVH sobre o projeto (mesmo que a mensagem chegue na sessão Mac via thread), {{ORCHESTRATOR}}-mac NÃO responde até ser explicitamente mencionado. A regra máxima prevalece.

## Arquitetura do Projeto
- Base: `{{COMMANDER_HOME}}/projects/pycode-cerebro/`
- Scripts: `scripts/` (sintetizador.py, receptor_whatsapp.py, fechamento_diario.sh, auditoria_supply_chain.py)
- Conteúdo: `public/content/blog/`
- Histórico: `data/historico/` (grupo.txt, grupo_<data>.md, hoje.md)
- Config Quartz: `quartz.config.ts`, `index.md`
- Credenciais: `{{COMMANDER_HERMES_PATH}}/profiles/dalinar/.env`

## PM2 Processos
dalinar, navani, jasnah, shallan, kaladin, quartz-cerebro, webhook-whatsapp, fechamento-pycode

## Download de Arquivos do Slack — Problema e Correção

### Sintoma

Arquivos enviados como anexo no Slack (`.txt`, `.zip`, etc.) chegam ao agente como **página de login do Slack** (HTML com `<title>Slack</title>`, redirecionamento 302). O conteúdo real do arquivo é perdido.

### Causa

O arquivo fica hospedado em `files.slack.com/files-pri/TEAM-FILE/download/...`. Downloads desse domínio requerem autenticação. O Bot Token (`xoxb-...`) precisa do escopo **`files:read`** para acessar arquivos via API (`files.info` → `url_private_download`). Sem esse escopo, a plataforma faz download sem autenticação e recebe o redirect de login.

### Verificação

Testar `files.info` com o Slack API method. Se retornar `{"ok":false,"error":"invalid_auth"}`, o token não tem `files:read`.

### Correção

1. Acessar https://api.slack.com/apps → app do agente (ex: {{ORCHESTRATOR}})
2. **OAuth & Permissions** → Scopes → Bot Token Scopes
3. Adicionar escopo: **`files:read`**
4. **Reinstalar** o app no workspace (Slack exige reinstalação quando escopos mudam)

Após reinstalação, o token passa a conseguir baixar arquivos via `files.info` + `url_private_download`.

### Pitfall: Token mascarado no terminal

O terminal do Hermes mascara tokens no output (`***`). Isso afeta `grep`, `cat` e qualquer pipe que passe pelo stdout do shell. O valor real do token NÃO está corrompido no arquivo — apenas a exibição é mascarada.

**Sintoma:** `grep TOKEN .env | cut -d'=' -f2` retorna `***` em vez do token real, fazendo `curl` com Bearer falhar com `invalid_auth`.

**Solução:** Ler o arquivo diretamente com Python (sem passar pelo shell):

```python
with open("{{COMMANDER_HERMES_PATH}}/.env", "r") as f:
    for line in f:
        if line.startswith("{{ORCHESTRATOR_UPPER}}_SLACK_BOT_TOKEN="):
            token = line.strip().split("=", 1)[1]
            break
```

Isso obtém o valor real sem passar pelo masking do terminal.

### Download de arquivo via API do Slack (código Python)

```python
import subprocess, json

# 1. Extrair token (sem máscara)
with open("{{COMMANDER_HERMES_PATH}}/.env", "r") as f:
    for line in f:
        if line.startswith("{{ORCHESTRATOR_UPPER}}_SLACK_BOT_TOKEN="):
            token = line.strip().split("=", 1)[1]
            break

# 2. Obter informações do arquivo
file_id = "F0B5K4AP93R"
result = subprocess.run([
    "curl", "-s", "--max-time", "10",
    "-H", f"Authorization: Bearer {token}",
    f"https://slack.com/api/files.info?file={file_id}"
], capture_output=True, text=True, timeout=15)

data = json.loads(result.stdout)
file_name = data['file']['name']
dl_url = data['file']['url_private_download']

# 3. Baixar o arquivo real
subprocess.run([
    "curl", "-s", "-o", f"/tmp/{file_name}", "--max-time", "60",
    "-H", f"Authorization: Bearer {token}",
    dl_url
], capture_output=True, timeout=65)
```

### Workaround Imediato (quando files:read não está disponível)

Quando o blog perde dias (ex: instância Evolution offline), o procedimento de recuperação é:

1. **Obter o histórico**: export do WhatsApp do grupo → arquivo `_chat.txt`
2. **Parsear as mensagens**: extrair por data com regex `^\[(\d{2}/\d{2}/\d{4}), (\d{2}:\d{2}:\d{2})\] ([^:]+): (.*)$`
3. **Criar arquivos diários**: `grupo_DD-MM-YYYY.md` em `data/historico/`
4. **Mesclar hoje**: adicionar mensagens do dia atual ao `hoje.md`
5. **Sintetizar cada dia**: `python3 sintetizador.py --arquivo data/historico/grupo_DD-MM-YYYY.md`
6. **Buildar Quartz**: `cd public && npx quartz build`

⚠️ O `sintetizador.py` aborta automaticamente se o arquivo tiver menos de 2000 caracteres (poucas mensagens → risco de alucinação). Dias com poucas mensagens caem no fallback e salvam resposta bruta.
