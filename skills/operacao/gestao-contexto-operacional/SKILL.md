---
name: gestao-contexto-operacional
title: Gestão de Contexto Operacional
description: Mantém, organiza e compacta o contexto operacional da equipe — DIARIO.md, ESTADO-DA-EQUIPE.md, sessões de aquecimento e protocolo de continuidade entre ciclos diários.
category: operacao
---

<!--
Arquivo criado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
-->

# Gestão de Contexto Operacional

## Gatilho

- Início de cada ciclo diário (fase de Planejamento)
- Antes de delegar tarefas para um agente específico
- Após interrupções ou pausas longas (> 2h)
- Quando um novo agente entra na equipe

## Pré-requisitos

- Estrutura `operacional/` criada no diretório do projeto com:
  - `DIARIO.md` — registro cronológico do dia
  - `ESTADO-DA-EQUIPE.md` — snapshot do estado atual
- Perfis Hermes configurados com `system_prompt` incluindo referência ao protocolo diário

---

## Procedimento Passo a Passo

### 1. Carregar Contexto Atual

Antes de qualquer operação, o orquestrador DEVE carregar:

```bash
# Estado atual da equipe
cat {{PROJECT_PATH}}/operacional/ESTADO-DA-EQUIPE.md

# Diário do dia (se existir)
cat {{PROJECT_PATH}}/operacional/DIARIO.md

# Plano do dia
cat {{PROJECT_PATH}}/planejamento-diario/{{DATA_ATUAL}}/PLANO.md
```

### 2. Aquecimento Contextual (Sessão de Continuidade)

Execute a sessão de aquecimento para garantir que todos os agentes compartilhem o mesmo contexto:

1. **Resumo do dia anterior:** Leia o PLANO.md e INDICE.md do dia anterior
2. **Estado atual:** Verifique ESTADO-DA-EQUIPE.md para tarefas pendentes, bloqueios e decisões
3. **Prioridades do dia:** Liste as 3-5 prioridades máximas do dia
4. **Agentes disponíveis:** Confirme quem está online e qual motor cada um usará

### 3. Compactação de Contexto

Se o DIARIO.md estiver muito longo (> 100 linhas), faça uma compactação:

```markdown
## Compactação — {{DATA_ATUAL}}

### Resumo
- Decisões: [lista de decisões chave]
- Bloqueios: [lista de bloqueios ativos]
- Pendências: [tarefas que passaram para o próximo ciclo]
```

O conteúdo original deve ser movido para `operacional/archive/DIARIO-{{DATA_ANTERIOR}}.md`.

### 4. Atualização do ESTADO-DA-EQUIPE.md

Após cada mudança significativa, atualize:

```markdown
# Estado da Equipe — {{TEAM_NAME}}

## Agentes
| Agente | Status | Motor | Última Ação |
|--------|--------|-------|-------------|
| {{ORCHESTRATOR}} | Online | {{MOTOR_PADRAO}} | — |

## Tarefas Ativas
| Task | Agente | Status | Bloqueio |
|------|--------|--------|----------|
| — | — | ⬜ | — |

## Alertas
- Nenhum

## Decisões do Dia
- {{DATA_BR}}: Início do ciclo
```

### 5. Protocolo de Continuidade entre Ciclos

Ao final de cada dia, o orquestrador DEVE:

1. Garantir que DIARIO.md esteja completo e coeso
2. Atualizar ESTADO-DA-EQUIPE.md com o snapshot final
3. Registrar no INDICE.md o progresso do dia
4. Commitar as alterações no repositório do projeto

---

## Verificação

- [ ] DIARIO.md existe e está atualizado
- [ ] ESTADO-DA-EQUIPE.md reflete o estado real
- [ ] Nenhum placeholder `{{...}}` bruto permanece nos arquivos
- [ ] Compactação feita se necessário (> 100 linhas)
- [ ] Alterações commitadas

---

## Armadilhas

- **Contexto conflitante:** Sempre carregue DIARIO.md e ESTADO-DA-EQUIPE.md ANTES de delegar — agentes diferentes podem ter visões diferentes
- **Compactação prematura:** Não compacte antes do final do ciclo — informação pode ser perdida
- **Esquecer de commitar:** O contexto só é útil se persistido. Commite ao final de cada dia
- **Agente offline:** Se um agente está offline, marque em ESTADO-DA-EQUIPE.md e reatribua as tarefas

---

## Referências

- `{{PROJECT_PATH}}/operacional/DIARIO.md`
- `{{PROJECT_PATH}}/operacional/ESTADO-DA-EQUIPE.md`
- `{{PROJECT_PATH}}/planejamento-diario/INDICE.md`
- `{{PROJECT_PATH}}/planejamento-diario/{{DATA_ATUAL}}/PLANO.md`
