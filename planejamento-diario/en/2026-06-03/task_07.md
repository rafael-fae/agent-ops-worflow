# Task 07 — Docs: initial setup + daily cycle + Slack protocol

**Wave:** 3 (Documentation)
**Priority:** 🟡
**Tool:** Gemini CLI
**Depends on:** task_06

---

## Context

The main workflow documentation needs to be complete and didactic.
We will create 3 fundamental documents in the `docs/` folder.

---

## Instructions

Create in `agent-ops-workflow/docs/`:

### 1. `docs/01-SETUP-INITIAL.md`

Step-by-step guide to configure the workflow in a new project:

**Content:**
- Prerequisites (Hermes Agent installed, CLI configured)
- Clone the repository
- Run `setup-workflow.sh`
- Customize placeholders in the project
- Configure Hermes agents (config.yaml, AGENTS.md)
- Configure Slack channels (app creation, tokens, home_channel)
- Test with a simple task

**Include:**
- Exact commands for each step
- config.yaml examples/screenshots
- Post-setup verification checklist

---

### 2. `docs/02-DAILY-CYCLE.md`

The heart of the workflow — the 6 phases of the daily cycle:

| Phase | What happens | Who does it |
|:----:|---------------|:--------:|
| 1 — Plan | Create PLAN.md + tasks + INDEX | Orchestrator |
| 2 — Approve | Review and authorize | Commander (human) |
| 3 — Delegate | Send in Slack with mentions | Orchestrator |
| 4 — Execute | Run task, fill checklist | Agent |
| 5 — Audit | Verify commits, diff, report | Orchestrator |
| 6 — Report | Consolidated table + verdict | Orchestrator |

**Content:**
- Detailed explanation of each phase
- Slack message template (with placeholders)
- Real (anonymized) example of a full day
- ASCII flow diagram
- Thread rules (one task = one thread)
- What to do when something goes wrong

---

### 3. `docs/03-SLACK-PROTOCOL.md`

Slack communication rules for the multi-agent team:

**Content:**
- Message hierarchy (who can post in channel vs. thread)
- Mention format `<@USER_ID>` (with explanation of why it's mandatory)
- Delegation template (with examples)
- Silence rule (only respond when mentioned)
- Lockdown protocol (commander's red signal)
- Best practices (don't open duplicate threads)
- Troubleshooting (mention didn't work, broken thread, etc.)

---

## Checklist

- [x] docs/01-SETUP-INITIAL.md created (English) — 697 lines
- [x] docs/02-DAILY-CYCLE.md created (English) — 900 lines
- [x] docs/03-SLACK-PROTOCOL.md created (English) — 817 lines
- [x] All documents with practical examples
- [x] Cross-links between documents working
- [x] No references to Roshar/Oeste Gestão/Rafael

---

## Constraints

- 100% generic content — any team should be able to follow
- Examples use placeholders (__TIME__, __ORCHESTRATOR__, etc.)
- Didactic tone — assume the reader is new to Hermes

---

## Conclusion

**Agent:** Dalinar (via subagents)
**Completed on:** 06/03/2026 ~11:00
**Engine used:** deepseek-v4-flash (subagent)
**Notes:**
- 01-SETUP-INITIAL.md — 697 lines, complete setup guide (prerequisites, clone, run setup-workflow.sh, configure agents, Slack, cron)
- 02-DAILY-CYCLE.md — 900 lines, 6 detailed phases with ASCII flowchart, full "Team Nova" example
- 03-SLACK-PROTOCOL.md — 817 lines, message hierarchy, mention format, lockdown protocol, troubleshooting
- All in ENGLISH (US), no references to Roshar/Rafael/Oeste Gestão
- .tpl templates also converted to English
