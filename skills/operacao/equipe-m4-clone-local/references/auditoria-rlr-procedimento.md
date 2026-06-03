# Auditoria RLR — Procedimento Canônico

> Procedimento validado em 29/05/2026 na auditoria da equipe Mac pós-emancipação.
> Replicável para qualquer equipe Hermes (OVH/Sociedade do Anel ou novas).

## Metodologia (5 passos)

### Passo 1: Levantamento de baseline

Para cada agente, mapear contaminação de IDs:

```bash
grep -n 'U0B' SOUL.md IDENTITY.md TEAM.md AGENTS.md TOOLS.md config.yaml
```

**Sinal de alerta:** IDs de outro ambiente (ex: IDs OVH `U0B1_` em agentes Mac `U0B6_/U0B7_`).

### Passo 2: Correção por agente (7 arquivos)

| Arquivo | O que verificar |
|---------|----------------|
| `config.yaml` | `bot_user_id`, `free_response_channels`, `allow_bots`, `require_mention` |
| `SOUL.md` | Canal textual, nomes de outros agentes, bloco RLR |
| `IDENTITY.md` | Auto-identificação (equipe correta) |
| `TEAM.md` | IDs de todos os membros, cross-team refs |
| `AGENTS.md` | Mapa de menções com `<@USER_ID>` real |
| `TOOLS.md` | Referências a canais/agentes (se houver) |
| `HEARTBEAT.md` | Referências a canais/agentes (se houver) |

### Passo 3: Configuração do RLR (3 camadas)

#### Camada 1 — Técnica (config.yaml)

```yaml
slack:
  require_mention: true
  free_response_channels: '<#CANAL_EQUIPE>,<#CANAL_CROSS_TEAM>'
  allow_bots: mentions
```

| Config | Valor | Efeito |
|--------|-------|--------|
| `free_response_channels` | IDs dos canais | Agente recebe TODAS as mensagens |
| `require_mention` | `true` | Bloqueio técnico: só processa menções |
| `allow_bots` | `mentions` | Previne loops bot→bot |

#### Camada 2 — Comportamental (SOUL.md)

```markdown
### Regime de Leitura e Resposta — CRÍTICO

Você recebe TODAS as mensagens do canal <#CANAL_EQUIPE> (equipe)
e <#CANAL_CROSS_TEAM> (cross-team).
Use esse fluxo para manter conhecimento situacional completo.

**Regras absolutas de resposta:**
1. **SÓ RESPONDA** quando seu `<@SEU_USER_ID>` for usado explicitamente.
2. **NUNCA responda** mensagens onde não foi mencionado.
3. **SEMPRE mencione** outros agentes por `<@USER_ID>`. Mensagem sem menção = não entregue.
4. **Violação** = quebra de corrente de comando. É gravíssimo.
5. **Silêncio = zero output.** Não produza mensagens dizendo "estou em silêncio".
```

#### Camada 3 — Conhecimento (AGENTS.md)

Mapa de menções com `<@USER_ID>` real para TODOS os agentes:
- Membros da própria equipe
- Membros cross-team (outra equipe)
- Sempre `<@USER_ID>` nu, nunca em backticks

### Passo 4: Verificação pós-auditoria (checklist)

- [ ] `config.yaml` tem `require_mention: true`
- [ ] `config.yaml` tem `free_response_channels` com ambos os canais
- [ ] `config.yaml` tem `allow_bots: mentions`
- [ ] Nenhum ID de outro ambiente nos arquivos do agente
- [ ] SOUL.md contém o bloco "Regime de Leitura e Resposta"
- [ ] AGENTS.md contém mapa correto de menções com `<@USER_ID>`
- [ ] Referências a canais antigos removidas
- [ ] Gateway **reiniciado** após alterações (`kill <PID>` — auto-restarta)

### Passo 5: Comando de verificação rápida

```bash
for agent in agente1 agente2 agente3; do
  profile_dir="$HOME/.hermes/profiles/$agent"
  echo "=== $agent ==="
  grep 'require_mention' "$profile_dir/config.yaml"
  grep 'free_response_channels' "$profile_dir/config.yaml"
  # IDs de outro ambiente? Deve retornar 0
  grep -c 'U0B6_\|U0B7_' "$profile_dir/AGENTS.md" "$profile_dir/TEAM.md" 2>/dev/null
  # Canais antigos?
  grep -c 'roshar-sync\|canal-antigo' "$profile_dir/SOUL.md" 2>/dev/null
done
```

## Pitfalls Específicos do RLR

1. **Backticks matam menções.** `<@USER_ID>` dentro de backticks vira texto literal. O agente destinatário NUNCA recebe.
2. **IDs de outro ambiente residuais.** `AGENTS.md` e `TEAM.md` frequentemente preservam IDs da origem. `grep` é obrigatório.
3. **config.yaml requer restart.** SOUL.md/MEMORY.md são lidos a cada turno, mas `config.yaml` só na inicialização do gateway.
4. **"Comentar o silêncio" é ruído.** Agentes não mencionados devem produzir zero output.
5. **Orquestrador não é exceção.** O líder da equipe também segue o RLR — só responde quando seu ID é mencionado.
6. **Menção textual = mensagem perdida.** Escrever "Nome" em vez de `<@USER_ID>` faz o agente nunca ver a mensagem. `require_mention: true` bloqueia menções textuais.
