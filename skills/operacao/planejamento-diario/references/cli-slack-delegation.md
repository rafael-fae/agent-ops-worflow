# CLI Mode — Slack Delegation via Subagent

## Context

When {{ORCHESTRATOR}} is running in CLI/tmux mode (not gateway), the toolset does not include `send_message`. Slack messages must be sent via Slack Web API through a `delegate_task` subagent.

## Workflow

1. Invoke `delegate_task` with toolsets `["terminal","file"]`
2. Pass in context: channel ID, target `<@USER_ID>`, message content
3. Subagent reads `SLACK_BOT_TOKEN` from `~/.hermes/profiles/dalinar/.env` (via Python, NEVER shell grep — terminal masks tokens as `***`)
4. Subagent calls `conversations.join` if bot is not already a member
5. Subagent calls `chat.postMessage` with the message

## Template Context Block

```
{{ORCHESTRATOR}} needs to delegate task_X in the {{SLACK_CHANNEL_TEAM}} Slack channel ({{SLACK_CHANNEL_TEAM_ID}}).
The bot token is in ~/.hermes/profiles/dalinar/.env as SLACK_BOT_TOKEN.
The {{ORCHESTRATOR}} bot ({{SLACK_ID_ORCHESTRATOR}}) is already a member of {{SLACK_CHANNEL_TEAM}}.

Send the message via chat.postMessage to {{SLACK_CHANNEL_TEAM_ID}}.
```

## Pitfalls

- **Wrong channel:** Subagent may send to wrong channel if context is incorrect. Verify channel ID before sending. If wrong, delete via `chat.delete` with timestamp.
- **not_in_channel error:** Bot must join channel first via `conversations.join` before `chat.postMessage`. First delegation to a channel will fail without this.
- **Token masking:** `grep TOKEN .env` in terminal returns `***`. Use Python `open().read()` to get the real value.
- **Temp files with tokens:** Scripts created by the subagent contain the token in plaintext. Clean up after use with `rm`.
