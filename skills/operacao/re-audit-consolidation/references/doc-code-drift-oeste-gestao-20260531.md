# Documentation vs Code Drift — {{PROJECT_NAME}} (31/05/2026)

## Context
After the Opus reescrita wave (8 gaps, 5,771 lines), {{ORCHESTRATOR}} ran a **retomada** cron at 05:30 to plan the next phase. The goal was planning for G08/G09 extraction + cross-audit.

## What Happened

Two subagents were delegated in parallel via `delegate_task`:
- **{{BACKEND_ENGINEER}}** → extraction plan for G08/G09 → `PLANO-EXTRACAO-G08-G09.md` (679 lines)
- **{{AUDITOR}}** → cross-audit of documentation vs gaps vs code → `AUDITORIA-PRIORIZACAO-CRUZADA.md` (369 lines)

## Key Discovery: 35% Documentation Staleness

The {{AUDITOR}} subagent cross-referenced ALL docs/refinamentos/ documents against the actual code on the `wave/2026-05-31-opus-gaps` branch and found:

| Document | Stale Claim | Reality | 
|----------|-------------|---------|
| CONSOLIDADO-FINAL.md | PgBouncer "não configurado" | ✅ Já no docker-compose.yml |
| PROGRESSO-2345.md | Event Bus "não implementado" | ✅ apps/core/eventbus.py (294L) |
| CRUZAMENTO-GAPS.md | "Django migrations ausentes" | ✅ Migrações criadas |
| AUDITORIA-FINAL-{{AUDITOR_UPPER}}.md | G08 "não wire-upados" | ✅ Corrigido por {{BACKEND_ENGINEER}} |
| AUDITORIA-FINAL-{{AUDITOR_UPPER}}.md | FIELD_ENCRYPTION_KEY "sem ponte" | ✅ Já em settings.py |
| CONSOLIDADO-FINAL.md | Logger "ausente do settings.py" | ✅ Configurado |

**Root cause:** A single {{BACKEND_ENGINEER}} correction session (31/05 00:50-01:10, 8 fixes in ~20 min) had silently updated the codebase but the planning documents were never refreshed.

## Real Bugs Found (No Document Had Claimed)

1. **`_register_invalidation_key()` undefined** (cache.py:81) — code existed but called undefined method → AttributeError
2. **`CACHES` dict absent** from settings.py — LocMemCache implicit, cache doesn't persist across workers
3. **Cache invalidation pattern broken** — searched for `*{user_id}*` but keys are MD5 → no-op

## Process Used

1. Compiled inventory of all claims from 6 planning documents
2. For each claim, ran verification commands (ls, grep, wc -l)
3. Built discrepancy table (doc claim vs code reality vs severity)
4. Split into: stale claims (verified fixed) + verified claims (still actionable) + new findings
5. Produced prioritized 3-tier action plan (Tier 1: 5 critical items, ~2h)

## What We Learned

- Documentation decays fast — a single 20-min correction session made 35% of claims stale
- Cross-audit must be **bidirectional**: don't just check doc claims against code, but also check code for bugs no document mentioned
- The "consolidated final" document should include a timestamp of last code verification, not just last document edit
- Verified claims (where doc and code agree on a problem) are actually harder to find than stale claims — most energy went to disproving stale claims, not finding new bugs
