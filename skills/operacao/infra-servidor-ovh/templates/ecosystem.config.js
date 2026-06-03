// PM2 Ecosystem — Sociedade do Anel (OVH)
// Agentes: Aragorn, Celebrimbor, Galadriel, Elrond, Éomer
// Gandalf e Lirin rodam via systemd
//
// CRÍTICO: interpreter: 'none' — PM2 tenta executar scripts com Node.js por padrão.
// O binário 'hermes' é um bash script wrapper; sem interpreter:'none', dá SyntaxError.

module.exports = {
  apps: [
    {
      name: 'aragorn',
      script: '{{COMMANDER_HOME}}fae/hermes_env/bin/python',
      args: '-m hermes_cli.main --profile aragorn gateway run --replace',
      cwd: '{{COMMANDER_HOME}}fae',
      interpreter: 'none',
      env: {
        HOME: '{{COMMANDER_HOME}}fae',
        PATH: '{{COMMANDER_HOME}}fae/hermes_env/bin:{{COMMANDER_HOME}}fae/.local/bin:/usr/bin:/bin',
      },
      restart_delay: 10000,
      max_restarts: 20,
      max_memory_restart: '2G',
      autorestart: true,
      watch: false,
      time: true,
    },
    {
      name: 'celebrimbor',
      script: '{{COMMANDER_HOME}}fae/hermes_env/bin/python',
      args: '-m hermes_cli.main --profile celebrimbor gateway run --replace',
      cwd: '{{COMMANDER_HOME}}fae',
      interpreter: 'none',
      env: {
        HOME: '{{COMMANDER_HOME}}fae',
        PATH: '{{COMMANDER_HOME}}fae/hermes_env/bin:{{COMMANDER_HOME}}fae/.local/bin:/usr/bin:/bin',
      },
      restart_delay: 10000,
      max_restarts: 20,
      max_memory_restart: '2G',
      autorestart: true,
      watch: false,
      time: true,
    },
    {
      name: 'galadriel',
      script: '{{COMMANDER_HOME}}fae/hermes_env/bin/python',
      args: '-m hermes_cli.main --profile galadriel gateway run --replace',
      cwd: '{{COMMANDER_HOME}}fae',
      interpreter: 'none',
      env: {
        HOME: '{{COMMANDER_HOME}}fae',
        PATH: '{{COMMANDER_HOME}}fae/hermes_env/bin:{{COMMANDER_HOME}}fae/.local/bin:/usr/bin:/bin',
      },
      restart_delay: 10000,
      max_restarts: 20,
      max_memory_restart: '2G',
      autorestart: true,
      watch: false,
      time: true,
    },
    {
      name: 'elrond',
      script: '{{COMMANDER_HOME}}fae/hermes_env/bin/python',
      args: '-m hermes_cli.main --profile elrond gateway run --replace',
      cwd: '{{COMMANDER_HOME}}fae',
      interpreter: 'none',
      env: {
        HOME: '{{COMMANDER_HOME}}fae',
        PATH: '{{COMMANDER_HOME}}fae/hermes_env/bin:{{COMMANDER_HOME}}fae/.local/bin:/usr/bin:/bin',
      },
      restart_delay: 10000,
      max_restarts: 20,
      max_memory_restart: '2G',
      autorestart: true,
      watch: false,
      time: true,
    },
    {
      name: 'eomer',
      script: '{{COMMANDER_HOME}}fae/hermes_env/bin/python',
      args: '-m hermes_cli.main --profile eomer gateway run --replace',
      cwd: '{{COMMANDER_HOME}}fae',
      interpreter: 'none',
      env: {
        HOME: '{{COMMANDER_HOME}}fae',
        PATH: '{{COMMANDER_HOME}}fae/hermes_env/bin:{{COMMANDER_HOME}}fae/.local/bin:/usr/bin:/bin',
      },
      restart_delay: 10000,
      max_restarts: 20,
      max_memory_restart: '2G',
      autorestart: true,
      watch: false,
      time: true,
    },
  ],
};
