# Exemplo Real: Gap-Filling Deep-Dive — {{PROJECT_NAME}} (2026-05-29)

## Contexto
Orquestração autônoma de 4 deep-dives Claude Opus preenchendo gaps críticos do plano de implementação do ERP {{PROJECT_NAME}}.

## Gaps Processados

| Gap | Prioridade | Prompt Lines | Resultado | Linhas |
|-----|-----------|-------------|-----------|--------|
| 1.1 threading.local → contextvars | 1 | ~80 linhas | 646 linhas | 36785 bytes |
| 1.2 Gargalo Wave 3 | 1 | ~70 linhas | 401 linhas | 24115 bytes |
| 1.3 Session IDOR | 1 | ~80 linhas | 725 linhas | 27825 bytes |
| 2.1 Event Bus Síncrono | 2 | ~75 linhas | 907 linhas | 36785 bytes |

## Comando Padrão Utilizado

```bash
cd /Users/{{COMMANDER}}fae/Dev/{{PROJECT_SLUG}} && ~/.local/bin/claude \
  -p 'PROMPT_AUTOSSUFICIENTE' \
  --print --dangerously-skip-permissions --effort max --max-budget-usd 5 \
  2>&1 | tail -5
```

## Estrutura dos Prompts

Cada prompt seguiu este formato:
1. **Role**: "Você é um arquiteto de software sênior especializado em [tema]"
2. **Contexto**: Trechos reais de código do plano de implementação (blocos Python/HTML)
3. **Problema**: Descrição do gap com exemplos concretos de falha
4. **Tarefa**: 5-7 seções numeradas que o documento deve cobrir
5. **Instrução de save**: "Produza o documento DEEP-DIVE-{NOME}.md em /path/to/docs/"
6. **Restrições**: "Apenas markdown, mínimo 200 linhas, sem explicações adicionais no stdout"

## Observações Operacionais

- **Tempo médio por deep-dive**: ~2-4 minutos (Claude Opus raciocínio)
- **Budget consumido**: ~$3-5 por deep-dive (total ~$15-20)
- **Confirmação**: Claude imprime "Documento criado em `docs/DEEP-DIVE-{NOME}.md`" no stderr — capturado via `2>&1 | tail -5`
- **Verificação pós-execução**: `wc -l docs/DEEP-DIVE-*.md` confirmou todos com conteúdo > 200 linhas
- **Sequência**: Foreground síncrono (um por vez) — sem paralelismo, pois o rate limit do Opus poderia exaurir

## Summary Final

Compilado em `docs/refinamentos/SUMMARY-POS-OPUS.md` com:
- Tabela de 4 gaps × 4 documentos × 2.679 linhas totais
- Próximos passos recomendados
- Gaps não processados (prioridade 3) com justificativa
