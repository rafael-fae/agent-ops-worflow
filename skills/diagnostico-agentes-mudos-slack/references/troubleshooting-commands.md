# Comandos de Troubleshooting para Agentes Slack Hermes

## Verificação de Gateway e Identidade

```bash
# 1. Processo rodando?
ps aux | grep "hermes.*<profile>" | grep -v grep

# 2. Logs do gateway (últimas linhas)
tail -20 ~/.hermes/profiles/<profile>/logs/gateway.log

# 3. Logs do agente (chamadas de API, tools)
tail -20 ~/.hermes/profiles/<profile>/logs/agent.log

# 4. Testar token contra Slack API (auth.test definitivo)
TOKEN=$(grep "^SLACK_BOT_TOKEN=" ~/.hermes/profiles/<profile>/.env | cut -d= -f2)
curl -s -H "Authorization: Bearer $TOKEN" -X POST https://slack.com/api/auth.test
# Resposta esperada: {"ok":true,"user":"username","user_id":"U0BXXXXXXX","bot_id":"B0BXXXXXX"}
```

## Verificação de Config

```bash
# 5. bot_user_id presente no config.yaml?
grep -A6 "^slack:" ~/.hermes/profiles/<profile>/config.yaml | head -10

# 6. require_mention no .env?
grep SLACK_REQUIRE_MENTION ~/.hermes/profiles/<profile>/.env

# 7. Token real existe no .env (via hex dump, porque terminal máscara como ***)
xxd ~/.hermes/profiles/<profile>/.env | head -5
# Procurar por: 78 6f 78 62 2d = "xoxb-" (token presente)

# 8. launchctl status
launchctl list | grep <profile>
```

## Restart via Launchctl (Mac)

```bash
# Restart forcado
launchctl kickstart -k gui/501/com.{{COMMANDER}}.hermes.<profile>
```

## Comparação de tokens entre profiles

```bash
# Extrair via Python (evita masking)
python3 -c "
with open('$HOME/.hermes/profiles/profile1/.env') as f:
    for line in f:
        if 'SLACK_BOT_TOKEN' in line:
            print(f'profile1: {line.strip()[:30]}...')
with open('$HOME/.hermes/profiles/profile2/.env') as f:
    for line in f:
        if 'SLACK_BOT_TOKEN' in line:
            print(f'profile2: {line.strip()[:30]}...')
"
```

## Casos Específicos

### Caso A: Agente não responde (silencioso)
- Token inválido/expirado? → `auth.test` retorna `ok:false`
- Gateway caiu? → sem processo rodando
- Bot username enganoso? → `auth.test` mostra user_id correto mas @username diferente. Confiar no user_id, não no username.

### Caso B: Agente responde a tudo (falante)
- `bot_user_id` ausente no config.yaml?
- `require_mention` não está true?
- Gateway recebe inbound messages de todos os IDs?
