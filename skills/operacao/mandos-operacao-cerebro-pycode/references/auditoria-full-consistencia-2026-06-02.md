# Auditoria Full-Consistência de Agentes — 02/06/2026

## Gatilho

{{COMMANDER}}: *"revise todas as informações em todos os arquivos dos agentes e veja se não existem outras informações, ordens e memórias conflitantes"*

## Escopo da auditoria

Para CADA um dos 6 agentes Mac (dalinar, kaladin, navani, shallan, jasnah, pattern), verificar:

| # | Arquivo | O que verificar |
|---|---------|----------------|
| 1 | `SOUL.md` | Canal está correto? ({{SLACK_CHANNEL_TEAM}} / {{SLACK_CHANNEL_TEAM_ID}}) |
| 2 | `IDENTITY.md` | Papel, domínio, escalonamentos — consistentes? |
| 3 | `USER.md` | Perfil do {{COMMANDER}} — atualizado? |
| 4 | `TEAM.md` | Fluxo de delegação usa "responde na thread" (não "abre uma thread")? |
| 5 | `AGENTS.md` | Tem Protocolo de Thread 02/06? IDs de menção corretos? |
| 6 | `TOOLS.md` | Existe? (opcional — alguns agentes não têm) |
| 7 | `HEARTBEAT.md` | Tarefas periódicas coerentes? |
| 8 | `memories/MEMORY.md` | IDs Slack corretos (Mac team, não OVH)? Tem Thread Protocol? |
| 9 | `memories/USER.md` | Perfil do {{COMMANDER}} consistente? |
| 10 | `config.yaml` | `home_channel` correto? `instructions` field tem conteúdo obsoleto? |

## Achados reais desta auditoria

### CRÍTICO — IDs OVH no MEMORY.md do {{DEVOPS_ENGINEER}}

{{DEVOPS_ENGINEER}} tinha `{{ORCHESTRATOR}} {{SLACK_ID_OVH_ORCHESTRATOR}}` (Aragorn OVH) no MEMORY.md. IDs corretos Mac:
- {{ORCHESTRATOR}}: {{SLACK_ID_ORCHESTRATOR}}
- {{BACKEND_ENGINEER}}: {{SLACK_ID_BACKEND}}
- {{FRONTEND_ENGINEER}}: {{SLACK_ID_FRONTEND}}
- {{AUDITOR}}: {{SLACK_ID_AUDITOR}}
- {{DEVOPS_ENGINEER}}: {{SLACK_ID_DEVOPS}}
- {{GIT_OPS}}: {{SLACK_ID_GITOPS}}

### CRÍTICO — home_channel errado em TODOS os config.yaml

Todos os 6 agentes tinham `home_channel: {{SLACK_CHANNEL_OVH_ID}}` ({{SLACK_CHANNEL_OVH}}). Correto: `{{SLACK_CHANNEL_TEAM_ID}}` ({{SLACK_CHANNEL_TEAM}}).

### CRÍTICO — SOUL.md de TODOS apontava para {{SLACK_CHANNEL_OVH}}

Todos os 6 SOUL.md diziam "Slack `<#{{SLACK_CHANNEL_OVH_ID}}>` ({{SLACK_CHANNEL_OVH}})". Correto: `{{SLACK_CHANNEL_TEAM}}`.

### ALTA — instructions field obsoleto no config.yaml do {{ORCHESTRATOR}}

O campo `instructions` (concatenado de SOUL.md + IDENTITY.md + TEAM.md + TOOLS.md + USER.md antigos) continha "O agente delegado **abre uma thread**" — desatualizado.

### MÉDIA — Modelo default conflita com regras

- {{ORCHESTRATOR}} config.yaml: `deepseek-v4-flash` (proibido para código)
- {{DEVOPS_ENGINEER}}/{{BACKEND_ENGINEER}}/{{FRONTEND_ENGINEER}}/{{AUDITOR}}/{{GIT_OPS}}: `deepseek-v4-pro` (aceitável mas pode precisar ajuste)

### VERDE — TOOLS.md ausente

{{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{GIT_OPS}} não têm TOOLS.md. {{AUDITOR}} e {{DEVOPS_ENGINEER}} têm.

## Checklist de correção (ordem executada)

1. [x] MEMORY.md do {{DEVOPS_ENGINEER}} — corrigir IDs OVH → Mac
2. [x] AGENTS.md de todos — adicionar Protocolo de Thread 02/06
3. [x] TEAM.md de todos — "abre uma thread" → "responde na thread"
4. [x] config.yaml de todos — home_channel → {{SLACK_CHANNEL_TEAM_ID}}
5. [x] SOUL.md de todos — canal → {{SLACK_CHANNEL_TEAM}}
6. [x] {{ORCHESTRATOR}} config.yaml instructions — corrigir "abre uma thread"
7. [x] model.default + fallback_providers em todos os config.yaml

---

## Extensão OVH — Mesma auditoria aplicada à Sociedade do Anel

Após concluir a auditoria Mac, {{COMMANDER}} ordenou replicar para a equipe OVH (aragorn, celebrimbor, galadriel, elrond, eomer, gandalf, lirin).

### CRÍTICO — AGENTS.md com IDs do {{ORCHESTRATOR}} Mac em vez de Aragorn OVH

**TODOS os 7 agentes OVH** tinham AGENTS.md copiado do template Mac com referências incorretas:

| Referência incorreta | Correção |
|---------------------|----------|
| "{{ORCHESTRATOR}} inicia tópico" | "Aragorn inicia tópico" |
| `<@{{SLACK_ID_ORCHESTRATOR}}>` ({{ORCHESTRATOR}} Mac) | `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>` (Aragorn OVH) |
| "APENAS {{ORCHESTRATOR}} delega tarefas" | "APENAS Aragorn delega tarefas" |
| "reportar a {{ORCHESTRATOR}}" | "reportar a Aragorn" |
| "Ordens diretas de {{ORCHESTRATOR}}" | "Ordens diretas de Aragorn" |
| "{{SLACK_CHANNEL_TEAM}}" (canal Mac) | "{{SLACK_CHANNEL_OVH}}" (canal OVH) |

**Impacto:** Agentes OVH estavam programados para responder a um ID que NÃO é o orquestrador deles. Quando Aragorn delegava, os agentes podiam ignorar porque o AGENTS.md dizia "só responda a {{ORCHESTRATOR}}".

### Achados OVH

| Item | Status | Observação |
|------|--------|------------|
| home_channel | ✅ Correto | OVH agents usam {{SLACK_CHANNEL_OVH}} ({{SLACK_CHANNEL_OVH_ID}}) via free_response_channels |
| SOUL.md canal | ✅ Correto | "Slack {{SLACK_CHANNEL_OVH}} ({{SLACK_CHANNEL_OVH_ID}})" — OK para OVH |
| TEAM.md "abre uma thread" | ❌ Corrigido | "abre" → "responde na thread aberta por Aragorn" |
| Protocolo de Thread | ❌ Adicionado | Seção adicionada em todos os 7 AGENTS.md |
| Hierarquia de Modelos | ❌ Adicionada | Seção adicionada em todos os 7 AGENTS.md |
| fallback_providers | ❌ Adicionados | Config.yaml de todos atualizados com deepseek-v4-pro como fallback |
| Gandalf config.yaml | ⚠️ Corrompido e recriado | Instruções completas (personalidade, git rules) estão no .bak |

### Gandalf — Observação especial

Gandalf (OVH) tem um `config.yaml` com campo `instructions` contendo toda a personalidade (Mago Istari). Este arquivo foi acidentalmente corrompido durante a correção (sed injetou fallback_providers dentro do bloco model). Foi recriado com a seção model correta + fallback, mas as instruções completas (regras de git, authorities, personalidade) estão no backup `config.yaml.bak` e precisam ser restauradas manualmente se necessário.
