# Formato de Mensagem de Delegação

## Template Completo

```markdown
<@AGENTE_ID> task_XX — TÍTULO. Wave X. Prioridade 🔴.

ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE [CLI] ([comando exato]).
NÃO usar outro. Se falhar, PARAR.

1. git checkout develop && git pull
2. Instrução específica 1
3. Instrução específica 2
N. COMMIT + PUSH — confirmar hash

Leitura Obrigatória: PRD §X, Blueprint §Y, Checklist S01, [outros docs].

Restrições: motor, proibido modificar X, NUNCA Y.

Recursos Dontus: https://sistema.dontus.com.br (consultar se necessário).
Credenciais: {{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}}.
NUNCA modificar dados no Dontus — apenas consulta.
```

## Regras de Ouro — Verificar ANTES de Enviar

### 1. Menção no INÍCIO
`<@USER_ID>` na PRIMEIRA palavra da mensagem. NUNCA texto antes da menção — o parser do Slack ignora a notificação.

### 2. ORDEM ABSOLUTA
Sempre incluir o bloco com comando exato. Ex: `Motor EXCLUSIVAMENTE Gemini CLI (gemini -m "gemini-3.1-pro-preview")`. SEMPRE.

### 3. Sem tabelas/pipes na mesma mensagem
Pipes `|` quebram o parser de menções. Se precisar de tabela, enviar em mensagem separada APÓS a menção.

### 4. Canal correto
**Equipe Mac:** `{{SLACK_CHANNEL_TEAM}}`. **Sociedade do Anel (OVH):** `{{SLACK_CHANNEL_OVH}}`. NUNCA misturar.

### 5. Thread única
A primeira mensagem ABRE a thread. TODAS as respostas (sinal verde, atualizações, correções, conclusão) vão como RESPOSTA nessa mesma thread. NUNCA criar thread nova para a mesma task.

### 6. Recursos Dontus — OBRIGATÓRIO avaliar
Antes de cada delegação, perguntar: *"O agente pode precisar consultar o Dontus para esta task?"*

Se SIM (tasks de interface, mapeamento, validação, CRUD, UX):
```
Recursos Dontus: https://sistema.dontus.com.br (consultar UX).
Credenciais: {{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}}.
NUNCA modificar dados no Dontus — apenas consulta.
```

Se NÃO (tasks puramente de infra, testes, segurança interna) — ok omitir.

**Já esquecido múltiplas vezes. NUNCA pular esta avaliação.**

### 7. Uma task por mensagem
Não agrupar múltiplas tasks na mesma mensagem.

---

## Motores (Hierarquia — NÃO negociação)

| Motor | Uso | Comando |
|-------|-----|---------|
| **Gemini 3.1 Pro** | **Padrão ABSOLUTO para código** | `gemini -m "gemini-3.1-pro-preview"` |
| **Opus 4.7** | Exclusivo {{FRONTEND_ENGINEER}} (design/visão) | `claude --print --dangerously-skip-permissions --effort max` |
| **DeepSeek V4 Pro** | PROIBIDO sem ordem explícita | `opencode run -m deepseek-v4-pro` |

### Regra: Motor do task_XX.md NÃO é autoridade
Se o arquivo task_XX.md disser "DeepSeek V4 Pro", SOBRESCREVER para Gemini CLI. O arquivo define O QUE fazer, não QUAL motor usar. A hierarquia de motores sempre prevalece.

### Se o motor falhar
PARAR e reportar a {{ORCHESTRATOR}} no Slack. NUNCA fazer fallback automático para outro motor.

---

## Vocabulário com {{COMMANDER}}

| {{COMMANDER}} diz | Significado | Ação |
|------------|-------------|------|
| "planeje" / "crie tasks" | CRIAR .md + índices APENAS | Não enviar no Slack |
| "pode soltar" / "pode delegar" | AUTORIZAÇÃO para enviar no Slack | Delegar 1 por vez |
| "aguarde" | PARAR tudo | Zero ações até nova ordem |
| "sinal vermelho" / "LOCKDOWN" | Emergência | Parar execução imediata |

**PLANEJAR ≠ DELEGAR.** Esses verbos NÃO são intercambiáveis.

---

## Exemplo Correto (Com Dontus)

```markdown
<@{{SLACK_ID_DEVOPS}}> task_12 — Validar RBAC contra Dontus Ao Vivo.
Wave 2. Prioridade 🟡.

ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE Gemini CLI
(gemini -m "gemini-3.1-pro-preview"). NÃO usar outro. Se falhar, PARAR.

1. Abrir Dontus (https://sistema.dontus.com.br) — login com credenciais
2. Navegar como Admin, Dentista, Recepcionista, Financeiro
3. Mapear cada ação → permissão {{PROJECT_NAME}}
4. Gerar relatório + COMMIT + PUSH

Leitura Obrigatória: PRD §2.2 (RBAC G02), Blueprint §6.
Recursos Dontus: https://sistema.dontus.com.br ({{COMMANDER}} / {{DONTUS_PASSWORD}} / {{DONTUS_CLINICA_ID}}).
NUNCA modificar dados no Dontus.
```

## Exemplo Correto (Sem Dontus)

```markdown
<@{{SLACK_ID_GITOPS}}> task_16 — SP1-28: Testes de Segurança.
Wave 3. Prioridade 🔴.

ORDEM ABSOLUTA: Motor EXCLUSIVAMENTE Gemini CLI
(gemini -m "gemini-3.1-pro-preview"). NÃO usar outro. Se falhar, PARAR.

1. Criar tests/test_security/ com 3 suites
2. Anti-IDOR, CSRF, CSP
3. Adicionar ao CI + COMMIT + PUSH

Leitura Obrigatória: PRD §2.3, Blueprint §6, Checklist S01 SP1-28.
```

## Exemplo ERRADO (NUNCA fazer)

```markdown
<@AGENTE> task_01
contexto...
```

E depois enviar OUTRA mensagem:

```markdown
<@AGENTE> SINAL VERDE
```

Cada mensagem inicia thread DIFERENTE = CAOS. Tudo na mesma thread.

---

## Regras Críticas — Pós-Delegação

### Ação corretiva NUNCA sem ordem explícita
Se perceber que errou (delegou task errada, motor errado, canal errado):
1. Reportar o erro a {{COMMANDER}}
2. AGUARDAR instruções
3. NÃO desfazer, não apagar, não corrigir por conta própria

### Auditoria pós-task
Após o agente reportar conclusão:
1. Verificar commit real (`git log --oneline`)
2. Verificar diff (`git show <hash> --stat`)
3. Atualizar PLANO.md (status ✅) e INDICE.md (hash, 👁)
4. Commit + push dos registros
5. Reportar veredito na thread
