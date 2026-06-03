---
name: opencode-api-key-fallback
title: Fallback Automático de API Keys OpenCode Go
description: Quando {{COMMANDER}} adiciona novas API keys ao time, implementar fallback automático entre OPENCODE_GO_API_KEY (primária) e OPENCODE_GO_API_KEY_2 (secundária) via script de health check + swap de .env.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Fallback Automático de API Keys OpenCode Go

## Gatilho
- {{COMMANDER}} adiciona nova API key e mantém a antiga como fallback nos `.env` do time
- Variáveis: `OPENCODE_GO_API_KEY` (primária), `OPENCODE_GO_API_KEY_2` (fallback)

## Arquitetura

O Hermes lê a API key da variável `OPENCODE_GO_API_KEY` no momento da requisição. Sem suporte nativo a fallback, a solução é um script que testa a chave via `GET /v1/models` e, se a primária falhar (429), reescreve o `.env` trocando o valor pela secundária. Se ambas falharem, cria lock file.

## Procedimento

### 1. Criar o Script Base

Caminho: `~/.hermes/profiles/dalinar/scripts/opencode_fallback.py`

**IMPORTANTE:** Usar caminhos ABSOLUTOS no script — `os.path.expanduser("~")` não funciona corretamente dentro do perfil do agente (expande para `{{COMMANDER_HERMES_PATH}}/profiles/dalinar/home/`).

O script deve:
- `check` — testar OPENCODE_GO_API_KEY via GET no health endpoint; se 429, fazer swap no .env para OPENCODE_GO_API_KEY_2; se ambas falharem, criar `.opencode_status.json` com `locked: true`
- `unlock` — remover o lock file

Tratar `***` (valor mascarado pelo Hermes) como chave inválida.

### 2. Personalizar por Agente

Cada agente tem `.env` em:
```
{{COMMANDER_HOME}}/hermes-roshar/profiles/{navani,shallan,jasnah,kaladin,lirin,pattern}/.env
```

Usar script Python para copiar com paths corretos (substituir os paths absolutos no código-fonte antes de copiar).

### 3. Cron de Monitoramento

Criar cron job a cada 15min que executa `opencode_fallback.py check` e alerta no `#operacao` se retornar `NO_ACTIVE_KEY`.

### 4. Destravar

```bash
python3 {{COMMANDER_HOME}}/hermes-roshar/profiles/{agente}/scripts/opencode_fallback.py unlock
```

## Pitfalls

1. **`~` não funciona** no contexto do perfil — usar caminhos absolutos
2. **`***`** nos `.env` — tratar como chave inválida
3. **Copiar para CADA agente** — cada um tem seu próprio `.env`
4. **Swap no `.env`** é mais confiável que variável de ambiente, pois persiste entre sessões
5. **Criar diretório** com `os.makedirs` antes de escrever lock file

## Verificação

- [ ] Script testado no {{ORCHESTRATOR}}: `python3 scripts/opencode_fallback.py check` → `ACTIVE_KEY=...`
- [ ] Script copiado para todos os 6 agentes com paths corretos
- [ ] Cron de monitoramento ativo
- [ ] Testar unlock: `python3 scripts/opencode_fallback.py unlock`
