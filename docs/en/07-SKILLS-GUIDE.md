# Skills Guide — Agent Ops Workflow

> Complete reference for Hermes Agent skills: what they are, how to load them,
> how to adapt and create them, and how to troubleshoot them. This guide
> covers every skill in the sanitized repository.

---

## Table of Contents

1. [What Is a Hermes Skill?](#what-is-a-hermes-skill)
2. [Skill Anatomy](#skill-anatomy)
3. [The Placeholder System](#the-placeholder-system)
4. [How to Load Skills](#how-to-load-skills)
5. [Complete Skills Reference Table](#complete-skills-reference-table)
6. [How to Adapt Skills to Your Team](#how-to-adapt-skills-to-your-team)
7. [How to Create New Skills](#how-to-create-new-skills)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## What Is a Hermes Skill?

A Hermes skill is a reusable procedural document — a markdown file (or a
directory of files) that teaches an agent how to perform a specific task. Think
of it as a **playbook** or **standard operating procedure** that an agent can
load at runtime.

Skills are the building blocks of agent intelligence in the Agent Ops Workflow.
Instead of coding agent behavior in Python or JavaScript, you write skills in
markdown using natural language, structured sections, and `{{PLACEHOLDER}}`
variables that get replaced with your team's actual values.

### Why Skills Instead of Code?

| Aspect | Skills (Markdown) | Scripts (Code) |
|--------|-------------------|----------------|
| **Authoring** | Write in any text editor | Requires programming knowledge |
| **Reading** | Humans and agents read equally well | Humans need to parse code |
| **Versioning** | Plain text in git, easy diffs | Works, but harder to review |
| **Adaptation** | Replace placeholders, done | Needs refactoring |
| **Scope** | One self-contained operation | Can be any programmatic logic |
| **Execution** | Loaded by agent at runtime | Runs via CLI or cron |

### When to Write a Skill vs. a Script

- **Write a skill** when a human would give the same instructions every time —
  deployment checklists, audit procedures, troubleshooting workflows.
- **Write a script** when the operation is purely computational — file
  manipulation, API calls, data processing that doesn't need agent judgment.

The two can work together: a skill can reference and invoke a script.

---

## Skill Anatomy

Every Hermes skill has at minimum a `SKILL.md` file. Complex skills may also
include a `references/` directory with supporting documents, and optionally a
`scripts/` directory with executable helpers.

### The SKILL.md File Structure

```yaml
---
name: my-skill-name                     # Unique identifier (kebab-case)
description: One-line summary           # What this skill does
category: operacao                      # Grouping category
---
```

After the YAML frontmatter, a sanitized `SKILL.md` includes a comment header:

```markdown
<!--
Sanitized file for agent-ops-workflow.
Replace the {{...}} placeholders with your team's values.
See docs/07-SKILLS-GUIDE.md for complete instructions.
-->
```

Then the body follows, organized in sections:

```
# Skill Title — Brief Subtitle

## Trigger

Conditions that start this skill (human commands, system events).

---

## Prerequisites

What must be in place before using this skill.

---

## Step-by-Step Procedure

Numbered instructions the agent follows.

---

## Verification

How to confirm the skill executed correctly.

---

## Pitfalls

Known issues, edge cases, and how to avoid them.

---

## References

Links to supporting files in `references/` directory.
```

### Directory Layout Examples

**Simple skill (single-file):**
```
skills/
└── my-skill/
    └── SKILL.md
```

**Complex skill (multi-file):**
```
skills/
└── my-skill/
    ├── SKILL.md                    # Entry point
    ├── references/
    │   ├── architecture-guide.md
    │   ├── troubleshooting-commands.md
    │   └── config-example.yaml
    └── scripts/
        ├── deploy.sh
        └── verify.py
```

The agent reads `SKILL.md` first. If the skill references files in
`references/` or `scripts/`, the agent is expected to read those too.

---

## The Placeholder System

Skills use **double curly braces** `{{PLACEHOLDER}}` for variables that must be
replaced with your team's actual values. This is intentional — it distinguishes
skill placeholders from template placeholders which use double underscores
`__PLACEHOLDER__`.

### Standard Placeholders

| Placeholder | Meaning | Example Value |
|-------------|---------|---------------|
| `{{PROJECT_PATH}}` | Absolute path to the project | `/home/alice/my-project` |
| `{{PROJECT_NAME}}` | Human-readable project name | `Project Atlas` |
| `{{PROJECT_SLUG}}` | URL-safe project identifier | `project-atlas` |
| `{{TEAM_NAME}}` | Team identifier | `Team Nova` |
| `{{COMMANDER}}` | Human commander name | `Alice` |
| `{{COMMANDER_NAME}}` | Full name | `Alice Johnson` |
| `{{COMMANDER_HOME}}` | Commander's home dir | `/home/alice` |
| `{{COMMANDER_HERMES_PATH}}` | Commander's Hermes path | `/home/alice/.hermes` |
| `{{ORCHESTRATOR}}` | Orchestrator agent name | `Nova` |
| `{{BACKEND_ENGINEER}}` | Backend agent name | `Atlas` |
| `{{FRONTEND_ENGINEER}}` | Frontend agent name | `Orion` |
| `{{DEVOPS_ENGINEER}}` | DevOps agent name | `Phoenix` |
| `{{AUDITOR}}` | Auditor agent name | `Vega` |
| `{{GIT_OPS}}` | Git operations agent name | `Gitbot` |
| `{{SLACK_CHANNEL_TEAM}}` | Team's Slack channel | `#agent-ops-nova` |
| `{{SLACK_CHANNEL_WAR_ROOM}}` | Cross-team channel | `#war-room` |
| `{{SLACK_CHANNEL_TEAM_ID}}` | Channel ID (C-prefix) | `C0123456789` |
| `{{SLACK_ID_ORCHESTRATOR}}` | Orchestrator Slack user ID | `U0123456789` |
| `{{SLACK_ID_BACKEND}}` | Backend agent Slack ID | `U9876543210` |
| `{{BLOG_URL}}` | Team blog or documentation URL | `https://blog.example.com` |
| `{{CONTACT_EMAIL}}` | Contact email | `alice@example.com` |
| `{{GITHUB_USERNAME}}` | GitHub username | `alice-johnson` |

### Placeholder Convention Rules

1. **Always replace before first use.** A skill with raw `{{PLACEHOLDER}}`
   values will not work correctly — the agent will see literal placeholder text.
2. **Keep substitutions consistent.** If `{{ORCHESTRATOR}}` is `Nova` in one
   skill, it must be `Nova` in all skills.
3. **Do not nest placeholders.** `{{TEAM_NAME_UPPER}}` is derived, not nested.
4. **Skills use `{{ }}` ; Templates use `__ __`.** Never mix the two systems.

---

## How to Load Skills

Hermes provides two commands for working with skills:

### Inspect a Skill (Without Loading)

Before activating a skill, inspect it to understand what it does:

```bash
hermes skill_view path/to/skill/SKILL.md
```

This displays the skill contents so you (or the agent) can evaluate it before
committing to load it.

### Load and Activate a Skill

```bash
hermes skill_manage add path/to/skill/SKILL.md
```

This registers the skill in the agent's skill registry. Once loaded, the agent
can invoke the skill by name or trigger condition.

### Verify Loaded Skills

```bash
# List all loaded skills
hermes skill_manage list
```

### Where to Store Skills

Skills can live anywhere on the filesystem. The recommended convention is:

```
project/
└── skills/
    └── category-name/
        ├── SKILL.md
        └── references/
```

Your Hermes config's `skills_dir` points to the root of this tree:

```yaml
profiles:
  nova-orch:
    skills_dir: ~/my-project/skills/
```

### Skill Loading Order

When an agent receives a task, it searches loaded skills in this order:

1. Skills explicitly invoked by the orchestrator (by name)
2. Skills matching the task description (loose semantic match)
3. All loaded skills as context (if no explicit match)

For best results, reference the skill name explicitly in delegation messages.

---

## Complete Skills Reference Table

The repository includes 43 sanitized skills organized into 3 categories. All
skills have been processed to replace team-specific values with `{{PLACEHOLDER}}`
tokens.

### Category: operacao (Operations) — 30 skills

| # | Skill Name | Description | Complexity |
|---|-----------|-------------|------------|
| 1 | `planejamento-diario` | Daily planning system — full 6-phase flow: plan, approve, delegate, execute, audit, report | High |
| 2 | `mandos-operacao-cerebro-pycode` | Cerebro operations — agent coordination, toolset management, vault design system | High |
| 3 | `execucao-wave-auditoria` | Wave execution and audit protocol — per-task verification, index/plan updates | Medium |
| 4 | `orquestracao-refinamento-multi-modelo` | Multi-model orchestration and refinement — engine selection, task splitting | Medium |
| 5 | `re-audit-consolidation` | Re-audit workflow — consolidating corrected tasks, cross-verification | Medium |
| 6 | `diagnostico-agentes-mudos-slack` | Diagnose silent agents — gateway checks, Slack token validation, WebSocket errors | High |
| 7 | `diagnostico-interrupcoes-agentes` | Diagnose agent interruptions — crash analysis, log inspection, recovery | Medium |
| 8 | `diagnostico-evolution-api` | Evolution API diagnostics — webhook issues, connection troubleshooting | Medium |
| 9 | `docs-governance-organization` | Documentation governance — folder audit, three-layer doc system, cross-verification | Medium |
| 10 | `slack-app-creation-hermes` | Create Slack apps for Hermes — manifest templates, OAuth scopes, Socket Mode | Low |
| 11 | `cli-tools-agent-setup` | CLI tools setup for agents — OpenCode, Claude Code, Gemini CLI | Low |
| 12 | `gemini-vision-analysis` | Image analysis via Gemini Vision — screenshot inspection, visual audit | Low |
| 13 | `gemini-vault-fusion` | Gemini + Obsidian vault fusion — AI-powered note generation | Medium |
| 14 | `opencode-api-key-fallback` | OpenCode API key fallback — handling rate limits, key rotation | Low |
| 15 | `opencode-go-api-key-fallback` | OpenCode Go API key fallback — engine-specific retry logic | Low |
| 16 | `m4-mac-team-clone-sync` | Clone Hermes team from OVH to Mac — bidirectional sync, profile setup | High |
| 17 | `equipe-m4-clone-local` | Local Mac team clone — self-contained team on macOS | Medium |
| 18 | `multi-team-hermes-architecture` | Multi-team isolation — profile isolation, PM2, systemd, routing | High |
| 19 | `hermes-whatsapp-native` | WhatsApp native integration — Evolution API bridge, message routing | Medium |
| 20 | `git-vault-agent-pattern` | Git-Vault utility agent — dedicated git versioning for Obsidian vault | Low |
| 21 | `prd-clone-exhaustivo` | Exhaustive PRD cloning methodology — module-by-module, page-by-page, field-by-field | High |
| 22 | `clone-build-orchestration` | Clone build orchestration — infra provisioning, Django setup, deployment | Medium |
| 23 | `legacy-system-api-endpoints` | Legacy system API endpoints reference — integration documentation | Low |
| 24 | `legacy-system-report-mapping` | Legacy system report mapping — report generation and data extraction | Low |
| 25 | `multi-tenant-discovery-re` | Multi-tenant discovery and reverse engineering — schema analysis | Medium |
| 26 | `server-migration-ovh` | Server migration to OVH — transfer planning, execution, verification | High |
| 27 | `ovh-server-migration` | OVH server migration (alt procedure) — alternative transfer method | High |
| 28 | `migracao-servidor-ovh` | OVH server migration (Portuguese) — detailed migration steps | High |
| 29 | `infra-servidor-ovh` | OVH server infrastructure — Nginx, Docker, PM2, security | Medium |
| 30 | `troubleshoot-m4-ovh-sync` | Troubleshoot M4-OVH sync — rsync failures, git conflicts, cron issues | Medium |

### Category: devops (DevOps) — 7 skills

| # | Skill Name | Description | Complexity |
|---|-----------|-------------|------------|
| 1 | `hermes-profiles-git-sync` | Sync Hermes profiles between machines via git monorepo — emancipation, cron, rsync | High |
| 2 | `correcao-fechamento-diario` | Fix daily close errors — index/plan consistency, counter recalculation | Medium |
| 3 | `css-production-cache-debug` | Debug CSS production cache — cache-busting, CDN invalidation | Low |
| 4 | `gemini-chunked-generation` | Gemini chunked generation — large document splitting, continuation protocol | Medium |
| 5 | `evolution-v2.4-upgrade-meta-integration` | Evolution API v2.4 upgrade — Meta integration, webhook migration | Medium |
| 6 | `github-pat-private-repos` | GitHub PAT for private repos — fine-grained token setup, access scopes | Low |
| 7 | `meta-webhook-receiver-setup` | Meta webhook receiver — FastAPI endpoint, Cloudflare Tunnel, Nginx | Medium |

### Category: security (Security) — 2 skills

| # | Skill Name | Description | Complexity |
|---|-----------|-------------|------------|
| 1 | `deploy-equipe-isolada` | Deploy isolated agent team — Linux user isolation, credential separation, PM2 | High |
| 2 | `auditoria-supply-chain` | Supply chain audit — dependency review, vulnerability scanning, SBOM | Medium |

### Uncategorized / Top-Level — 4 skills

| # | Skill Name | Description | Complexity |
|---|-----------|-------------|------------|
| 1 | `m4-mac-team-clone-sync` | (Listed under operacao) | High |
| 2 | `git-vault-agent-pattern` | (Listed under operacao) | Low |
| 3 | `diagnostico-agentes-mudos-slack` | (Listed under operacao) | High |
| 4 | `prd-clone-exhaustivo` | (Listed under operacao) | High |

### Complexity Levels Explained

| Level | Characteristics | Typical File Size | Estimated Agent Time |
|-------|-----------------|-------------------|---------------------|
| **Low** | Single procedure, few decisions | 30-100 lines | 5-15 minutes |
| **Medium** | Multiple steps with branching, references external files | 100-300 lines | 15-45 minutes |
| **High** | Multi-phase process, significant dependencies, high risk | 300-800+ lines | 1-4 hours |

---

## How to Adapt Skills to Your Team

Skills in the repository are **sanitized** — team-specific values have been
replaced with `{{PLACEHOLDER}}` tokens. Before you can use a skill, you must
replace these placeholders with your actual team values.

### Step 1: Map Your Placeholders

Create a substitution table in a file called `PLACEHOLDER-MAP.md` in your
project root:

```markdown
# Placeholder Map — Team Nova

| Placeholder | Value |
|-------------|-------|
| `{{PROJECT_PATH}}` | `/home/alice/project-atlas` |
| `{{PROJECT_NAME}}` | `Project Atlas` |
| `{{TEAM_NAME}}` | `Team Nova` |
| `{{COMMANDER}}` | `Alice` |
| `{{ORCHESTRATOR}}` | `Nova` |
| `{{BACKEND_ENGINEER}}` | `Atlas` |
| `{{FRONTEND_ENGINEER}}` | `Orion` |
| `{{DEVOPS_ENGINEER}}` | `Phoenix` |
| `{{AUDITOR}}` | `Vega` |
| `{{GIT_OPS}}` | `Gitbot` |
| `{{SLACK_CHANNEL_TEAM}}` | `#agent-ops-nova` |
| `{{SLACK_CHANNEL_TEAM_ID}}` | `C0123456789` |
| `{{SLACK_ID_ORCHESTRATOR}}` | `U0123456789` |
| `{{SLACK_ID_BACKEND}}` | `U9876543210` |
| `{{SLACK_ID_FRONTEND}}` | `U5555555555` |
| `{{SLACK_ID_AUDITOR}}` | `U4444444444` |
| `{{SLACK_ID_DEVOPS}}` | `U3333333333` |
| `{{SLACK_ID_GITOPS}}` | `U2222222222` |
| `{{BLOG_URL}}` | `https://blog.nova-team.com` |
| `{{CONTACT_EMAIL}}` | `alice@nova-team.com` |
| `{{GITHUB_USERNAME}}` | `alice-nova` |
```

### Step 2: Copy Skills to Your Project

Do not modify skills in the `agent-ops-workflow/files/skills/sanitized/`
directory — those are the source of truth. Copy them to your project's
skills directory:

```bash
mkdir -p ~/my-project/skills
cp -r ~/Dev/agent-ops-workflow/files/skills/sanitized/* ~/my-project/skills/
```

### Step 3: Replace Placeholders

Use a systematic find-and-replace across all skill files. A `sed` script is
the most reliable approach:

```bash
# Placeholder replacement script
# Save as ~/my-project/scripts/replace-placeholders.sh

SKILLS_DIR=~/my-project/skills

# Team info
find "$SKILLS_DIR" -name "SKILL.md" -o -name "*.md" | while read f; do
  sed -i '' \
    -e 's/{{PROJECT_PATH}}/\/home\/alice\/project-atlas/g' \
    -e 's/{{PROJECT_NAME}}/Project Atlas/g' \
    -e 's/{{TEAM_NAME}}/Team Nova/g' \
    -e 's/{{COMMANDER}}/Alice/g' \
    -e 's/{{ORCHESTRATOR}}/Nova/g' \
    -e 's/{{BACKEND_ENGINEER}}/Atlas/g' \
    -e 's/{{FRONTEND_ENGINEER}}/Orion/g' \
    -e 's/{{DEVOPS_ENGINEER}}/Phoenix/g' \
    -e 's/{{AUDITOR}}/Vega/g' \
    -e 's/{{GIT_OPS}}/Gitbot/g' \
    -e 's/{{SLACK_CHANNEL_TEAM}}/#agent-ops-nova/g' \
    -e 's/{{SLACK_CHANNEL_TEAM_ID}}/C0123456789/g' \
    -e 's/{{SLACK_ID_ORCHESTRATOR}}/U0123456789/g' \
    -e 's/{{SLACK_ID_BACKEND}}/U9876543210/g' \
    -e 's/{{SLACK_ID_FRONTEND}}/U5555555555/g' \
    -e 's/{{SLACK_ID_AUDITOR}}/U4444444444/g' \
    -e 's/{{SLACK_ID_DEVOPS}}/U3333333333/g' \
    -e 's/{{SLACK_ID_GITOPS}}/U2222222222/g' \
    -e 's/{{BLOG_URL}}/https:\/\/blog.nova-team.com/g' \
    -e 's/{{CONTACT_EMAIL}}/alice@nova-team.com/g' \
    -e 's/{{GITHUB_USERNAME}}/alice-nova/g' \
    "$f"
done
```

### Step 4: Verify No Placeholders Remain

```bash
grep -rn "{{" ~/my-project/skills/ | grep -v "\.git" || echo "OK — no placeholders remaining"
```

### Step 5: Load the Adapted Skills

```bash
# Load each skill you need
hermes skill_manage add ~/my-project/skills/planejamento-diario/SKILL.md
hermes skill_manage add ~/my-project/skills/hermes-profiles-git-sync/SKILL.md

# Verify
hermes skill_manage list
```

### Important: Never Commit Raw Placeholders

If you are publishing skills publicly (open source), keep the placeholders and
let users replace them. If these are internal team skills, replace all
placeholders before committing to your private repository.

---

## How to Create New Skills

Creating a new skill is straightforward. Follow this step-by-step process.

### Step 1: Identify the Procedure

A good skill candidate is any procedure that:
- An agent repeats regularly (deployment, audit, troubleshooting)
- Has clear steps with verification at each stage
- Can be documented in 30-800 lines
- Benefits from agent judgment (if it's purely computational, write a script)

### Step 2: Create the Skill Directory

```bash
mkdir -p ~/my-project/skills/my-new-skill/references
mkdir -p ~/my-project/skills/my-new-skill/scripts
```

### Step 3: Write the SKILL.md Frontmatter

```yaml
---
name: my-new-skill
description: One-line description of what this skill does.
category: operacao
---
```

Choose the category that best fits:
- `operacao` — General operations, planning, execution workflows
- `devops` — Infrastructure, CI/CD, deployment, git
- `security` — Audits, isolation, vulnerability management

### Step 4: Write the Body

Use this template as a starting point:

```markdown
---
name: my-new-skill
description: Brief, one-line summary that tells an agent when to use this skill.
category: operacao
---

# My New Skill — Subtitle

## Trigger

Describe the conditions that trigger this skill. Examples:
- Human command: "run the deployment checklist"
- Event: "new pull request opened against main"
- Time: "first run of the day"

---

## Prerequisites

What must be in place before starting:
- Access credentials
- Required tools (list with version minimums)
- Any pre-checks to run

---

## Procedure

Numbered steps the agent follows. Each step should be:
- **Verifiable** — How does the agent (or auditor) know this step is done?
- **Concrete** — Include file paths, commands, and expected outputs
- **Consequential** — If step 4 fails, what happens? Branching logic is fine.

### Step 1: Preparation

```bash
# Example command that step 1 runs
git checkout -b feature/my-feature
```

### Step 2: Execution

Detailed instructions with expected results.

### Step 3: Verification

How to confirm the step worked.

---

## Verification

Final verification checklist — the agent runs these checks and reports results:

- [ ] Expected output matches actual output
- [ ] Logs show no errors
- [ ] Tests pass (if applicable)
- [ ] Changes committed and pushed

---

## Rollback

If something goes wrong, how to undo the operation:

```bash
git revert <hash>
git push
```

---

## Pitfalls

Known issues and how to avoid them:

1. **Pitfall name** — Description and prevention.
2. **Another pitfall** — Description and prevention.

---

## References

- `references/detailed-guide.md` — Supplementary information
- `scripts/helper.py` — Automation script referenced in step 2
```

### Step 5: Add Supporting Files

If the skill needs reference documents, add them to `references/`. If it calls
helper scripts, add them to `scripts/` and make them executable.

### Step 6: Test the Skill

Load the skill in a sandbox agent and run through the procedure:

```bash
hermes skill_manage add ~/my-project/skills/my-new-skill/SKILL.md
hermes skill_manage list  # Verify it loaded
```

Then ask the agent to execute the skill with a test scenario.

### Step 7: Iterate

After testing, refine:
- Remove ambiguity in instructions
- Add missing verification steps
- Document new pitfalls discovered during testing
- Add references to related skills

---

## Best Practices

### Structure

1. **One procedure per skill.** If a skill has multiple unrelated procedures,
   split it into multiple skills.

2. **Front-load the context.** The first section after the title should explain
   *when* and *why* to use this skill. Agents scan this before reading details.

3. **Use consistent section names.** Agents learn to find information faster
   when sections follow a predictable pattern. Use the same section names
   across all skills (Trigger, Prerequisites, Procedure, Verification, Pitfalls).

4. **Include exit criteria.** Every skill should end with a clear definition of
   done — what does success look like? What does failure look like?

### Writing Style

5. **Write for both humans and agents.** Skills are read by both. Use clear,
   imperative language. Avoid jargon unless it is defined in the skill.

6. **Be concrete.** Prefer specific file paths and commands over abstract
   descriptions. An agent executes what it reads — ambiguity leads to errors.

7. **Number instructions.** Numbered lists make it easy for agents to track
   progress and for auditors to verify completion.

8. **Use checklists for verification.** Binary checklist items (`[ ]` / `[x]`)
   map directly to agent capability. They are the most reliable way to confirm
   task completion.

### Placeholder Hygiene

9. **Always sanitize before publishing.** If you open-source a skill, replace
   all team-specific values with `{{PLACEHOLDER}}` tokens first.

10. **Never hardcode secrets.** Use `{{PLACEHOLDER}}` for credentials, API
    keys, and tokens — or better, reference environment variables.

11. **Keep placeholders scoped.** A single skill should not reference more than
    15-20 placeholders. If it does, consider splitting it.

### Maintenance

12. **Review skills quarterly.** Procedures change, tools update, people leave.
    Set a recurring calendar reminder to audit your skills for accuracy.

13. **Version your skills.** Commit SKILL.md changes with descriptive messages:
    `skill: update deployment checklist for v2.1`.

14. **Cross-reference related skills.** If skill A depends on skill B being
    loaded first, note this in both SKILL.md files.

---

## Troubleshooting

### Skill Not Found When Invoked

**Symptom:** Agent says "I don't have a skill named X" or returns unrelated
results.

**Checklist:**
- [ ] Did you run `hermes skill_manage add ...` ? Loading requires an explicit
      command.
- [ ] Is the path to `SKILL.md` correct? `hermes skill_view path/to/SKILL.md`
      should display the content.
- [ ] Did you verify with `hermes skill_manage list` ? Run this to confirm the
      skill is registered.
- [ ] Does the Hermes profile have the correct `skills_dir` pointing to the
      parent directory of your skills?

### Placeholders Not Replaced

**Symptom:** Agent reads literal `{{PLACEHOLDER}}` text in its response.

**Cause:** The skill was loaded from the sanitized directory without
substitutions.

**Fix:**
```bash
# Check for remaining placeholders
grep -rn "{{" ~/my-project/skills/ | grep -v "\.git"

# If any remain, run your replacement script
~/my-project/scripts/replace-placeholders.sh
```

### Agent Cannot Find Referenced Files

**Symptom:** Skill references `references/X.md` or `scripts/Y.sh` but the agent
reports file not found.

**Checklist:**
- [ ] Are the files present in the skill directory?
- [ ] Does the reference path use relative paths (recommended)?
- [ ] Is the reference file named exactly as referenced (case-sensitive)?
- [ ] Did you copy the entire skill directory (not just SKILL.md)?

### Skill Loads but Agent Ignores It

**Symptom:** The skill is listed in `hermes skill_manage list` but the agent
does not use it during a relevant task.

**Possible causes:**
- The skill's `name` in the YAML frontmatter does not match how you reference
  it in delegation messages.
- The skill's `Trigger` section does not match the agent's current context.
- Another loaded skill has higher priority for the same task type.

**Fix:** Explicitly reference the skill by name in your delegation:
```
Use skill "my-skill-name" for this task.
```

### Performance: Too Many Loaded Skills

**Symptom:** Agent responses become slow or context windows fill up.

**Cause:** Every loaded skill adds context tokens. Loading all 43 skills
simultaneously can exceed context limits.

**Best practice:** Load only the skills needed for the current day's tasks.
The orchestrator can load/unload skills dynamically per wave:

```bash
# Before the day starts, load relevant skills
hermes skill_manage add skills/planejamento-diario/SKILL.md
hermes skill_manage add skills/deploy-equipe-isolada/SKILL.md

# After the day ends (or after waves that need them), unload
hermes skill_manage remove skills/deploy-equipe-isolada/SKILL.md
```

### Skill Content Does Not Render Correctly

**Symptom:** Sections missing, tables broken, code blocks not syntax-highlighted.

**Checklist:**
- [ ] Is the YAML frontmatter valid? Ensure `name:`, `description:`, and
      `category:` are present and separated by `---`.
- [ ] Are there unclosed code blocks? Every ``` must have a closing ```.
- [ ] Are tables formatted correctly? Each table row must have the same number
      of columns as the header.
- [ ] Did you use `|` characters inside table cells? This breaks the table
      parser — use HTML breaks `<br>` instead.

### Skill Has Outdated Information

**Symptom:** Agent follows the procedure but the steps no longer match the
current system state.

**Fix:** Update the skill file and reload:
```bash
# Edit the SKILL.md
vim ~/my-project/skills/my-skill/SKILL.md

# Reload (remove then re-add)
hermes skill_manage remove skills/my-skill/SKILL.md
hermes skill_manage add skills/my-skill/SKILL.md
```

Schedule a quarterly skill audit to catch staleness before it causes problems.

---

## Appendix: Skill File Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Skill directory | `kebab-case` | `planejamento-diario/` |
| Entry point | `SKILL.md` (uppercase) | `SKILL.md` |
| Reference files | `kebab-case.md` | `architecture-guide.md` |
| Script files | `kebab-case.sh` or `.py` | `deploy-skill.sh` |
| YAML name | `kebab-case` | `name: planejamento-diario` |

---

## Appendix: Category Definitions

| Category | Scope | Typical Skills |
|----------|-------|---------------|
| `operacao` | General agent operations, daily workflows, troubleshooting | Planning, diagnostics, migration, PRD creation |
| `devops` | Infrastructure, CI/CD, tooling, version control | Profile sync, PAT setup, webhook receivers |
| `security` | Isolation, audits, vulnerability management | Deploy isolated team, supply chain audit |

---

> Skills are the most powerful abstraction in the Agent Ops Workflow. They
> encode human expertise into agent-readable procedures, making your team
> smarter with every skill you write.
