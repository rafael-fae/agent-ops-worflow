# Daily Cycle Guide — Agent Ops Workflow

> Complete walkthrough of the 6-phase daily planning and execution cycle.
> This is the core of the workflow — the rhythm that keeps your multi-agent
> team coordinated, audited, and shipping every day.

---

## Table of Contents

1. [Overview](#overview)
2. [ASCII Flow Diagram](#ascii-flow-diagram)
3. [Phase 1: PLAN](#phase-1-plan)
4. [Phase 2: APPROVE](#phase-2-approve)
5. [Phase 3: DELEGATE](#phase-3-delegate)
6. [Phase 4: EXECUTE](#phase-4-execute)
7. [Phase 5: AUDIT](#phase-5-audit)
8. [Phase 6: REPORT](#phase-6-report)
9. [Complete Example Day — Team Nova](#complete-example-day--team-nova)
10. [Thread Rules](#thread-rules)
11. [Error Recovery Procedures](#error-recovery-procedures)
12. [Daily Report Template](#daily-report-template)

---

## Overview

The Agent Ops Workflow follows a strict 6-phase cycle that repeats every
working day. Each phase has a clear owner, a defined output, and a
verification step before the next phase begins.

**The golden rule:** Never skip phases. Never start a phase unless the
previous one is complete and verified. Plan before you approve, approve
before you delegate, delegate before you execute, execute before you audit,
audit before you report.

### Actors

| Role          | Who                                       | Responsibility                         |
|---------------|-------------------------------------------|----------------------------------------|
| Commander     | Human (team lead, product owner)          | Reviews plan, gives final green light  |
| Orchestrator | Lead agent (Hermes profile)               | Creates plan, delegates, audits, reports |
| Agent         | Any Hermes agent with a task assignment   | Executes assigned task, reports back   |
| Auditor       | Agent designated to cross-check           | Verifies work, checks commits, signs off |

In small teams, the orchestrator and auditor may be the same agent at
different points in the cycle. In larger teams, these are separate roles.

---

## ASCII Flow Diagram

```
                                  ┌──────────────┐
                                  │  COMMANDER   │
                                  │  (HUMAN)     │
                                  └──────┬───────┘
                                         │
                                    ╔════╧════╗
                                    ║ PHASE 1 ║
                                    ║  PLAN   ║
                                    ╚════╤════╝
                                         │
                                         ▼
                                    ╔════╧════╗
                                    ║ PHASE 2 ║
                                    ║ APPROVE ║
                                    ╚════╤════╝
                                         │
                                    ╔════╧════╗
                                    ║ PHASE 3 ║
                                    ║DELEGATE ║
                                    ╚════╤════╝
                                         │
                           ┌─────────────┼──────────────┐
                           │             │              │
                           ▼             ▼              ▼
                     ┌──────────┐ ┌──────────┐  ┌──────────┐
                     │ AGENT A  │ │ AGENT B  │  │ AGENT C  │
                     │ (EXECUTE)│ │ (EXECUTE)│  │ (EXECUTE)│
                     └────┬─────┘ └────┬─────┘  └────┬─────┘
                          │            │              │
                          └────────────┼──────────────┘
                                       ▼
                                  ╔════╧════╗
                                  ║ PHASE 5 ║
                                  ║  AUDIT  ║  ← Cross-check by different agent
                                  ╚════╤════╝
                                       │
                                  ╔════╧════╗
                                  ║ PHASE 6 ║
                                  ║ REPORT  ║
                                  ╚════╤════╝
                                       │
                                       ▼
                              ┌─────────────────┐
                              │   NEXT DAY      │
                              │   (back to P1)  │
                              └─────────────────┘
```

### What Flows Between Phases

```
PHASE 1 ──→ PLANO.md + task_XX.md files + INDICE.md entries
PHASE 2 ──→ approved_plan (verbal sign-off in Slack)
PHASE 3 ──→ Slack thread per task with @mention + instructions
PHASE 4 ──→ filled checkboxes + Conclusao section + commit hash
PHASE 5 ──→ updated INDICE.md + PLANO.md with audit stamps
PHASE 6 ──→ consolidated table + report message + git commit
```

---

## Phase 1: PLAN

**Owner:** Orchestrator (Hermes agent)
**Input:** Previous day's report, today's priorities (from Commander)
**Output:** `PLANO.md`, `task_XX.md` files, updated `INDICE.md`

### What the Orchestrator Does

1. **Read the previous day's report.** Check what was completed, what was
   left pending, and what the Commander flagged for follow-up.

2. **Review the INDICE.md.** The index shows the current state of all tasks
   across all days. It is the starting point for today's plan.

3. **Determine today's waves.** A typical day has 3 waves (morning,
   afternoon, evening), but you can have more or fewer depending on your
   team's capacity and the complexity of the work.

4. **Define tasks for each wave.** Each task should have:
   - A clear, testable description
   - A designated agent (e.g., `nova-dev`)
   - A designated engine (e.g., `Gemini CLI`)
   - A priority (🔴 high / 🟡 medium / 🟢 low)
   - Dependencies (which tasks must come first)

5. **Create the PLANO.md file** for the day under
   `planejamento-diario/YYYY-MM-DD/PLANO.md`.

6. **Create individual task files** (`task_01.md`, `task_02.md`, etc.)
   using the TASK.md template. Each file contains:
   - Required reading (links, docs, references)
   - Context explaining why the task exists
   - Detailed, numbered instructions
   - A checklist of binary items (done/not done)
   - Constraints (engine mandate, forbidden files)
   - A Conclusion section (to be filled by the agent later)

7. **Update INDICE.md** with the new day's tasks. Add a new section under
   `## DD/MM/YYYY — X/Y` listing all tasks with status ⬜.

### The PLANO.md Structure

```
# Daily Plan — Project Name

**Created by:** Orchestrator / Team Nova
**Date:** DD/MM/YYYY
**Purpose:** [Brief summary of the day]

---

## Resources

| Resource | Location | Purpose |
|----------|----------|---------|
| Repo     | ~/project | Code    |

---

## Summary

[2-3 sentences about the day's objectives]

---

## Waves

### Wave 1 — Morning 🔴

| Task | Description | Agent | Engine | Priority | Status |
|:----:|-------------|-------|--------|:--------:|:------:|
| task_01 | Fix login bug | nova-dev | Gemini | 🔴 | ⬜ |

**Objective:** All morning tasks complete.

---

### Wave 2 — Afternoon 🟡

---

## Dependencies

```
Wave 1 (Morning)
  task_01 → task_02

Wave 2 (Afternoon)
  task_03 depends on task_01
```

---

## Rules of Execution

1. **Default engine:** Gemini CLI
2. ...
```

### Planning Tips

- **One task = one responsibility.** If a task has multiple unrelated
  outputs, split it into separate tasks.
- **Mark dependencies clearly.** If task_03 needs task_01 to be done first,
  say so in the Dependencies section and in task_03's header.
- **Parallel waves are fine.** Wave 2 can start as soon as Wave 1's
  blocking tasks are done, even if Wave 1 has unstarted non-blocking tasks.
- **Never plan more than the team can execute.** A good rule of thumb is
  2-3 tasks per wave, 3 waves per day = 6-9 tasks max.

---

## Phase 2: APPROVE

**Owner:** Commander (human)
**Input:** `PLANO.md` shared in Slack (or reviewed via file)
**Output:** Verbal approval (or rejection with comments)

### What the Commander Does

1. **Read the PLANO.md.** Review every task, its description, its assigned
   agent, its engine, and its priority.

2. **Check dependencies.** Are they accurate? Will blocked tasks stall the
   day?

3. **Check engine assignments.** Is the right model assigned to each task?
   The default is Gemini 3.1 Pro for all coding, but some tasks may need
   Opus 4.7 (UI/design, complex audits) or another engine.

4. **Approve or reject.** Send a message in the operations channel:

```
✅ Plan approved. Proceed with delegation.
```

Or, if changes are needed:

```
⚠️ Plan needs revision: task_03 should use Opus, not Gemini.
   task_05 priority should be 🟢, not 🟡. Fix and re-submit.
```

### The Golden Rule of Approval

**Never implement without the green light.** Phase 3 must not start until
Phase 2 is complete. If the orchestrator starts delegating before approval,
it is a protocol violation.

### What Happens During Rejection

1. The orchestrator revises the plan per the Commander's comments
2. The orchestrator posts the updated `PLANO.md` or a diff
3. The Commander re-reviews and approves
4. Only then does Phase 3 begin

---

## Phase 3: DELEGATE

**Owner:** Orchestrator
**Input:** Approved `PLANO.md`
**Output:** One Slack thread per task with @mention + instructions

### What the Orchestrator Does

1. **Open the operations channel** (e.g., `#agent-ops-nova`).

2. **For each task, create a top-level message** (not a thread reply) with:
   - The agent @mention at the very start of the message
   - The task ID and title
   - A brief summary of the task
   - The engine mandate (which model to use)
   - Any critical constraints
   - A link to the task file or a copy of key instructions

3. **Each task gets its OWN top-level message** — never combine multiple
   tasks in one message. This creates separate threads automatically.

4. **Wait for acknowledgment.** The mentioned agent should respond with
   "Received" or start working. If no response within a reasonable time,
   check the agent's connectivity.

### Delegation Message Template

```
<@U0123456789> Task task_01: Fix login redirect bug

**Engine:** Gemini 3.1 Pro (DEFAULT — use this)
**Priority:** 🔴 HIGH — blocks task_02
**File:** planejamento-diario/YYYY-MM-DD/task_01.md

**Summary:**
The login redirect is sending users to /dashboard instead of
/home after authentication. Fix the redirect logic in the
auth controller.

**Checklist reminder:**
- Verify fix in staging before reporting
- Fill the Conclusion section in task_01.md
- Commit and push before reporting back

**Constraints:**
- Do NOT modify any database migration files
- Do NOT change the authentication middleware
- Only touch the redirect URL constant
```

### Engine Mandate Format

Every delegation message MUST include a clear engine directive. Use one of
these formats:

```
**Engine:** Gemini 3.1 Pro (DEFAULT)
**Engine:** Opus 4.7 (MANDATORY — UI/vision task)
**Engine:** OpenCode Go (exploration only)
**Engine:** DeepSeek V4 Pro (PROHIBITED without Commander order)
```

The "ORDEM ABSOLUTA" (absolute order) prefix is used for non-negotiable
engine assignments:

```
**ORDEM ABSOLUTA — Engine:** Gemini 3.1 Pro.
Do NOT switch. If you hit rate limits, split into subtasks.
```

---

## Phase 4: EXECUTE

**Owner:** Each assigned agent
**Input:** Slack delegation message + `task_XX.md` file
**Output:** Completed task with filled checklist, Conclusion section, commit

### What the Agent Does

1. **Acknowledge the task** by replying in the thread:
   ```
   Received. Starting task_01 now.
   ```

2. **Read the task file.** Open `planejamento-diario/YYYY-MM-DD/task_XX.md`
   and read the Required Reading, Context, Instructions, Checklist, and
   Constraints sections.

3. **Read referenced documents.** If the task requires reading a PRD,
   blueprint, or API doc, read those first. Do not start coding before
   understanding the context.

4. **Execute the instructions step by step.** Mark checkboxes as you go:
   ```
   - [x] Identified the redirect constant in auth controller
   - [x] Changed redirect URL from /dashboard to /home
   - [x] Tested in staging environment
   - [x] Verified no side effects on other routes
   ```

5. **Fill the Conclusion section** in the task file:
   ```markdown
   ## Conclusao

   **Agent:** nova-dev
   **Completed:** DD/MM/YYYY HH:MM
   **Engine used:** Gemini 3.1 Pro
   **Commit hash:** abc1234def5678
   **Observations:**
   Fixed the redirect URL constant in AuthController.php.
   The bug was a leftover from the previous sprint's routing
   refactor. All tests pass (47/47). No side effects detected.
   ```

6. **Commit and push:**
   ```bash
   git add -A
   git commit -m "fix: correct login redirect to /home"
   git push
   ```

7. **Report back in the Slack thread:**
   ```
   ✅ Task_01 complete.
   Commit: abc1234def5678
   Tests: 47/47 passing
   Observations: Fixed redirect URL in AuthController.php.
   Ready for audit.
   ```

### Execution Rules

- **Always commit before reporting.** A task with no commit hash is not
  done. If there is nothing to commit (e.g., research task), note this
  explicitly.
- **One agent per task.** If you are not the assigned agent, do not touch
  the task.
- **Engine compliance is mandatory.** Do not switch engines unless the
  Commander explicitly authorizes it.
- **Split if stuck.** If you hit engine rate limits (e.g.,
  RESOURCE_EXHAUSTED), split the task into smaller subtasks rather than
  switching models. If still failing after splitting, stop and report to
  the orchestrator.
- **Do not take corrective action without approval.** If you make a
  mistake, report it and wait. Do not revert, delete, or fix without the
  Commander's green light.

---

## Phase 5: AUDIT

**Owner:** Orchestrator (or designated auditor agent)
**Input:** Agent's completion report (Slack thread + commit)
**Output:** Verified task status in `INDICE.md` + `PLANO.md`

### What the Auditor Does

1. **Verify the commit.** Check that the commit hash exists:
   ```bash
   git log --oneline -5
   git show abc1234 --stat
   ```

2. **Review the changes.** Read the diff to verify the work is correct:
   ```bash
   git diff abc1234^..abc1234
   ```

3. **Read the task file.** Open the completed `task_XX.md` and check:
   - Are all checkboxes filled? (No [ ] left unchecked)
   - Is the Conclusion section filled with meaningful observations?
   - Are constraints respected? (No forbidden files touched)

4. **Verify the checklist items** by inspecting the actual code/files.

5. **If approved:**

   a. Update `PLANO.md` — mark the task's status as ✅
   b. Update `INDICE.md` — mark ✅ and 👁, add the commit hash
   c. Reply in the Slack thread:
      ```
      ✅ Audit passed for task_01.
      Commit abc1234 verified. All checkboxes filled.
      Constraints respected. INDICE.md updated.
      ```

6. **If rejected:**

   a. Reply in the Slack thread with specific issues:
      ```
      ⚠️ Audit failed for task_01:
      - Checklist item #3 not filled (staging test not done)
      - Commit hash missing in Conclusion section
      Please fix and re-submit.
      ```
   b. The agent fixes the issues and posts again
   c. Re-audit happens in the same thread (no new threads)

### Audit Checklist

```
[ ] Commit hash exists and is valid (git log --oneline)
[ ] Diff is correct and complete
[ ] All checkboxes in task file are filled ([x])
[ ] Conclusion section has meaningful content
[ ] Constraints were respected
[ ] No forbidden files were modified
[ ] Task file was committed (not just code)
```

---

## Phase 6: REPORT

**Owner:** Orchestrator
**Input:** All audited tasks
**Output:** Consolidated report + git commit

### What the Orchestrator Does

1. **Compile results from all tasks.** For each task:
   - Task ID and description
   - Status (✅ / ⚠️ / ❌)
   - Commit hash
   - Key observations

2. **Post a consolidated report** in the operations channel:

```
📊 Daily Report — Team Nova — DD/MM/YYYY

| Task     | Description          | Status | Commit    |
|----------|----------------------|--------|-----------|
| task_01  | Fix login redirect   | ✅     | abc1234   |
| task_02  | Update API docs      | ✅     | def5678   |
| task_03  | Refactor auth module  | ⚠️     | ghi9012   |
| task_04  | Add unit tests       | ❌     | —         |

**Summary:** 2/4 tasks complete. 1 audited. 1 failed (see thread).
**Pending:** task_04 blocked by upstream dependency.
**Next steps:** Re-assess task_04 in tomorrow's plan.
```

3. **Update INDICE.md** with the final X/Y counters and progress section.

4. **Commit everything:**
   ```bash
   git add -A
   git commit -m "daily: report for DD/MM/YYYY — X/Y tasks complete"
   git push
   ```

5. **Prepare handoff for the next day.** Document any pending items and
   blockers in the report message so the next day's Plan phase starts with
   full context.

---

## Complete Example Day — Team Nova

Let's walk through a full day for Team Nova using a fictional project
called "Project Atlas."

### Setting

- **Project:** Atlas — A microservices dashboard
- **Team:** Team Nova (Commander: Sarah, Orchestrator: @nova-orch, Agents:
  @nova-dev, @nova-audit)
- **Date:** 2026-06-10

### Phase 1: PLAN (08:00)

@nova-orch creates the plan based on yesterday's report. Yesterday had 3
pending items: a login bug, an incomplete API migration, and a documentation
gap.

```
# Daily Plan — Project Atlas

**Created by:** nova-orch / Team Nova
**Date:** 10/06/2026
**Purpose:** Resolve login redirect bug, finish API migration, fix docs

## Waves

### Wave 1 — Morning 🔴

| Task     | Description                        | Agent    | Engine   | Prio | Status |
|----------|------------------------------------|----------|----------|:----:|:------:|
| task_01  | Fix login redirect bug             | nova-dev | Gemini   | 🔴   | ⬜     |
| task_02  | Complete API migration v2          | nova-dev | Gemini   | 🔴   | ⬜     |

### Wave 2 — Afternoon 🟡

| Task     | Description                        | Agent      | Engine | Prio | Status |
|----------|------------------------------------|------------|--------|:----:|:------:|
| task_03  | Update API documentation           | nova-audit | Opus   | 🟡   | ⬜     |
| task_04  | Audit login fix + migration        | nova-audit | Opus   | 🟡   | ⬜     |

## Dependencies

task_02 depends on task_01 (migration assumes login works)
task_04 depends on task_01 + task_02
task_03 is independent
```

@nova-orch creates `task_01.md` through `task_04.md` and updates INDICE.md
with 4 new tasks.

### Phase 2: APPROVE (08:15)

@nova-orch posts the plan in `#agent-ops-nova`:

```
📋 Daily plan for 10/06/2026 ready for review:
4 tasks across 2 waves.

Wave 1 (🔴 Morning):
- task_01: Fix login redirect bug (nova-dev, Gemini)
- task_02: Complete API migration v2 (nova-dev, Gemini)

Wave 2 (🟡 Afternoon):
- task_03: Update API documentation (nova-audit, Opus)
- task_04: Audit login fix + migration (nova-audit, Opus)

Dependencies: task_02 → task_01, task_04 → task_01 + task_02
```

**Sarah (Commander):**
```
✅ Plan approved. Good priorities. Proceed.
```

### Phase 3: DELEGATE (08:20)

@nova-orch posts 4 top-level messages in the channel, one per task:

```
<@U0123456789> Task task_01: Fix login redirect bug

**Engine:** Gemini 3.1 Pro (DEFAULT)
**Priority:** 🔴 HIGH
**File:** planejamento-diario/2026-06-10/task_01.md
...

<@U9876543210> Task task_02: Complete API migration v2
...

<@U5555555555> Task task_03: Update API documentation
...

<@U5555555555> Task task_04: Audit login fix + migration
...
```

Each message creates a separate thread automatically.

### Phase 4: EXECUTE (08:30 onwards)

In thread for task_01:
```
nova-dev: Received. Starting task_01 now.
nova-dev: ✅ Task_01 complete.
  Commit: aabbccdd
  Tests: 47/47 passing
  Observations: Fixed redirect URL in AuthController.php.
  Ready for audit.
```

In thread for task_02:
```
nova-dev: Starting task_02.
nova-dev: ✅ Task_02 complete.
  Commit: eeff0011
  Migration ran successfully. No data loss.
  Ready for audit.
```

Meanwhile, task_03 (documentation) runs in parallel since it has no
dependencies:
```
nova-audit: Received task_03. Starting docs update.
nova-audit: ✅ Task_03 complete.
  Commit: 11223344
  All API endpoints documented. Migration notes added.
  Ready for audit (or skip — no code changed).
```

### Phase 5: AUDIT (after execution)

@nova-orch audits task_01:
```
Verifying commit aabbccdd...
Diff looks correct. Redirect constant changed from /dashboard to /home.
Checklist complete. Constraints respected.

✅ Audit passed for task_01.
Committing audit record.
```

@nova-orch updates INDICE.md:
```
## 10/06/2026 — 1/4

| Task | Description | Wave | ✅ | 👁 | Commit |
|------|-------------|:----:|---|---|--------|
| task_01 | Fix login redirect bug | 1 | ✅ | ✅ | aabbccdd |
| task_02 | Complete API migration v2 | 1 | ⬜ | ⬜ | — |
| task_03 | Update API documentation | 2 | ⬜ | ⬜ | — |
| task_04 | Audit login fix + migration | 2 | ⬜ | ⬜ | — |
```

Audit continues for task_02 and task_03.

### Phase 6: REPORT (end of day)

```
📊 Daily Report — Team Nova — 10/06/2026

| Task     | Description                   | Status | Commit    |
|----------|-------------------------------|--------|-----------|
| task_01  | Fix login redirect bug        | ✅ 👁  | aabbccdd  |
| task_02  | Complete API migration v2     | ✅ 👁  | eeff0011  |
| task_03  | Update API documentation      | ✅ 👁  | 11223344  |
| task_04  | Audit login fix + migration   | ✅ 👁  | —         |

**Summary:** 4/4 tasks complete. 4/4 audited. 0 blockers.
**Pending for tomorrow:** None. Sprint on track.

**Final counters:** INDICE.md: 4/4 ✅, 4/4 👁
**Commits:** 3 new commits pushed.
```

Final git push and the day is done. Tomorrow's plan starts from this report.

---

## Thread Rules

Thread discipline is critical to keeping the workflow readable and
auditable. Violations cause confusion, lost context, and missed
communications.

### Rule 1: One Task = One Thread

Each delegation message is a top-level post. Every reply about that task
goes in **that** thread. Never create a new thread for the same task,
even for corrections, re-audits, or supplements.

```
✅ Correct:

@nova-dev task_01: Fix login bug    ← top-level post
├── nova-dev: Received              ← thread reply
├── nova-dev: Commit abc123...      ← thread reply
├── nova-orch: Audit passed         ← thread reply
└── nova-dev: Thanks                ← thread reply

❌ Wrong:

@nova-dev task_01: Fix login bug    ← top-level post
nova-dev: Received                  ← in channel (not thread!)
nova-dev: Commit abc123...          ← in channel (not thread!)
nova-orch: @nova-dev please audit   ← new top-level post (wrong!)
```

### Rule 2: Only the Orchestrator Posts Outside Threads

The orchestrator is the only role that posts top-level messages in the
operations channel. Agents always reply within their assigned thread. The
Commander may also post top-level messages (approvals, lockdowns,
directives).

### Rule 3: No Tables in Delegation Messages

Pipe characters (`|`) break the Slack mention parser when used inside a
delegation message. Use plain text or bullet points instead of tables when
instructing an agent.

```
❌ Wrong:
| Field | Value |
|-------|-------|
| Engine | Gemini |

✅ Correct:
**Engine:** Gemini
```

### Rule 4: Threads Are the Source of Truth

Every decision, clarification, and status update about a task lives in its
thread. Do not discuss tasks in DMs, in other channels, or in separate
threads. If someone needs to reference a task later, they look at the
thread.

---

## Error Recovery Procedures

Despite the rigorous structure, things can go wrong. Here is the playbook
for each failure mode.

### Agent Reports a False Commit Hash

**Symptom:** Agent says "Commit abc123" but `git log` shows no such commit.

**Procedure:**
1. The auditor replies in thread: "⚠️ Commit abc123 not found in git log."
2. The agent verifies and re-commits.
3. The agent posts the correct hash in the same thread.
4. The auditor re-verifies.

**Prevention:** Always run `git log --oneline -1` before reporting.

### Thread Broken (Agent Replies in Channel)

**Symptom:** An agent posts outside their thread, mixing up the channel.

**Procedure:**
1. The orchestrator posts: "⚠️ @agent, please reply in your thread:
   https://link-to-thread"
2. The orchestrator deletes the misplaced message (if possible) or ignores
   it.
3. No new thread is created.

### Engine Failure (Rate Limit / Exhausted)

**Symptom:** Agent gets RESOURCE_EXHAUSTED or similar engine error.

**Procedure:**
1. The agent reports the error in the thread.
2. The agent splits the task into smaller subtasks and continues with the
   same engine.
3. If it fails again, the agent stops and reports.
4. The orchestrator decides whether to wait, reassign, or escalate.

**Never switch engines** without Commander approval.

### Lockdown (Red Signal)

**Symptom:** Commander posts "LOCKDOWN" or "sinal vermelho" in the channel.

**Procedure:** See [05-SLACK-PROTOCOL.md](05-SLACK-PROTOCOL.md) for the
complete lockdown protocol. In short:
1. All agents freeze immediately.
2. No new actions, commits, or messages.
3. Wait for the "LOCKDOWN LIFTED" signal from the Commander.
4. Resume from where you stopped, report any partial work.

### Plan Needs Mid-Day Revision

**Symptom:** The Commander realizes a task priority changed, or a blocker
emerges.

**Procedure:**
1. The Commander posts the revision in the channel.
2. The orchestrator updates PLANO.md and informs affected agents in their
   threads.
3. Already-completed tasks are not re-opened unless the revision requires
   rework.
4. New tasks get new delegation messages and new threads.

### Agent Unresponsive

**Symptom:** An agent does not acknowledge a delegation message within
15 minutes.

**Procedure:**
1. The orchestrator checks if the agent's Hermes instance is running.
2. If the agent is down, the orchestrator reassigns the task to another
   agent or escalates to the Commander.
3. The original thread is updated with the reassignment note.

---

## Daily Report Template

Use this template for the Phase 6 report. Post it in the operations
channel and commit it to your daily folder for archival.

```markdown
📊 Daily Report — {{TEAM_NAME}} — {{DATE}}

| Task     | Description                    | Status | Commit    |
|----------|--------------------------------|--------|-----------|
| task_01  | {{SHORT_DESCRIPTION}}          | {{✅/⚠️/❌}} | {{HASH}} |
| task_02  | {{SHORT_DESCRIPTION}}          | {{✅/⚠️/❌}} | {{HASH}} |
| ...      | ...                            | ...    | ...       |

**Summary:**
{{X}}/{{Y}} tasks complete. {{A}} audited. {{B}} failed.
{{C}} blockers remaining.

**Pending items for tomorrow:**
- {{ITEM_1}}
- {{ITEM_2}}

**Final counters:** INDICE.md: {{X}}/{{Y}} ✅, {{A}}/{{Y}} 👁
**Commits:** {{N}} new commits pushed today.

**Notable observations:**
- {{OBSERVATION_1}}
- {{OBSERVATION_2}}
```

---

## Summary — The 6 Golden Rules of the Cycle

1. **Never skip phases.** Plan → Approve → Delegate → Execute → Audit →
   Report. In that order.

2. **Never delegate without approval.** Phase 3 cannot start until Phase 2
   is complete.

3. **One task = one thread.** Every task gets its own top-level message and
   its own thread. No exceptions.

4. **Always commit before reporting.** A task without a commit hash is not
   done. Verify with `git log`.

5. **Update IMMEDIATELY after each audit.** INDICE.md and PLANO.md must
   reflect reality at all times. Do not batch updates.

6. **Never take corrective action without the Commander's green light.**
   Made a mistake? Report and wait.
