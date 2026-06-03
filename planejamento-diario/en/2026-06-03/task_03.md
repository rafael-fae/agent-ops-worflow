# Task 03 — Sanitize skills — remove specific references

**Wave:** 2 (Sanitization)
**Priority:** 🔴
**Tool:** Gemini CLI
**Depends on:** task_01

---

## Context

The skills copied into `files/skills/raw/` contain references to the **Roshar** team
(Dalinar, Navani, Kaladin, Shallan, Jasnah, Pattern), the **Oeste Gestão** project,
and **Rafael**. We need to create sanitized versions in `files/skills/sanitized/`.

---

## Instructions

### 1. Create output directory

```
mkdir -p agent-ops-workflow/files/skills/sanitized/
```

### 2. For each skill in raw/, create a sanitized copy in sanitized/

Mandatory replacements:

| Original term | Replace with |
|---------------|--------------|
| Roshar | {{TEAM_NAME}} |
| Dalinar | {{ORCHESTRATOR}} |
| Navani | {{BACKEND_ENGINEER}} |
| Kaladin | {{DEVOPS_ENGINEER}} |
| Shallan | {{FRONTEND_ENGINEER}} |
| Jasnah | {{AUDITOR}} |
| Pattern | {{GIT_OPS}} |
| Oeste Gestão | {{PROJECT_NAME}} |
| Rafael | {{COMMANDER}} |
| Rafael Fae | {{COMMANDER_NAME}} |
| oeste-gestao | {{PROJECT_SLUG}} |
| ~/Dev/oeste-gestao | {{PROJECT_PATH}} |
| pycode.rafaelfae.com.br | {{BLOG_URL}} |
| rafael@... (emails) | {{CONTACT_EMAIL}} |
| BBmqCzkuy72YHkb!pr4g | {{DONTUS_PASSWORD}} |
| 230257 | {{DONTUS_CLINICA_ID}} |
| U0B7EHB5VJL and other IDs | {{SLACK_ID_ORCHESTRATOR}} etc. |
| C0B6DUQGJSX | {{SLACK_CHANNEL_MAC}} |
| #operacao-mac | {{SLACK_CHANNEL_TEAM}} |
| #sala-de-guerra | {{SLACK_CHANNEL_WAR_ROOM}} |

### 3. Sanitization rules

- Preserve document structure and logic
- Placeholders use `{{NAME}}` (Mustache/django template format)
- Include a comment at the top of each file:
  ```markdown
  <!--
  File sanitized for agent-ops-workflow.
  Replace the {{...}} placeholders with your team's values.
  See docs/SETUP.md for instructions.
  -->
  ```
- Do NOT translate content (keep pt-BR)
- Do NOT modify skill structure

### 4. Verification

At the end, verify no original terms remain:
```
grep -rn "Roshar\|Rafael\|Dalinar\|Navani\|Kaladin\|Shallan\|Jasnah\|Pattern\|Oeste Gestão\|oeste-gestao" \
  agent-ops-workflow/files/skills/sanitized/ || echo "OK — no original terms found"
```

---

## Checklist

- [x] sanitized/ directory created
- [x] Each skill raw/ → sanitized/ with substitutions
- [x] Placeholders use consistent {{NAME}} format
- [x] Header comment added to each file
- [x] grep verification found no original terms
- [x] SANITIZING-REPORT.md created

---

## Constraints

- Do NOT modify raw/ — raw is the immutable original source
- Do NOT translate content
- Do NOT invent placeholders — use only those listed

---

## Relevant files

- files/skills/raw/* → source
- files/skills/sanitized/* → destination

---

## Conclusion

**Agent:** Dalinar (via subagents)
**Completed on:** 06/03/2026 ~10:30
**Engine used:** deepseek-v4-flash (subagent)
**Notes:**
- 142 of 163 files modified (binary/raw files were only copied)
- 10 skill categories processed (5 devops, 29 operacao, 2 security, 7 standalone)
- 35 replacement rules applied (including ALL CAPS and lowercase variations)
- {{...}} placeholders added to all files
- Header comment inserted in all 43 SKILL.md files
- SANITIZING-REPORT.md created in files/skills/SANITIZING-REPORT.md
- Verification: 0 original terms found ✅
