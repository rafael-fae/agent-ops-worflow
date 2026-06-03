---
name: auditoria-supply-chain
description: Procedimento de auditoria de segurança para ataques à supply chain (NPM/PyPI). Inclui verificação de hooks Claude Code/VS Code, inventário de credenciais, e script de verificação cruzada de dependências.
category: security
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Auditoria de Supply Chain — Procedimento Padrão

## Trigger
- Alerta de pacotes maliciosos em NPM, PyPI, ou RubyGems
- Solicitação de análise de risco por qualquer agente
- Ordem direta do {{ORCHESTRATOR}}

## Passos (Ordem de Prioridade)

### 1. Auditoria de Diretórios de Persistência
Verificar se `~/.claude/` e `~/.vscode/` existem no servidor:
```bash
ls -la ~/.claude/ 2>/dev/null || echo "Diretório ~/.claude/ não existe"
ls -la ~/.vscode/ 2>/dev/null || echo "Diretório ~/.vscode/ não existe"
```
Se existirem, inspecionar:
- `~/.claude/settings.json`
- `~/.vscode/tasks.json`
- Hooks e automações suspeitas

### 2. Inventário de Credenciais

**Arquitetura multi-profile:** Cada um dos 5 Radiantes ({{ORCHESTRATOR}}, {{BACKEND_ENGINEER}}, {{AUDITOR}}, {{FRONTEND_ENGINEER}}, {{DEVOPS_ENGINEER}}) possui credenciais em 2 camadas:
- **Camada 1 — Global:** `{{COMMANDER_HERMES_PATH}}/.env` — variáveis prefixadas (`{{ORCHESTRATOR_UPPER}}_SLACK_BOT_TOKEN`, `{{DEVOPS_ENGINEER_UPPER}}_GITHUB_PERSONAL_ACCESS_TOKEN`, etc.)
- **Camada 2 — Profile:** `{{COMMANDER_HERMES_PATH}}/profiles/<agente>/.env` — variáveis sem prefixo (`SLACK_BOT_TOKEN`, `GITHUB_PERSONAL_ACCESS_TOKEN`)
- **PM2:** `ecosystem.config.js` contém tokens Slack de todos os 5 Radiantes

**OpenCode API Key:** `{{COMMANDER_HERMES_PATH}}/profiles/navani/.env:1` + `{{COMMANDER_HERMES_PATH}}/profiles/jasnah/.env:1` (provider opencode-go)

**Slack Tokens:** 5 bots × 2 tokens (Bot `xoxb-` + App `xapp-`) = 10 tokens. Distribuídos em `ecosystem.config.js`, `.hermes/.env`, e `profiles/<agente>/.env`. Total: 26 substituições em 6 arquivos.

**GitHub Tokens:** 5 PATs (1 por Radiante). Confirmado: não existe 6º token. Armazenados em `.hermes/.env` (prefixed) + `profiles/<agente>/.env` (non-prefixed). GitHub Actions usa `${{ secrets.GITHUB_TOKEN }}` efêmero — não é PAT.

**Evolution API Key:** Persiste em 3 pontos no HOST:
1. `/var/www/oeste-odontologia/.env` → `EVOLUTION_API_KEY`
2. `/var/www/dontus_app/config.yaml` → `evolution_apikey`
3. Container `evolution-api` → `AUTHENTICATION_API_KEY` (injetada via docker-compose env do host)
O compose ativo é `/var/www/oeste-odontologia/docker-compose.yml` (NÃO `dontus_app/vps-config`).

### 3. Script de Verificação Cruzada
**Script existente:** `{{COMMANDER_HOME}}/projects/pycode-cerebro/scripts/auditoria_supply_chain.py`

**Funcionalidades:**
1. Coleta pacotes NPM globais + PyPI de todos os ambientes (sistema, uv, venvs)
2. Baixa IOCs de fontes oficiais (GitHub threat-intel) automaticamente
3. Cruza com listas manuais `IOC_MANUAL_NPM` e `IOC_MANUAL_PYPI`
4. Heurística de typosquatting (distância Levenshtein ≤ 2 de pacotes populares)
5. Relatório em texto ou JSON (`--json`)

**Uso:** `python3 auditoria_supply_chain.py`

**:warning: As listas `IOC_MANUAL_NPM` e `IOC_MANUAL_PYPI` começam VAZIAS.** Alimentar com IOCs do TabNews/BleepingComputer assim que disponíveis antes de executar.

### 4. Rotação de Chaves

**Scripts prontos em `{{COMMANDER_HOME}}/hermes-configs/rotacionar_*.sh`** (todos com backup automático + sed + validação de saúde):

| Script | Alvo | Gatilho |
|--------|------|---------|
| `rotacionar_opencode_key.sh` | OPENCODE_GO_API_KEY ({{BACKEND_ENGINEER}} + {{AUDITOR}}) | `bash script.sh "<chave>"` |
| `rotacionar_slack_tokens.sh` | 10 tokens Slack (5 bots × 2) | `export NOVO_*_TOKEN=... && bash script.sh` |
| `rotacionar_evolution_key.sh` | Evolution API Key (3 pontos) | `bash script.sh` (auto-gera `openssl rand -hex 32`) |
| `rotacionar_github_tokens.sh` | 5 PATs GitHub | `export NOVO_*_GITHUB_TOKEN=... && bash script.sh` |

**Procedimento OpenCode (P0):**
1. {{COMMANDER}} gera nova chave em https://opencode.ai → Settings → API Keys (JANELA ANÔNIMA)
2. `bash {{COMMANDER_HOME}}/hermes-configs/rotacionar_opencode_key.sh "<nova_chave>"`
3. {{BACKEND_ENGINEER}} + {{AUDITOR}} reiniciados automaticamente

**Procedimento Slack (P1):**
1. {{COMMANDER}} rotaciona tokens em https://api.slack.com/apps (5 apps × 2 tokens cada)
2. Exporta `NOVO_<AGENTE>_SLACK_BOT_TOKEN` e `NOVO_<AGENTE>_SLACK_APP_TOKEN`
3. `bash {{COMMANDER_HOME}}/hermes-configs/rotacionar_slack_tokens.sh`

**Procedimento Evolution (P1):**
- Script auto-suficiente: gera chave forte → atualiza `.env` + `config.yaml` → recria container → valida

**Procedimento GitHub (P2):**
1. {{COMMANDER}} gera 5 novos PATs em https://github.com/settings/tokens (escopo: `repo`, `workflow`)
2. Exporta `NOVO_<AGENTE>_GITHUB_TOKEN`
3. `bash {{COMMANDER_HOME}}/hermes-configs/rotacionar_github_tokens.sh`

### 5. Verificação PM2
```bash
pm2 status
```
Processos: dalinar, navani, jasnah, shallan, kaladin, quartz-cerebro, webhook-whatsapp, fechamento-pycode.

## Pitfalls
- :red_circle: **VETOR DE ATAQUE CONFIRMADO: MÁQUINA LOCAL** — extensões VS Code (`github.copilot-chat`, `ms-vscode-remote.remote-ssh`) são os vetores de infecção. O servidor OVH é headless e está limpo. Toda nova credencial deve ser gerada em JANELA ANÔNIMA do navegador, sem extensões carregadas.
- Malware sobrevive à desinstalação de pacotes (hooks em IDEs)
- Assinaturas criptográficas podem ser falsificadas
- `uv pip install` sem `--require-hashes` é vulnerável
- O timezone do `date` no shell script pode causar data incorreta (ver skill `correcao-fechamento-diario`)
- Chaves fracas como `dontus2024evolution` são previsíveis — usar SEMPRE `openssl rand -hex 32` para chaves novas
- O compose ativo da Evolution é `/var/www/oeste-odontologia/docker-compose.yml` (NÃO `dontus_app/vps-config`)
- :warning: **REGRA CRÍTICA**: Nenhum passo deste procedimento (exceto verificações passivas de existência de diretórios) pode ser executado sem "Sinal Verde" explícito do {{COMMANDER}}. O servidor é de produção e ele exige autorização prévia para qualquer comando. Ver regra 8 do skill `mandos-operacao-cerebro-pycode`.
