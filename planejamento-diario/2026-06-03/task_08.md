# Task 08 — Docs: guia de skills e adaptação para outros times

**Wave:** 3 (Documentação)
**Prioridade:** 🟡
**Ferramenta:** Gemini CLI
**Depende de:** task_03

---

## Contexto

As skills Hermes são o coração da memória procedural dos agentes. Precisamos
documentar como adaptá-las para outros times, quais skills são essenciais,
e como criar novas skills.

---

## Instruções

Criar em `agent-ops-workflow/docs/`:

### 1. `docs/04-GUIA-SKILLS.md`

**Conteúdo:**
- O que são skills Hermes (SKILL.md + estrutura de diretórios)
- Como carregar uma skill (`skill_view`, `skill_manage`)
- Skills incluídas neste repositório (tabela com nome, categoria, descrição, tamanho)
- Como adaptar uma skill para seu time (substituir placeholders)
- Como criar uma skill nova (passo-a-passo com template)
- Boas práticas (categorização, frontmatter YAML, referências)
- Troubleshooting (skill não carrega, caminho errado, conflitos)

**Tabela de skills fornecidas:**

| Skill | Categoria | Descrição | Complexidade |
|-------|-----------|-----------|:-----------:|
| planejamento-diario | operacao | Sistema de planejamento diário | 🔴 |
| diagnostico-agentes-mudos | operacao | Diagnosticar agentes que param de responder | 🟡 |
| git-vault-agent-pattern | operacao | Arquitetura de agente Utility dedicado | 🟡 |
| ... | ... | ... | ... |

---

### 2. `docs/05-ADAPTACAO.md`

Guia para times que querem personalizar o workflow:

**Conteúdo:**
- Escolhendo nomes para seus agentes (dica: usar tema unificado ex: personagens, elementos)
- Definindo papéis (orquestrador, backend, frontend, devops, auditor, git)
- Hierarquia de motores LLM (qual modelo para cada tipo de tarefa)
- Configurando canais Slack (criação do app, permissões, IDs)
- Adaptando templates (como modificar PLANO.md.tpl para sua realidade)
- Exemplo: "Time Avatar" — Aang (orquestrador), Katara (backend), Zuko (devops), etc.
- Checklist de migração

---

### 3. `docs/06-REFERENCIA-RAPIDA.md`

Folha de cola (cheat sheet) de 1 página:

```markdown
# Referência Rápida — agent-ops-workflow

## Comandos
- Setup: `./scripts/setup-workflow.sh ~/projeto "Time" "Projeto"`
- Gerar plano: `./scripts/gerar-plano-diario.sh ~/projeto`
- Validar: `./scripts/validate-workflow.sh ~/projeto`

## Estrutura
projeto/planejamento-diario/
├── INDICE.md         ← histórico de todas as tasks
├── YYYY-MM-DD/       ← um diretório por dia
│   ├── PLANO.md      ← plano do dia
│   ├── task_01.md    ← task individual
│   └── ...
└── TEMPLATE_PLANO.md ← template (não editar)

## 6 Fases
1. PLANEJAR → 2. APROVAR → 3. DELEGAR → 4. EXECUTAR → 5. AUDITAR → 6. RELATAR

## Regras de Ouro
- Uma task = uma thread no Slack
- Motor padrão = Gemini 3.1 Pro
- Sempre commitar + push antes de reportar
- NUNCA implementar sem "sinal verde" do comandante
```

---

## Checklist

- [ ] docs/04-GUIA-SKILLS.md criado com tabela de skills
- [ ] docs/05-ADAPTACAO.md criado com exemplos de times
- [ ] docs/06-REFERENCIA-RAPIDA.md criado (1 página)
- [ ] Cross-links entre docs funcionais
- [ ] Nenhuma referência a Roshar/Oeste Gestão

---

## Restrições

- Conteúdo 100% genérico
- Exemplos de times usam nomes fictícios (ex: Time Avatar, Time Elemental)

---

## Conclusão

`TBD`
