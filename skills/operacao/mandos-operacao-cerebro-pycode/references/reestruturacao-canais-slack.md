# Reestruturação de Canais Slack — Arquitetura Final (29/05/2026)

Checklist para quando canais Slack são renomeados/reestruturados. Deve ser executado por ambos os orquestradores (OVH + Mac).

## Arquitetura Final de Canais

| Canal | ID | Equipe | Participantes |
|---|---|---|---|
| `{{SLACK_CHANNEL_TEAM}}` | `{{SLACK_CHANNEL_TEAM_ID}}` | Mac (M4) | {{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}, {{DEVOPS_ENGINEER}}, {{GIT_OPS}} + {{COMMANDER}} |
| `{{SLACK_CHANNEL_OVH}}` | `{{SLACK_CHANNEL_OVH_ID}}` | OVH | Aragorn, Celebrimbor, Galadriel, Elrond, Éomer, Gandalf + {{COMMANDER}} |
| `{{SLACK_CHANNEL_WAR_ROOM}}` | `{{SLACK_CHANNEL_WAR_ROOM_ID}}` | Cross-team | TODOS os 12 agentes (Mac + OVH) + {{COMMANDER}} |

**Regra:** Cada equipe tem seu canal principal. `{{SLACK_CHANNEL_WAR_ROOM}}` é o ponto de encontro cross-team com TODOS os agentes, não apenas os orquestradores.

## Configuração Dual-Channel (free_response_channels)

Cada agente lê ambos os canais (seu canal de equipe + `{{SLACK_CHANNEL_WAR_ROOM}}`):

```yaml
slack:
  require_mention: true
  free_response_channels: '<#CANAL_EQUIPE>,<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>'
  allow_bots: mentions
```

| Agente | free_response_channels |
|---|---|
| Mac agents | `<#{{SLACK_CHANNEL_TEAM_ID}}>,<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>` |
| OVH agents | `<#{{SLACK_CHANNEL_OVH_ID}}>,<#{{SLACK_CHANNEL_WAR_ROOM_ID}}>` |

## Regime de Leitura e Resposta (RLR)

Implementado em todos os SOUL.md:

1. **Leitura**: Agentes recebem TODAS as mensagens de ambos os canais (via `free_response_channels`)
2. **Resposta**: SÓ respondem quando seu `<@USER_ID>` é usado explicitamente
3. **Menção**: SEMPRE usar `<@USER_ID>` ao comunicar-se com outros agentes
4. **Violação**: Responder sem menção = quebra de corrente de comando

## Checklist por Ambiente (pós-reestruturação)

### Para cada agente

#### 1. SOUL.md
- [ ] Canal principal correto (`{{SLACK_CHANNEL_TEAM}}` ou `{{SLACK_CHANNEL_OVH}}`)
- [ ] Seção "Regime de Leitura e Resposta" presente com `<@USER_ID>` próprio
- [ ] Ambos os canais mencionados na seção de leitura
- [ ] IDs Slack do próprio time corretos (Mac: U0B6*/U0B7*, OVH: U0B1*)

#### 2. config.yaml
- [ ] `free_response_channels` com ambos os canais
- [ ] `require_mention: true`
- [ ] `allow_bots: mentions`
- [ ] IDs nos campos `bot_user_id` e `allowed_users` corretos

#### 3. TEAM.md / AGENTS.md
- [ ] Mapa de menções com IDs corretos
- [ ] Canal de comunicação com nome e ID corretos
- [ ] Referências cross-team com nomes da outra equipe (LOTR ↔ Stormlight)

#### 4. Reinicialização
- [ ] Gateways reiniciados após alterações de config.yaml
- [ ] `channel_directory.json` regenerado automaticamente

## Pitfalls

- **`state.db` mantém sessões antigas** com referência ao canal antigo. Limpar após alteração de `home_channel`.
- **Gateways precisam ser reiniciados.** Alterações em config.yaml só têm efeito após restart.
- **Não usar execute_code read/write para editar arquivos de perfil.** O `read_file` retorna conteúdo com prefixos de linha (`1|conteúdo`), e `write_file` escreve isso de volta, corrompendo os arquivos. Use `sed`/`perl` no terminal ou a ferramenta `patch`.
- **BSD sed (macOS) não interpreta `\n` em replacement.** Use `perl -i -pe` para inserir newlines, ou use a ferramenta `patch` que lida com quebras de linha corretamente.
- **Arquivos removidos do git (.gitignore) não podem ser restaurados com `git checkout`.** Se corrompidos, precisam ser reescritos do zero com `write_file`.
