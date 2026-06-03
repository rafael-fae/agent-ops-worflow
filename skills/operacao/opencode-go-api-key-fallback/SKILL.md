---
name: opencode-go-api-key-fallback
title: OpenCode Go API Key Fallback Automático
description: >-
  Mecanismo de fallback para API keys do provider OpenCode Go. Script em
  cada profile testa OPENCODE_GO_API_KEY, se 429 faz swap automático no .env
  para OPENCODE_GO_API_KEY_2. Se ambas falharem, trava. Cron monitor 15min.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# OpenCode Go API Key Fallback Automático

## Gatilho
- {{COMMANDER}} adiciona nova API key e mantém a antiga nos .env
- Ordena fallback automático: primária → secundária → parar se ambas exauridas

## Arquitetura

O Hermes provider `opencode-go` lê `OPENCODE_GO_API_KEY` do .env (definido em `hermes_cli/auth.py` via `api_key_env_vars`). **Não há suporte nativo a fallback.** A solução:

1. Script Python que testa a chave ativa contra `GET /v1/models`
2. Se 429, altera a linha `OPENCODE_GO_API_KEY=` no .env com o valor de `OPENCODE_GO_API_KEY_2`
3. Se ambas falharem, cria `.opencode_status.json` com `locked: true`
4. Cron Hermes a cada 15min testa a chave ativa

## O Script

Localização: `~/.hermes/profiles/{agent}/scripts/opencode_fallback.py`

Ver o código completo em: `scripts/opencode_fallback.py` neste skill directory.

**Comandos:**
- `python3 scripts/opencode_fallback.py check` — testa e retorna ACTIVE_KEY ou NO_ACTIVE_KEY
- `python3 scripts/opencode_fallback.py unlock` — destrava após {{COMMANDER}} restaurar chaves

## Deploy

```bash
# Customizar paths para cada agente
agents=("navani" "shallan" "jasnah" "kaladin" "lirin" "pattern")
for a in "${agents[@]}"; do
    # Copiar script base e ajustar ENV_FILE/STATUS_FILE paths
    sed "s|ENV_FILE = .*|ENV_FILE = \"{{COMMANDER_HOME}}/hermes-roshar/profiles/$a/.env\"|" \
        base.py > "{{COMMANDER_HOME}}/hermes-roshar/profiles/$a/scripts/opencode_fallback.py"
    chmod +x "{{COMMANDER_HOME}}/hermes-roshar/profiles/$a/scripts/opencode_fallback.py"
done
```

## Cron Monitor

```python
cronjob(action="create", name="opencode-fallback-monitor", schedule="every 15m",
        prompt="Execute opencode_fallback.py check; if NO_ACTIVE_KEY, alert {{COMMANDER}}")
```

## Antes de Iniciar Waves — Verificar Modelo

{{COMMANDER}} exige confirmação explícita do modelo antes de iniciar qualquer wave:

1. Verificar `model:` em cada profile config (ou `hermes_cli/config.py` se global)
2. Se algum agente estiver em `deepseek-v4-pro` e a tarefa for RE/extração, solicitar autorização de {{COMMANDER}} para usar `deepseek-v4-flash`
3. Editar cada profile que estiver no modelo errado: `sed -i 's/deepseek-v4-pro/deepseek-v4-flash/g' ~/.hermes/profiles/{agent}/config.yaml`
4. Confirmar para {{COMMANDER}}: "Todos em V4 Flash. Pode iniciar."

## Quando Agentes Não Respondem

Se agentes delegados ({{BACKEND_ENGINEER}}, {{DEVOPS_ENGINEER}}) ficarem em standby sem executar as ordens, assumir execução direta:

1. Verificar scripts prontos no projeto (`wave_extract_playwright.py`, `extract_page.py`)
2. Verificar modelo dos agentes primeiro (item acima)
3. Instalar dependências: `uv pip install playwright beautifulsoup4 httpx && uv run playwright install chromium`
4. Executar em background com `notify_on_complete=True`
5. Reportar resultado no Slack com resumo de páginas extraídas e eventuais rotas 404

## Verificando Token Real com Hex Dump

O Hermes Agent mascara tokens no output — `cat`/`grep` sempre mostram `***` para padrões como `sk-or-`, `xoxb-`, `xapp-`. Para confirmar qual key está realmente ativa:

```bash
# Mostrar últimos 12 bytes (8 chars visíveis + newline) em hex
grep 'OPENCODE_GO_API_KEY=' /path/to/.env | tail -c 12 | xxd | tail -1
# Exemplo: 00000000: 3648 6a6f 4247 4a61 4668 780a   6HjoBGJaFhx.
```

Isto é essencial quando:
- {{COMMANDER}} diz que trocou a key mas o agente ainda reporta limite
- Há dúvida se a key primária ou secundária está ativa
- O `.env` foi editado manualmente e precisa confirmar o valor real

**:red_circle: Atenção ao path do `.env`:** Se `~/.hermes/profiles/<agent>` for um diretório real (não symlink), edições no git (`Dev/hermes-profiles/<agent>/.env`) não propagam para o arquivo ativo. Verificar com `readlink -f` que ambos apontam para o mesmo inode.

## Centralização de Keys por Grupo (DK / SJ / NP) — Padrão que FUNCIONA

**:red_circle: Devido ao bug do `api_key_env` (ver Pitfall #1), a centralização funciona da seguinte forma:**

O `~/.hermes/.env` central serve como **referência única** onde todas as keys ficam documentadas. Mas cada agente precisa de `OPENCODE_GO_API_KEY` no seu **próprio `.env` individual** com o valor do seu grupo.

```bash
# ~/.hermes/.env (REFERÊNCIA — não é lido pelos agentes para OpenCode)
OPENCODE_GO_DK_KEY=sk-or-v1-xxx   # {{ORCHESTRATOR}} + {{DEVOPS_ENGINEER}}
OPENCODE_GO_SJ_KEY=sk-or-v1-yyy   # {{FRONTEND_ENGINEER}} + {{AUDITOR}}
OPENCODE_GO_NP_KEY=sk-or-v1-zzz   # {{BACKEND_ENGINEER}} + {{GIT_OPS}}
```

```bash
# dalinar/.env e kaladin/.env (ATIVO — efetivamente lido)
OPENCODE_GO_API_KEY=<mesmo valor de OPENCODE_GO_DK_KEY>

# shallan/.env e jasnah/.env
OPENCODE_GO_API_KEY=<mesmo valor de OPENCODE_GO_SJ_KEY>

# navani/.env e pattern/.env
OPENCODE_GO_API_KEY=<mesmo valor de OPENCODE_GO_NP_KEY>
```

**IMPORTANTE:** Remover `api_key_env` do `config.yaml` — ele NÃO funciona com opencode-go e causa `HTTP 401 Invalid API key`.

**Vantagens:**
- Rotacionar 3 keys = editar 1 arquivo (`~/.hermes/.env`, 3 linhas) como referência + copiar para os `.env` dos 2 agentes do grupo
- Script `rotate-key` (ver abaixo) automatiza a cópia
- Menos risco de gargalo (3 contas para 6 agentes vs 1 conta para todos)
- Se uma conta estourar limite, só 2 agentes são afetados

## Rotação de Keys (rotate-key)

Script `~/.local/bin/rotate-key` (ver `planejamento-diario/scripts/rotate-key.sh`) automatiza a troca de key para um grupo inteiro:

```bash
rotate-key DK sk-nova-key   # atualiza central + dalinar + kaladin
```

Isto edita o `~/.hermes/.env` central E os `.env` individuais dos 2 agentes. Após rodar, reiniciar os gateways do grupo.

## Pitfalls

1. **:red_circle: `api_key_env` NÃO é respeitado pelo provider opencode-go (verificado 31/05/2026):** O Hermes provider `opencode-go` IGNORA a diretiva `api_key_env: OPENCODE_GO_DK_KEY` no bloco `model:` do config.yaml. O provider SEMPRE lê `OPENCODE_GO_API_KEY`. Tentar usar `api_key_env` resulta em `AuthenticationError [HTTP 401] Invalid API key` mesmo com a variável corretamente definida.

   **Solução que funciona:** Colocar `OPENCODE_GO_API_KEY=<valor>` diretamente no `.env` de cada agente individual. Para compartilhar keys entre 2 agentes, colocar o mesmo valor em ambos os `.env`.

   **Teste de verificação:** Se o agente reporta `Invalid API key` mesmo após restart e a variável existe no `.env` central, o `api_key_env` não está sendo lido. Remover `api_key_env` do config.yaml e colocar `OPENCODE_GO_API_KEY` direto no `.env` individual.

   **Não tente fazer:** `source` ou `export` no `.env` do agente apontando para o central. O Hermes não suporta `source` em arquivos `.env` (não é bash, é parsing simples de `KEY=VALUE`).

2. **~ expande diferente em contexto Hermes.** Usar caminhos absolutos, não `expanduser`.
3. **Swap no .env só é efetivo após restart do agente.** Para efeito imediato, exportar var de ambiente.
4. **Valores de chave aparecem como `***` no read_file** — o Hermes redacta secrets. Usar `xxd` para verificar valores reais.
  - **Para usar chave secundária direto no config.yaml:** adicionar `api_key_env: OPENCODE_GO_API_KEY_2` no bloco `model:` do `config.yaml`. **:warning: Este recurso NÃO funciona com opencode-go — usar apenas com providers que suportam.** O provider opencode-go IGNORA `api_key_env` e sempre lê `OPENCODE_GO_API_KEY`.

## Rotação Rápida (rotate-key)

Script `~/.local/bin/rotate-key` (Mac) ou `{{COMMANDER_HOME}}fae/.local/bin/rotate-key` (OVH):

```bash
# Mac
rotate-key DK sk-nova-key   # {{ORCHESTRATOR}} + {{DEVOPS_ENGINEER}}
rotate-key SJ sk-nova-key   # {{FRONTEND_ENGINEER}} + {{AUDITOR}}
rotate-key NP sk-nova-key   # {{BACKEND_ENGINEER}} + {{GIT_OPS}}

# OVH
rotate-key AC sk-nova-key   # Aragorn + Celebrimbor
rotate-key GE sk-nova-key   # Galadriel + Elrond
rotate-key EG sk-nova-key   # Éomer + Gandalf
rotate-key LR sk-nova-key   # Lirin
```

O script atualiza o `.env` central E os `.env` individuais dos agentes do grupo.

## Verificação

- [ ] Script rodando sem erro em cada profile
- [ ] Cron monitor ativo e testado
- [ ] .env tem ambas as chaves
- [ ] key1 responde 200 no health check
- [ ] key2 disponível como fallback
- [ ] unlock funciona se locked
