#!/bin/bash
# hermes-agent wrapper — ativa venv e executa hermes --profile
# Instalar em ~/.local/bin/hermes-agent (chmod +x)
#
# Mac: source ~/Dev/Hermes/.venv/bin/activate
# OVH: source ~/hermes_env/bin/activate

VENV_PATH="${HERMES_VENV:-$HOME/Dev/Hermes/.venv}"
source "$VENV_PATH/bin/activate"
exec hermes --profile "$@"
