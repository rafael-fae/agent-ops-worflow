# OVH Security Hardening — Procedimento Completo (01/06/2026)

## Sequência Aplicada e Testada

### 1. Docker — Portas em 127.0.0.1

Todos os serviços Docker devem expor portas apenas em localhost, nunca em 0.0.0.0:

```yaml
# docker-compose.yml — ANTES (inseguro)
ports:
  - "5432:5432"
  - "6379:6379"

# docker-compose.yml — DEPOIS (seguro)
ports:
  - "127.0.0.1:5432:5432"
  - "127.0.0.1:6379:6379"
```

O acesso externo é EXCLUSIVAMENTE via Cloudflare Tunnel (porta 80 → Nginx → serviços internos).

### 2. UFW — Firewall

```bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80/tcp        # Cloudflare Tunnel
sudo ufw allow 443/tcp       # HTTPS (Cloudflare)
sudo ufw allow 22/tcp        # SSH (até migrar para Tunnel)
sudo ufw allow from 127.0.0.1 # Localhost interno
sudo ufw --force enable
```

### 3. Fail2ban

```bash
# Ubuntu/Debian
sudo apt-get install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# Arch Linux
sudo pacman -S --noconfirm fail2ban
echo '[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600' | sudo tee /etc/fail2ban/jail.d/sshd.local
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

### 4. Unattended-upgrades (Ubuntu/Debian)

```bash
sudo apt-get install -y unattended-upgrades
# Security updates já vêm habilitadas por padrão
```

No Arch Linux, unattended-upgrades não existe. Usar timer systemd com `pacman -Syu` (cuidado: rolling release pode quebrar).

### 5. Remover usuário ubuntu

```bash
sudo userdel -r ubuntu
```

### 6. SSH — Desabilitar senha

```bash
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### 7. Verificação Final

```bash
sudo ufw status verbose
sudo fail2ban-client status
sudo systemctl status unattended-upgrades
sudo grep '^PasswordAuthentication' /etc/ssh/sshd_config
docker ps --format '{{.Names}} {{.Ports}}'  # todas devem mostrar 127.0.0.1
```

## Pitfalls

- **Ubuntu 24.04 SSH socket activation**: Portas são controladas pelo systemd (`ssh.socket`), NÃO pelo `sshd_config`. `Port 2222` no sshd_config é IGNORADO. Usar override em `/etc/systemd/system/ssh.socket.d/override.conf`.
- **UFW reinstall reseta regras**: `apt-get install --reinstall ufw` deixa o firewall INACTIVE e apaga todas as regras. Recriar regras antes de reativar.
- **Fechar porta 22 antes de testar nova porta = lockout**: SEMPRE testar a nova porta antes de remover a antiga do UFW.
