# Segurança de Servidor — Checklist OVH

> Aplicado em 01/06/2026 no servidor OVH (142.4.215.215) e Soyo (home server)

## Checklist Mínimo

| # | Item | OVH | Soyo |
|---|------|:---:|:----:|
| 1 | UFW ativo (deny incoming) | ✅ | ✅ |
| 2 | Docker ports em `127.0.0.1` | ✅ | — |
| 3 | Fail2ban (jail sshd) | ✅ | ✅ |
| 4 | PasswordAuthentication no | ✅ | ✅ |
| 5 | Unattended-upgrades | ✅ | ⚠️ Arch |
| 6 | Usuário `ubuntu` removido | ✅ | N/A |
| 7 | Senhas desabilitadas | ✅ | ✅ |
| 8 | Acesso IP direto bloqueado | ✅ | ✅ |

## Comandos de Instalação

### Ubuntu/Debian
```bash
sudo apt-get install -y ufw fail2ban unattended-upgrades
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw allow from 127.0.0.1
sudo ufw --force enable
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo userdel -r ubuntu
```

### Arch Linux
```bash
sudo pacman -S --noconfirm fail2ban
echo '[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600' | sudo tee /etc/fail2ban/jail.d/sshd.local
sudo systemctl enable --now fail2ban
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Docker — Fechar Portas

Todas as portas Docker devem bindar em `127.0.0.1`, nunca `0.0.0.0`:

```yaml
# ERRADO — exposto na internet
ports:
  - "5432:5432"

# CERTO — só localhost
ports:
  - "127.0.0.1:5432:5432"
```

## SSH Porta Backup (iptables REDIRECT)

Para ter porta SSH backup sem mexer no systemd socket (Ubuntu 24.04):

```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 2222 -j REDIRECT --to-port 22
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
```

**Cuidado:** Ubuntu 24.04 usa systemd socket activation para SSH. Editar `Port` no sshd_config não funciona. Usar iptables REDIRECT é o método seguro.

## Pitfalls

1. **Systemd socket activation** — Ubuntu 24.04 gerencia portas SSH via `/usr/lib/systemd/system/ssh.socket`. Mudar `Port` no sshd_config NÃO funciona. Usar override no socket OU iptables REDIRECT.
2. **UFW + iptables REDIRECT** — A regra PREROUTING sobrevive a `ufw reset` porque fica na tabela `nat`, não `filter`.
3. **Fail2ban log path** — Ubuntu usa `/var/log/auth.log`, Arch pode usar `/var/log/secure` ou journal. Verificar com `sudo fail2ban-client status sshd`.
