# Slack Configuration for Hermes Agents + Personality and Memory

> Didactic guide — from empty workspace to operational agent on Slack,
> covering personality, permanent memory, and multiple agents.

---

## Table of Contents

1. [Slack Workspace](#1-slack-workspace)
2. [Create Slack App for the Agent (with Manifest)](#2-create-slack-app-for-the-agent-with-manifest)
3. [Get Tokens](#3-get-tokens)
4. [Configure Tokens in the Hermes Profile](#4-configure-tokens-in-the-hermes-profile)
5. [Agent Personality (system_prompt)](#5-agent-personality-system_prompt)
6. [Permanent Agent Memory](#6-permanent-agent-memory)
7. [Creating Multiple Agents](#7-creating-multiple-agents)
8. [Post-Configuration Checklist](#8-post-configuration-checklist)

---

## 1. Slack Workspace

### 1.1 Create a free workspace

1. Go to **[slack.com](https://slack.com)** and click **"Create a workspace"**.
2. Enter your email and follow the creation flow.
3. Choose a name for your company/team (e.g., `My Company`).
4. Set a short workspace name (e.g., `my-company`). This name appears in the URL: `my-company.slack.com`.
5. The **Free** plan is sufficient for testing — you get access to the last 90 days of history, app integrations, and up to 10 connected apps.

> Tip: The Free plan already allows Socket Mode (required for Hermes)
> at no cost. For production with many users, consider the Pro plan.

### 1.2 Create a dedicated channel for operations

Channels are where agents will listen and respond. Create at least one channel:

1. In the left sidebar, click the **+** next to "Channels".
2. Name: `#agents` (or `#ops`, `#automations`).
3. Set as **Public** (any member can join) or **Private** (invite only).
4. Click **Create**.

```
   #agents  ← public channel where your agent will operate
   ┌─────────────────────────────────────┐
   │  You: @my-agent, run the report     │
   │                                     │
   │  Agent: Report generated!           │
   │  [file.pdf]                         │
   └─────────────────────────────────────┘
```

### 1.3 Invite members (if needed)

- Go to **Settings > Manage members**.
- Click **Invite** and send the link via email.
- Each member needs to create a free account to participate.

---

## 2. Create Slack App for the Agent (with Manifest)

### 2.1 What is a Slack App?

A **Slack App** is your agent's identity inside the workspace. It has:

- A **name and icon** that appear in messages.
- **Permissions** (scopes) that define what the bot can do.
- **Tokens** that Hermes uses to authenticate.

Hermes connects to Slack via **Socket Mode** — a direct WebSocket connection, without needing a public HTTP server. This means your agent runs locally or on a private server without exposing ports.

> Summary: Slack App = agent's badge. Socket Mode = secure communication
> channel. Hermes = the brain that processes messages.

### 2.2 Step-by-step in the browser

#### Step 1 — Access the apps dashboard

Go to **[api.slack.com/apps](https://api.slack.com/apps)** and click **"Create New App"**.

#### Step 2 — Choose "From an app manifest"

On the creation screen, select:

```
○ From scratch    (manual creation — more steps)
● From an app manifest   ← CHOOSE THIS OPTION
```

The **manifest** is a JSON file that declares everything the app needs: name, permissions, events it listens to, settings. It's the fastest and safest way to configure.

#### Step 3 — Choose the workspace

Select the workspace you created in the previous section.

#### Step 4 — Paste the manifest JSON

An editor screen will appear. Paste the JSON below and click **"Next"** and then **"Create"**.

### 2.3 Manifest Template (with explanations)

```json
{
  "display_information": {
    "name": "Your Agent",
    "description": "Description of your agent — example: Operations Assistant",
    "background_color": "#1A1A2E"
  },
  "features": {
    "app_home": {
      "home_tab_enabled": false,
      "messages_tab_enabled": true,
      "messages_tab_read_only_enabled": false
    },
    "bot_user": {
      "display_name": "your-agent",
      "always_online": true
    }
  },
  "oauth_config": {
    "scopes": {
      "bot": [
        "app_mentions:read",
        "channels:history",
        "channels:read",
        "chat:write",
        "groups:history",
        "groups:read",
        "users:read",
        "files:read",
        "files:write",
        "reactions:read",
        "reactions:write"
      ]
    },
    "pkce_enabled": false
  },
  "settings": {
    "event_subscriptions": {
      "bot_events": [
        "app_mention",
        "message.channels",
        "message.groups"
      ]
    },
    "interactivity": {
      "is_enabled": true
    },
    "org_deploy_enabled": false,
    "socket_mode_enabled": true,
    "token_rotation_enabled": false,
    "is_mcp_enabled": false
  }
}
```

#### Explanation of Each Section

| Field | What it does | Required to change? |
|-------|-------------|:-------------------:|
| `display_information.name` | **Visible bot name in Slack.** Appears in mentions (`@Your Agent`) | ✅ **YES** — set your agent's name |
| `display_information.description` | Short text shown in the app profile | ✅ **YES** — describe the agent's role |
| `display_information.background_color` | Hex color for the app card (e.g., `#1A1A2E`) | 🟡 Optional — customize the color |
| `features.app_home.home_tab_enabled` | "Home" tab in the bot profile (recommended: false) | ❌ Leave as is |
| `features.app_home.messages_tab_enabled` | Messages tab in the bot profile (recommended: true) | ❌ Leave as is |
| `features.bot_user.display_name` | **Bot username** (no spaces, used in @mentions like `@your-agent`) | ✅ **YES** — same as `name` but without spaces |
| `features.bot_user.always_online` | If `true`, the bot appears online 24/7 | ❌ Leave as is |

##### Scopes (oauth_config.scopes.bot)

Each scope is a permission the bot requests:

| Scope | What it allows |
|-------|----------------|
| `app_mentions:read` | Know when the bot is mentioned (`@your-agent`) |
| `channels:history` | Read history of public channels where the bot is |
| `channels:read` | View list and metadata of public channels |
| `chat:write` | **Send messages as the bot** — essential for responding |
| `groups:history` | Read history of private channels |
| `groups:read` | View list and metadata of private channels |
| `users:read` | View user information (name, email) |
| `files:read` | Read files uploaded to channels |
| `files:write` | Upload files as the bot |
| `reactions:read` | View reactions on messages |
| `reactions:write` | Add reactions to messages |

##### Event Subscriptions (settings.event_subscriptions.bot_events)

| Event | When it fires |
|-------|---------------|
| `app_mention` | When someone mentions `@your-agent` in a channel |
| `message.channels` | When any message is sent in public channels where the bot is |
| `message.groups` | When any message is sent in private channels where the bot is |

##### Other Settings

| Field | What it does |
|-------|-------------|
| `oauth_config.pkce_enabled` | OAuth security (leave `false` for Socket Mode) |
| `settings.socket_mode_enabled` | **REQUIRED** — allows WebSocket connection without exposing ports |
| `settings.interactivity.is_enabled` | Enables interactive buttons and modals |
| `settings.token_rotation_enabled` | Automatic token rotation (leave `false`) |
| `settings.is_mcp_enabled` | MCP (Model Context Protocol — leave `false` for now) |

> Important: Hermes uses **chat:write** to respond,
> **channels:history** / **groups:history** to read contexts,
> and **app_mentions:read** + **message.im** to receive commands.

##### Event Subscriptions (settings.event_subscriptions.bot_events)

- **`app_mention`** — The bot receives an event every time someone mentions it in a public or private channel. E.g.: `@my-agent how much time until the deadline?`
- **`message.im`** — The bot receives direct messages (DMs). E.g.: the user opens a DM with the bot and types "today's report".

These two events are **essential** for Hermes to work. Without them, the agent doesn't know when it's been called.

##### Socket Mode (settings.socket_mode_enabled)

**REQUIRED for Hermes.** Set to `true`.

Socket Mode makes Slack connect to your agent via WebSocket instead of HTTP. Advantages:

- No need for a public server with SSL.
- Your agent can run on your laptop, a VPS, or anywhere.
- The connection is bidirectional and real-time.

---

## 3. Get Tokens

### 3.1 Difference between Bot Token and App Token

After creating the app, you need **two tokens**:

| Token | Prefix | What it is |
|-------|--------|------------|
| **Bot Token** | `xoxb-...` | Identifies the **bot** (the robot user). Used to read/write messages, act in the workspace |
| **App Token** | `xapp-...` | Identifies the **app** (the configuration). Used exclusively to authenticate the Socket Mode connection |

> Analogy: the Bot Token is the bot's "driver's license" (allows driving),
> the App Token is the "car key" (allows starting the engine/Socket).

### 3.2 Where to find each token

**Bot Token:**

1. In your app dashboard, go to **OAuth & Permissions**.
2. Scroll to **OAuth Tokens for Your Workspace**.
3. Click **"Install to Workspace"** (if not yet installed).
4. Authorize the permissions.
5. The `xoxb-...` token will appear. Copy and store it securely.

```
  OAuth & Permissions
  ┌────────────────────────────────────────────┐
  │  OAuth Tokens for Your Workspace           │
  │                                            │
  │  ● Bot User OAuth Token                    │
  │    xoxb-S...HERE         │
  │    [Copy]                                  │
  │                                            │
  │  ● Install to Workspace  (if not installed)│
  └────────────────────────────────────────────┘
```

**App Token (app-level):**

1. Go to **Basic Information**.
2. Scroll to **App-Level Tokens**.
3. Click **"Generate Token"**.
4. Give it a name (e.g., `socket-token`).
5. Add the scope **`connections:write`** (required for Socket Mode).
6. Generate and copy the `xapp-...` token.

```
  Basic Information
  ┌────────────────────────────────────────────┐
  │  App-Level Tokens                         │
  │                                            │
  │  ● socket-token                            │
  │    xapp-YOUR-APP-TOKEN-HERE         │
  │    Scopes: connections:write               │
  │                                            │
  │  [Generate Token]                          │
  └────────────────────────────────────────────┘
```

### 3.3 Install the app to the workspace

If you haven't already installed while copying the Bot Token:

1. Go to **OAuth & Permissions**.
2. Click **"Install to Workspace"**.
3. Review the requested permissions.
4. Click **"Allow"**.
5. Done — the bot is now a member of the workspace!

### 3.4 Add the bot to the channel

The bot needs to be invited to the channel where it will operate:

```
  In Slack, inside channel #agents, type:

  /invite @my-agent
```

The bot will appear as a channel member. You can also invite via the interface: click the channel name > Integrations > Add apps.

> If the bot is not added to the channel, it won't see messages
> (unless it receives a DM).

---

## 4. Configure Tokens in the Hermes Profile

### 4.1 Hermes profile structure

Hermes organizes configurations by **profiles**. Each profile has:

```
~/.hermes/profiles/<profile-name>/
├── .env               ← environment variables (tokens)
└── config.yaml        ← agent configuration
```

If you don't have a profile yet, create one:

```bash
mkdir -p ~/.hermes/profiles/my-agent
```

### 4.2 .env File

Create or edit `~/.hermes/profiles/my-agent/.env`:

```env
# ─── Slack ──────────────────────────────────────
SLACK_BOT_TOKEN=xoxb-S...HERE
SLACK_APP_TOKEN=xapp-YOUR-APP-TOKEN-HERE
SLACK_HOME_CHANNEL=C0123456789
SLACK_REQUIRE_MENTION=true
```

| Variable | Required? | Description |
|----------|-----------|-------------|
| `SLACK_BOT_TOKEN` | Yes | Bot token (xoxb-...). Allows Hermes to act as the bot |
| `SLACK_APP_TOKEN` | Yes | App token (xapp-...). Used for Socket Mode |
| `SLACK_HOME_CHANNEL` | Yes | Main channel ID (e.g., #agents). Hermes uses this as default channel |
| `SLACK_REQUIRE_MENTION` | No (default: true) | If `true`, bot only responds when mentioned. If `false`, responds to any message in the channel |

**How to get the channel ID (SLACK_HOME_CHANNEL):**

In Slack, right-click the channel name > **"Copy link"**.
The link will have the format:
```
https://my-company.slack.com/archives/C0123456789
```
The ID is the `C0123456789` part.

> Alternative: click the channel name, go to "About" and see the ID
> at the bottom of the page.

### 4.3 config.yaml File

Create or edit `~/.hermes/profiles/my-agent/config.yaml`:

```yaml
agent:
  name: "My Agent"
  system_prompt: "..."  # ← will be explained in Section 5

slack:
  bot_user_id: "U0123456789"
  bot_user_name: "my-agent"
  home_channel: "C0123456789"
```

**How to get the bot_user_id:**

1. In Slack, send a DM to the bot.
2. Hermes (when connected) can identify it. But to configure beforehand:
   - Go to `api.slack.com/apps` > Your app > **OAuth & Permissions**.
   - The `Bot User ID` appears in the "Bot User" section.
   - Or simply mention the bot in a channel and see the ID in the profile URL.

---

## 5. Agent Personality (system_prompt)

### 5.1 What is system_prompt?

The **system_prompt** is the fundamental instruction that defines **WHO** the agent is, **HOW** it thinks, and **WHAT** tone its responses use. It's like the DNA of your assistant's personality.

> Think of the system_prompt as the agent's "code of conduct."
> Everything it does is guided by this instruction.

### 5.2 Where to configure

In the profile's `config.yaml`:

```yaml
agent:
  name: "My Agent"
  system_prompt: |
    You are an administrative assistant focused on organizing the team's
    daily tasks. Your tone is professional but friendly. Respond in
    English. Whenever you receive a request, confirm receipt and inform
    the estimated time. Use bullet points to list items.
    If something is not clear, ask for clarification before acting.
```

### 5.3 Personality Examples

#### Example 1 — Administrative Assistant

```yaml
agent:
  name: "Admin Assistant"
  system_prompt: |
    You are an administrative assistant specialized in organizing
    tasks, schedules, and team documents.

    Response tone: professional, direct, polite.
    Language: English.

    Rules:
    - Always greet who called you.
    - Confirm tasks with estimated time.
    - Use bullet points in lists.
    - Ask before executing destructive actions (delete, overwrite).
    - If you don't know, say "I don't know" and offer alternative help.
```

#### Example 2 — Data Analyst

```yaml
agent:
  name: "Data Analyst"
  system_prompt: |
    You are a data analyst specialized in generating financial
    reports and performance metrics.

    Response tone: technical, objective, data-driven.
    Language: English.

    Rules:
    - Always present data with context (comparison, trend).
    - Use tables to compare results.
    - If data is missing, report the gap.
    - Suggest actions based on numbers.
    - Prefer charts when relevant (ascii or file reference).
```

#### Example 3 — Generalist (multi-function)

```yaml
agent:
  name: "General Assistant"
  system_prompt: |
    You are a generalist assistant that helps in the company's
    day-to-day operations. You can research information, organize
    files, answer questions, and execute simple automations.

    Response tone: friendly and helpful, like a team colleague.
    Language: English, but understands commands in other languages.

    Rules:
    - For general knowledge questions, research before answering.
    - If the user is frustrated, be patient and help resolve.
    - Offer shortcuts: "Next time, you can ask..."
    - Keep responses short in busy channels, detailed in DMs.
```

### 5.4 Tips for a Good system_prompt

1. **Be specific** — "You are an assistant" is vague. "You are an assistant that organizes meetings" is better.
2. **Define the tone** — "professional", "casual", "technical", "friendly".
3. **Include clear rules** — "Never delete files without confirmation", "Always confirm before sending".
4. **Exemplify response format** — "Use bullet points", "Respond in short paragraphs".
5. **Limit to 300-500 words** — Very long prompts can dilute the main instruction.

---

## 6. Permanent Agent Memory

### 6.1 What is permanent memory?

Unlike a common chatbot that forgets everything after the conversation, Hermes maintains two memory files that persist between sessions:

| File | Content |
|------|---------|
| `MEMORY.md` | Facts, decisions, project context |
| `USER.md` | User profile (name, preferences, history) |

These files live in the profile directory:

```
~/.hermes/profiles/my-agent/
├── .env
├── config.yaml
├── MEMORY.md       ← facts the agent remembers
└── USER.md         ← user profile
```

### 6.2 How it works in practice

The agent uses the **tool** `memory` to:

- **Save** information: `memory save "The user prefers PDF reports"`.
- **Query** information: `memory read` (reads both files).

Every time the agent starts a session, it automatically reads `MEMORY.md` and `USER.md`. It's like it "wakes up" remembering everything that was recorded.

### 6.3 What to save in MEMORY.md

```
~/.hermes/profiles/my-agent/MEMORY.md
```

Example content:

```markdown
# Agent Memory

## Decisions Made
- Weekly reports should be generated every Monday at 9 AM.
- Automatic backup configured for critical folders.

## Project Context
- Active project: Server migration (deadline: June 30).
- Technical contact: John (john@company.com).

## Formatting Preferences
- PDF reports with company logo.
- Slack responses with status emojis (✅ done, ❌ error).
```

### 6.4 What to save in USER.md

```markdown
# User Profile

## Identification
- Name: Jane Smith
- Title: Operations Manager
- Timezone: UTC-5 (Eastern)

## Preferences
- Language: English
- Response tone: Formal
- Report format: PDF, sent by email
- Work hours: 9 AM to 6 PM (don't send notifications outside these hours)

## History
- June 1: Requested weekly sales dashboards.
- June 5: Asked to test new scheduling skill.
```

### 6.5 Memory usage tips

- **Revisit periodically** — Ask the agent: "What do you know about me?" It reads the files and responds.
- **Update when things change** — If a preference changes, the user can ask: "Update my memory: now I prefer Excel reports."
- **Don't save everything** — Only what's relevant for medium/long term. Details from a single conversation are best left in the chat history.

---

## 7. Creating Multiple Agents

### 7.1 Each agent needs...

| Component | Why |
|-----------|-----|
| Own profile | Each profile has its `.env`, `config.yaml`, memory |
| Own Slack App | Each app has its token, name, permissions |
| Own personality | Each system_prompt defines a different role |
| (Optional) Own channel | Can separate by subject or keep all in the same channel |

### 7.2 Folder structure for multiple agents

```
~/.hermes/profiles/
├── agent-admin/
│   ├── .env              ← tokens from Slack App "Admin Assistant"
│   ├── config.yaml       ← system_prompt: admin
│   ├── MEMORY.md
│   └── USER.md
│
└── agent-dev/
    ├── .env              ← tokens from Slack App "Dev Assistant"
    ├── config.yaml       ← system_prompt: developer
    ├── MEMORY.md
    └── USER.md
```

### 7.3 Same channel or separate channels?

```
Same channel (#agents)              Separate channels
─────────────────────────           ─────────────────────────
#agents                             #admin  +  #dev
│                                   │            │
├─ @admin: report                   @admin:      @dev:
├─ @dev: deploy now                 "report"     "deploy"
└─ (confusing if many agents)       (organized, each in their own)
```

**Recommendation:** Start with the same channel. If it gets confusing, create separate channels.

### 7.4 Unique names for each Slack App

In each app's manifest, use different names:

| App | `display_information.name` | `display_name` |
|-----|---------------------------|----------------|
| Admin | "Admin Assistant" | `admin-assistant` |
| Dev | "Dev Assistant" | `dev-assistant` |

This avoids visual confusion and @mention conflicts.

### 7.5 Sharing the workspace

All agents can share the **same workspace**. There's no limit on the Free plan for the number of bots (only for connected apps: 10).

---

## 8. Post-Configuration Checklist

Use this list to verify everything is working:

```
[ ] Slack App created with manifest (api.slack.com/apps)
[ ] Tokens copied to profile .env
[ ] Bot added to channel (/invite @my-agent)
[ ] Gateway started (hermes --profile my-agent gateway run)
[ ] TEST: Mention @my-agent in the channel
[ ] TEST: Send a DM to the bot
[ ] Personality configured in system_prompt
[ ] MEMORY.md created with initial facts
[ ] USER.md created with user profile
```

### Quick test

After starting the gateway:

```bash
hermes --profile my-agent gateway run
```

You should see logs similar to:

```
[INFO] Connected to Slack via Socket Mode
[INFO] Bot @my-agent listening in #agents
[INFO] Waiting for messages...
```

In Slack, type:

```
@my-agent hello, is it working?
```

The bot should respond.

---

> **Next step:** See `07-SKILLS-GUIDE.md` to add skills
> to your agent, or `02-PERSONALIZACAO-PERFIS.md` for fine-tuning
> behavior.
