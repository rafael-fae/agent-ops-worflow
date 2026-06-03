#!/bin/bash
# rotate-key — Atualiza API key OpenCode para um grupo de agentes
# Uso: rotate-key <grupo> <nova-key>
#
# Grupos Mac: DK (dalinar+kaladin), SJ (shallan+jasnah), NP (navani+pattern)
# Grupos OVH: AC (aragorn+celebrimbor), GE (galadriel+elrond), EG (eomer+gandalf), LR (lirin)
#
# Exemplo: rotate-key DK sk-or-v1-novakey...

GRUPO="$1"
NOVA_KEY="$2"

[ -z "$GRUPO" ] || [ -z "$NOVA_KEY" ] && {
    echo "Uso: rotate-key <grupo> <nova-key>"
    echo "Grupos: DK SJ NP AC GE EG LR"
    exit 1
}

CENTRAL="$HOME/.hermes/.env"
BASE_PROFILES="${HERMES_PROFILES_BASE:-$HOME/.hermes/profiles}"

case "$GRUPO" in
    DK) AGENTS="dalinar kaladin";   VAR="OPENCODE_GO_DK_KEY";;
    SJ) AGENTS="shallan jasnah";    VAR="OPENCODE_GO_SJ_KEY";;
    NP) AGENTS="navani pattern";    VAR="OPENCODE_GO_NP_KEY";;
    AC) AGENTS="aragorn celebrimbor"; VAR="OPENCODE_GO_AC_KEY"
        BASE_PROFILES="$HOME/Dev/hermes-profiles";;
    GE) AGENTS="galadriel elrond";  VAR="OPENCODE_GO_GE_KEY"
        BASE_PROFILES="$HOME/Dev/hermes-profiles";;
    EG) AGENTS="eomer gandalf";     VAR="OPENCODE_GO_EG_KEY"
        BASE_PROFILES="$HOME/Dev/hermes-profiles";;
    LR) AGENTS="lirin";             VAR="OPENCODE_GO_LR_KEY"
        BASE_PROFILES="$HOME/Dev/hermes-profiles";;
    *) echo "Grupo inválido: $GRUPO"; exit 1;;
esac

# 1. Atualizar .env central
sed -i "s/^${VAR}=.*/${VAR}=${NOVA_KEY}/" "$CENTRAL"
echo "✅ Central: $VAR atualizada"

# 2. Atualizar .env de cada agente
for agent in $AGENTS; do
    ENVFILE="$BASE_PROFILES/$agent/.env"
    sed -i "s/^OPENCODE_GO_API_KEY=.*/OPENCODE_GO_API_KEY=${NOVA_KEY}/" "$ENVFILE"
    echo "✅ $agent: OPENCODE_GO_API_KEY atualizada"
done

echo ""
echo "Agora reinicie os gateways dos agentes do grupo $GRUPO"
