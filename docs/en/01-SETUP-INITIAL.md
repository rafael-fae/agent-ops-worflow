# Setup Guide — Agent Ops Workflow

> Complete walkthrough to install, configure, and verify your multi-agent daily
> planning system. Time to first plan: ~30 minutes if you have prerequisites ready.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Clone the Repository](#clone-the-repository)
3. [Run the Setup Script](#run-the-setup-script)
4. [Customize Placeholders for Your Team](#customize-placeholders-for-your-team)
5. [Configure Hermes Agents](#configure-hermes-agents)
6. [Set Up Slack Integration](#set-up-slack-integration)
7. [Configure the Cron Job](#configure-the-cron-job)
8. [Post-Setup Verification Checklist](#post-setup-verification-checklist)
9. [Troubleshooting](#troubleshooting)
10. [Next Steps](#next-steps)

---

## Prerequisites

Before you begin, make sure your environment has the following tools and
accounts ready.

### 1. Hermes Agent (Required)

Hermes is the CLI agent framework that powers this workflow. You need it
installed and configured on the machine that will act as the orchestrator.

```bash
# Verify installation
hermes --version

# Expected output:
# hermes/1.x.x ...
```

If Hermes is not installed, follow the official guide:
https://hermes-agent.nousresearch.com/docs

You will need at least one Hermes profile configured with:
- An API key for your chosen AI model provider
- Optional: Slack integration tokens (covered in Section 6)
- Skills directory where workflow skills can be loaded

```bash
# Check your current Hermes configuration
hermes config list
# or inspect the config file directly
cat ~/.hermes/config.yaml
```

### 2. Slack Workspace (Recommended)

A Slack workspace where your team communicates. You will need:
- **Workspace Admin** (or permission to install apps)
- A dedicated channel for operations (e.g., `#agent-ops`)
- Ability to create Slack apps if you want automated delegation

If you are running a fully local team without Slack, you can substitute with
any chat system that supports thread-based messaging and @mentions. The
protocol is designed to be channel-agnostic, but Slack is the reference
implementation.

### 3. CLI Tools

| Tool     | Minimum Version | Check Command         | Notes                          |
|----------|-----------------|----------------------|--------------------------------|
| bash     | 4.0+            | `bash --version`     | macOS has 3.x by default       |
| git      | 2.0+            | `git --version`      | Required for cloning and tasks |
| sed      | any             | `sed --version`      | Used by cron script            |
| grep     | any             | `grep --version`     | Used by validation script      |
| find     | any             | `find --version`     | Used by validation script      |
| date     | any             | `date --help`        | Date formatting for plans      |

> **macOS note:** Default bash is version 3.x. Install bash 4+ via Homebrew:
> `brew install bash`. All scripts use `#!/bin/bash` shebang, so update your
> PATH or change the shebang if needed.

### 4. SSH Key (Optional but Recommended)

```bash
# Generate an ed25519 key if you don't have one
ssh-keygen -t ed25519 -C "your-email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

The project includes a `scripts/rotate-key.sh` helper for key rotation.

---

## Clone the Repository

Start by cloning the agent-ops-workflow repository to your local machine.

```bash
# Navigate to your development directory
cd /path/to/your/projects

# Clone the repository
git clone https://github.com/your-username/agent-ops-workflow.git
cd agent-ops-workflow

# Make scripts executable
chmod +x scripts/*.sh
```

The repository structure you should see:

```
agent-ops-workflow/
├── scripts/               # Automation toolbelt
│   ├── setup-workflow.sh        # One-shot project initialization
│   ├── gerar-plano-diario.sh    # Cron-ready daily plan generator
│   ├── validate-workflow.sh     # Integrity & consistency auditor
│   └── rotate-key.sh            # SSH key rotation
├── templates/             # Source of truth for all templates
│   ├── PLANO.md.tpl             # Daily plan template
│   ├── TASK.md.tpl              # Individual task template
│   ├── INDEX.md.tpl            # Progress index template
│   └── README-WORKFLOW.md.tpl   # Folder README template
├── docs/                  # Full documentation (you are here)
├── planejamento-diario/   # The workflow running on itself
├── files/                 # .gitignored working area
├── README.md              # Portuguese guide
└── README-en.md           # English guide (you read this)
```

> **Important:** The `files/` directory is in `.gitignore`. It is a working
> area for raw, team-specific data. Nothing in `files/` is ever committed.

---

## Run the Setup Script

The `setup-workflow.sh` script creates the daily-planning folder structure
inside your **project directory** (not inside agent-ops-workflow itself). It
copies templates, generates an initial `INDICE.md`, and creates a folder for
today with a skeleton `PLANO.md`.

### Interactive Mode

Run without arguments to be guided step by step:

```bash
cd agent-ops-workflow
./scripts/setup-workflow.sh
```

You will be prompted for:

1. **Target directory** — Where your project lives (e.g., `~/my-project`).
   The script creates `~/my-project/planejamento-diario/`.

2. **Team name** — Your team identifier (e.g., `Team Nova`). This is
   embedded in generated plans and index files.

3. **Project name** — Your project name (e.g., `Project Atlas`).

4. **Default engine** — The primary AI model for coding tasks.
   Recommended: `Gemini CLI` or `Claude Code`.

5. **Additional engines** — Comma-separated list of fallback engines.

6. **Documentation language** — `en-US` or `pt-BR`.

Example interactive session:

```
╔══════════════════════════════════════════════════════════════╗
║       Setup do Workflow de Planejamento Diário             ║
╚══════════════════════════════════════════════════════════════╝

Diretório do projeto (ex: ~/meu-projeto): ~/my-project
Nome do time (ex: Time Alfa): Team Nova
Nome do projeto (ex: Projeto X): Project Atlas
Motor padrão [Gemini CLI]:
Outros motores (separados por vírgula) [Claude Code, OpenAI API, DeepSeek]:
Idioma da documentação [pt-BR]: en-US
```

### Non-Interactive Mode

Pass all parameters as arguments for headless setup (useful in CI/CD):

```bash
./scripts/setup-workflow.sh ~/my-project "Team Nova" "Project Atlas"
```

Environment variable fallbacks:

```bash
export WORKFLOW_TEAM_NAME="Team Nova"
export WORKFLOW_PROJECT_NAME="Project Atlas"
./scripts/setup-workflow.sh ~/my-project
```

### What the Script Creates

After running, your project directory will have:

```
~/my-project/
└── planejamento-diario/
    ├── INDICE.md                    # Master progress index
    ├── TEMPLATES/                   # Copied from agent-ops-workflow/templates/
    │   ├── PLANO.md
    │   ├── TASK.md
    │   ├── INDICE.md
    │   └── README-WORKFLOW.md
    └── YYYY-MM-DD/                  # Today's date (e.g., 2026-06-03)
        └── PLANO.md                 # Skeleton plan for the day
```

---

## Customize Placeholders for Your Team

The templates use `__PLACEHOLDER__` syntax (double underscores). These
placeholders are replaced by `setup-workflow.sh` with the values you
provided, but you may want to further customize.

### Template Files to Review

Review and edit the following files in `~/my-project/planejamento-diario/TEMPLATES/`:

| File         | Purpose                                    | Key Placeholders                          |
|--------------|--------------------------------------------|-------------------------------------------|
| `PLANO.md`   | Daily execution plan template              | `__DATA__`, `__COMANDANTE__`, `__TIME__`  |
| `TASK.md`    | Individual task brief template             | `__AGENTE__`, `__MOTOR__`, `__CONTEXTO__` |
| `INDICE.md`  | Master progress index template             | `__NOME_DO_PROJETO__`, `__DATA__`         |
| `README-WORKFLOW.md` | README for the planning folder    | `__NOME_DO_TIME__`, `__URL_DOCS__`        |

### Example Customization for Team Nova

Edit `PLANO.md` to replace the execution rules section:

```markdown
## Rules of Execution

1. **Default engine:** Gemini CLI (gemini-3.1-pro-preview)
2. **NEVER modify original files** — work in copies or branches
3. **Repository:** Commit only sanitized/generic content
4. **Self-contained:** This project does not depend on external infra
5. **Language:** English (US) for all documentation
6. **Semantic commits:** Descriptive commits in English
7. **Max concurrent threads:** 3 agents
8. **Audit:** Every completed task must be cross-reviewed
```

### Language Switch

To switch from Portuguese (default) to English:

1. Set `IDIOMA="en-US"` during setup
2. Edit `TEMPLATES/PLANO.md` and replace rule #6 with your language
3. Update `INDICE.md` header text and section names

---

## Configure Hermes Agents

The orchestrator machine needs Hermes configured with agent profiles that
correspond to your team roles.

### Understanding the Agent Model

In the Agent Ops Workflow, each agent is a **role**, not a person. A single
Hermes instance can act as multiple agents by switching contexts. The
standard team roles are:

| Role          | Function                                        |
|---------------|-------------------------------------------------|
| Commander     | Human — reviews plans, gives final approval     |
| Orchestrator  | Hermes agent — creates plans, delegates, audits |
| Dev Agent     | Hermes agent — executes coding tasks            |
| Audit Agent   | Hermes agent — cross-checks completed work      |
| Report Agent  | Hermes agent — consolidates daily report        |

### Creating AGENTS.md

Create a file `AGENTS.md` in your project root that documents your team.
Example for Team Nova:

```markdown
# Team Nova — Agent Roster

| Agent ID     | Role          | Slack User ID     | Default Engine        |
|--------------|---------------|-------------------|-----------------------|
| @nova-orch   | Orchestrator  | <@U0123456789>    | Gemini 3.1 Pro        |
| @nova-dev    | Dev Agent     | <@U9876543210>    | Gemini 3.1 Pro        |
| @nova-audit  | Audit Agent   | <@U5555555555>    | Opus 4.7              |
| @nova-report | Report Agent  | <@U1111111111>    | Gemini 3.1 Pro        |
```

This file is not consumed by any script directly, but it serves as the
canonical reference for who is who on the team.

### Hermes config.yaml

Your Hermes configuration (`~/.hermes/config.yaml`) should include:

```yaml
profiles:
  nova-orch:
    model: gemini-3.1-pro-preview
    skills_dir: ~/my-project/skills/
    slack:
      enabled: true
      bot_token: xoxb-...
      app_token: xapp-...
      home_channel: C0123456789

  nova-dev:
    model: gemini-3.1-pro-preview
    # No Slack config needed for executors
    # They communicate through the orchestrator

  nova-audit:
    model: opus-4.7
```

> The Slack tokens are covered in the next section. You can skip `slack:`
> config if you are running a local-only setup.

### Loading Skills

Skills are reusable workflows that agents can load. The repository includes
sanitized skills in `files/skills/sanitized/` (if available). To load a
skill:

```bash
# Inspect a skill before loading
hermes skill_view path/to/skill/SKILL.md

# Load and activate a skill
hermes skill_manage add path/to/skill/SKILL.md
```

Skills use `{{PLACEHOLDER}}` syntax (double curly braces). Template files
use `__PLACEHOLDER__` (double underscores). This distinction prevents
conflicts.

---

## Set Up Slack Integration

Slack is the recommended communication layer for delegating tasks to agents.
This section walks through creating a Slack app, obtaining tokens, and
configuring the workspace.

### Step 1: Create a Slack App

1. Go to https://api.slack.com/apps
2. Click **Create New App** → **From Scratch**
3. Name it (e.g., `Team Nova Agent Ops`) and select your workspace
4. Click **Create App**

### Step 2: Configure Bot Token Scopes

Navigate to **OAuth & Permissions** → **Scopes** → **Bot Token Scopes**.
Add the following scopes:

| Scope              | Purpose                                 |
|--------------------|-----------------------------------------|
| `channels:history` | Read channel history (find threads)     |
| `channels:read`    | View channel info and member lists      |
| `chat:write`       | Send messages and post in threads       |
| `reactions:read`   | Read emoji reactions (audit signals)    |
| `users:read`       | Read user info (resolve @mentions)      |

Also add these **User Token Scopes** if you want the app to act on behalf
of a user:

| Scope                | Purpose                             |
|----------------------|-------------------------------------|
| `channels:manage`    | Create/manage channels (if needed)  |

### Step 3: Install the App to Your Workspace

1. Under **OAuth & Permissions**, click **Install to Workspace**
2. Review the permissions and click **Allow**
3. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

### Step 4: Get Your Bot Token and App Token

You need two tokens:

1. **Bot Token** (`SLACK_BOT_TOKEN`): `xoxb-...` from the previous step
2. **App-Level Token** (`SLACK_APP_TOKEN`): Go to **Basic Information** →
   **App-Level Tokens** → **Generate Token**. Add scopes:
   `connections:write`, `authorizations:read`

> Store tokens securely. Never commit them to version control. Use
> environment variables or a secrets manager.

### Step 5: Find Your Slack Workspace IDs

**Channel ID** (the home channel for operations):
```bash
# In Slack, right-click the channel name → Copy Link
# The URL contains the channel ID:
# https://workspace.slack.com/archives/C0123456789
#                                    ^^^^^^^^^^^^
```

**User IDs** for your team members:
```bash
# Method 1: Slack app page
# Go to api.slack.com/methods/users.list → Try It
# Enter your token and find user IDs

# Method 2: Open Slack, click a user's profile → More → Copy member ID
# User IDs look like: U0123456789
```

**Home channel**: Create a dedicated channel (e.g., `#agent-ops-nova`) and
use its ID as the `home_channel` in your Hermes config.

### Step 6: Configure Hermes with Slack Tokens

Add the Slack configuration to your Hermes profile:

```bash
# Method A: Environment variables (recommended for security)
export SLACK_BOT_TOKEN=xoxb-your-bot-token
export SLACK_APP_TOKEN=xapp-your-app-token
export SLACK_HOME_CHANNEL=C0123456789

# Method B: Hermes config.yaml
# Edit ~/.hermes/config.yaml
```

### Step 7: Test the Connection

Send a test message to verify the bot is working:

```bash
# Using Hermes Slack capability (if available)
hermes slack send --channel C0123456789 --text "Team Nova online. Ready for daily ops."

# Expected: The bot sends a message to the channel
```

If you see errors, double-check:
- Tokens are correct and not expired
- The bot is invited to the channel (`/invite @TeamNovaBot`)
- The home channel ID is correct

---

## Configure the Cron Job

The daily plan generator (`gerar-plano-diario.sh`) is designed to run via
cron at the start of each day. It creates a new folder and skeleton plan
so the team has a fresh structure waiting.

### Cron Schedule

```bash
# Edit your crontab
crontab -e

# Add this line to generate a daily plan at 5:00 AM
0 5 * * * /path/to/agent-ops-workflow/scripts/gerar-plano-diario.sh \
  /Users/your-user/my-project \
  >> /Users/your-user/my-project/planejamento-diario/cron.log 2>&1
```

### Testing the Cron Command

Run the command manually to verify it works:

```bash
/path/to/agent-ops-workflow/scripts/gerar-plano-diario.sh \
  /Users/your-user/my-project --tasks=5
```

Output should be:

```
[INFO]  Plano diário gerado com sucesso:
[INFO]    Local: /Users/your-user/my-project/planejamento-diario/YYYY-MM-DD/PLANO.md
[INFO]    Data: DD/MM/YYYY
[INFO]    Tasks por wave: 5
```

### Cron Options

| Option          | Description                                        |
|-----------------|----------------------------------------------------|
| `--tasks=N`     | Number of skeleton tasks per wave (default: 5)     |
| `--force, -f`   | Overwrite existing plan for today (use carefully)  |
| `--help, -h`    | Show help message                                  |

### Cron Log

The script appends to `planejamento-diario/cron.log` automatically. Monitor
this file for failures:

```bash
tail -f ~/my-project/planejamento-diario/cron.log
```

### Environment Variables for Cron

Cron runs with a minimal environment. Set these in your crontab:

```bash
# Before the cron command, set:
WORKFLOW_TEAM_NAME="Team Nova"
WORKFLOW_PROJECT_NAME="Project Atlas"
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
SLACK_HOME_CHANNEL=C0123456789

# Then the cron command
0 5 * * * export WORKFLOW_TEAM_NAME="Team Nova" WORKFLOW_PROJECT_NAME="Project Atlas"; /path/to/gerar-plano-diario.sh ~/my-project >> ~/my-project/planejamento-diario/cron.log 2>&1
```

Or use a wrapper script that sources environment variables first.

---

## Post-Setup Verification Checklist

Run through this checklist after completing the setup to confirm everything
is working correctly.

### Structure Check

```
~/my-project/
├── planejamento-diario/
│   ├── INDICE.md                     ← [ ] Exists and is valid markdown
│   ├── TEMPLATES/
│   │   ├── PLANO.md                  ← [ ] Copied from .tpl
│   │   ├── TASK.md                   ← [ ] Copied from .tpl
│   │   ├── INDICE.md                 ← [ ] Copied from .tpl
│   │   └── README-WORKFLOW.md        ← [ ] Optional, but helpful
│   └── YYYY-MM-DD/                   ← [ ] Today's folder exists
│       └── PLANO.md                  ← [ ] Contains skeleton plan
```

### Template Check

- [ ] `PLANO.md` has `__PLACEHOLDER__` values replaced with your team info
- [ ] `TASK.md` has correct agent names and default engines
- [ ] `INDICE.md` shows your project name in the header

### Script Check

```bash
# Run the validation script
./scripts/validate-workflow.sh ~/my-project

# Expected exit code: 0 (or 1 with warnings, which is acceptable for initial setup)
# If exit code 2, something is missing — fix before proceeding
```

### Slack Check

- [ ] Bot token is valid and has correct scopes
- [ ] Bot is invited to the home channel
- [ ] Channel ID is correct in Hermes config
- [ ] User IDs are documented in AGENTS.md
- [ ] Test message was sent and received

### Cron Check

- [ ] Cron job is scheduled (`crontab -l` shows the entry)
- [ ] Manual run produces no errors
- [ ] `cron.log` file exists in `planejamento-diario/`
- [ ] Plan was generated for the correct date

### Authentication Check

- [ ] Git can push to your remote (if using one)
- [ ] SSH key is loaded in ssh-agent
- [ ] Hermes can reach its API endpoint
- [ ] Slack tokens are not expired

---

## Troubleshooting

### Script Errors

| Error                                | Likely Cause                          | Fix                                             |
|--------------------------------------|---------------------------------------|-------------------------------------------------|
| `bash: ./scripts/*.sh: Permission denied` | Scripts not executable           | `chmod +x scripts/*.sh`                         |
| `Pasta de templates não encontrada`  | Running outside project root          | `cd agent-ops-workflow` first                   |
| `sed: RE error: illegal byte sequence` | macOS sed + non-ASCII chars         | Install GNU sed: `brew install gnu-sed`         |
| `date: illegal option`               | macOS date syntax issue               | Use `gdate` from coreutils if needed            |

### Slack Issues

| Issue                                | Likely Cause                          | Fix                                             |
|--------------------------------------|---------------------------------------|-------------------------------------------------|
| Bot does not respond to @mentions    | Bot not in channel                    | `/invite @TeamNovaBot`                          |
| `not_in_channel` error               | Bot not invited to channel            | Invite the bot user to the channel              |
| `invalid_auth` error                 | Token expired or wrong                | Regenerate token in Slack API dashboard         |
| Message not showing in thread        | Missing `thread_ts` parameter         | Always reply in thread, not as new message      |
| Scope missing error                  | Bot does not have required scope      | Add scope, reinstall app to workspace           |

### Cron Issues

| Issue                                | Likely Cause                          | Fix                                             |
|--------------------------------------|---------------------------------------|-------------------------------------------------|
| Cron job does not run                | PATH not set in cron                  | Use absolute paths or set PATH in crontab       |
| Cron produces no output              | stderr not redirected                 | Add `2>&1` to the cron command                  |
| Script runs but plan not generated   | Template missing                      | Run `setup-workflow.sh` first                   |

### Validation Failures

```bash
# If validate-workflow.sh returns errors, use --fix to auto-correct
./scripts/validate-workflow.sh ~/my-project --fix

# Run with --verbose to see all checks in detail
./scripts/validate-workflow.sh ~/my-project --verbose
```

Common validation warnings and how to resolve them:

| Warning                              | Resolution                                     |
|--------------------------------------|-------------------------------------------------|
| Contador incorreto no INDICE.md      | Run with `--fix` to auto-correct, or manually  |
| Task X: nenhum checkbox preenchido   | Fill in checkboxes in the task file             |
| PLANO.md lista N tasks, disco tem M  | Add or remove task files to match               |
| Pasta TEMPLATES/ vazia              | Re-run `setup-workflow.sh` to copy templates   |

---

## Next Steps

Once setup is complete, your team is ready for the first daily cycle.

1. **Read the Daily Cycle Guide** (`02-DAILY-CYCLE.md`) — Understand the 6
   phases (Plan → Approve → Delegate → Execute → Audit → Report).

2. **Read the Slack Protocol** (`03-SLACK-PROTOCOL.md`) — Learn how agents
   communicate, the mention system, thread rules, and lockdown procedures.

3. **Run your first dry cycle** — Create a test day with 1-2 tasks, run
   through all 6 phases, and verify the loop closes cleanly.

4. **Customize your templates** — Edit `TEMPLATES/` files to match your
   team's conventions, preferred engines, and language.

5. **Invite your team** — Share `AGENTS.md`, the home channel invite link,
   and the cron schedule. Make sure everyone knows the golden rules.

---

## Quick Reference

```bash
# Initialize a new project
./scripts/setup-workflow.sh ~/new-project "Team Nova" "Nova Project"

# Generate today's plan (manual)
./scripts/gerar-plano-diario.sh ~/new-project

# Validate structure
./scripts/validate-workflow.sh ~/new-project

# Validate and auto-fix
./scripts/validate-workflow.sh ~/new-project --fix

# Rotate SSH key
./scripts/rotate-key.sh id_nova
```

---

## Environment Variables Reference

| Variable                  | Used By                  | Purpose                          |
|---------------------------|--------------------------|----------------------------------|
| `WORKFLOW_TEAM_NAME`      | setup, gerar-plano       | Team name for placeholders       |
| `WORKFLOW_PROJECT_NAME`   | setup, gerar-plano       | Project name for placeholders    |
| `SLACK_BOT_TOKEN`         | Hermes Slack integration | Bot authentication               |
| `SLACK_APP_TOKEN`         | Hermes Slack integration | App-level socket mode            |
| `SLACK_HOME_CHANNEL`      | Hermes Slack integration | Default operations channel       |

---

> Setup complete. Your team now has a production-tested multi-agent daily
> planning system running on Hermes. The next step is learning the daily
> cycle — head to `02-DAILY-CYCLE.md`.
