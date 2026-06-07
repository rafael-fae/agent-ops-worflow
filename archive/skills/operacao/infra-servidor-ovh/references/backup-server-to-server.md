# Backup Server-to-Server via tar Pipe

## Padrão: OVH antigo → Soyo (Home Server)

O OVH antigo não tem chave SSH configurada para o Soyo. A solução é usar o Mac como ponte SSH, ou pipe via SSH chain.

### Método 1 — Tar pipe via SSH chain (18GB em ~30min)

```bash
# Do Mac, pipe direto entre servidores
ssh soyo "ssh ovh-old 'sudo tar czf - /var/www /home 2>/dev/null' > ~/ovh-old.bak/backup-full.tar.gz"
```

**Vantagens:**
- Inclui arquivos ocultos, `.env`, `.venv`, configurações
- Zero perda de metadados (permissoẽs, timestamps)
- Único arquivo de saída
- Não requer chave SSH entre os servidores (usa o Mac como ponte)

**Verificar progresso:**
```bash
ssh soyo "ls -lh ~/ovh-old.bak/backup-full.tar.gz"
```

**Extrair depois:**
```bash
ssh soyo "cd ~/ovh-old.bak && tar xzf backup-full.tar.gz"
```

### Método 2 — Rsync direto (requer chave SSH entre servidores)

```bash
# Requer que OVH antigo tenha chave SSH para Soyo
rsync -avz ovh-old:/var/www/ soyo:~/ovh-old.bak/var-www/
```

## Pitfalls

- **OVH antigo sem acesso SSH ao Soyo**: O rsync direto falha com `Permission denied`. Usar tar pipe via Mac.
- **Sudo necessário**: Arquivos em `/var/www` e `/home` podem exigir `sudo`. O tar com `sudo` resolve.
- **Tamanho**: 18GB comprimido → ~8GB com tar czf (depende do conteúdo). Monitorar com `ls -lh` periódico.
- **Timeout**: Para volumes grandes, usar `background=true` ou `nohup`.
