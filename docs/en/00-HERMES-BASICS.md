# 00 — Hermes Agent: Fundamentals and First Run

> **Purpose of this document:** Present Hermes Agent, its fundamental concepts,
> installation guides for macOS and Ubuntu, OpenCode Go (DeepSeek) provider configuration,
> creating your first agent profile, and initial run — all in clear, didactic English.
>
> **Target audience:** Developers, ops engineers, and AI enthusiasts who want to set up
> their first Hermes Agent from scratch.

---

## Table of Contents

1. [What is Hermes Agent?](#section-1-what-is-hermes-agent)
2. [Installation on macOS](#section-2-installation-on-macos)
3. [Installation on Ubuntu](#section-3-installation-on-ubuntu)
4. [Configuring the OpenCode Go Provider (DeepSeek)](#section-4-configuring-the-opencode-go-provider-deepseek)
5. [Creating Your First Agent Profile](#section-5-creating-your-first-agent-profile)
6. [First Run](#section-6-first-run)

---

## Section 1: What is Hermes Agent?

**Hermes Agent** is a **framework for autonomous AI agents** that operate directly
in the terminal. Unlike a common chatbot (which only answers questions in a chat
window), a Hermes agent **executes real actions**: it reads and writes files, runs
shell commands, browses the web, manages Git repositories, and even communicates via Slack.

### 3-Pillar Architecture

| Concept | What it is | Example |
|---------|-----------|---------|
| **Independent Profiles** | Each agent is a folder with its own identity, personality, and configuration | `~/.hermes/profiles/devops/`, `~/.hermes/profiles/writer/` |
| **Gateway** | Server mode that exposes the agent via API/Slack | `hermes --profile devops gateway run` |
| **Skills** | Procedural memory modules — knowledge about how to do something | Git skill, Docker skill, deploy skill |

### What Makes a Hermes Agent Different from a Chatbot?

| Feature | Chatbot (ChatGPT, Claude Web) | Hermes Agent |
|---------|-------------------------------|--------------|
| **Memory** | Ephemeral (dies with session) | **Permanent** — files, logs, context saved to disk |
| **Tools** | None (text only) | **Terminal, filesystem, browser, Git, Slack** |
| **Autonomy** | None (you copy/paste everything) | **Executes commands, writes code, deploys on its own** |
| **Identity** | Generic | **Configurable personality via system_prompt + SOUL.md** |
| **Offline/End** | Dies when you close the browser | **Keeps existing — you reactivate the profile** |

### Supported AI Providers

Hermes Agent is **provider-agnostic**. You can use:

- **OpenAI** — GPT-4o, GPT-4o-mini, o-series
- **Anthropic** — Claude 3.5 Sonnet, Claude 3 Opus
- **OpenCode Go** — DeepSeek V4 Flash and V4 Pro (gateway)
- **Google** — Gemini 1.5 Pro, Gemini 2.0 Flash

---

## Section 2: Installation on macOS

### Prerequisites

| Requirement | Minimum Version | How to Check |
|-------------|-----------------|--------------|
| **Python** | 3.11+ | `python3 --version` |
| **Homebrew** | Any | `brew --version` |
| **Git** | 2.x | `git --version` |
| **Bash** | 4+ | `bash --version` |

> ⚠️ **Bash 4+ is mandatory on macOS.** macOS comes with Bash 3.2 by default
> (very old). Install the modern version:
>
> ```bash
> brew install bash
> # Check the new bash location:
> which bash            # Should show /opt/homebrew/bin/bash
> ```

### Method 1: pip Installation (Recommended)

```bash
pip install hermes-agent
```

After installation, verify:

```bash
hermes --version
```

If the command is not found, your `PATH` probably doesn't include
`~/.local/bin`. Fix with:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
hermes --version
```

### Method 2: Homebrew Installation

```bash
brew install nousresearch/tap/hermes
```

Verify:

```bash
hermes --version
```

### Timezone — Mandatory Configuration

Hermes Agent **requires** the timezone to be set on the system and in the profile.
On macOS:

```bash
# Check current timezone
sudo systemsetup -gettimezone

# If you need to change (example: America/New_York)
sudo systemsetup -settimezone America/New_York
```

Or via `timedatectl` (if available on macOS via brew):

```bash
brew install coreutils
timedatectl list-timezones | grep -i new_york
```

### Common macOS Troubleshooting

#### 1. `hermes: command not found`
**Cause:** `~/.local/bin` is not in PATH.
**Solution:** Add to `~/.zshrc` as shown above.

#### 2. Permission error: `Permission denied` when installing pip packages
**Cause:** Python installed via Homebrew with site-packages directory permissions.
**Solution:**
```bash
# Use a virtualenv or install with --user
pip install --user hermes-agent
```

#### 3. Sandboxd blocking execution
**Cause:** macOS Sandbox or TCC (Transparency, Consent, and Control) blocking
access to files/folders.
**Solution:**
- Go to **System Preferences → Privacy & Security → Files and Folders**
- Allow Terminal (or iTerm2) to access the folder where Hermes operates
- Alternatively: use Finder to drag the `~/.hermes` folder to Terminal
  when the permission prompt appears

#### 4. `bash: line 0: printf: `: invalid format character`
**Cause:** macOS Bash 3.2 is incompatible with Hermes.
**Solution:** Install Bash 4+ via Homebrew and configure Hermes to use it:

```bash
brew install bash
# In the agent profile file (explained in Section 5), configure:
# terminal:
#   bash_path: /opt/homebrew/bin/bash
```

#### 5. Error `dyld: Library not loaded` related to Python
**Cause:** Python was updated and native libraries lost their reference.
**Solution:**
```bash
brew reinstall python@3.11
pip install --force-reinstall hermes-agent
```

---

## Section 3: Installation on Ubuntu

### Prerequisites

```bash
# Python 3.11+
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git build-essential

# System dependencies required for native package compilation
sudo apt install -y python3-dev libffi-dev libssl-dev

# Verify installation
python3 --version
pip3 --version
git --version
```

### Installation via pip

```bash
pip3 install hermes-agent
```

Verify:

```bash
hermes --version
```

If not found, adjust PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
hermes --version
```

### Timezone — Mandatory Configuration

```bash
# Check current timezone
timedatectl

# List available timezones
timedatectl list-timezones | grep -i new_york

# Configure (example)
sudo timedatectl set-timezone America/New_York

# Confirm
timedatectl
```

### Common Ubuntu Troubleshooting

#### 1. `externally-managed-environment` error when using pip
**Cause:** Ubuntu 23.04+ blocks pip outside of virtualenv.
**Solution:**
```bash
# Option A — Use a virtualenv
python3 -m venv ~/hermes-env
source ~/hermes-env/bin/activate
pip install hermes-agent

# Option B — Force installation (not recommended)
pip install --break-system-packages hermes-agent
```

#### 2. Compilation error: `fatal error: Python.h: No such file or directory`
**Cause:** Missing `python3-dev` package.
**Solution:**
```bash
sudo apt install python3-dev
pip install --force-reinstall hermes-agent
```

#### 3. `ModuleNotFoundError: No module named '_cffi_backend'`
**Cause:** Missing `libffi-dev`.
**Solution:**
```bash
sudo apt install libffi-dev
pip install --force-reinstall hermes-agent
```

---

## Section 4: Configuring the OpenCode Go Provider (DeepSeek)

### What is OpenCode Go?

**OpenCode Go** is an API gateway that provides access to **DeepSeek** models —
high-quality Chinese language models known for excellent cost-benefit ratio. It works
as a proxy: you pay per usage directly on OpenCode, without needing a DeepSeek account.

### DeepSeek V4 Flash vs V4 Pro

| Feature | DeepSeek V4 Flash | DeepSeek V4 Pro |
|---------|-------------------|-----------------|
| **Speed** | ⚡ Very fast | 🐢 Slower (deeper reasoning) |
| **Cost** | 💰 Cheap (ideal for daily use) | 💵 Moderate |
| **Best for** | Simple code, file reading, routine tasks, prototyping | Complex debug, auditing, refactoring, deep analysis |
| **Context** | 128K tokens | 128K tokens |
| **Use when** | You want a quick answer without overthinking | The problem is hairy and needs analysis |

**Rule of thumb:** Always start with **Flash**. If the agent is making mistakes
or can't solve the problem, switch to **Pro**.

### Getting the API Key

1. Go to [opencode.ai](https://opencode.ai)
2. Create an account (or log in)
3. Go to **API Keys** in the user menu
4. Click **Create New Key**
5. Give it a name (e.g., "hermes-agent")
6. Copy the generated key — it starts with `oc_...`

### Setting the Environment Variable

```bash
# Add to your ~/.zshrc (macOS) or ~/.bashrc (Linux)
echo 'export OPENCODE_GO_API_KEY="oc_your_key_here"' >> ~/.zshrc
source ~/.zshrc

# Test if the variable is accessible
echo $OPENCODE_GO_API_KEY
```

### Testing the Connection

```bash
hermes run --model deepseek-v4-flash --prompt "Respond only 'OK' if you hear me."
```

If everything is configured correctly, Hermes will respond with "OK" or
a similar phrase. If an API key error appears, check if the environment
variable is correct.

> 💡 **Tip:** You can also set the API Key inside the agent profile's `.env`
> file (explained in Section 5), which is more secure and allows you
> to use different keys for each agent.

---

## Section 5: Creating Your First Agent Profile

### Directory Structure

Each Hermes agent lives inside `~/.hermes/profiles/`. Create the complete
structure for your first agent:

```bash
# Create the profile folder
mkdir -p ~/.hermes/profiles/my-first-agent

# Create support folders
mkdir -p ~/.hermes/profiles/my-first-agent/logs
mkdir -p ~/.hermes/profiles/my-first-agent/sessions
```

### `config.yaml` File

This is the heart of the profile. Each field has a specific purpose.

```yaml
# ~/.hermes/profiles/my-first-agent/config.yaml

model: deepseek-v4-flash
provider: opencode-go
base_url: https://api.opencode.ai/v1
api_mode: chat

# === Tools the agent can use ===
toolsets:
  - terminal    # Execute shell commands
  - filesystem  # Read, write, edit files
  - git         # Git operations
  - browser     # Web navigation (if needed)

# === Terminal ===
terminal:
  bash_path: /bin/bash           # macOS: /opt/homebrew/bin/bash
  working_directory: /home/your-user/your-project   # Default directory
  allowed_commands: []           # [] = all allowed (recommended)
  blocked_commands: []           # Blocked commands (e.g., rm -rf /)

# === Filesystem ===
filesystem:
  allowed_directories:
    - /home/your-user/your-project
    - /home/your-user/Documents
  blocked_patterns:              # Files the agent CANNOT read
    - "*.key"
    - "*.pem"
    - ".env"

# === Git ===
git:
  enabled: true
  allowed_repositories:
    - /home/your-user/your-project

# === Browser (optional) ===
browser:
  enabled: false                 # Enable only if needed

# === Slack Gateway (optional) ===
slack:
  enabled: false

# === Timezone (REQUIRED) ===
timezone: America/New_York
```

#### ⚠️ Why is `timezone` required?

Hermes Agent uses the timezone to:
- Stamp logs and messages with correct date/time
- Calculate deadlines and timers
- Organize sessions and chronological memories
- Ensure consistency between the system and the agent

**Without a configured timezone, the agent may refuse to start or operate
with wrong timestamps.**

### `.env` File

API keys go here, **outside the configuration file** (never
commit `.env` to Git if you ever version your profile):

```bash
# ~/.hermes/profiles/my-first-agent/.env

OPENCODE_GO_API_KEY=oc_your_key_here
```

### Identity and Personality Files

Each profile can (and should) contain files that define **who** the agent is.
This is what turns a generic LLM into a **character-driven assistant**.

#### `AGENTS.md` — Who Are the Team Members

```markdown
# AGENTS.md — Project Team

## Me (my-first-agent)
- Name: Dev Assistant
- Role: Main development agent
- Responsibilities: coding, review, deploy

## Humans
- Primary user's name (you define)
```

#### `SOUL.md` — The Agent's Soul and Values

```markdown
# SOUL.md — Soul of the Dev Assistant

## Purpose
Help the development team with code, automation, and documentation.

## Values
1. **Clarity** — Didactic and complete explanations
2. **Efficiency** — Solve the problem without beating around the bush
3. **Honesty** — Admit when you don't know something
4. **Safety** — Never execute destructive commands without confirmation
```

#### `IDENTITY.md` — Personality and Style

```markdown
# IDENTITY.md — Identity of the Dev Assistant

- Tone: professional but friendly
- Main language: English
- Code style: Modern Python with type hints
- Preferences: tests before implementation, documentation alongside code
- Weaknesses: no access to external data beyond what you provide
```

#### `TEAM.md` — Team Dynamics

```markdown
# TEAM.md — Team Dynamics

- I (assistant) execute tasks on demand
- The human (user) reviews before production deploy
- Feedback is logged for continuous learning
```

### Injecting the Daily Protocol into `system_prompt`

The **Daily Protocol** is a practice that gives the agent a structure for
thinking and acting. Inject it into the `system_prompt` of `config.yaml`:

```yaml
# Add this section to config.yaml
agent:
  system_prompt: |
    You are an autonomous development assistant.
    
    ## DAILY PROTOCOL
    1. On startup, read your SOUL.md and IDENTITY.md to remember who you are.
    2. Before each action, think: "Is this aligned with my purpose?"
    3. For destructive commands (rm, drop, delete), ASK FOR CONFIRMATION.
    4. Always explain what you're going to do BEFORE executing.
    5. At the end, summarize what was done and the results.
    6. If you encounter an error, log it and try an alternative approach.
    
    ## GUIDELINES
    - Prefer safe and reversible commands.
    - Use Git frequently to version changes.
    - When in doubt, ask the human.
```

> 💡 **Important tip:** The number of lines in `system_prompt` directly impacts
> cost (each call sends the entire prompt). Be concise but complete. Keep long
> details in `SOUL.md` and reference it in the prompt instead of copying everything.

### Final Profile Structure

```
~/.hermes/profiles/my-first-agent/
├── config.yaml         # Agent configuration
├── .env                # API keys (NEVER version)
├── AGENTS.md           # Who the agents/humans are
├── SOUL.md             # Purpose and values
├── IDENTITY.md         # Personality and style
├── TEAM.md             # Team dynamics
├── logs/               # Execution logs (created automatically)
└── sessions/           # Saved sessions (created automatically)
```

---

## Section 6: First Run

### CLI Mode (Single Command)

The simplest mode: you pass a command directly and the agent executes
and responds:

```bash
hermes --profile my-first-agent run --prompt "List the files in the current folder, show me the content of config.yaml, and tell me today's date."
```

The agent will:
1. Read the `config.yaml` to understand its profile
2. Read `SOUL.md`, `IDENTITY.md`, etc. to know who it is
3. Execute `ls` in the terminal
4. Read the `config.yaml` with the filesystem
5. Discover the current date
6. Respond with everything organized

### Gateway Mode (Slack / API)

To keep the agent **always available** (like a Slack bot):

```bash
hermes --profile my-first-agent gateway run
```

This starts a server that listens for messages from Slack (or a REST API)
and responds autonomously. See the official documentation for configuring
the Slack bot.

### Testing with Terminal Commands

Try these prompts to see the agent in action:

```bash
# Test 1: Command execution
hermes --profile my-first-agent run --prompt "Create a file called hello-world.txt with content 'Hello, Hermes Agent!'"

# Test 2: File reading
hermes --profile my-first-agent run --prompt "Read the hello-world.txt file we just created"

# Test 3: System information
hermes --profile my-first-agent run --prompt "Tell me which operating system we're running, how much free RAM we have, and how much disk space is available"

# Test 4: Git operation
cd /path/to/your/repository
hermes --profile my-first-agent run --prompt "Show the Git status, the last 3 commits, and tell me if there are unmerged branches"
```

### Checking Logs

Every agent interaction is logged. This is useful for debugging, auditing,
and for the agent itself to learn from past executions:

```bash
# List available logs
ls ~/.hermes/profiles/my-first-agent/logs/

# View the most recent log
cat ~/.hermes/profiles/my-first-agent/logs/$(ls -t ~/.hermes/profiles/my-first-agent/logs/ | head -1)
```

Logs contain:
- Timestamp of each action
- Executed command and its output
- Files read/written
- Agent decisions
- Errors encountered

---

## Template config.yaml

### ⚠️ Attention: Hermes Does NOT Create the Profile Folder Automatically

You need to create the structure manually:

```bash
mkdir -p ~/.hermes/profiles/my-agent/
```

### Complete Template

Copy and paste this content into `~/.hermes/profiles/my-agent/config.yaml`:

```yaml
# =============================================================================
# ~/.hermes/profiles/my-agent/config.yaml
# =============================================================================

# --- MODEL (WHICH AI TO USE) ---
model:
  default: deepseek-v4-flash
  provider: opencode-go
  base_url: https://opencode.ai/zen/go/v1
  api_mode: chat_completions

# Additional providers (optional)
providers: {}

# Fallback: if the main model fails, try this one
fallback_providers:
  - provider: opencode-go
    model: deepseek-v4-pro

# --- ENABLED TOOLS ---
toolsets:
  - terminal    # Execute shell commands
  - file        # Read, write, edit files
  - web         # Access URLs and make requests
  - browser     # Assisted web navigation
  - search      # Search files and code
  - memory      # Long-term memory
  - cronjob     # Schedule recurring tasks

# --- AGENT CONFIGURATION ---
agent:
  max_turns: 90              # Maximum actions per session
  gateway_timeout: 1800      # Gateway timeout in seconds (30 min)
  system_prompt: "You are my-agent. Here you define the personality."

# --- TERMINAL ---
terminal:
  backend: local
  cwd: .                     # Default working directory
  timeout: 180               # Timeout per command (3 min)

# --- TIMEZONE (REQUIRED!) ---
# CHANGE TO YOUR TIMEZONE! Examples:
#   America/New_York     (NY)
#   America/Chicago      (Chicago)
#   America/Denver       (Denver)
#   America/Los_Angeles  (LA)
#   Europe/London        (UK)
#   Europe/Lisbon        (PT)
timezone: America/New_York

# --- SLACK GATEWAY (optional) ---
slack:
  bot_user_id: U0XXXXXXX         # Bot ID in Slack
  bot_user_name: my-agent        # Bot username
  home_channel: C0XXXXXXX        # Main bot channel
  require_mention: true          # Only respond if mentioned
```

### Explanation of Each Section

| Section | Purpose |
|---------|---------|
| **model** | Defines which AI the agent will use. `default` is the main model; `provider` is the gateway serving the model; `base_url` is the API endpoint; `api_mode` defines the call format (`chat_completions` for conversational LLMs). |
| **fallback_providers** | If the main model is down or fails, Hermes automatically tries this secondary model. |
| **toolsets** | The tools the agent can use. Each gives a different power: `terminal` for running commands, `file` for file manipulation, `web` for accessing URLs, `browser` for interactive navigation, `search` for searching files, `memory` for remembering past conversations, `cronjob` for scheduling tasks. |
| **agent** | Execution limits. `max_turns` prevents infinite loops; `gateway_timeout` controls how long the gateway waits before giving up; `system_prompt` is the root instruction that defines the agent's personality. |
| **terminal** | Shell configuration. `backend: local` uses your machine's terminal; `cwd` is the directory where commands are executed; `timeout` prevents commands from hanging forever. |
| **timezone** | **Required.** Hermes uses the timezone for timestamps in logs, sessions, and Slack messages. If it's wrong, everything will have the wrong time. |
| **slack** | Slack bot configuration. Only needed if you want to talk to the agent via Slack. |

---

## Setup via Terminal (Simpler)

### Why Terminal Setup is Easier

Setting up via terminal is **MUCH easier** than editing YAML manually. You don't need to:
- Remember exact YAML syntax (indentation, hyphens, colons)
- Know where each field goes in the file
- Worry about typos that break parsing

Hermes commands are **self-documenting**: you immediately see what each configuration does.

### Basic Commands

```bash
# 1. CREATE THE PROFILE
# -----------------
# Official command (recommended):
hermes --profile my-agent init

# OR manually (if you prefer):
mkdir -p ~/.hermes/profiles/my-agent/


# 2. CONFIGURE THE MODEL VIA TERMINAL
# ------------------------------------
hermes --profile my-agent config set model.default deepseek-v4-flash
hermes --profile my-agent config set model.provider opencode-go
hermes --profile my-agent config set model.base_url https://opencode.ai/zen/go/v1


# 3. CONFIGURE TIMEZONE (easier than finding it in YAML!)
# ------------------------------------------------------
hermes --profile my-agent config set timezone America/New_York


# 4. VIEW THE COMPLETE CONFIGURATION
# ------------------------------
hermes --profile my-agent config show


# 5. ADD API KEYS TO .env
# -----------------------------------
# OpenCode key (REQUIRED to use DeepSeek)
echo 'OPENCODE_GO_API_KEY=sk-...' >> ~/.hermes/profiles/my-agent/.env

# Slack keys (if using the Slack bot)
echo 'SLACK_BOT_TOKEN=xoxb-...' >> ~/.hermes/profiles/my-agent/.env
echo 'SLACK_APP_TOKEN=xapp-...' >> ~/.hermes/profiles/my-agent/.env


# 6. TEST THE AGENT
# ------------------
hermes --profile my-agent run --prompt "Hello, who are you?"
```

### Terminal Advantages

- ✅ **No need to know YAML** — terminal commands are intuitive
- ✅ **Auto-completes** — Hermes suggests options if you make a mistake
- ✅ **Immediate feedback** — errors appear instantly, no mystery
- ✅ **Changes are instant** — no need to restart anything
- ✅ **History** — your terminal saves commands, you can repeat them later

---

## Simple vs Complete Setup

You can choose between two setup levels, depending on what you need:

### SIMPLE Setup (5 minutes)

Just the essentials for a functional agent:

```
1. mkdir -p ~/.hermes/profiles/my-agent/
2. Configure model via terminal (3 commands)
3. Add API key to .env
4. Test: hermes --profile my-agent run --prompt "test"
```

**Recommended for:** Testing Hermes for the first time, experimenting with the platform, quick proofs of concept.

**What you get at the end:**
- An agent that responds in the terminal
- Basic tools enabled (terminal, files, web)
- Ability to execute simple tasks

### COMPLETE Setup (2 hours)

Professional setup with personality, memory, and Slack integration:

```
1. Simple setup (above)
2. Create AGENTS.md, SOUL.md, IDENTITY.md, TEAM.md
3. Create operacional/DIARIO.md and ESTADO-DA-EQUIPE.md
4. Configure Slack (app, tokens, gateway)
5. Install agent-ops-workflow skills
6. Inject DAILY PROTOCOL into system_prompt
7. Start gateway
```

**Recommended for:** Daily use in real projects, teams needing continuous automation, multi-agent operations.

**What you get at the end:**
- Agent with defined personality (SOUL.md, IDENTITY.md)
- Long-term memory (state files)
- Slack bot responding 24/7
- Daily protocol (automatic planning and review)
- Ability to work in a team with other agents

> 💡 **Tip:** Start with the simple setup. After you feel confident, evolve to the complete setup. You don't need to do everything at once.

---

## Expanded Next Steps

Now that you have a functional agent, here are the next steps with detailed instructions:

### Automate with Cron

Hermes can execute tasks automatically at scheduled times — ideal for generating daily plans, audit reports, or syncing data.

#### Via System Cron (Most Reliable)

```bash
# Example: every day at 5 AM, generate a daily plan
# Edit the crontab:
crontab -e

# Add this line:
0 5 * * * /path/to/scripts/generate-daily-plan.sh ~/my-project --tasks=5

# The generate-daily-plan.sh script internally calls:
# hermes --profile my-agent run --prompt "Generate today's plan with 5 tasks"
```

#### Via Hermes Cron (Integrated with Agent)

```bash
# Create a cronjob that runs every day at 5 AM
hermes cronjob create \
  --name "daily-plan" \
  --schedule "0 5 * * *" \
  --prompt "Generate today's plan based on the current project state"
```

#### Automatic DuckDB Cache Refresh

If you use the DuckDB audit system, use the `export-cache.sh` script to periodically update the cache:

```bash
# In crontab:
*/30 * * * * /path/to/export-cache.sh
```

### Expand Your Team

Adding more agents is simple: repeat the process of creating a profile, configuring the model, and giving it a personality. Each agent can have a different role.

#### Role Suggestions

| Role | Personality | Tools | Purpose |
|------|-------------|-------|---------|
| **Admin Assistant** | Organized, concise | terminal, file, cronjob | Manage files, schedule tasks, maintain diaries |
| **Data Analyst** | Analytical, detail-oriented | terminal, file, web, search | Generate reports, analyze logs, cross-reference data |
| **Auditor** | Skeptical, rigorous | terminal, file, git | Review code, check compliance, detect anomalies |

#### Reusing the Same Slack Workspace

You can have multiple agents in the same Slack workspace. Each needs its own **Slack App** (or the same app with different bot names). Just create another profile and configure Slack with a unique bot name.

```bash
# Create a second agent
mkdir -p ~/.hermes/profiles/data-analyst/
# Configure model
hermes --profile data-analyst config set model.default deepseek-v4-flash
hermes --profile data-analyst config set model.provider opencode-go
# Add personality (create SOUL.md, IDENTITY.md, etc.)
```

### Create Your Own Skills

Skills are **procedural knowledge modules** that teach the agent how to do something specific. They live in markdown files inside the profile's `skills/` folder.

#### Skill Structure

```markdown
---
name: my-skill
description: What this skill does
---

# My Skill

## Trigger
- When the user asks to do X
- When Y happens in the workflow
- When the agent detects condition Z

## Instructions
1. First, check if the configuration file exists
2. If it exists, read and interpret the parameters
3. Execute the main action using available tools
4. Log the result in the skill log

## Pitfalls (COMMON TRAPS)
- Be careful with relative paths: always use absolute paths
- Don't assume environment variables exist — check first
- If the action fails, try an alternative approach instead of crashing
- Remember to ask for confirmation for destructive actions

## Examples
- `"Execute the project deploy"` → Read config, run tests, deploy
- `"Check system health"` → Check CPU, memory, disk, error logs
```

#### How to Install a Skill

```bash
# 1. Create the skills folder
mkdir -p ~/.hermes/profiles/my-agent/skills/

# 2. Create the skill file
touch ~/.hermes/profiles/my-agent/skills/my-skill.md

# 3. Edit with the content above (use your favorite editor)

# 4. Reference the skill in config.yaml (optional but recommended)
hermes --profile my-agent config set skills.my-skill enabled true
```

### Configure DuckDB Alerts

If you use the audit system with DuckDB, there is a **canary** mechanism that monitors data integrity.

#### How the Canary Works

The audit script compares the current record count with the historical average. If there's a variation **above 50%**, the script stops and issues an alert. This prevents corrupted or incomplete data from going unnoticed.

#### Configure Slack Notification

```bash
# Option 1: Slack Webhook (simple)
# Create a webhook in Slack and add it to the audit script:
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"ALERT: Variation detected in DuckDB cache!"}' \
#   YOUR_WEBHOOK_URL

# Option 2: Let the agent monitor itself
# Create a cronjob that checks the cache state periodically:
hermes cronjob create \
  --name "check-cache" \
  --schedule "0 */2 * * *" \
  --prompt "Check the DuckDB cache. If there's a >50% variation from the average, alert me immediately."
```

### Integrate with CI/CD

After code auditing, the orchestrator can trigger automatic deploys. This closes the cycle: code arrives → agent reviews → auditor approves → automatic deploy.

#### Pipeline Example

```
[Dev commits] → [Auditor agent reviews] → [Task approved]
                                            ↓
                                 [Orchestrator executes:]
                                 1. git push to main
                                 2. GitHub Actions detects the push
                                 3. CI/CD pipeline runs
                                 4. Deploy to staging/production
```

#### GitHub Actions Configuration

```yaml
# .github/workflows/deploy.yml
name: Automatic Deploy
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: |
          echo "Deploy triggered after Hermes Agent audit"
          # Your deploy commands here
```

> 💡 **Tip:** You can have the agent execute `git push` automatically after approval, or just have it prepare the merge request for human review. The autonomy level is configurable.

---

## Verification Checklist

Use this list to confirm everything is working:

- [ ] `hermes --version` displays the installed version
- [ ] `echo $OPENCODE_GO_API_KEY` shows your key (or it's in `.env`)
- [ ] `~/.hermes/profiles/my-first-agent/config.yaml` exists with `timezone` configured
- [ ] `~/.hermes/profiles/my-first-agent/.env` exists with the API key
- [ ] `AGENTS.md`, `SOUL.md`, `IDENTITY.md`, `TEAM.md` have been created
- [ ] The test command with `--prompt` returns a response without errors
- [ ] Logs were generated in `logs/`

---

> **Document generated in:** June 2026
> **Hermes Agent Version:** See `hermes --version`
> **Recommended Provider:** OpenCode Go (DeepSeek V4 Flash for daily use,
> V4 Pro for complex tasks)
