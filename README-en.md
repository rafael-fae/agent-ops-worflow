<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/status-active-2ea043?style=for-the-badge">
    <img alt="Agent Ops Workflow" src="https://img.shields.io/badge/status-active-2ea043?style=for-the-badge">
  </picture>
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge">
  <img alt="Version: v1.0.0" src="https://img.shields.io/badge/version-v1.0.0-8250df?style=for-the-badge">
  <img alt="Hermes Agent" src="https://img.shields.io/badge/built%20for-Hermes%20Agent-ff6b35?style=for-the-badge">
</p>

<h1 align="center">🤖 Agent Ops Workflow</h1>
<h3 align="center">Multi-Agent Daily Planning for Hermes</h3>

<p align="center">
  <strong><a href="README.md">📖 Leia em Português</a></strong>
</p>

<p align="center">
  A production-tested daily planning workflow for teams of AI agents running on <strong>Hermes</strong>.<br>
  Plan. Approve. Delegate. Execute. Audit. Report. — on repeat, every day.
</p>

<p align="center">
  <a href="#-quickstart">Quickstart</a> •
  <a href="#-the-problem">The Problem</a> •
  <a href="#-the-solution">The Solution</a> •
  <a href="#-features">Features</a> •
  <a href="#-repository-structure">Structure</a> •
  <a href="#-for-whom">For Whom</a>
</p>

---

## 🧠 The Problem

AI agents have **no persistent memory between sessions**. Every time a conversation starts, it's a clean slate — no context, no awareness of what happened yesterday, no understanding of the bigger picture. Without an external orchestration system, teams of agents suffer from:

- **Lost context** — yesterday's decisions vanish overnight
- **Duplicate work** — multiple agents unknowingly solving the same problem
- **Inconsistent engines** — the wrong model gets used for the wrong task
- **No audit trail** — who did what, when, and why? Nobody knows
- **Scattered progress** — no single source of truth for what's been done

When running a multi-agent operation, these problems compound exponentially. You need a system — not just good prompts.

---

## 🔁 The Solution

**Agent Ops Workflow** is a structured, repeatable daily cycle that gives your Hermes agent team a shared operating system. It's simple by design, rigorous by convention.

### The 6-Phase Cycle

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│   PLAN   │ ──→ │ APPROVE  │ ──→ │ DELEGATE │
└──────────┘     └──────────┘     └──────────┘
                                         │
                                         ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│  REPORT  │ ←── │  AUDIT   │ ←── │ EXECUTE  │
└──────────┘     └──────────┘     └──────────┘
```

| Phase | What Happens |
|-------|-------------|
| **📋 Plan** | The orchestrator creates a daily plan (`PLANO.md`) with waves, tasks, priorities, and dependencies |
| **✅ Approve** | A human (or lead agent) reviews and signs off on the plan before execution begins |
| **🎯 Delegate** | Tasks are assigned to specific agents via Slack or direct channel — one agent, one task |
| **⚡ Execute** | Each agent runs their task with the designated engine, following detailed instructions |
| **🔍 Audit** | A different agent cross-checks every completed task for quality and correctness |
| **📊 Report** | Results are logged, the index is updated, and progress is committed for the next cycle |

The cycle repeats daily. Each day starts from the previous day's report, creating a continuous chain of context.

---

## 🚀 Quickstart

Get a team running in under 60 seconds.

```bash
# 1. Clone the repository
git clone https://github.com/rafael-fae/agent-ops-worflow.git
cd agent-ops-workflow

# 2. Run the setup wizard
./scripts/setup-workflow.sh ~/my-project "{{TEAM_NAME}}" "{{PROJECT_NAME}}"

# 3. Review and customize your first daily plan
open planejamento-diario/$(date +%Y-%m-%d)/PLANO.md

# 4. (Optional) Schedule daily plan generation via cron
crontab -e
# Add: 0 5 * * * /path/to/scripts/gerar-plano-diario.sh ~/my-project --tasks=5
```

That's it. Your team now has a daily planning system. Customize the templates, add your agents, and start shipping.

---

## 📁 Repository Structure

```text
agent-ops-workflow/
│
├── planejamento-diario/        # 📅 Daily plans — the workflow running itself
│   ├── INDICE.md               # Master index with progress tracking
│   ├── 2026-06-03/             # Our own plan for creating this repo
│   │   ├── PLANO.md
│   │   ├── task_01.md
│   │   └── ...
│   └── TEMPLATE_PLANO.md
│
├── docs/                       # 📖 Main documentation (🇧🇷 pt-BR)
│   ├── 01-SETUP-WORKFLOW.md
│   ├── 06-CICLO-DIARIO.md
│   ├── 05-PROTOCOLO-SLACK.md
│   ├── 07-GUIA-SKILLS.md
│   ├── 02-PERSONALIZACAO-PERFIS.md
│   └── 11-REFERENCIA-RAPIDA.md
│
├── docs/en/                    # 🌐 English documentation (🇺🇸 en-US)
│   ├── 01-SETUP-INITIAL.md
│   ├── 02-DAILY-CYCLE.md
│   ├── 03-SLACK-PROTOCOL.md
│   ├── 04-SKILLS-GUIDE.md
│   ├── 05-CUSTOMIZATION.md
│   └── 06-QUICK-REFERENCE.md
│
├── templates/                  # 📄 Official templates (🇧🇷 pt-BR)
│   ├── PLANO.md.tpl
│   ├── TASK.md.tpl
│   ├── INDICE.md.tpl
│   └── README-WORKFLOW.md.tpl
│
├── templates/en/               # 🌐 English templates (🇺🇸 en-US)
│   ├── PLANO.md.tpl
│   ├── TASK.md.tpl
│   ├── INDEX.md.tpl
│   └── README-WORKFLOW.md.tpl
│
├── skills/                     # 🧠 Hermes skills (sanitized, 43 skills)
│   ├── operacao/               # Operational skills (29)
│   ├── devops/                 # DevOps skills (5)
│   ├── security/               # Security skills (2)
│   └── ...                     # + standalone skills (7)
│
├── scripts/                    # ⚙️ Automation
│   ├── setup-workflow.sh
│   ├── gerar-plano-diario.sh
│   ├── validate-workflow.sh
│   └── rotate-key.sh
│
├── README.md                   # 📖 Read this in Portuguese (🇧🇷 pt-BR)
├── README-en.md                # ← You are here (🇺🇸 en-US)
├── LICENSE                     # 📄 MIT
└── .gitignore
```

> **Note:** This repository already includes all documentation and ready-to-use templates. After initial setup, your `planejamento-diario/` folder will be generated automatically.

---

## ✨ Features

- **📝 Markdown Templates** — Fully commented, placeholder-driven templates for plans, tasks, and indexes. Copy, paste, adapt.
- **🔁 Daily Cycle Automation** — Cron-ready script (`gerar-plano-diario.sh`) that auto-generates daily plans at 5 AM.
- **🧩 Multi-Agent Delegation** — Assign tasks to specific agents with explicit engine requirements per task.
- **🔐 Slack Protocol** — Structured agent communication via Slack with mention-based dispatch and zero cross-talk.
- **📊 Audit Trail** — Every task has a conclusion section with agent, timestamp, engine used, and observations. Cross-audited by another agent.
- **✅ Built-in Validation** — `validate-workflow.sh` checks structure integrity, index counters, checkbox fill rates, and plan-to-disk consistency.
- **🌐 Language Agnostic** — Templates support any language. Switch between pt-BR and en-US by changing a single placeholder.
- **🔧 Engine Routing** — Pin specific AI engines (Opus, Gemini, GPT-4, etc.) per task to ensure the right model for the right job.
- **⚠️ Lockdown Protocol** — Emergency stop mechanism via Slack that freezes all agents instantly.
- **🔄 Self-Documenting** — The repository documents its own creation process via `planejamento-diario/`. Proof that it works.

---

## 🎯 For Whom

This workflow is designed for:

| Role | How They Benefit |
|------|-----------------|
| **Hermes Users** | Get a structured daily workflow that solves the no-memory problem out of the box |
| **Multi-Agent Teams** | Coordinate 3+ agents with clear task boundaries, engine assignments, and cross-auditing |
| **Orchestrators / Leads** | One person sets the daily plan, delegates, and reviews — no micromanagement needed |
| **Ops Engineers** | Automation scripts integrate with cron, CI/CD pipelines, and existing toolchains |
| **Open Source Contributors** | Clean templates and clear documentation make onboarding trivial |
| **Anyone running AI agents** | If you're running more than one agent per day, you need this system |

### Prerequisites

- **Hermes Agent** installed and configured
- **bash >= 4** (macOS / Linux)
- **git** for version control
- Optional: **Slack workspace** for agent communication channel

---

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [Setup Guide](docs/en/01-SETUP-INITIAL.md) | Install dependencies, configure Hermes, and initialize your first project |
| [Daily Cycle](docs/en/02-DAILY-CYCLE.md) | Step-by-step walkthrough of the 6-phase cycle |
| [Slack Protocol](docs/en/03-SLACK-PROTOCOL.md) | Agent communication patterns, mention system, and zero-cross-talk |
| [Skills Guide](docs/en/04-SKILLS-GUIDE.md) | How to adapt, sanitize, and share skills across teams |
| [Customization](docs/en/05-CUSTOMIZATION.md) | Choosing names, roles, engines, and practical examples |
| [Quick Reference](docs/en/06-QUICK-REFERENCE.md) | 1-page cheat sheet with commands, structure, and rules |
| [Daily Automation](docs/en/07-DAILY-AUTOMATION.md) | All automated flows: cron, Hermes, shell scripts, and monitoring |
| [GitHub Tokens for Agents](docs/en/08-AGENT-TOKENS.md) | Individual token setup for each Hermes agent to commit |

---

## 📄 License

This project is open source under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

This project would not be possible without the teachings and community of [**Pycodebr**](https://pycodebr.com.br/) ([GitHub](https://github.com/pycodebr)) and the **IA Master Elite**. The shared knowledge about agent architecture, workflow automation, and best practices with Hermes Agent was fundamental to building this workflow. Thank you!

---

<p align="center">
  <sub>Built for Hermes Agent teams. Fork it, adapt it, make it yours.</sub>
  <br>
  <sub>© 2026 — MIT License</sub>
</p>
