# Padronização de Config dos Agentes — Checklist

Procedimento para auditar e corrigir `config.yaml` de todos os agentes simultaneamente.

## Gatilho

- Após alteração de regra operacional que afeta todos os agentes
- Quando houver inconsistência de formato entre agentes (ex: `allow_mentions` vs `allow_bots`)
- Após migração ou clonagem de equipe

## Checklist por Agente

Cada `config.yaml` deve conter em TODAS as seções `slack:`:

```yaml
slack:
  require_mention: true
  allow_bots: mentions
  free_response_channels: ''    # vazio = sem bypass de menção
```

## Comando de Auditoria

```bash
for agent in dalinar navani shallan jasnah kaladin pattern; do
  echo "=== $agent ==="
  grep -E "(require_mention|allow_bots|allow_mentions|free_response_channels)" \
    ~/.hermes/profiles/$agent/config.yaml
  echo
done
```

## Problemas Comuns e Correções

| Sintoma | Causa | Correção |
|---------|-------|----------|
| `allow_mentions: true` | Formato antigo (pré-30/05/2026) | Substituir por `allow_bots: mentions` |
| Sem `allow_bots` ao lado de `require_mention` | Seção incompleta | Adicionar `allow_bots: mentions` |
| `free_response_channels` não-vazio | Bypass do `require_mention` | Esvaziar: `free_response_channels: ''` |
| Sem `require_mention` | Agente responde a qualquer mensagem | Adicionar `require_mention: true` |

## Agentes Padrão

| Agente | ID Slack | Profile Path |
|--------|----------|-------------|
| {{ORCHESTRATOR}} | {{SLACK_ID_ORCHESTRATOR}} | `~/.hermes/profiles/dalinar/config.yaml` |
| {{BACKEND_ENGINEER}} | {{SLACK_ID_BACKEND}} | `~/.hermes/profiles/navani/config.yaml` |
| {{FRONTEND_ENGINEER}} | {{SLACK_ID_FRONTEND}} | `~/.hermes/profiles/shallan/config.yaml` |
| {{AUDITOR}} | {{SLACK_ID_AUDITOR}} | `~/.hermes/profiles/jasnah/config.yaml` |
| {{DEVOPS_ENGINEER}} | {{SLACK_ID_DEVOPS}} | `~/.hermes/profiles/kaladin/config.yaml` |
| {{GIT_OPS}} | {{SLACK_ID_GITOPS}} | `~/.hermes/profiles/pattern/config.yaml` |

## Pitfalls

- `allow_mentions` ≠ `allow_bots`. O primeiro é formato obsoleto, o segundo é o correto.
- `free_response_channels: ''` (string vazia) é diferente de `free_response_channels:` (ausente). Ambos funcionam, mas string vazia é explícito.
- Após alterar config.yaml, o gateway precisa ser reiniciado para aplicar as mudanças.
- {{GIT_OPS}} historicamente não tinha `allow_bots` nem `free_response_channels` — precisa ser adicionado manualmente em clonagens.
- **Caso real (30/05/2026):** Padronização completa executada. {{BACKEND_ENGINEER}}/{{FRONTEND_ENGINEER}}/{{AUDITOR}}/{{DEVOPS_ENGINEER}}: `allow_mentions: true` → `allow_bots: mentions`. {{GIT_OPS}}: adicionado `allow_bots: mentions` + `free_response_channels: ''`. {{ORCHESTRATOR}}: segunda seção slack sem `allow_bots` — adicionado. Verificação final: todos os 6 agentes com `require_mention: true`, `allow_bots: mentions`, `free_response_channels: ''`.
