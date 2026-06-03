# AGENTS.md — Template for Two-Tier Architecture

This file goes in the **project root** (not inside `docs/`). It is the first thing agents see when accessing the repo. Copy and adapt to each project.

```markdown
---
title: Project Name — Rules for Hermes Agents
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [rules, governance, agents]
modulo: cross
estagio: final
---

# 🤖 Project Name — Rules for Hermes Agents

> **Purpose:** Establish documentation separation rules for Hermes agents.

---

## 1. Documentation Separation

| Layer | Path | Function | Rule |
|-------|------|----------|------|
| **📘 docs/** | `project-root/docs/` | **Active source of truth** | All planning, specs, ADRs, audits, infra go HERE. |
| **📓 obsidian/** | `~/Dev/obsidian/10_Projects/project-name/` | **Historical reference** | Consult for legacy reverse engineering only. **Forbidden to edit.** |

### Truth Hierarchy

```
obsidian/ (ideas, drafts, reverse engineering)
     │
     ▼  (when mature, migrate to docs/)
     │
docs/  (official, active, indexed)
     │
     ▼  (reference for implementation)
     │
code/ (apps, config, templates)
```

> 🔑 **Golden rule:** If an agent needs to document something new → write in `docs/`. If an agent needs historical context → read from `obsidian/`, but **never write there**.

## 2. New .md Document Rules

**Every new .md file** MUST:
1. ✅ Follow `docs/REGRAS-ORGANIZACAO.md` — frontmatter YAML, tags, module, stage
2. ✅ Be registered in `docs/INDEX.md` in the same commit
3. ✅ Contain at least 1 cross-link to another document in the repo
4. ✅ Be placed in the correct subdirectory within `docs/`

### Minimum Frontmatter

```yaml
---
title: Document Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]
modulo: G01 | G02 | ... | K4 | cross
estagio: rascunho | revisado | final
---
```

## 3. `docs/` Directory Structure

```
docs/
├── INDEX.md
├── REGRAS-ORGANIZACAO.md
├── adr/
├── infra/
├── architecture/
├── planejamento/
├── especificacao/
├── deep-dives/
├── refinamentos/
│   ├── INDEX-REFINAMENTOS.md
│   ├── auditorias/
│   ├── prompts/
│   └── revisoes/
└── vault/
    ├── INDEX-VAULT.md
    └── ...
```

## 4. Agent Workflow

### Consult historical context (obsidian/)
1. Read files directly from `~/Dev/obsidian/10_Projects/project-name/`
2. **Never** create, edit, or move files inside obsidian/

### Create new docs (docs/)
1. Identify correct subdirectory in `docs/`
2. Create .md with full frontmatter YAML
3. Add entry in `docs/INDEX.md`
4. Add cross-links and verify they work

### Modify existing docs
1. Update `updated` in frontmatter YAML
2. If moving directories, update all indexes and cross-links
3. Never leave orphan .md files (no entry in any index)

## 5. Pre-Commit Checklist for Agents

- [ ] Frontmatter YAML present with `tags`, `modulo`, `estagio`
- [ ] Document registered in `docs/INDEX.md`
- [ ] Registered in specific indexes if applicable
- [ ] At least 1 cross-link to another repo document
- [ ] Links working (relative paths correct)
- [ ] `updated` date updated (if modifying existing)
- [ ] No files accidentally deleted
- [ ] Document in appropriate subdirectory

## 6. Related Documents

- [`docs/REGRAS-ORGANIZACAO.md`](./docs/REGRAS-ORGANIZACAO.md)
- [`docs/INDEX.md`](./docs/INDEX.md)
- [`docs/LEGADO-<DOMAIN>-REFERENCIA.md`](./docs/LEGADO-<DOMAIN>-REFERENCIA.md) — Bridge to obsidian legacy
```
