# Task 05 — Create generic automation scripts

**Wave:** 2 (Sanitization)
**Priority:** 🔴
**Tool:** Gemini CLI
**Depends on:** task_02

---

## Context

We have automation scripts (cron, key rotation, etc.) that are useful for
any multi-agent team. We need to create generic, documented versions.

---

## Instructions

Create in `agent-ops-workflow/scripts/`:

### 1. `scripts/setup-workflow.sh`

Initial setup script that:
- Creates the `planejamento-diario/` structure in the user's project
- Copies templates to the current day's folder
- Creates the initial INDEX.md
- Allows team/project name customization via variables

```bash
# Usage:
# ./scripts/setup-workflow.sh ~/my-project "My Team" "My Project"
```

### 2. `scripts/gerar-plano-diario.sh`

Cron job script (automatic execution):
- Reads PLAN.md.tpl template
- Replaces placeholders with current date
- Creates YYYY-MM-DD/ folder
- Generates PLAN.md + skeleton tasks
- Ideal for scheduling at 05:00 every day

```bash
# Suggested cron:
# 0 5 * * * /path/scripts/gerar-plano-diario.sh ~/project
```

### 3. `scripts/validate-workflow.sh`

Validation/audit script:
- Checks if INDEX.md exists and is up-to-date
- Checks if tasks have completed checklists
- Checks if PLAN.md reflects actual statuses
- Workflow health report

```bash
# Usage:
# ./scripts/validate-workflow.sh ~/my-project
# → "3 tasks without completed checklist" / "INDEX.md outdated"
```

### 4. `scripts/rotate-key.sh` (generic)

Key rotation script (based on our existing one):
- Generates new SSH/GPG key
- Updates config
- Backs up old key

---

## Checklist

- [x] setup-workflow.sh created with configurable variables
- [x] gerar-plano-diario.sh created with cron support
- [x] validate-workflow.sh created with report
- [x] Generic rotate-key.sh created
- [x] Scripts commented in Portuguese
- [x] All with `set -euo pipefail` and error handling
- [x] `scripts/README.md` with usage instructions for each script

---

## Constraints

- NO references to Rafael, Roshar, Oeste Gestão
- Explanatory comments in Portuguese
- Error handling in all scripts

---

## Conclusion

**Agent:** Dalinar (via subagents)
**Completed on:** 06/03/2026 ~10:40
**Engine used:** deepseek-v4-flash (subagent)
**Notes:**
- setup-workflow.sh — 12.3KB, interactive + env vars, structure creation
- gerar-plano-diario.sh — 10.2KB, cron-ready, --tasks=N, --force, logging
- validate-workflow.sh — 14.7KB, 9 checks, --fix, exit codes
- rotate-key.sh — 10.5KB, ed25519, backup, --host, --show
- scripts/README.md — 8.3KB, complete documentation of all scripts
- All pass bash -n (syntax check), set -euo pipefail
- Zero references to Roshar/Rafael/Oeste Gestão
