# Transferência OVH→OVH — Comandos e Métricas (30/05/2026)

## Conexão entre servidores

```bash
# No servidor antigo — gerar chave sem passphrase
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_migrate -N '' -C 'migration-key'

# Adicionar ao servidor novo
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO0t...' >> ~/.ssh/authorized_keys

# SSH config no antigo (~/.ssh/config)
Host new-ovh
  HostName 142.4.215.215
  User {{COMMANDER}}fae
  IdentityFile ~/.ssh/id_ed25519_migrate
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
```

## Velocidade de transferência

OVH→OVH direto: **30 MB/s** (rsync com compressão)
Mac→OVH (via internet): ~1 MB/s (138 MB levariam 2+ minutos)

## Comandos de rsync utilizados

```bash
# Projetos (excluindo .venv, cache)
rsync -avz --exclude='.venv' --exclude='__pycache__' --exclude='node_modules' \
  {{COMMANDER_HOME}}/projects/pycode-cerebro/ new-ovh:{{COMMANDER_HOME}}fae/projects/pycode-cerebro/

# SIA (13 GB) — sem .venv
rsync -avz --exclude='.venv' --exclude='__pycache__' \
  {{COMMANDER_HOME}}/sia_projeto/ new-ovh:{{COMMANDER_HOME}}fae/sia_projeto/

# Docker volumes — containers PARADOS
rsync -avz -e 'ssh -i ~/.ssh/id_ed25519_migrate' \
  /var/lib/docker/volumes/oeste-odontologia_mysql_data/ \
  {{COMMANDER}}fae@142.4.215.215:/tmp/docker-volumes/mysql_data/

# Thaísa (300 MB)
sudo rsync -avz --exclude='.cache' --exclude='.pm2/logs' \
  /home/thaisa/ new-ovh:/home/thaisa/
```

## Métricas por diretório

| Diretório | Tamanho | Tempo | Velocidade |
|-----------|---------|-------|------------|
| pycode-cerebro | 575 MB | 68s | 8.4 MB/s |
| pycode-blog | 15 MB | < 5s | — |
| meta-webhook | 32 MB | < 5s | — |
| SIA (sem .venv) | 13 GB | ~7 min | ~31 MB/s |
| hermes-roshar | 171 MB | ~6s | ~28 MB/s |
| hermes-profiles | 175 MB | ~6s | ~29 MB/s |
| Thaísa home | 277 MB | ~10s | ~10.7 MB/s |
| Docker mysql | 195 MB | ~3s | ~40x speedup |
| Docker postgres | 124 MB | ~3s | ~5x speedup |
| Docker redis | 45 MB | ~2s | ~5.6x speedup |
| Docker dontus | 290 MB | ~3s | ~31x speedup |

## Ordem recomendada

1. Projetos pequenos primeiro (pycode-blog, meta-webhook)
2. Projetos médios (pycode-cerebro, hermes-roshar, profiles)
3. Projetos grandes (SIA — 13 GB)
4. Docker volumes (requer containers parados)
5. Thaísa (ambiente completo)
