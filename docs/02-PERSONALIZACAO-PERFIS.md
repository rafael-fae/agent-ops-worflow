# Guia de Personalização — Agent Ops Workflow

> Guia completo para personalizar o Agent Ops Workflow para seu time — nomes
> de agentes, funções, hierarquia de motores, configuração Slack, adaptação de
> templates e planejamento de migração. Cada equipe é diferente; este guia ajuda
> você a fazer o workflow seu.

---

## Sumário

1. [Visão Geral: A Filosofia da Personalização](#visão-geral-a-filosofia-da-personalização)
2. [Escolhendo Nomes de Agentes](#escolhendo-nomes-de-agentes)
3. [Definindo Funções](#definindo-funções)
4. [Hierarquia de Motores LLM](#hierarquia-de-motores-llm)
5. [Configurando Canais Slack](#configurando-canais-slack)
6. [Adaptando Templates](#adaptando-templates)
7. [Exemplo Completo — Time Nova](#exemplo-completo--time-nova)
8. [Checklist de Migração](#checklist-de-migração)

---

## Visão Geral: A Filosofia da Personalização

O Agent Ops Workflow é intencionalmente genérico. Templates usam sintaxe
`__PLACEHOLDER__`, skills usam sintaxe `{{PLACEHOLDER}}`, e ambos podem ser
adaptados a qualquer estrutura de equipe. O workflow não assume o tamanho da
sua equipe, sua convenção de nomenclatura, seus modelos de IA preferidos ou
sua topologia de canais Slack.

Há **uma regra de ouro da personalização**:

> Mude tudo o que torna o workflow seu. Não mude nada que quebre o protocolo.

Isso significa:
- Nomes de agentes, temas de equipe e canais Slack são seus para definir —
  seja criativo.
- O ciclo de 6 fases (Planejar → Aprovar → Delegar → Executar → Auditar → Reportar)
  permanece o mesmo.
- O formato de @menção, regras de thread e regra do silêncio permanecem os mesmos.
- A estrutura de template (PLANO.md, TASK.md, INDICE.md) permanece a mesma.
- A convenção `{{PLACEHOLDER}}` / `__PLACEHOLDER__` permanece a mesma.

---

## Escolhendo Nomes de Agentes

Nomes de agentes são a camada de identidade do seu workflow. Bons nomes são:
- **Distintos** — Dois agentes não soam parecidos (evita confusão)
- **Memoráveis** — Fáceis de digitar em @menções do Slack
- **Apropriados à função** — O nome sugere a função do agente
- **Consistentes** — Seguem o mesmo tema entre todos os agentes

### Ideias de Temas

#### Elementos (Terra, Fogo, Água, Ar)

| Função | Nome do Elemento | Justificativa |
|--------|------------------|---------------|
| Orquestrador | Éter | O quinto elemento — une tudo |
| Backend | Terra | Fundação, estável, confiável |
| Frontend | Ígnea | Fogo — visível, dinâmico, interativo |
| DevOps | Vento | Infraestrutura invisível, sempre em movimento |
| Auditor | Água | Clara, reflexiva, vê através das coisas |
| GitOps | Ferro | Ferramentas, mecânica, controle de versão |

#### Gemas e Minerais

| Função | Nome da Gema | Justificativa |
|--------|-------------|---------------|
| Orquestrador | Diamante | Mais duro, mais claro, central |
| Backend | Ônix | Escuro, sólido, fundação |
| Frontend | Rubi | Brilhante, visível, envolvente |
| DevOps | Quartzo | Preciso, cronometragem, infraestrutura |
| Auditor | Safira | Clara, analítica, valiosa |
| GitOps | Obsidiana | Afiada, tipo ferramenta, eficiente |

#### Corpos Celestes

| Função | Nome Celeste | Justificativa |
|--------|-------------|---------------|
| Orquestrador | Sol | O centro do sistema |
| Backend | Terra | Solo, dados, persistência |
| Frontend | Lua | Visível, reflete luz, interface |
| DevOps | Nova | Mudança explosiva, eventos de infraestrutura |
| Auditor | Estrela | Constante, observadora confiável |
| GitOps | Cometa | Rápido, órbita previsível, ferramenta |

#### Figuras Mitológicas

| Função | Nome Mitológico | Justificativa |
|--------|----------------|---------------|
| Orquestrador | Atena | Deusa da sabedoria, estratégia |
| Backend | Hefesto | Deus da forja, artesanato, construção |
| Frontend | Apolo | Deus das artes, aparência, interface |
| DevOps | Hermes | Mensageiro, viagem, infraestrutura |
| Auditor | Têmis | Deusa da justiça, ordem |
| GitOps | Clio | Musa da história, registros, versionamento |

#### Mitologia Nórdica

| Função | Nome Nórdico | Justificativa |
|--------|-------------|---------------|
| Orquestrador | Odin | Pai de todos, vigilante, sabedoria |
| Backend | Thor | Força, proteção, fundação |
| Frontend | Freya | Beleza, amor, artes visíveis |
| DevOps | Heimdall | Guardião, vigia, infraestrutura |
| Auditor | Forseti | Deus da justiça, arbitragem |
| GitOps | Mimir | Guardião do conhecimento, registros |

#### Máquinas / Robótica

| Função | Nome de Máquina | Justificativa |
|--------|----------------|---------------|
| Orquestrador | Prime | Líder, primário, central |
| Backend | Core | Fundação, processamento, armazenamento |
| Frontend | Pixel | Tela, renderização, interface |
| DevOps | Relay | Roteamento de sinal, infraestrutura |
| Auditor | Sensor | Detecção, verificação, monitoramento |
| GitOps | Gear | Mecanismo, precisão, controle de versão |

#### Conceitos de Computação

| Função | Nome do Conceito | Justificativa |
|--------|-----------------|---------------|
| Orquestrador | Kernel | Núcleo do sistema operacional |
| Backend | Cache | Rápido, persistente, fundamental |
| Frontend | Render | Tela, visualização, saída |
| DevOps | Proxy | Roteamento, segurança, infraestrutura |
| Auditor | Checksum | Verificação, integridade, validação |
| GitOps | Rebase | Operação git, gerenciamento de histórico |

### Regras de Nomenclatura

1. **Um nome por agente.** Nunca reutilize um nome entre funções ou ambientes.
2. **Sem espaços em nomes de exibição do Slack.** Use `nova-orch` não `Nova Orch`.
3. **Mantenha AGENTS.md alinhado com Slack.** Se renomear um bot Slack, atualize AGENTS.md
   imediatamente.
4. **Referência cruzada consistente.** Se o orquestrador é `Aether` no Mac
   e `Diamond` no servidor, documente ambos em AGENTS.md com rótulos de ambiente.

---

## Definindo Funções

O Agent Ops Workflow define **6 funções padrão**. Você pode adicionar mais, mas
estas são o mínimo para uma operação multi-agente saudável.

### Definições de Funções Padrão

| Função | Tag | Responsabilidade | Posts no Slack | Perfil Hermes Necessário? |
|--------|-----|-----------------|----------------|---------------------------|
| **Comandante** | Humano | Revisa planos, dá aprovação final, emite lockdowns | Sim — nível superior apenas | Não (humano) |
| **Orquestrador** | `@aria` | Cria planos, delega tarefas, audita trabalho, produz relatórios | Sim — nível superior + threads de auditoria | Sim |
| **Engenheiro Backend** | `@terra` | Executa tarefas de backend/código, commita, reporta em threads | Não — apenas respostas em thread | Sim |
| **Engenheiro Frontend** | `@ignis` | Executa tarefas de frontend/UI (tipicamente usa Opus para visão) | Não — apenas respostas em thread | Sim |
| **Engenheiro DevOps** | `@ventus` | Infraestrutura, deploy, CI/CD, manutenção de servidor | Não — apenas respostas em thread | Sim |
| **Auditor** | `@aqua` | Verifica tarefas concluídas, verifica commits, aprova | Não — apenas respostas em thread | Opcional (orquestrador pode auditar) |
| **GitOps** | `@ferrum` | Operações git, controle de versão, sincronização de vault | Não — apenas respostas em thread | Opcional (agente utilitário) |

### Adicionando ou Removendo Funções

**Para adicionar uma função (ex.: Cientista de Dados, QA, Gerente de Produto):**

1. Defina as responsabilidades da função em uma nova linha na tabela acima.
2. Crie um usuário Slack para a função (se baseado em bot) ou atribua um humano.
3. Adicione a função ao AGENTS.md.
4. Atualize templates para referenciar a nova função em mensagens de delegação.
5. Documente quaisquer restrições de motor específicas da função.

**Para remover uma função (ex.: mesclando Auditor no Orquestrador):**

1. Atualize AGENTS.md — remova a linha da função.
2. Reassign quaisquer tarefas pendentes que referenciem a função.
3. Atualize templates de delegação para remover instruções específicas da função.
4. Atualize a seção EXEMPLO COMPLETO neste documento.

### Melhores Práticas de Atribuição de Funções

| Tamanho da Equipe | Configuração Recomendada |
|-------------------|------------------------|
| 1 pessoa (solo) | Comandante + Orquestrador (mesmo humano). Um agente de código faz tudo. Auditor é o orquestrador. |
| 2-3 pessoas | Comandante (humano) + Orquestrador (bot) + 1-2 agentes de código. Orquestrador também audita. |
| 4-6 pessoas | Comandante + Orquestrador + Backend + Frontend + DevOps + Auditor. Separação total de responsabilidades. |
| 7+ pessoas | Comandante + Orquestrador + 2 Backend + 2 Frontend + DevOps + Auditor + GitOps. Múltiplas especializações. |

### Funções Multi-Máquina / Multi-Ambiente

Se você executa agentes em múltiplas máquinas (ex.: Mac local + servidor cloud),
cada ambiente recebe seu próprio conjunto de instâncias de função. Documente o
mapeamento:

| Função | Local (Mac) | Cloud (Servidor) |
|--------|-------------|------------------|
| Orquestrador | `@aria-mac` | `@aria-server` |
| Backend | `@terra-mac` | `@terra-server` |
| ... | ... | ... |

Os dois orquestradores coordenam como iguais — sem hierarquia entre ambientes.
Cada orquestrador gerencia apenas os agentes de seu próprio ambiente.

---

## Hierarquia de Motores LLM

O workflow suporta múltiplos modelos de IA (motores) com uma hierarquia de
prioridade estrita. O motor padrão para tarefas de código é Gemini 3.1 Pro.
Outros motores são atribuídos com base nos requisitos da tarefa.

### Hierarquia Padrão de Motores

| Prioridade | Motor | Caso de Uso Principal | Quando Usar |
|:----------:|-------|----------------------|-------------|
| **1** | Gemini 3.1 Pro | TODAS as tarefas padrão de código, configuração, documentação | Padrão — use para tudo a menos que uma exceção específica se aplique |
| **2** | Opus 4.7 (Claude) | Tarefas de UI/visão/design, auditorias complexas, migrações de dados cross-DB | Trabalho frontend, operações críticas de dados, auditoria de código de terceiros |
| **3** | OpenCode Go / GLM 5.1 | Exploração rápida, operações de arquivo, scripts simples | Tarefas pequenas, prototipagem rápida, exploração |
| — | DeepSeek V4 / V4 Pro | **PROIBIDO** sem ordem explícita do Comandante | Nunca — apenas se o Comandante autorizar especificamente |

### Heurística de Seleção de Motor

Use esta árvore de decisão ao atribuir motores a tarefas:

```
A tarefa é puramente mecânica (mudança de config, mover arquivos, edição simples)?
  → SIM → Gemini 3.1 Pro (menor custo, qualidade suficiente)
  → NÃO → ↓

A tarefa envolve migração de dados com chaves estrangeiras cross-DB?
  → SIM → Considere Opus 4.7 (risco de perda de dados justifica o custo)
  → NÃO → ↓

É uma tarefa de frontend/UI/design (CSS, layout, componentes visuais)?
  → SIM → Opus 4.7 OBRIGATÓRIO (Engenheiro Frontend)
  → NÃO → ↓

É uma auditoria do trabalho de outro agente?
  → SIM → Opus 4.7 recomendado (pega erros sutis melhor)
  → NÃO → ↓

A tarefa é simples, bem definida, arquivo único, sem ações irreversíveis?
  → SIM → Gemini 3.1 Pro (suficiente para o trabalho)
  → NÃO → ↓

Padrão para Gemini 3.1 Pro. Escale para Opus apenas se Gemini falhar.
```

### Formatos de Restrição de Motor

Ao delegar uma tarefa, inclua a obrigação do motor na mensagem Slack:

```markdown
**Motor:** Gemini 3.1 Pro (PADRÃO)
```

```markdown
**Motor:** Opus 4.7 (OBRIGATÓRIO — tarefa de UI/visão)
```

```markdown
**ORDEM ABSOLUTA — Motor:** Gemini 3.1 Pro.
NÃO troque. Se atingir limites de taxa, divida em subtarefas.
```

### Protocolo de Fallback de Motor

Se o motor designado falhar (limite de taxa, erro de API, timeout):

1. **Divida a tarefa** em subtarefas menores e tente novamente com o mesmo motor.
2. Se a divisão não resolver o problema, **pare e reporte** ao orquestrador.
3. O orquestrador pode escalar para o Comandante para autorização de troca de motor.
4. **Nunca troque de motor sem autorização.** Isso é uma violação de protocolo.

### Múltiplos Motores na Mesma Tarefa

Para tarefas complexas, o orquestrador pode designar motores diferentes para
passos diferentes. Por exemplo:

```
Tarefa: Migrar dados de usuário do sistema legado
  Passo 1 (extração de dados): Opus 4.7 — SQL complexo com FKs cross-DB
  Passo 2 (transformação): Gemini 3.1 Pro — ETL mecânico
  Passo 3 (verificação): Opus 4.7 — auditar integridade dos dados
```

Documente atribuições de múltiplos motores na seção de Instruções do arquivo
da tarefa.

---

## Configurando Canais Slack

O Slack é a camada de comunicação para o Agent Ops Workflow. Você pode
configurar um canal (simples) ou múltiplos canais (avançado). Ambas as
configurações funcionam com as mesmas regras de protocolo.

### Canal Único (Recomendado para Equipes de 1-5)

```
Canal: #agent-ops-{nomedotime}
Propósito: Planejamento, delegação, atualizações de execução, resultados de auditoria, relatórios
```

Toda a comunicação acontece neste único canal. Threads mantêm conversas de
tarefas isoladas. Esta é a configuração mais simples e funciona bem para
equipes pequenas.

### Configuração Multicanal (Equipes de 6+)

| Canal | Propósito | Quem Publica |
|-------|-----------|--------------|
| `#agent-ops-{nomedotime}` | Planejamento diário, aprovações, relatórios | Comandante, Orquestrador |
| `#{nomedotime}-execucao` | Mensagens de delegação e threads de execução | Orquestrador, Agentes |
| `#{nomedotime}-auditoria` | Resultados de auditoria e verificações cruzadas | Orquestrador, Auditor |
| `#{nomedotime}-alertas` | Sinais de lockdown, erros críticos | Apenas Comandante |

### Convenção de Nomenclatura de Canais

```yaml
#agent-ops-{nomedotime}           # Operações principais
#agent-ops-{nomedotime}-exec      # Threads de execução
#agent-ops-{nomedotime}-audit     # Canal de auditoria
#agent-ops-{nomedotime}-alert     # Alertas de emergência
```

### Criando um App Slack para Seu Time

Cada agente que precisa enviar/receber mensagens Slack requer um app Slack (bot).
Aqui está o processo passo a passo:

#### Passo 1: Crie o App

1. Acesse https://api.slack.com/apps
2. Clique em **Create New App** → **From Scratch**
3. Dê um nome (ex.: `Time Nova Agent Ops`) e selecione seu workspace
4. Clique em **Create App**

#### Passo 2: Configure os Escopos do Token Bot

Navegue até **OAuth & Permissions** → **Scopes** → **Bot Token Scopes**.
Adicione estes escopos:

| Escopo | Propósito |
|--------|-----------|
| `channels:history` | Ler histórico do canal (encontrar threads) |
| `channels:read` | Visualizar informações do canal e listas de membros |
| `chat:write` | Enviar mensagens e postar em threads |
| `reactions:read` | Ler reações de emoji (sinais de auditoria) |
| `users:read` | Ler informações do usuário (resolver @menções) |

#### Passo 3: Instale o App

1. Em **OAuth & Permissions**, clique em **Install to Workspace**
2. Revise as permissões e clique em **Allow**
3. Copie o **Bot User OAuth Token** (`xoxb-...`)

#### Passo 4: Obtenha o Token de Nível de App

1. Vá em **Basic Information** → **App-Level Tokens** → **Generate Token**
2. Adicione escopos: `connections:write`, `authorizations:read`
3. Nomeie (ex.: `ws-token`) e copie o token resultante (`xapp-...`)

Este token habilita o Socket Mode, que permite ao agente conectar-se ao Slack
sem expor um endpoint HTTP público.

#### Passo 5: Encontre Seus IDs do Workspace

**ID do Canal:**
```bash
# Clique com botão direito no nome do canal → Copy Link
# Extraia da URL: https://workspace.slack.com/archives/C0123456789
```

**IDs de Usuário para seus agentes:**
```bash
# Método 1: Interface Slack
# Clique no perfil do usuário → More → Copy member ID

# Método 2: API Slack
curl -H "Authorization: Bearer *** \
  https://slack.com/api/users.list | jq '.members[] | {name: .name, id: .id}'
```

#### Passo 6: Configure o Hermes

Adicione à sua configuração Hermes ou ambiente:

```yaml
# ~/.hermes/config.yaml (específico do perfil)
profiles:
  aria:
    slack:
      enabled: true
      bot_token: xoxb-...
      app_token: xapp-...
      home_channel: C0123456789
```

Ou defina variáveis de ambiente:

```bash
export SLACK_BOT_TOKEN=xoxb-...
export SLACK_APP_TOKEN=xapp-...
export SLACK_HOME_CHANNEL=C0123456789
```

#### Passo 7: Convide o Bot para os Canais

Em cada canal que o bot precisa operar:

```
/invite @TimeNovaBot
```

O bot não pode ler ou escrever em canais para os quais não foi convidado.

#### Passo 8: Crie AGENTS.md

Documente o mapeamento Slack do seu time na raiz do projeto:

```markdown
# Registro de Agentes — Time Nova

| Nome | Função | ID do Slack | Motor Padrão |
|------|--------|-------------|--------------|
| Aria | Orquestrador | <@U0123456789> | Gemini 3.1 Pro |
| Terra | Backend | <@U9876543210> | Gemini 3.1 Pro |
| Ignea | Frontend | <@U5555555555> | Opus 4.7 |
| Vento | DevOps | <@U4444444444> | Gemini 3.1 Pro |
| Água | Auditor | <@U3333333333> | Opus 4.7 |
```

---

## Adaptando Templates

Templates em `agent-ops-workflow/templates/` usam sintaxe `__PLACEHOLDER__`.
Quando você executa `setup-workflow.sh`, eles são copiados para o diretório
`planejamento-diario/TEMPLATES/` do seu projeto. Você pode (e deve) personalizá-los.

### O que Personalizar

#### PLANO.md.tpl

| Seção | O que Mudar | Exemplo |
|-------|-------------|---------|
| Cabeçalho | Nome do time, nome do Comandante | `Time Nova`, `Comandante Alex` |
| Recursos | URLs e repositórios reais do seu projeto | GitHub, CI/CD, staging |
| Waves | Nomes e horários das waves | `Wave 1 — Manhã (8-12)` |
| Regras | Convenções específicas do time | Idioma, max threads, regras de auditoria |
| Métricas | Métricas alvo do seu time | Cobertura de testes, frequência de deploy |

#### TASK.md.tpl

| Seção | O que Mudar | Exemplo |
|-------|-------------|---------|
| Leitura Obrigatória | Links de doc do seu projeto | PRD, Blueprint, docs de API |
| Restrições | Restrições específicas do time | `NUNCA modificar config/producao/` |
| Checklist | Itens de verificação padrão | `Testes unitarios passaram` |
| Conclusão | Campos personalizados se necessário | Adicione `Ticket Jira` se usar Jira |

#### INDICE.md.tpl

| Seção | O que Mudar | Exemplo |
|-------|-------------|---------|
| Cabeçalho | Nome do seu projeto | `Projeto Atlas` |
| Legenda | Símbolos personalizados se necessário | Mantenha padrão ✅ 👁 ⬜ |
| Seção de progresso | Nomes de wave personalizados | Iguale às waves do seu PLANO.md |

### Personalizando Regras de Execução

A seção de regras de execução no PLANO.md é a parte mais específica do time no
template. Aqui estão exemplos para diferentes tipos de equipe:

**Equipe pequena (2-3 pessoas):**
```markdown
## Regras de Execução

1. **Motor padrão:** Gemini 3.1 Pro
2. **Trabalhe em branches** — nunca commit diretamente na main
3. **Idioma:** Português (Brasil) para todos os docs e commits
4. **Máximo de threads concorrentes:** 2 agentes
5. **Auditoria:** Orquestrador audita todas as tarefas concluídas
6. **Estilo de commit:** `tipo(escopo): descrição` (ex.: `feat(api): adicionar endpoint login`)
```

**Equipe completa (6+ pessoas):**
```markdown
## Regras de Execução

1. **Motor padrão:** Gemini 3.1 Pro (TODO código)
2. **Tarefas frontend:** Opus 4.7 OBRIGATÓRIO (atribuído ao Engenheiro Frontend)
3. **Migrações de dados:** Opus 4.7 recomendado (FKs cross-DB)
4. **NUNCA modifique config de produção** — trabalhe em cópias
5. **Repositório:** Commit apenas conteúdo sanitizado; segredos vão em .env
6. **Idioma:** Português (Brasil)
7. **Máximo de threads concorrentes:** 4 agentes
8. **Auditoria:** Toda tarefa concluída DEVE ser revisada por um agente diferente
9. **Lockdown:** "LOCKDOWN" do Comandante congela todas as operações imediatamente
```

### Troca de Idioma

Os templates padrão estão em Português (pt-BR). Para trocar para Inglês (US):

1. Defina `IDIOMA="en-US"` durante `setup-workflow.sh`
2. Edite `TEMPLATES/PLANO.md` — traduza cabeçalhos de seção, regras e rótulos
3. Edite `TEMPLATES/TASK.md` — traduza cabeçalhos de seção e instruções
4. Edite `TEMPLATES/INDICE.md` — traduza cabeçalho e legenda

Traduções principais para cabeçalhos de seção:

| Português | Inglês |
|-----------|--------|
| Plano de Execução | Execution Plan |
| Recursos do Projeto | Project Resources |
| Resumo | Summary |
| Waves | Waves |
| Dependencias | Dependencies |
| Regras da Execucao | Execution Rules |
| Ao final do dia | End of Day Checklist |
| Metricas-alvo | Target Metrics |
| Leitura Obrigatoria | Required Reading |
| Contexto | Context |
| Instrucoes | Instructions |
| Checklist | Checklist |
| Restricoes | Constraints |
| Arquivos relevantes | Relevant Files |
| Conclusao | Conclusion |

---

## Exemplo Completo — Time Nova

Este é um exemplo completo de um time personalizado. O Time Nova usa o tema
Elementos e executa uma configuração completa de 6 funções.

### Visão Geral do Time

| Atributo | Valor |
|----------|-------|
| Nome do Time | Time Nova |
| Projeto | Projeto Atlas |
| Comandante | Alex (humano) |
| Orquestrador | Aria (bot) |
| Canal Slack | `#agent-ops-nova` |
| Motor Padrão | Gemini 3.1 Pro |
| Idioma da Documentação | Português (Brasil) |

### Atribuições de Funções

| Nome | Função | Slack @ | ID do Slack | Motor Padrão | Especialidade |
|------|--------|---------|-------------|--------------|---------------|
| Alex | Comandante | `@alex` | Humano | N/A (humano) | Produto, estratégia |
| Aria | Orquestrador | `@aria` | `U0AA01A1A1A` | Gemini 3.1 Pro | Planejamento, delegação, auditoria |
| Terra | Backend | `@terra` | `U0BB02B2B2B` | Gemini 3.1 Pro | Python, Django, APIs |
| Ignea | Frontend | `@ignea` | `U0CC03C3C3C` | Opus 4.7 | React, CSS, UI |
| Vento | DevOps | `@vento` | `U0DD04D4D4D` | Gemini 3.1 Pro | Docker, CI/CD, OVH |
| Água | Auditor | `@agua` | `U0EE05E5E5E` | Opus 4.7 | Revisão de código, segurança |

### AGENTS.md

```markdown
# Registro de Agentes — Time Nova

| Nome | Função | ID do Slack | Motor Padrão |
|------|--------|-------------|--------------|
| Aria | Orquestrador | <@U0AA01A1A1A> | Gemini 3.1 Pro |
| Terra | Backend | <@U0BB02B2B2B> | Gemini 3.1 Pro |
| Ignea | Frontend | <@U0CC03C3C3C> | Opus 4.7 |
| Vento | DevOps | <@U0DD04D4D4D> | Gemini 3.1 Pro |
| Água | Auditor | <@U0EE05E5E5E> | Opus 4.7 |

**Comandante:** Alex (humano) — revisa planos, dá aprovação, emite lockdowns.
**Orquestrador:** Aria — cria planos, delega, audita, reporta.
```

### Configuração Slack

- **Canal principal:** `#agent-ops-nova` (ID: `C0AA01A1A1A`)
- **Token bot:** `xoxb-...` (armazenado na config Hermes, nunca no git)
- **Token app:** `xapp-...` (Socket Mode)
- **Todos os agentes convidados para:** `#agent-ops-nova`

### Personalizações de Template

No `PLANO.md.tpl` (Português), a seção de regras de execução:

```markdown
## Regras de Execução

1. **Motor padrão:** Gemini 3.1 Pro
2. **Tarefas frontend (UI/CSS/visão):** Opus 4.7 OBRIGATÓRIO — atribuído a @ignea
3. **Migrações de dados com FKs cross-DB:** Opus 4.7 recomendado
4. **NUNCA modifique arquivos originais** — trabalhe em cópias ou branches
5. **Commit apenas conteúdo sanitizado** — segredos ficam em .env
6. **Idioma:** Português (Brasil) para toda documentação e commits
7. **Máximo de threads concorrentes:** 3 agentes
8. **Auditoria:** TODA tarefa concluída deve ser auditada por @agua antes de fechar
9. **Lockdown:** "LOCKDOWN" / "sinal vermelho" do Comandante congela todas as ops
```

### Mapa de Placeholders

```markdown
# Mapa de Placeholders — Time Nova / Projeto Atlas

{{PROJECT_PATH}} → /home/alex/projeto-atlas
{{PROJECT_NAME}} → Projeto Atlas
{{TEAM_NAME}} → Time Nova
{{COMMANDER}} → Alex
{{ORCHESTRATOR}} → Aria
{{BACKEND_ENGINEER}} → Terra
{{FRONTEND_ENGINEER}} → Ignea
{{DEVOPS_ENGINEER}} → Vento
{{AUDITOR}} → Água
{{SLACK_CHANNEL_TEAM}} → #agent-ops-nova
{{SLACK_CHANNEL_TEAM_ID}} → C0AA01A1A1A
{{SLACK_ID_ORCHESTRATOR}} → U0AA01A1A1A
{{SLACK_ID_BACKEND}} → U0BB02B2B2B
{{SLACK_ID_FRONTEND}} → U0CC03C3C3C
{{SLACK_ID_AUDITOR}} → U0EE05E5E5E
{{SLACK_ID_DEVOPS}} → U0DD04D4D4D
```

### Um Dia na Vida do Time Nova

**08:00** — Aria (orquestrador) verifica o relatório de ontem, cria `PLANO.md`
com 3 waves e 6 tarefas.

**08:15** — Alex (comandante) revisa o plano, aprova.

**08:20** — Aria delega em `#agent-ops-nova`:
```
<@U0BB02B2B2B> Tarefa task_01: Refatorar modelo de usuário
**Motor:** Gemini 3.1 Pro (PADRÃO)
...
```

**08:25** — Terra confirma, começa o trabalho.

**09:00** — Terra conclui task_01, commita, faz push, reporta na thread.

**09:05** — Aria verifica o commit, lê o diff, atualiza PLANO.md e
INDICE.md. Reporta: "✅ Auditoria aprovada para task_01."

**09:10** — Aria delega task_02 (componente UI) para Ignea com obrigação Opus.

...repete ao longo do dia...

**17:00** — Aria compila relatório diário, publica no canal, commita todos os registros.

---

## Checklist de Migração

Use este checklist ao migrar o Agent Ops Workflow para um novo time ou
ambiente. Abrange tudo, de nomes a Slack e verificação.

### Fase 1: Fundação (Antes do Setup)

- [ ] **Escolha um nome de time** (ex.: `Time Nova`)
- [ ] **Escolha nomes de agentes** usando um tema deste guia
- [ ] **Decida as funções** — mínimo: Comandante + Orquestrador + 1 agente de código
- [ ] **Decida a topologia Slack** — canal único ou multicanal
- [ ] **Decida os motores de IA** — Gemini padrão, com exceções Opus
- [ ] **Escolha o idioma da documentação** — Português (pt-BR) ou Inglês (US)
- [ ] **Crie o mapa de placeholders** — liste todas as substituições `{{PLACEHOLDER}}`

### Fase 2: Setup

- [ ] **Clone agent-ops-workflow** ou copie o repositório template
- [ ] **Execute setup-workflow.sh** com as informações do seu time/projeto
- [ ] **Crie app(s) Slack** para seus agentes
- [ ] **Configure escopos do token bot** (channels:history, chat:write, etc.)
- [ ] **Instale app(s) Slack** no seu workspace
- [ ] **Copie tokens bot** e tokens de nível de app
- [ ] **Encontre e documente IDs de canal** (prefixo C)
- [ ] **Encontre e documente IDs de usuário** (prefixo U)

### Fase 3: Adaptação de Templates

- [ ] **Traduza templates** para seu idioma (se não for português)
- [ ] **Personalize PLANO.md** — regras, recursos, nomes de wave
- [ ] **Personalize TASK.md** — restrições, itens de checklist
- [ ] **Personalize INDICE.md** — cabeçalho, seção de progresso
- [ ] **Defina hierarquia de motor** na seção de regras do PLANO.md

### Fase 4: Adaptação de Skills

- [ ] **Copie skills sanitizadas** de `files/skills/sanitized/` para seu projeto
- [ ] **Execute substituição de placeholders** (script sed ou manual)
- [ ] **Verifique se não restam placeholders** — `grep -rn "{{\" skills/`
- [ ] **Carregue skills essenciais** via `hermes skill_manage add`
- [ ] **Verifique se skills carregam corretamente** — `hermes skill_manage list`

### Fase 5: Configuração

- [ ] **Crie AGENTS.md** com todas as funções, IDs Slack, motores
- [ ] **Crie PLACEHOLDER-MAP.md** para referência futura
- [ ] **Configure perfis Hermes** para cada agente (ou um multi-função)
- [ ] **Configure Slack** no config.yaml do Hermes ou variáveis de ambiente
- [ ] **Convide bots** para todos os canais que precisam operar
- [ ] **Teste conectividade Slack** — envie uma mensagem de teste

### Fase 6: Validação

- [ ] **Execute validate-workflow.sh** — verifique estrutura e consistência
- [ ] **Verifique manualmente o PLANO.md de hoje** — parece correto?
- [ ] **Crie uma tarefa de teste** — percorra todas as 6 fases
- [ ] **Verifique delegação Slack** — @menção funciona, thread criada
- [ ] **Verifique fluxo de auditoria** — verificação de commit, atualizações INDICE/PLANO
- [ ] **Verifique fluxo de relatório** — tabela consolidada, commit final
- [ ] **Teste protocolo de lockdown** — "LOCKDOWN" congela todos os agentes?
- [ ] **Agende cron diário** — `gerar-plano-diario.sh` às 5 AM

### Fase 7: Entrar em Produção

- [ ] **Anuncie para a equipe** — compartilhe AGENTS.md e regras da sessão
- [ ] **Primeiro dia real** — execute o ciclo completo de 6 fases
- [ ] **Retrospectiva de fim de dia** — o que quebrou? O que foi confuso?
- [ ] **Atualize docs** com base nas lições aprendidas
- [ ] **Defina revisão trimestral** de skills, templates e funções

### Solução de Problemas de Migração

| Problema | Causa Provável | Solução |
|----------|---------------|----------|
| Bot Slack não responde | Bot não convidado ao canal | `/invite @SeuBot` |
| @menção Slack não funciona | Usando nome de exibição em vez de `<@USER_ID>` | Use formato `<@U...>` |
| `hermes skill_view` não mostra nada | Caminho para SKILL.md incorreto | Verifique se o arquivo existe |
| Placeholders de template não substituídos | Executando setup antigo sem personalização | Edite arquivos TEMPLATES/ diretamente |
| Agente usa motor errado | Motor não especificado na delegação | Adicione "ORDEM ABSOLUTA — Motor:" à mensagem |
| Contador do INDICE.md sempre errado | Não atualizado após cada auditoria | Atualize imediatamente — torne um hábito |
| Cron não gera plano | Variáveis de ambiente ausentes no crontab | Exporte WORKFLOW_TEAM_NAME, etc. |

---

> Personalização é o que torna o Agent Ops Workflow seu. Reserve um tempo para
> escolher nomes que ressoem, configurar canais que se encaixem no seu estilo
> de comunicação e adaptar templates às convenções do seu time. O protocolo
> permanece o mesmo; a identidade é sua para construir.
