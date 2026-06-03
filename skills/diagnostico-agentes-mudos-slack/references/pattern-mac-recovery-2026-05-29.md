# {{GIT_OPS}}-mac Recovery Case Study (2026-05-29)

## Symptom
{{GIT_OPS}}-mac (`{{SLACK_ID_GITOPS}}`, bot username `@dalinarmac6`) stopped responding in `#operacao` ({{SLACK_CHANNEL_TEAM_ID}}). Gateway showed `running`, `slack: connected`, Bolt app `⚡️ Bolt app is running!` — but zero `inbound message` entries in `gateway.log` since 08:41.

Verified: responding in `#roshar-sync` ({{SLACK_CHANNEL_WAR_ROOM_ID}}) but not `#operacao`. This meant the WebSocket WAS working — the issue was timing (mentions happened during disconnect windows) combined with app_token invalidity.

## Root Cause Timeline

1. **Pre-08:41** — Gateway working. Last inbound: {{COMMANDER}} mentioning `<@{{SLACK_ID_ORCHESTRATOR}}>`.
2. **08:41–10:24** — WebSocket connected but zero events. Cause: `SLACK_APP_TOKEN` (xapp-) was invalid. `err.log` showed `apps.connections.open → invalid_auth`. Bot_token (xoxb-) was valid (`auth.test` passed).
3. **09:44–10:24** — Multiple restarts (PID changes: 28739→31129→31500→32361→32816) but same app_token — all failed.
4. **10:24** — {{COMMANDER}} regenerated app_token in Slack dashboard. Updated `.env`. Gateway restarted.
5. **10:26** — First inbound message received: {{COMMANDER}}'s "teste" in `#roshar-sync` ({{SLACK_CHANNEL_WAR_ROOM_ID}}). 
6. **10:27** — Inbound from `#operacao` ({{SLACK_CHANNEL_TEAM_ID}}) confirmed. Gateway fully operational.
7. **10:28** — Response sent: 734 chars, 3 API calls, 45.8s processing time.

## Secondary Issues Found and Fixed

### Wrong `terminal.cwd` in config.yaml
```yaml
# Wrong:
cwd: /Users/{{COMMANDER}}fae/projects/obsidian  # DOES NOT EXIST
# Fixed:
cwd: /Users/{{COMMANDER}}fae/Dev/obsidian
```
Caused `cd: /Users/{{COMMANDER}}fae/projects/obsidian: No such file or directory` errors in `err.log`.

### Wrong path in instructions
```yaml
# Wrong (Linux/OVH path):
- Executo: cd {{COMMANDER_HOME}}/projects/obsidian
# Fixed:
- Executo: cd /Users/{{COMMANDER}}fae/Dev/obsidian
```

### Channel directory count anomaly
After reinstall: `Channel directory built: 2 target(s)` (was 5). This was a red herring — the bot was still in both `#operacao` and `#roshar-sync`. The count drop was coincidental.

## Key Diagnostic Signal Missed

The `auth.test` API only validates the **bot_token** (xoxb-). It returns `ok:true` even when the **app_token** (xapp-) is invalid. The app_token failure only appears in `err.log` as:
```
ERROR slack_bolt.AsyncApp: Failed to retrieve WSS URL: 
apps.connections.open → invalid_auth
```

**Lesson:** `auth.test` is NOT sufficient to validate Socket Mode. Always check `err.log` for `invalid_auth` on `apps.connections.open` when a gateway connects but receives zero events.

## Successful Fix Sequence

1. Fix `terminal.cwd` path in `config.yaml`
2. Fix instruction paths in `config.yaml`
3. Kill gateway, clear `state.db` and `sessions/`
4. Regenerate `SLACK_APP_TOKEN` in Slack dashboard
5. Update `.env` with new app_token
6. Restart gateway (launchctl KeepAlive auto-restarts)
7. Test with FRESH mention (pre-restart mentions are lost)

## Verification Commands

```bash
# Check for app_token errors
grep "invalid_auth" ~/.hermes/profiles/<agent>/logs/err.log

# Verify bot_token (does NOT verify app_token)
TOKEN=$(grep "^SLACK_BOT_TOKEN=" .env | cut -d= -f2)
curl -s -H "Authorization: Bearer $TOKEN" -X POST https://slack.com/api/auth.test

# Check which channels the bot is in
TOKEN=$(grep "^SLACK_BOT_TOKEN=" .env | cut -d= -f2)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://slack.com/api/users.conversations?types=public_channel,private_channel"
```

## Time to Resolution
~1h45m from first symptom (08:41) to full resolution (10:27). Most of the delay was due to:
- Misdiagnosing as `require_mention` filter issue (it wasn't)
- Misdiagnosing as event subscription issue (it wasn't)
- The `auth.test` false positive (bot_token OK ≠ app_token OK)
- Multiple unnecessary restarts with same broken app_token
