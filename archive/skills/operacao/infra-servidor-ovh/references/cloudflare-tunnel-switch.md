# Cloudflare Tunnel — Server Migration Switch Procedure

## Architecture
The Cloudflare Tunnel (`cloudflared`) connects OUT to Cloudflare's edge. Routes are
managed REMOTELY in the Cloudflare Zero Trust dashboard, NOT in the local config.yml.

Both servers can share the same tunnel credentials. Only ONE server's cloudflared
should be running at a time — Cloudflare routes to whichever is connected.

## Switch Procedure (zero DNS change)

### 1. Ensure direct SSH access to both servers
Before stopping the tunnel, open port 22 on the old server's firewall:
```bash
# On old server
sudo ufw allow 22/tcp
```
Add SSH config entries for direct IP access:
```
Host ovh-old
  HostName <OLD_IP>
  User {{COMMANDER}}

Host ovh-new  
  HostName <NEW_IP>
  User {{COMMANDER}}fae
```

### 2. Stop cloudflared on old server
```bash
ssh ovh-old "sudo systemctl stop cloudflared"
```

### 3. Start cloudflared on new server
```bash
{{OVH_SSH_COMMAND}} "sudo systemctl start cloudflared"
# Enable on boot
{{OVH_SSH_COMMAND}} "sudo systemctl enable cloudflared"
```

### 4. Verify tunnel connected
```bash
{{OVH_SSH_COMMAND}} "sudo journalctl -u cloudflared --no-pager -n 5 | grep Registered"
# Should show: "Registered tunnel connection connIndex=..."
```

### 5. Test all subdomains
```bash
for host in oesteodontologia.com.br dashboard.oesteodontologia.com.br \
  evolution.oesteodontologia.com.br sia.oesteodontologia.com.br \
  webhook.oesteodontologia.com.br {{BLOG_URL}}; do
  echo -n "$host: "
  curl -s -o /dev/null -w '%{http_code}' "https://$host/"
  echo ""
done
```

### 6. Fix SSH host key
The new server has a different SSH host key. Clean up:
```bash
ssh-keygen -R ssh.oesteodontologia.com.br
ssh -o StrictHostKeyChecking=accept-new ssh.oesteodontologia.com.br "echo OK"
```

## Rollback
```bash
{{OVH_SSH_COMMAND}} "sudo systemctl stop cloudflared"
ssh ovh-old "sudo systemctl start cloudflared"
```
~30 seconds downtime.

## Critical: Local config.yml is IGNORED
The `/etc/cloudflared/config.yml` on the server is a LOCAL cache. Routes are defined
in the Cloudflare dashboard. Adding a route to the local file does NOT make it active.
The tunnel receives its configuration from Cloudflare on connection.
