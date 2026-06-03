# Task 06 — README.md + project overview

**Wave:** 3 (Documentation)
**Priority:** 🟡
**Tool:** Gemini CLI
**Depends on:** task_03, task_04, task_05

---

## Context

The repository needs a README.md at the root that explains:
- What agent-ops-workflow is
- Who it's for (developers using Hermes Agent)
- The problem it solves
- Quickstart to get started in 5 minutes
- Repository structure

---

## Instructions

Create `agent-ops-workflow/README.md` with:

### 1. Title and description (1 impactful paragraph)

Example: "Agent Ops Workflow — A markdown-based daily planning system
for multi-agent Hermes teams. Organize, delegate, and audit tasks among
your AI agents with a production-tested workflow."

### 2. The problem (brief)

"AI agents have no memory of past sessions. Without an external system,
each session starts from scratch. Tasks get lost, wrong engines are used,
commits become orphaned."

### 3. The solution (the workflow in 1 minute)

- 6 phases: Plan → Approve → Delegate → Execute → Audit → Report
- `planejamento-diario/` structure with PLAN.md + tasks + INDEX.md
- Slack protocol for communication
- Supporting Hermes skills

### 4. Quickstart (5 steps)

```bash
# 1. Clone
git clone https://github.com/YOUR_USER/agent-ops-workflow.git

# 2. Setup
cd agent-ops-workflow
./scripts/setup-workflow.sh ~/my-project "MyTeam" "MyProject"

# 3. Customize placeholders
# 4. Create your first plan
# 5. Start delegating!
```

### 5. Repository structure (annotated tree)

### 6. Next steps (links to docs/)

### 7. License (MIT suggested)

---

## Checklist

- [ ] README.md created with complete sections
- [ ] Functional quickstart (testable)
- [ ] Repository structure documented
- [ ] Links to docs/ working
- [ ] Professional and didactic tone

---

## Constraints

- NO references to Rafael, Roshar, or Oeste Gestão
- Write for a developer who has NEVER seen the project before

---

## Conclusion

**Agent:** Shallan (Opus 4.7)
**Completed on:** 06/03/2026 ~09:00
**Engine used:** Opus 4.7
**Notes:**
- Main README.md in Portuguese (BR) with badges, hero section, ASCII diagram of the 6 phases, quickstart, tree view, 10 features
- README-en.md — complete English (US) version
- Commit: 8610903 + push via Dalinar
- Modern README with shields.io badges
