# Task {XX} — {TÍTULO}

**Agente:** {agente}  
**Motor:** {motor}  
**⚠️ ORDEM ABSOLUTA:** Motor EXCLUSIVAMENTE {motor}. NÃO usar outro. Se falhar, PARAR e reportar.  
**Wave:** {wave}  
**Prioridade:** {prioridade}

---

## Leitura Obrigatória (ANTES de executar — 🔴 IGNORAR = ERRO)

1. `docs/PRD.md` — Seção {seção PRD relevante}
2. `docs/BLUEPRINT-ARQUITETURAL.md` — Seção {seção Blueprint relevante}
3. `docs/referencias/ACESSO-DONTUS.md` — Para consulta visual se necessário

---

## Motor

| Ordem | Especificação |
|---|---|
| 1. Gemini CLI | `gemini -m "gemini-3.1-pro-preview"` |
| 2. DeepSeek V4 Pro | SÓ com autorização explícita do {{COMMANDER}} |
| 3. Opus 4.7 | EXCLUSIVO {{FRONTEND_ENGINEER}} (design) |

---

## Contexto

{Breve contexto do que precisa ser feito e por quê}

---

## Instruções

1. `git checkout develop && git pull`
2. {Passo 2}
3. {Passo 3}
4. COMMIT + PUSH — confirmar hash
5. Atualizar `planejamento-diario/INDICE.md`: marcar ✅ na sua task e preencher hash do commit

---

## Checklist

- [ ] 1. Ler PRD §{X} e Blueprint §{Y}
- [ ] 2. {descrição da subtarefa}
- [ ] 3. {descrição da subtarefa}
- [ ] 4. Commit + push (hash: __________)
- [ ] 5. INDICE.md: marcar ✅ + preencher hash
- [ ] 6. Reportar conclusão no Slack nesta thread mencionando `<@{{SLACK_ID_ORCHESTRATOR}}>`

---

## Restrições

- NÃO modificar arquivos fora do escopo
- **SEMPRE**: git checkout develop, git commit + push (hash no report), preencher checkboxes ANTES de reportar
- CADA task = UMA thread Slack. Responder EXCLUSIVAMENTE nela mencionando `<@{{SLACK_ID_ORCHESTRATOR}}>`
- Checkboxes + Conclusão ANTES de reportar

---

## Conclusão

**Agente:** {agente}  
**Concluída em:** {data/hora}  
**Motor utilizado:** {motor real usado}  
**Commit:** __________  
**Observações:** {notas}
