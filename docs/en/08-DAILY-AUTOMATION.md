# Daily Automation Flows

> Complete and detailed guide to ALL automation flows — both at the shell script
> level and the Hermes Agent level — for Team Nova's daily routine.
> Every command here is copy-ready and ready to use.

---

## Summary

1. [Overview — The 7 Automation Flows](#1-overview--the-7-automation-flows)
2. [Flow 1 — Automatic Daily Plan Generation](#2-flow-1--automatic-daily-plan-generation)
3. [Flow 2 — Task Delegation](#3-flow-2--task-delegation)
4. [Flow 3 — Execution, Reporting and Commit](#4-flow-3--execution-reporting-and-commit)
5. [Flow 4 — Auditing and Automatic Validation](#5-flow-4--auditing-and-automatic-validation)
6. [Flow 5 — Consolidated Daily Report](#6-flow-5--consolidated-daily-report)
7. [Flow 6 — Git Sync and Backup](#7-flow-6--git-sync-and-backup)
8. [Flow 7 — Security and Maintenance](#8-flow-7--security-and-maintenance)
9. [Complete Automation Map](#9-complete-automation-map)
10. [Automation Checklist](#10-automation-checklist)

---

## 1. Overview — The 7 Automation Flows

The Agent Ops Workflow has **7 automation flows** that operate at 3 distinct
levels:

| # | Flow | Shell Level | Hermes (AI) Level | When | Description |
|:-:|-------|:-----------:|:------------------:|:------:|-----------|
| 1 | Daily Plan Generation | `gerar-plano-diario.sh` + cron | `hermes run --skills planejamento-diario` + native cron job | 05:00 | Creates the day's structure with PLANO.md and skeleton tasks |
| 2 | Task Delegation | Slack curl script | `hermes run --prompt "Delegate pending tasks"` | 08:00 (post-approval) | Assigns tasks to agents via Slack |
| 3 | Execution, Reporting and Commit | `git add/commit/push` | Hermes Agent executes and reports | Continuous | Agent executes task, fills checklist, commits, reports |
| 4 | Auditing and Validation | `validate-workflow.sh` + cron | `hermes run --skills execucao-wave-auditoria` | 22:00 | Verifies integrity, checkbox consistency and indexes |
| 5 | Consolidated Report | Shell compilation script | `hermes run --prompt "Generate daily report"` | 23:00 | Compiles status, generates markdown, publishes on Slack |
| 6 | Git Sync and Backup | Automatic `git push` + `rotate-key.sh` | — (operational only) | 23:30 | Daily push, configuration backup |
| 7 | Security and Maintenance | `rotate-key.sh` + log cleanup | `hermes cronjob` management | Periodic | Key rotation, cleanup, skill updates |

---

## 2. Flow 1 — Automatic Daily Plan Generation

### Level 1: Shell Script (`gerar-plano-diario.sh`)

**File:** `scripts/gerar-plano-diario.sh`

This script is the backbone of automation. It reads the `PLANO.md` template,
replaces placeholders with the current date, creates the `YYYY-MM-DD/` folder and
generates a `PLANO.md` with an empty structure (editable waves).

#### Basic command

```bash
# Generates the plan for today in the project directory
./scripts/gerar-plano-diario.sh ~/my-project

# With custom number of tasks per wave
./scripts/gerar-plano-diario.sh ~/my-project --tasks=8

# Force overwrite if the day's folder already exists
./scripts/gerar-plano-diario.sh ~/my-project --force
```

#### Replaced placeholders

| Placeholder | Source | Example |
|-------------|-------|---------|
| `__DATA__` | `date +%d/%m/%Y` | 03/06/2026 |
| `__NOME_DO_PROJETO__` | `WORKFLOW_PROJECT_NAME` or INDICE.md | Atlas Project |
| `__NOME_DO_TIME__` | `WORKFLOW_TEAM_NAME` | Team Nova |
| `__COMANDANTE__` | Fixed "Commander" | Commander |

#### Generated structure (template mode)

```
~/my-project/planejamento-diario/
└── 2026-06-10/
    └── PLANO.md
```

The generated `PLANO.md` contains:

```
# Execution Plan — Atlas Project

**Created by:** gerar-plano-diario.sh / Team Nova
**Date:** 10/06/2026

---

## Waves

### Wave 1 — Morning 🔴

| Task | Description | Agent | Engine | Priority | Status |
|:----:|-----------|:------:|:-----:|:----------:|:------:|
| task_01 | — | — | — | 🔴 | ⬜ |
...

### Wave 2 — Afternoon 🟡
...

### Wave 3 — Evening 🟢
...

## At the end of the day

- [ ] 0/15 tasks completed and audited
- [ ] INDICE.md updated with day's status
- [ ] All commits made and push performed
```

#### Exact cron command

```bash
# Edit crontab
crontab -e

# Add this line:
0 5 * * * /Users/your-user/Dev/agent-ops-workflow/scripts/gerar-plano-diario.sh \
  /Users/your-user/Dev/my-project \
  >> /Users/your-user/Dev/my-project/planejamento-diario/cron.log 2>&1
```

#### Environment variables for cron

Cron runs with a minimal environment. You need to set these variables:

```bash
# Recommended format in crontab (all on one line):
WORKFLOW_TEAM_NAME="Team Nova" WORKFLOW_PROJECT_NAME="Atlas Project" \
  0 5 * * * /path/scripts/gerar-plano-diario.sh ~/my-project \
  >> ~/my-project/planejamento-diario/cron.log 2>&1
```

Or use a wrapper script that loads the variables first:

```bash
#!/bin/bash
# ~/scripts/wrapper-plano-diario.sh
export WORKFLOW_TEAM_NAME="Team Nova"
export WORKFLOW_PROJECT_NAME="Atlas Project"
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

cd /Users/your-user/Dev/agent-ops-workflow
./scripts/gerar-plano-diario.sh /Users/your-user/Dev/my-project --tasks=5 \
  >> /Users/your-user/Dev/my-project/planejamento-diario/cron.log 2>&1
```

#### Logs

The script automatically appends to `cron.log`:

```bash
# Monitor the log
tail -f ~/my-project/planejamento-diario/cron.log

# Example output
[2026-06-10 05:00:01] Plan generated: /Users/.../planejamento-diario/2026-06-10/PLANO.md
  Project: Atlas Project | Team: Team Nova
  Tasks per wave: 5 | Force: false
```

---

### Level 2: Hermes Orchestrator (NEW)

Instead of relying solely on the shell script (which generates a generic structure),
you can use the **Hermes Orchestrator agent itself** to generate the plan
with AI — with context, smart tasks and real dependencies.

#### Basic command

```bash
hermes --profile orquestrador run \
  --skills planejamento-diario \
  --prompt "Generate today's daily plan for Team Nova in the Atlas Project"
```

#### Full prompt to generate daily plan

```bash
hermes --profile orquestrador run \
  --skills planejamento-diario \
  --prompt '<USER>
Generate the daily plan for today for the Atlas Project.

CONTEXT:
- Team: Nova
- Project: Atlas (microservices dashboard)
- Commander: Alex
- Yesterday report: 4/4 tasks completed, all audited
- Yesterday's pending items: None
- Today's priority: Implement 2FA authentication, update API documentation, fix timeout bug in reporting module

EXPECTED OUTPUT:
1. Create the YYYY-MM-DD/ folder in planejamento-diario/
2. Generate PLANO.md with 3 waves (Morning/Afternoon/Evening)
3. Each wave with 2-3 tasks containing: task_ID, description, agent, engine, priority
4. Create individual files task_01.md, task_02.md, etc.
5. Update INDICE.md with the new tasks

RULES:
- Default engine: Gemini 3.1 Pro
- DeepSeek PROHIBITED without Commander authorization
- Documentation in en-US
- Tasks must have clear dependencies
</USER>'
```

#### How to schedule in cron

```bash
# In crontab:
0 5 * * * cd /Users/your-user/Dev/agent-ops-workflow && \
  hermes --profile orquestrador run \
    --skills planejamento-diario \
    --prompt "Generate today's daily plan for Team Nova in the Atlas Project. Consider the previous day's report in planejamento-diario/INDICE.md as context." \
    >> /Users/your-user/Dev/my-project/planejamento-diario/hermes-plan.log 2>&1
```

#### Hermes Level vs Shell Script Advantages

| Feature | Shell Script | Hermes Agent (AI) |
|----------------|:------------:|:------------------:|
| Structure generation | ✅ Yes | ✅ Yes |
| Smart tasks | ❌ Generic skeleton | ✅ Real project context |
| Dependencies between tasks | ❌ No | ✅ Inferred from previous report |
| INDICE.md update | ❌ Partial | ✅ Complete with counters |
| Creation of individual task_XX.md | ❌ No | ✅ Yes, with real briefings |
| Respects yesterday's pending items | ❌ No | ✅ Yes, reads from report |
| Requires template | ✅ Yes | ✅ Yes (but uses AI to fill) |
| Speed | ✅ Instant | ⚠️ 10-30 seconds |
| Unsupervised generation | ✅ Safe | ⚠️ May hallucinate tasks |

**Recommendation:** Use the shell script as a daily fallback (cron 05:00) and the
Hermes agent when Commander Alex wants a more refined plan.

---

### Level 3: Hermes Native Cron Job (NEW)

Hermes Agent has a native cron job system. You can create a job
that runs the `planejamento-diario` skill automatically every day at 05:00.

#### Create the cron job

```bash
hermes --profile orquestrador cronjob create \
  --name "plano-diario-5am" \
  --schedule "0 5 * * *" \
  --skills planejamento-diario \
  --prompt "Generate today's daily plan for Team Nova in the Atlas Project. Use the previous day's report in planejamento-diario/INDICE.md as context. Create PLANO.md with 3 waves, individual tasks and update INDICE.md."
```

#### Check active cron jobs

```bash
# List all cron jobs
hermes --profile orquestrador cronjob list

# View details of a specific job
hermes --profile orquestrador cronjob show plano-diario-5am
```

#### Pause / Resume / Remove

```bash
# Pause (without removing)
hermes --profile orquestrador cronjob pause plano-diario-5am

# Reactivate
hermes --profile orquestrador cronjob resume plano-diario-5am

# Permanently remove
hermes --profile orquestrador cronjob delete plano-diario-5am
```

#### ⚠️ Attention with native cron

As documented in the `planejamento-diario` skill:

1. **Local time:** Cron uses the machine's LOCAL time, not UTC.
2. **Generation ≠ Delegation:** Cron generates `.md` files but does **NOT delegate**
   on Slack. Delegation is still manual (or semi-automatic via Flow 2).
3. **Recovery plan:** If the previous day didn't execute, cron may generate
   an outdated "recovery" plan. Always verify and clean up before
   proceeding.

---

## 3. Flow 2 — Task Delegation

### Manual (via Slack)

This is the flow documented in `03-PROTOCOLO-SLACK.md`. The Orchestrator posts
each task as a top-level message in the `#agent-ops-nova` channel,
with `<@USER_ID>` at the beginning and the complete delegation template.

**Message template:**

```
<@U0123456789> Task task_01: Fix login redirect bug

**Engine:** Gemini 3.1 Pro (DEFAULT)
**Priority:** 🔴 HIGH — blocks task_02
**File:** planejamento-diario/2026-06-10/task_01.md

**Summary:
The login redirect is sending users to /dashboard instead of
/home after authentication. Fix the redirect logic.

**Main instructions:**
1. Find the redirect constant in AuthController.php
2. Change the value from '/dashboard' to '/home'
3. Test on staging with curl
4. Run the complete test suite

**Checklist reminder:**
- Verified fix on staging
- Ran complete test suite
- Filled in the Conclusion section in task_01.md
- Committed and pushed

**Restrictions:**
- DO NOT modify database migration files
- DO NOT alter the authentication middleware
- Only touch the redirect URL constant
```

---

### Semi-automatic (via shell script with Slack webhook)

You can create a script that reads the day's `PLANO.md` and generates
delegation messages automatically via the Slack webhook.

#### Example script: `delegar-tasks.sh`

```bash
#!/bin/bash
# scripts/delegar-tasks.sh — Semi-automatic task delegation to Slack
# =============================================================================
# Reads PLANO.md, extracts tasks with status ⬜ and sends delegation messages
# via Slack webhook, one per task.
#
# Usage: ./scripts/delegar-tasks.sh <project-directory> [date YYYY-MM-DD]
# =============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
DATA="${2:-$(date +%Y-%m-%d)}"
PLANO="$TARGET_DIR/planejamento-diario/$DATA/PLANO.md"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

if [ ! -f "$PLANO" ]; then
    echo "[ERROR] PLANO.md not found: $PLANO"
    exit 1
fi

if [ -z "$WEBHOOK_URL" ]; then
    echo "[ERROR] Set SLACK_WEBHOOK_URL as environment variable."
    exit 1
fi

echo "[INFO] Reading tasks from $PLANO..."

# Extract task lines with status ⬜ (not completed)
grep '| task_' "$PLANO" | grep '⬜' | while IFS='|' read -r _ task_id desc agent engine priority status _; do
    task_id="$(echo "$task_id" | xargs)"
    desc="$(echo "$desc" | xargs)"
    agent="$(echo "$agent" | xargs)"
    engine="$(echo "$engine" | xargs)"
    priority="$(echo "$priority" | xargs)"

    echo "[INFO] Delegating $task_id: $desc to $agent..."

    # Build JSON payload
    payload=$(cat <<JSONEOF
{
    "channel": "${SLACK_HOME_CHANNEL:-C0123456789}",
    "text": "<@${agent}> Task ${task_id}: ${desc}\n\n**Engine:** ${engine} (DEFAULT)\n**Priority:** ${priority}\n**File:** planejamento-diario/${DATA}/${task_id}.md\n\n**Summary:**\n${desc}\n\n**Instructions:**\nRefer to the task file for complete instructions.\n\n**Reminder:**\n- Fill in the Conclusion section after executing\n- Commit + push before reporting\n- Report in this thread when done",
    "unfurl_links": false
}
JSONEOF
)

    # Send via webhook
    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL"
    echo ""
done

echo "[OK] Delegation completed."
```

**How to use:**

```bash
# Configure webhook
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00.../B00.../xxx"
export SLACK_HOME_CHANNEL="C0123456789"

# Delegate tasks from today's plan
./scripts/delegar-tasks.sh ~/my-project
```

**Limitations of the semi-automatic approach:**

- Requires mapping agent names to Slack IDs
- Does not validate whether the Commander approved the plan
- Messages are generic (no detailed instructions)
- Does not create separate threads (uses simple `text`, not `blocks`)

---

### Automatic (via Hermes Orchestrator)

The Hermes Orchestrator can delegate tasks automatically by reading the day's `PLANO.md`
and sending standardized messages on Slack with AI.

#### Command

```bash
hermes --profile orquestrador run \
  --prompt "Delegate the pending tasks from today's plan in the Atlas Project.
    Read the file planejamento-diario/$(date +%Y-%m-%d)/PLANO.md.
    For each task with status ⬜, create a delegation message on Slack
    using the standard template with @mention of the agent, engine, priority and
    instructions.
    Rules:
    - One top-level message per task (creates separate threads)
    - ABSOLUTE ORDER: Gemini 3.1 Pro engine for all
    - Include the full path of the task file
    - Publish in channel #agent-ops-nova"
```

**Advantages of Hermes automation:**

1. Reads the real context from `PLANO.md` with AI
2. Generates personalized instructions for each task
3. Resolves agent names automatically (if configured in AGENTS.md)
4. Creates separate threads correctly
5. Can validate whether the plan was approved (Phase 2) before delegating

**When to use each level:**

| Situation | Level |
|----------|-------|
| Small team (1-3 tasks/day) | Manual |
| Medium team (4-8 tasks/day) | Semi-automatic (webhook script) |
| Large team (8+ tasks/day) | Automatic (Hermes) |
| Commander wants to review each delegation | Manual |
| Commander trusts the Orchestrator | Automatic |

---

## 4. Flow 3 — Execution, Reporting and Commit

This flow is executed by the **assigned agent** for each task. The agent:

1. Confirms receipt in the Slack thread
2. Reads the `task_XX.md` file
3. Executes the instructions
4. Fills the checklist (`[x]`)
5. Fills the Conclusion section
6. Commits + pushes
7. Reports in the thread

### Execution checklist (for the agent)

```markdown
## Checklist

- [ ] Read the "Required Reading" section (PRD, Blueprint, docs)
- [ ] Read the complete task_XX.md file
- [ ] Configured the required environment/engine
- [ ] Executed each step of the instructions
- [ ] Tested the result (staging, unit tests)
- [ ] Filled in the Conclusion section below
- [ ] Committed (`git add -A && git commit -m "..."`)
- [ ] Pushed (`git push`)
- [ ] Reported in the Slack thread
```

### Conclusion section (to be filled by the agent)

```markdown
## Conclusion

**Agent:** nova-dev
**Completed on:** 10/06/2026 14:30
**Engine used:** Gemini 3.1 Pro
**Commit hash:** aabbccdd11223344
**Notes:
Fixed the URL redirect constant in AuthController.php.
The bug was leftover from the routing refactor of the previous sprint.
All tests pass (47/47). No side effects detected.
```

### Commit automation (message template)

```bash
# Semantic commit in English
git add -A
git commit -m "feat: implement 2FA authentication in login module"
git push
```

**Semantic commit pattern:**

| Prefix | Meaning |
|---------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `refactor:` | Refactoring |
| `test:` | Tests |
| `chore:` | Maintenance |
| `audit:` | Audit record |
| `daily:` | Daily report / index |

### Post-task validation script

The agent can run a quick validation before reporting:

```bash
#!/bin/bash
# valida-task.sh — Quick validation before reporting
# Usage: ./valida-task.sh ~/my-project task_01

TARGET_DIR="${1:-.}"
TASK="${2:-}"
DATA=$(date +%Y-%m-%d)

if [ -z "$TASK" ]; then
    echo "Usage: $0 <directory> <task_id>"
    exit 1
fi

TASK_FILE="$TARGET_DIR/planejamento-diario/$DATA/$TASK.md"

echo "=== Post-task validation ==="
echo ""

# Check if task file exists
if [ ! -f "$TASK_FILE" ]; then
    echo "[ERROR] File $TASK_FILE not found."
    exit 1
fi

# 1. Check checkboxes
CHECKBOXES=$(grep -cP '^\s*-\s*\[[ x]\]' "$TASK_FILE" 2>/dev/null || true)
FILLED=$(grep -cP '^\s*-\s*\[x\]' "$TASK_FILE" 2>/dev/null || true)
echo "[CHECKBOX] $FILLED/$CHECKBOXES filled"

# 2. Check Conclusion section
if grep -q "^## Conclusion" "$TASK_FILE" 2>/dev/null; then
    echo "[CONCLUSION] Conclusion section found."
    HASH=$(grep "^\\*\\*Commit hash:\\*\\*" "$TASK_FILE" 2>/dev/null | head -1)
    echo "  $HASH"
else
    echo "[WARNING] Conclusion section not found!"
fi

# 3. Check actual commit
if [ -d "$TARGET_DIR/.git" ]; then
    LAST_COMMIT=$(cd "$TARGET_DIR" && git log --oneline -1 2>/dev/null || true)
    echo "[GIT] Last commit: $LAST_COMMIT"
    
    # Check if there are pending pushes
    AHEAD=$(cd "$TARGET_DIR" && git status 2>/dev/null | grep -c "Your branch is ahead" || true)
    if [ "$AHEAD" -gt 0 ]; then
        echo "[GIT] ⚠️ Push pending! Run 'git push' before reporting."
    else
        echo "[GIT] ✅ Push is up to date."
    fi
fi

echo ""
echo "=== End of validation ==="
```

---

## 5. Flow 4 — Auditing and Automatic Validation

### Shell Level: `validate-workflow.sh`

**File:** `scripts/validate-workflow.sh`

This script checks the integrity of the entire `planejamento-diario/` structure:

1. Whether the basic structure exists
2. Whether `INDICE.md` exists and is consistent
3. Whether the X/Y counters in INDICE.md match the actual tasks
4. Whether date folders exist and have PLANO.md
5. Whether current day tasks have checkboxes filled
6. Whether tasks have a Conclusion section
7. Whether PLANO.md reflects the actual status (task count)
8. Whether templates exist in the TEMPLATES/ folder
9. Whether cron.log exists

#### Basic command

```bash
# Validate project structure
./scripts/validate-workflow.sh ~/my-project

# Validate with automatic correction of minor inconsistencies
./scripts/validate-workflow.sh ~/my-project --fix

# Validate with detailed output
./scripts/validate-workflow.sh ~/my-project --verbose
```

#### Exit codes

| Code | Meaning |
|:------:|-------------|
| 0 | Everything ok (no warnings, no errors) |
| 1 | Warnings found (inconsistencies, but structure intact) |
| 2 | Error (structure missing or corrupted) |

#### Example output

```
[OK]      Structure planejamento-diario/ found.
[OK]      INDICE.md found.
[WARN]    Incorrect counter in '10/06/2026': declared 0/15, actual 3/4
[WARN]    Task task_01: no checkboxes filled (0/6)
[OK]      3 template(s) found in TEMPLATES/.

╔══════════════════════════════════════════════════════════════╗
║           Audit completed with inconsistencies              ║
╚══════════════════════════════════════════════════════════════╝

  Checks: 9
  Passed:     5
  Warnings:     2
  Errors:        0
```

#### Cron command for daily validation

```bash
# Run validation every night at 22:00, with automatic fix
0 22 * * * /Users/your-user/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/your-user/Dev/my-project --fix \
  >> /Users/your-user/Dev/my-project/planejamento-diario/validate.log 2>&1
```

#### Integration with notifications

You can combine validation with Slack notification:

```bash
#!/bin/bash
# ~/scripts/cron-validate-notify.sh
# Wrapper that validates and notifies on Slack

PROJECT="/Users/your-user/Dev/my-project"
VALIDATE_LOG="$PROJECT/planejamento-diario/validate.log"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# Run validation
/Users/your-user/Dev/agent-ops-workflow/scripts/validate-workflow.sh "$PROJECT" --fix \
  > "$VALIDATE_LOG" 2>&1
EXIT_CODE=$?

# If there are warnings or errors, notify
if [ $EXIT_CODE -ne 0 ]; then
    SUMMARY=$(tail -10 "$VALIDATE_LOG")
    
    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -X POST -H "Content-Type: application/json" \
          -d "{\"channel\":\"${SLACK_HOME_CHANNEL:-C0123456789}\",\"text\":\"⚠️ Workflow validation reported inconsistencies (code $EXIT_CODE).\n\n\`\`\`$SUMMARY\`\`\`\"}" \
          "$WEBHOOK_URL"
    fi
fi

exit $EXIT_CODE
```

---

### Audit by Hermes Orchestrator

The Orchestrator can perform auditing with AI, verifying commits and
updating indexes automatically.

#### Audit command

```bash
hermes --profile orquestrador run \
  --skills execucao-wave-auditoria \
  --prompt '<USER>
Execute the complete audit for day 10/06/2026 in the Atlas Project.

STEPS:
1. Read the day's PLANO.md
2. For each task with pending status (⬜), check if the agent reported
3. Verify the commits: git log --oneline and git show for each hash
4. Check if the checkboxes are filled in each task_XX.md
5. If approved:
   - Update PLANO.md: mark status as ✅
   - Update INDICE.md: mark ✅, 👁, add commit hash
   - git add + git commit + git push
6. If rejected:
   - List the specific issues in the Slack thread
   - Wait for agent correction

RULES:
- One task per thread — all communication in the same thread
- Update INDICE.md IMMEDIATELY after each audit
- ⬜ kept is a critical failure
</USER>'
```

#### Commit verification (auditor's checklist)

```bash
# 1. Check if the hash exists
git log --oneline -5

# 2. Check commit details
git show aabbccdd --stat

# 3. Check actual diff
git diff aabbccdd^..aabbccdd

# 4. Check if the push was made
git branch -r --contains aabbccdd
```

---

### Integrity cron (complete)

```bash
# Daily cron — 22:00 — validate structure and fix automatically
0 22 * * * /Users/your-user/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/your-user/Dev/my-project --fix \
  >> /Users/your-user/Dev/my-project/planejamento-diario/validate.log 2>&1

# Weekly cron — Sunday 10:00 — complete validation with verbose
0 10 * * 0 /Users/your-user/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/your-user/Dev/my-project --verbose --fix \
  >> /Users/your-user/Dev/my-project/planejamento-diario/validate-semanal.log 2>&1
```

---

## 6. Flow 5 — Consolidated Daily Report

### Automatic generation via shell script

This script compiles the status of all day tasks, generates a markdown
report and publishes on Slack via webhook.

#### Example script: `gerar-relatorio.sh`

```bash
#!/bin/bash
# scripts/gerar-relatorio.sh — Consolidated Daily Report
# =============================================================================
# Reads PLANO.md and INDICE.md for the day, compiles status, generates markdown
# report and publishes on Slack via webhook.
#
# Usage: ./scripts/gerar-relatorio.sh <project-directory> [date YYYY-MM-DD]
# =============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
DATA="${2:-$(date +%Y-%m-%d)}"
DATA_BR="$(date -d "$DATA" +%d/%m/%Y 2>/dev/null || echo "$DATA")"

PD_DIR="$TARGET_DIR/planejamento-diario"
DIA_DIR="$PD_DIR/$DATA"
PLANO="$DIA_DIR/PLANO.md"
INDICE="$PD_DIR/INDICE.md"
REPORT="$DIA_DIR/RELATORIO.md"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

TEAM_NAME="${WORKFLOW_TEAM_NAME:-Team Nova}"

if [ ! -f "$PLANO" ]; then
    echo "[ERROR] PLANO.md not found: $PLANO"
    exit 1
fi

echo "[INFO] Generating report for $DATA_BR..."

# --- Data collection ---

# Total tasks in PLANO.md
TOTAL_TASKS=$(grep -cP '^\|\s*task_\d+' "$PLANO" 2>/dev/null || echo 0)

# Completed tasks (status ✅ in PLANO.md)
COMPLETED=$(grep -cP '^\|\s*task_\d+.*\|\s*✅\s*\|' "$PLANO" 2>/dev/null || echo 0)

# Audited tasks (👁 column in INDICE.md)
if [ -f "$INDICE" ]; then
    AUDITED=$(grep -cP '^\|\s*task_\d+.*\|.*\|.*\|.*✅\s*\|' "$INDICE" 2>/dev/null || echo 0)
else
    AUDITED=0
fi

# Today's commits (last commits)
COMMITS_TODAY=$(cd "$TARGET_DIR" && git log --oneline --since="$(date +%Y-%m-%d)T00:00:00" --until="$(date +%Y-%m-%d)T23:59:59" 2>/dev/null | head -10 || true)

# --- Build task table ---
TASKS_JSON=""
while IFS='|' read -r _ task_id desc agent engine priority status _; do
    task_id="$(echo "$task_id" | xargs)"
    desc="$(echo "$desc" | xargs)"
    status="$(echo "$status" | xargs)"
    
    [ -z "$task_id" ] && continue
    
    # Translate status
    case "$status" in
        "✅") STATUS_ICON="✅" ;;
        "⬜") STATUS_ICON="⬜" ;;
        *) STATUS_ICON="$status" ;;
    esac
    
    # Look for commit hash in INDICE.md
    COMMIT_HASH="—"
    if [ -f "$INDICE" ]; then
        HASH=$(grep "^| $task_id " "$INDICE" 2>/dev/null | awk -F'|' '{print $NF}' | xargs)
        [ -n "$HASH" ] && [ "$HASH" != "—" ] && COMMIT_HASH="$HASH"
    fi
    
    TASKS_JSON+="| $task_id | $desc | $STATUS_ICON | $COMMIT_HASH |"$'\n'
done < <(grep -P '^\|\s*task_\d+' "$PLANO")

# --- Generate markdown report ---
cat > "$REPORT" <<RELEOF
# Daily Report — $TEAM_NAME

**Date:** $DATA_BR
**Generated by:** gerar-relatorio.sh
**Total tasks:** $TOTAL_TASKS | Completed: $COMPLETED | Audited: $AUDITED

---

## Task Status

| Task | Description | Status | Commit |
|:----:|-----------|:------:|:------:|
$TASKS_JSON

---

## Summary

**$COMPLETED/$TOTAL_TASKS** tasks completed.
**$AUDITED** tasks audited.
**$((TOTAL_TASKS - COMPLETED))** pending tasks.

**Completion rate:** $(awk "BEGIN {printf \"%.0f\", ($COMPLETED/$TOTAL_TASKS)*100}")%

---

## Today's Commits

\`\`\`
$COMMITS_TODAY
\`\`\`

---

## Pending Items for Tomorrow

- $(grep -cP '⬜' <<< "$TASKS_JSON") uncompleted tasks
- Review tasks with status ⬜ in tomorrow's plan

---

## Notes

<!-- Fill in manually if needed -->

RELEOF

echo "[OK] Report generated: $REPORT"

# --- Publish on Slack ---
if [ -n "$WEBHOOK_URL" ]; then
    # Summary version for Slack (without complex table)
    SUMMARY="📊 Daily Report — $TEAM_NAME — $DATA_BR

*Summary:* $COMPLETED/$TOTAL_TASKS tasks completed. $AUDITED audited.
*Pending:* $((TOTAL_TASKS - COMPLETED)) pending tasks.

*Commits:*"
    while IFS= read -r commit; do
        [ -n "$commit" ] && SUMMARY+="
• $commit"
    done <<< "$COMMITS_TODAY"
    [ -z "$COMMITS_TODAY" ] && SUMMARY+="
• No commits today"

    curl -s -X POST -H "Content-Type: application/json" \
      -d "{\"channel\":\"${SLACK_HOME_CHANNEL:-C0123456789}\",\"text\":\"$SUMMARY\",\"unfurl_links\":false}" \
      "$WEBHOOK_URL"
    echo "[OK] Report published on Slack."
fi

echo "[OK] Report completed."
```

#### How to use

```bash
# Configure variables
export WORKFLOW_TEAM_NAME="Team Nova"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00.../B00.../xxx"
export SLACK_HOME_CHANNEL="C0123456789"

# Generate report for today
./scripts/gerar-relatorio.sh ~/my-project

# Generate report for a specific date
./scripts/gerar-relatorio.sh ~/my-project 2026-06-10
```

#### Generated report template

```markdown
# Daily Report — Team Nova

**Date:** 10/06/2026
**Generated by:** gerar-relatorio.sh
**Total tasks:** 4 | Completed: 3 | Audited: 2

---

## Task Status

| Task | Description | Status | Commit |
|:----:|-----------|:------:|:------:|
| task_01 | Fix login redirect bug | ✅ | aabbccdd |
| task_02 | Complete API v2 migration | ✅ | eeff0011 |
| task_03 | Update API documentation | ✅ | 11223344 |
| task_04 | Audit fix + migration | ⬜ | — |

---

## Summary

**3/4** tasks completed.
**2** tasks audited.
**1** pending tasks.

**Completion rate:** 75%

---

## Pending Items for Tomorrow

- 1 uncompleted tasks
- Review tasks with status ⬜ in tomorrow's plan
```

#### Cron for automatic report generation

```bash
# Generate report at 23:00 every day
0 23 * * * cd /Users/your-user/Dev/agent-ops-workflow && \
  export WORKFLOW_TEAM_NAME="Team Nova" && \
  export SLACK_WEBHOOK_URL="your-webhook" && \
  export SLACK_HOME_CHANNEL="C0123456789" && \
  ./scripts/gerar-relatorio.sh /Users/your-user/Dev/my-project \
  >> /Users/your-user/Dev/my-project/planejamento-diario/relatorio.log 2>&1
```

---

### Generation via Hermes Orchestrator

The Orchestrator can generate a smarter report, analyzing the
real context of each task.

```bash
hermes --profile orquestrador run \
  --prompt '<USER>
Generate the consolidated daily report for Team Nova in the Atlas Project, date $(date +%d/%m/%Y).

CONTEXT:
- Read planejamento-diario/INDICE.md for status of all tasks
- Read planejamento-diario/$(date +%Y-%m-%d)/PLANO.md for the day's plan
- Check the commits with git log --oneline

EXPECTED OUTPUT:
1. Markdown table with all tasks, status and commits
2. Numerical summary (X/Y completed, A audited)
3. Pending items for tomorrow
4. Noteworthy observations

RULES:
- Save in planejamento-diario/$(date +%Y-%m-%d)/RELATORIO.md
- Publish in channel #agent-ops-nova
- Do git add + git commit + git push
</USER>'
```

---

## 7. Flow 6 — Git Sync and Backup

### Automatic push via cron

```bash
# Daily cron — 23:30 — commit + push of all day changes
30 23 * * * cd /Users/your-user/Dev/my-project && \
  git add -A && \
  git commit -m "daily: update $(date +%Y-%m-%d)" --allow-empty && \
  git push \
  >> /Users/your-user/Dev/my-project/planejamento-diario/git-push.log 2>&1
```

#### Wrapper script: `git-push-diario.sh`

```bash
#!/bin/bash
# scripts/git-push-diario.sh — Automatic push with semantic message
# =============================================================================
# Usage: ./scripts/git-push-diario.sh <project-directory> [message]
# =============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
DATA="$(date +%Y-%m-%d)"
DATA_BR="$(date +%d/%m/%Y)"
MESSAGE="${2:-daily: update $DATA_BR}"

cd "$TARGET_DIR"

echo "[INFO] Syncing $TARGET_DIR..."

# Check if it's a git repository
if [ ! -d ".git" ]; then
    echo "[ERROR] $TARGET_DIR is not a git repository."
    exit 1
fi

# Add everything
git add -A

# Check if there's anything to commit
if git diff --cached --quiet; then
    echo "[INFO] Nothing to commit. Skipping."
    exit 0
fi

# Commit
git commit -m "$MESSAGE"
echo "[OK] Commit: $(git log --oneline -1)"

# Push
git push
echo "[OK] Push completed."

# Log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Push: $MESSAGE" >> "$TARGET_DIR/planejamento-diario/git-push.log"
```

---

### Security backup

#### Backup of `.hermes/` directory

The `~/.hermes/` directory contains the profile configuration, tokens and skills
of Hermes Agent. It is essential to have backup.

```bash
#!/bin/bash
# scripts/backup-hermes-config.sh
# =============================================================================
# Backup of Hermes Agent configuration
# =============================================================================

BACKUP_DIR="$HOME/backups/hermes-config"
DATA="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/hermes-config-$DATA.tar.gz"

mkdir -p "$BACKUP_DIR"

if [ -d "$HOME/.hermes" ]; then
    tar -czf "$BACKUP_FILE" -C "$HOME" .hermes
    echo "[OK] Backup created: $BACKUP_FILE"
    echo "     Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # Keep only the 7 most recent backups
    ls -t "$BACKUP_DIR"/hermes-config-*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm
    echo "[INFO] Old backups removed (7 kept)."
else
    echo "[ERROR] ~/.hermes/ not found."
    exit 1
fi
```

#### Weekly backup cron

```bash
# Backup Hermes configuration every Sunday at 03:00
0 3 * * 0 /Users/your-user/Dev/agent-ops-workflow/scripts/backup-hermes-config.sh \
  >> /Users/your-user/Dev/agent-ops-workflow/planejamento-diario/backup.log 2>&1
```

#### Backup recommendations

| What | Frequency | Method |
|-------|:----------:|--------|
| `~/.hermes/config.yaml` | Weekly | backup-hermes-config.sh script |
| SSH keys (`~/.ssh/`) | Monthly | `rotate-key.sh --backup` |
| `planejamento-diario/` | Daily | Git (already versioned) |
| Slack tokens | Every rotation | Password manager |
| Custom skills | Weekly | Git (already in repository) |

---

## 8. Flow 7 — Security and Maintenance

### SSH key rotation (`rotate-key.sh`)

**File:** `scripts/rotate-key.sh`

This script generates a new ed25519 SSH key pair, backs up the previous
key with timestamp and updates `~/.ssh/config` if needed.

#### Commands

```bash
# Rotate default key
./scripts/rotate-key.sh id_my_key

# Rotate and update configuration for a specific host
./scripts/rotate-key.sh id_company --host=github.com

# Rotate in custom directory
./scripts/rotate-key.sh id_server --dir=~/.ssh/company

# Just display current public key (without rotating)
./scripts/rotate-key.sh --show id_my_key

# Skip backup of previous key
./scripts/rotate-key.sh id_test --no-backup
```

#### Recommended frequency

| Environment | Frequency | Reason |
|----------|:----------:|--------|
| Local development | Every 6 months | Basic security |
| Production / servers | Every 3 months | Compliance |
| After suspected leak | Immediate | Emergency |
| Shared machine | Every 1 month | Higher risk |

#### Example execution

```bash
$ ./scripts/rotate-key.sh id_new --host=github.com --comment="Team Nova - $(date +%Y-%m-%d)"

[INFO] Generating new ed25519 key: /Users/your-user/.ssh/id_new

[OK] Backup of previous key created:
[OK]   /Users/your-user/.ssh/id_new.bak.20260603_140000
[OK]   /Users/your-user/.ssh/id_new.pub.bak.20260603_140000

[OK] New key generated successfully.
[INFO]   Private: /Users/your-user/.ssh/id_new
[INFO]   Public: /Users/your-user/.ssh/id_new.pub
[INFO]   Comment: Team Nova - 2026-06-03

[OK] ~/.ssh/config: IdentityFile updated for host 'github.com'.

╔══════════════════════════════════════════════════════════════╗
║         Public Key — Copy to the server                     ║
╚══════════════════════════════════════════════════════════════╝

ssh-ed25519 AAAAC3... user@hostname

╔══════════════════════════════════════════════════════════════╗
║           Rotation completed successfully!                   ║
╚══════════════════════════════════════════════════════════════╝
```

---

### Log cleanup

#### cron.log rotation

Without rotation, logs can grow indefinitely. Use `logrotate` or a
simple script:

```bash
#!/bin/bash
# scripts/rotate-logs.sh — Log rotation for the workflow

LOG_DIR="/Users/your-user/Dev/my-project/planejamento-diario"
RETENTION_DAYS=30

for log in cron.log validate.log relatorio.log git-push.log; do
    LOG_FILE="$LOG_DIR/$log"
    if [ -f "$LOG_FILE" ] && [ "$(stat -f%m "$LOG_FILE" 2>/dev/null || stat -c%Y "$LOG_FILE" 2>/dev/null)" -lt "$(date -d "-$RETENTION_DAYS days" +%s 2>/dev/null || echo 0)" ]; then
        gzip "$LOG_FILE"
        mv "${LOG_FILE}.gz" "${LOG_FILE}.$(date +%Y%m%d).gz"
        echo "[OK] Log rotated: $log"
    fi
done

# Clean temporary files
find "$LOG_DIR" -name "*.tmp" -type f -delete
find "$LOG_DIR" -name "*.bak" -type f -mtime +7 -delete

echo "[OK] Cleanup completed."
```

#### Cleanup cron

```bash
# Weekly log cleanup (Sunday 04:00)
0 4 * * 0 /Users/your-user/Dev/agent-ops-workflow/scripts/rotate-logs.sh
```

---

### Skill updates

Keeping Hermes skills up to date is essential for proper functioning.

#### Check available skills

```bash
# List installed skills
hermes skill_list

# View details of a specific skill
hermes skill_view --name planejamento-diario
```

#### Update skills from repository

```bash
# Pull the agent-ops-workflow repository
cd /Users/your-user/Dev/agent-ops-workflow
git pull origin main

# Reload skills in Hermes
hermes skill_manage sync --dir /Users/your-user/Dev/agent-ops-workflow/skills
```

#### Add new skill

```bash
# Load skill from skills directory
hermes skill_manage add /Users/your-user/Dev/agent-ops-workflow/skills/devops/correcao-fechamento-diario/SKILL.md

# Check if it was loaded
hermes skill_list | grep correcao-fechamento-diario
```

---

## 9. Complete Automation Map

Complete table of ALL workflow automation commands:

| # | What | Command / Script | When | Level | Where |
|:-:|-------|------------------|:------:|:-----:|------|
| 1 | Initial workflow setup | `./scripts/setup-workflow.sh ~/project "Team Nova" "Atlas Project"` | Once | Shell | Setup |
| 2 | Generate daily plan (shell) | `./scripts/gerar-plano-diario.sh ~/project --tasks=5` | 05:00 | Shell | Cron |
| 3 | Generate daily plan (Hermes) | `hermes --profile orquestrador run --skills planejamento-diario --prompt "..."` | 05:00 | AI | Cron |
| 4 | Hermes native cron job | `hermes --profile orquestrador cronjob create --name "plano-5am" --schedule "0 5 * * *" --skills planejamento-diario --prompt "..."` | 05:00 | AI | Hermes |
| 5 | Delegate tasks (manual) | Post `<@USER_ID> Task task_N: ...` on Slack | 08:00 | Manual | Slack |
| 6 | Delegate tasks (script) | `./scripts/delegar-tasks.sh ~/project` | 08:00 | Shell | Cron |
| 7 | Delegate tasks (Hermes) | `hermes --profile orquestrador run --prompt "Delegate pending tasks..."` | 08:00 | AI | Hermes |
| 8 | Execute task | Agent executes, fills checklist + Conclusion | Continuous | Manual | CLI |
| 9 | Commit + push | `git add -A && git commit -m "..." && git push` | Continuous | Shell | CLI |
| 10 | Validate integrity | `./scripts/validate-workflow.sh ~/project` | 22:00 | Shell | Cron |
| 11 | Validate + fix | `./scripts/validate-workflow.sh ~/project --fix` | 22:00 | Shell | Cron |
| 12 | Validate with verbose | `./scripts/validate-workflow.sh ~/project --verbose` | On demand | Shell | CLI |
| 13 | Audit by Orchestrator | `hermes --profile orquestrador run --skills execucao-wave-auditoria --prompt "Audit the day..."` | 22:00 | AI | Hermes |
| 14 | Daily report (script) | `./scripts/gerar-relatorio.sh ~/project` | 23:00 | Shell | Cron |
| 15 | Daily report (Hermes) | `hermes --profile orquestrador run --prompt "Generate the daily report..."` | 23:00 | AI | Hermes |
| 16 | Automatic git push | `git add -A && git commit -m "daily: ..." && git push` | 23:30 | Shell | Cron |
| 17 | Backup Hermes configuration | `./scripts/backup-hermes-config.sh` | Weekly (Sun 03:00) | Shell | Cron |
| 18 | SSH key rotation | `./scripts/rotate-key.sh id_new` | Quarterly | Shell | Manual |
| 19 | Log rotation | `./scripts/rotate-logs.sh` | Weekly (Sun 04:00) | Shell | Cron |
| 20 | Update skills | `hermes skill_manage sync --dir skills/` | After git pull | Hermes | CLI |
| 21 | Check cron jobs | `hermes --profile orquestrador cronjob list` | On demand | Hermes | CLI |
| 22 | Validation notification | Wrapper that calls Slack webhook if `validate-workflow.sh` fails | 22:00 | Shell | Cron |

---

## 10. Automation Checklist

### Daily Checklist

- [ ] **05:00** — Did cron generate the daily plan? Check `cron.log`
  - Command: `tail -5 ~/project/planejamento-diario/cron.log`
- [ ] **08:00** — Plan reviewed and approved by the Commander?
- [ ] **08:00-18:00** — Tasks delegated and in execution?
- [ ] **22:00** — Did automatic validation run? Check `validate.log`
  - Command: `tail -15 ~/project/planejamento-diario/validate.log`
- [ ] **23:00** — Report generated and published on Slack?
  - Command: `ls -la ~/project/planejamento-diario/$(date +%Y-%m-%d)/RELATORIO.md`
- [ ] **23:30** — Automatic git push executed?
  - Command: `tail -3 ~/project/planejamento-diario/git-push.log`

### Weekly Checklist

- [ ] Verify `INDICE.md` integrity manually
- [ ] Review validation logs for the week
- [ ] Check if all cron jobs are active: `crontab -l`
- [ ] Backup `~/.hermes/`
- [ ] Rotate old logs
- [ ] Review outdated skills

### Monthly Checklist

- [ ] SSH key rotation (if due)
- [ ] Review Slack tokens (expiration)
- [ ] Check disk space for logs
- [ ] Update `agent-ops-workflow` repository: `git pull`
- [ ] Sync skills: `hermes skill_manage sync --dir skills/`
- [ ] Check AGENTS.md (are team members still the same?)

### Consolidated Cron Jobs

Add ALL these lines to your crontab:

```bash
# ─── Agent Ops Workflow — Daily Cron Jobs ────────────────────────────────

# 05:00 — Generate daily plan (shell script)
0 5 * * * cd /Users/your-user/Dev/agent-ops-workflow && \
  WORKFLOW_TEAM_NAME="Team Nova" WORKFLOW_PROJECT_NAME="Atlas Project" \
  ./scripts/gerar-plano-diario.sh /Users/your-user/Dev/my-project --tasks=5 \
  >> /Users/your-user/Dev/my-project/planejamento-diario/cron.log 2>&1

# 05:30 — Generate daily plan via Hermes Orchestrator (optional, shell alternative)
# 30 5 * * * cd /Users/your-user/Dev/agent-ops-workflow && \
#   hermes --profile orquestrador run \
#     --skills planejamento-diario \
#     --prompt "Generate today's daily plan for Team Nova in the Atlas Project" \
#     >> /Users/your-user/Dev/my-project/planejamento-diario/hermes-plan.log 2>&1

# 22:00 — Validate workflow integrity
0 22 * * * /Users/your-user/Dev/agent-ops-workflow/scripts/validate-workflow.sh \
  /Users/your-user/Dev/my-project --fix \
  >> /Users/your-user/Dev/my-project/planejamento-diario/validate.log 2>&1

# 23:00 — Generate daily report
0 23 * * * cd /Users/your-user/Dev/agent-ops-workflow && \
  WORKFLOW_TEAM_NAME="Team Nova" SLACK_WEBHOOK_URL="your-webhook" \
  SLACK_HOME_CHANNEL="C0123456789" \
  ./scripts/gerar-relatorio.sh /Users/your-user/Dev/my-project \
  >> /Users/your-user/Dev/my-project/planejamento-diario/relatorio.log 2>&1

# 23:30 — Automatic git push
30 23 * * * cd /Users/your-user/Dev/my-project && \
  git add -A && \
  git commit -m "daily: update $(date +%Y-%m-%d)" --allow-empty && \
  git push \
  >> /Users/your-user/Dev/my-project/planejamento-diario/git-push.log 2>&1

# ─── Weekly Cron Jobs ────────────────────────────────────────────────────

# Sunday 03:00 — Backup Hermes configuration
0 3 * * 0 /Users/your-user/Dev/agent-ops-workflow/scripts/backup-hermes-config.sh \
  >> /Users/your-user/Dev/my-project/planejamento-diario/backup.log 2>&1

# Sunday 04:00 — Log cleanup
0 4 * * 0 /Users/your-user/Dev/agent-ops-workflow/scripts/rotate-logs.sh

# ─── Cron Environment Variables ─────────────────────────────────────────
# Make sure PATH includes the necessary binaries
# PATH=/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin
```

### Log monitoring

```bash
# Check all automation logs for the day
echo "=== Cron Log ===" && tail -3 ~/project/planejamento-diario/cron.log
echo "=== Validate Log ===" && tail -3 ~/project/planejamento-diario/validate.log
echo "=== Git Push Log ===" && tail -3 ~/project/planejamento-diario/git-push.log
echo "=== Report ===" && ls -la ~/project/planejamento-diario/$(date +%Y-%m-%d)/RELATORIO.md 2>/dev/null || echo "No report today"
```

### Quick Reference — Useful Commands

```bash
# Initial setup (once)
./scripts/setup-workflow.sh ~/my-project "Team Nova" "Atlas Project"

# Generate plan manually
./scripts/gerar-plano-diario.sh ~/my-project

# Validate workflow
./scripts/validate-workflow.sh ~/my-project --fix

# Validate with details
./scripts/validate-workflow.sh ~/my-project --verbose --fix

# Generate report manually
./scripts/gerar-relatorio.sh ~/my-project

# Rotate SSH key
./scripts/rotate-key.sh id_new

# View cron jobs
crontab -l

# Edit cron jobs
crontab -e

# View logs
tail -f ~/my-project/planejamento-diario/cron.log
tail -f ~/my-project/planejamento-diario/validate.log

# Hermes: generate plan with AI
hermes --profile orquestrador run --skills planejamento-diario \
  --prompt "Generate today's daily plan for Team Nova"

# Hermes: create native cron job
hermes --profile orquestrador cronjob create \
  --name "plano-diario-5am" \
  --schedule "0 5 * * *" \
  --skills planejamento-diario \
  --prompt "Generate today's daily plan"

# Hermes: list cron jobs
hermes --profile orquestrador cronjob list

# Hermes: audit
hermes --profile orquestrador run --skills execucao-wave-auditoria \
  --prompt "Audit today's day in the Atlas Project"
```

---

> **Final note:** Automation in Agent Ops Workflow is divided into two
> broad groups: **operational automation** (shell scripts, cron, git) that
> ensures predictable and reliable execution of the daily cycle, and **intelligent
> automation** (Hermes agent, skills, AI) that brings context, adaptability
> and decision-making to the flow. Use both together — the shell for
> what is repetitive and deterministic, Hermes for what requires analysis
> and judgment.
