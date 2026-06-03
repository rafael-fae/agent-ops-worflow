<!--
==============================================================================
  TASK.md.tpl — Generic Individual Task Template
  ============================================================================
  This is the template for creating a task within a daily plan.
  Copy to planejamento-diario/__DATA__/task_NN.md and fill in.

  How to use:
    1. Determine the sequential task number (e.g., task_01.md)
    2. Copy this template as task_NN.md
    3. Replace __PLACEHOLDERS__ with the actual values
    4. Write clear and verifiable instructions
    5. When done, update the "Conclusion" section

  Best practices:
    - One task = one clear and testable responsibility
    - Context should explain the WHY, not just the WHAT
    - Instructions must be numbered and specific
    - Checklist should contain binary items (yes/no, done/not done)
==============================================================================
-->

# Task __NUMERO__ — __TITULO_DA_TASK__

<!--
  Header: identifies the task within the day's plan.
-->
**Wave:** __WAVE__ (__NOME_DA_WAVE__)
**Priority:** __PRIORIDADE__ (🔴 = high, 🟡 = medium, 🟢 = low)
**Assigned agent:** __AGENTE__
**Engine:** __MOTOR__ (e.g.: Gemini CLI, Claude Code, OpenAI API)
**Depends on:** __DEPENDE_DE__ (e.g.: task_01, task_02 — or "—" if root)

---

<!-- =====================================================================
  SECTION: REQUIRED READING
  Links, documents or references the agent MUST read before starting.
  Leave empty if there are none, or fill with relevant links.
===================================================================== -->
## Required Reading

<!--
  Examples (remove or adapt):
  - [Payment API documentation](https://docs.example.com/api/payments)
  - [Issue #42 on GitHub](https://github.com/team/project/issues/42)
  - [Project style guide](https://docs.example.com/style-guide)
  - Reference commit: abc1234
-->
- __LEITURA_1__
- __LEITURA_2__

---

<!-- =====================================================================
  SECTION: CONTEXT
  Explain why this task exists. What problem does it solve?
  What is the current scenario? What happens if it's not done?
  Context is what allows the agent to make autonomous decisions.
===================================================================== -->
## Context

__CONTEXTO_DA_TASK__

Explain here:
- What is the problem or opportunity
- What has been done before (if applicable)
- Why this task is needed NOW
- What to expect at the end

<!--
  Example:
  "The /api/users endpoint is returning 500 for requests with
  special parameters. This was reported by 3 clients earlier today.
  We need to fix it before the next deploy at 3:00 PM."
-->

---

<!-- =====================================================================
  SECTION: INSTRUCTIONS
  Numbered and specific. Each instruction must be a verifiable action.
  Include commands, file paths, and code examples when possible.
===================================================================== -->
## Instructions

<!--
  Numbered markdown instructions. Example:

  1. Access the environment:
     ```bash
     ssh user@server
     cd /var/www/project
     ```

  2. Check logs:
     ```bash
     tail -100 logs/error.log | grep "500"
     ```

  3. Identify the root cause:
     - Check parameters that trigger the error
     - Verify validation in the controller

  4. Apply the fix following the project's coding standards

  5. Test:
     ```bash
     curl -X POST https://staging.example.com/api/users \
       -H "Content-Type: application/json" \
       -d '{"param":"test"}'
     ```

  6. Commit:
     ```bash
     git add -A
     git commit -m "fix 500 error on /api/users endpoint"
     git push
     ```
-->

### 1. __INSTRUCAO_1_TITULO__

__INSTRUCAO_1_DETALHES__

```bash
__COMANDO_1__
```

### 2. __INSTRUCAO_2_TITULO__

__INSTRUCAO_2_DETALHES__

```bash
__COMANDO_2__
```

### 3. __INSTRUCAO_3_TITULO__

__INSTRUCAO_3_DETALHES__

```bash
__COMANDO_3__
```

### 4. __INSTRUCAO_4_TITULO__

__INSTRUCAO_4_DETALHES__

```bash
__COMANDO_4__
```

_Add more instructions as needed._

---

<!-- =====================================================================
  SECTION: CHECKLIST
  Binary items the agent must check off when completed.
  Use [ ] for pending and [x] for done.
  Recommended: 5-8 items per task.
===================================================================== -->
## Checklist

- [ ] __CHECKLIST_1__
- [ ] __CHECKLIST_2__
- [ ] __CHECKLIST_3__
- [ ] __CHECKLIST_4__
- [ ] __CHECKLIST_5__
- [ ] __CHECKLIST_6__
- [ ] __CHECKLIST_7__
- [ ] __CHECKLIST_8__

<!--
  Example checklist items:
  - [x] Code compiled without errors
  - [ ] Unit tests passed (coverage > 80%)
  - [ ] Logs show no new errors
  - [ ] PR reviewed by at least one colleague
  - [ ] Documentation updated
  - [ ] NO production files were affected
  - [ ] Commits follow the team's semantic commit convention
-->

---

<!-- =====================================================================
  SECTION: CONSTRAINTS
  Specific rules for this task. What is forbidden? Which engine to use?
  Which files CANNOT be touched?
===================================================================== -->
## Constraints

- __RESTRICAO_1__
- __RESTRICAO_2__
- __RESTRICAO_3__

<!--
  Examples:
  - REQUIRED engine: Gemini CLI (do not use Claude for this task)
  - NEVER modify files in config/production/
  - DO NOT commit credentials or tokens
  - FORBIDDEN to deploy without approval
  - DO NOT change the public API interface
-->

---

<!-- =====================================================================
  SECTION: RELEVANT FILES
  Table with files the agent needs to know about to execute the task.
  Can include source and destination, or just paths of interest.
===================================================================== -->
## Relevant files

| File | Location | Purpose |
|------|----------|---------|
<!--
  Examples:
  | src/controllers/UserController.ts | Source code | Controller that needs to be changed |
  | tests/unit/UserController.test.ts | Tests | Where to write the tests |
  | config/database.ts | Configuration | Connection string (do not modify!) |
  | docs/API.md | Documentation | Update if the interface changes |
-->
| __ARQUIVO_1__ | __LOCAL_ARQUIVO_1__ | __PROPOSITO_ARQUIVO_1__ |
| __ARQUIVO_2__ | __LOCAL_ARQUIVO_2__ | __PROPOSITO_ARQUIVO_2__ |
| __ARQUIVO_3__ | __LOCAL_ARQUIVO_3__ | __PROPOSITO_ARQUIVO_3__ |

---

<!-- =====================================================================
  SECTION: CONCLUSION
  Filled by the agent upon completing the task.
  Keep the format below — it serves for audit and documentation purposes.
===================================================================== -->
## Conclusion

**Agent:** __AGENTE__
**Completed on:** __DATA__ ~__HORARIO__
**Engine used:** __MOTOR_UTILIZADO__
**Notes:**

__OBSERVACOES__

<!--
  Example notes:
  "Task completed successfully. The bug was in the 'email' parameter validation
  which did not accept special characters. Fixed in commit abc1234.
  Tests passed: 42/42. Logs clean."
-->
