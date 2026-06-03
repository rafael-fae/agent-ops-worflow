<!--
==============================================================================
  PLANO.md.tpl — Generic Daily Plan Template
  ============================================================================
  This is a template for the daily execution plan of any team using the
  multi-agent workflow. Copy to planejamento-diario/__DATA__/PLANO.md
  and fill in the __PLACEHOLDER__ tokens.

  How to use:
    1. Copy this file to planejamento-diario/__DATA__/PLANO.md
    2. Replace all __PLACEHOLDERS__ with your team's values
    3. Adjust the waves as needed (Morning/Afternoon/Evening)
    4. Fill the task table at the start of each wave

  About the placeholders:
    __PLACEHOLDER__ = text you MUST replace (double underscore)
    <!-- comment   = didactic instruction explaining the section
    (example)     = illustration of how to fill, remove or adapt
==============================================================================
-->

# Execution Plan — __NOME_DO_PROJETO__

<!--
  Editable header: fill in date, team and commander.
  The commander is the person (or orchestrator agent) who defines the day's plan.
-->
**Created by:** __COMANDANTE__ / __TIME__
**Date:** __DATA__ (format: DD/MM/YYYY)
**Purpose:** __PROPOSITO_DO_DIA__ (e.g.: "Finish current sprint", "Fix critical bugs", "Prepare release")
**Workflow:** This plan FOLLOWS the daily planning workflow documented in the repository.

---

<!-- =====================================================================
  SECTION: PROJECT RESOURCES
  List here all resources your team will consult during the day.
  Fill the table with what is relevant to the project.
  Leave empty and fill at the start of the day — examples below are illustrative.
===================================================================== -->
## 📚 PROJECT RESOURCES

| Resource | Location | Purpose |
|----------|----------|---------|
<!--
  Examples (remove or adapt):
  | Main repository     | github.com/your-team/your-project  | Source code |
  | API documentation   | docs.yourproject.com/api           | Technical reference |
  | Task board          | link-to-your-board                  | Issue tracking |
  | Staging environment | https://staging.yourproject.com     | Testing and validation |
  | CI/CD pipeline      | link-to-your-ci                     | Deploys and builds |
-->
| __RECURSO_1__ | __LOCAL_1__ | __PROPOSITO_1__ |
| __RECURSO_2__ | __LOCAL_2__ | __PROPOSITO_2__ |
| __RECURSO_3__ | __LOCAL_3__ | __PROPOSITO_3__ |

---

<!-- =====================================================================
  SECTION: SUMMARY
  Describe in 2-3 sentences the macro objective of the day.
  Example: "Today we will finalize the payment gateway integration
  and fix the 3 bugs identified in the last audit."
===================================================================== -->
## Summary

__RESUMO_DO_DIA__

Describe here, in general terms, what needs to be delivered by the end of the day.
What problems will be solved? What features will be implemented?
What is the success criterion?

---

<!-- =====================================================================
  SECTION: WAVES
  The waves divide the day into execution blocks. The most common pattern is:
    Wave 1 — Morning
    Wave 2 — Afternoon
    Wave 3 — Evening
  Each wave has a set of tasks with priority, agent, and status.

  You can rename the waves or use fewer/more — the important thing is to group
  tasks by shift or logical phase.

  How to fill:
    1. Copy the block below for each wave you need
    2. Adjust the name (e.g.: "Wave 1 — Morning 🔴 ✅" if already completed)
    3. Fill the task table

  Status: ✅ completed | 🔴 in progress | ⬜ pending
===================================================================== -->

## Waves

### Wave 1 — __NOME_DA_WAVE_1__ (__TURNO_1__) 🔴

<!--
  Example wave:
  ### Wave 1 — Setup and Planning (Morning) 🔴 ✅
-->

| Task | Description | Agent | Engine | Priority | Status |
|:----:|-------------|:-----:|:------:|:--------:|:------:|
<!--
  Example row (adapt):
  | task_01 | Set up development environment     | Agent Alpha  | Gemini CLI  | 🔴 | ✅ |
  | task_02 | Review sprint requirements         | Agent Beta   | Claude Code | 🟡 | ⬜ |
  | task_03 | Fix critical login bug             | Agent Gamma  | OpenAI API  | 🔴 | 🔴 |
-->
| __TASK_ID_1__ | __DESCRICAO_1__ | __AGENTE_1__ | __MOTOR_1__ | __PRIORIDADE_1__ | __STATUS_1__ |
| __TASK_ID_2__ | __DESCRICAO_2__ | __AGENTE_2__ | __MOTOR_2__ | __PRIORIDADE_2__ | __STATUS_2__ |

**Goal:** __OBJETIVO_DA_WAVE_1__

---

### Wave 2 — __NOME_DA_WAVE_2__ (__TURNO_2__) 🟡

| Task | Description | Agent | Engine | Priority | Status |
|:----:|-------------|:-----:|:------:|:--------:|:------:|
| __TASK_ID_3__ | __DESCRICAO_3__ | __AGENTE_3__ | __MOTOR_3__ | __PRIORIDADE_3__ | __STATUS_3__ |
| __TASK_ID_4__ | __DESCRICAO_4__ | __AGENTE_4__ | __MOTOR_4__ | __PRIORIDADE_4__ | __STATUS_4__ |

**Goal:** __OBJETIVO_DA_WAVE_2__

---

### Wave 3 — __NOME_DA_WAVE_3__ (__TURNO_3__) 🟢

| Task | Description | Agent | Engine | Priority | Status |
|:----:|-------------|:-----:|:------:|:--------:|:------:|
| __TASK_ID_5__ | __DESCRICAO_5__ | __AGENTE_5__ | __MOTOR_5__ | __PRIORIDADE_5__ | __STATUS_5__ |
| __TASK_ID_6__ | __DESCRICAO_6__ | __AGENTE_6__ | __MOTOR_6__ | __PRIORIDADE_6__ | __STATUS_6__ |

**Goal:** __OBJETIVO_DA_WAVE_3__

---

<!-- =====================================================================
  SECTION: DEPENDENCIES
  ASCII diagram showing which tasks depend on which.
  Use arrows (→) to indicate flow.
  Parallel tasks stay on the same level; sequential tasks on different levels.
===================================================================== -->
## Dependencies

```

<!--
  Example dependency diagram:
  Wave 1 (Setup)
    task_01 (infra) + task_02 (config) — parallel

  Wave 2 (Development)
    task_03 (backend) depends on task_01
    task_04 (frontend) depends on task_02
    task_05 (tests) depends on task_03, task_04

  Wave 3 (Finalization)
    task_06 (deploy) depends on task_05
-->

__DIAGRAMA_DE_DEPENDENCIAS__

```

---

<!-- =====================================================================
  SECTION: EXECUTION RULES
  Non-negotiable rules that the team must follow.
  Customize as agreed by the team.
===================================================================== -->
## ⚠️ EXECUTION RULES

1. **Default engine:** __MOTOR_PADRAO__ (e.g.: "Gemini CLI" or "Claude Code" or "OpenAI API")
2. **NEVER modify original files** — always work on copies or branches
3. **Repository:** Only commit sanitized/generic content — __ARQUIVOS_IGNORADOS__ are NOT uploaded
4. **Independence:** This project is self-contained. Does not depend on undocumented external resources
5. **Didactic:** Every file MUST be commented and explained — other people will read it
6. **Language:** Documentation in __IDIOMA__ (e.g.: pt-BR, en-US)
7. **Semantic commit:** Descriptive commits in the chosen language
8. **Threads:** Maximum of __MAX_THREADS__ simultaneous agents
9. **Audit:** Every completed task MUST be audited by another agent before closing

---

<!-- =====================================================================
  SECTION: END OF DAY CHECKLIST
  Check off items when closing the work day.
===================================================================== -->
## End of Day

- [ ] __TOTAL_TASKS__/__TOTAL_TASKS__ tasks completed and audited
- [ ] INDICE.md updated with day's status
- [ ] All commits made and pushed
- [ ] Pending items documented for the next day
- [ ] Security checklist verified (if applicable)
- [ ] Plan link shared with the team (if there is a channel)

---

<!-- =====================================================================
  SECTION: TARGET METRICS
  Define the day's goals — can be number of tasks, test coverage,
  deploys, etc.
===================================================================== -->
## Target Metrics

| Metric | Target | Actual |
|--------|:------:|:------:|
| Completed tasks | __META_TASKS__ | __REALIZADO_TASKS__ |
| __METRICA_EXTRA_1__ | __META_EXTRA_1__ | __REALIZADO_EXTRA_1__ |
| __METRICA_EXTRA_2__ | __META_EXTRA_2__ | __REALIZADO_EXTRA_2__ |
