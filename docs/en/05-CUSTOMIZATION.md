# Customization Guide — Agent Ops Workflow

> Complete guide to customizing the Agent Ops Workflow for your team — agent
> names, roles, engine hierarchy, Slack configuration, template adaptation,
> and migration planning. Every team is different; this guide helps you make
> the workflow yours.

---

## Table of Contents

1. [Overview: The Customization Philosophy](#overview-the-customization-philosophy)
2. [Choosing Agent Names](#choosing-agent-names)
3. [Defining Roles](#defining-roles)
4. [LLM Engine Hierarchy](#llm-engine-hierarchy)
5. [Setting Up Slack Channels](#setting-up-slack-channels)
6. [Adapting Templates](#adapting-templates)
7. [Complete Example — Team Elemental](#complete-example--team-elemental)
8. [Migration Checklist](#migration-checklist)

---

## Overview: The Customization Philosophy

The Agent Ops Workflow is intentionally generic. Templates use `__PLACEHOLDER__`
syntax, skills use `{{PLACEHOLDER}}` syntax, and both can be adapted to any
team structure. The workflow does not assume your team size, your naming
convention, your preferred AI models, or your Slack channel topology.

There is **one golden rule of customization**:

> Change everything that makes the workflow yours. Change nothing that breaks
> the protocol.

That means:
- Agent names, team themes, and Slack channels are yours to define — be
  creative.
- The 6-phase cycle (Plan → Approve → Delegate → Execute → Audit → Report)
  stays the same.
- The @mention format, thread rules, and silence rule stay the same.
- The template structure (PLANO.md, TASK.md, INDICE.md) stays the same.
- The `{{PLACEHOLDER}}` / `__PLACEHOLDER__` convention stays the same.

---

## Choosing Agent Names

Agent names are the identity layer of your workflow. Good names are:
- **Distinct** — No two agents sound similar (avoids confusion)
- **Memorable** — Easy to type in Slack @mentions
- **Role-appropriate** — The name hints at the agent's function
- **Consistent** — Follow the same theme across all agents

### Theme Ideas

#### Elements (Earth, Fire, Water, Air)

| Role | Element Name | Rationale |
|------|-------------|-----------|
| Orchestrator | Aether | The fifth element — binds everything together |
| Backend | Terra | Earth — foundation, stable, reliable |
| Frontend | Ignis | Fire — visible, dynamic, interactive |
| DevOps | Ventus | Air — invisible infrastructure, always moving |
| Auditor | Aqua | Water — clear, reflective, sees through things |
| GitOps | Ferrum | Iron — tools, mechanics, version control |

#### Gems and Minerals

| Role | Gem Name | Rationale |
|------|----------|-----------|
| Orchestrator | Diamond | Hardest, clearest, central |
| Backend | Onyx | Dark, solid, foundation |
| Frontend | Ruby | Bright, visible, engaging |
| DevOps | Quartz | Precise, timekeeping, infrastructure |
| Auditor | Sapphire | Clear, analytical, valuable |
| GitOps | Obsidian | Sharp, tool-like, efficient |

#### Celestial Bodies

| Role | Celestial Name | Rationale |
|------|---------------|-----------|
| Orchestrator | Sol | The sun — center of the system |
| Backend | Terra (Earth) | Ground, data, persistence |
| Frontend | Luna | Visible, reflects light, interface |
| DevOps | Nova | Explosive change, infrastructure events |
| Auditor | Stella | Star — constant, reliable observer |
| GitOps | Cometa | Fast, predictable orbit, tool |

#### Mythological Figures

| Role | Myth Name | Rationale |
|------|-----------|-----------|
| Orchestrator | Athena | Goddess of wisdom, strategy |
| Backend | Hephaestus | God of forge, craftsmanship, building |
| Frontend | Apollo | God of arts, appearance, interface |
| DevOps | Hermes | Messenger, travel, infrastructure |
| Auditor | Themis | Goddess of justice, order |
| GitOps | Clio | Muse of history, records, versioning |

#### Norse Mythology

| Role | Norse Name | Rationale |
|------|-----------|-----------|
| Orchestrator | Odin | All-father, overseer, wisdom |
| Backend | Thor | Strength, protection, foundation |
| Frontend | Freya | Beauty, love, visible arts |
| DevOps | Heimdall | Guardian, watchman, infrastructure |
| Auditor | Forseti | God of justice, arbitration |
| GitOps | Mimir | Keeper of knowledge, records |

#### Machines / Robotics

| Role | Machine Name | Rationale |
|------|-------------|-----------|
| Orchestrator | Prime | Leader, primary, central |
| Backend | Core | Foundation, processing, storage |
| Frontend | Pixel | Display, rendering, interface |
| DevOps | Relay | Signal routing, infrastructure |
| Auditor | Sensor | Detection, verification, monitoring |
| GitOps | Gear | Mechanism, precision, version control |

#### Computing Concepts

| Role | Concept Name | Rationale |
|------|-------------|-----------|
| Orchestrator | Kernel | Core of the operating system |
| Backend | Cache | Fast, persistent, foundational |
| Frontend | Render | Display, visualization, output |
| DevOps | Proxy | Routing, security, infrastructure |
| Auditor | Checksum | Verification, integrity, validation |
| GitOps | Rebase | Git operation, history management |

### Naming Rules

1. **One name per agent.** Never reuse a name across roles or environments.
2. **No spaces in Slack display names.** Use `nova-orch` not `Nova Orch`.
3. **Match AGENTS.md to Slack.** If you rename a Slack bot, update AGENTS.md
   immediately.
4. **Cross-reference consistently.** If the orchestrator is `Aether` on Mac
   and `Diamond` on the server, document both in AGENTS.md with environment
   labels.

---

## Defining Roles

The Agent Ops Workflow defines **6 standard roles**. You can add more, but
these are the minimum for a healthy multi-agent operation.

### Standard Role Definitions

| Role | Tag | Responsibility | Slack Posts | Hermes Profile Required? |
|------|-----|---------------|-------------|--------------------------|
| **Commander** | Human | Reviews plans, gives final approval, issues lockdowns | Yes — top-level only | No (human) |
| **Orchestrator** | `@aria` | Creates plans, delegates tasks, audits work, produces reports | Yes — top-level + audit threads | Yes |
| **Backend Engineer** | `@terra` | Executes backend/coding tasks, commits, reports in threads | No — thread replies only | Yes |
| **Frontend Engineer** | `@ignis` | Executes frontend/UI tasks (typically uses Opus for vision work) | No — thread replies only | Yes |
| **DevOps Engineer** | `@ventus` | Infrastructure, deployment, CI/CD, server maintenance | No — thread replies only | Yes |
| **Auditor** | `@aqua` | Cross-checks completed tasks, verifies commits, signs off | No — thread replies only | Optional (orchestrator can audit) |
| **GitOps** | `@ferrum` | Git operations, version control, vault sync | No — thread replies only | Optional (utility agent) |

### Adding or Removing Roles

**To add a role (e.g., Data Scientist, QA, Product Manager):**

1. Define the role's responsibilities in a new row in the table above.
2. Create a Slack user for the role (if bot-based) or assign a human.
3. Add the role to AGENTS.md.
4. Update templates to reference the new role in delegation messages.
5. Document any engine constraints specific to the role.

**To remove a role (e.g., merging Auditor into Orchestrator):**

1. Update AGENTS.md — remove the role row.
2. Reassign any standing tasks that reference the role.
3. Update delegation templates to remove role-specific instructions.
4. Update the COMPLETE EXAMPLE section in this document.

### Role Assignment Best Practices

| Team Size | Recommended Setup |
|-----------|-------------------|
| 1 person (solo) | Commander + Orchestrator (same human). One coding agent does everything. Auditor is the orchestrator. |
| 2-3 people | Commander (human) + Orchestrator (bot) + 1-2 coding agents. Orchestrator also audits. |
| 4-6 people | Commander + Orchestrator + Backend + Frontend + DevOps + Auditor. Full separation of concerns. |
| 7+ people | Commander + Orchestrator + 2 Backend + 2 Frontend + DevOps + Auditor + GitOps. Multiple specializations. |

### Cross-Machine / Multi-Environment Roles

If you run agents on multiple machines (e.g., local Mac + cloud server), each
environment gets its own set of role instances. Document the mapping:

| Role | Local (Mac) | Cloud (Server) |
|------|-------------|----------------|
| Orchestrator | `@aria-mac` | `@aria-server` |
| Backend | `@terra-mac` | `@terra-server` |
| ... | ... | ... |

The two orchestrators coordinate as equals — no hierarchy cross-environments.
Each orchestrator manages only its own environment's agents.

---

## LLM Engine Hierarchy

The workflow supports multiple AI models (engines) with a strict priority
hierarchy. The default engine for coding tasks is Gemini 3.1 Pro. Other
engines are assigned based on task requirements.

### Standard Engine Hierarchy

| Priority | Engine | Primary Use Case | When to Use |
|:--------:|--------|-----------------|-------------|
| **1** | Gemini 3.1 Pro | ALL standard coding tasks, configuration, documentation | Default — use for everything unless a specific exception applies |
| **2** | Opus 4.7 (Claude) | UI/vision/design tasks, complex audits, cross-DB data migrations | Frontend work, critical data operations, auditing third-party code |
| **3** | OpenCode Go / GLM 5.1 | Quick exploration, file operations, simple scripts | Small tasks, rapid prototyping, exploration |
| — | DeepSeek V4 / V4 Pro | **PROHIBITED** without explicit Commander order | Never — only if Commander specifically authorizes |

### Engine Selection Heuristic

Use this decision tree when assigning engines to tasks:

```
Is the task purely mechanical (config change, move files, simple edit)?
  → YES → Gemini 3.1 Pro (lowest cost, sufficient quality)
  → NO  → ↓

Does the task involve data migration with cross-DB foreign keys?
  → YES → Consider Opus 4.7 (risk of data loss justifies cost)
  → NO  → ↓

Is it a frontend/UI/design task (CSS, layout, visual components)?
  → YES → Opus 4.7 MANDATORY (Frontend Engineer)
  → NO  → ↓

Is it an audit of another agent's work?
  → YES → Opus 4.7 recommended (catches subtle errors better)
  → NO  → ↓

Is the task simple, well-defined, single-file, no irreversible actions?
  → YES → Gemini 3.1 Pro (sufficient for the job)
  → NO  → ↓

Default to Gemini 3.1 Pro. Escalate to Opus only if Gemini fails.
```

### Engine Constraint Formats

When delegating a task, include the engine mandate in the Slack message:

```markdown
**Engine:** Gemini 3.1 Pro (DEFAULT)
```

```markdown
**Engine:** Opus 4.7 (MANDATORY — UI/vision task)
```

```markdown
**ORDEM ABSOLUTA — Engine:** Gemini 3.1 Pro.
Do NOT switch. If you hit rate limits, split into subtasks.
```

### Engine Fallback Protocol

If the assigned engine fails (rate limit, API error, timeout):

1. **Split the task** into smaller subtasks and retry with the same engine.
2. If splitting does not resolve the issue, **stop and report** to the
   orchestrator.
3. The orchestrator may escalate to the Commander for authorization to switch
   engines.
4. **Never switch engines without authorization.** This is a protocol
   violation.

### Multiple Engines on the Same Task

For complex tasks, the orchestrator can assign different engines to different
steps. For example:

```
Task: Migrate user data from legacy system
  Step 1 (data extraction): Opus 4.7 — complex SQL with cross-DB FKs
  Step 2 (transformation): Gemini 3.1 Pro — mechanical ETL
  Step 3 (verification): Opus 4.7 — audit data integrity
```

Document multi-engine assignments in the task file's Instructions section.

---

## Setting Up Slack Channels

Slack is the communication layer for the Agent Ops Workflow. You can set up
one channel (simple) or multiple channels (advanced). Both configurations work
with the same protocol rules.

### Single Channel (Recommended for Teams of 1-5)

```
Channel: #agent-ops-{teamname}
Purpose: Planning, delegation, execution updates, audit results, reports
```

All communication happens in this one channel. Threads keep task conversations
isolated. This is the simplest setup and works well for small teams.

### Multi-Channel Setup (Teams of 6+)

| Channel | Purpose | Who Posts |
|---------|---------|-----------|
| `#agent-ops-{teamname}` | Daily planning, approvals, reports | Commander, Orchestrator |
| `#{teamname}-execution` | Delegation messages and execution threads | Orchestrator, Agents |
| `#{teamname}-audit` | Audit results and cross-checks | Orchestrator, Auditor |
| `#{teamname}-alerts` | Lockdown signals, critical errors | Commander only |

### Channel Naming Convention

```yaml
#agent-ops-{teamname}          # Main operations
#agent-ops-{teamname}-exec     # Execution threads
#agent-ops-{teamname}-audit    # Audit channel
#agent-ops-{teamname}-alerts   # Emergency alerts
```

### Creating a Slack App for Your Team

Each agent that needs to send/receive Slack messages requires a Slack app (bot).
Here is the step-by-step process:

#### Step 1: Create the App

1. Go to https://api.slack.com/apps
2. Click **Create New App** → **From Scratch**
3. Name it (e.g., `Team Elemental Agent Ops`) and select your workspace
4. Click **Create App**

#### Step 2: Configure Bot Token Scopes

Navigate to **OAuth & Permissions** → **Scopes** → **Bot Token Scopes**.
Add these scopes:

| Scope | Purpose |
|-------|---------|
| `channels:history` | Read channel history (find threads) |
| `channels:read` | View channel info and member lists |
| `chat:write` | Send messages and post in threads |
| `reactions:read` | Read emoji reactions (audit signals) |
| `users:read` | Read user info (resolve @mentions) |

#### Step 3: Install the App

1. Under **OAuth & Permissions**, click **Install to Workspace**
2. Review the permissions and click **Allow**
3. Copy the **Bot User OAuth Token** (`xoxb-...`)

#### Step 4: Get the App-Level Token

1. Go to **Basic Information** → **App-Level Tokens** → **Generate Token**
2. Add scopes: `connections:write`, `authorizations:read`
3. Name it (e.g., `ws-token`) and copy the resulting token (`xapp-...`)

This token enables Socket Mode, which lets the agent connect to Slack without
exposing a public HTTP endpoint.

#### Step 5: Find Your Workspace IDs

**Channel ID:**
```bash
# Right-click channel name → Copy Link
# Extract from URL: https://workspace.slack.com/archives/C0123456789
```

**User IDs for your agents:**
```bash
# Method 1: Slack UI
# Click user profile → More → Copy member ID

# Method 2: Slack API
curl -H "Authorization: Bearer xoxb-..." \
  https://slack.com/api/users.list | jq '.members[] | {name: .name, id: .id}'
```

#### Step 6: Configure Hermes

Add to your Hermes config or environment:

```yaml
# ~/.hermes/config.yaml (profile-specific)
profiles:
  aria:
    slack:
      enabled: true
      bot_token: xoxb-...
      app_token: xapp-...
      home_channel: C0123456789
```

Or set environment variables:

```bash
export SLACK_BOT_TOKEN=xoxb-...
export SLACK_APP_TOKEN=xapp-...
export SLACK_HOME_CHANNEL=C0123456789
```

#### Step 7: Invite the Bot to Channels

In each channel the bot needs to operate in:

```
/invite @TeamElementalBot
```

Bot cannot read or write in channels it has not been invited to.

#### Step 8: Create AGENTS.md

Document your team's Slack mapping in the project root:

```markdown
# Agent Roster — Team Elemental

| Name | Role | Slack User ID | Default Engine |
|------|------|---------------|----------------|
| Aria | Orchestrator | <@U0123456789> | Gemini 3.1 Pro |
| Terra | Backend | <@U9876543210> | Gemini 3.1 Pro |
| Ignis | Frontend | <@U5555555555> | Opus 4.7 |
| Ventus | DevOps | <@U4444444444> | Gemini 3.1 Pro |
| Aqua | Auditor | <@U3333333333> | Opus 4.7 |
```

---

## Adapting Templates

Templates in `agent-ops-workflow/templates/` use `__PLACEHOLDER__` syntax.
When you run `setup-workflow.sh`, these are copied to your project's
`planejamento-diario/TEMPLATES/` directory. You can (and should) customize them.

### What to Customize

#### PLANO.md.tpl

| Section | What to Change | Example |
|---------|---------------|---------|
| Header | Team name, Commander name | `Team Elemental`, `Commander Alex` |
| Resources | Your project's real URLs and repos | GitHub, CI/CD, staging |
| Waves | Wave names and times | `Wave 1 — Morning (8-12)` |
| Rules | Team-specific conventions | Language, max threads, audit rules |
| Metrics | Your team's target metrics | Test coverage, deploy frequency |

#### TASK.md.tpl

| Section | What to Change | Example |
|---------|---------------|---------|
| Required Reading | Your project's doc links | PRD, Blueprint, API docs |
| Restrictions | Team-specific constraints | `NUNCA modificar config/producao/` |
| Checklist | Standard verification items | `Testes unitarios passaram` |
| Conclusion | Custom fields if needed | Add `Jira ticket` if you use Jira |

#### INDICE.md.tpl

| Section | What to Change | Example |
|---------|---------------|---------|
| Header | Your project name | `Project Olympus` |
| Legend | Custom symbols if needed | Keep standard ✅ 👁 ⬜ |
| Progress section | Custom wave names | Match your PLANO.md waves |

### Customizing Execution Rules

The execution rules section in PLANO.md is the most team-specific part of the
template. Here are examples for different team types:

**Small team (2-3 people):**
```markdown
## Rules of Execution

1. **Default engine:** Gemini 3.1 Pro
2. **Work in branches** — never commit directly to main
3. **Language:** English (US) for all docs and commits
4. **Max concurrent threads:** 2 agents
5. **Audit:** Orchestrator audits all completed tasks
6. **Commit style:** `type(scope): description` (e.g., `feat(api): add login endpoint`)
```

**Full team (6+ people):**
```markdown
## Rules of Execution

1. **Default engine:** Gemini 3.1 Pro (ALL coding)
2. **Frontend tasks:** Opus 4.7 MANDATORY (assigned to Frontend Engineer)
3. **Data migrations:** Opus 4.7 recommended (cross-DB FKs)
4. **NEVER modify production config** — work in copies
5. **Repository:** Commit only sanitized content; secrets go in .env
6. **Language:** English (US)
7. **Max concurrent threads:** 4 agents
8. **Audit:** Every completed task MUST be cross-reviewed by a different agent
9. **Lockdown:** Commander's "LOCKDOWN" freezes all operations immediately
```

### Language Switch

The templates default to Portuguese (pt-BR). To switch to English (US):

1. Set `IDIOMA="en-US"` during `setup-workflow.sh`
2. Edit `TEMPLATES/PLANO.md` — translate section headers, rules, and labels
3. Edit `TEMPLATES/TASK.md` — translate section headers and instructions
4. Edit `TEMPLATES/INDICE.md` — translate header and legend

Key translations for section headers:

| Portuguese | English |
|-----------|---------|
| Plano de Execucao | Execution Plan |
| Recursos do Projeto | Project Resources |
| Resumo | Summary |
| Waves | Waves |
| Dependencias | Dependencies |
| Regras da Execucao | Execution Rules |
| Ao final do dia | End of Day Checklist |
| Metricas-alvo | Target Metrics |
| Leitura Obrigatoria | Required Reading |
| Contexto | Context |
| Instrucoes | Instructions |
| Checklist | Checklist |
| Restricoes | Constraints |
| Arquivos relevantes | Relevant Files |
| Conclusao | Conclusion |

---

## Complete Example — Team Elemental

This is a full worked example of a customized team. Team Elemental uses the
Elements naming theme and runs a full 6-role setup.

### Team Overview

| Attribute | Value |
|-----------|-------|
| Team Name | Team Elemental |
| Project | Project Olympus |
| Commander | Alex (human) |
| Orchestrator | Aria (bot) |
| Slack Channel | `#agent-ops-elemental` |
| Default Engine | Gemini 3.1 Pro |
| Documentation Language | English (US) |

### Role Assignments

| Name | Role | Slack @ | Slack User ID | Default Engine | Expertise |
|------|------|---------|---------------|----------------|-----------|
| Alex | Commander | `@alex` | Human | N/A (human) | Product, strategy |
| Aria | Orchestrator | `@aria` | `U0AA01A1A1A` | Gemini 3.1 Pro | Planning, delegation, audit |
| Terra | Backend | `@terra` | `U0BB02B2B2B` | Gemini 3.1 Pro | Python, Django, APIs |
| Ignis | Frontend | `@ignis` | `U0CC03C3C3C` | Opus 4.7 | React, CSS, UI |
| Ventus | DevOps | `@ventus` | `U0DD04D4D4D` | Gemini 3.1 Pro | Docker, CI/CD, OVH |
| Aqua | Auditor | `@aqua` | `U0EE05E5E5E` | Opus 4.7 | Code review, security |

### AGENTS.md

```markdown
# Agent Roster — Team Elemental

| Name | Role | Slack User ID | Default Engine |
|------|------|---------------|----------------|
| Aria | Orchestrator | <@U0AA01A1A1A> | Gemini 3.1 Pro |
| Terra | Backend | <@U0BB02B2B2B> | Gemini 3.1 Pro |
| Ignis | Frontend | <@U0CC03C3C3C> | Opus 4.7 |
| Ventus | DevOps | <@U0DD04D4D4D> | Gemini 3.1 Pro |
| Aqua | Auditor | <@U0EE05E5E5E> | Opus 4.7 |

**Commander:** Alex (human) — reviews plans, gives approval, issues lockdowns.
**Orchestrator:** Aria — creates plans, delegates, audits, reports.
```

### Slack Configuration

- **Main channel:** `#agent-ops-elemental` (ID: `C0AA01A1A1A`)
- **Bot token:** `xoxb-...` (stored in Hermes config, never in git)
- **App token:** `xapp-...` (Socket Mode)
- **All agents invited to:** `#agent-ops-elemental`

### Template Customizations

In `PLANO.md.tpl` (English), the execution rules section:

```markdown
## Rules of Execution

1. **Default engine:** Gemini 3.1 Pro
2. **Frontend tasks (UI/CSS/vision):** Opus 4.7 MANDATORY — assigned to @ignis
3. **Data migrations with cross-DB FKs:** Opus 4.7 recommended
4. **NEVER modify original files** — work in copies or branches
5. **Commit only sanitized content** — secrets stay in .env
6. **Language:** English (US) for all documentation and commits
7. **Max concurrent threads:** 3 agents
8. **Audit:** EVERY completed task must be audited by @aqua before closure
9. **Lockdown:** Commander's "LOCKDOWN" / "sinal vermelho" freezes all ops
```

### Placeholder Map

```markdown
# Placeholder Map — Team Elemental / Project Olympus

{{PROJECT_PATH}} → /home/alex/project-olympus
{{PROJECT_NAME}} → Project Olympus
{{TEAM_NAME}} → Team Elemental
{{COMMANDER}} → Alex
{{ORCHESTRATOR}} → Aria
{{BACKEND_ENGINEER}} → Terra
{{FRONTEND_ENGINEER}} → Ignis
{{DEVOPS_ENGINEER}} → Ventus
{{AUDITOR}} → Aqua
{{SLACK_CHANNEL_TEAM}} → #agent-ops-elemental
{{SLACK_CHANNEL_TEAM_ID}} → C0AA01A1A1A
{{SLACK_ID_ORCHESTRATOR}} → U0AA01A1A1A
{{SLACK_ID_BACKEND}} → U0BB02B2B2B
{{SLACK_ID_FRONTEND}} → U0CC03C3C3C
{{SLACK_ID_AUDITOR}} → U0EE05E5E5E
{{SLACK_ID_DEVOPS}} → U0DD04D4D4D
```

### A Day in the Life of Team Elemental

**08:00** — Aria (orchestrator) checks yesterday's report, creates `PLANO.md`
with 3 waves and 6 tasks.

**08:15** — Alex (commander) reviews the plan, approves.

**08:20** — Aria delegates in `#agent-ops-elemental`:
```
<@U0BB02B2B2B> Task task_01: Refactor user model
**Engine:** Gemini 3.1 Pro (DEFAULT)
...
```

**08:25** — Terra acknowledges, starts work.

**09:00** — Terra completes task_01, commits, pushes, reports in thread.

**09:05** — Aria verifies the commit, reads the diff, updates PLANO.md and
INDICE.md. Reports: "✅ Audit passed for task_01."

**09:10** — Aria delegates task_02 (UI component) to Ignis with Opus mandate.

...repeats through the day...

**17:00** — Aria compiles daily report, posts in channel, commits all records.

---

## Migration Checklist

Use this checklist when migrating the Agent Ops Workflow to a new team or
environment. It covers everything from names to Slack to verification.

### Phase 1: Foundation (Before Setup)

- [ ] **Choose a team name** (e.g., `Team Elemental`)
- [ ] **Choose agent names** using one theme from this guide
- [ ] **Decide on roles** — minimum: Commander + Orchestrator + 1 coding agent
- [ ] **Decide on Slack topology** — single channel or multi-channel
- [ ] **Decide on AI engines** — default Gemini, with Opus exceptions
- [ ] **Choose documentation language** — English (US) or Portuguese (pt-BR)
- [ ] **Create the placeholder map** — list all `{{PLACEHOLDER}}` replacements

### Phase 2: Setup

- [ ] **Clone agent-ops-workflow** or copy the template repo
- [ ] **Run setup-workflow.sh** with your team/project info
- [ ] **Create Slack app(s)** for your agents
- [ ] **Configure bot token scopes** (channels:history, chat:write, etc.)
- [ ] **Install Slack app(s)** to your workspace
- [ ] **Copy bot tokens** and app-level tokens
- [ ] **Find and document channel IDs** (C-prefix)
- [ ] **Find and document user IDs** (U-prefix)

### Phase 3: Template Adaptation

- [ ] **Translate templates** to your language (if not English)
- [ ] **Customize PLANO.md** rules, resources, wave names
- [ ] **Customize TASK.md** restrictions, checklist items
- [ ] **Customize INDICE.md** header, progress section
- [ ] **Set engine hierarchy** in PLANO.md rules section

### Phase 4: Skill Adaptation

- [ ] **Copy sanitized skills** from `files/skills/sanitized/` to your project
- [ ] **Run placeholder replacement** (sed script or manual)
- [ ] **Verify no placeholders remain** — `grep -rn "{{" skills/`
- [ ] **Load essential skills** via `hermes skill_manage add`
- [ ] **Verify skills load correctly** — `hermes skill_manage list`

### Phase 5: Configuration

- [ ] **Create AGENTS.md** with all roles, Slack IDs, engines
- [ ] **Create PLACEHOLDER-MAP.md** for future reference
- [ ] **Configure Hermes profiles** for each agent (or one multi-role)
- [ ] **Set up slack config** in Hermes config.yaml or env vars
- [ ] **Invite bots** to all channels they need to operate in
- [ ] **Test Slack connectivity** — send a test message

### Phase 6: Validation

- [ ] **Run validate-workflow.sh** — check structure and consistency
- [ ] **Manually verify today's PLANO.md** — does it look right?
- [ ] **Create a test task** — walk through all 6 phases
- [ ] **Verify Slack delegation** — @mention works, thread created
- [ ] **Verify audit flow** — commit verification, INDICE/PLANO updates
- [ ] **Verify report flow** — consolidated table, final commit
- [ ] **Test lockdown protocol** — does "LOCKDOWN" freeze all agents?
- [ ] **Schedule daily cron** — `gerar-plano-diario.sh` at 5 AM

### Phase 7: Go Live

- [ ] **Announce to the team** — share AGENTS.md and session rules
- [ ] **First real day** — run the full 6-phase cycle
- [ ] **End-of-day retrospective** — what broke? What was confusing?
- [ ] **Update docs** based on lessons learned
- [ ] **Set quarterly review** of skills, templates, and roles

### Migration Troubleshooting

| Problem | Likely Cause | Solution |
|---------|-------------|----------|
| Slack bot does not respond | Bot not invited to channel | `/invite @YourBot` |
| Slack @mention does not work | Using display name instead of `<@USER_ID>` | Use `<@U...>` format |
| `hermes skill_view` shows nothing | Path to SKILL.md is incorrect | Verify the file exists |
| Template placeholders not replaced | Running old setup without customization | Edit TEMPLATES/ files directly |
| Agent uses wrong engine | Engine not specified in delegation | Add "ORDEM ABSOLUTA — Engine:" to message |
| INDICE.md counter always wrong | Not updated after each audit | Update immediately — make it a habit |
| Cron does not generate plan | Missing environment variables in crontab | Export WORKFLOW_TEAM_NAME, etc. |

---

> Customization is what makes the Agent Ops Workflow yours. Take the time to
> choose names that resonate, configure channels that fit your communication
> style, and adapt templates to your team's conventions. The protocol stays
> the same; the identity is yours to build.
