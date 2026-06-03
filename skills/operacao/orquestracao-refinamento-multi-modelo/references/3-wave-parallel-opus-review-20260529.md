# 3-Wave Parallel Opus Review — {{PROJECT_NAME}} (29/05/2026)

## Context

After {{COMMANDER}}'s Mandato dos 3 Motores, 17 of 22 resolved gaps needed Opus CLI review because they were originally generated with `deepseek-v4-flash`. All agents (except {{AUDITOR}}) had `provider: opencode-go, default: deepseek-v4-flash` in their configs — they wrote `model: Opus 4.7` in frontmatter but content was processed by deepseek-v4-flash.

## Deployment {{GIT_OPS}}

Three waves deployed in parallel after {{COMMANDER}}'s signal. Each agent reviewed their own or delegated gaps:

| Wave | Reviewer | Gaps | Source Agent | Result |
|:----:|:--------:|------|:------------:|--------|
| 1 | {{BACKEND_ENGINEER}}-mac | K3, G02, G06 | {{BACKEND_ENGINEER}} (self) | All 3 REPROVADO (11 critical) |
| 2 | {{FRONTEND_ENGINEER}}-mac | G10, G13 | {{FRONTEND_ENGINEER}} (self) | Passed with corrections (7/10, 7.5/10) |
| 3 | {{AUDITOR}}-mac | K2, K1, G03, G05, G11, K4, G08, G09 | {{DEVOPS_ENGINEER}} | 43 issues in 6 gaps; 2 already Opus |

## Key Operational Details

### Command {{GIT_OPS}} (all agents)
```bash
cat prompt_revisao.md | ~/.local/bin/claude --print --dangerously-skip-permissions --effort max
```

### Verification Protocol
After each agent reported completion, {{ORCHESTRATOR}} verified:
1. Files exist on disk (`search_files` or `ls`)
2. File sizes non-zero (`wc -c`)
3. Frontmatter accuracy (model, reviewed_by fields)
4. Timestamps consistent with claimed execution

### Coordination Challenges
1. **Agent confusion about wave assignments** — {{BACKEND_ENGINEER}} confirmed Onda 3 three times when assigned Onda 1. {{AUDITOR}} confirmed Ondas 1+2 when assigned Onda 3. Required explicit correction with `<@USER_ID>` mentions each time.
2. **{{AUDITOR}} claimed pre-completion** — said Onda 3 was done "at 14:05" before signal was given. Files were verified to exist, but timing was suspicious.
3. **{{FRONTEND_ENGINEER}}'s first report was terse** — required file verification before acceptance.

## Results

**Total: 13 gaps reviewed with Opus CLI real.**
- 9 gaps with issues (54 total: 11 critical, 13 high, 30 medium/low)
- 4 gaps OK (2 {{FRONTEND_ENGINEER}}'s corrected, 2 {{AUDITOR}}'s already Opus)

**Key finding:** 100% failure rate for deepseek-v4-flash-generated code. Validates {{COMMANDER}}'s ban.

## Lessons for Future Parallel Reviews

1. **Assign each agent their OWN gaps where possible** — they know the context best
2. **{{AUDITOR}} for cross-agent review** — only agent proven to use Opus CLI correctly before the session
3. **Explicit gap lists in confirmation** — agent must confirm with exact gap IDs, not just "Onda X"
4. **Verify files before accepting reports** — `wc -c` + `head` checks prevent hallucination acceptance
5. **Don't proceed to signal until ALL agents confirm correct assignment**
