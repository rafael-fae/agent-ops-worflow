---
name: re-audit-consolidation
description: >
  Multi-agent audit consolidation for reverse engineering projects.
  After the discovery phase, deploy 3+ independent auditors to assess
  coverage across different lenses (schema, UI, business logic, APIs).
  Each produces honest numbers independently. Then reconcile discrepancies
  into a unified coverage report with clear go/no-go recommendation.
tags:
  - reverse-engineering
  - audit
  - coverage
  - consolidation
  - decision-gate
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Multi-Agent Audit Consolidation for Reverse Engineering

## When to Use

After the discovery/mapeamento phase of a large reverse engineering project, when you need an honest assessment of coverage completeness before transitioning to architecture/implementation.

## The Problem

Single-agent coverage estimates are unreliable. The person doing the work tends to inflate numbers (100% feels good) or underestimate (impostor syndrome). The decision-maker (user/Comandante) needs an **honest, defensible** assessment.

## The Solution: 3 Independent Auditors

### Roles

| Auditor | Lens | Focus |
|---------|------|-------|
| **{{AUDITOR}}** (Strategic) | **Dashboard coverage** | Broad view: how many modules at what %? High-level trends. Tends to be most optimistic (90%). |
| **{{BACKEND_ENGINEER}}** (Technical) | **Data depth** | Schema completeness, API endpoints, state machines, field-level coverage. Tends to be most conservative (85%). |
| **{{FRONTEND_ENGINEER}}** (Functional/UI) | **Business logic + UI** | How much of the *functionality* do we understand? Component coverage, validation rules, UX patterns. Tends to be moderate (75%). |

### Variant: Two-Track Parallel Audit (Validate + Discover)

In the planning/gating phase, when the work product includes both **deep-dives** (existing analysis to validate) and **open questions** (gaps to discover), use a two-track approach:

| Track | Agent | Focus | Output |
|-------|-------|-------|--------|
| **Track A — Validation** | {{BACKEND_ENGINEER}} (or technical lead) | Review deep-dives, architecture blueprint, and implementation plan for correctness & consistency. | Validation report with ✅/⚠️/❌ per artifact + residual gaps. |
| **Track B — Discovery** | Claude Opus (or subagent) | Feed ALL planning documents to Opus with explicit instruction to find gaps NOT covered by existing deep-dives. | Gap audit with numbered items, severity, location, recommendation, effort. |

**Process:**
1. Deploy both tracks in parallel (they don't need each other's output)
2. When both return, consolidate into a single unified report
3. Note where findings overlap (cross-validation) and where they diverge (unique insights)
4. Present to decision-maker with clear verdict: go/no-go

This variant was proven effective in the {{PROJECT_NAME}} planning review (29/05/2026): {{BACKEND_ENGINEER}} validated 4 deep-dives + identified 7 residual gaps, while an Opus review found 20 additional gaps (3 critical). The overlapping finding on Migration ETL and NFSe complexity gave high confidence those were real risks.

**When to use Two-Track over 3-Auditor:**
- When you're past the RE phase and have already produced deep-dives/blueprints
- When the decision is about "ready to implement?" rather than "more discovery needed?"
- When you need both validation of existing work AND discovery of new gaps

**Fallback when Opus rate-limited:** If Claude API rate limit is hit (resets midday BRT), the Discovery Track subagent can perform the analysis **directly** by reading all documents itself — the subagent processes the full corpus and produces the same structured gap report. This was tested successfully with 7,443 lines across 7 documents.

### Process

#### Step 1 — Define scope boundaries
Be explicit about what you're measuring:
- What counts as a "module"?
- What does "% coverage" mean (visual? fields? rules? APIs?)
- What is explicitly OUT of scope?

#### Step 2 — Deploy independent auditors
Each agent receives:
```
[AUDIT_TASK]
You are auditing the [LENS] of our reverse engineering of [SYSTEM].
Your job: be HONEST, not optimistic. Identify gaps. Count rigorously.
Produce a report with:
1. Coverage % per module with breakdown
2. What you found that's new
3. What you know we still don't know
4. A clear recommendation: sufficient or need more waves?
```

**Critical instruction:** Tell each agent to be independent and honest. "Do not inflate numbers. The comandante values honesty over optimism."

#### Step 3 — Let them deliver independently
Wait for all 3 reports. Do NOT reconcile them yourself before they deliver — the discrepancies are valuable information.

#### Step 4 — Consolidate
Create a consolidated report with:

1. **Three columns side-by-side** showing what each auditor said
2. **The real consensus range** (e.g., "85-90%")
3. **Discrepancies explained** (why {{AUDITOR}} said 90% and {{BACKEND_ENGINEER}} said 85%)
4. **Lacunas reais vs percebidas** table — what we actually don't know vs what we resolved
5. **Recommendation** — only if all 3 independently agree

### Step 4b — Implementation Drift Detection (Code-vs-Blueprint)

When the audit scope includes **implementation code** (not just RE documentation), add this cross-reference step after consolidating auditor reports:

> ⚠️ **Multi-wave attention:** If this is Wave N of a multi-wave audit cycle, ALWAYS re-verify the previous wave's claims against the actual filesystem — not against the previous wave's report. Document-vs-code staleness compounds across waves; a claim that was true when Wave N wrote it may be stale by Wave N+1 if code was changed in between. The current session's 03:00 → 07:30 audit found 3 claims that were stale within 4 hours due to undocumented corrections applied between waves.

1. **Map blueprint promises to implementation reality.** For each planned module/entity in the blueprint or ETL plan, check if actual code exists:
   ```bash
   # Check if referenced target apps exist
   grep -r 'target_model' apps/*/management/commands/*.py | grep -oP "'[^']+\\.[^']+'" | sort -u
   ```

2. **Cross-reference field names.** Migration code maps source columns to model fields. Verify each mapped field actually exists on the target model:
   ```bash
   # Extract field names referenced in migration code
   grep -oP '"[^"]+"\s*:\s*"[^"]+"' apps/*/management/commands/migrate_*.py | sort -u
   # Cross-reference with actual model fields
   python3 -c "
   from apps.core.models import Paciente
   actual = {f.name for f in Paciente._meta.fields}
   mapped = {'dontus_id', 'migration_batch_id', 'nome', 'cpf'}
   missing = mapped - actual
   if missing: print(f'Fields missing from model: {missing}')
   "
   ```

3. **Quantify implementation drift.** Create a comparison table:
   | Entity | Blueprint/Planned | Implemented | Coverage |
   |--------|:-----------------:|:-----------:|:--------:|
   | Tables in whitelist | N planned | M implemented | ~X% |
   | Target models referenced | N | M exist, K missing | ~X% |
   | Field mappings | Full col-map | M of N cols | ~X% |

4. **Flag app label mismatches.** Migration code referencing `app_label.ModelName` when no such app exists is a **critical gap** — the command will fail at `apps.get_model()` before any SQL runs. Create a gap entry immediately.

This step detects **silent failures** — code that compiles but breaks at runtime because `apps.get_model()` raises `LookupError` for non-existent apps or models.

#### Step 5 — Present to decision-maker
Format:
```
## Options
| A | RE sufficient → proceed to architecture | 🟢 |
| B | Process remaining raw material | 🟡 |
| C | One more full extraction wave | 🔴 |

## My recommendation as [role]: Option X
## Why: [2-3 sentence justification]
## What we lose if wrong: [honest risk assessment]
```

#### Step 6 — Consolidate into Obsidian Vault (Segundo Cérebro)

After presenting to the decision-maker, ALL knowledge produced by the audit (reports, gap analyses, validation docs) must be **organized into the Obsidian vault** by {{GIT_OPS}}. This is the canonical knowledge store for cross-team reference:

1. Create structured folders under `10_Projects/{projeto}/` with sub-sections:
   - `02-Planejamento/` — plans, summaries, validation reports
   - `03-Arquitetura/` — blueprints, strategy docs
   - `04-Deep-Dives/` — technical deep-dive documents
   - `05-RE/` — reverse engineering final reports
2. Delegate to {{GIT_OPS}}-mac (`<@{{SLACK_ID_GITOPS}}>`) with explicit file list and target structure
3. {{GIT_OPS}} organizes, creates _index.md with [[links]], and registers the operation
4. {{GIT_OPS}} does NOT git push — presents diff for approval first
5. Knowledge is then available to BOTH Mac and OVH teams via vault sync

This is the default workflow — every audit cycle ends with organized knowledge in the vault.

## Example Output

From {{PROJECT_NAME}} RE audit (26/05/2026):
- {{AUDITOR}}: 90% (dashboard view)
- {{BACKEND_ENGINEER}}: 85% (data depth view)  
- {{FRONTEND_ENGINEER}}: 75% (functional view)
- **Consensus: 85-90% → SUFFICIENT**

All 3 independently said "parar extração, iniciar arquitetura."

## Pitfalls

1. **Don't inflate to please.** The user/Comandante will trust you MORE if you give honest numbers.
2. **Discrepancies are good.** They show real independent thinking. Explain why they differ.
3. **New modules discovered late** (like Auditoria, AssinaturaDontus) should be noted but not penalized — they're wins, not gaps.
4. **Unprocessed raw material** (e.g., 153 images without vision model) — be transparent about what's not analyzed.
5. **The "last 10%"** illusion — the final 10% takes as long as the first 90% in reverse engineering. Recognize diminishing returns.

## Follow-Up: Gemini Vault Fusion

After the multi-agent audit declares "RE sufficient", the natural next step is the **Gemini Vault Fusion** strategy:

1. Consolidate entire vault into single file
2. Feed to Gemini 3.1 Pro Preview for professional PRD/Blueprint generation
3. Cross-validate AI output vs human docs (what improved, what we lost)
4. **FUSE** both — AI structure (personas, journeys, criteria, metrics) + human depth (schemas, UX divergences, state machines, risks, waves) → v3.0 definitive documents

See skill `gemini-vault-fusion` for the complete methodology.

## Decision Rules

| All 3 say | Action |
|-----------|--------|
| "Sufficient" | ✅ Proceed with confidence |
| 2 say "sufficient", 1 says "1 more wave" | 🟡 Proceed but note the gap |
| 2 say "1 more wave" | 🔴 Do another wave |
| All 3 say "1 more wave" | 🛑 Stop. You've moved too fast. |

## Closing the Last 3-7% (Beyond Audit)

After the audit declares "sufficient but not 100%", execute a **systematic gap-closing campaign**:

### Step 1 — Concrete Gap Analysis

Identify exact missing coverage using two sources:
1. **Audit report** (AUDITORIA-GERAL.md) — which layers/cameras are below 100%
2. **Crawl residual report** (CRAWL-RESIDUAL.md) — which routes were not captured

### Step 2 — Priority-Based Wave Planning

| Priority | Routes | Purpose |
|----------|--------|---------|
| 🔴 High (Wave N) | Main gaps from audit (e.g., Auditoria, Financeiro edge cases) | +3-4% |
| 🟡 Medium (Wave N+1) | Uncaptured routes with functional impact (ContasPagar, CaixaDiario, Funcionario) | +2-3% |
| 🔵 Low (Wave N+2) | Remaining routes + 404 corrections + micro-interactions | +1-2% |
| ✅ Final | 404 corrections, empty/loading/error states | Final 1% |

### Step 3 — Deploy by Agent Specialty

| Agent | Specialty | Example Close |
|-------|-----------|---------------|
| **{{DEVOPS_ENGINEER}}** | Crawl + Infrastructure | Captures remaining routes, validates HTTP 200, configures git |
| **{{BACKEND_ENGINEER}}** | Finance + Integration + Business Rules | Deep RE on edge cases, 404 route corrections, integration docs |
| **{{FRONTEND_ENGINEER}}** | UI/UX + Visual {{GIT_OPS}}s | Micro-interactions, empty states, error states, loading patterns |
| **{{AUDITOR}}** | Consolidation + Blueprint | Reviews all deliveries, generates final 100% report, updates vault |

### Step 4 — Sanitize Before Git Push (⚠️ LGPD)

**Critical:** Raw captured data (HTML, JSON, screenshots) may contain **real patient PII** (names, phones, CPFs, addresses, treatment data). Before committing to version control:

| Safeguard | Why |
|-----------|-----|
| Add `biblia/`, `raw_data/`, `screenshots/` to `.gitignore` | These contain PII from the legacy system |
| Commit only `docs/` vault + reports + blueprints | Sanitized, structured knowledge |
| Keep raw data **locally on the server** | Available for team reference, not exposed on GitHub |
| Document the exclusion in `.gitignore` comments | Team knows why PII data is excluded |
| Do NOT assume — verify `.gitignore` before each push | Accidental PII exposure is a compliance violation |

### Step 5 — Generate the RELATORIO-100%.md

After all waves complete, the consolidation agent ({{AUDITOR}}) generates a **single authoritative document**:

```
docs/RELATORIO-100%.md
```

Structure:
1. **Resumo Executivo** — 3-line summary with final %
2. **Métricas Consolidadas** — table across ALL waves (pages, fields, KO bindings, endpoints, rules, modals, files)
3. **O Que Foi Descoberto** — key architectural findings (multi-tenant, stack decisions, app architecture)
4. **Entregas por Wave** — wave-by-wave table with agent, delivery, coverage
5. **Artefatos no GitHub** — where each deliverable lives
6. **Próximos Passos** — what comes next ({{COMMANDER}} reviews → sinal verde → implementação)

Then **present it directly to the Comandante** in the Slack channel. This is the final deliverable — no more waves unless ordered.

## Variant: Documentation vs Implementation Drift Audit (Planning Phase)

When the audit scope includes **both** existing documentation and implementation code, add a systematic cross-reference step that compares what docs claim vs what the code actually does.

### Trigger
- You have a `docs/refinamentos/` directory (or equivalent) with multiple planning/audit documents
- Code has been extracted from vault markdowns into actual source files
- You need to know if the planning docs are still accurate (before starting a new implementation wave)

### Process

**1. Compile the claim inventory.** Read all audit/planning documents and extract every specific claim about code state:
- "G08 middlewares não wire-upados" → check if settings.py MIDDLEWARE has them
- "PgBouncer não configurado" → check docker-compose.yml
- "Event Bus não implementado" → check if apps/core/eventbus.py exists
- Status flags (❌/⚠️/✅) per gap in consolidated documents

**2. Verify each claim against the actual filesystem.**
```bash
# Check if claimed-missing files exist
ls -la apps/core/middleware/cache.py 2>/dev/null && wc -l $_
# Check specific config entries
grep -n "CACHES" config/settings.py  # does the dict exist?
grep -n "HTMXPartialCacheMiddleware" config/settings.py  # is it registered?
# Check if claimed-missing features are actually present
grep -rn "transaction.on_commit" apps/core/ --include="*.py" | head -5
```

**3. Build a discrepancy table.** For each claim, record:
| # | Document | Claim | Reality | Severity |
|:-:|----------|-------|---------|----------|
| | CONSOLIDADO-FINAL.md | "PgBouncer não configurado" | ✅ Já no docker-compose | 🔴 (doc outdated) |

The severity here is about the **documentation gap** ({{COMMANDER}} relying on stale docs), not the code gap itself.

**4. Produce a unified picture.** Split findings into three buckets:
- **Stale claims** — doc says missing, code already has it (doc needs update)
- **Verified claims** — doc says missing, code really misses it (still actionable)
- **New findings** — bug found in code that no doc mentioned (e.g., `_register_invalidation_key` undefined despite the class existing)

### Example Output
From {{PROJECT_NAME}} (31/05/2026):
- 6 stale claims found across 4 documents (CONSOLIDADO-FINAL.md, PROGRESSO-2345.md, CRUZAMENTO-GAPS.md, AUDITORIA-FINAL-{{AUDITOR_UPPER}}.md)
- 2 verified bugs: `_register_invalidation_key` undefined, CACHES dict absent
- Documentation was ~35% outdated relative to code state
- Result: produced AUDITORIA-PRIORIZACAO-CRUZADA.md (369 lines) with 3-tier priority

Full session reference: `references/doc-code-drift-{{PROJECT_SLUG}}-20260531.md`

### Why This Matters
Documentation in active projects decays fast — a single {{BACKEND_ENGINEER}} correction session (8 fixes in ~20 min) can render half the audit claims stale. Running this cross-reference **before** starting implementation prevents:
- Wasted effort on already-fixed items
- False confidence ("doc says it's done!")
- Confusion when code compiles despite doc claiming blockers

## Pitfalls (from {{PROJECT_NAME}} 7-wave campaign)

1. **Don't ask questions that captured data can answer.** {{COMMANDER}}'s multi-tenant question was fully answerable from `DASHBOARD_src.json`. Searching data first preserves trust.
2. **PII is everywhere in RE.** HTML pages contain real patient data. Assume ALL raw captures have PII until proven otherwise.
3. **404s are often misspelled routes, not missing pages.** Cross-reference menu/sidebar HTML for correct route names before declaring them 404.
4. **Low-priority routes ≠ low complexity.** In the Oeste campaign, `/Financiamento` (104 KO) and `/CamposObrigatorios` (79 KO) were labeled "low priority" but had higher complexity than many medium-priority routes.
5. **Memorized protocols must be used, not just known.** The team was corrected multiple times on `<@USER_ID>` Slack mentions. Knowing the rule is useless without applying it.
6. **The "last 3%" takes N waves.** Each additional % requires exponentially more effort. Budget accordingly and communicate diminishing returns to the Comandante upfront.
7. **Migration code-model mismatch.** When auditing coverage of implementation code, ALWAYS cross-reference migration scripts against actual Django models. A migration that references `profissionais.Profissional` when only `core.Funcionario` exists will compile (Django check passes) but fail at runtime with `LookupError`. The same applies to field names: if the migration maps `dontus_id` but the model defines `id_dontus`, the INSERT fails. Run `apps.get_model()` validation explicitly to catch these.
8. **File content corruption from automated generation.** Generated documents may contain API error messages (rate limits, auth failures, timeout messages) instead of actual content — the tool appended the error to the intended output file. Always verify with `head -5` that the file starts with valid markdown/document headers, not just checking `wc -l` (which may be non-zero for error messages). This is especially critical for deep-dive documents generated by CLI tools (Claude Opus, Gemini) where rate-limit messages can silently overwrite the intended output.
9. **Coverage metric disambiguation.** "100% coverage" is meaningless without specifying WHAT the metric measures. Four different metrics collide in practice:
   - **Documentation coverage** — how much of the legacy system's behavior is reverse-engineered in the vault
   - **Model/entity coverage** — how many legacy tables have corresponding Django models
   - **ETL whitelist coverage** — how many legacy tables have migration entries in the ETL pipeline
   - **Migration readiness** — how many Django models have the required migration fields (dontus_id, migration_batch_id, updated_at)
   These can diverge dramatically: a project can have 100% documentation coverage but 0% migration readiness. Always clarify which metric a stakeholder is referencing, and when reporting, break out all four metrics explicitly with percentages.
10. **Multi-wave audit staleness.** When running successive audit waves (e.g., cron cycles every 4h), do NOT carry forward a previous wave's factual claims without re-verifying against the actual filesystem. The previous wave may have based findings on stale documentation, or undocumented code changes may have been applied between waves. In the {{PROJECT_NAME}} 03:00→07:30 audit cycle, 3 claims from the 03:00 wave (G08 "not extracted", G09 "not extracted", logger "missing") were already incorrect — code had been committed hours earlier. The 07:30 wave had to spend time correcting errors that should never have propagated. Solution: each audit wave re-verifies ALL status claims against the filesystem, not just the new ones.

11. **Gap inflation when discovery outpaces implementation.** When successive audit/planning waves run without code implementation between them, the total gap count inflates rapidly — each wave finds new gaps on top of unexecuted old ones. In the {{PROJECT_NAME}} cycle (31/05/2026), gap count grew from 13→18→27 across 3 waves with zero code changes between them. This creates a false sense of regression. Solution: after each wave, compute the **gap delta attributable to unexecuted prior-wave actions** vs genuinely new discoveries. Flag to the Comandante when implementation velocity is the bottleneck: "X of the Y new gaps were already planned in the previous wave's Tier 1 but unexecuted — the priority is implementation, not more discovery."

## Verification

Before presenting, verify:
- [ ] Schema/entities: 100% coverage of core models?
- [ ] State machines: all critical workflows documented?
- [ ] API endpoints: read coverage sufficient?
- [ ] UI components: enough to define component library?
- [ ] Architectural blueprint exists with key decisions?
- [ ] Multi-tenant model validated?
- [ ] All 3 auditors agreed independently?
- [ ] Migration/ETL code references existing apps and models? (`apps.get_model()` validation passes)
- [ ] Field names in migration code match actual model fields? (no `dontus_id` vs `id_dontus` mismatches)
- [ ] Generated deep-dive files have valid content, not API errors? (`head -5` check on each)
