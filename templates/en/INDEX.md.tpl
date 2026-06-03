<!--
==============================================================================
  INDEX.md.tpl — Generic Planning Index Template
  ============================================================================
  This is the template for the overall daily planning index.
  Copy to planejamento-diario/INDICE.md and fill in.

  The index is the SHOWCASE of the team's progress. It shows:
    - What was planned vs. accomplished
    - The status of each task (completed, audited, pending)
    - Progress by wave
    - Commits associated with each delivery

  How to use:
    1. Copy this template to planejamento-diario/INDICE.md
    2. Each new day, add a "## DD/MM/YYYY — X/Y" section
    3. Fill the table with the day's tasks
    4. Update the progress by wave section
    5. Keep the legend at the top

  Daily update:
    - At the start of the day: add the date section with pending tasks
    - Upon completing a task: change ⬜ to ✅ and add the commit hash
    - After audit: change 👁 ⬜ to 👁 ✅
    - At the end of the day: update the X/Y counter and the progress section
==============================================================================
-->

# Planning Index — __NOME_DO_PROJETO__

<!--
  Legend: explains the symbols used in the tables.
  ✅ = task completed (execution finished)
  👁 = task audited (cross-review done by another agent)
  ⬜ = pending (not started or not completed)
-->
> **Purpose:** This index documents the planning and progress of project
> __NOME_DO_PROJETO__ — a multi-agent daily planning system.
>
> **Legend:** ✅ = completed | 👁 = audited | ⬜ = pending
>
> **Goal:** This file is the workflow THERMOMETER — it shows execution health.

---

<!-- =====================================================================
  DAY SECTION
  For each work day, add a block like the one below.

  Header format:
    ## DD/MM/YYYY — COMPLETED_TASKS/TOTAL_TASKS

  Example:
    ## 03/06/2026 — 2/10

  The table has 6 columns:
    Task      | File name (link)
    Description | Summary of what the task does
    Wave      | Wave number
    ✅        | Completed? (✅ or ⬜)
    👁        | Audited? (✅ or ⬜)
    Commit    | Commit hash (or "—" if not committed)

  IMPORTANT: The counter in the title MUST reflect the actual sum of ✅ in the column.
  At the end of the day, the counter must match the total of completed tasks.
===================================================================== -->

## __DATA__ — __TASKS_CONCLUIDAS__/__TOTAL_TASKS__

| Task | Description | Wave | ✅ | 👁 | Commit |
|------|-------------|:----:|---|---|--------|
<!--
  Example row (fill for each task):
  | task_01 | Set up development environment | 1 | ✅ | ⬜ | a1b2c3d |
  | task_02 | Review requirements             | 1 | ✅ | ✅ | e4f5g6h |
  | task_03 | Fix critical bug                | 2 | ⬜ | ⬜ | — |
-->
| __TASK_1__ | __DESCRICAO_1__ | __WAVE_1__ | __STATUS_1__ | __AUDIT_1__ | __COMMIT_1__ |
| __TASK_2__ | __DESCRICAO_2__ | __WAVE_2__ | __STATUS_2__ | __AUDIT_2__ | __COMMIT_2__ |
| __TASK_3__ | __DESCRICAO_3__ | __WAVE_3__ | __STATUS_3__ | __AUDIT_3__ | __COMMIT_3__ |
| __TASK_4__ | __DESCRICAO_4__ | __WAVE_4__ | __STATUS_4__ | __AUDIT_4__ | __COMMIT_4__ |
| __TASK_5__ | __DESCRICAO_5__ | __WAVE_5__ | __STATUS_5__ | __AUDIT_5__ | __COMMIT_5__ |
| __TASK_6__ | __DESCRICAO_6__ | __WAVE_6__ | __STATUS_6__ | __AUDIT_6__ | __COMMIT_6__ |
| __TASK_7__ | __DESCRICAO_7__ | __WAVE_7__ | __STATUS_7__ | __AUDIT_7__ | __COMMIT_7__ |
| __TASK_8__ | __DESCRICAO_8__ | __WAVE_8__ | __STATUS_8__ | __AUDIT_8__ | __COMMIT_8__ |
| __TASK_9__ | __DESCRICAO_9__ | __WAVE_9__ | __STATUS_9__ | __AUDIT_9__ | __COMMIT_9__ |
| __TASK_10__ | __DESCRICAO_10__ | __WAVE_10__ | __STATUS_10__ | __AUDIT_10__ | __COMMIT_10__ |

_Add or remove rows as needed based on the number of tasks for the day._

---

<!-- =====================================================================
  SECTION: PROGRESS BY WAVE
  Visual summary of consolidated progress across all project waves.
  The table shows:
    - Wave name
    - Total tasks in the wave
    - How many completed
    - Visual status (progress bar)

  Bar format: "X/Y" where X is completed and Y is total.
  Example: "3/5" or "✅ 3/5" if the wave is complete.

  OPTIONAL: you can add a Total row at the end.
===================================================================== -->

## Progress

| Wave | Tasks | Status |
|:----:|:-----:|:------:|
<!--
  Example:
  | 1 — Setup        | 2 | ✅ 2/2 |
  | 2 — Development  | 3 | ⬜ 1/3 |
  | 3 — Testing      | 3 | ⬜ 0/3 |
  | 4 — Deploy       | 2 | ⬜ 0/2 |
  | **Total**        | **10** | **3/10** |
-->
| 1 — __NOME_WAVE_1__ | __TOTAL_WAVE_1__ | __STATUS_WAVE_1__ |
| 2 — __NOME_WAVE_2__ | __TOTAL_WAVE_2__ | __STATUS_WAVE_2__ |
| 3 — __NOME_WAVE_3__ | __TOTAL_WAVE_3__ | __STATUS_WAVE_3__ |
| 4 — __NOME_WAVE_4__ | __TOTAL_WAVE_4__ | __STATUS_WAVE_4__ |
| **Total** | **__TOTAL_GERAL__** | **__STATUS_GERAL__** |

---

<!-- =====================================================================
  SECTION: UPDATE INSTRUCTIONS
  Keep these instructions at the end of the file for quick reference.
  Anyone on the team should be able to update the index.
===================================================================== -->

## How to update this index

1. **Add a new day:** copy the "## __DATA__" section block and adjust
2. **Mark task completed:** change ⬜ to ✅ in the ✅ column and add the commit hash
3. **Mark task audited:** change ⬜ to ✅ in the 👁 column
4. **Update header counter:** count how many ✅ exist in the ✅ column and update __TASKS_CONCLUIDAS__/__TOTAL_TASKS__
5. **Update progress by wave:** update each wave's status in the "Progress" section
6. **Commit the changes:** `git add -A && git commit -m "index: updates progress for day __DATA__" && git push`

### Reminder

> The index is ONLY useful if it is kept up to date. Take 2 minutes at the end of each
> wave to reflect the actual progress. Do not accumulate updates — they
> tend to never happen.
