# Quick Reference — Agent Ops Workflow

> One-page cheat sheet for the multi-agent daily planning workflow.
> See the full docs for details.

---

## Commands

| Action | Command |
|--------|---------|
| **Initialize** | `./scripts/setup-workflow.sh ~/project "Team Name" "Project Name"` |
| **Generate daily plan** | `./scripts/gerar-plano-diario.sh ~/project` |
| **Validate workflow** | `./scripts/validate-workflow.sh ~/project` |
| **Validate + auto-fix** | `./scripts/validate-workflow.sh ~/project --fix` |
| **Validate (verbose)** | `./scripts/validate-workflow.sh ~/project --verbose` |
| **Load skill (inspect)** | `hermes skill_view path/to/skill/SKILL.md` |
| **Load skill (activate)** | `hermes skill_manage add path/to/skill/SKILL.md` |
| **Cron schedule (5 AM)** | `0 5 * * * /path/gerar-plano-diario.sh ~/project >> ~/project/planejamento-diario/cron.log 2>&1` |

---

## Project Structure

```
project/
└── planejamento-diario/
    ├── INDICE.md              ← Master progress index (ALL days)
    ├── TEMPLATES/             ← Template files (don't edit directly)
    │   ├── PLANO.md           ← Copied from templates/PLANO.md.tpl
    │   ├── TASK.md            ← Copied from templates/TASK.md.tpl
    │   └── INDICE.md          ← Copied from templates/INDICE.md.tpl
    └── YYYY-MM-DD/            ← One directory per day
        ├── PLANO.md           ← Day's plan (waves, tasks, status)
        ├── task_01.md         ← Individual task brief + checklist
        ├── task_02.md
        └── ...
```

### Repository Layout (agent-ops-workflow/)

```
agent-ops-workflow/
├── planejamento-diario/    # Dogfooding — the workflow running on itself
├── templates/              # Source of truth: PLANO.md.tpl, TASK.md.tpl, INDICE.md.tpl
├── scripts/                # setup-workflow.sh, gerar-plano-diario.sh, validate-workflow.sh, rotate-key.sh
├── docs/                   # Full documentation (6 guides)
├── files/                  # Working area — NOT committed (.gitignored)
│   └── skills/
│       ├── raw/            # Original skills before sanitization
│       └── sanitized/      # Skills with placeholders for reuse
└── LICENSE                 # MIT
```

---

## The 6 Phases

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  PLAN    │ ──→ │ APPROVE  │ ──→ │ DELEGATE │
└──────────┘     └──────────┘     └──────────┘
                                         │
                                         ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│  REPORT  │ ←── │  AUDIT   │ ←── │ EXECUTE  │
└──────────┘     └──────────┘     └──────────┘
```

| Phase | What Happens |
|-------|-------------|
| **1. PLAN** | Orchestrator creates `PLANO.md` with waves, tasks, priorities, and dependencies. Creates `task_XX.md` files with briefings, checklists, and constraints. Updates `INDICE.md`. |
| **2. APPROVE** | Commander (human) reviews the plan, adjusts priorities, approves or rejects tasks. **Never implement without the green light.** |
| **3. DELEGATE** | Orchestrator sends tasks to agents via Slack — one task per `@mention` in one thread. Each message includes engine mandate, instructions, and constraints. |
| **4. EXECUTE** | Agent reads required docs, follows instructions, marks checkboxes, fills conclusion section, commits + pushes, reports in thread. |
| **5. AUDIT** | Orchestrator verifies commits (`git log`, `git show`), checks diffs, reads changed files. If approved: updates PLANO + INDICE and commits records. |
| **6. REPORT** | Orchestrator produces consolidated table, per-task verdict (✅/⚠️/❌), commits all records (PLANO.md, INDICE.md). |

---

## Golden Rules

1. **INDICE.md and PLANO.md** — Update IMMEDIATELY after each audited task.
   ⬜ left open = critical failure. Commit hash and 👁 required.

2. **PLANNING ≠ DELEGATION** — "Plan" means create .md files + update indices.
   "Delegate" means send on Slack. One does not imply the other.

3. **One task = one Slack thread** — All communication about a task goes in
   its original thread. No new threads for corrections, supplements, or
   re-audits.

4. **Default engine = Gemini 3.1 Pro** — Every coding task uses Gemini.
   If it fails (RESOURCE_EXHAUSTED, error), split into smaller subtasks.
   NEVER switch models. If still failing, STOP and report.

5. **Always commit + push before reporting** — If there is no commit hash,
   the task is not done.

6. **NEVER take corrective action without the Commander's green light.**
   Made a mistake? Report and WAIT. Do not delete, revert, or fix.

---

## Engine Hierarchy

| Priority | Engine | Usage |
|:--------:|--------|-------|
| **1 (DEFAULT)** | Gemini 3.1 Pro | ALL coding tasks |
| **2** | Opus 4.7 | UI/vision/design (Frontend Engineer), complex audits, cross-DB data migrations |
| **3** | OpenCode Go / GLM 5.1 | Quick tasks, exploration, file operations |
| — | DeepSeek V4 Pro | **PROHIBITED** without explicit Commander order |

> The engine in `task_XX.md` is NOT authoritative. Override to Gemini before
> delegating.

---

## Slack Protocol

| Rule | Description |
|------|-------------|
| **Mention format** | Always `<@USER_ID>` at the start of the message |
| **No tables in delegation** | Pipe characters break the mention parser |
| **One agent per mention** | Only the mentioned agent responds |
| **Silence rule** | If not mentioned, stay silent |
| **Lockdown** | "sinal vermelho" freezes all agents — no actions until lifted |

### Required Slack Scopes (Bot Token)

- `channels:history` — Read channel history
- `channels:read` — View channel info
- `chat:write` — Send messages
- `reactions:read` — Read reactions
- `users:read` — Read user info

---

## Task File Sections (task_XX.md)

Every task file must contain:

- **Leitura Obrigatoria (Required Reading)** — PRD sections, Blueprint sections, references
- **Checklist** — Numbered, binary items (done/not done)
- **Conclusao (Conclusion)** — Agent, Date, Engine, Commit hash, Observations
- **Restricoes (Constraints)** — Mandatory engine, forbidden modifications,
  never-do actions

---

## INDICE.md Format

```
## DD/MM/AAAA — COMPLETED/TOTAL

| Task | Description | Wave | ✅ | 👁 | Commit |
|------|-------------|:----:|---|---|--------|
| task_01 | Short description | 1 | ✅ | ✅ | abc1234 |
| task_02 | Short description | 2 | ⬜ | ⬜ | — |
```

**Legend:** ✅ = completed | 👁 = audited and approved | ⬜ = pending

---

## Workflow Files Reference

| File | Purpose |
|------|---------|
| `docs/setup.md` | Environment setup, prerequisites, first run |
| `docs/daily-cycle.md` | Step-by-step of the 6-phase cycle |
| `docs/slack-protocol.md` | Agent communication rules |
| `docs/04-SKILLS-GUIDE.md` | Full skill reference, creation, adaptation |
| `docs/05-CUSTOMIZATION.md` | Team setup, templates, engine config |
| `docs/best-practices.md` | Tips, pitfalls, conventions |

---

## Common Pitfalls

| Pitfall | Prevention |
|---------|-----------|
| Slack mention broken by tables | Never use `|` in delegation messages |
| Agent reports fake commit hash | Always verify with `git log --oneline` |
| Index not updated after audit | Update INDICE + PLANO immediately after each task |
| Wrong engine used | "ORDEM ABSOLUTA" + exact engine command in delegation |
| Delegation without authorization | Commander approval required before any Slack send |
| Thread broken (agent replies in channel) | Only the orchestrator posts outside threads |
| Empty checklists | Reinforce at delegation time — fill before reporting |
| Index counter wrong | Recalculate X/Y after every audited task |

---

## Quick Tips

- **Daily plan at 5 AM:** Cron `gerar-plano-diario.sh` for morning-ready plans
- **Skill placeholders use `{{ ... }}`** ; Template placeholders use `__ ... __`
- **`files/` is .gitignored** — it's a working area, never committed
- **Validate daily** before starting new tasks: `validate-workflow.sh`
- **Lockdown overrides everything** — even the golden rules

---

## License

MIT — Free to use, adapt, and share. See [LICENSE](../LICENSE) for details.

© 2026 — Agent Ops Workflow
