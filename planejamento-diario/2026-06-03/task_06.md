# Task 06 — README.md + visão geral do projeto

**Wave:** 3 (Documentação)
**Prioridade:** 🟡
**Ferramenta:** Gemini CLI
**Depende de:** task_03, task_04, task_05

---

## Contexto

O repositório precisa de um README.md na raiz que explique:
- O que é o agent-ops-workflow
- Para quem é (desenvolvedores que usam Hermes Agent)
- O problema que resolve
- Quickstart para começar em 5 minutos
- Estrutura do repositório

---

## Instruções

Criar `agent-ops-workflow/README.md` com:

### 1. Título e descrição (1 parágrafo impactante)

Ex: "Agent Ops Workflow — Um sistema de planejamento diário em markdown
para times multi-agente Hermes. Organize, delegue e audite tarefas entre
seus agentes de IA com um fluxo testado em produção."

### 2. O problema (breve)

"Agentes IA não têm memória de sessões passadas. Sem um sistema externo,
cada sessão começa do zero. Tarefas se perdem, motores errados são usados,
commits ficam órfãos."

### 3. A solução (o workflow em 1 minuto)

- 6 fases: Planejar → Aprovar → Delegar → Executar → Auditar → Relatar
- Estrutura `planejamento-diario/` com PLANO.md + tasks + INDICE.md
- Protocolo Slack para comunicação
- Skills Hermes de suporte

### 4. Quickstart (5 passos)

```bash
# 1. Clone
git clone https://github.com/SEU_USUARIO/agent-ops-workflow.git

# 2. Setup
cd agent-ops-workflow
./scripts/setup-workflow.sh ~/meu-projeto "MeuTime" "MeuProjeto"

# 3. Personalize os placeholders
# 4. Crie seu primeiro plano
# 5. Comece a delegar!
```

### 5. Estrutura do repositório (tree comentada)

### 6. Próximos passos (links para docs/)

### 7. Licença (MIT sugerida)

---

## Checklist

- [ ] README.md criado com seções completas
- [ ] Quickstart funcional (testável)
- [ ] Estrutura do repositório documentada
- [ ] Links para docs/ funcionais
- [ ] Tom profissional e didático

---

## Restrições

- NENHUMA referência a Rafael, Roshar ou Oeste Gestão
- Escrever para um desenvolvedor que NUNCA viu o projeto antes

---

## Conclusão

**Agente:** Shallan (Opus 4.7)
**Concluída em:** 03/06/2026 ~09:00
**Motor utilizado:** Opus 4.7
**Observações:**
- README.md principal em português (BR) com badges, hero section, diagrama ASCII das 6 fases, quickstart, tree view, 10 funcionalidades
- README-en.md — versão completa em inglês (US)
- Commit: 8610903 + push via Dalinar
- README moderno com shields.io badges
