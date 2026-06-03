# Task 11 — Docs: GitHub tokens for agents (pt-BR + en-US)

**Wave:** 4 (Finalization)
**Priority:** 🟢
**Tool:** Gemini CLI
**Depends on:** —

---

## Context

Each Hermes agent needs its own GitHub token to make commits
with proper attribution and granular permissions. We need to document
how to configure this for multi-agent teams.

---

## Instructions

1. Create `docs/08-TOKENS-AGENTES.md` (pt-BR) covering:
   - Why each agent needs its own token
   - Multi-agent team structure (6 roles: orchestrator, backend, frontend, devops, auditor, gitops)
   - Token types (fine-grained vs classic) and required permissions
   - Step-by-step fine-grained PAT creation
   - Hermes configuration (env var, netrc, credential helper, SSH)
   - Recommended approach for multi-agent teams
   - Security best practices
   - Troubleshooting
   - Complete example

2. Create `docs/en/08-AGENT-TOKENS.md` (en-US) — full translation

---

## Checklist

- [x] docs/08-TOKENS-AGENTES.md created (pt-BR)
- [x] docs/en/08-AGENT-TOKENS.md created (en-US)
- [x] Zero references to Roshar/Rafael/Oeste Gestão
- [x] README.md and README-en.md with updated links

---

## Conclusion

**Agent:** Dalinar (via subagent)
**Completed on:** 06/03/2026 ~12:00
**Engine used:** deepseek-v4-flash (subagent)
**Notes:**
- docs/08-TOKENS-AGENTES.md — 729 lines, complete guide in pt-BR
- docs/en/08-AGENT-TOKENS.md — 730 lines, English version
- Covers 6 team roles, token creation, Hermes configuration, security
- Example with "Team Nova" and "nova-dev"
