# Evidência Definitiva: OpenCode CLI NÃO Suporta Batch (29/05/2026)

## Comando Testado

```bash
/Users/{{COMMANDER}}fae/.local/share/mise/installs/node/24.13.1/bin/opencode run \
  -m zai-coding-plan/glm-5.1 \
  "responda apenas: OK" \
  --format json \
  --variant minimal
```

## Resultado no stdout

```json
{"type":"step_start","timestamp":1780078401226,"sessionID":"ses_18b0f3edeffemonDv53soyMq02","part":{"id":"prt_e74f0d6c6001bqaRxPFUfV8RX2","messageID":"msg_e74f0c1740017nqAuzP8tZa4P0","sessionID":"ses_18b0f3edeffemonDv53soyMq02","type":"step-start"}}
```

**Apenas `step_start`. Nenhum evento `text`, `step_end`, ou resposta textual.**

## Log Interno (--print-logs) — O Que REALMENTE Acontece

```
INFO  service=llm providerID=zai-coding-plan modelID=glm-5.1 session.id=... small=true agent=title mode=primary stream
INFO  service=provider providerID=zai-coding-plan pkg=@ai-sdk/openai-compatible using bundled provider
INFO  service=llm providerID=zai-coding-plan modelID=glm-5.1 session.id=... small=false agent=build mode=primary stream
INFO  service=bus type=message.part.updated publishing       ← resposta do modelo
INFO  service=bus type=message.part.delta publishing          ← delta de streaming
INFO  service=bus type=session.prompt ... exiting loop        ← loop termina
INFO  service=default ... disposing instance                  ← cleanup
```

**A resposta do modelo (texto "OK") foi processada pelo bus interno e renderizada na TUI — NUNCA foi para stdout.**

## Testes Adicionais (Todos Falharam)

| Abordagem | Comando | Resultado |
|-----------|---------|-----------|
| `--format json` | `opencode run -m ... "prompt" --format json` | Apenas `step_start` |
| `--format default` | `opencode run -m ... "prompt" --format default` | stdout vazio |
| `--format json` + `--variant minimal` | `opencode run -m ... "prompt" --format json --variant minimal` | Apenas `step_start` |
| `terminal(pty=true)` + `--format json` | `terminal(pty=true, command="opencode run ...")` | Apenas `step_start` |
| `terminal(pty=true)` + `process(submit)` | PTY background + submeter prompt | Output vazio, processo trava |
| Pipe via stdin | `echo "prompt" \| opencode run -m ...` | Apenas `step_start` |
| `--command` flag | `opencode run --command "prompt" -m ...` | Erro: "Command not found" (--command espera nome de skill) |

## Conclusão

**OpenCode CLI é fundamentalmente TUI-first. O `run` inicia uma sessão interativa. Em modo batch (não-interativo), a resposta do modelo NUNCA chega ao stdout — fica confinada ao bus de eventos interno e é renderizada exclusivamente na TUI.**

## Uso Correto

| Modo | Como | Quando |
|------|------|--------|
| TUI interativa | `terminal(pty=true)` → `opencode run -m zai-coding-plan/glm-5.1` | Sessões de desenvolvimento |
| Batch (via API HTTP) | Chamada direta ao endpoint `open.bigmodel.cn/api/paas/v4` | Automação (requer chave com saldo) |
| Batch (alternativa) | Substituir por Claude Opus ou Gemini 3.1 Pro | SEMPRE preferível |

## Provider vs CLI — Distinção Crítica

| Componente | API Key | Uso |
|------------|---------|-----|
| `opencode-go` (config.yaml) | `sk-Lqr...` | Motor de conversa Hermes — NUNCA para código |
| `zai-coding-plan` (auth.json) | `6490cee4...` | OpenCode CLI com GLM-5.1 via z.ai |
| `zai` (auth.json) | `f4f72d1b...` | Z.AI uso geral |
| `google` (auth.json) | `AIzaSy...` | Google Gemini API |
