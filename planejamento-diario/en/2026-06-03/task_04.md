# Task 04 — Create generic templates (PLAN, TASK, INDEX .tpl)

**Wave:** 2 (Sanitization)
**Priority:** 🔴
**Tool:** Gemini CLI
**Depends on:** task_02

---

## Context

The current templates (PLAN.md, TASK.md, INDEX.md) are adapted to Oeste Gestão.
We need to create generic .tpl (template) versions that any team can use
by replacing placeholders.

---

## Instructions

Create the following templates in `agent-ops-workflow/templates/`:

### 1. `templates/PLAN.md.tpl`

Daily plan template with:
- Editable header (date, team name, commander)
- Project resources section (empty, to fill in)
- Waves section (Morning/Afternoon/Evening — editable)
- Task table per wave (Task, Agent, Engine, Priority, Status)
- Dependencies section (Mermaid diagram or list)
- Non-negotiable rules (generic)
- End-of-day checklist
- Target metrics (editable)

### 2. `templates/TASK.md.tpl`

Individual task template with:
- Header (Task ID, Wave, Priority, Depends on)
- Required Reading section (empty, to fill in)
- Context (explanation of why)
- Numbered instructions
- Template checklist
- Engine constraints
- Relevant files (editable table)
- Conclusion section (pre-formatted)

### 3. `templates/INDEX.md.tpl`

Index template with:
- Header with legend (✅ 👁 ⬜)
- Task table (Task, Description, Wave, ✅, 👁, Commit)
- Progress section per wave
- Update instructions

### 4. `templates/README-WORKFLOW.md.tpl`

README template for the user project's `planejamento-diario/` folder:
- Explanation of what the folder is
- How to use it
- Reference to full documentation

### Placeholder format

Use `__PLACEHOLDER__` (double underscore) for placeholders within the templates,
to differentiate from the `{{PLACEHOLDER}}` used in sanitized skills.

Example:
```markdown
# Daily Plan — __DATE__

**Approved by:** __COMMANDER__
```

---

## Checklist

- [x] PLAN.md.tpl created with all sections
- [x] TASK.md.tpl created with all fields
- [x] INDEX.md.tpl created with legend and table
- [x] README-WORKFLOW.md.tpl created
- [x] Placeholders use consistent __PLACEHOLDER__ format
- [x] Templates testable (someone can fill and use them)

---

## Constraints

- Do NOT copy specific Oeste Gestão content
- Keep explanatory comments in the template

---

## Conclusion

**Agent:** Dalinar (via subagents)
**Completed on:** 06/03/2026 ~10:30
**Engine used:** deepseek-v4-flash (subagent)
**Notes:**
- PLAN.md.tpl — 215 lines, ~70 placeholders, editable waves, dependencies, rules
- TASK.md.tpl — 251 lines, ~50 placeholders, complete sections
- INDEX.md.tpl — 147 lines, ~65 placeholders, auto-counter
- README-WORKFLOW.md.tpl — 202 lines, 11 placeholders, workflow overview
- All with __DOUBLE_UNDERSCORE__ placeholders and HTML comments
- Zero references to Roshar/Rafael/Oeste Gestão
- Based on real examples from planejamento-diario/
