---
name: gemini-vault-fusion
description: >
  After completing reverse engineering vault, use a high-reasoning LLM
  (Gemini 3.1 Pro Preview or similar) to review all documentation, identify
  inconsistencies, generate a professional PRD/Blueprint structure, then
  FUSE the AI output with existing deep technical docs into a v3.0
  definitive document.
tags:
  - reverse-engineering
  - document-review
  - gemini
  - ai-assisted
  - fusion-strategy
  - prd
  - blueprint
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Gemini Vault Fusion — AI-Assisted Documentation Review & Consolidation

## When to Use

After completing a large reverse engineering vault (30+ documents, 20+ modules, ~200KB+), when you need to:

1. **Audit for inconsistencies** across documents
2. **Generate a professional-quality PRD/Blueprint** with personas, journeys, acceptance criteria, metrics
3. **Not lose technical depth** in the process

## The Problem

- **AI-only output** (feeding vault to Gemini and asking for PRD): produces professional structure but loses deep technical content — schemas get simplified, UX divergences disappear, state machines become generic, risks/implementation waves vanish.
- **Human-only docs**: have glorious technical depth (797-line schemas, 7 UX divergences, 4 state machines) but lack executive polish — no formal personas, no acceptance criteria section, no success metrics.

**The solution is not to choose. It's to FUSE.**

## The Fusion Strategy

### Phase 1 — Vault Consolidation

1. Gather ALL documentation files from the project
2. Consolidate into ONE file with clear source headers:
   ```markdown
   ## Fonte: docs/caminho/arquivo.md
   [full content of file]
   ```
3. Save to `/tmp/vault_completo.md`

### Phase 2 — AI Review (Gemini 3.1 Pro Preview)

Feed the consolidated vault to a high-reasoning model with a structured audit prompt:

```
Revise toda esta documentação de engenharia reversa do [SISTEMA].
Identifique:
1. Inconsistências entre documentos (com documento e linha)
2. Informações faltantes
3. Contradições
4. Sobreposições
5. No final: nota de 0-10 para completude e consistência
```

Save output as `docs/AUDITORIA-GEMINI-[MODELO].md`

### Phase 3 — AI Generation (Second Prompt)

```
Com base em toda esta documentação, produza:
1. PRD completo e profissional — visão geral, personas, funcionalidades,
   regras de negócio, jornadas de usuário, critérios de aceitação
2. Blueprint arquitetural — stack, schema, multi-tenancy, API design,
   UI architecture, infraestrutura
```

Save outputs as draft v2.0.

### Phase 4 — Human Cross-Validation

Deploy a dedicated auditor ({{AUDITOR}} role) to compare AI output vs existing docs:

| Aspect | AI v2.0 | Human v1.x | Veredict |
|--------|---------|------------|----------|
| Structure/Personas | ✅ Professional | ⚠️ Lacking | 🏆 **AI wins** |
| Deep schemas | ❌ 15 generic | ✅ 30+ detailed | 🏆 **Human wins** |
| UX divergences | ❌ Zero | ✅ 7 documented | 🏆 **Human wins** |
| State machines | ⚠️ Incomplete | ✅ Complete | 🏆 **Human wins** |

### Phase 5 — Fusion (v3.0)

**Strategy:** Use AI v2.0 as the **shell** (executive structure, personas, journeys, acceptance criteria, metrics), then **inject** the deep technical content from human v1.x (schemas, UX divergences, performance targets, state machines, risks, implementation waves).

Result: `PRD-v3.0.md` and `BLUEPRINT-v3.0.md` — professional AND implementable.

### Phase 6 — Fix Real Gaps Found

The AI audit will find real gaps. Fix them:

| Priority | Gap | Action |
|:--------:|-----|--------|
| 🔴 | Schema contradictions | Update source docs immediately |
| 🟡 | Architecture gaps (Docker networking, auth) | Document resolution |
| 🟢 | Bloated files | Clean up |

## ⚠️ Pitfalls

1. **Model names change fast.** Always verify available models via API before stating what exists. {{COMMANDER}} corrected us that Gemini 3.5 Flash and 3.1 Pro Preview existed when we thought they didn't.
   ```python
   from google import genai
   client = genai.Client(api_key=key)
   for m in client.models.list():
       print(f'{m.name}: {m.supported_actions}')
   ```
   Don't guess model names — check the API.

2. **AI loses technical depth.** The v2.0 will simplify schemas, drop UX divergences, and genericize risks. Plan the fusion BEFORE generating, not after.

3. **The shell is the easy part.** 80% of the v3.0 fusion effort is identifying what the AI dropped and re-injecting it. Budget time for this.

4. **Cross-validation is essential.** Never trust AI-generated documentation without a human auditor comparing it point-by-point against the originals.

5. **Context window management.** A vault of 193KB+ fits in Gemini 2M context, but the response may truncate. Split into chunks if needed, or use a model with large context (Gemini 3.1 Pro Preview = 2M tokens).

## Model Selection Guide

| For | Model | Why |
|-----|-------|-----|
| **Deep review + generation** | `gemini-3.1-pro-preview` | Best reasoning, 2M context, catches inconsistencies |
| **Fast iteration / re-generation** | `gemini-3.5-flash` | Faster, cheaper, still capable |
| **Vision (screenshots)** | `gemini-2.5-flash` (legacy) or Kimi K2.5 via opencode-go | For image analysis during RE |

## Example Output

This skill was developed and validated on the {{PROJECT_NAME}}/Dontus RE project:

- **Input:** 18 documents, 28 modules, 193KB vault
- **AI Model:** `gemini-3.1-pro-preview`
- **Audit found:** 5 real inconsistencies (Vue.js vs Alpine.js, FK direct vs N:N, Docker networking missing, auth cross-tenant undocumented, bloated cadastros doc)
- **Fusion result:** PRD v3.0 (7.7KB) + Blueprint v3.0 (7.2KB)
- **Time:** ~3 hours total (1h vault consolidation + 30min AI generation + 1h cross-validation + 30min fusion)

## Related Skills

- `re-audit-consolidation` — For the pre-fusion audit phase (multi-agent coverage assessment)
- `prd-clone-exhaustivo` — For the initial mapeamento/discovery phase
