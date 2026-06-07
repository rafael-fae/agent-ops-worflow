# rotate-key — Script de Rotação de API Keys OpenCode

Scripts idênticos no Mac e OVH para rotacionar API keys OpenCode agrupadas por dupla de agentes.

## Mac (`~/.local/bin/rotate-key`)

```bash
#!/bin/bash
GRUPO="$1"
NOVA_KEY="$2"
[ -z "$GRUPO" ] || [ -z "$NOVA_KEY" ] && echo "Uso: rotate-key <DK|SJ|NP> <nova-key>" && exit 1
case "$GRUPO" in
    DK) AGENTS="dalinar kaladin";   CENTRAL=~/.hermes/.env; VAR="OPENCODE_GO_DK_KEY";;
    SJ) AGENTS="shallan jasnah";    CENTRAL=~/.hermes/.env; VAR="OPENCODE_GO_SJ_KEY";;
    NP) AGENTS="navani pattern";    CENTRAL=~/.hermes/.env; VAR="OPENCODE_GO_NP_KEY";;
    *) echo "Grupo inválido: $GRUPO"; exit 1;;
esac
sed -i '' "s/^${VAR}=.*/${VAR}=${NOVA_KEY}/" "$CENTRAL"
echo "✅ Central: $VAR atualizada"
for agent in $AGENTS; do
    ENVFILE=~/.hermes/profiles/$agent/.env
    sed -i '' "s/^OPENCODE_GO_API_KEY=.*/OPENCODE_GO_API_KEY=${NOVA_KEY}/" "$ENVFILE"
    echo "✅ $agent: atualizado"
done
echo ""
echo "Agora reinicie os gateways: hermes-$agent"
```

## OVH (`{{COMMANDER_HOME}}fae/.local/bin/rotate-key`)

```bash
#!/bin/bash
GRUPO="$1"
NOVA_KEY="$2"
[ -z "$GRUPO" ] || [ -z "$NOVA_KEY" ] && echo "Uso: rotate-key <AC|GE|EG|LR> <nova-key>" && exit 1
case "$GRUPO" in
    AC) AGENTS="aragorn celebrimbor"; VAR="OPENCODE_GO_AC_KEY";;
    GE) AGENTS="galadriel elrond";   VAR="OPENCODE_GO_GE_KEY";;
    EG) AGENTS="eomer gandalf";      VAR="OPENCODE_GO_EG_KEY";;
    LR) AGENTS="lirin";              VAR="OPENCODE_GO_LR_KEY";;
    *) echo "Grupo inválido: $GRUPO"; exit 1;;
esac
CENTRAL={{COMMANDER_HOME}}fae/.hermes/.env
sed -i "s/^${VAR}=.*/${VAR}=${NOVA_KEY}/" "$CENTRAL"
echo "✅ Central atualizada"
for agent in $AGENTS; do
    ENVFILE={{COMMANDER_HOME}}fae/Dev/hermes-profiles/$agent/.env
    sed -i "s/^OPENCODE_GO_API_KEY=.*/OPENCODE_GO_API_KEY=${NOVA_KEY}/" "$ENVFILE"
    echo "✅ $agent atualizado"
done
echo ""
echo "Reinicie: pm2 restart <agentes> ou systemctl restart hermes-<agente>"
```

## Uso

```bash
# Mac
rotate-key DK sk-rXg...     # {{ORCHESTRATOR}} + {{DEVOPS_ENGINEER}}
rotate-key SJ sk-qlG...     # {{FRONTEND_ENGINEER}} + {{AUDITOR}}
rotate-key NP sk-1yK...     # {{BACKEND_ENGINEER}} + {{GIT_OPS}}

# OVH
rotate-key AC sk-cjh...     # Aragorn + Celebrimbor
rotate-key GE sk-CVi...     # Galadriel + Elrond
rotate-key EG sk-uE1...     # Éomer + Gandalf
rotate-key LR sk-Eky...     # Lirin
```

## Funcionamento

1. Atualiza a variável no `~/.hermes/.env` central (referência)
2. Atualiza `OPENCODE_GO_API_KEY` no `.env` de cada agente do grupo
3. Os agentes precisam ser reiniciados para carregar a nova key

## ⚠️ Por que não usar `api_key_env` no config.yaml?

O provider `opencode-go` **IGNORA** a diretiva `api_key_env` no `config.yaml` (verificado 31/05/2026). Tentativas de usar `api_key_env: OPENCODE_GO_DK_KEY` resultam em HTTP 401. Por isso o `rotate-key` escreve diretamente `OPENCODE_GO_API_KEY` no `.env` individual de cada agente.
