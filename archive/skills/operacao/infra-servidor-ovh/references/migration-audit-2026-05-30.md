# Auditoria de Migração — 30-31/05/2026

## Itens encontrados faltando após migração inicial

| # | Item | Status | Correção |
|---|------|:------:|----------|
| 1 | `sync-weekly-backup.sh` | ❌ Ausente | Copiado do antigo, paths ajustados |
| 2 | `obsidian/` vault | ❌ Ausente | Copiado do antigo (2.1 MB) |
| 3 | PM2 startup | ❌ Não configurado | `pm2 startup systemd` |
| 4 | `hermes_files/` (workspace) | ❌ Ausente | Copiado (168 KB) |
| 5 | `{{PROJECT_SLUG}}/` (projeto Django) | ❌ Ausente | Movido de `hermes-roshar/projetos/` |
| 6 | `pycode-cerebro/data/historico/` | ❌ Ausente | Copiado do antigo (808 KB, 24 arquivos) |
| 7 | `sintetizador.py` + `fechamento_diario.sh` | ❌ Ausentes | Copiados e adaptados |
| 8 | `fechamento-pycode` (PM2 cron) | ❌ Ausente | Recriado via crontab (PM2 cron bug) |
| 9 | Agentes em container Docker | ❌ Errado | Removido container, PM2+systemd nativos |
| 10 | Hostname `ns509999` | ❌ Padrão OVH | Alterado para `oesteodontologia.com.br` |
| 11 | Powerlevel10k / oh-my-zsh | ❌ Ausente | Instalado + config copiada |
| 12 | `hermes-agent` wrapper | ❌ Ausente | Criado em `~/.local/bin/` |
| 13 | `rotate-key` script | ❌ Ausente | Criado para Mac e OVH |
| 14 | `planejamento-diario/` | ❌ Ausente | Criado com templates |

## Aprendizados

1. **PM2 cron não dispara com status=stopped** — usar crontab do sistema
2. **Docker não é adequado para agentes Hermes** — gateway tenta iniciar bridge própria
3. **Symlinks em `~/.hermes/profiles/`** — se o diretório já existe, `ln -sf` cria symlink DENTRO
4. **Arquivos com owner root do Docker** — precisam de `chown` após migração
5. **Dados de runtime não estão no git** — `data/historico/` precisa ser copiado explicitamente
6. **Scripts de síntese têm paths hardcoded** — ajustar `{{COMMANDER}}` → `{{COMMANDER}}fae`
