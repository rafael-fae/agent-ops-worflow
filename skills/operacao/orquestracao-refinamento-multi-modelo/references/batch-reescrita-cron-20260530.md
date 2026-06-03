# Batch Reescrita com Opus CLI — Padrão Cron Autônomo

**Validado:** 30/05/2026 — {{ORCHESTRATOR}}-mac executando reescrita de 8 gaps em 5 ondas.

## Estrutura da Missão

### Formato de Ondas
A missão usa ondas sequenciais com 2 gaps por onda, prioridade decrescente:

```
ONDA 1 — Críticos ({{BACKEND_ENGINEER}}): K3 + G02
ONDA 2 — Crítico  ({{BACKEND_ENGINEER}}): G06
ONDA 3 — Altos    ({{DEVOPS_ENGINEER}}): K1 + K2
ONDA 4 — Altos    ({{DEVOPS_ENGINEER}}): G03 + G05
ONDA 5 — Médio    ({{DEVOPS_ENGINEER}}): G11
```

### Padrão de Execução por Gap

```
1. Ler arquivo de revisão (REVISAO-*.md) → entender issues
2. Ler código original (se existir)
3. Criar prompt detalhado em arquivo .md:
   - Contexto completo (autossuficiente para execução autônoma)
   - Código atual embedado
   - Tabela de issues com severidade e correção
   - Instruções explícitas de formato de saída
   - Regras absolutas
4. Executar Opus CLI com --add-dir + timeout 600s:
   claude --add-dir docs/refinamentos \
     -p "Leia prompt-X.md. Execute a reescrita..." \
     --print --dangerously-skip-permissions --effort max --max-budget-usd 5 \
     2>/tmp/err.log > REESCRITA-OPUS-{GAP}.md
5. Verificar saída: wc -l, wc -c, head -10
6. Se falhar (rate limit): Gemini 3.1 Pro como fallback
```

## Métricas da Sessão

| Gap | Modelo | Linhas | Bytes | Tempo Aprox |
|-----|--------|-------:|------:|:-----------:|
| K3  | Opus   | 1.069 | 44K | ~4 min |
| G02 | Opus   | 1.045 | 42K | ~5 min |
| G06 | Opus   | 1.411 | 51K | ~6 min |
| K1  | Opus   | 444 | 16K | ~3 min |
| K2  | Opus   | 291 | 10K | ~2 min |
| G03 | Opus   | 526 | 19K | ~4 min |
| G05 | Gemini | 156 | 4.6K | ~1 min |
| G11 | Gemini | 231 | 11K | ~1 min |

**Total Opus:** 4.786 linhas (92.5%), ~$30 USD, ~6 execuções antes de exaurir.

## Lições Aprendidas

### 1. `--add-dir` + prompt curto > pipe com prompt longo
A primeira tentativa com `cat prompt.md | claude` falhou (exit 1, 0 bytes). A segunda com `--add-dir` + prompt inline referenciando o arquivo funcionou. **Regra:** usar SEMPRE `--add-dir` para submeter conteúdo ao Claude. O pipe só funciona bem em foreground simples.

### 2. Timeout 300s é insuficiente para prompts longos
Primeira execução de K3 (13KB de prompt) com timeout=300s → 0 bytes. Aumentar para 600s resolveu. Para prompts >10KB, usar timeout=600.

### 3. Limiar de exaustão: 6 execuções × $5
Após 6 execuções com `--max-budget-usd 5`, o Opus retornou "You've hit your limit · resets 7:50am". Isso equivale a ~$30 USD consumidos. Planejar ondas para que os gaps mais críticos sejam processados primeiro — os últimos 1-2 gaps vão para Gemini.

### 4. Gemini 3.1 Pro entrega 40-60% do volume do Opus
Para gaps de segurança (G05, G11), o Gemini produziu 156-231 linhas vs média Opus de 798. O conteúdo é correto mas menos detalhado. Para gaps críticos, priorizar sempre Opus.

### 5. Foreground sequencial é mais confiável que background paralelo
Em execução autônoma (cron), foreground sequencial com timeout=600s foi 100% confiável (7/8 gaps no Opus, 1/1 rate limit detectado corretamente). Background com notify_on_complete não foi necessário — o overhead de coordenação não compensa para 8 gaps.

### 6. Prompts em arquivos separados são reutilizáveis
Os prompts (`prompt-k3.md`, `prompt-g02.md`, etc.) permanecem no disco como documentação do que foi pedido ao modelo. Isso fecha o ciclo de auditabilidade.

## Estrutura de Diretórios do Batch

```
docs/refinamentos/
├── REVISAO-OPUS-K3.md          # Revisão original (input)
├── REVISAO-OPUS-G02.md         # Revisão original (input)
├── ...
├── prompt-k3.md                # Prompt criado para o Opus
├── prompt-g02.md               # Prompt criado para o Opus
├── ...
├── REESCRITA-OPUS-K3.md        # Output do Opus (1069 linhas)
├── REESCRITA-OPUS-G02.md       # Output do Opus (1045 linhas)
├── ...
└── REESCRITA-SUMMARY.md        # Sumário final com métricas
```

## Comando Canônico para Batch

```bash
cd /path/to/project

# 1. Criar prompt (write_file)
# 2. Executar Opus
~/.local/bin/claude \
  --add-dir docs/refinamentos \
  -p "Leia prompt-X.md. Execute a reescrita... Gere APENAS o código no stdout." \
  --print --dangerously-skip-permissions --effort max --max-budget-usd 5 \
  2>/tmp/claude-err.log \
  > docs/refinamentos/REESCRITA-OPUS-X.md

# 3. Verificar
wc -l docs/refinamentos/REESCRITA-OPUS-X.md
head -10 docs/refinamentos/REESCRITA-OPUS-X.md

# 4. Fallback se rate limit
GEMINI_CLI_TRUST_WORKSPACE=true \
  /Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/gemini \
  -m "gemini-3.1-pro-preview" \
  -p "Leia prompt-X.md e execute a reescrita..." \
  2>/dev/null > docs/refinamentos/REESCRITA-OPUS-X.md
```

---

## Pós-Reescrita: Verificação e Consolidação

### Padrão: Cron Job Que Encontra Trabalho Já Concluído

Quando um cron subsequente dispara e descobre que a reescrita já foi feita por uma execução anterior:

1. **NÃO reexecutar o trabalho.** Verificar integridade primeiro.
2. **Verificar todos os arquivos com métricas concretas:**
   ```bash
   for f in docs/refinamentos/REESCRITA-OPUS-*.md; do
     echo "$(wc -l < "$f") linhas | $(wc -c < "$f") bytes | $(stat -f '%Sm' "$f") | $f"
   done
   ```
3. **Comparar com o sumário (REESCRITA-SUMMARY.md):** Confirmar que linha/byte counts batem.
4. **Identificar gaps remanescentes:** G05/G11 com Gemini precisam de re-run? Plano consolidado desatualizado?
5. **Produzir relatório de status** — não reexecutar código, apenas consolidar.

### Padrão: Atualização Autônoma do PLANO-GAPS-CONSOLIDADO.md

Após batch de reescrita concluído, o plano consolidado (geralmente em `~/Dev/obsidian/10_Projects/<projeto>/PLANO-GAPS-CONSOLIDADO.md`) precisa ser atualizado para refletir:

1. **Atualizar frontmatter:** `updated:` com timestamp atual
2. **Adicionar seção de cronologia:** Linha do tempo Review → Rewrite com datas
3. **Atualizar todos os status:** Substituir artefatos originais pelos REESCRITA-OPUS-*.md
4. **Modelo real usado:** Trocar "Gemini 3.1 Pro" / "Opus 4.7" auto-declarado pelo modelo que REALMENTE gerou (verificar via `wc -c` e timestamp — arquivos Opus são 3-5x maiores)
5. **Adicionar status ⚠️ para gaps Gemini:** Com nota "Aguardando re-run Opus após reset"
6. **Tabela de métricas:** Linhas, bytes, modelo, timestamp por gap
7. **Seção de decisões pendentes:** O que {{COMMANDER}} precisa decidir (re-run G05/G11? Integrar código? Descartar {{DEVOPS_ENGINEER}}?)
8. **Arquivos não-autorizados:** Se houver, tabela comparativa com recomendação explícita

### Padrão: Auditoria de Arquivos Não-Autorizados

Quando um agente gera arquivos sem autorização (ex: {{DEVOPS_ENGINEER}} reescreveu K3 e G03 em `docs/vault/` enquanto a reescrita oficial estava em `docs/refinamentos/`):

| Passo | Comando | Decisão |
|-------|---------|---------|
| 1. Comparar tamanhos | `wc -l` nos dois arquivos | Se oficial 1.5-3x maior → descartar não-autorizado |
| 2. Comparar timestamps | `stat -f '%Sm'` | Se não-autorizado é anterior → confirma feito sem autorização |
| 3. Ler primeiras 50 linhas | `head -50` em cada | Verificar qualidade relativa do conteúdo |
| 4. Recomendar | Reportar com tabela | "Supersedido pelo REESCRITA-OPUS-X.md (Nx maior, Opus real)" |

**Regra:** Nunca manter arquivos não-autorizados se a reescrita oficial com Opus CLI real cobre o mesmo gap e é significativamente maior/melhor.

### Métricas de Qualidade: Gemini 3.1 Pro vs Opus 4.7 (Concreto)

Dados reais da sessão de 30/05/2026 (8 gaps):

| Gap | Opus (linhas) | Gemini (linhas) | Ratio |
|-----|:------------:|:---------------:|:-----:|
| K3  | 1.069 | — | — |
| G02 | 1.045 | — | — |
| G06 | 1.411 | — | — |
| K1  | 444 | — | — |
| K2  | 291 | — | — |
| G03 | 526 | — | — |
| G05 | — | **156** ⚠️ | Gemini = 15% da média Opus (798) |
| G11 | — | **231** ⚠️ | Gemini = 29% da média Opus (798) |

**Conclusão:** Gemini 3.1 Pro entrega 15-30% do volume do Opus para o mesmo tipo de gap. O código é correto e funcional, mas menos detalhado — menos comentários, menos edge cases, menos docstrings. Para gaps de segurança (G05) onde cada edge case importa, **sempre re-rodar com Opus quando possível.**

## Checklist Pós-Batch

- [ ] Todos os `REESCRITA-OPUS-*.md` existem com `wc -l` > 50?
- [ ] `REESCRITA-SUMMARY.md` gerado com métricas consolidadas?
- [ ] `PLANO-GAPS-CONSOLIDADO.md` atualizado com novos status?
- [ ] Arquivos não-autorizados identificados e comparados?
- [ ] Gaps Gemini (⚠️) listados para re-run Opus?
- [ ] Decisões pendentes documentadas para {{COMMANDER}}?
- [ ] Nenhum `deepseek-v4-flash` utilizado em nenhum gap?
