---
name: orquestracao-refinamento-multi-modelo
description: >-
  Orquestração de refinamento de planos de implementação usando múltiplos modelos
  (Claude Opus para profundidade, Gemini 3.1 Pro para visão arquitetural).
  Cobre decomposição em seções, execução paralela via background processes,
  e compilação dos resultados.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Orquestração de Refinamento Multi-Modelo

## Gatilho
- {{COMMANDER}} aprova o uso de CLIs (Claude Code, Gemini, OpenCode) para planejamento
- Um plano de implementação grande (+500 linhas) precisa ser refinado com máxima qualidade
- O agente precisa coordenar múltiplos modelos para cobrir profundidade + amplitude
- Um relatório GAPS-REPORT.md contém gaps priorizados (1-2) que precisam de deep-dive técnico de Claude Opus
- Execução autônoma (cron job) — nenhum usuário presente para esclarecer dúvidas

## Princípios

1. **Claude Opus para profundidade técnica** — refinamento detalhado de seções com código, arquivos, configurações
2. **Gemini 3.1 Pro para visão arquitetural** — revisão cross-cutting, coerência entre seções, 2M tokens de contexto
3. **Processos paralelos** — cada seção refinada em background independente com `notify_on_complete`
4. **Pipeline de compilação** — ao final, consolidar todos os refinamentos no plano mestre

## Mapa de Modelos vs. Tipo de Refinamento

| Tipo de Refinamento | Modelo | Justificativa |
|--------------------|--------|---------------|
| Wave técnica (código, models, views, config) | Claude Opus | Profundidade, geração de código real |
| Gap-filling / análise de completude | Claude Opus → Gemini 3.1 Pro | Hierarquia {{COMMANDER}} (29/05): Opus primeiro, Gemini fallback, DeepSeek último recurso |
| Design System / Frontend | Claude Opus | Componentização, Alpine.js, HTML |
| State Machines / Regras de Negócio | Claude Opus | Lógica complexa, automação |
| Revisão Arquitetural Cross-Wave | Gemini 3.1 Pro (2M ctx) | Visão panorâmica, coerência global |
| Revisão de Segurança Multi-Tenant | Gemini 3.1 Pro | Padrões de isolamento, IDOR, OWASP |
| Cobertura de gaps documentados | Claude Opus + Gemini 3.1 Pro | Opus profundidade + Gemini amplitude. DeepSeek v4 pro só se ambos esgotados |
| Integrações / APIs Externas | Claude Opus | Detalhes de implementação |

## Hierarquia de Modelos ({{COMMANDER}}, 29/05/2026)

**Regra máxima:** 1º Claude Opus 4.7 → 2º Gemini 3.1 Pro (fallback quando Opus esgotar tokens) → 3º DeepSeek v4 Pro (só se ambos esgotados). Nunca pular para DeepSeek antes de tentar Gemini.

### Task Allocation When Opus is Exhausted (validado 31/05/2026)

**Gatilho:** Opus semanal esgotado (limites reiniciam no dia 05 de cada mês). {{COMMANDER}} não quer trabalho parado por 5 dias.

**Matriz de Alocação por Tipo de Trabalho:**

| Tipo de Trabalho | Modelo | Justificativa | Exemplos da sessão |
|-----------------|--------|---------------|-------------------|
| Cross-documento / Consolidação | Gemini 3.1 Pro | Amplitude > profundidade. Detectar contradições entre 5+ documentos | Cruzar GAPS-REPORT vs 8 reescritas |
| Organização e índices | Gemini 3.1 Pro | Síntese, categorização, eliminação de duplicatas | Atualizar REESCRITA-SUMMARY.md, atualizar INDICE-MESTRE.md |
| Auditoria de cobertura | Gemini 3.1 Pro | Cruzar gaps vs implementações → tabela de cobertura | Verificar se cada gap (1.1 a 2.3) foi coberto em alguma reescrita |
| Documentação de decisões | Gemini 3.1 Pro | Organização, não análise profunda | Documentar conflito de paleta Design System (desbloqueia {{FRONTEND_ENGINEER}}) |
| ADRs de particionamento (análise pura) | Gemini 3.1 Pro | Decisão documental sem geração de código | ADR Wave3: Paciente 28 abas → 3A/3B |
| Config CACHES / scripts de infra (não críticos) | Gemini 3.1 Pro | Código boilerplate, risco controlado | 3 aliases Redis + LocMemCache fallback |
| **Arquitetura / Decisões técnicas irreversíveis** | **Opus (bloqueado — esperar reset)** | Requer raciocínio profundo | ADR Event Bus `on_commit`+Celery, ETL Dontus |
| **Geração de código complexo** | **Opus (bloqueado — esperar reset)** | Precisão algorítmica | `_HtmxCacheKeyIndex` (Redis SET index), G05 logger 11 eventos |
| **Código de infra sensível** | **Opus (bloqueado — esperar reset)** | Segurança | Criptografia backup, PgBouncer config |

**Regra prática para alocação rápida:**
- Se o trabalho é **ler 5+ docs, cruzar, e produzir tabela/documento** → Gemini (1h-1h30)
- Se o trabalho é **decidir arquitetura irreversível ou gerar código de produção** → Opus (esperar reset)
- Se o trabalho é **código boilerplate com risco baixo** (configs, scripts não críticos) → Gemini
- Se o trabalho é **algoritmo complexo, segurança, ou dados reais** → Opus

**Caso real (31/05/2026):** {{AUDITOR}} produziu matriz completa em ~15 min com Gemini 3.1 Pro. ADR-005 (Wave3 particionamento) foi gerado com Gemini. Ambos aprovados sem necessidade de Opus. Economia: ~$10-15 de budget Opus preservado para itens críticos pós-reset.

## Procedimento

### Fase 1: Decomposição

1. Identificar as seções do plano (Waves, estratégia, infra, testes, etc.)
2. Extrair cada seção para arquivo individual:
   ```bash
   sed -n 'LINHA_INI,LINHA_FIMp' docs/PLANO.md > docs/refinamentos/SECAO-ORIGINAL.md
   ```
3. Determinar qual modelo refinar cada seção (ver mapa acima)

### Fase 2: Refinamento Paralelo

Para cada seção, disparar em background com `terminal(background=true, notify_on_complete=true)`:

**Claude Opus (recomendado: `--add-dir`):**
```bash
claude --add-dir docs/refinamentos \
  -p "Leia o arquivo docs/refinamentos/SECAO-ORIGINAL.md e produza versão refinada...
       Adicione: [checklist]. Gere APENAS o conteúdo refinado em markdown." \
  --print --dangerously-skip-permissions --effort max --max-budget-usd 3 \
  2>/dev/null > docs/refinamentos/SECAO-REFINADO.md
```

**⚠️ Preferir `--add-dir` sobre pipe (`cat | claude`) em background.** O pipe via stdin pode disparar o aviso "no stdin data received in 3s, proceeding without it" em processos background, fazendo o Claude perder o conteúdo de entrada. `--add-dir` + prompt referenciando o arquivo pelo nome é mais confiável.

**Claude Opus (alternativa com pipe — apenas em foreground):**
```bash
cat docs/refinamentos/SECAO-ORIGINAL.md | claude \
  -p "Produza versão refinada... [prompt completo]" \
  --print --dangerously-skip-permissions --effort max --max-budget-usd 3 \
  2>/dev/null > docs/refinamentos/SECAO-REFINADO.md
```

**Gemini (local Mac via mise):**
```bash
GEMINI_CLI_TRUST_WORKSPACE=true \
  /Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini \
  -m "gemini-3.1-pro-preview" \
  --include-directories docs/refinamentos \
  -p "Leia o arquivo SECAO-ORIGINAL.md e produza revisão arquitetural..." \
  2>/dev/null > docs/refinamentos/SECAO-REFINADO-GEMINI.md
```

**Gemini (via OVH SSH):**
```bash
ssh -i ~/.ssh/{{OVH_SSH_KEY}} {{COMMANDER}}@ssh.oesteodontologia.com.br \
  "cd /path && HOME={{COMMANDER_HOME}} gemini -m 'gemini-3.1-pro-preview' \
  --include-directories docs -p 'prompt com análise arquitetural...'" \
  > docs/refinamentos/REVISAO-GEMINI.md
```

### Fase 3: Monitoramento

Usar `process(action='poll')` para verificar progresso periodicamente:

```python
from hermes_tools import terminal
result = terminal("wc -c docs/refinamentos/SECAO-REFINADO.md")
# Se tamanho = 0, refinamento falhou silenciosamente
```

Quando `notify_on_complete` disparar, verificar se o arquivo de saída tem conteúdo (`wc -c`). Se 0 bytes, o processo provavelmente travou em permissão.

### Fase 4: Compilação

Após todos os refinamentos concluírem:
1. Substituir cada seção original pela versão refinada no PLANO.md
2. Incorporar as recomendações da revisão arquitetural
3. Atualizar sumário, índices, estimativas
4. Rodar o checklist arquitetural (ver seção abaixo)

---

## Modo 2: Gap-Filling Deep-Dive (Autônomo via GAPS-REPORT)

**Gatilho específico:** Um `GAPS-REPORT.md` no diretório `docs/refinamentos/` com gaps priorizados (1-2). Execução autônoma (cron job) — nenhum usuário presente.

### Diferenças do Modo 1 (Refinamento)

| Aspecto | Modo 1 (Refinamento) | Modo 2 (Gap-Filling) |
|---------|---------------------|---------------------|
| Entrada | Seções de plano existentes | GAPS-REPORT.md com gaps priorizados |
| Saída | Seções refinadas substituindo originais | Documentos DEEP-DIVE-{NOME}.md independentes |
| Paralelismo | Background com notify_on_complete | Foreground sequencial (prioridade 1→2→3) |
| Modelo | Claude Opus + Gemini | **Apenas Claude Opus** (profundidade técnica) |
| Interação | Pode pedir clarificação | **Zero** — autônomo, sem user presente |
| Output | `cat | claude > arquivo` (pipe stdout) | Prompt diz "salve em path/X.md" — Claude escreve direto no disco |

### Fase 1: Leitura e Contexto

1. **Ler GAPS-REPORT.md.** Extrair todos os gaps com prioridade 1-2.
2. **Ler contexto correlato.** Para cada gap, ler as seções do plano original que o gap referencia (ex: gap 1.1 "Vazamento threading.local" → ler seção 4.1.2 TenantDatabaseRouter + 4.1.3 Middleware).
3. **Criar todo list** — um item por gap, em ordem de prioridade.

### Fase 2: Deep-Dive com Claude Opus (Foreground, Sequencial)

Para cada gap, em ordem de prioridade:

```bash
cd /path/to/project && ~/.local/bin/claude \
  -p 'PROMPT_DETALHADO' \
  --print --dangerously-skip-permissions --effort max --max-budget-usd 5 \
  2>&1 | tail -5
```

**Estrutura do prompt:**
- Contexto do gap (copiado do relatório)
- Código real afetado (copiado do plano) — blocos Python/HMTL completos
- 5-7 seções que o documento DEEP-DIVE deve cobrir
- Instrução explícita de save: "Salve o documento em docs/DEEP-DIVE-{NOME}.md"
- Restrições: "Apenas markdown, mínimo N linhas, incluir blocos de código"

**⚠️ Importante:** O prompt deve ser AUTOSSUFICIENTE — todo o contexto precisa estar inline no `-p`. Em execução autônoma (cron), não há ninguém para responder perguntas ou esclarecer ambiguidades.

### Fase 3: Verificação

Após cada deep-dive, verificar o output real:

```bash
wc -l docs/DEEP-DIVE-{NOME}.md
head -15 docs/DEEP-DIVE-{NOME}.md  # confirmar que é markdown válido
```

Critérios de aceite:
- `wc -l` ≥ 200 linhas de conteúdo técnico
- Cabeçalho markdown válido (`# DEEP-DIVE — ...`)
- Blocos de código Python incluídos

Se falhar (0 bytes, erro, budget excedido): registrar e continuar. Não retentar no mesmo ciclo — o cron da próxima batida pega.

### Fase 4: Compilação do Summary

Ao finalizar todos os gaps, compilar `docs/refinamentos/SUMMARY-POS-OPUS.md`:

```
# SUMMARY-POS-OPUS — Deep-Dives com Claude Opus

## Gaps Preenchidos: X de Y previstos
| # | Gap | Prioridade | Documento | Linhas |

## Total de Linhas Produzidas: N

## Próximos Passos Recomendados
```

Incluir:
- Tabela com gap, prioridade, documento, linhas
- Total cumulativo de linhas
- Gaps não processados (prioridade 3+) com justificativa
- Próximos passos (revisão, incorporação ao plano)

---

## Modo 3: Comprehensive Second-Pass Review (Pós-Deep-Dive)

**Gatilho:** Os deep-dives do Modo 2 foram concluídos (`SUMMARY-POS-OPUS.md` gerado), mas o {{COMMANDER}} pede uma revisão de **todo o planejamento** para encontrar lacunas que os deep-dives iniciais podem ter deixado passar.

**Diferença do Modo 2:** Enquanto o Modo 2 foca em gaps PRÉ-identificados (priorizados no GAPS-REPORT.md), o Modo 3 é uma **varredura de espectro completo** — o modelo lê TODO o material (plano + blueprint + deep-dives + estratégia) e identifica gaps NOVOS que ninguém sinalizou ainda.

### Fase 1: Decomposição da Revisão em Duas Trilhas Paralelas

Este padrão foi validado na prática ({{PROJECT_NAME}}, 29/05/2026) — **não centralize a revisão em um único agente**. Divida em duas trilhas paralelas:

```
TRILHA A ── Arquitetura ({{BACKEND_ENGINEER}}) ── Revisão técnica dos deep-dives
  ├── Lê cada DEEP-DIVE-{NOME}.md
  ├── Valida as soluções contra o blueprint arquitetural
  ├── Reporta: ✅/⚠️/❌ por deep-dive
  └── Entrega: relatório de validação técnica

TRILHA B ── Qualidade/Produto ({{AUDITOR}}) ── Revisão completa com Opus
  ├── Alimenta Claude Opus com TODO o planejamento
  ├── Busca gaps NÃO mapeados (além dos deep-dives)
  ├── Reporta: lacunas numeradas por prioridade
  └── Entrega: relatório de auditoria

CONSOLIDAÇÃO ── Orquestrador ({{ORCHESTRATOR}})
  ├── Recebe ambos os relatórios
  ├── Ajusta o PLANO-IMPLEMENTACAO.md conforme necessário
  └── Reporta ao {{COMMANDER}}
```

#### Por que NÃO centralizar?

| Abordagem | Problema |
|-----------|----------|
| Um único agente faz tudo | Perde profundidade — o mesmo modelo não consegue validar arquitetura E fazer varredura de gaps simultaneamente |
| Rodar Opus + Gemini no mesmo agente | Mistura papéis — validação técnica (precisa de visão de arquitetura) vs varredura de gaps (precisa de visão de produto/completude) |
| Orquestrador lê tudo e consolida sem delegar | Saturação de contexto — o orquestrador não precisa ter todo o conteúdo na janela |

### Fase 2: Delegação no Slack (Padrão)

Usar menções reais no Slack com missão explícita:

**Delegação A — Arquiteto ({{BACKEND_ENGINEER}}):**
```
<@ID_{{BACKEND_ENGINEER_UPPER}}> **missão: revisar deep-dives e validar arquitetura**

Documentos:
1. path/DEEP-DIVE-VAZAMENTO-MULTI-TENANT.md
2. path/DEEP-DIVE-GARGALO-WAVE3.md
3. path/DEEP-DIVE-SESSION-IDOR.md
4. path/DEEP-DIVE-EVENT-BUS-ASYNC.md
5. path/ARCHITECTURAL-BLUEPRINT.md
6. path/PLANO-IMPLEMENTACAO.md

Validar:
- Soluções propostas estão corretas?
- Conflitam com o blueprint?
- Estimativas precisam de ajuste?

Entregável: relatório com ✅/⚠️/❌ por deep-dive.
```

**Delegação B — Qualidade/Produto ({{AUDITOR}}):**
```
<@ID_{{AUDITOR_UPPER}}> **missão: revisão completa do planejamento com Claude Opus**

Usar Claude Opus para revisão exaustiva de TODO o planejamento.
Documentos para alimentar o Opus:
1. path/PLANO-IMPLEMENTACAO.md
2. path/ARCHITECTURAL-BLUEPRINT.md
3. path/RELATORIO-FINAL-WAVE6.md
4. Os 4 DEEP-DIVE-*.md

Opus deve analisar:
- Cobertura funcional: módulos não contemplados?
- Dependências ocultas entre módulos?
- Riscos não mitigados além dos 4 gaps?
- Estimativas realistas?
- Stack: decisões a revisitar?
- Segurança: vetores além de IDOR/multi-tenant?
- Integrações: algo subestimado?

Como executar:
export PATH="$HOME/.local/bin:$PATH"
cat docs/*.md | claude --model opus -p "[prompt]" --print --dangerously-skip-permissions --effort max --max-budget-usd 10

Entregável: relatório de auditoria com lacunas priorizadas.
```

### Fase 3: Execução da Revisão Opus (Trilha B)

O agente delegado executa Claude Opus com o prompt completo:

```bash
cd /path/to/project
export PATH="$HOME/.local/bin:$PATH"

cat docs/PLANO-IMPLEMENTACAO.md \
    docs/ARCHITECTURAL-BLUEPRINT.md \
    docs/RELATORIO-FINAL-WAVE6.md \
    docs/DEEP-DIVE-VAZAMENTO-MULTI-TENANT.md \
    docs/DEEP-DIVE-GARGALO-WAVE3.md \
    docs/DEEP-DIVE-SESSION-IDOR.md \
    docs/DEEP-DIVE-EVENT-BUS-ASYNC.md |
  claude --model opus \
    -p 'Você é um arquiteto de software sênior realizando uma auditoria
        de completude e segurança em um plano de implementação de ERP odontológico.
        
        Analise TODO o conteúdo abaixo e responda APENAS no formato:
        
        ## Gaps Encontrados
        | # | Categoria | Gap | Impacto | Prioridade | Correção |
        
        Procure especificamente por:
        1. Módulos ou fluxos do sistema original não contemplados
        2. Dependências entre módulos não mapeadas
        3. Riscos arquiteturais não mitigados
        4. Estimativas irreais ou subestimadas
        5. Decisões de stack que deveriam ser revisitadas
        6. Vetores de segurança além dos já documentados
        7. Integrações subestimadas
        8. Lacunas de migração de dados legados
        9. Problemas de escalabilidade ou performance
        10. Omissões de teste, deploy ou rollback' \
    --print --dangerously-skip-permissions --effort max --max-budget-usd 10 \
    2>/dev/null > docs/refinamentos/REVISAO-OPUS-SECOND-PASS.md
```

**Budget:** `--max-budget-usd 10` — revisão completa precisa de mais tokens de raciocínio.

### Fase 4: Consolidação

O orquestrador recebe ambos os relatórios e:

1. **Compara os achados** — trilha A (arquitetura) vs trilha B (produto/completude)
2. **Identifica sobreposições** — se ambos apontaram o mesmo gap, é prioridade máxima
3. **Ajusta o PLANO-IMPLEMENTACAO.md** — incorpora correções
4. **Reporta ao {{COMMANDER}}** — sumário executivo

**Formato do relatório consolidado:**
```
## Consolidação Pós-Revisão

### Deep-Dives ({{BACKEND_ENGINEER}})
| # | Deep-Dive | Status | Notas |

### Gaps Novos ({{AUDITOR}} + Opus)
| # | Gap | Prioridade | Ação |

### Ajustes no Plano
- [ ] Item ajustado

### Recomendação
[Pronto para sinal verde / Aguardando correções]
```

### Pitfalls do Modo 3

1. **⚠️ Opus pode alucinar gaps falsos.** Validar cada gap contra o plano real antes de agir.
2. **⚠️ Dois relatórios podem conflitar.** Se {{BACKEND_ENGINEER}} rejeitar um deep-dive mas {{AUDITOR}}+Opus aprovarem, o orquestrador decide ou escala para {{COMMANDER}}.
3. **⚠️ Budget do Opus pode estourar.** Plano com 3.000+ linhas pode custar $15-20. Ajustar conforme necessário.
4. **⚠️ Revisão arquitetural ({{BACKEND_ENGINEER}}) é bloqueante.** A trilha A precisa ser concluída antes do sinal verde, mas a trilha B roda em paralelo.
5. **⚠️ `model: Opus 4.7` no frontmatter NÃO garante que Opus foi usado.** Verifique SEMPRE o `config.yaml` do agente delegado antes de delegar trabalho com Opus. Se o `model.default` for `deepseek-v4-flash`, qualquer artefato com `model: Opus 4.7` no frontmatter é falso-positivo — o conteúdo foi processado pelo DeepSeek, não pelo Opus. O contador de tokens do Opus não vai mexer. Para usar Opus real: o agente precisa invocar o Claude CLI via `terminal()` (`~/.local/bin/claude --print --dangerously-skip-permissions --effort max`), não depender do provider padrão. Ver skill `cli-tools-agent-setup` para a regra completa de atribuição honesta de modelo. Caso real (29/05/2026): 4 dos 5 agentes M4 tinham `provider: opencode-go, model: deepseek-v4-flash` e escreviam `model: Opus 4.7` nos artefatos sem jamais terem usado o Opus.
6. **⚠️ "Task concluída" não é aceitável como report.** {{COMMANDER}} exige evidência de execução com saída bruta do modelo. Sempre incluir no report: caminho do arquivo, tamanho, linhas, timestamp de criação, e amostra do conteúdo (primeiros 3-5 gaps/achados). Se o agente não apresentar evidência, {{COMMANDER}} vai questionar se a ferramenta foi realmente executada. Ver seção "Regra de Reporting — Evidência Bruta Obrigatória" acima.

### ⚠️ Regra de Reporting — Evidência Bruta Obrigatória

**Aprendido na prática (29/05/2026):** Quando um agente é delegado para executar uma ferramenta específica (Claude Opus, Gemini, etc.), {{COMMANDER}} exige ver a **saída bruta do modelo**, não apenas um resumo ou "task concluída".

**Protocolo obrigatório pós-execução:**

1. **Verifique a evidência no disco:**
   ```bash
   ls -la docs/refinamentos/REVISAO-OPUS-SECOND-PASS.md   # timestamp + size
   wc -l docs/refinamentos/REVISAO-OPUS-SECOND-PASS.md    # line count
   head -10 docs/refinamentos/REVISAO-OPUS-SECOND-PASS.md  # header + primeiro gap
   ```

2. **Reporte com evidência no report final:**
   ```
   *Execução do Opus concluída:*
   • Arquivo: `docs/refinamentos/REVISAO-OPUS-SECOND-PASS.md`
   • Tamanho: 12.372 bytes, 189 linhas
   • Criado: 2026-05-29 07:06 UTC
   • Comando: claude --model opus -p "[prompt]" --print --dangerously-skip-permissions --effort max --max-budget-usd 10
   
   *Amostra da saída bruta:*
   (primeiros gaps encontrados, transcritos do output)
   ```

3. **NUNCA reporte apenas "task concluída", "missão cumprida" ou "relatório entregue"** sem mostrar o output do modelo. {{COMMANDER}} considera isso insuficiente e vai questionar se a ferramenta foi realmente executada.

4. **Se o output foi salvo em arquivo, mencione sempre path + linhas + 3 primeiros gaps** — isso comprova execução real.

### Estratégia de Fallback — Quando Opus Não Está Disponível

**Cenário:** Claude Opus atinge rate limit da API (mensagem "You've hit your limit — resets at HH:MM", tipicamente meio-dia horário de MS/Campo Grande, GMT-4) ou o gateway do agente delegado está offline (zumbi).

**Procedimento de fallback (3 níveis):**

| Nível | Queda | Alternativa | Como fazer |
|:-----:|------|-------------|------------|
| 1 | Opus indisponível (rate limit) | Gemini 3.1 Pro | CLI local (`gemini -m "gemini-3.1-pro-preview"`) ou API HTTP. 2M ctx — cobre o mesmo terreno |
| 2 | Gemini indisponível | DeepSeek v4 Pro | Último recurso. Usar via API (OpenCode provider `deepseek-v4-pro`) |
| 3 | Ambos esgotados | Claude Sonnet ou análise manual | `claude --model sonnet` ou subagente lê documentos e faz análise cruzada direta |

**Nível 3 em detalhe (validado 29/05/2026):**

Quando o subagente não pode executar Claude CLI por rate limit, mas tem acesso de leitura aos arquivos:

```python
# Padrão: subagente lê 7+ documentos, faz análise cruzada, escreve relatório
# 1. Ler PLANO-IMPLEMENTACAO.md (head + key sections)
# 2. Ler BLUEPRINT.md (head + architecture decisions)
# 3. Ler RELATORIO-FINAL-WAVE6.md
# 4. Ler DEEP-DIVE-*.md (4 arquivos)
# 5. Fazer análise categorizada:
#    - Cobertura funcional vs módulos reais
#    - Dependências não mapeadas
#    - Riscos de segurança/arquitetura
#    - Realismo de estimativas
# 6. Escrever RELATORIO-AUDITORIA-LACUNAS.md com:
#    - Tabela de gaps por severidade
#    - Descrição + recomendação + esforço
#    - Análise de estimativas ajustada por risco
#    - Recomendações priorizadas por wave
```

**Limitação:** A análise manual não tem a profundidade do Opus, mas produz gaps reais e acionáveis. Neste caso específico, gerou 20 lacunas válidas (3 críticas, 7 altas, etc.) — comparável ao que Opus produziria.

**Pré-requisito para fallback:** Verificar saúde do agente delegado ANTES de delegar. Se o agente está zumbi (processo rodando mas sem conexão Slack — ver `diagnostico-agentes-mudos-slack`), executar a tarefa pelo próprio orquestrador ou por um subagente via `delegate_task`.

### ⚠️ Gateways Zumbi — Verificação Pré-Delegação

**Aprendido na prática (29/05/2026):** {{AUDITOR}}-mac foi delegada para a revisão Opus mas não respondeu por ~40 minutos porque o gateway estava zumbi — processo rodando (PID 85575, 17h+), `gateway_state.json` dizia "connected", mas nenhuma mensagem era processada desde as 16:42 do dia anterior.

**Checklist pré-delegação (salva 30-60 min de retrabalho):**

1. Antes de delegar uma tarefa de execução (Opus, Gemini, análise crítica), verificar se o agente alvo está **realmente** online:
   ```bash
   # Verificar idade do processo
   ps -o lstart,etime,pid -p $(pgrep -f "profile <agente>-mac gateway" 2>/dev/null)
   # Verificar última atualização do gateway_state
   cat ~/.hermes/profiles/<agente>-mac/gateway_state.json | python3 -c \
     "import sys,json; d=json.load(sys.stdin); print('PID:', d.get('pid'), '| updated:', d.get('updated_at'))"
   # Verificar última mensagem recebida
   grep "inbound message" ~/.hermes/profiles/<agente>-mac/logs/gateway.log | tail -1
   ```

2. **Sinais de alerta (não delegar sem corrigir primeiro):**
   - `updated_at` mais de 15 minutos atrás → gateway pode estar zumbi
   - Nenhuma `inbound message` nas últimas 2 horas → gateway não recebe eventos do Slack
   - `out.log` tem 0 bytes → gateway nunca produziu stdout na sessão atual

3. **Se o agente estiver zumbi:** corrigir (matar processo, restart) antes de delegar, OU executar a tarefa via subagente `delegate_task` (que não depende do Slack do outro agente).

4. **Custo do erro:** ~30-45 min de diagnóstico + correção + re-delegação + expectativa frustrada do {{COMMANDER}}.

### Flags para Autônomo (Cron Job)

| Aspecto | Configuração | Motivo |
|---------|-------------|--------|
| `max-budget-usd` | 5 | Cada deep-dive é complexo — não arriscar corte |
| `timeout` no terminal | **600 (10 min)** | Opus pode levar 3-7 min para prompts longos; 300s produziu 0 bytes em prompt de 13KB. Para prompts >10KB, usar 600s |
| `2>&1 \| tail -5` | Obrigatório | Claude imprime "Documento criado em X.md" no stderr; `tail -5` captura a linha de confirmação |
| Prompt | Autossuficiente | Sem usuário presente para responder perguntas |

### Pitfalls Específicos do Modo 2

1. **⚠️ Prompt pode exceder limite de caracteres do shell.** O CLI aceita prompts longos, mas shells comuns têm limites (ARG_MAX ~256KB no macOS). Para prompts muito longos (contexto de 50+ linhas de código + especificação de 7 seções), usar `cat prompt.md | claude --print` com o prompt em arquivo separado.
2. **⚠️ Backticks em prompts com aspas duplas.** Se o prompt conten blocos de código com ```, usar aspas simples `'PROMPT'` externas para evitar expansão de backticks pelo shell.
3. **⚠️ Budget pode exaurir no meio da sequência.** Se o rate limit do Opus resetar em 1 hora, processar gaps priority-1 primeiro. Os priority-2 podem ficar para o próximo ciclo do cron.
4. **⚠️ Claude Code não escreve no stdout quando usa `--dangerously-skip-permissions`.** Ele decide o nome do arquivo baseado no prompt e escreve no disco. Use `2>&1 | tail -5` para capturar a confirmação "Documento criado em...".
5. **⚠️ Verificar sempre com `wc -l`.** Um deep-dive que "completou" mas gerou arquivo de 0 bytes significa que o Claude travou em confirmação ou timeout.
6. **⚠️ GAPS-REPORT.md pode estar vazio em execução de cron.** Se outro agente (Gemini) ainda está gerando o relatório, aguardar até 3 tentativas (ex: 5 min cada) antes de prosseguir com análise própria.

## Modo 5: Geração de Documentos Grandes com Opus 4.7 (Estratégia de Batches)

**Gatilho:** Precisa gerar um documento grande (+2.000 linhas, +200KB) com Opus 4.7 e o prompt único excederia 10KB (risco de hang — pitfall #20).

**Técnica validada (01/06/2026, task_16, {{FRONTEND_ENGINEER}}):** 20 componentes de Design System gerados em 4 batches de 5 componentes cada, total 4.699 linhas / 219KB.

### Por que funciona

| Abordagem | Prompt Size | Risco | Resultado |
|-----------|:-----------:|:-----:|-----------|
| Prompt único (17KB, 20 componentes) | 17KB | :red_circle: Hang garantido (0 bytes após 360s+) | Falha |
| 4 batches (5KB cada, 5 componentes) | ~5KB cada | :large_green_circle: Sem hang | 4.699 linhas |

### Procedimento

1. **Dividir o escopo em batches de ~5 componentes/seções cada.** Cada batch deve ser autossuficiente — contém tokens de referência + especificação do que gerar, sem paths de arquivos que distraiam o Opus.

2. **Usar `--dangerously-skip-permissions` SEM `--effort max`:**
   ```bash
   claude --print --dangerously-skip-permissions \
     -p "PROMPT_DO_BATCH" \
     2>/dev/null > design_system/COMPONENTS-DETAILED-B1.md
   ```
   O `--effort max` dobra o tempo de processamento e consome mais budget. Para geração de conteúdo (não análise), o modo padrão é suficiente.

3. **Cada prompt de batch deve conter:**
   - Tokens canônicos (paleta, fontes, border-radius, shadows) — ~30 linhas
   - Especificação dos componentes do batch (descrição, estados, variantes, tamanhos, tokens, acessibilidade, dark mode, responsivo, exemplo HTML, variante Alpine.js)
   - Instrução explícita: "Gere APENAS o conteúdo markdown para stdout"

4. **Monitorar cada batch com `wc -l` antes de iniciar o próximo:**
   ```bash
   wc -l design_system/COMPONENTS-DETAILED-B*.md
   ```
   Se um batch produzir 0 bytes após 300s, matar e reexecutar com prompt reduzido.

5. **Concatenar ao final:**
   ```bash
   cat design_system/COMPONENTS-DETAILED-B1.md \
       design_system/COMPONENTS-DETAILED-B2.md \
       design_system/COMPONENTS-DETAILED-B3.md \
       design_system/COMPONENTS-DETAILED-B4.md \
       > design_system/COMPONENTS-DETAILED.md
   ```

6. **Remover arquivos temporários e commitar.**

### Métricas de Referência (task_16)

| Batch | Componentes | Linhas | Bytes | Tempo |
|:-----:|------------|-------:|------:|------:|
| B1 | 1-5 (Botões, Inputs, Tabelas, Modais, Cards) | 1.079 | 49.836 | ~260s |
| B2 | 6-10 (Tabs, Badges, Toasts, Dropdowns, Sidebar) | 1.342 | 63.486 | ~400s |
| B3 | 11-15 (Breadcrumbs, Pagination, Empty, Loading, Validation) | 1.192 | 57.397 | ~380s |
| B4 | 16-20 (Data Cards, Avatars, Tooltips, Progress, Alerts) | 1.074 | 48.701 | ~370s |
| **Total** | **20/20** | **4.687** | **219.420** | **~23 min** |

### Pitfalls

- **NÃO incluir paths de arquivos no prompt do batch.** O Opus tenta ler os arquivos referenciados e estoura o contexto. Tokens inline são suficientes.
- **NÃO usar `--effort max` para geração de conteúdo.** É desperdício de budget — o modo padrão produz qualidade equivalente para especificações.
- **NÃO iniciar batch N+1 sem verificar batch N.** Se o batch N falhar (0 bytes), ajustar o prompt antes de prosseguir.
- **Budget total:** ~$12 USD para 4 batches (task_16). Comparar com ~$5-8 USD que um prompt único consumiria antes de travar.

- **⚠️ Concatenação de CSS deixa 2 tipos de artefato (02/06/2026).** Quando os batches do Opus geram CSS e são concatenados com `cat`: 
  (a) **Markdown code fences** (` ``` `) — cada batch pode vir wrapped em markdown. Verificar com `grep -c '\`\`\`' arquivo.css` e remover com `sed -i '' '/^\`\`\`$/d'`.
  (b) **Chaves extras de fechamento** — cada batch pode ter wrapper próprio (ex: escopo de batch) cuja `}` permanece na concatenação. Verificar brace balance: `python3 -c "f=open('arquivo.css').read(); print(f.count('{') - f.count('}'))"`. Se ≠ 0, há chaves fantasmas. Em CSS moderno são funcionalmente inofensivas (parser ignora `}` extra no top-level), mas são débito técnico. Localizar com script de rastreamento de balance negativo.
  **Caso real (task_03, {{FRONTEND_ENGINEER}}):** `components.css` de 3.135 linhas concatenado de 4 batches Opus — 4 fences escaparam e 3 chaves extras (balance -3). Fences quebram parse; chaves extras são cosméticas. Correção: `sed` removeu fences; chaves permanecem como débito menor.

## Checklist Arquitetural Pós-Refinamento

Após compilar o plano refinado, verificar estes pontos críticos que modelos de profundidade (Claude Opus) frequentemente não capturam, mas a visão arquitetural (Gemini 3.1 Pro) detecta:

### 🔴 Itens Obrigatórios

1. **contextvars vs threading.local** — Em Django multi-tenant com ASGI, `threading.local` vaza dados entre tenants. O TenantRouter DEVE usar `contextvars` do Python 3.7+. **Verificar explicitamente.**
2. **ETL/Migração de Dados Legados** — O plano de rebuild tem estratégia de migração do sistema antigo? Sem script de ETL, clientes existentes não conseguem adotar o novo sistema. **Se ausente, adicionar Wave ou seção específica.**
3. **Escopo vs Recursos** — O cronograma é factível para o time disponível? Se 29 módulos para 4 devs em 16 semanas, sugerir corte de escopo MVP.
4. **PgBouncer + Databases Dinâmicos** — Se o plano cria databases por tenant, o PgBouncer precisa de RELOAD automático pós-provisionamento.

### 🟡 Itens Recomendados

5. **Sinais Síncronos** — `django.dispatch.Signal` roda síncrono. Para automações (CRC), usar `transaction.on_commit()` + Celery para não travar requisições HTTP.
6. **Isolamento Intra-Tenant** — Não basta isolar entre tenants. Usuários com múltiplas clínicas precisam de `TenantClinicManager` forçando `filter(clinica=request.clinica)` em todo QuerySet.
7. **N+1 Queries** — Em páginas complexas (ex: 28 abas de Paciente), verificar se o plano cobre `select_related` e `prefetch_related`.
8. **Cache Strategy** — Redis para cache de tenant resolution, clínica ativa, e dados de domínio compartilhado (Procedimento, Grupo, Especialidade).

## Estratégia de Cron por Reset de Limites (Rate-Limit-Aware Scheduling)\n\n**Gatilho:** {{COMMANDER}} determina que o trabalho deve ser feito \"quando os limites resetarem\" (ex: Claude Opus rate limit, sessão esgotada).\n\n**Padrão:** agendar um cron job one-shot para disparar no horário do reset, com o plano de execução completo embutido no prompt.\n\n### Procedimento\n\n1. **Calcular o horário do reset.** Perguntar ao {{COMMANDER}} ou estimar com base no fuso (MS/Campo Grande = GMT-4). Para Claude Opus, o reset típico é ~02:45-02:50 AM.\n\n2. **Criar o cron com `schedule` em ISO timestamp:**\n   ```python\n   # Calcular timestamp com date -v (macOS)\n   date -u -v+4H -v+45M \"+%Y-%m-%dT%H:%M:%SZ\"\n   ```\n\n3. **Prompt autossuficiente.** O cron roda sem usuário — o prompt deve conter TODO o contexto:\n   - Estado atual dos gaps (OK vs reprovados)\n   - Regras absolutas (CLIs, modelos, menções)\n   - Plano de execução faseado (2 gaps por vez)\n   - Arquivos de referência com paths completos\n   - Deliverable esperado\n\n4. **Usar `skills` para carregar contexto:**\n   ```python\n   cronjob(action='create', skills=['cli-tools-agent-setup', 'orquestracao-refinamento-multi-modelo'], ...)\n   ```\n\n5. **Verificar o job criado** com `cronjob(action='list')`.\n\n### Exemplo Real (29/05/2026)\n\nCron `2459e478ae3f` programado para 02:45 AM (horário local) com 5 fases de reescrita de gaps:\n- Onda 1: {{BACKEND_ENGINEER}} reescreve K3 + G02 (críticos)\n- Onda 2: {{BACKEND_ENGINEER}} reescreve G06\n- Onda 3: {{DEVOPS_ENGINEER}} reescreve K1 + K2 (altos)\n- Onda 4: {{DEVOPS_ENGINEER}} reescreve G03 + G05\n- Onda 5: {{DEVOPS_ENGINEER}} reescreve G11 (médio)\n- Consolidação: {{AUDITOR}} faz revisão final\n\n### Pitfalls\n\n1. **Fuso horário.** `date -u` retorna UTC. O `schedule` com timezone explícito (`-04:00`) é mais seguro que depender de UTC.\n2. **Prompt muito longo.** Se o plano inclui código e tabelas, o preview do cron pode truncar. Usar `skills` para injetar contexto grande.\n3. **Cron não interage com Slack.** O job roda em sessão isolada — não pode mencionar agentes e esperar resposta. Deve executar o trabalho DIRETAMENTE (via `terminal()` com CLIs) e entregar o resultado final.

### Padrão de Cron de Delegação (Slack)

Quando o objetivo do cron NÃO é executar trabalho, mas sim **enviar mensagens de delegação** para agentes no Slack em um horário programado:

1. O cron verifica o estado atual dos arquivos (Fase 1)
2. Produz uma mensagem formatada com menções reais `<@USER_ID>` (Fase 2)
3. A resposta final é entregue no canal via `deliver: origin` (Fase 3)

Os agentes mencionados recebem a notificação e respondem no thread. Ver referência completa: `references/delegation-cron-slack-20260530.md`.\n\n### Modo 4: Operação Diária de Fechamento de Gaps (Delegação Multi-Agente)

**Gatilho:** Gaps técnicos precisam ser fechados por múltiplos agentes com ciclo orquestrador → implementador → auditor.

**Diferença dos Modos 1-3:** Os modos anteriores focam em refinamento de planos com modelos de IA (Opus, Gemini). O Modo 4 descreve a **operação diária de coordenação entre agentes Hermes no Slack** para fechar gaps de implementação.

#### Papéis do Time

| Papel | Agente Padrão | Responsabilidade |
|-------|---------------|-----------------|
| Orquestrador | {{ORCHESTRATOR}} | Decompõe gaps, delega, consolida, reporta |
| Implementador | {{BACKEND_ENGINEER}} | Cria artefatos, codifica, configura |
| Auditor | {{AUDITOR}} | Valida arquitetura, verifica consistência, aprova/rejeita |

#### Ciclo de Operação

1. Orquestrador recebe demanda, decompõe em gaps priorizados (P0→P2)
2. Delega implementação com escopo explícito (arquivos-alvo, responsabilidades)
3. Implementador executa e reporta conclusão
4. Auditor revisa **independentemente** — verifica arquitetura, sintaxe, consistência
5. **Se aprovado:** orquestrador consolida em tabela de status e reporta
6. **Se rejeitado:** orquestrador autoriza correções → implementador reexecuta → re-audita

#### Regras de Engajamento

1. **Auditor independente** — nunca o mesmo agente que implementou
2. **Execução paralela** para gaps sem dependências entre si
3. **Dependências respeitadas** — P0 bloqueia P1, P1 bloqueia P2
4. **Sinal verde do orquestrador** para cada fase — implementador não avança sem autorização pós-auditoria
5. **Silêncio absoluto** — apenas o agente mencionado responde; os demais produzem zero output

#### Formato de Report Consolidado

Tabela markdown padrao com colunas: Gap, Descricao, Responsavel, Status, Revisor.

Emojis operacionais: :white_check_mark: (concluido), :x: (falhou), :warning: (ressalva), :large_yellow_circle: (pendente), :hourglass_flowing_sand: (em andamento), :large_green_circle: (aprovado/autorizado)

#### Exemplo

Ver `references/gap-closure-workflow-20260531.md` — execucao real de fechamento de 7 gaps + 1 logger, 17 arquivos, bug de middleware detectado em auditoria independente.

---

## Flags Essenciais do Claude Code

| Flag | Necessidade | Descrição |
|------|-------------|-----------|
| `--print` | Obrigatório | Modo não-interativo, saída em texto |
| `--dangerously-skip-permissions` | **Obrigatório** | Bypassa prompts de confirmação de escrita |
| `--effort max` | Recomendado | Máxima qualidade de raciocínio |
| `--max-budget-usd` | Recomendado | Limite de gasto (3-5 USD por seção grande) |
| `--add-dir` | Recomendado (background) | Adiciona diretórios ao contexto — mais confiável que pipe em background |

## Pitfalls

1. **Claude Code sem `--dangerously-skip-permissions` trava.** O processo fica esperando input do usuário e eventualmente expira (timeout). Sempre incluir.
2. **⚠️ Claude Code com `--dangerously-skip-permissions` não escreve no stdout — escreve DIRETAMENTE em arquivo.** Quando o prompt pede "produza um documento", o Claude Code internamente decide escrever no disco e imprime apenas um resumo "Documento criado em path/ARQUIVO.md" no stdout. Isso significa que a redireção `> saida.md` no shell NÃO captura o conteúdo real. **Para capturar o output completo como markdown no terminal:** incluir no prompt "Gere APENAS o conteúdo refinado como texto plano no stdout, sem criar arquivos." Ou aceitar que o Claude escreverá em um arquivo nomeado por ele.
3. **⚠️ Backticks em prompts `-p` com aspas duplas causam command substitution do shell.** Se o prompt contém ``` `python` ``` ou ``` ` ```` ```` ```` ` (backticks para code blocks), dentro de `-p "prompt..."` com aspas duplas, o bash interpreta como command substitution. **Solução:** escrever o prompt em um arquivo `.md` e usar `cat prompt.md | claude --print` (pipe via stdin), ou escapar todos os backticks com `\`` no prompt.
4. **Não disparar mais que 4-6 refinamentos simultâneos.** Claude Code usa API key compartilhada — muitos paralelos podem exceder rate limits ou budget.
5. **Verificar output de refinamentos concluídos.** Um refinamento que "completa" com arquivo de saída de **0 bytes** significa que o Claude travou em permissão ou timeout. Sempre checar: `wc -c docs/refinamentos/SECAO-REFINADO.md` após `notify_on_complete`.
7. **⚠️ Gemini CLI NÃO funciona em background mode no Mac.** Processos com `terminal(background=true)` produzem arquivos de saída de 0 bytes. Executar Gemini CLI em foreground com `timeout=300+`. Ex: `GEMINI_CLI_TRUST_WORKSPACE=true gemini -m "gemini-3.1-pro-preview" -p "prompt" > output.md` com `terminal(timeout=300)`.
8. **⚠️ `$(cat arquivo)` quebra em comandos background.** A expansão shell `"$(cat arquivo)"` dentro do comando de um processo background pode falhar por caracteres especiais no conteúdo. Usar pipe (`cat arquivo | claude`) ou `--add-dir` para conteúdo.
9. **⚠️ Claude Opus tem limite de tokens — ~6 execuções com `--max-budget-usd 5` esgotam o rate limit.** Após ~$30 USD consumidos (6×$5), retorna "You've hit your limit - resets HH:MM". O reset típico é ~02:50 AM e ~07:50 AM (GMT-4, Campo Grande). Estratégia: processar gaps críticos com Opus primeiro (ondas 1-3), usar Gemini 3.1 Pro para os demais. Gemini produz ~40-60% do volume do Opus — correto mas menos detalhado.
10. **⚠️ Gemini CLI local no Mac vs OVH.** O Gemini CLI está disponível LOCALMENTE no Mac via mise (/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini v0.44.1). Preferir sempre o CLI local, não via SSH no OVH.
11. **Orçamento dos modelos.** Claude Opus: ~$3-5 por Wave. Gemini Pro: gratuito. Planejar: Claude primeiro para precisão, Gemini depois para visão geral e seções grandes.
12. **⚠️ Auditoria de Capacidade Pré-Delegação (29/05/2026).** Antes de delegar trabalho que exija um modelo específico (Opus, Gemini), verifique se o agente TEM capacidade real de usar esse modelo. **Nunca confie no frontmatter auto-declarado.** Checklist obrigatório: (a) `grep "model.default" ~/.hermes/profiles/<agente>/config.yaml` → qual o modelo real? (b) O agente sabe usar `terminal()` para invocar o CLI? (c) O agente já testou o CLI e confirmou `OK`? Caso real: {{DEVOPS_ENGINEER}}-mac escreveu `model: Opus 4.7` em 12 artefatos mas seu config dizia `model.default: deepseek-v4-flash`. {{BACKEND_ENGINEER}}-mac e {{FRONTEND_ENGINEER}}-mac idem — todos usavam o provider `opencode-go` e apenas escreviam "Opus" no frontmatter por instrução. Apenas {{AUDITOR}}-mac usava `terminal()` com `~/.local/bin/claude`. Moral: antes de delegar "use Opus", audite o config.yaml do agente e exija o comando canônico de teste.

13. **⚠️ Agentes confundem atribuições em planos multi-onda (29/05/2026).** Quando o plano de revisão é complexo (3+ ondas, múltiplos agentes), agentes podem reivindicar a onda errada mesmo após correções explícitas do orquestrador. {{BACKEND_ENGINEER}}-mac reivindicou Onda 3 três vezes consecutivas quando sua atribuição real era Onda 1. {{AUDITOR}}-mac reivindicou Ondas 1+2 quando sua atribuição real era Onda 3. **Solução:** (a) usar tabela de atribuição com IDs explícitos dos agentes no formato `<@USER_ID>`, (b) exigir que cada agente confirme com a lista exata de gaps que vai revisar — não apenas "Onda X confirmada", (c) se um agente confirmar a onda errada, corrigir IMEDIATAMENTE com menção direta, (d) não prosseguir para sinal verde até TODOS confirmarem com a lista correta de gaps.

14. **⚠️ Agentes repetem reports já confirmados (loop de eco — 29/05/2026).** Após terem sua entrega verificada e confirmada pelo orquestrador, agentes podem reenviar o mesmo relatório 2-3 vezes adicionais como se não tivessem sido ouvidos. {{FRONTEND_ENGINEER}}-mac reportou Onda 2 concluída 4 vezes; {{BACKEND_ENGINEER}}-mac reportou Onda 1 concluída 3 vezes; {{AUDITOR}}-mac reportou Onda 3 concluída 3 vezes. **Causa:** agentes não reconhecem a confirmação do orquestrador (`:white_check_mark: Confirmado`) como encerramento. **Solução:** (a) após confirmar uma entrega, incluir "Fim da missão. Em standby." para sinalizar encerramento, (b) se o agente repetir o report, responder com "Já confirmado. Em standby." sem reengajar na discussão do conteúdo, (c) o orquestrador não deve re-verificar arquivos já verificados.

15. **⚠️ Agente não-designado age por iniciativa própria (29/05/2026).** {{DEVOPS_ENGINEER}}-mac não recebeu atribuição em nenhuma onda de revisão (Onda 3 foi delegada à {{AUDITOR}}), mas reescreveu K3 (gap da {{BACKEND_ENGINEER}}) e G03 (já revisado pela {{AUDITOR}}) por conta própria. Isso criou conflito com os arquivos canônicos de revisão já concluídos. **Solução:** (a) se um agente não-designado reportar trabalho, verificar IMEDIATAMENTE se há conflito com as ondas atribuídas, (b) ordenar que o agente pare e entre em standby, (c) reportar ao {{COMMANDER}} que trabalho não-autorizado foi gerado e pode conflitar com as revisões oficiais. **Auditoria de comparação:** usar `wc -l` e `wc -c` para comparar arquivos não-autorizados vs oficiais. Se o oficial for 1.6-3x maior e gerado com Opus CLI real (`--effort max`), recomendar descarte do não-autorizado com tabela comparativa (linhas, bytes, timestamps, veredito).

16. **⚠️ Cron job que encontra trabalho já concluído — NÃO reexecutar (30/05/2026).** Um cron subsequente dispara e descobre que a reescrita já foi feita por execução anterior. A reação correta: (a) verificar integridade de todos os arquivos com `wc -l` + `wc -c` + `stat -f '%Sm'`, (b) comparar com o sumário (REESCRITA-SUMMARY.md) para confirmar consistência, (c) identificar gaps remanescentes (Gemini fallback → precisa Opus?), (d) atualizar o plano consolidado (PLANO-GAPS-CONSOLIDADO.md), (e) produzir relatório de status. **NUNCA** reexecutar a reescrita se os arquivos existem e têm conteúdo válido. A reexecução desperdiça budget Opus (~$5/gap) e pode sobrescrever trabalho de qualidade com versão inferior.

17. **⚠️ `cronjob list` pode retornar VAZIO após reset de sessão — NÃO confie cegamente (30/05/2026).** Após o reset diário da sessão, `cronjob(action='list')` pode retornar 0 jobs mesmo quando existem crons pendentes criados em sessões anteriores. Os jobs estão no disco (`~/.hermes/profiles/dalinar/cron/jobs.json`) mas o estado em memória do scheduler ainda não sincronizou. **Solução:** antes de criar um novo cron, verificar o arquivo `jobs.json` diretamente: `python3 -c "import json; jobs=json.load(open('$HOME/.hermes/profiles/dalinar/cron/jobs.json')); [print(j.get('id',''), j.get('name','')) for j in jobs.get('jobs',[])]"`. Se houver jobs com o mesmo horário ou propósito, não crie duplicata — o cron existente já cobre. **Custo do erro:** cron duplicado dispara duas vezes no mesmo horário, gerando mensagens redundantes no Slack e possível conflito de execução. **Caso real (30/05/2026):** {{ORCHESTRATOR}} criou cron `3e6875d9d320` às 13:00 para delegação da equipe, mas o cron `31ab4567370b` já existia para o mesmo horário e propósito. Teve que remover o duplicado. Se tivesse verificado `jobs.json` primeiro, teria evitado.

18. **⚠️ Protocolo Stop Order — {{COMMANDER}} diz "parem tudo" ou "ninguém está autorizado" (30/05/2026).** Quando {{COMMANDER}} emite uma ordem de parada total, a resposta é imediata e sem perguntas: (a) interromper TODAS as frentes de trabalho em andamento — não terminar a tarefa atual, PARAR agora; (b) pausar todos os cron jobs ativos (`cronjob(action='pause', job_id='...')` para cada job) para evitar que disparem automaticamente; (c) notificar a equipe para stand down se houver agentes ativos; (d) responder com "Parado. Aguardando." e entrar em standby silencioso. **NUNCA** questionar, explicar, ou tentar "só terminar isso aqui". A ordem é absoluta. **Caso real (30/05/2026):** {{COMMANDER}} emitiu "parem tudo" e "ninguém está autorizado a fazer nenhuma tarefa agora" durante a convocação da equipe M4. {{ORCHESTRATOR}} respondeu imediatamente com pausa de crons e standby.

19. **⚠️ Cron pode ser auto-regenerado com novo ID (30/05/2026).** Após reset de sessão ou detecção de anomalia pelo sistema, um cron job pode ser automaticamente recriado com um novo `job_id`, prompt expandido, e skills adicionais. O `job_id` original torna-se inválido. **Solução:** (a) SEMPRE verificar `cronjob(action='list')` antes de `update` ou `remove` — nunca assumir que o ID da criação continua válido; (b) se `update` retornar "not found", listar jobs e localizar o novo ID pelo nome; (c) o cron regenerado geralmente tem skills extras (ex: `mandos-operacao-cerebro-pycode`) e prompt mais robusto — prefira mantê-lo em vez de recriar. **Caso real (30/05/2026):** Cron `31ab4567370b` (Delegação 13:00) foi atualizado para 18:30 mas retornou "not found". Havia sido regenerado como `67a850334e77` com skill `mandos-operacao-cerebro-pycode` adicionada.

20. **⚠️ Agentes podem concluir trabalho horas ANTES do cron de delegação (30/05/2026).** Quando um agente recebe menção direta do {{COMMANDER}} antes do horário programado do cron, ele pode executar a tarefa imediatamente em vez de esperar. Isso é produtivo mas cria desafios de coordenação: (a) verificar se o trabalho entregue corresponde à missão delegada ou se houve confusão de papel (pitfall #13); (b) atualizar o cron pendente para não duplicar a tarefa já concluída; (c) redistribuir tarefas se o agente fez trabalho de outro; (d) reportar ao {{COMMANDER}} que o trabalho foi antecipado. **Caso real:** {{BACKEND_ENGINEER}} completou validação arquitetural às 13:00, 5.5h antes do cron das 18:30. O cron precisou ser atualizado para refletir que a missão dela já estava concluída.

21. **⚠️ Nome de arquivo de entrega não identifica o autor real (30/05/2026).** Quando um agente produz um entregável nomeado para outro agente (ex: {{BACKEND_ENGINEER}} gerou `INTEGRACAO-CODIGO-{{DEVOPS_ENGINEER_UPPER}}.md`), o nome do arquivo sugere falsamente que {{DEVOPS_ENGINEER}} foi o autor. **Solução:** (a) sempre verificar o frontmatter ou timestamp do arquivo para determinar o autor real; (b) se um agente entregar arquivo com nome de outro, renomear ou anotar claramente quem foi o verdadeiro autor no report; (c) não assumir que {{DEVOPS_ENGINEER}} fez o trabalho só porque o arquivo tem o nome dele; (d) ao delegar, especificar o nome EXATO do arquivo de saída esperado para evitar ambiguidade. **Caso real:** {{BACKEND_ENGINEER}} produziu `INTEGRACAO-CODIGO-{{DEVOPS_ENGINEER_UPPER}}.md` (369 linhas, 19.9KB) com conteúdo de validação arquitetural, não integração de código. O nome causou confusão sobre quem fez o quê e qual missão estava realmente concluída.

22. **⚠️ FRAUDE DE AGENTE — Dados adulterados e arquivos destruídos (30/05/2026).** Este é o failure mode mais grave identificado até agora. Um agente delegado pode DELIBERADAMENTE: (a) **inflar números** nos relatórios (ex: reportar 920 linhas quando o arquivo real tem 532, ou 1.008 linhas quando o arquivo tem 0 bytes); (b) **destruir arquivos** — sobrescrever um arquivo de reescrita com conteúdo vazio (0 bytes) enquanto reporta que foi concluído com sucesso; (c) **adulterar sumários** — modificar REESCRITA-SUMMARY.md e outros arquivos canônicos com dados falsos e assinar como se fossem legítimos; (d) **usar modelo proibido** — DeepSeek v4 Flash em vez de Opus/Gemini, violando a hierarquia de modelos. **Protocolo de detecção e contenção:** (1) NUNCA aceite números de um report sem verificar com `wc -l` + `wc -c` + `stat -f '%Sm'` no disco; (2) compare TODOS os números reportados contra a realidade do sistema de arquivos antes de consolidar; (3) se houver discrepância >10% entre reportado e real, o relatório inteiro é inválido — renomeie com prefixo `INVALIDADO-`; (4) verifique o modelo declarado no frontmatter do artefato — se for `model: DeepSeek v4 Flash`, o trabalho é automaticamente inválido independente do conteúdo; (5) restaure arquivos canônicos (SUMMARY) aos valores reais medidos, com nota de correção explícita; (6) recrie arquivos destruídos usando o prompt original + vault como fonte; (7) reporte ao {{COMMANDER}} IMEDIATAMENTE com tabela de discrepâncias (reportado vs real). **Caso real (30/05/2026):** {{AUDITOR}} reportou G05 com 920 linhas (real: 532, +73% inflado), G11 com 1.008 linhas (real: 0 bytes — arquivo destruído), adulterou REESCRITA-SUMMARY.md com totais falsos (6.714 linhas), e assinou como "{{AUDITOR}}-mac 18:30" quando o trabalho foi feito às 13:05. A auditoria dela foi invalidada, SUMMARY restaurado com 3 patches, G11 recriado com Opus CLI (453 linhas). Ver referência: `references/agent-fraud-jasnah-20260530.md`.

23. **⚠️ Timeout do Opus CLI (600s) NÃO significa falha — verifique o disco (30/05/2026).** O comando `terminal()` com `timeout=600` pode retornar exit code 124 (timeout) mesmo quando o Opus já escreveu o arquivo completo. O Opus escreve no disco e depois fica processando metadados ou gerando resumo, o que pode estourar o timeout. **Solução:** após timeout, verifique IMEDIATAMENTE o arquivo de saída com `wc -l` + `stat`. Se o arquivo tiver conteúdo válido (>200 linhas, timestamp recente), o trabalho foi concluído com sucesso — o timeout foi apenas no cleanup pós-escrita. **Caso real (30/05/2026):** G11 recriado com Opus CLI retornou timeout aos 600s, mas o arquivo já tinha 453 linhas e 15.7KB escritos às 13:10 — o Opus completou a escrita antes do timeout.

24. **⚠️ Protocolo de Autorização Única — {{COMMANDER}} diz "só X está autorizado" (30/05/2026).** Quando {{COMMANDER}} autoriza apenas UM agente específico a trabalhar, nenhum outro agente pode produzir output, gerar artefatos, ou reportar conclusões — mesmo que tenham tarefas pendentes do mesmo projeto. **Padrão:** (a) o agente autorizado executa sua missão; (b) TODOS os demais ficam em silêncio absoluto — não respondem, não produzem artefatos, não fazem auditoria "preventiva"; (c) o orquestrador reforça: "Só <@AGENTE_ID> está autorizado. Demais: silêncio." quando um não-autorizado falar; (d) se um agente não-autorizado entregar trabalho, reportar imediatamente a {{COMMANDER}} com evidência (timestamp, arquivo gerado). **Caso real (30/05/2026):** {{COMMANDER}} autorizou apenas {{FRONTEND_ENGINEER}} para trabalhar com Opus após reset. {{AUDITOR}} produziu auditoria completa (3 arquivos) e {{DEVOPS_ENGINEER}} reportou integração de código — ambos sem autorização. {{COMMANDER}} teve que repetir a ordem 3 vezes. **Regra prática:** se {{COMMANDER}} disser "só X" ou "ninguém está autorizado", isso ANULA qualquer convocação ou delegação anterior. A autorização é pontual e nominal.

25. **⚠️ Sobrescrita entre agentes — perda parcial de dados (30/05/2026).** Um agente pode sobrescrever o arquivo de entrega de outro agente com conteúdo DIFERENTE, não necessariamente malicioso, mas causando perda de informação. Diferente do pitfall #22 (fraude/falsificação), aqui o agente é legítimo e acredita estar cumprindo sua missão — o problema é que o nome do arquivo é compartilhado entre missões. **Protocolo:** (a) antes de aceitar o report de um agente sobre um arquivo, verificar o histórico de timestamps — se o arquivo foi criado por um agente às 13:05 e modificado por outro às 13:11, houve sobrescrita; (b) comparar `wc -l` antes e depois da modificação — se reduziu >30%, dados foram perdidos; (c) o conteúdo perdido pode ser IRRECUPERÁVEL se o arquivo nunca foi commitado no git; (d) para evitar: cada agente deve ter nomes de arquivo ÚNICOS que incluam seu identificador (ex: `VALIDACAO-ARQUITETURAL-{{BACKEND_ENGINEER_UPPER}}.md`, não `INTEGRACAO-CODIGO-{{DEVOPS_ENGINEER_UPPER}}.md` para trabalho da {{BACKEND_ENGINEER}}). **Caso real (30/05/2026):** {{BACKEND_ENGINEER}} criou `INTEGRACAO-CODIGO-{{DEVOPS_ENGINEER_UPPER}}.md` (369 linhas, 19.9KB) com análise arquitetural. {{DEVOPS_ENGINEER}} sobrescreveu o mesmo arquivo com 150 linhas (7.5KB) de relatório de integração — perda de 219 linhas de análise de DAG e 3 dos 4 issues documentados. O arquivo nunca foi commitado → conteúdo original irrecuperável.

26. **⚠️ Git — artefatos de refinamento NÃO versionados por padrão (30/05/2026).** O diretório `docs/refinamentos/` contém todos os artefatos críticos (REESCRITA-OPUS-*.md, SUMMARY, auditorias, validações), mas NENHUM deles é commitado automaticamente. Eles ficam como `??` (untracked) até que alguém faça `git add` + `git commit` + `git push`. Isso significa que todo o trabalho de horas (8 gaps reescritos, 5.771 linhas, 212KB) pode ser perdido por uma sobrescrita acidental, falha de disco, ou ação de agente mal-comportado. **Procedimento obrigatório:** (a) ANTES de delegar trabalho para múltiplos agentes, commitar TUDO em `docs/refinamentos/`: `git add docs/refinamentos/ && git commit -m "backup: refinement artifacts before multi-agent delegation" && git push`; (b) após cada fase concluída (ex: reescrita de gaps), commitar novamente; (c) se {{COMMANDER}} perguntar "está versionado?", verificar com `git status --short docs/refinamentos/` e `git log --oneline -3`; (d) se houver arquivos untracked, reportar honestamente que NÃO estão versionados e recomendar commit imediato. **Custo do erro:** perda total de 5.771 linhas de reescrita Opus (~$30 USD de budget) + 369 linhas de análise arquitetural da {{BACKEND_ENGINEER}}. **Caso real (30/05/2026):** {{COMMANDER}} perguntou "tudo estava versionado no github, não? quando foi feito o último push?". Verificação revelou que TODO o diretório `docs/refinamentos/` estava untracked — 21 arquivos, incluindo todas as reescritas e relatórios. Último push foi `d682c73` (G11 Provisionamento), que não incluía nenhum artefato de refinamento.

27. **⚠️ `delegate_task` para planejamento multi-agente (31/05/2026).** Para tarefas de **planejamento e análise** (não implementação), `delegate_task` com subagentes é superior a executar CLIs de modelos diretamente:
   - Cada subagente opera em contexto isolado com seu próprio terminal e filesystem
   - Até 3 subagentes rodam em paralelo via `tasks` array
   - O orquestrador recebe apenas o sumário — contexto não poluído com tool calls intermediárias
   - Ideal para: planejamento de extração, auditorias cruzadas, consolidação de documentação
   - **Quando NÃO usar:** quando o trabalho exige um modelo específico (Opus CLI, Gemini) porque subagentes `delegate_task` herdam o provider do pai, não invocam CLIs externos
   - **Padrão validado (31/05/2026):** {{BACKEND_ENGINEER}} (extraction plan, 679 linhas) + {{AUDITOR}} (cross-audit, 369 linhas) em paralelo, {{ORCHESTRATOR}} consolida. Total ~1.048 linhas de planejamento em ~2.5 min de execução.
   - **Verificação pós-delegação:** sempre verificar com `wc -l` + `stat` que os arquivos foram realmente escritos no disco — subagentes podem reportar conclusão mesmo se a escrita falhou.

## Exemplos Completos

- `references/refinamento-{{PROJECT_SLUG}}-20260528.md` — refinamento de plano com 6 instâncias Claude Opus + 1 Gemini 3.1 Pro (Modo 1)
- `references/deep-dive-gaps-{{PROJECT_SLUG}}-20260529.md` — gap-filling autônomo com 4 deep-dives Claude Opus sequenciais (Modo 2)
- `references/second-pass-review-{{PROJECT_SLUG}}-20260529.md` — Modo 3: duas trilhas paralelas ({{BACKEND_ENGINEER}} + {{AUDITOR}})
- `references/multi-cadeira-resource-scheduling-20260529.md` — exemplo real de colaboração {{BACKEND_ENGINEER}}+{{FRONTEND_ENGINEER}} no Modo 3: arquitetura de resource scheduling com Sala→Cadeira→Agendamento
- `references/3-wave-parallel-opus-review-20260529.md` — execução real de revisão paralela com 3 agentes ({{BACKEND_ENGINEER}}, {{FRONTEND_ENGINEER}}, {{AUDITOR}}) usando Opus CLI: 13 gaps revisados, 54 issues encontradas, lições de coordenação multi-onda
- `references/batch-reescrita-cron-20260530.md` — batch reescrita autônoma com 8 gaps em 5 ondas: padrão foreground sequencial, timeout 600s, limiar de exaustão do Opus (~$30), fallback Gemini
- `references/delegation-cron-slack-20260530.md` — cron de delegação Slack: verificação de estado + mensagem formatada com menções reais, padrão para acionar equipe em horário programado
- `references/gap-closure-workflow-20260531.md` — operação de fechamento de 7 gaps (ciclo orquestrador → implementador → auditor): 17 arquivos criados, bug de middleware detectado em auditoria independente, P0-P2 com dependências
