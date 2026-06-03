# Refinamento {{PROJECT_NAME}} — 28/05/2026

## Escopo
Refinar plano de implementação do {{PROJECT_NAME}} (3.491 linhas, 8 Waves, 19 seções) para ~10K+ linhas usando Claude Opus + Gemini 3.1 Pro.

## Resultados

| Seção | Original | Refinado | Modelo | 
|-------|:--------:|:--------:|:------:|
| Wave 0 — Fundação | 198 | 2.174 | Claude Opus |
| Wave 1 — Core + Auth | 390 | 2.058 | Gemini Pro |
| Wave 2 — Design System | 349 | 415 | Gemini Pro |
| Wave 3 — Cadastros | 275 | 496 | Gemini Pro |
| Wave 4 — Agenda/Odontograma | 434 | 370 | Gemini Pro |
| Wave 5 — Financeiro | 317 | 461 | Gemini Pro |
| Wave 6-7-8 — CRC/Relatórios | 451 | 430 | Gemini Pro |
| Sec 1-2 — Estratégia | 336 | 545 | Gemini Pro |
| Sec Transversais | 1.028 | 1.971 | Gemini Pro |
| Deep-dive Odontograma | — | 2.559 | Claude Opus |
| Deep-dive ETL Migração | — | ~102KB | Claude Opus |
| Revisão Arquitetural | — | 51 (8 achados) | Gemini Pro (OVH) |

**Total: ~15.000+ linhas**

## Lições Aprendidas

### Ferramentas

1. **Claude Code com `--dangerously-skip-permissions` escreve arquivos diretamente.** Quando o prompt pede "produza um documento", o Claude Code cria o arquivo no disco e imprime apenas um resumo no stdout. `> saida.md` não captura o conteúdo real. Para capturar no stdout incluir no prompt: "Gere APENAS o conteúdo refinado como texto plano no stdout, sem criar arquivos."

2. **Backticks em `-p "prompt"` quebram o shell.** O prompt continha triplos backticks para code blocks dentro de aspas duplas do `-p`. O bash interpretou como command substitution. Solução: escrever o prompt em arquivo `.md` e usar `cat prompt.md | claude --print`.

3. **Gemini CLI requer foreground, não background.** `terminal(background=true)` produz arquivos de 0 bytes. Executar em foreground com `timeout=300`.

4. **Claude Code `--add-dir` com background é frágil.** O "no stdin data received in 3s" aparece frequentemente em background. Preferir pipe via stdin para conteúdo + foreground com timeout.

5. **Limite de tokens do Claude Opus.** ~$3-5 de budget por execução. Reset automático após ~50 min. Estratégia: Opus para seções críticas primeiro, Gemini Pro para o restante, retomar após reset.

### Correções Arquiteturais (Gemini Review)

6. **`threading.local` → `contextvars`** — TenantRouter usando `threading.local` vaza dados entre tenants em ASGI. Migrar para `contextvars`.

7. **ETL/Migração Legado ausente** — O plano original não tinha estratégia de migração de dados do Dontus (MSSQL). Showstopper para adoção por clientes existentes.

8. **CRC Signals síncronos** — `django.dispatch.Signal` roda síncrono e trava requisições HTTP. Usar `transaction.on_commit()` + Celery.

9. **PgBouncer + DB dinâmico** — Script de provisionamento precisa dar RELOAD no PgBouncer automaticamente.

10. **Escopo vs Equipe** — 29 módulos para 4 devs em 16-22 semanas é apertado. Sugerir corte de Wave 8 (LIA, Estoque, SAC) do MVP.

### Estado dos Agentes

11. **{{BACKEND_ENGINEER}}-mac com memória corrompida.** `config.yaml` tinha `bot_user_id: {{SLACK_ID_BACKEND}}` (correto) mas `memories/MEMORY.md` tinha `{{BACKEND_ENGINEER}}-mac={{SLACK_ID_OVH_ORCHESTRATOR}}` (ID do {{ORCHESTRATOR}} OVH). A memória antiga prevaleceu sobre o config correto. Fix: editar MEMORY.md, limpar state.db + sessions/, reiniciar gateway.
