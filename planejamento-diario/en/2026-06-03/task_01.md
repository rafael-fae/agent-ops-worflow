# Task 01 — Map existing skills + copy to files/skills/raw/

**Wave:** 1 (Mapping)
**Priority:** 🔴
**Tool:** Gemini CLI
**Depends on:** —

---

## Context

We have Hermes skills stored in `~/.hermes/profiles/dalinar/skills/`. They contain
specific references to the Roshar team (Dalinar, Navani, Kaladin, etc.), the
Oeste Gestão project, and Rafael. We need to copy them into the `files/` folder to work
on sanitized versions without touching the originals.

---

## Instructions

1. List all available skills:
   ```
   ls -la ~/.hermes/profiles/dalinar/skills/*/
   ```

2. For each skill, copy the entire folder to:
   ```
   agent-ops-workflow/files/skills/raw/<SKILL-NAME>/
   ```
   Including SKILL.md, references/, templates/, scripts/, assets/

3. At the end, verify:
   ```
   tree agent-ops-workflow/files/skills/raw/ -L 3
   ```

4. Create a `MANIFEST.md` file in `files/skills/` listing:
   - Name of each skill
   - Category (operacao, devops, security)
   - Number of files
   - Notes (e.g., "contains refs to Oeste Gestão")

---

## Checklist

- [x] All skills listed and copied
- [x] Directory structure preserved (SKILL.md + subfolders)
- [x] MANIFEST.md created with complete inventory
- [x] NO original files were modified
- [x] Copied to agent-ops-workflow/files/skills/raw/

---

## Relevant files

| Origin | Destination |
|--------|---------|
| ~/.hermes/profiles/dalinar/skills/*/ | files/skills/raw/*/ |

---

## Constraints

- NEVER modify files in ~/.hermes/profiles/dalinar/skills/ (originals)
- Copy + listing only — no editing
- files/ will NOT be committed at the end

---

## Conclusion

**Agent:** Dalinar (via subagents)
**Completed on:** 06/03/2026 ~10:00
**Engine used:** Gemini CLI + deepseek-v4-flash (subagents)
**Notes:** 43 skills copied to files/skills/raw/ (163 files).
Categories: 5 devops, 29 operacao, 2 security, 7 standalone.
MANIFEST.md created with complete inventory of each skill.
.curator_state and .usage.json files were removed from destination (control metadata).
No original files were modified.
