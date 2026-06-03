# 01 — Initial Setup Guide

> **Goal:** Get the Agent Ops Workflow running in your own project from scratch.
> **Audience:** Anyone new to Hermes agents who wants to set up a multi-agent daily planning system.
> **Estimated time:** 30–45 minutes.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Clone the Repository](#clone-the-repository)
- [Run setup-workflow.sh](#run-setup-workflowsh)
- [Customize Placeholders for Your Team](#customize-placeholders-for-your-team)
- [Configure Hermes Agents](#configure-hermes-agents)
- [Set Up Slack Channels](#set-up-slack-channels)
- [Configure Cron for Daily Planning](#configure-cron-for-daily-planning)
- [Post-Setup Verification Checklist](#post-setup-verification-checklist)

---

## Prerequisites

Before starting, make sure you have the following:

### 1. Hermes Agent Installed and Configured

Hermes is the CLI tool that orchestrates your AI agents. You need:

- **Hermes CLI** installed on your machine or CI environment
- At least one **Hermes profile** configured with your API keys
- Basic familiarity with running `hermes` commands

```bash
# Verify Hermes is installed
hermes --version

# List available profiles
ls ~/.hermes/profiles/
```

If you don't have Hermes yet, follow the [official Hermes installation guide](https://hermes-agent.nousresearch.com/docs).

### 2. A Slack App Created and CLI-Configured

The workflow uses Slack to delegate tasks and receive reports. You need:

- A **Slack workspace** where your team operates
- A **Slack app** with the `chat:write` and `channels:read` OAuth scopes
- A **bot token** (`xoxb-...`) stored in your environment
- The Slack CLI configured on your machine

```bash
# Verify Slack CLI
slack --version

# Verify your token is accessible
echo $SLACK_BOT_TOKEN  # Should start with xoxb-
```

> See the [Slack API Setup](#set-up-slack-channels) section below for detailed instructions.

### 3. Git and Bash >= 4

The setup scripts depend on standard Unix tools:

```bash
git --version
bash --version  # Must be >= 4
```

---

## Clone the Repository

Start by cloning the `agent-ops-workflow` repository:

```bash
git clone https://github.com/__YOUR_ORG__/agent-ops-workflow.git
cd agent-ops-workflow
```

If you prefer to keep the repository as a template and create a fresh project:

```bash
# Option A: Use as a Git template
cp -r agent-ops-workflow ~/my-project
cd ~/my-project
rm -rf .git
git init

# Option B: Fork on GitHub and clone your fork
git clone https://github.com/__YOUR_TEAM__/agent-ops-workflow.git
```

---

## Run setup-workflow.sh

The `setup-workflow.sh` script creates the `planejamento-diario/` directory structure inside your target project. It copies templates, generates an initial `INDICE.md`, and creates a skeleton `PLANO.md` for today.

### Basic Usage

```bash
# From the agent-ops-workflow root directory
./scripts/setup-workflow.sh ~/my-project "Team Nova" "Nova Platform"
```

### Interactive Mode

Run without arguments to be prompted for each value:

```bash
./scripts/setup-workflow.sh
```

You will be asked for:

- **Target directory** — where your project lives (e.g., `~/my-project`)
- **Team name** — your team's name (e.g., `Team Nova`)
- **Project name** — your project's name (e.g., `Nova Platform`)
- **Default engine** — the primary AI engine (e.g., `Gemini CLI`)
- **Additional engines** — comma-separated (e.g., `Claude Code, OpenAI API, DeepSeek`)
- **Documentation language** — e.g., `en-US` (default is `pt-BR`)

### Environment Variables (Non-Interactive)

For automated setups or CI, use environment variables:

```bash
export WORKFLOW_TEAM_NAME="Team Nova"
export WORKFLOW_PROJECT_NAME="Nova Platform"

./scripts/setup-workflow.sh ~/my-project
```

### What Gets Created

After running the script, your project will have this structure:

```
~/my-project/
└── planejamento-diario/
    ├── INDICE.md                     ← Progress tracker for all tasks
    ├── TEMPLATES/                    ← Reusable templates
    │   ├── PLANO.md
    │   ├── TASK.md
    │   ├── INDICE.md
    │   └── README-WORKFLOW.md
    └── 2026-06-03/                   ← Today's date folder
        └── PLANO.md                  ← Today's execution plan
```

---

## Customize Placeholders for Your Team

The templates use `__PLACEHOLDER__` notation — double-underscore words that you replace with your team's actual values.

### Common Placeholders

| Placeholder | Description | Example Value |
|---|---|---|
| `__NOME_DO_TIME__` | Your team name | `Team Nova` |
| `__NOME_DO_PROJETO__` | Your project name | `Nova Platform` |
| `__COMANDANTE__` | The human commander | `Commander Alex` |
| `__MOTOR_PADRAO__` | Default AI engine | `Gemini CLI` |
| `__IDIOMA__` | Documentation language | `en-US` |
| `__DATA__` | Current date | `06/03/2026` |

### Where to Replace

1. **Templates** — `planejamento-diario/TEMPLATES/PLANO.md`, `TASK.md`, `INDICE.md`
2. **Daily plans** — each `PLANO.md` inside a date folder
3. **Task files** — each `task_NN.md` inside a date folder

> **Tip:** The `gerar-plano-diario.sh` script (see [cron section](#configure-cron-for-daily-planning)) automatically replaces `__DATA__`, `__NOME_DO_PROJETO__`, and `__NOME_DO_TIME__` when generating daily plans. You only need to manually fill in task-specific content.

---

## Configure Hermes Agents

Each agent in your team needs a Hermes profile. The workflow supports multiple agents with different roles and engines.

### 1. Create Agent Profiles

Your Hermes profiles live in `~/.hermes/profiles/`. Create one profile per agent:

```bash
# Example: Creating an orchestrator agent
mkdir -p ~/.hermes/profiles/orchestrator/skills
mkdir -p ~/.hermes/profiles/developer-alpha/skills
mkdir -p ~/.hermes/profiles/developer-beta/skills
```

### 2. Configure `config.yaml`

Each profile needs a `config.yaml` that defines the agent's behavior. Here's a minimal example:

```yaml
# ~/.hermes/profiles/orchestrator/config.yaml
name: orchestrator
default_engine: gemini
skills:
  - planning
  - delegation
  - auditing
```

```yaml
# ~/.hermes/profiles/developer-alpha/config.yaml
name: developer-alpha
default_engine: claude
skills:
  - coding
  - testing
  - documentation
```

### 3. Define `AGENTS.md`

Create an `AGENTS.md` in your project root that lists every agent in the team:

```markdown
# Agents — Team Nova

| Agent | Profile | Engine | Role |
|---|---|---|---|
| Orchestrator | orchestrator | Gemini CLI | Plan, delegate, audit |
| Developer Alpha | developer-alpha | Claude Code | Build features, fix bugs |
| Developer Beta | developer-beta | OpenAI API | Review, test, document |
| Commander Alex | (human) | — | Approve plans, give final sign-off |
```

### 4. Define `TEAM.md`

Create a `TEAM.md` with communication preferences and escalation rules:

```markdown
# Team Nova — Charter

- **Communication channel:** #team-nova on Slack
- **Commander:** Alex (human)
- **Orchestrator:** (Hermes agent — orchestrator profile)
- **Working hours:** 09:00–18:00 UTC-3
- **Escalation:** If a task blocks for >30 min, notify Commander
- **Slack bot token:** `$SLACK_BOT_TOKEN` (env var)
```

### 5. Skills

Copy the generic skills from `agent-ops-workflow` into each profile:

```bash
# Copy the skills you need
cp -r agent-ops-workflow/skills/planning ~/.hermes/profiles/orchestrator/skills/
cp -r agent-ops-workflow/skills/delegation ~/.hermes/profiles/orchestrator/skills/
cp -r agent-ops-workflow/skills/coding ~/.hermes/profiles/developer-alpha/skills/
```

> Each skill has a `SKILL.md` that explains its purpose. Read these to understand what each agent can do.

---

## Set Up Slack Channels

The workflow relies on Slack for task delegation and reporting. You need a dedicated channel where agents post plans and reports.

### 1. Create a Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and click **Create New App**
2. Choose **From scratch**
3. Name it (e.g., `Agent Ops Workflow`) and select your workspace

### 2. Add OAuth Scopes

Under **OAuth & Permissions** > **Scopes**, add these **Bot Token Scopes**:

| Scope | Why It's Needed |
|---|---|
| `chat:write` | Post messages and replies |
| `channels:read` | List channels and get channel info |
| `channels:join` | Join the team channel automatically |
| `chat:write.customize` | Set bot name and icon per message |

### 3. Install the App and Get a Token

1. Click **Install to Workspace**
2. Copy the **Bot User OAuth Token** (starts with `xoxb-`)
3. Set it as an environment variable:

```bash
export SLACK_BOT_TOKEN="xoxb-YOUR-TOKEN-HERE"
```

### 4. Create a Dedicated Channel

Create a channel in your Slack workspace for the workflow:

```bash
# Using Slack CLI
slack channel create "agent-ops-nova"
```

Or create it manually in Slack. Name it something like `#agent-ops-__TEAM_NAME__`.

### 5. Set the Home Channel

The workflow posts the daily plan and reports to a "home channel." Configure this in your project's `TEAM.md` or in a `.env` file:

```bash
# .env
SLACK_HOME_CHANNEL="C0123456789"  # Replace with your channel ID
SLACK_BOT_TOKEN="xoxb-..."
```

To find your channel ID:
- Open the channel in Slack
- The channel ID is in the URL: `https://app.slack.com/client/T00000000/C0123456789`
- Or right-click the channel name → **Copy link** → the last part is the channel ID

> See [03-SLACK-PROTOCOL.md](./03-SLACK-PROTOCOL.md) for detailed rules on how agents communicate in Slack channels.

---

## Configure Cron for Daily Planning

Automate daily plan generation so your Orchestrator always has a fresh plan every morning.

### 1. Test the Script Manually First

```bash
./scripts/gerar-plano-diario.sh ~/my-project --tasks=5
```

This creates a `YYYY-MM-DD/` folder with a `PLANO.md` containing 5 skeleton tasks per wave.

Options:

| Flag | Description |
|---|---|
| `--tasks=N` | Number of tasks per wave (default: 5) |
| `--force, -f` | Overwrite if today's folder already exists |
| `--help, -h` | Show help |

### 2. Add the Cron Entry

```bash
# Open crontab
crontab -e

# Add this line (runs every day at 5:00 AM)
0 5 * * * /path/to/agent-ops-workflow/scripts/gerar-plano-diario.sh /path/to/my-project >> /path/to/my-project/planejamento-diario/cron.log 2>&1
```

### 3. Verify Cron Is Running

```bash
# Check the cron log
tail -f ~/my-project/planejamento-diario/cron.log

# Expected output:
# [2026-06-03 05:00:01] Plano gerado: .../2026-06-03/PLANO.md
#   Projeto: Nova Platform | Time: Team Nova
#   Tasks por wave: 5 | Force: false
```

### Environment Variables for Cron

Cron jobs have a minimal environment. Make sure `WORKFLOW_TEAM_NAME` and `WORKFLOW_PROJECT_NAME` are set:

```bash
# In crontab, set variables before the command
WORKFLOW_TEAM_NAME="Team Nova"
WORKFLOW_PROJECT_NAME="Nova Platform"
SLACK_BOT_TOKEN="xoxb-..."

0 5 * * * /path/to/.../gerar-plano-diario.sh /path/to/my-project >> /path/to/cron.log 2>&1
```

---

## Post-Setup Verification Checklist

Use this checklist to confirm everything is working:

### Structure

- [ ] `planejamento-diario/` exists in your project
- [ ] `planejamento-diario/INDICE.md` exists and has correct header
- [ ] `planejamento-diario/TEMPLATES/` contains PLANO.md, TASK.md, INDICE.md
- [ ] Today's date folder exists with PLANO.md

### Configuration

- [ ] `TEAM.md` created with team name, channel, commander
- [ ] `AGENTS.md` created with all agent profiles listed
- [ ] `SLACK_BOT_TOKEN` environment variable is set
- [ ] `SLACK_HOME_CHANNEL` is configured (channel ID)

### Scripts

- [ ] `setup-workflow.sh` ran without errors
- [ ] `gerar-plano-diario.sh` generates a plan correctly
- [ ] `validate-workflow.sh` passes (exit code 0):

```bash
./scripts/validate-workflow.sh ~/my-project
# Expected: "Auditoria concluída — tudo OK!"
```

### Slack

- [ ] Slack app is installed in your workspace
- [ ] Bot token has `chat:write` and `channels:read` scopes
- [ ] Bot has joined the home channel (`/invite @botname`)
- [ ] You can manually post a test message:

```bash
curl -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-type: application/json" \
  -d '{"channel":"C0123456789","text":"Hello from Agent Ops Workflow!"}'
```

### Cron

- [ ] Crontab entry is active
- [ ] Cron log file exists and has entries
- [ ] Tomorrow's date folder will be created automatically at 5 AM

---

## Next Steps

Once setup is complete, proceed to [02-DAILY-CYCLE.md](./02-DAILY-CYCLE.md) to understand how the daily planning cycle works — the 6 phases from planning to reporting.

If you haven't configured Slack communication yet, read [03-SLACK-PROTOCOL.md](./03-SLACK-PROTOCOL.md) for the messaging rules that keep multi-agent teams organized.

---

## Troubleshooting

| Problem | Likely Cause | Solution |
|---|---|---|
| `setup-workflow.sh: command not found` | Wrong directory | Run from `agent-ops-workflow/` root |
| `Templates directory not found` | Script not run from repo root | Use absolute path to script |
| `SLACK_BOT_TOKEN not set` | Environment variable missing | Add to `.env` or shell profile |
| `gerar-plano-diario.sh` creates empty plan | Template missing | Run `setup-workflow.sh` first |
| `validate-workflow.sh` exit code 1 | Inconsistencies found | Run with `--fix` to auto-correct |
| Bot doesn't respond in Slack | Bot not in channel | `/invite @YourBotName` |
