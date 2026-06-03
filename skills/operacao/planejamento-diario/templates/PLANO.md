# Plano Diário — {DATA}

**Aprovado por:** {{COMMANDER}}  
**Waves:** {N} waves  
**Motores disponíveis:** Opus 4.7 (semanal), Gemini 3.1 Pro (diário), DeepSeek V4 Pro (autorizado)

---

## 📚 RECURSOS DO PROJETO (CONSULTA OBRIGATÓRIA)

| Recurso | Local | Tipo |
|---|---|---|
| PRD (5343 linhas) | `docs/PRD.md` | Especificação de produto |
| Blueprint | `docs/BLUEPRINT-ARQUITETURAL.md` | Arquitetura técnica |
| Checklist Sprint 1 | `docs/sprint1/S01-CHECKLIST.md` | 29 itens |
| Design System | `design_system/DESIGN-SYSTEM-OPUS-FINAL.md` (934 linhas) | Cânone visual Teal #0d9488 |
| Componentes Detalhados | `design_system/COMPONENTS-DETAILED.md` (4699 linhas) | 20 componentes |
| Fichas Técnicas | `docs/prd/modulos/` (24 arquivos) | Extração por módulo |
| Obsidian Vault | `~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/` (40 .md) | ⚠️ READ ONLY |
| Dontus Ao Vivo | `https://sistema.dontus.com.br` | Consulta visual |
| DontusClient | `{{OVH_SSH_COMMAND}}` → `/var/www/dontus_app/dontus/client.py` | API real |
| OVH Stack | `{{OVH_SSH_COMMAND}}` → `docker compose ps` | 4 serviços |
| Domínio Testes | `https://gestao.oesteodontologia.com.br` | Django admin |
| Credenciais Dontus | `docs/referencias/ACESSO-DONTUS.md` | {{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}} |

---

## Resumo

{Breve descrição do dia}

---

## Waves

### Wave 1 — Manhã 08:00 ({MOTOR})

| Task | Agente | Prioridade | Status |
|------|--------|:----------:|:------:|
| task_01 | {agente} | 🔴 | ⬜ |

### Wave 2 — Tarde 14:00 ({MOTOR})

| Task | Agente | Prioridade | Status |
|------|--------|:----------:|:------:|
| task_XX | {agente} | 🟡 | ⬜ |

### Wave 3 — Noite ({MOTOR})

| Task | Agente | Prioridade | Status |
|------|--------|:----------:|:------:|
| task_XX | {{FRONTEND_ENGINEER}} | 🔴 | ⬜ |

---

## ⚠️ REGRAS INEGOCIÁVEIS

1. Gemini CLI padrão. DeepSeek só autorizado. Opus 4.7 EXCLUSIVO {{FRONTEND_ENGINEER}}
2. Branch `develop`. `git checkout develop`. COMMIT + PUSH (hash)
3. Cada task = UMA thread Slack `{{SLACK_CHANNEL_TEAM}}`
4. Checkboxes + Conclusão ANTES de reportar
5. Leitura obrigatória: PRD + Blueprint antes de cada task
6. Consultar Dontus vivo + Obsidian + documentação
7. NUNCA modificar Dontus. NUNCA implementar sem sinal verde
8. CRIAR tasks ≠ DELEGAR tasks
9. INDICE.md: criar tasks ao planejar (✅ ⬜ | 👁 ⬜). Agente marca ✅, {{ORCHESTRATOR}} marca 👁 após auditoria.

---

## Ao final do dia

- [ ] INDICE.md atualizado com todas as tasks + commits
- [ ] OVH sincronizado (git pull + docker compose ps)
- [ ] Relatório consolidado no Slack
- [ ] PLANO.md marcado como concluído
