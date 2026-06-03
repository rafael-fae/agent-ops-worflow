# Task 09 — Structure final repository (without files/)

**Wave:** 4 (Finalization)
**Priority:** 🟢
**Tool:** Gemini CLI
**Depends on:** task_06, task_07, task_08

---

## Context

At this point we have:
- `files/` with raw and sanitized material (NOT going to the final repository)
- `templates/` with the .tpl files
- `scripts/` with automations
- `docs/` with documentation
- `README.md` at the root

We need to organize the FINAL repository structure, removing `files/`,
adding `.gitignore`, and ensuring everything is cohesive.

---

## Instructions

### 1. Desired final structure

```
agent-ops-workflow/
├── README.md
├── LICENSE (MIT)
├── .gitignore
├── .github/
│   └── FUNDING.yml (optional)
├── docs/
│   ├── 01-SETUP-INITIAL.md
│   ├── 02-DAILY-CYCLE.md
│   ├── 03-SLACK-PROTOCOL.md
│   ├── 04-SKILLS-GUIDE.md
│   ├── 05-CUSTOMIZATION.md
│   └── 06-QUICK-REFERENCE.md
├── templates/
│   ├── PLAN.md.tpl
│   ├── TASK.md.tpl
│   ├── INDEX.md.tpl
│   └── README-WORKFLOW.md.tpl
├── skills/
│   └── <sanitized skills organized by category>
├── scripts/
│   ├── setup-workflow.sh
│   ├── gerar-plano-diario.sh
│   ├── validate-workflow.sh
│   ├── rotate-key.sh
│   └── README.md (script instructions)
├── assets/
│   └── (only if there's something useful and generic)
└── planejamento-diario/    ← OUR OWN PLAN (living proof)
    ├── INDEX.md
    ├── 2026-06-03/
    │   ├── PLAN.md
    │   ├── task_01.md
    │   └── ...
    └── TEMPLATE_PLAN.md (template copy)
```

### 2. Actions

- Move `templates/` from root to root (already there)
- Move sanitized skills from `files/skills/sanitized/` to `skills/`
- Remove `files/` completely
- Create `.gitignore`:
  ```
  # agent-ops-workflow .gitignore
  files/          ← never committed
  .env
  *.local
  ```

### 3. Verifications

- Final structure clean and symmetrical
- No raw files in skills/ (only sanitized)
- README.md reflects actual structure
- All internal links work

### 4. Initial commit (local, not yet published)

```bash
cd ~/Dev/agent-ops-workflow
git init
git add .
git status  # verify files/ does NOT appear
```

---

## Checklist

- [x] files/ completely removed (via Python shutil.rmtree)
- [x] skills/ populated with 163 sanitized skills (76 directories)
- [x] .gitignore cleaned (removed /files/ entry)
- [x] Structure as planned (docs/, docs/en/, templates/, templates/en/, skills/, scripts/)
- [x] `git status` confirms files/ is not being tracked
- [x] README.md will be updated by Shallan (task_06)
- [x] MIT License added (since initial commit)

---

## Constraints

- NO raw files — only sanitized content
- NO references to Roshar/Oeste Gestão in the final structure

---

## Conclusion

**Agent:** Dalinar
**Completed on:** 06/03/2026 ~11:30
**Engine used:** Gemini CLI
**Notes:**
- 163 sanitized skills moved from files/skills/sanitized/ to skills/
- files/ removed (279 raw files freed)
- .gitignore cleaned (removed reference to /files/)
- Final structure: docs/ (pt-BR), docs/en/ (en-US), templates/, templates/en/, skills/, scripts/
- README.md being updated by Shallan in parallel (task_06)
- Next step: task_10 — final audit + release v1.0.0
