# Execution Plan — agent-ops-workflow

**Created by:** Dalinar / Rafael Fae
**Date:** 06/03/2026
**Purpose:** Create a public template repository with the Hermes multi-agent workflow
**Workflow:** This plan FOLLOWS the very workflow being documented — living proof that it works.

---

## 📚 PROJECT RESOURCES

| Resource | Location | Purpose |
|---------|-------|-----------|
| Published tutorial | https://pycode.rafaelfae.com.br/equipe-roshar | Conceptual basis of the workflow |
| Current skills | ~/.hermes/profiles/dalinar/skills/ | Source of skills to be generalized |
| Current scripts | ~/.hermes/profiles/dalinar/skills/*/scripts/ | Existing automations |
| Current templates | ~/.hermes/profiles/dalinar/skills/*/templates/ | Plan and task templates |
| This plan | agent-ops-workflow/planejamento-diario/ | THE PLAN in action |

---

## Summary

Create the `agent-ops-workflow` repository that documents and packages the
multi-agent daily planning system for Hermes. The repository will contain:

1. **Templates** — PLAN.md, TASK.md, INDEX.md (generic, no specific names)
2. **Skills** — sanitized Hermes skills (no references to Roshar, Oeste Gestão, Rafael)
3. **Scripts** — cron automations, key rotation, setup
4. **Documentation** — complete tutorial in Portuguese about the workflow
5. **Assets** — minimal (only what's necessary)

**Golden rule:** The `files/` folder contains RAW copies of our files — it will
NEVER be committed. At the end, it will be removed. The final repository only has
sanitized and generic content.

---

## Waves

### Wave 1 — Mapping and Copy (Morning) 🔴 ✅

| Task | Description | Tool | Status |
|:----:|-----------|:----:|:------:|
| task_01 | Map existing skills + copy raw to files/skills/raw/ | Gemini | ✅ |
| task_02 | Map scripts, templates, assets → respective files/ | Gemini | ✅ |

**Goal:** ✅ 2/2 — 43 skills copied, 120+ script/template/reference files

### Wave 2 — Sanitization and Generalization (Afternoon) 🔴 ✅

| Task | Description | Tool | Status |
|:----:|-----------|:----:|:------:|
| task_03 | Sanitize skills — replace Roshar→{{TEAM_NAME}}, Oeste Gestão→{{PROJECT_NAME}}, etc. | Opus/Gemini | ✅ |
| task_04 | Create .tpl templates with placeholders | Gemini | ✅ |
| task_05 | Create generic scripts (cron, setup, rotate-key, validate) | Gemini | ✅ |

**Goal:** ✅ 3/3 — 142 sanitized skills, 4 .tpl templates, 4 scripts + README

### Wave 3 — Documentation (Evening) 🟡 ✅

| Task | Description | Tool | Status |
|:----:|-----------|:----:|:------:|
| task_06 | Main README.md (pt-BR) + README-en.md (en-US) | Opus 4.7 | ✅ |
| task_07 | Docs: initial setup, daily cycle, Slack protocol | Gemini | ✅ |
| task_08 | Docs: skills guide, adaptation, best practices | Gemini | ✅ |

**Goal:** ✅ 3/3 — Modern README (Shallan/Opus) + 6 docs pt-BR + 6 docs en-US + bilingual templates. Total: ~10,000 lines of documentation.

### Wave 4 — Finalization (Dawn) 🟢 ✅

| Task | Description | Tool | Status |
|:----:|-----------|:----:|:------:|
| task_09 | Structure final repository (organize, remove files/, .gitignore) | Gemini | ✅ |
| task_10 | Daily flow automation docs (shell + Hermes) + release | Gemini | ✅ |

**Goal:** ✅ 2/2 — Structured repository, complete documentation (14 docs, ~10,000 lines), 7 documented automation flows.

---

## Dependencies

```
Wave 1 (Mapping)
  task_01 (skills) + task_02 (scripts/templates) — parallel

Wave 2 (Sanitization)
  task_03 (sanitized skills) depends on task_01
  task_04 (templates) depends on task_02
  task_05 (scripts) depends on task_02

Wave 3 (Documentation)
  task_06 (README) depends on task_03, task_04, task_05
  task_07 (cycle+setup) depends on task_06
  task_08 (skills guide) depends on task_03

Wave 4 (Publishing)
  task_09 (structuring) depends on task_06, task_07, task_08
  task_10 (publish) depends on task_09
```

---

## ⚠️ EXECUTION RULES

1. **Default engine:** Gemini CLI (`gemini -m "gemini-3.1-pro-preview"`)
2. **NEVER modify original files** — only work in `files/` and project root
3. **files/ is NOT committed** — add to .gitignore at the end
4. **Independence:** This project does NOT depend on Oeste Gestão. It is self-contained.
5. **Didactic:** Every file MUST be commented and explained — other people will read it.
6. **Portuguese:** Documentation in pt-BR (at least v1).
7. **Semantic commits:** Descriptive commits in Portuguese.

---

## At the end of the project

- [ ] 10/10 tasks completed and audited
- [ ] Repository published on GitHub (public)
- [ ] README with functional quickstart
- [ ] files/ folder removed
- [ ] Link shared with Rafael
