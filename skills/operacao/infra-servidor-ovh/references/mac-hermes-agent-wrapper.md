# Hermes Agent Wrapper + Aliases

Scripts e aliases para iniciar agentes Hermes rapidamente em ambos os ambientes.

## Mac (M4 local)

### `/Users/{{COMMANDER}}fae/.local/bin/hermes-agent`

```bash
#!/bin/bash
# Wrapper: hermes-agent <profile> [args...]
source ~/Dev/Hermes/.venv/bin/activate
exec hermes --profile "$@"
```

### `.zshrc` aliases

```bash
export PATH="$HOME/.local/bin:$PATH"
alias ha='hermes-agent'
alias hermes-dalinar='hermes-agent dalinar'
alias hermes-navani='hermes-agent navani'
alias hermes-shallan='hermes-agent shallan'
alias hermes-jasnah='hermes-agent jasnah'
alias hermes-kaladin='hermes-agent kaladin'
alias hermes-pattern='hermes-agent pattern'
```

Uso: `hermes-dalinar`, `hermes-kaladin gateway status`, `ha navani`

## OVH (servidor)

### `{{COMMANDER_HOME}}fae/.local/bin/hermes-agent`

```bash
#!/bin/bash
source {{COMMANDER_HOME}}fae/hermes_env/bin/activate
exec hermes --profile "$@"
```

### `.bashrc` aliases

```bash
export PATH="$HOME/.local/bin:$PATH"
alias ha='hermes-agent'
alias hermes-aragorn='hermes-agent aragorn'
alias hermes-celebrimbor='hermes-agent celebrimbor'
alias hermes-galadriel='hermes-agent galadriel'
alias hermes-elrond='hermes-agent elrond'
alias hermes-eomer='hermes-agent eomer'
alias hermes-gandalf='hermes-agent gandalf'
alias hermes-lirin='hermes-agent lirin'
```

Uso: `hermes-aragorn`, `ha lirin gateway status`
