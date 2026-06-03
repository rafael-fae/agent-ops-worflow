# Task 10 — Publish to GitHub + consolidated final audit

**Wave:** 4 (Finalization)
**Priority:** 🟢
**Tool:** Gemini CLI
**Depends on:** task_09

---

## Context

Repository is ready locally. Now we will publish to GitHub and perform
the final audit of the entire project — ensuring everything is correct,
documented, and functional.

---

## Instructions

### 1. Create repository on GitHub

Use `gh` CLI (if available) or manual instructions:

```bash
# If gh is configured:
gh repo create agent-ops-workflow --public --description \
  "Multi-agent daily planning system for Hermes — markdown, Slack, skills and scripts"

# Push
git remote add origin git@github.com:YOUR_USER/agent-ops-workflow.git
git branch -M main
git push -u origin main
```

### 2. Configure repository on GitHub

- Topics: `hermes-agent`, `hermes-workflow`, `multi-agent`, `ai-agents`, `workflow`, `planejamento`
- Website: (if any)
- Description: filled
- Releases: create initial v1.0.0

### 3. Final quality audit

Verify point by point:

**Sanitization:**
- [ ] No file contains "Roshar", "Rafael", "Oeste Gestão", "Dalinar", etc.
- [ ] All placeholders use consistent format
- [ ] Header comments present in sanitized skills

**Documentation:**
- [ ] README.md complete with functional quickstart
- [ ] All 6 docs/ are filled
- [ ] Cross-links work
- [ ] docs/06-QUICK-REFERENCE.md is actually 1 page

**Templates:**
- [ ] PLAN.md.tpl functional (someone can fill it)
- [ ] TASK.md.tpl functional
- [ ] INDEX.md.tpl functional

**Scripts:**
- [ ] setup-workflow.sh executable (`chmod +x`)
- [ ] gerar-plano-diario.sh executable
- [ ] validate-workflow.sh executable
- [ ] rotate-key.sh executable

**Repository:**
- [ ] .gitignore correct
- [ ] files/ is not being tracked
- [ ] LICENSE present (MIT)
- [ ] Clean structure

**Our own planning:**
- [ ] INDEX.md updated with commits and status
- [ ] All task_XX.md with filled checkboxes
- [ ] Conclusion filled in completed tasks
- [ ] PLAN.md updated with final statuses

### 4. Consolidated report

Produce in terminal:

```markdown
# Final Audit — agent-ops-workflow v1.0.0

## Items verified: 25/25 ✅

## Structure
- skills/: X sanitized skills
- docs/: 6 documents
- templates/: 4 templates
- scripts/: 4 scripts + README

## Verdict
✅ Repository ready for publication.
```

---

## Checklist

- [ ] Repository created on GitHub (public)
- [ ] Push successful
- [ ] Topics and description configured
- [ ] Sanitization audit: 0 original terms found
- [ ] Docs audit: 6/6 documents complete
- [ ] Scripts audit: all tested
- [ ] Planning-diary finalized and committed
- [ ] Release v1.0.0 created
- [ ] Link sent to Rafael

---

## Constraints

- PUBLIC repository — no sensitive data
- NO credentials or data from the original project

---

## Conclusion

`TBD`
