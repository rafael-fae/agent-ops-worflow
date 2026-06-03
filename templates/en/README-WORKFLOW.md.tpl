<!--
==============================================================================
  README-WORKFLOW.md.tpl — Daily Planning Folder README
  ============================================================================
  This file serves as the README for the `planejamento-diario/` folder of your
  project. Copy to planejamento-diario/README.md and adapt.

  The purpose of this README is to explain to ANYONE who enters the folder
  what it is, how it works, and how to participate in the daily workflow.

  How to use:
    1. Copy this template to planejamento-diario/README.md
    2. Replace __PLACEHOLDERS__ with your team's data
    3. Adapt the examples as needed
    4. Keep the didactic tone — newcomers need to understand quickly
==============================================================================
-->

# 📋 Daily Planning — __NOME_DO_TIME__

> **This folder is the HEART of our daily planning workflow.**
> Here we document what we did, what we are doing, and what we will do.

---

<!-- =====================================================================
  SECTION: WHAT IT IS
  Explains the folder purpose in simple language.
===================================================================== -->
## What is this folder?

The `planejamento-diario/` folder is the central nervous system of our
multi-agent operation. It contains:

- **`INDICE.md`** — The dashboard. Shows overall progress, day by day,
  with status for each task (completed, audited, pending).

- **`__DATA__/`** — Date-stamped folders (e.g.: `2026-06-03/`) containing the plan
  and tasks for each day:
  - `PLANO.md` — The day's execution plan: waves, tasks, dependencies
  - `task_01.md`, `task_02.md`, ... — Individual tasks with detailed instructions

The workflow is simple:
1. **Plan** — Create the day's PLANO.md with waves and tasks
2. **Execute** — Each agent picks a task and executes it
3. **Record** — Update the status in INDICE.md
4. **Audit** — Another agent reviews the completed task
5. **Repeat** — The next day, start again

---

<!-- =====================================================================
  SECTION: FOLDER STRUCTURE
  Shows the directory tree for quick reference.
===================================================================== -->
## Structure

```
planejamento-diario/
├── README.md              ← This file (usage instructions)
├── INDICE.md              ← General index with progress
├── __DATA_1__/            ← E.g.: 2026-06-03/
│   ├── PLANO.md           ← Day's plan
│   ├── task_01.md         ← Individual task
│   ├── task_02.md
│   └── ...
└── __DATA_2__/            ← E.g.: 2026-06-04/
    ├── PLANO.md
    └── ...
```

---

<!-- =====================================================================
  SECTION: DAILY CYCLE
  Explains step by step how to use the workflow day to day.
===================================================================== -->
## Daily usage

### 🌅 Start of day (Commander / Orchestrator)

1. **Read INDICE.md** — see what was left pending from the previous day
2. **Create the day's folder:** `mkdir -p planejamento-diario/$(date +%Y-%m-%d)`
3. **Copy the PLANO.md.tpl template** into the folder and fill in:
   - Date, team, day's purpose
   - Waves (Morning/Afternoon/Evening — as many as make sense)
   - Tasks with description, agent, engine, priority
   - Dependency diagram
4. **Copy TASK.md.tpl templates** for each task in the plan
5. **Update INDICE.md** with the new day's tasks

### 🏃 During the day (Agents)

1. **Pick a task** — choose a pending task from INDICE.md
2. **Read the task** — understand the context, instructions, and constraints
3. **Execute** — follow the instructions step by step
4. **Check the checklist** — mark items as completed
5. **Fill in the Conclusion** — document what was done
6. **Update INDICE.md** — mark ✅ and add the commit hash
7. **Notify the auditor** — the task needs to be reviewed

### ✅ End of day (Commander / Orchestrator)

1. **Check progress** — how many tasks were completed?
2. **Audit pending tasks** — 👁 should become ✅
3. **Update the counter** in the INDICE.md header
4. **Update the Progress section** by wave
5. **Commit and push**:
   ```bash
   git add -A
   git commit -m "planning: updates day __DATA__"
   git push
   ```
6. **Document pending items** for the next day in INDICE.md

---

<!-- =====================================================================
  SECTION: CONVENTIONS
  Naming and formatting rules to maintain consistency.
===================================================================== -->
## Conventions

### Naming

| Item | Format | Example |
|------|--------|---------|
| Date folder | `YYYY-MM-DD` | `2026-06-03/` |
| Day plan | `PLANO.md` | `2026-06-03/PLANO.md` |
| Individual task | `task_NN.md` | `task_01.md` |
| General index | `INDICE.md` | `INDICE.md` |

### Status symbols

| Symbol | Meaning |
|:------:|---------|
| ✅ | Task completed |
| 👁 | Task audited (reviewed by another agent) |
| ⬜ | Pending (not started) |
| 🔴 | High priority |
| 🟡 | Medium priority |
| 🟢 | Low priority |

### Priorities

- **🔴 High:** Blocking. Prevents other tasks. Must be done first.
- **🟡 Medium:** Important but does not block other tasks.
- **🟢 Low:** Improvement, refinement, technical debt.

---

<!-- =====================================================================
  SECTION: REFERENCE
  Links to full documentation and examples.
===================================================================== -->
## Reference

- **Full workflow documentation:** __URL_DOCS__ (e.g.: https://docs.yourteam.com/workflow)
- **Project repository:** __URL_REPO__ (e.g.: github.com/your-team/your-project)
- **Templates available at:** `templates/` (PLANO.md.tpl, TASK.md.tpl, INDICE.md.tpl)
- **Team channel:** __CANAL_DO_TIME__ (e.g.: #team-channel on Slack)
- **Current commander:** __COMANDANTE__

---

<!-- =====================================================================
  SECTION: QUICK EXAMPLE
  A mini-tutorial for anyone who wants to get started immediately.
===================================================================== -->
## Quick example

```bash
# 1. Create the day's folder
mkdir -p planejamento-diario/$(date +%Y-%m-%d)

# 2. Copy the plan template
cp templates/PLANO.md.tpl planejamento-diario/$(date +%Y-%m-%d)/PLANO.md

# 3. Edit the plan (fill in placeholders)
# Open the file and replace __DATA__, __NOME_DO_PROJETO__, etc.

# 4. Create tasks
cp templates/TASK.md.tpl planejamento-diario/$(date +%Y-%m-%d)/task_01.md
cp templates/TASK.md.tpl planejamento-diario/$(date +%Y-%m-%d)/task_02.md

# 5. Update the index
# Add the tasks to INDICE.md with status ⬜

# 6. Initial commit
git add -A
git commit -m "planning: starts day $(date +%Y-%m-%d)"
git push
```

---

<!-- =====================================================================
  SECTION: LICENSE / CLOSING INFORMATION
===================================================================== -->
---
*Part of project __NOME_DO_PROJETO__ · Internal documentation of team __NOME_DO_TIME__*
*License: __LICENCA__ (e.g.: MIT, Apache 2.0)*
