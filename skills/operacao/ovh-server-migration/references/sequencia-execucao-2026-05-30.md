# Sequência de Execução — Migração 30/05/2026

## Linha do Tempo

| Hora | Ação |
|------|------|
| 16:00 | Início — inventário completo do servidor antigo |
| 16:10 | Criação usuário {{COMMANDER}}fae no servidor novo (142.4.215.215) |
| 16:12 | SSH keys copiadas, sudo NOPASSWD configurado |
| 16:14 | Pacotes base instalados (Docker, Node, Python, PM2, ZSH, CLIs) |
| 16:17 | Cloudflared configurado (NÃO iniciado) |
| 16:18 | UFW ativo, timezone America/Cuiaba |
| 16:20 | Hermes Agent 0.14.0 instalado |
| 16:22 | OpenCode CLI transferido (OVH→OVH, 30 MB/s) |
| 16:24 | Cron jobs configurados |
| 16:25 | Chave SSH de migração criada no servidor antigo |
| 16:27 | Transferências iniciadas (OVH→OVH) |
| 16:28 | pycode-cerebro transferido (575 MB, 68s) |
| 16:30 | SIA transferido (13 GB, excluindo .venv) |
| 16:31 | Docker containers parados no antigo |
| 16:32 | Docker volumes copiados (640 MB total) |
| 16:33 | /var/www movido para local correto no novo |
| 16:35 | Ambiente Thaísa transferido (277 MB) |
| 16:36 | Webhooks corrigidos (paths, venvs) |
| 16:38 | PM2 online (pycode-blog, webhook-meta) |
| 16:40 | Docker compose up no novo (build + start) |
| 16:48 | Docker: 7/7 containers UP |
| 16:50 | Acesso SSH por IP testado em ambos servidores |
| 17:12 | Switch Cloudflare Tunnel executado |
| 17:13 | Todos subdomínios verificados (200) |
| 17:14 | Licença Evolution ativada pelo {{COMMANDER}} |
| 17:15 | Thaísa 5/5 agentes ativos |
| 17:20 | SIA iniciado |
| 17:22 | Venv webhook-whatsapp recriado (bug de path hardcoded) |
| 17:25 | Relatório final |

## Lições da Execução

1. **Transferência OVH→OVH é 30x mais rápida** que Mac→OVH. O binário OpenCode de 145 MB levou 4s via OVH→OVH vs 120s+ timeout via Mac.
2. **Sempre recriar venvs** — o rsync preserva paths hardcoded que quebram com username diferente.
3. **PM2 + venv = wrapper script** — `--interpreter` sozinho não ativa o venv.
4. **Acesso IP direto antes do switch** é essencial — evita perda total de acesso.
5. **Evolution API perde instâncias** com novo `instance_id` — recriação necessária.
