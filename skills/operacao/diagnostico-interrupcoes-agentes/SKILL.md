---
name: diagnostico-interrupcoes-agentes
description: Diagnosticar e corrigir interrupções/timeouts em agentes Hermes durante tarefas longas
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Diagnóstico de Interrupções em Agentes Hermes

## Sintoma A — Tarefa interrompida por timeout

Mensagens como `"3 min elapsed, iteration 5/90, running: terminal"` — a tarefa é interrompida antes de concluir, seja por timeout do terminal ou por chegada de nova mensagem.

## Sintoma B — Agente não responde no Slack (Mac/launchctl)

Mensagens no canal ficam sem resposta. `launchctl list | grep hermes` mostra menos processos que o esperado (ex: só o dalinar-mac).

**Causa:** LaunchAgents dos agentes não foram carregados. `launchctl load -w` carrega APENAS o plist especificado — se só o dalinar-mac foi carregado, os demais 5 agentes não respondem.

**Correção:**
```bash
for agent in dalinar-mac navani-mac shallan-mac jasnah-mac kaladin-mac pattern-mac; do
  launchctl load -w ~/Library/LaunchAgents/com.{{COMMANDER}}.hermes.$agent.plist
done
```

## Causas raiz (3 parâmetros no config.yaml de cada agente)

| Parâmetro | Padrão problemático | Efeito |
|---|---|---|
| `terminal.timeout` | `180` (3 min) | Corta comandos longos (pip install, npm install, builds, git clone) |
| `display.busy_input_mode` | `interrupt` | Qualquer mensagem nova mata a tarefa em execução |
| `delegation.max_iterations` | `15` | Subagentes falham em tarefas complexas (análise de segurança, debugging) |

## Correção padrão

```yaml
terminal.timeout: 600        # 10 minutos
display.busy_input_mode: queue  # enfileira mensagens, não mata tarefa
delegation.max_iterations: 30   # dobra tolerância para subagentes
```

## Procedimento

1. Listar agentes ativos
2. Para cada agente, ler `config.yaml`
3. Verificar os 3 parâmetros acima
4. Se divergirem dos valores corrigidos, aplicar `patch()` — NUNCA usar script intermediário ou `sed` (Regra 11 dos Mandos)
5. Aguardar Sinal Verde do {{COMMANDER}} antes de aplicar qualquer alteração

## Sintoma C — Gateway Zumbi (processo vivo, conexão morta)

**Ocorrência real:** {{AUDITOR}}-mac (29/05/2026) — processo rodando (PID 85575, 17h+ ativo), `gateway_state.json` com `slack.state: "connected"`, mas zero mensagens processadas desde o dia anterior (16:42). Nenhum `inbound message` registrado há 13+ horas. Erros de `TimeoutError` no `err.log` ao tentar reconectar Socket Mode (DNS falhou e a reconexão nunca aconteceu).

**Como diagnosticar (3 verificações rápidas):**
```bash
# 1. Idade do processo vs última mensagem recebida
ps -o lstart,etime,pid -p $(pgrep -f "profile <agente>-mac gateway" 2>/dev/null)
grep "inbound message" ~/.hermes/profiles/<agente>-mac/logs/gateway.log | tail -1

# 2. Timestamp do gateway_state vs agora
cat ~/.hermes/profiles/<agente>-mac/gateway_state.json | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print('pid:', d.get('pid'), '| slack:', d.get('platforms',{}).get('slack',{}).get('state'), '| updated:', d.get('updated_at'))"

# 3. out.log vazio = gateway nunca produziu stdout nesta sessão
ls -la ~/.hermes/profiles/<agente>-mac/logs/out.log
```

**Sinais de alerta:**
- `updated_at` > 15 min atrás → possível zumbi
- Última `inbound message` > 2h atrás → não recebe eventos
- `out.log` com 0 bytes → stdout nunca foi escrito (inicialização incompleta)

**Correção:**
```bash
# Matar o processo antigo
kill $(pgrep -f "profile <agente>-mac gateway")
# Aguardar launchctl restartar automaticamente (KeepAlive)
sleep 10
# Confirmar novo PID + conexão
pgrep -fl "<agente>-mac"
grep "Authenticated as" ~/.hermes/profiles/<agente>-mac/logs/gateway.log | tail -1
grep "Socket Mode connected" ~/.hermes/profiles/<agente>-mac/logs/gateway.log | tail -1
```

**Custo do erro:** ~30-45 min de diagnóstico + correção + re-delegação + expectativa frustrada do {{COMMANDER}}.

**Prevenção:** Checklist pré-delegação — antes de atribuir tarefa crítica a um agente, verificar os 3 sinais acima. Se zumbi, corrigir primeiro ou usar subagente via `delegate_task` (que não depende do Slack do outro agente).

## Agentes afetados (time do {{COMMANDER_NAME}})
- {{ORCHESTRATOR}} (orquestrador)
- {{BACKEND_ENGINEER}} (backend/arquitetura)
- {{FRONTEND_ENGINEER}} (frontend/UI)
- {{AUDITOR}} (pesquisa/análise)
- {{DEVOPS_ENGINEER}} (devops/infra)
