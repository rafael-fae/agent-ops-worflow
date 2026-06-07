# Operational Memory System — DIARY.md + TEAM-STATE.md

> Complete, didactic, and in-depth guide to the operational memory system
> for multi-agent AI agents: the problem, the solution, the system_prompt
> discovery, and the step-by-step implementation.

---

## Table of Contents

1. [The Problem — Why We Created This System](#1-the-problem-why-we-created-this-system)
2. [The Solution — What We Created](#2-the-solution-what-we-created)
3. [Directory Structure — How We Organized It](#3-directory-structure-how-we-organized-it)
4. [The DIARY.md — Personal Logbook](#4-the-diarymd-personal-logbook)
5. [The TEAM-STATE.md — Shared Dashboard](#5-the-team-statemd-shared-dashboard)
6. [The Critical Discovery: System Prompt vs AGENTS.md](#6-the-critical-discovery-system-prompt-vs-agentsmd)
7. [The 3 Enforcement Layers](#7-the-3-enforcement-layers)
8. [How to Implement — Step by Step](#8-how-to-implement-step-by-step)
9. [Proven Benefits](#9-proven-benefits)
10. [References](#10-references)

---

## 1. The Problem — Why We Created This System

### AI Agents Have No Memory Between Sessions

This is the fundamental truth that motivated everything. An AI agent (like a Hermes
Agent based on an LLM) **has no intrinsic memory between sessions**. Every time
you start a conversation with it, context begins from zero:

```
Session 1 (8:00 AM):
  Human: "Agent, start task_01. We're refactoring module X."
  Agent: "Understood! I'll refactor module X now."
  [Agent works, commits, ends]

  ─── END OF SESSION 1 ───
         ↓
  ALL CONTEXT IS LOST
         ↓

Session 2 (2:00 PM):
  Human: "Agent, continue task_01."
  Agent: "Which task_01? What is module X? I don't know what you're talking about."
```

This happens because the language model **does not persist state**. Each
API call is independent. What the agent "knows" is only what's in the
current conversation context.

### Each Session Starts from Zero

Without an operational memory system, the agent:

- **Does not remember** which tasks it has already executed
- **Does not know** the current project state
- **Does not recognize** decisions made in previous sessions
- **Does not distinguish** completed tasks from pending ones

### Multiple Agents Can Overwrite Each Other's Work

In a multi-agent team (orchestrator + various specialists), the problem
is amplified:

```
Agent A (morning):
  "I'll implement feature X in main.py"

Agent B (afternoon) ← DOESN'T KNOW that A already did this:
  "I'll implement feature X in main.py"

RESULT: Duplicate work, merge conflicts, rework.
```

### No Visibility of What's Happening Now

The human (commander) doesn't have a single dashboard showing:

- Who is working on what?
- Which tasks are blocked?
- What has been completed today?
- Where are the bottlenecks?

### History: Instructions Buried in Huge Documents

Before this system, operational rules were:

| Where | Size | Problem |
|-------|------|---------|
| `AGENTS.md` | ~11K chars | Buried in the middle of doc separation rules and pre-commit checklist |
| Skills | ~29K total chars | Hard to find and remember — the model ignores what isn't prioritized |

The result: **agents simply ignored the rules**. Not out of bad
will, but because the model couldn't prioritize instructions buried in
tens of thousands of characters of context.

---

## 2. The Solution — What We Created

We created an **Operational Memory System** with three main components:

### DIARY.md — Personal Logbook

Each agent has its own `DIARY.md` file in its Hermes profile directory.
It's the agent's "notebook" — it records:

- When it started working
- Which task it's on
- What it did (commands, commits, decisions)
- When it paused or completed
- Observations and learning

### TEAM-STATE.md — Shared Dashboard

A single file, maintained **only by the orchestrator**, that functions as a
central control panel. It shows:

- Status of each agent (Online/Busy/Pending)
- Active tasks with their assignees
- Blocked tasks and reasons
- Day's decisions and alerts

### Check-in / Check-out Protocol

A set of rules that EVERY agent MUST follow:

1. **Read TEAM-STATE.md** before any action
2. **Update your DIARY.md** when starting, pausing, or completing a task
3. **Update TEAM-STATE.md** (if you're the orchestrator) when changing status
4. **Never** start a task without checking if another agent is already on it

---

## 3. Directory Structure — How We Organized It

The operational files live inside each Hermes profile directory, in a
subfolder called `operational/`:

```
~/.hermes/profiles/
│
├── orchestrator/          ← Orchestrator agent profile
│   ├── config.yaml
│   ├── SOUL.md
│   ├── AGENTS.md
│   ├── skills/
│   └── operational/      ← OPERATIONAL MEMORY FOLDER
│       ├── DIARY.md          ← Orchestrator's personal diary
│       └── TEAM-STATE.md     ← Shared dashboard (ONLY HERE!)
│
├── agent1/               ← First specialist profile
│   ├── config.yaml
│   ├── SOUL.md
│   ├── AGENTS.md
│   └── operational/
│       └── DIARY.md          ← Personal diary (NO TEAM-STATE)
│
├── agent2/               ← Second specialist profile
│   ├── config.yaml
│   └── operational/
│       └── DIARY.md
│
└── agent3/               ← Third specialist profile
    └── operational/
        └── DIARY.md
```

### Why This Structure?

- **Each agent has its own DIARY.md** because each needs to record its
  own activities. If everyone wrote in the same file, there would be
  concurrent write conflicts.

- **Only the orchestrator has TEAM-STATE.md** because it is the central
  coordination point. If each agent could alter the team state, one could
  overwrite another's change. The orchestrator is the state "gatekeeper".

- **Inside `operational/`** to keep it separate from profile configuration
  files (config.yaml, SOUL.md, etc.) and facilitate backup,
  synchronization, and auditing.

- **Inside `~/.hermes/profiles/`** (not in the project directory) because
  operational memory belongs to the **agent**, not the project. An agent can
  work on multiple projects and needs the same memory across all of them.

---

## 4. The DIARY.md — Personal Logbook

### Field-by-Field Template Explanation

```markdown
# Operation Diary — {AGENT_NAME}

## Daily Activity Log

| Date       | Wave/Shift | Task ID | Activities / Commits                     | Status |
|------------|------------|---------|------------------------------------------|--------|
| DD/MM/YYYY | Morning/Afternoon/Night | task_XX | Description of what was done + commit hash | ⬜/🟢/✅ |
```

**Explanation of each field:**

| Field | What it is | Example | Required? |
|-------|-----------|---------|:---------:|
| **Date** | Date in DD/MM/YYYY format | `06/06/2026` | Yes |
| **Wave/Shift** | Time of day (morning, afternoon, night) or plan wave | `Morning (Wave 1)` | Yes |
| **Task ID** | Task identifier per PLAN.md | `task_03` | Yes |
| **Activities/Commits** | Concise description of what was done + commit hash | `Fixes login route. Commit: a1b2c3d` | Yes |
| **Status** | Current task state | ⬜ = Pending, 🟢 = In progress, ✅ = Completed | Yes |

### Real Example of a Filled Entry

```markdown
# Operation Diary — agent1

## Daily Activity Log

| Date       | Wave/Shift | Task ID | Activities / Commits                     | Status |
|------------|------------|---------|------------------------------------------|--------|
| 06/06/2026 | Morning (W1) | task_01 | Start: fixing login route.              | 🟢     |
| 06/06/2026 | Morning (W1) | task_01 | Route fixed in AuthController.php.      | ✅     |
|            |            |         | Commit: a1b2c3d4e5f6. Tests: 47/47.    |        |
| 06/06/2026 | Afternoon (W2) | task_03 | Start: refactoring reports module.    | 🟢     |
| 06/06/2026 | Afternoon (W2) | task_03 | Structure refactored. Awaiting review. | 🟢     |

## Observations
- task_01 had an unexpected bug in the authentication middleware.
  Extra 30 min of debugging was needed.
- task_03 depends on data model approval (task_02).
```

### When to Update

The agent MUST update DIARY.md at these moments:

```
┌─────────────────────────────────────────────────────────┐
│                  SESSION START                           │
│  • Read DIARY.md (to know where you left off)           │
│  • Read TEAM-STATE.md (to understand context)           │
│  • Add a line in DIARY: "Session start"                 │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  WHEN STARTING A TASK                    │
│  • Add in DIARY:                                        │
│    | DATE | WAVE | task_XX | Start: description | 🟢   │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  WHEN COMPLETING A TASK                  │
│  • Add in DIARY:                                        │
│    | DATE | WAVE | task_XX | What was done + commit | ✅│
│  • Update TEAM-STATE.md (if orchestrator)               │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  WHEN PAUSING A TASK                     │
│  • Add in DIARY:                                        │
│    | DATE | WAVE | task_XX | Paused: reason | 🟢       │
│  • Update TEAM-STATE.md (if orchestrator)               │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  END OF SESSION                          │
│  • Verify DIARY reflects current state                  │
│  • Add observations if needed                           │
└─────────────────────────────────────────────────────────┘
```

### What to Record (Golden Rule)

Record **everything another agent (or future you) would need to know**:

- **Start/end time** of each activity
- **Commit hash** associated with each completion
- **Important technical decisions** (why you chose X over Y)
- **Problems encountered** and how they were resolved
- **Dependencies** between tasks (task_03 depends on task_01)
- **Observations** that might help in the next session

### When NOT to Update

- No need to record every individual command
- No need to copy the entire code — just the summary and hash
- No need to update for read/analysis tasks (but log that you read)

---

## 5. The TEAM-STATE.md — Shared Dashboard

### Explained Template

```markdown
# Team State — Global Control

**Orchestrator:** {ORCHESTRATOR_NAME}
**Timezone:** {TIMEZONE}

## Agent Dashboard

| Agent        | Type         | Operational Status | Last Activity |
|-------------|--------------|-------------------|---------------|
| orchestrator| Orchestrator | [Active]          | Started task_01 |
| agent1      | Specialist   | [Running 🟢]      | task_03 — 80% |
| agent2      | Specialist   | [Waiting 🟡]     | task_04 — ready |
| agent3      | Specialist   | [Blocked 🔴]      | Waiting for API key |

## Task Control for the Day

| Task ID | Description          | Responsible | Wave | Status     | Commit Hash |
|---------|----------------------|-------------|------|------------|-------------|
| task_01 | Fix login route      | agent1      | W1   | ✅         | a1b2c3d     |
| task_02 | Reports model        | agent2      | W1   | 🟢         | —           |
| task_03 | Refactor reports     | agent1      | W2   | 🟢         | —           |
| task_04 | Integration tests    | agent3      | W2   | 🟡         | —           |

## Blocked Tasks

| Task | Responsible | Block Reason         | Unblock        |
|------|-------------|---------------------|----------------|
| task_04 | agent3    | Waiting for external API key | Request from commander |

## Day's Decisions

- 06/06 — Defined that task_03 only starts after task_01 + task_02
- 06/06 — Decided to use DuckDB instead of PostgreSQL for reports

## Alerts

- ⚠️ agent3 waiting for authorization for new API key
```

### The 4 States

| State | Symbol | Meaning | When to Use |
|-------|:------:|---------|-------------|
| Running | 🟢 | Agent is actively working on this task | When starting a task |
| Waiting | 🟡 | Agent completed but waiting for something (review, dependency) | When completed but with external blocker |
| Blocked | 🔴 | Can't advance — needs intervention | When something external prevents progress |
| Completed | ✅ | Task finished and audited | After successful auditing |

### Who Maintains TEAM-STATE.md

**Absolute rule: only the orchestrator changes this file.**

```
Why? Imagine 3 agents trying to change the same file simultaneously:
   agent1 writes: "task_01 🟢" (in the middle of the file)
   agent2 writes: "task_02 ✅" (in the middle of the file)
   agent3 writes: "task_03 🔴" (in the middle of the file)

RESULT: The last one to write OVERWRITES the others.
         Data lost. Inconsistent state.
```

The correct flow is:

```
agent1: "Task_01 completed! Commit: a1b2c3d"
    │
    ▼
orchestrator: Reads the message, verifies, UPDATES TEAM-STATE.md
    │
    ▼
orchestrator: task_01 marked as ✅ on TEAM-STATE.md
    │
    ▼
agent2: Reads TEAM-STATE.md, sees task_01 ✅, starts task_02
```

### How to Check-in and Check-out

**CHECK-IN** (when starting work):

1. Read `TEAM-STATE.md` to see if there are conflicts
2. If you're the orchestrator: change your status to `🟢` and add the task
3. If you're a regular agent: just update your `DIARY.md`

```
Check-in example (orchestrator updates):
| agent1 | Specialist | [Running 🟢] | task_03 — started |
```

**CHECK-OUT** (when finishing or pausing):

1. If you're the orchestrator: change status to ✅ or 🟡
2. Add the commit hash to TEAM-STATE.md
3. Update your `DIARY.md` with a summary of what was done

```
Check-out example (orchestrator updates):
| task_01 | Fix login route | agent1 | W1 | ✅ | a1b2c3d |
```

---

## 6. The Critical Discovery: System Prompt vs AGENTS.md

This is the most important discovery in the entire system. It was the "eureka moment"
that transformed a system that didn't work into one that works.

### The Fundamental Difference

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  system_prompt  ≠  AGENTS.md  ≠  Skills                            │
│                                                                     │
│  They are loaded at different times and with different STRENGTHS    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### system_prompt (config.yaml)

- **What it is:** The definition of the agent's "self." The first system message.
- **When loaded:** At the start of EACH conversation, before any input.
- **Strength:** MAXIMUM. The model sees this FIRST and with the highest attention weight.
- **Where it is:** Inside the Hermes profile's `config.yaml`.
- **Typical size:** 200-500 characters.

```yaml
# BEFORE the discovery — generic system_prompt (weak):
system_prompt: "You are the Radiant agent1. Speak in English."
```

```yaml
# AFTER the discovery — system_prompt with protocol (strong):
system_prompt: "You are the Radiant agent1.
  Speak in English.

  ### DIARY PROTOCOL — MANDATORY
  You HAVE two operational files you MUST use in EVERY session:
  1. DIARY.md (your personal diary): READ at the start, UPDATE when completing/pausing.
  2. TEAM-STATE.md (collective memory): READ before ANY action."
```

#### AGENTS.md

- **What it is:** A markdown document with operational rules, Slack mentions,
  team maps, etc.
- **When loaded:** As additional context, alongside other files.
- **Strength:** MEDIUM. The model reads it, but may ignore it if the system_prompt
  doesn't explicitly reference it.
- **Where it is:** In the Hermes profile directory.
- **Typical size:** 5K-15K characters.

#### Skills

- **What it is:** Skill modules with step-by-step procedures.
- **When loaded:** When invoked by name or trigger.
- **Strength:** GOOD (when loaded), but can be forgotten if not triggered.
- **Where it is:** In the `skills/` directory in the profile.
- **Typical size:** 2K-5K characters each, ~29K total.

### The Problem with the 11K-Character AGENTS.md

Before the discovery, the DIARY rules were buried in AGENTS.md:

```
AGENTS.md (~11,000 characters):
─────────────────────────────────
  Line 1-50:   Real Slack mentions (user IDs)
  Line 51-120:  Document separation rules
  Line 121-180: Pre-commit checklist
  Line 181-220: <— HERE WAS THE DIARY RULE (buried!)
  Line 221-350: Commit and push instructions
  ...

RESULT: The model DID NOT PRIORITIZE the DIARY rule.
         It was just 1 among 11,000 characters of instruction.
```

The language model works with **attention**. The more text, the more the
model needs to "decide" what's important. Rules buried in the middle of
large documents are **systematically ignored** because:

1. The **beginning** of context receives more weight (primacy effect)
2. The **end** of context receives less weight (recency effect)
3. The **middle** of context is where attention drops most

The DIARY rules were in the **middle** of an 11K-char AGENTS.md.
Result: nobody followed them.

### Why System Prompt is the Only Reliable Place

The system_prompt is:

1. **The FIRST thing the model sees** — maximum primacy effect
2. **The shortest** — 200-500 chars vs 11K-29K for other documents
3. **Defined in config.yaml** — doesn't need to be "found" among skills
4. **Referenced by the model itself** — the model "knows who it is" from the prompt

```
Visualization of the model's attention hierarchy:
─────────────────────────────────────────────────

  system_prompt  ←  MAXIMUM ATTENTION (first, shortest, defines the "self")
       ↓
    AGENTS.md   ←  MEDIUM ATTENTION (referenced by system_prompt)
       ↓
     Skills     ←  GOOD ATTENTION (loaded on demand)
       ↓
   Context      ←  VARIABLE ATTENTION (depends on size and position)
```

### The Fix: Inject the Protocol into the System Prompt

The solution was **adding the operational protocol directly into the system_prompt**
of each profile, with **ABSOLUTE paths**.

#### Template for system_prompt with the protocol

```yaml
system_prompt: "You are {AGENT_NAME}.
  Speak in English.

  ### DIARY PROTOCOL — MANDATORY

  You HAVE two operational files you MUST use in EVERY session:

  1. DIARY.md (your personal diary)
     Location: /Users/your-user/.hermes/profiles/{AGENT_NAME}/operational/DIARY.md
     READ at the start of each session
     UPDATE when completing/pausing a task

  2. TEAM-STATE.md (collective memory)
     Location: /Users/your-user/.hermes/profiles/orchestrator/operational/TEAM-STATE.md
     READ before ANY action
     UPDATE when starting/completing/pausing (only if you're the orchestrator)

  ABSOLUTE RULE: If you haven't read TEAM-STATE before acting,
  you might be overwriting another agent. Always read first.
"
```

### ⚠️ The IMPORTANCE of Using ABSOLUTE Paths

This deserves emphasis because it was one of the root causes of the system not working.

#### What happens with relative paths

```yaml
# WRONG — relative path:
system_prompt: "... READ operational/DIARY.md..."
```

Each agent resolves relative paths from the **project dir** (the working directory
configured in `cwd` in config.yaml), which is typically something like
`/Users/user/Dev/my-project/`. The result:

```
Agent tries to open: /Users/user/Dev/my-project/operational/DIARY.md
But the file is at: /Users/user/.hermes/profiles/agent1/operational/DIARY.md

RESULT: File not found. Agent gives up. Protocol ignored.
```

#### What happens with `~/` (tilde)

```yaml
# WRONG — tilde not expanded:
system_prompt: "... READ ~/.hermes/profiles/agent1/operational/DIARY.md..."
```

The tilde (`~/`) is a **shell** convention, not a filesystem one. Hermes
Agent (or any Python tool) may or may not expand the tilde depending on how
it implements file reading. Often, the model tries `open('~/.hermes/...')`
which literally looks for a folder named `~`.

```
Agent tries to open: ~/.hermes/profiles/agent1/operational/DIARY.md
The system sees: "~" literally as a folder name

RESULT: FileNotFoundError. Agent gives up.
```

#### The CORRECT format

```yaml
# CORRECT — complete absolute path:
system_prompt: "... READ /Users/your-user/.hermes/profiles/agent1/operational/DIARY.md..."
```

Always use the complete path, starting from `/`. Don't rely on tilde, relative paths,
or environment variables.

---

## 7. The 3 Enforcement Layers

The operational memory system works across 3 layers, each with a different
level of "persuasion" strength:

```
                    STRENGTH
                      │
                      ▲
                      │
                ┌─────┴──────┐
                │             │
         ┌──────┴──────┐     │
         │  System     │  MAXIMUM  ← Definition of "self"
         │  Prompt     │     │     The model reads FIRST
         └──────┬──────┘     │
                │            │
         ┌──────┴──────┐     │
         │  AGENTS.md  │  MEDIUM   ← Operational rules
         │             │     │     The model reads as context
         └──────┬──────┘     │
                │            │
         ┌──────┴──────┐     │
         │  MEMORY.md  │  GOOD     ← Memory between sessions
         │  (Hermes)   │     │     Automatic persistence
         └─────────────┘     │
                      │
                      ▼
                    TIME
```

### Comparison Table

| Layer | What it is | When loaded | Strength | Typical size | Reliability |
|-------|-----------|-------------|:--------:|:------------:|:-----------:|
| **System Prompt** | Definition of the agent's "self" | Start of every session | Maximum | 200-500 chars | 95%+ |
| **AGENTS.md** | Operational rules, mentions, team map | On startup, as additional context | Medium | 5K-15K chars | 60-70% |
| **MEMORY.md** | Automatic Hermes persistent memory | Via the `memory` tool | Good | Variable | 70-80% |

### Layer 1: System Prompt (Maximum Strength)

**What it is:** The first message the model receives. Defines who it is, how
it should act, and what its absolute priorities are.

**Strength:** Maximum — because:
- It's the **first** token in the context (primacy effect)
- It's **short** and direct (200-500 chars)
- It defines the agent's **identity** ("You are X...")
- The model doesn't need to "choose" whether to read it — it's part of the setup

**How to configure:**
```yaml
# In ~/.hermes/profiles/{agent}/config.yaml
agent:
  system_prompt: "You are agent1. Speak in English.

### DIARY PROTOCOL — MANDATORY
You HAVE two operational files...

1. DIARY.md
   Location: /Users/user/.hermes/profiles/agent1/operational/DIARY.md
   READ at start, UPDATE when completing/pausing.

2. TEAM-STATE.md
   Location: /Users/user/.hermes/profiles/orchestrator/operational/TEAM-STATE.md
   READ before any action."
```

**Never rely solely on it for everything** — the system_prompt is strong but limited
in size. Use it for the essential protocol (the "what" and "when"), and leave the
details (the "how") for AGENTS.md and Skills.

### Layer 2: AGENTS.md (Medium Strength)

**What it is:** Markdown document with detailed operational rules, Slack
mentions, team hierarchy, etc.

**Strength:** Medium — because:
- It's loaded as additional context, not as definition of "self"
- It can be large (>10K chars), which dilutes attention
- The model may "forget" to consult it if the system_prompt doesn't reference it

**How to use effectively:**
```markdown
# AGENTS.md — My Agent

## Operational Rules (referenced by system_prompt)

### DIARY.md — Filling Details
- Use table format: | Date | Wave | Task | Activity | Status |
- Possible statuses: ⬜ Pending, 🟢 In progress, ✅ Completed
- Always include commit hash for completed activities

### TEAM-STATE.md — How to Update
- Only the ORCHESTRATOR changes this file
- On check-in: change status to 🟢
- On check-out: change to ✅ or 🟡

### Real Slack Mentions
- Orchestrator: <@U1234567890>
- agent1: <@U0987654321>
```

### Layer 3: MEMORY.md (Good Strength)

**What it is:** Hermes Agent has an internal memory system (tool `memory`)
that persists key information between sessions automatically.

**Strength:** Good — because:
- It persists between sessions (doesn't need to be recreated)
- The model can query and update via dedicated tool
- But depends on the model **remembering to use** the memory tool

**How to use:**
```
Hermes Agent automatically saves memories using the "memory" tool.
The MEMORY.md file lives in ~/.hermes/profiles/{agent}/memories/MEMORY.md
and is managed by the system itself, not manually.
```

---

## 8. How to Implement — Step by Step

Follow these 7 steps to implement the Operational Memory System in your team.

### Step 1: Create the `operational/` Directory for Each Agent

```bash
# For EACH agent on your team, create the operational folder:
mkdir -p ~/.hermes/profiles/orchestrator/operational
mkdir -p ~/.hermes/profiles/agent1/operational
mkdir -p ~/.hermes/profiles/agent2/operational
mkdir -p ~/.hermes/profiles/agent3/operational
```

### Step 2: Create DIARY.md with the Template

Create the `DIARY.md` file inside `operational/` for each agent:

```bash
# Template for each agent
cat > ~/.hermes/profiles/orchestrator/operational/DIARY.md << 'TEMPLATE'
# Operation Diary — orchestrator

## Daily Activity Log

| Date | Wave/Shift | Task ID | Activities / Commits | Status |
|------|------------|---------|----------------------|--------|
|      |            |         |                      | ⬜/🟢/✅ |
TEMPLATE

# Repeat for each agent, changing the name
```

### Step 3: Create TEAM-STATE.md (Orchestrator Only)

```bash
cat > ~/.hermes/profiles/orchestrator/operational/TEAM-STATE.md << 'TEMPLATE'
# Team State — Global Control

**Orchestrator:** orchestrator
**Timezone:** America/New_York

## Agent Dashboard

| Agent | Type | Operational Status | Last Activity |
|-------|------|--------------------|---------------|
| orchestrator | Orchestrator | [Active] | — |
| agent1 | Specialist | [Pending] | — |
| agent2 | Specialist | [Pending] | — |

## Task Control for the Day

| Task ID | Description | Responsible | Wave | Status | Commit Hash |
|---------|-------------|-------------|------|--------|-------------|
| | | | | ⬜/🟢/✅ | |

## Blocked Tasks

| Task | Responsible | Block Reason | Unblock |
|------|-------------|--------------|---------|

## Day's Decisions

## Alerts
TEMPLATE
```

### Step 4: Inject the Protocol into the System Prompt of EACH Profile

This is the most critical step. You need to add the DIARY protocol to the
`system_prompt` of each config.yaml.

#### Identify the YAML escape format of each profile

Each profile may have a different format for the system_prompt. Check:

```bash
for p in orchestrator agent1 agent2 agent3; do
  echo "=== $p ==="
  grep "system_prompt:" ~/.hermes/profiles/$p/config.yaml | head -1
done
```

Common formats are:

| Format | Appearance | How to Identify |
|--------|-----------|-----------------|
| Multiline | `system_prompt: \|` + indented lines | Uses pipe followed by lines |
| Single backslash | `system_prompt: "text\\n"` | `\n` inside quotes |
| Double backslash | `system_prompt: "text\\\\n"` | `\\n` inside quotes |
| Continuation | `system_prompt: "text\\\n  \ continuation"` | `\` at end of lines |

#### Add the protocol (example for multiline format)

```yaml
# BEFORE:
agent:
  system_prompt: |
    You are agent1. Speak in English.

# AFTER:
agent:
  system_prompt: |
    You are agent1. Speak in English.

    ### DIARY PROTOCOL — MANDATORY

    You HAVE two operational files you MUST use in EVERY session:

    1. DIARY.md (your personal diary)
       Location: /Users/your-user/.hermes/profiles/agent1/operational/DIARY.md
       READ at the start of each session
       UPDATE when completing/pausing a task

    2. TEAM-STATE.md (collective memory)
       Location: /Users/your-user/.hermes/profiles/orchestrator/operational/TEAM-STATE.md
       READ before ANY action
       UPDATE when starting/completing/pausing (only if you're the orchestrator)

    ABSOLUTE RULE: read TEAM-STATE before acting.
```

### Step 5: Configure Timezone

Empty or missing timezone makes Hermes use UTC, resulting in wrong
times in DIARY records.

```bash
# Check current timezone of each profile
grep "timezone:" ~/.hermes/profiles/*/config.yaml

# If empty or missing, configure for your local timezone:
# For Eastern Time (UTC-5):
sed -i '' 's/timezone: .*/timezone: America\/New_York/' \
  ~/.hermes/profiles/*/config.yaml

# For Central Time (UTC-6):
sed -i '' 's/timezone: .*/timezone: America\/Chicago/' \
  ~/.hermes/profiles/*/config.yaml

# If the key doesn't exist, add it manually in config.yaml
# inside the agent section:
#   timezone: America/New_York
```

### Step 6: Restart the Gateways

Changes to system_prompt and timezone only take effect after restarting the
Hermes gateway:

```bash
# For EACH profile:
hermes --profile orchestrator gateway run --replace
hermes --profile agent1 gateway run --replace
hermes --profile agent2 gateway run --replace
hermes --profile agent3 gateway run --replace

# Or in a loop:
for p in orchestrator agent1 agent2 agent3; do
  echo "Restarting gateway for $p..."
  hermes --profile $p gateway run --replace 2>/dev/null
done
```

### Step 7: Verify

```bash
# 1. Verify protocol is in system_prompt
echo "=== DIARY PROTOCOL Verification ==="
for p in orchestrator agent1 agent2 agent3; do
  if grep -q "DIARY PROTOCOL" ~/.hermes/profiles/$p/config.yaml; then
    echo "$p: ✅ OK"
  else
    echo "$p: ❌ MISSING"
  fi
done

# 2. Verify timezone
echo ""
echo "=== TIMEZONE Verification ==="
grep "timezone:" ~/.hermes/profiles/*/config.yaml

# 3. Verify DIARYs exist
echo ""
echo "=== DIARY.md Verification ==="
for p in orchestrator agent1 agent2 agent3; do
  if [ -f ~/.hermes/profiles/$p/operational/DIARY.md ]; then
    lines=$(wc -l < ~/.hermes/profiles/$p/operational/DIARY.md)
    echo "$p: ✅ DIARY.md exists ($lines lines)"
  else
    echo "$p: ❌ DIARY.md not found"
  fi
done

# 4. Verify TEAM-STATE.md (orchestrator only)
echo ""
echo "=== TEAM-STATE.md Verification ==="
if [ -f ~/.hermes/profiles/orchestrator/operational/TEAM-STATE.md ]; then
  echo "orchestrator: ✅ TEAM-STATE.md exists"
else
  echo "orchestrator: ❌ TEAM-STATE.md not found"
fi

# 5. Verify running gateways
echo ""
echo "=== Active Gateways ==="
ps aux | grep "hermes.*gateway" | grep -v grep
```

---

## 9. Proven Benefits

### Before the System Prompt Fix

Agents **tried** to follow the protocol but failed because:

1. **Relative/wrong paths** — tried to open files that didn't exist
2. **System_prompt without DIARY mention** — model didn't prioritize the rule
3. **UTC timezone** — recorded wrong times, causing confusion

Example of what happened:

```
Agent (before fix):
  "I'll log in DIARY.md according to the protocol...
   Location: operational/DIARY.md
   Trying to open: /Users/user/Dev/project/operational/DIARY.md
   ERROR: File not found. Skipping log."

RESULT: DIARY remained EMPTY. Protocol didn't work.
```

### After the System Prompt Fix

Agents started following the protocol correctly:

```
Agent (after fix):
  "I'll log in DIARY.md according to the protocol...
   Location: /Users/user/.hermes/profiles/agent1/operational/DIARY.md
   ✓ File found! Logging entry..."

RESULT: DIARY filled. TEAM-STATE updated. Time synchronized.
```

### Usage Data

| Metric | Before | After | Improvement |
|--------|:------:|:-----:|:----------:|
| DIARYs filled | 0/6 | 4/6+ | ∞ |
| TEAM-STATE updated | Never | Regularly | ∞ |
| Agents checking state before acting | Rarely | Always | Significant |
| Conflicts between agents | Frequent | Rare | Drastic reduction |
| Time lost to rework | High | Minimal | ~70% reduction |

### Why It Works

1. **The protocol is in the system_prompt** — the model sees it first, it's short, defines
   its essential behavior
2. **Absolute paths** — the agent finds files without error
3. **Correct timezone** — times in records are reliable
4. **3 enforcement layers** — system_prompt (maximum) + AGENTS.md (medium) +
   MEMORY.md (good) reinforce each other
5. **Clear responsibility** — orchestrator maintains TEAM-STATE, each
   agent maintains its DIARY

---

## 10. References

### Related Documents

| Document | What it contains | Location |
|----------|-----------------|----------|
| Initial Setup Guide | Complete Hermes profile setup | `docs/01-SETUP-WORKFLOW.md` |
| Daily Cycle | 6 phases of operational workflow | `docs/06-DAILY-CYCLE.md` |
| Operational Context Management | Skill for maintaining context | `skills/operacao/gestao-contexto-operacional/SKILL.md` |
| Operational Lessons 06/06/2026 | Complete problem diagnosis | `skills/.../references/licoes-06-06-2026.md` |

### Quick Commands

```bash
# Verify protocol is active in all profiles
grep "DIARY PROTOCOL" ~/.hermes/profiles/*/config.yaml

# Verify DIARYs
for p in orchestrator agent1 agent2; do
  wc -l ~/.hermes/profiles/$p/operational/DIARY.md
done

# Restart all gateways
for p in orchestrator agent1 agent2; do
  hermes --profile $p gateway run --replace
done

# Timezone diagnosis
grep "timezone:" ~/.hermes/profiles/*/config.yaml

# Gateway diagnosis
cat ~/.hermes/profiles/orchestrator/gateway.pid
ps aux | grep hermes | grep -v grep
```

### Frequently Asked Questions

**Q: What if the agent refuses to follow the protocol?**
A: Check if DIARY PROTOCOL is in the system_prompt (Step 7). If it is,
the problem might be context size — try shortening the rest of the
system_prompt to give more weight to the protocol.

**Q: Can a specialist agent read TEAM-STATE.md?**
A: Yes! It MUST read. But it MUST NOT modify it. Only the orchestrator writes
to TEAM-STATE.md. If a specialist tries to modify it, the orchestrator
will correct it on the next audit.

**Q: What if two orchestrators modify TEAM-STATE at the same time?**
A: This shouldn't happen — there's only ONE orchestrator. If you have multiple
teams, each team has its own orchestrator and its own TEAM-STATE.md.

**Q: Do I need to create DIARY.md manually for each agent?**
A: Yes, the first time. After that, the agent maintains the file
automatically following the system_prompt protocol.

**Q: What happens if DIARY.md gets too large?**
A: Compress it: move old content to an archive file
(`operational/archive/DIARY-YYYY-MM-DD.md`) and keep only the recent
records in the main DIARY.md.

---

> **Summary:** The Operational Memory System solves the fundamental problem
> of lack of memory between AI agent sessions. The key to success was
> discovering that the **system_prompt** (not AGENTS.md or skills) is the only
> place where critical operational rules are effectively followed by the model.
> With personal DIARY.md, shared TEAM-STATE.md, absolute paths,
> and configured timezone, the multi-agent team operates in a coordinated,
> auditable manner without rework.
