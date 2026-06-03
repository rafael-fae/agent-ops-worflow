# Slack Protocol — Agent Ops Workflow

> The complete guide to agent communication via Slack. Covers message
> hierarchy, @mention format, delegation templates, the silence rule,
> lockdown protocol, and troubleshooting.

---

## Table of Contents

1. [Why Slack?](#why-slack)
2. [Channel Structure](#channel-structure)
3. [Message Hierarchy: Channel vs. Thread](#message-hierarchy-channel-vs-thread)
4. [The @Mention Format](#the-mention-format)
5. [Delegation Template](#delegation-template)
6. [Agent Response Protocol](#agent-response-protocol)
7. [The Silence Rule](#the-silence-rule)
8. [Lockdown Protocol](#lockdown-protocol)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)
11. [Reference Tables](#reference-tables)

---

## Why Slack?

Slack provides three features that make it the ideal communication layer for
multi-agent operations:

1. **Threads** — Each task gets an isolated conversation that does not
   pollute the main channel. All history about a task lives in one place.

2. **@mentions** — Direct dispatch to a specific agent. Only the mentioned
   agent responds (silence rule). No cross-talk.

3. **Persistence** — Every message, decision, and status update is
   permanently logged and searchable. No context is lost between sessions.

Alternative chat systems (Discord, Teams, Matrix) can work if they support
threads and @mentions, but Slack is the reference implementation that this
protocol is designed for.

---

## Channel Structure

### Single Operations Channel

The simplest setup uses one dedicated channel for all agent communication.

```
Channel: #agent-ops-nova
Purpose: Daily planning, task delegation, status updates, reports

Participants:
- Commander (human)  — reads plans, approves, issues directives
- Orchestrator       — posts plans, delegates, audits, reports
- Agent A            — executes tasks, reports in threads
- Agent B            — executes tasks, reports in threads
- Agent C (auditor)  — cross-checks completed tasks
```

All top-level messages in this channel come from the Commander or the
Orchestrator. Agents reply within threads.

### Multi-Channel Setup (Advanced)

For larger teams, you can use multiple channels:

| Channel              | Purpose                                    |
|----------------------|--------------------------------------------|
| `#agent-ops-nova`    | Daily planning, approvals, reports         |
| `#nova-execution`    | Delegation messages and execution threads  |
| `#nova-audit`        | Audit reports and cross-checks             |
| `#nova-alerts`       | Lockdown signals, critical errors          |

The protocol rules are the same across channels. Each channel has its own
thread space — do not cross-post between channels for the same task.

### Channel Naming Convention

```
#agent-ops-{teamname}     — Main operations channel
#agent-ops-{teamname}-exec — Execution channel (if separate)
#agent-ops-{teamname}-audit — Audit channel (if separate)
#agent-ops-{teamname}-alerts — Alerts and lockdowns
```

The channel ID (e.g., `C0123456789`) is referenced in the Hermes config as
`home_channel`. All agents must be invited to the channels they operate in.

---

## Message Hierarchy: Channel vs. Thread

Understanding the distinction between channel messages and thread replies
is the most important concept in this protocol.

### Rules

| Context              | Who Can Post                      | Example                           |
|----------------------|-----------------------------------|-----------------------------------|
| Top-level (channel)  | Commander, Orchestrator only      | Plan, delegation, report, lockdown|
| Thread reply         | Any agent in the thread           | Status update, commit report      |
| DM                   | Never for task communication      | Escalation only (Commander)       |

### Top-Level Messages

These are the only types of messages that appear in the main channel view:

1. **Plan announcement:** Orchestrator posts the daily PLANO.md summary
2. **Approval:** Commander approves or rejects the plan
3. **Delegation:** Orchestrator assigns tasks (one per message)
4. **Directive:** Commander gives a team-wide instruction
5. **Report:** Orchestrator posts the end-of-day summary
6. **Lockdown:** Commander triggers emergency freeze
7. **Status check:** Orchestrator asks for a team-wide status

### Thread Replies

These belong inside a specific task's thread:

1. **Acknowledgment:** Agent confirms receipt of task
2. **Progress update:** Agent reports checkpoints mid-task
3. **Completion report:** Agent marks task done with commit hash
4. **Audit result:** Auditor passes or fails the task
5. **Clarification:** Any participant asks or answers a question about the task
6. **Correction:** Agent fixes issues and re-submits for audit
7. **Re-audit:** Auditor re-verifies after fixes

### What Never Belongs in a Thread

- A new task delegation (that is a new top-level message)
- A completely unrelated topic
- A global directive or lockdown

---

## The @Mention Format

### Why `<@USER_ID>` Is Mandatory

Slack supports two ways to mention a user:

1. **Display name** — `@nova-dev` (human-readable, changes if name changes)
2. **User ID** — `<@U0123456789>` (permanent, never changes)

**You MUST use the User ID format.** Here is why:

- Display names can change. If someone renames `@nova-dev` to `@nova-engineer`,
  all your historical messages break — the @mention no longer resolves.
- Hermes and other automated agents parse the User ID from the message. If
  the display name is used, the parser may not know which agent to route to.
- The Slack API resolves `<@U0123456789>` to the user in any context. The
  display name `<@nova-dev>` only works if the user is currently in the
  channel.

### How to Find User IDs

**Method 1: Slack UI**
1. Click on the user's profile picture
2. Click **More** (three dots)
3. Select **Copy member ID**
4. The ID looks like `U0123456789`

**Method 2: Slack API**
```bash
# Use the users.list API endpoint
curl -H "Authorization: Bearer xoxb-your-token" \
  https://slack.com/api/users.list \
  | jq '.members[] | {name: .name, id: .id}'
```

**Method 3: Message context**
1. Right-click any message from the user
2. Select **Copy link**
3. The link contains the user ID: `.../pU0123456789_...`
4. Extract the `U` + 9-11 digits

### The Format in Practice

```
✅ Correct:
<@U0123456789> Task task_01: Fix login redirect bug

❌ Wrong:
@nova-dev Task task_01: Fix login redirect bug
```

### Document Your User IDs

Create an `AGENTS.md` file in your project root:

```markdown
# Agent Roster — Team Nova

| Agent Role  | Slack Display Name | Slack User ID      | Default Engine        |
|-------------|--------------------|--------------------|-----------------------|
| Orchestrator| nova-orch          | <@U0123456789>     | Gemini 3.1 Pro        |
| Dev Agent   | nova-dev           | <@U9876543210>     | Gemini 3.1 Pro        |
| Audit Agent | nova-audit         | <@U5555555555>     | Opus 4.7              |
| Commander   | sarah              | <@U0000000001>     | Human                 |
```

Keep this file updated whenever team membership changes.

---

## Delegation Template

Every task delegation message follows a strict template. This ensures
consistency, parsability, and completeness.

### The Exact Template

```
<@USER_ID> Task TASK_ID: TASK_TITLE

**Engine:** ENGINE_NAME (MANDATE_LEVEL)
**Priority:** PRIORITY_LEVEL
**File:** planejamento-diario/DATE/TASK_FILE

**Summary:**
BRIEF_DESCRIPTION

**Key instructions:**
1. INSTRUCTION_1
2. INSTRUCTION_2

**Checklist reminder:**
- CHECKLIST_ITEM_1
- CHECKLIST_ITEM_2

**Constraints:**
- CONSTRAINT_1
- CONSTRAINT_2
```

### Mandate Levels

| Level     | Syntax                                  | Meaning                                    |
|-----------|-----------------------------------------|--------------------------------------------|
| DEFAULT   | `**Engine:** Gemini 3.1 Pro (DEFAULT)`  | Use this engine unless it fails            |
| MANDATORY | `**Engine:** Opus 4.7 (MANDATORY)`      | This engine is required. No alternatives.  |
| PROHIBITED| `**Engine:** DeepSeek (PROHIBITED)`     | Do NOT use this engine without Commander order |
| ABSOLUTE  | `**ORDEM ABSOLUTA — Engine:** Gemini`   | Non-negotiable. Split subtasks if failing. |

### Example Delegations

**Example 1: Standard Coding Task**

```
<@U9876543210> Task task_01: Fix login redirect bug

**Engine:** Gemini 3.1 Pro (DEFAULT)
**Priority:** 🔴 HIGH — Blocks task_02
**File:** planejamento-diario/2026-06-10/task_01.md

**Summary:**
The login redirect is sending users to /dashboard instead of
/home after authentication. Fix the redirect URL constant.

**Key instructions:**
1. Find the redirect constant in AuthController.php
2. Change the value from '/dashboard' to '/home'
3. Test in staging with curl
4. Run the full test suite

**Checklist reminder:**
- Verified fix in staging
- Ran full test suite
- Filled Conclusion section in task_01.md
- Committed and pushed

**Constraints:**
- Do NOT modify database migration files
- Do NOT change the authentication middleware
- Only touch the redirect URL constant
```

**Example 2: Audit Task**

```
<@U5555555555> Task task_04: Audit login fix

**Engine:** Opus 4.7 (MANDATORY — audit requires deep analysis)
**Priority:** 🟡 MEDIUM
**File:** planejamento-diario/2026-06-10/task_04.md

**Summary:**
Audit task_01 (login redirect fix) and task_02 (API migration).
Verify commits, check diffs, confirm constraints respected.

**Key instructions:**
1. git log --oneline to find commits
2. git show each commit to review changes
3. Read each task file for checklist completion
4. Update PLANO.md and INDICE.md after each pass

**Constraints:**
- Do not modify the code you are auditing
- Post audit results in the original task threads
```

**Example 3: Documentation Task (No Code)**

```
<@U9876543210> Task task_03: Update API documentation

**Engine:** Gemini 3.1 Pro (DEFAULT)
**Priority:** 🟢 LOW
**File:** planejamento-diario/2026-06-10/task_03.md

**Summary:**
The API migration v2 changed 3 endpoint URLs. Update the
API documentation to reflect the new endpoints.

**Key instructions:**
1. Read the current API docs
2. Cross-reference with the migrated code
3. Update URLs and request/response examples
4. Mark changed endpoints with "(v2)" tag

**Constraints:**
- Do not change code — only documentation files
- Keep the same markdown structure
```

### What NOT to Include in Delegation Messages

1. **Tables** — Pipe characters (`|`) break the mention parser. Use bullet
   points or bold text instead.

2. **Long code blocks** — Reference the task file for full instructions.
   Keep the delegation message to a summary.

3. **Multiple tasks in one message** — Each task gets its own top-level
   message. Never combine task_01 and task_02 in a single post.

4. **Unrelated context** — Stick to the task. Historical context goes in
   the task file, not the Slack message.

---

## Agent Response Protocol

### Acknowledgment

When an agent receives a delegation, they must acknowledge within the
thread:

```
Received. Starting task_01 now.
```

If the agent cannot start immediately (e.g., waiting for a dependency):

```
Received. Task_01 is blocked by task_02. Will start as soon as
task_02 is complete.
```

### Progress Updates

For long tasks, periodic updates are helpful:

```
Progress update on task_01 (30 min in):
- Found the redirect constant
- Changed URL, testing now
- Estimated completion: 15 min
```

### Completion Report

```
✅ Task_01 complete.
Commit: aabbccdd11223344
Tests: 47/47 passing
Observations: Fixed redirect URL in AuthController.php.
Ready for audit.
```

The completion report must include:
- ✅ (checkmark) + task ID
- Commit hash (verified with `git log --oneline`)
- Test results or verification evidence
- Observations about what was done
- "Ready for audit" handoff

### Error Report

```
⚠️ Task_01 stalled.
Engine returned RESOURCE_EXHAUSTED at step 3.
I split the task into subtasks but hit the same error.
Stopping and waiting for instructions.

Partial work committed at commit: 99bbaa00 (not complete).
```

### Audit Result

Pass:
```
✅ Audit passed for task_01.
Commit aabbccdd verified.
- Login fix correct (redirect URL changed)
- All tests pass (47/47)
- Checklist complete (6/6)
- Constraints respected
INDICE.md updated.
```

Fail:
```
⚠️ Audit failed for task_01.
Issues found:
- Checklist item #3 (staging test) not filled
- Conclusion section missing commit hash
Please fix and re-submit in this thread.
```

---

## The Silence Rule

**Definition:** Only the agent who is @mentioned in a message responds to
that message. All other agents remain silent.

### Why It Matters

In a multi-agent channel, multiple agents see every message. Without the
silence rule, you get:

- **Cross-talk:** Agent B responds to a task meant for Agent A
- **Confusion:** Two agents execute the same task in parallel
- **Noise:** Irrelevant replies pollute the thread
- **Lost context:** The thread becomes unreadable

### How It Works

1. The orchestrator posts: `<@U0123456789> Task task_01: ...`
2. Only the user with ID `U0123456789` responds in that thread.
3. All other agents (including orchestrator, until needed) stay silent.
4. After the agent reports completion, the orchestrator may reply for audit.

### Exceptions

The silence rule has three exceptions:

1. **The Commander** can always post anywhere, anytime. Their authority
   overrides the silence rule.

2. **The Orchestrator** can reply in any thread for:
   - Clarifying instructions
   - Conducting audits
   - Providing status updates

3. **Lockdown** — During a lockdown, NO ONE posts anything except the
   Commander.

### Practical Example

```
Channel: #agent-ops-nova

orchestrator: <@U9876543210> Task task_01: Fix login redirect
              bug. [Engine: Gemini...]
              ↑ Only nova-dev (U9876543210) responds

nova-dev: Received. Starting.               ← OK (nova-dev)
nova-audit: I can help if needed.           ← VIOLATION (silence rule)
nova-orch: @nova-audit please stay silent   ← Warning
nova-dev: ✅ Complete. Commit: aabbccdd     ← OK
nova-audit: Nice work!                      ← VIOLATION (silence rule)
nova-orch: ✅ Audit passed.                 ← OK (orchestrator)
```

---

## Lockdown Protocol

The lockdown protocol is the emergency brake for the entire operation. When
triggered, ALL agent activity stops immediately.

### Trigger Phrases

The Commander initiates lockdown by posting one of these exact phrases as a
top-level message in the operations channel:

```
LOCKDOWN
sinal vermelho
RED SIGNAL
```

These are case-insensitive but must be exact. Variations like "lockdown
please" or "sinal amarelo" are not recognized.

### What Happens During Lockdown

1. **All agents freeze immediately.** Drop whatever you are doing.
2. **No new actions.** Do not start new tasks, do not continue current
   ones, do not commit, do not push.
3. **No new messages.** Do not post anything in any channel or thread.
4. **Partial work stays as-is.** Do not revert or delete partial work.
5. **Wait for the all-clear.** Only the Commander can lift the lockdown.

### What the Commander Does During Lockdown

1. Posts the lockdown signal
2. Resolves the issue (security breach, wrong direction, external crisis)
3. Posts the all-clear message:

```
LOCKDOWN LIFTED
sinal verde
GREEN SIGNAL
```

4. Optionally posts a directive explaining what happened and what changes

### Resuming After Lockdown

1. All agents report their state in their task threads:
   ```
   Status before lockdown: Step 3 of 6 complete. Partial commit at
   99bbaa00 (not pushed). Resuming from step 4.
   ```
2. The orchestrator assesses if any tasks need to be re-assigned or
   scrapped.
3. Normal operations resume.

### Sample Lockdown Flow

```
sarah: LOCKDOWN                          ← Emergency signal
nova-dev: (freezes immediately)          ← No message needed
nova-audit: (freezes immediately)        ← No message needed
nova-orch: (freezes)                     ← No message needed

... 10 minutes pass ...

sarah: LOCKDOWN LIFTED                   ← All clear
sarah: Security issue resolved.
       Please check your threads for
       any tasks that touched the auth
       module. Resume normal ops.

nova-dev: Status before lockdown:        ← OK
  task_01 complete, task_02 at step 2.
nova-audit: Status before lockdown:      ← OK
  task_04 audit in progress, no partial results.
nova-orch: Resuming audits.              ← OK
```

### What Is NOT a Lockdown

These are NOT lockdown signals:

- "Can everyone pause for a moment?" (clarification, not lockdown)
- "Hold on, let me check something" (not lockdown)
- "Stop what you're doing" (must use exact keyword "LOCKDOWN")

If the Commander means lockdown, they will use the exact keyword. Anything
else is a normal conversation.

---

## Best Practices

### 1. No Duplicate Threads

If a task needs re-audit or correction, use the **existing thread**. Do not
create a new top-level message.

```
✅ Correct: Reply in original thread
❌ Wrong: "@agent Task task_01 re-audit" (new top-level message)
```

### 2. Checkboxes Before Reporting

Before posting a completion report, verify that all checklist items in the
task file are filled (`[x]`). A task with empty checkboxes is not complete.

```
# What the orchestrator checks during audit:
[ ] All checkboxes filled in task_XX.md
[ ] No [ ] left unchecked
[ ] Conclusion section has agent, date, engine, commit, observations
```

### 3. Use Thread Links for Reference

When referring to a previous conversation, use the Slack thread link:

```
See the discussion in task_01 thread: https://... (not "remember when...")
```

### 4. One Mention Per Message

Never @mention multiple agents in a single delegation message. Each task
has one owner. If a task needs collaboration, it should be split into
subtasks.

```
✅ Correct:
<@U0123456789> Task task_01: ...
<@U9876543210> Task task_02: ...

❌ Wrong:
<@U0123456789> <@U9876543210> Task task_01: ... (who owns this?)
```

### 5. No DMs for Task Communication

Everything about a task goes in its thread. Do not DM agents about tasks.
If the Commander needs to escalate, they DM the orchestrator, who then
updates the thread.

### 6. Reactions as Signals

Use emoji reactions for lightweight signaling:

| Reaction | Meaning                                    |
|----------|--------------------------------------------|
| ✅       | Task complete / approved                   |
| 👁       | Audited / being reviewed                   |
| ⬜       | Pending / not started                      |
| 🚨       | Error / needs attention                    |
| 🔒       | Lockdown active                            |
| 🔓       | Lockdown lifted                            |

Reactions are not a substitute for written communication. Use them as
supplements to text messages.

### 7. Archive Completed Days

At the end of each day, the orchestrator should pin the daily report
message in the channel for easy reference. Old threads can be archived or
left as-is since Slack preserves thread history.

### 8. Keep AGENTS.md Updated

Whenever a team member changes their Slack display name or leaves the team,
update `AGENTS.md` immediately. Stale agent rosters cause delegation to
fail silently.

---

## Troubleshooting

### Common Issues and Fixes

| Issue                                    | Cause                                        | Fix                                                  |
|------------------------------------------|----------------------------------------------|------------------------------------------------------|
| Agent does not respond to @mention       | Agent not in channel                         | `/invite @agent-name`                                |
| @mention shows as plain text             | Using display name instead of User ID        | Use `<@U...>` format                                 |
| Message not showing in thread            | Posted as new message instead of reply       | Click "Reply in thread" before posting               |
| Bot returns `not_in_channel` error       | Bot not invited to the operations channel    | Invite the bot user to the channel                   |
| `invalid_auth` error                     | Token expired or revoked                     | Generate new token in Slack API dashboard             |
| `missing_scope` error                    | Bot lacks required permission                | Add scope in app settings, reinstall app             |
| Pipe characters break mention parser     | Using tables in delegation message           | Use bullet points or bold text instead of tables     |
| Wrong agent responds to delegation       | Multiple agents mentioned or silence rule violated | Use <@USER_ID> for exactly one agent          |
| Thread history lost after reinstall      | App reinstalled with new credentials         | Keep the same app ID across reinstalls               |
| Lockdown keyword not recognized          | Typo or alternate phrasing                   | Use exact phrase: LOCKDOWN / sinal vermelho          |

### Debugging Steps

**Problem: Agent does not respond**

1. Check if the agent is in the channel:
   ```bash
   curl -H "Authorization: Bearer xoxb-token" \
     https://slack.com/api/conversations.members?channel=C0123456789
   ```
2. Check if the agent's Hermes instance is running
3. Verify the User ID in the @mention matches the agent's config
4. Check Slack app logs in api.slack.com/apps → Your App → Logs

**Problem: Messages not routing correctly**

1. Check that the bot token has `chat:write` scope
2. Verify `thread_ts` is included in reply messages
3. Check that the home_channel ID in Hermes config matches the actual
   channel ID

**Problem: Lockdown not working**

1. Verify the Commander is using the exact keyword: `LOCKDOWN`
2. Check that all agents have the lockdown keyword in their prompt/system
   instructions
3. Run a lockdown drill during a non-critical time to test the flow

### Recovery from Common Mistakes

**I posted a delegation in the wrong thread.**
```
orchestrator: (realizes mistake)
orchestrator: ⚠️ Wrong thread. Moving to correct one.
orchestrator: Deletes the misplaced message (if within edit window)
orchestrator: Posts the delegation in the correct location
```

**An agent posted in the channel instead of a thread.**
```
orchestrator: ⚠️ @agent, please reply in your thread:
              https://link-to-task-thread
orchestrator: (deletes misplaced message if possible)
agent: (reposts in correct thread)
```

**The Commander accidentally triggered lockdown.**
```
sarah: LOCKDOWN  ← oops
sarah: LOCKDOWN LIFTED — false alarm, sorry.
       Resume normal operations.
```

---

## Reference Tables

### Complete Message Type Reference

| Message Type        | Who Posts         | Where             | Example                          |
|---------------------|-------------------|-------------------|----------------------------------|
| Plan announcement   | Orchestrator      | Top-level channel | 📋 Daily plan for DD/MM/YYYY... |
| Plan approval       | Commander         | Top-level channel | ✅ Plan approved. Proceed.       |
| Plan rejection      | Commander         | Top-level channel | ⚠️ Plan needs revision: ...     |
| Task delegation     | Orchestrator      | Top-level channel | <@U...> Task task_01: ...       |
| Task ack            | Assigned agent    | Thread reply      | Received. Starting now.          |
| Task progress       | Assigned agent    | Thread reply      | Progress: step 3 of 6 done.     |
| Task completion     | Assigned agent    | Thread reply      | ✅ Task_01 complete. Commit:... |
| Audit pass          | Orchestra/auditor | Thread reply      | ✅ Audit passed for task_01.    |
| Audit fail          | Orchestra/auditor | Thread reply      | ⚠️ Audit failed: ...            |
| Daily report        | Orchestrator      | Top-level channel | 📊 Daily Report — DD/MM/YYYY    |
| Lockdown            | Commander         | Top-level channel | LOCKDOWN                         |
| Lockdown lifted     | Commander         | Top-level channel | LOCKDOWN LIFTED                  |
| Directive           | Commander         | Top-level channel | 📢 Attention team: ...          |
| Clarification       | Any participant   | Thread reply      | Question about step 2...         |

### Slack Scope Reference

| Scope                | Required For                        | Used In                         |
|----------------------|-------------------------------------|---------------------------------|
| `channels:history`   | Reading channel history             | Finding threads, audit context  |
| `channels:read`      | Viewing channel info                | Channel membership, ID lookup   |
| `chat:write`         | Sending messages                    | Delegation, reports, everything |
| `reactions:read`     | Reading emoji reactions             | Signal detection                |
| `users:read`         | Reading user info                   | Resolving @mentions, ID lookup  |

### Token Types

| Token Type           | Prefix   | Where to Find                     | Purpose                  |
|----------------------|----------|-----------------------------------|--------------------------|
| Bot Token            | `xoxb-`  | OAuth & Permissions page          | Bot authentication       |
| App Token (Socket)   | `xapp-`  | Basic Information → App-Level Tokens | Socket mode connection |

### User ID Format

| ID Format            | Example            | How to Obtain                         |
|----------------------|--------------------|---------------------------------------|
| User ID              | `U0123456789`      | Profile → More → Copy member ID       |
| Channel ID           | `C0123456789`      | Channel URL: /archives/C0123456789    |
| Team/Workspace ID    | `T0123456789`      | Workspace URL: app.slack.com/client/T... |

### Communication Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   #agent-ops-nova (Channel)                  │
├─────────────────────────────────────────────────────────────┤
│ Top-level messages:                                          │
│                                                              │
│ orchestrator: 📋 Daily plan for 10/06/2026...               │
│ sarah:        ✅ Plan approved. Proceed.                     │
│                                                              │
│ orchestrator: <@U9876543210> Task task_01: Fix login bug    │ ← Thread A
│ orchestrator: <@U5555555555> Task task_04: Audit login fix  │ ← Thread B
│                                                              │
│ nova-dev:     ✅ Task_01 complete. Commit: aabbccdd          │ ← In Thread A
│ nova-orch:    ✅ Audit passed.                               │ ← In Thread A
│                                                              │
│ orchestrator: 📊 Daily Report — 10/06/2026...                │
└─────────────────────────────────────────────────────────────┘

Thread A (task_01):
├── nova-dev: Received. Starting.
├── nova-dev: ✅ Complete. Commit: aabbccdd
├── nova-orch: ✅ Audit passed.
└── nova-dev: Thanks.

Thread B (task_04):
├── nova-audit: Received. Starting audit.
├── nova-audit: ✅ task_01 audited (passed).
├── nova-audit: ✅ task_02 audited (passed).
└── nova-orch: Confirmed. INDICE.md updated.
```

---

## Summary — Protocol Commandments

1. **Always use `<@USER_ID>`** — never display names.
2. **One task = one top-level message** = one thread.
3. **If not @mentioned, stay silent** — silence rule is absolute.
4. **Only the orchestrator posts top-level messages** (plus Commander).
5. **No tables in delegation messages** — pipe characters break mentions.
6. **Check checkboxes before reporting** — auditors will check.
7. **Never DM for task communication** — it belongs in the thread.
8. **LOCKDOWN freezes everything** — exact keyword, non-negotiable.
9. **Lockdown only lifted by Commander** — with exact "LOCKDOWN LIFTED".
10. **AGENTS.md is the source of truth** — keep it updated.
