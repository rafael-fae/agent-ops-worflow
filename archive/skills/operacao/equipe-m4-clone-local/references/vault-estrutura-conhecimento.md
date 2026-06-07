# Vault Obsidian — Estrutura de Conhecimento (P.A.R.A.)

**Path oficial:** `~/Dev/obsidian/` (clone git, **não** `~/Obsidian/` que é iCloud symlink)
**Padrão estabelecido por:** {{COMMANDER}} — 28/05/2026
**Versão:** Mac + OVH sincronizados via git ({{GIT_OPS}} gerencia push/pull)

---

## Estrutura P.A.R.A.

| Pasta | Conteúdo | Para quem |
|-------|----------|-----------|
| `00_Inbox/` | Captura bruta de ideias, notas soltas | **{{FRONTEND_ENGINEER}}** (referências de design) |
| `10_Projects/` | Projetos ativos: Dontus, {{PROJECT_SLUG}}, Ortodontia, Levantamento | **{{BACKEND_ENGINEER}}** (PRDs, specs, modelos) |
| `20_Areas/` | Responsabilidades contínuas: Software Engineering, Faculdade, Oeste Odontologia | **{{AUDITOR}}** (auditorias, regras de negócio) |
| `30_Resources/` | Conhecimento reutilizável: Templates, Snippets de Código, Wikiosx | **{{DEVOPS_ENGINEER}}** (receitas de infra, DevOps) |
| `90_Archives/` | Projetos concluídos/arquivados | {{ORCHESTRATOR}} (visão geral) |
| `99_System/` | Logs do {{GIT_OPS}}, ativações de agentes, decisões do sistema | **{{ORCHESTRATOR}}** (logs, decisões) |

---

## Domínios por Agente

### {{BACKEND_ENGINEER}} (Backend/Arquitetura)
- `10_Projects/{{PROJECT_SLUG}}/` — docs de RE, PRD, blueprint arquitetural
- `30_Resources/Templates/` — templates de backend, snippets Python/Django
- `30_Resources/Snippets de Código/` — padrões de código reutilizáveis

### {{AUDITOR}} (Produto/Regras de Negócio)
- `20_Areas/Oeste Odontologia/` — domínio do cliente, regras de negócio
- `10_Projects/{{PROJECT_SLUG}}/` — state machines, PRD, decisões registradas
- `20_Areas/Software Engineering/` — metodologias, frameworks de produto

### {{DEVOPS_ENGINEER}} (Infra/DevOps)
- `30_Resources/Templates/` — templates de deploy, Docker, CI/CD
- `30_Resources/Snippets de Código/` — scripts de infra, automação
- `30_Resources/Wikiosx/` — referências técnicas diversas
- `10_Projects/{{PROJECT_SLUG}}/docs/vault/05-Infra/` — blueprint de infra

### {{FRONTEND_ENGINEER}} (Frontend/UI)
- `00_Inbox/` — referências de design, inspirações
- `10_Projects/{{PROJECT_SLUG}}/docs/vault/04-UI/` — design system, componentes
- `30_Resources/Templates/` — templates de frontend, componentes reutilizáveis

### {{ORCHESTRATOR}} (Orquestração)
- `99_System/` — logs, decisões, registros de ativação
- `10_Projects/` — visão geral de todos os projetos
- `20_Areas/` — entendimento do domínio do cliente

### {{GIT_OPS}} (Vault/Git)
- `99_System/{{GIT_OPS}}/` — logs de operação do vault
- Todo o vault — responsável pela integridade e sincronização git

---

## Como Usar

1. **Leitura:** navegue pela pasta do seu domínio
2. **Escrita:** crie notas em `99_System/Memories/` com timestamp no nome (evita conflitos git)
3. **Sincronização:** {{GIT_OPS}} gerencia push/pull automático (autorizado por {{COMMANDER}})
4. **Conflitos:** escala para {{COMMANDER}} — {{GIT_OPS}} nunca resolve merge automático

## ⚠️ Regras

- **NUNCA** manipular arquivos do vault manualmente sem ser via {{GIT_OPS}}
- **NUNCA** apagar arquivos — podem ser untracked (não versionados)
- **SEMPRE** escrever notas com timestamp no nome para evitar conflitos
- Vault é o **segundo cérebro** da equipe — todo conhecimento relevante deve ser registrado aqui
