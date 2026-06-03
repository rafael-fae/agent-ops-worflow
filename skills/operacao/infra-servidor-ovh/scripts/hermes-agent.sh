#!/bin/bash
# Wrapper: hermes-agent <profile> [args...]
# Ex: hermes-agent dalinar
#     hermes-agent kaladin gateway status
#
# Instalar em ~/.local/bin/hermes-agent
# Adicionar aliases no .zshrc/.bashrc:
#   alias hermes-dalinar='hermes-agent dalinar'
#   alias ha='hermes-agent'
#
# Path do venv: ajustar conforme ambiente
#   Mac: ~/Dev/Hermes/.venv/bin/activate
#   OVH: {{COMMANDER_HOME}}fae/hermes_env/bin/activate

if [ -f ~/Dev/Hermes/.venv/bin/activate ]; then
    source ~/Dev/Hermes/.venv/bin/activate
elif [ -f {{COMMANDER_HOME}}fae/hermes_env/bin/activate ]; then
    source {{COMMANDER_HOME}}fae/hermes_env/bin/activate
fi

exec hermes --profile "$@"
