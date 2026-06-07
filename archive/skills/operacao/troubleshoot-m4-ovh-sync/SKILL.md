---
name: troubleshoot-m4-ovh-sync
description: Diagnóstico de problemas no sync rsync M4 Mac ↔ OVH via Cloudflare Tunnel — openrsync limitations, iCloud Drive permissions, bulk connection drops.
category: operacao
---

<!--
Arquivo sanitizado para agent-ops-workflow.
Substitua os placeholders {{...}} pelos valores do seu time.
Veja docs/SETUP.md para instruções completas.
-->


# Troubleshoot: Sync M4 ↔ OVH via Cloudflare Tunnel

**⚠️ LEGADO: rsync substituído por git em mai/2026.**
A solução definitiva é o git monorepo `~/Dev/hermes-profiles/` + symlinks.
Veja a skill `hermes-profiles-git-sync` para o fluxo atual.
Este documento é mantido apenas para troubleshooting histórico de logs antigos.

## Gatilho

- {{COMMANDER}} reporta `unexpected end of file` no sync-rsync.log
- {{COMMANDER}} reporta `unrecognized option --append-verify`
- {{COMMANDER}} reporta `Operation not permitted` no vault Obsidian
- Sync muito lento ou cron não roda

## Diagnóstico Rápido

```bash
# 1. Verificar se o sync completou
grep "Sync concluido" ~/.hermes/logs/sync-rsync.log | tail -3

# 2. Verificar erros recentes
grep -E "unexpected end|unrecognized|Operation not permitted|error:" ~/.hermes/logs/sync-rsync.log | tail -10

# 3. Versão do rsync no Mac
rsync --version | head -2
```

## Problemas Conhecidos

### 1. `unexpected end of file` — Queda do Cloudflare Tunnel sob carga

**Causa:** O túnel cloudflared é estável para `echo SSH_OK`, mas sob carga bulk (dezenas de rsyncs sequenciais com compressão) ocorre queda intermitente.

**Mitigações (no sync-m4-ovh-complete.sh):**
- `--partial`: mantém arquivos parciais
- `--append`: retoma de onde parou
- `--bwlimit=5000`: limita 5MB/s para não saturar o túnel
- `ServerAliveCountMax=5` em vez de 3 (75s de tolerância)
- `|| true` em todos os rsyncs para não abortar o script

### 2. `unrecognized option --append-verify` — macOS usa openrsync

**Causa:** O macOS (inclusive M4) usa `openrsync`, compatível com rsync 2.6.9.
`--append-verify` só existe no rsync 3.x (Linux).

**Verificação:**
```bash
rsync --version
# Saída: "rsync version 2.6.9 compatible" ou "openrsync"
rsync --help | grep -- append
# Se "append" aparecer, --append funciona; --append-verify não
```

**Solução:** Usar `--append` em vez de `--append-verify`. Menos seguro (sem checksum extra), mas combinado com `--partial` é suficiente para retomar transferências.

### 3. `Operation not permitted` no vault iCloud — cron sem acesso

**Causa:** O cron/scheduled task no macOS não tem permissão para o caminho bruto do iCloud Drive:
`/Users/{{COMMANDER}}fae/Library/Mobile Documents/iCloud~md~obsidian/Documents/{{COMMANDER}}/`

**Solução:** Usar symlink no script:
```
M4_VAULT="$HOME/Obsidian"  # em vez do caminho iCloud completo
```
Verificar se o symlink existe: `ls -la ~/Obsidian`

### 4. Sync muito lento com cron a cada 10min

**Causa:** O script sincroniza 6 agentes × 3 tipos (skills, memórias, configs) + vault chunkado em 6 partes = ~30 conexões SSH por ciclo.

**Recomendação:** Ajustar cron para `*/60 * * * *` (1hora) em vez de `*/10`.

### 5. Risco de perda de dados com rsync bidirecional

**Problema estrutural:** O rsync PUSH+PULL sobrescreve o lado mais antigo quando ambos os lados editam o mesmo arquivo entre ciclos. Não há merge inteligente.

**Opções de solução (não implementadas):**
- Git como source of truth para memórias (merge textual explícito)
- Lock de escrita: apenas um lado escreve cada tipo de arquivo
- Padrão mestre-escravo: M4 escreve, OVH só lê (ou vice-versa)

## Logs Relevantes

- Log de sync: `~/.hermes/logs/sync-rsync.log`

## Padrão de Flags Rsync para Túnel Cloudflare

Para qualquer rsync atravessando Cloudflare Tunnel, usar:
```
--partial --append --bwlimit=5000 -o ServerAliveInterval=15 -o ServerAliveCountMax=5 --timeout=30
```

`--bwlimit` é o mais importante — sem ele o túnel satura com tráfego bulk.
