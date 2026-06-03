---
name: correcao-fechamento-diario
description: Correção do bug de timezone no script fechamento_diario.sh. O date capturava UTC, causando data errada quando executado próximo à meia-noite BRT.
category: devops
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Correção: Bug de Timezone no `fechamento_diario.sh`

## Problema
O script `{{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/fechamento_diario.sh` usava `date +%d-%m-%Y` sem especificar timezone. O servidor OVH roda em UTC. Quando o script executa às 22:55 BRT (01:55 UTC do dia seguinte), o arquivo `hoje.md` é renomeado com a data errada (dia anterior).

Exemplo: `hoje.md` de 11/05/2026 foi renomeado para `grupo_10-05-2026.md` em vez de `grupo_11-05-2026.md`.

## Causa Raiz
Linha afetada (original):
```bash
DATA=$(date +%d-%m-%Y)
```

## Correção Aplicada
```bash
DATA=$(TZ=America/Sao_Paulo date +%d-%m-%Y)
```

## Localização do Script
`{{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/fechamento_diario.sh`

## Verificação
Após correção, verificar com:
```bash
TZ=America/Sao_Paulo date +%d-%m-%Y
```
Deve retornar a data correta no horário de São Paulo.

## Impacto
- Arquivos historicos em `{{COMMANDER_HOME}}/projects/pycode-cerebro/data/historico/`
- Arquivos de blog em `{{COMMANDER_HOME}}/projects/pycode-cerebro/public/content/blog/`
- Processo PM2: `fechamento-pycode` (precisa estar online)

## Protocolo de Diagnóstico — Blog Genérico ou de Baixa Qualidade

Quando um blog gerado sai resumido, genérico, com alucinações ou contaminação de outros dias, seguir este roteiro:

### 1. Linha do tempo — `stat` nos arquivos
```bash
stat {{COMMANDER_HOME}}/projects/pycode-cerebro/public/content/blog/YYYY-MM-DD.md
stat {{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/sintetizador.py
```
- Comparar `Modify` do blog vs horário esperado do fechamento (22:55 BRT)
- Se o blog foi gerado muito antes das 22:55 → **execução prematura**, input incompleto

### 2. Tamanho do input vs output
```bash
wc -l -c {{COMMANDER_HOME}}/projects/pycode-cerebro/data/historico/grupo_DD-MM-YYYY.md
wc -c {{COMMANDER_HOME}}/projects/pycode-cerebro/public/content/blog/YYYY-MM-DD.md
```
- Comparar com outros dias para detectar anomalia (ex: input maior mas output menor)

### 3. Status do PM2
```bash
pm2 show fechamento-pycode | grep -E "status|cron restart"
```
- Se `stopped` com `cron restart: 55 22 * * *` → **normal**. Cron job PM2 executa e para automaticamente. Será reincubado no próximo horário agendado.
- Se `stopped` SEM `cron restart` → falha no deploy, recriar com `--cron`.
- Se `errored` → verificar logs.
- Se `status: stopped` + `cron restart: 55 22 * * *` → funcionamento normal.
- Se `cron restart: 0` → não há agendamento configurado, precisa recriar o cron.
- Para confirmar se a última execução rodou, verificar os logs:
  ```bash
  tail -5 {{COMMANDER_HOME}}/.pm2/logs/fechamento-pycode-out.log
  ```
  Procure por `"Fechamento concluído com sucesso!"` e a data correspondente.

### 4. Contaminação e alucinação
- Ler o blog e o input lado a lado
- Verificar se há menções a fatos/pessoas que **não estão no input** → alucinação
- Verificar se há conteúdo de outro dia → contaminação (input continha mensagens de múltiplos dias)

### 5. Log do sintetizador
```bash
grep -E "Processando|destilar|Dia DD/MM|Erro|Aviso|fallback" {{COMMANDER_HOME}}/.pm2/logs/fechamento-pycode-out.log
```
- "Processando N dias" → código antigo com `grupo.txt` (se N > 1)
- "Aviso: O modelo não devolveu o separador" → fallback ativado, qualidade comprometida
- Ausência de "destilar conhecimento do dia DD/MM" → trava de reprocessamento bloqueou

### 6. Regeneração
```bash
cd {{COMMANDER_HOME}}/projects/pycode-cerebro/scripts
source {{COMMANDER_HOME}}/hermes_env/bin/activate
python3 sintetizador.py --arquivo {{COMMANDER_HOME}}/projects/pycode-cerebro/data/historico/grupo_DD-MM-YYYY.md
```
O flag `--arquivo` pula a trava de reprocessamento.

## Defesas Anti-Alucinação (adicionadas 16/05/2026)

Implementadas no `sintetizador.py` após incidente do blog 14/05 (blog gerado às 09:41 com ~10 linhas de input, 80% alucinado):

| # | Defesa | Gatilho |
|---|---|---|
| 1 | Parser de linhas órfãs | Linhas sem timestamp herdam data da última mensagem |
| 2 | Threshold mínimo de 2000 chars | `len(texto_dia) < 2000` → aborta com warning, não chama IA |
| 3 | Heurística de qualidade na trava | Blog existente < 500 bytes → remove e regenera no cron |
| 4 | Log de auditoria | Toda execução registra `whoami`, `PID`, `timestamp` e `args` |

### Alteração do Prompt (16/05/2026)
Linha 121 do `sintetizador.py` alterada para:
```
- Relevância: Priorize discussões técnicas, dicas de ferramentas e decisões do grupo. Quando o dia tiver pouco conteúdo técnico, inclua também outros assuntos discutidos (off-topic, comunidade, eventos, descontração) para manter um registro fiel do que aconteceu no grupo.
```
Permite resumo não-técnico em dias fracos de tech, evitando alucinação por falta de conteúdo.

## Lição: Gatilho Prematuro via Terminal
Incidente 14/05: blog gerado às 09:41 BRT porque {{COMMANDER}} executou o sintetizador manualmente do terminal (`.zsh_history` modificado às 09:40). O `hoje.md` tinha apenas ~10 linhas de small talk. O cron das 22:55 encontrou arquivo existente e preservou a versão alucinada. As defesas #2 e #3 acima previnem recorrência.

## Dependência
- PM2 cron job `fechamento-pycode` com agendamento `55 22 * * *`. Status `stopped` é normal entre execuções.
- Se o cron não estiver configurado, recriar: `pm2 start {{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/fechamento_diario.sh --name fechamento-pycode --cron "55 22 * * *"`
- Requer `OPENCODE_GO_API_KEY` válida no `.env`

---

## Bug Relacionado: Contaminação por `grupo.txt` Cumulativo

### Diagnóstico (2026-05-15, {{AUDITOR}})

O `sintetizador.py` processa `grupo.txt` + `hoje.md` como fontes. O `grupo.txt` nunca é truncado, acumulando:
- 590+ linhas órfãs de data (mensagens multilinha do WhatsApp sem timestamp)
- Histórico de meses já arquivados em `grupo_DATA.md`

Isso infla o bucket do dia corrente (ex: 857 mensagens em vez de ~94) e o truncamento `texto_dia[:18000]` corta fora o conteúdo relevante, gerando blog genérico.

### Correção (delegada à {{BACKEND_ENGINEER}})
1. **`sintetizador.py` linha ~67**: remover `grupo.txt` das fontes, manter apenas `hoje.md`
2. **Truncar** `grupo.txt` com `truncate -s 0`
3. **Prompt**: adicionar trava de escopo — "Use APENAS as informações contidas no LOG abaixo"
4. **Auditar** `fechamento_diario.sh` para truncar `grupo.txt` após renomeação do `hoje.md`
