# OVH Security Hardening — Procedimento Completo

## Sequência testada e aprovada (01/06/2026)

### 1. Docker — Fechar portas no host

Todas as portas de banco/aplicação devem ser bindadas em `127.0.0.1`, nunca em `0.0.0.0`.

```yaml
# docker-compose.yml — CORRETO
ports:
  - "127.0.0.1:5432:5432"   # PostgreSQL
  - "127.0.0.1:6379:6379"   # Redis
  - "127.0.0.1:8000:8000"   # Django
  - "127.0.0.1:6432:6432"   # PgBouncer
```

Acesso externo deve ser EXCLUSIVAMENTE via Cloudflare Tunnel (porta 80).

### 2. UFW — Firewall

```bash
sudo apt-get install -y ufw
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp          # SSH (fechar depois se migrar para Tunnel)
sudo ufw allow from 127.0.0.1   # localhost (Docker, Cloudflare Tunnel)
sudo ufw --force enable
```

### 3. Fail2ban

```bash
sudo apt-get install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

Verificar: `sudo fail2ban-client status sshd`

### 4. Unattended-upgrades

```bash
sudo apt-get install -y unattended-upgrades
# Já vem habilitado no Ubuntu 24.04
```

Verificar: `sudo unattended-upgrades --dry-run --debug`

### 5. Remover usuário ubuntu

```bash
sudo userdel -r ubuntu
```

### 6. Verificar senhas

```bash
sudo grep -E '{{COMMANDER}}|thaisa|ubuntu' /etc/shadow
# Senhas devem estar vazias (:) ou bloqueadas (!)
```

### 7. Portas abertas — auditoria

```bash
ss -tlnp | grep '0.0.0.0'
# Deve mostrar APENAS portas 22, 80, 443
# NUNCA: 5432, 6379, 8000, 6432, 8501 em 0.0.0.0
```

### ⚠️ SSH port migration TRAP

Ubuntu 24.04 usa systemd socket activation para SSH. As portas são controladas pelo `ssh.socket`, NÃO pelo `sshd_config`.

**Sequência correta:**
1. Adicionar porta extra via socket override
2. Testar conexão na nova porta
3. SÓ ENTÃO fechar porta antiga no UFW

**NUNCA fechar a 22 antes de testar a nova porta.**
