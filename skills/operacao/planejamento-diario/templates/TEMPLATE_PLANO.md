# Plano Diário — {DATA}

**Aprovado por:** {{COMMANDER}}  
**Waves:** {N} waves  
**Motores disponíveis:** Gemini 3.1 Pro (padrão), DeepSeek V4 Pro (autorizado), Opus 4.7 (exclusivo {{FRONTEND_ENGINEER}})  
**Status:** {N}/18 concluídas

---

## 📚 RECURSOS DO PROJETO (CONSULTA OBRIGATÓRIA)

| Recurso | Local | Tipo |
|---|---|---|
| PRD | `docs/PRD.md` | Especificação de produto |
| Blueprint | `docs/BLUEPRINT-ARQUITETURAL.md` | Arquitetura técnica |
| Checklist Sprint 1 | `docs/sprint1/S01-CHECKLIST.md` | 29 itens |
| Design System | `design_system/` | Cânone visual Teal #0d9488 |
| Fichas Técnicas | `docs/prd/modulos/` (24 arquivos) | Extração por módulo |
| Obsidian Vault | `~/Dev/obsidian/10_Projects/{{PROJECT_SLUG}}/` | ⚠️ READ ONLY |
| Dontus Ao Vivo | `https://sistema.dontus.com.br` ({{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}}) | Consulta visual |
| DontusClient | `{{OVH_SSH_COMMAND}}` → `/var/www/dontus_app/dontus/client.py` | API real |
| OVH Stack | `{{OVH_SSH_COMMAND}}` → `{{PROJECT_PATH}}` | 4 serviços |
| Domínio Testes | `https://gestao.oesteodontologia.com.br` | Django admin |

---

## Resumo

{Breve descrição do dia}

---

## Waves

### Wave 1 — {HORÁRIO} ({MOTOR})

| Task | Agente | Motor | Prioridade | Status |
|------|--------|-------|:----------:|:------:|
| task_01 | {agente} | {motor} | 🔴 | ⬜ |

### Wave 2 — {HORÁRIO} ({MOTOR})

| Task | Agente | Motor | Prioridade | Status |
|------|--------|-------|:----------:|:------:|
| task_XX | {agente} | {motor} | 🔴 | ⬜ |

---

## ⚠️ REGRAS INEGOCIÁVEIS

1. Motor na delegação: "ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE [CLI]. NÃO usar outro. Se falhar, PARAR."
2. Branch `develop`. COMMIT + PUSH sem falta (hash no report)
3. Cada task = UMA thread. CRIAR tasks ≠ DELEGAR tasks
4. Checkboxes + Conclusão ANTES de reportar
5. Consultar Dontus vivo + Obsidian + docs
6. INDICE.md: atualizar ao criar tasks + preencher hash após auditoria
7. PLANO.md: manter status REAL-TIME
8. Memória 95%: reportar ao {{COMMANDER}} antes de modificar

---

## Ao final do dia

- [ ] Todas as tasks com checkboxes preenchidos
- [ ] INDICE.md atualizado com todos os commits
- [ ] PLANO.md com status final
- [ ] OVH sincronizado (git pull + docker compose ps)
- [ ] Relatório consolidado no Slack
