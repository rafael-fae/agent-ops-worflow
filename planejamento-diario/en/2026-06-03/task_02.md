# Task 02 — Map scripts, templates, assets → files/

**Wave:** 1 (Mapping)
**Priority:** 🔴
**Tool:** Gemini CLI
**Depends on:** —

---

## Context

Besides skills, we have automation scripts, document templates, and visual
assets scattered across skills. We need to copy everything to `files/` for
later sanitization.

---

## Instructions

### 1. Scripts

Copy all scripts found in skills to:
```
agent-ops-workflow/files/scripts/raw/
```

Possible sources:
- `~/.hermes/profiles/dalinar/skills/*/scripts/*`
- `~/.hermes/profiles/dalinar/scripts/*` (if it exists)

### 2. Templates

Copy all templates found in skills to:
```
agent-ops-workflow/files/templates/raw/
```

Sources:
- `~/.hermes/profiles/dalinar/skills/*/templates/*`

### 3. Assets

Copy assets (CSS, HTML, images) if any exist in skills to:
```
agent-ops-workflow/files/assets/raw/
```

### 4. Master Manifest

Create `files/MANIFEST-GERAL.md` with:

```markdown
# Master Manifest — agent-ops-workflow

## Scripts found
| # | Name | Origin | Type | Description |
|---|------|--------|------|-----------|
| 1 | rotate-key.sh | skill/planejamento-diario | Shell | SSH key rotation |

## Templates found
| # | Name | Origin | Description |
|---|------|--------|-----------|
| 1 | PLAN.md | skill/planejamento-diario | Daily plan template |

## Assets found
| # | Name | Origin | Type |
|---|------|--------|------|
...
```

---

## Checklist

- [x] Scripts copied to files/scripts/raw/
- [x] Templates copied to files/templates/raw/
- [x] Assets copied to files/assets/raw/
- [x] MANIFEST-GERAL.md created with inventory
- [x] NO original files modified

---

## Constraints

- NEVER modify original files
- Copy + inventory only — no editing

---

## Conclusion

**Agent:** Dalinar (via subagents)
**Completed on:** 06/03/2026 ~10:00
**Engine used:** Gemini CLI + deepseek-v4-flash (subagents)
**Notes:**
- Scripts: 4 found (3 .sh, 1 .py) — rotate-key, hermes-agent, and others
- Templates: 8 found (PLAN.md, TEMPLATE_TASK.md, etc.)
- References: 108 files (107 .md + 1 .json) from various skills
- Assets: 0 — no skill has an assets/ folder
- MANIFEST-GERAL.md created in files/MANIFEST-GERAL.md with complete inventory
- 2 name conflicts resolved: docker-pitfalls.md and ovh-security-hardening.md (prefixed with source skill)
