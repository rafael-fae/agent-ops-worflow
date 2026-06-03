# Coordenação Multi-Equipe: M4 (Mac) vs OVH

## Contexto

Duas equipes de agentes Hermes coexistem:
- **Equipe M4 (Mac)** — perfil local no MacBook M4 de {{COMMANDER}}
- **Equipe OVH** — servidor remoto (Ponte Quatro original)

Ambos os times operam no **mesmo workspace Slack**, no **mesmo canal `#operacao`**, com **apps Slack independentes** mas **mesma nomenclatura de agentes** ({{BACKEND_ENGINEER}}, {{AUDITOR}}, etc.).

## O Problema

Quando {{ORCHESTRATOR}}-mac convoca "a equipe" sem especificar, cria ambiguidade:

```
<@{{SLACK_ID_BACKEND}}> <@{{SLACK_ID_FRONTEND}}> → "Convocando equipe para revisão"
```

Os IDs {{SLACK_ID_BACKEND}} e {{SLACK_ID_FRONTEND}} existem nos DOIS ambientes (M4 e OVH) com apps Slack diferentes, mas **no mesmo workspace o mesmo user ID resolve para o mesmo bot user**. Se ambas as instâncias estiverem rodando, a menção ativa as duas.

## Regra de Convocation

1. **Sempre especificar a equipe** explicitamente na mensagem: "Equipe M4, revisem..." ou "Equipe OVH..."
2. AGENTS.md do orquestrador **deve ter seções separadas** para M4 e OVH
3. **Nunca convocar agentes OVH do Mac** a menos que {{COMMANDER}} autorize expressamente
4. Quando houver dúvida sobre qual equipe convocar, **perguntar a {{COMMANDER}} primeiro**

## Mapa de IDs (confirmado por {{FRONTEND_ENGINEER}}-mac 28/05/2026)

### Equipe M4 (Mac local)
| Agente | ID Slack |
|--------|----------|
| {{ORCHESTRATOR}}-mac | `<@{{SLACK_ID_ORCHESTRATOR}}>` |
| {{BACKEND_ENGINEER}}-mac | `<@{{SLACK_ID_BACKEND}}>` |
| {{FRONTEND_ENGINEER}}-mac | `<@{{SLACK_ID_FRONTEND}}>` |
| {{AUDITOR}}-mac | `<@{{SLACK_ID_AUDITOR}}>` |
| {{DEVOPS_ENGINEER}}-mac | `<@{{SLACK_ID_DEVOPS}}>` |
| {{GIT_OPS}}-mac | `<@{{SLACK_ID_GITOPS}}>` |

### Equipe OVH (servidor remoto)
| Agente | ID Slack |
|--------|----------|
| {{ORCHESTRATOR}} OVH | `<@{{SLACK_ID_OVH_ORCHESTRATOR}}>` |
| {{BACKEND_ENGINEER}} OVH | `<@{{SLACK_ID_OVH_BACKEND}}>` |
| {{FRONTEND_ENGINEER}} OVH | `<@{{SLACK_ID_OVH_FRONTEND}}>` |
| {{AUDITOR}} OVH | `<@{{SLACK_ID_OVH_PRODUCT}}>` |
| {{DEVOPS_ENGINEER}} OVH | `<@{{SLACK_ID_OVH_DEVOPS}}>` |

## Verificação Rápida de Qual Equipe Está Online

```bash
# Verificar gateways Mac (locais)
ps aux | grep "hermes.*-mac gateway" | grep -v grep

# Verificar gateways OVH (via SSH)
ssh {{COMMANDER}}@ssh.oesteodontologia.com.br "ps aux | grep 'hermes.*gateway' | grep -v grep"
```
