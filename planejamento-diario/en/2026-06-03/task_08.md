# Task 08 — Docs: skills guide and adaptation for other teams

**Wave:** 3 (Documentation)
**Priority:** 🟡
**Tool:** Gemini CLI
**Depends on:** task_03

---

## Context

Hermes skills are the heart of the agents' procedural memory. We need to
document how to adapt them for other teams, which skills are essential,
and how to create new skills.

---

## Instructions

Create in `agent-ops-workflow/docs/`:

### 1. `docs/04-SKILLS-GUIDE.md`

**Content:**
- What are Hermes skills (SKILL.md + directory structure)
- How to load a skill (`skill_view`, `skill_manage`)
- Skills included in this repository (table with name, category, description, size)
- How to adapt a skill for your team (replace placeholders)
- How to create a new skill (step-by-step with template)
- Best practices (categorization, YAML frontmatter, references)
- Troubleshooting (skill won't load, wrong path, conflicts)

**Skills provided table:**

| Skill | Category | Description | Complexity |
|-------|-----------|-----------|:-----------:|
| planejamento-diario | operacao | Daily planning system | 🔴 |
| diagnostico-agentes-mudos | operacao | Diagnose agents that stop responding | 🟡 |
| git-vault-agent-pattern | operacao | Dedicated Utility agent architecture | 🟡 |
| ... | ... | ... | ... |

---

### 2. `docs/05-CUSTOMIZATION.md`

Guide for teams that want to customize the workflow:

**Content:**
- Choosing agent names (tip: use a unified theme e.g., characters, elements)
- Defining roles (orchestrator, backend, frontend, devops, auditor, git)
- LLM engine hierarchy (which model for each task type)
- Configuring Slack channels (app creation, permissions, IDs)
- Adapting templates (how to modify PLAN.md.tpl for your reality)
- Example: "Team Avatar" — Aang (orchestrator), Katara (backend), Zuko (devops), etc.
- Migration checklist

---

### 3. `docs/06-QUICK-REFERENCE.md`

1-page cheat sheet:

```markdown
# Quick Reference — agent-ops-workflow

## Commands
- Setup: `./scripts/setup-workflow.sh ~/project "Team" "Project"`
- Generate plan: `./scripts/gerar-plano-diario.sh ~/project`
- Validate: `./scripts/validate-workflow.sh ~/project`

## Structure
project/planejamento-diario/
├── INDEX.md           ← history of all tasks
├── YYYY-MM-DD/        ← one directory per day
│   ├── PLAN.md        ← day's plan
│   ├── task_01.md     ← individual task
│   └── ...
└── TEMPLATE_PLAN.md   ← template (do not edit)

## 6 Phases
1. PLAN → 2. APPROVE → 3. DELEGATE → 4. EXECUTE → 5. AUDIT → 6. REPORT

## Golden Rules
- One task = one Slack thread
- Default engine = Gemini 3.1 Pro
- Always commit + push before reporting
- NEVER implement without the commander's "green light"
```

---

## Checklist

- [x] docs/04-SKILLS-GUIDE.md created (English) — 795 lines
- [x] docs/05-CUSTOMIZATION.md created (English) — 742 lines
- [x] docs/06-QUICK-REFERENCE.md created (English) — 208 lines
- [x] Cross-links between docs working
- [x] No references to Roshar/Oeste Gestão

---

## Constraints

- 100% generic content
- Team examples use fictional names (e.g., Team Avatar, Team Elemental)

---

## Conclusion

**Agent:** Dalinar (via subagents)
**Completed on:** 06/03/2026 ~11:10
**Engine used:** deepseek-v4-flash (subagent)
**Notes:**
- 04-SKILLS-GUIDE.md — 795 lines, all 43 skills listed with description and complexity, guide for adapting and creating skills
- 05-CUSTOMIZATION.md — 742 lines, 7 name themes, role definitions, engine hierarchy, complete "Team Elemental" example
- 06-QUICK-REFERENCE.md — 208 lines, 1-page cheat sheet
- All in ENGLISH (US), no references to Roshar/Rafael/Oeste Gestão
