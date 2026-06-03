# Task 11 — Docs: tokens GitHub para agentes (pt-BR + en-US)

**Wave:** 4 (Finalização)
**Prioridade:** 🟢
**Ferramenta:** Gemini CLI
**Depende de:** —

---

## Contexto

Cada agente Hermes precisa de seu próprio token GitHub para fazer commits
com atribuição correta e permissões granulares. Precisamos documentar
como configurar isso para equipes multi-agente.

---

## Instruções

1. Criar `docs/08-TOKENS-AGENTES.md` (pt-BR) cobrindo:
   - Por que cada agente precisa de seu próprio token
   - Estrutura de equipe multi-agente (6 papéis: orquestrador, backend, frontend, devops, auditor, gitops)
   - Tipos de token (fine-grained vs classic) e permissões necessárias
   - Passo a passo de criação de fine-grained PAT
   - Configuração no Hermes (env var, netrc, credential helper, SSH)
   - Abordagem recomendada para equipes multi-agente
   - Boas práticas de segurança
   - Troubleshooting
   - Exemplo completo

2. Criar `docs/en/08-AGENT-TOKENS.md` (en-US) — tradução completa

---

## Checklist

- [x] docs/08-TOKENS-AGENTES.md criado (pt-BR)
- [x] docs/en/08-AGENT-TOKENS.md criado (en-US)
- [x] Zero referências a Roshar/Rafael/Oeste Gestão
- [x] README.md e README-en.md com links atualizados

---

## Conclusão

**Agente:** Dalinar (via subagente)
**Concluída em:** 03/06/2026 ~12:00
**Motor utilizado:** deepseek-v4-flash (subagente)
**Observações:**
- docs/08-TOKENS-AGENTES.md — 729 linhas, guia completo em pt-BR
- docs/en/08-AGENT-TOKENS.md — 730 linhas, versão em inglês
- Cobre 6 papéis de equipe, criação de tokens, configuração no Hermes, segurança
- Exemplo com "Team Nova" e "nova-dev"
