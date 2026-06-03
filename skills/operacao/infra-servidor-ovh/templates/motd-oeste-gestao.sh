#!/bin/bash
# MOTD — {{PROJECT_NAME}} (OVH)
# Instalar: sudo cp este arquivo para /etc/update-motd.d/99-{{PROJECT_SLUG}} && sudo chmod +x /etc/update-motd.d/99-{{PROJECT_SLUG}}
# Desabilitar mensagens padrão: sudo chmod -x /etc/update-motd.d/00-header /etc/update-motd.d/10-help-text /etc/update-motd.d/50-landscape-sysinfo /etc/update-motd.d/50-motd-news /etc/update-motd.d/90-updates-available

echo ''
echo '╔══════════════════════════════════════════════════╗'
echo '║        🦷 {{PROJECT_NAME_UPPER}} — Servidor OVH          ║'
echo '║        oesteodontologia.com.br                   ║'
echo '╚══════════════════════════════════════════════════╝'

# System info
RAM_USED=$(free -h | awk '/^Mem:/ {print $3}' | sed 's/Gi/G/')
RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}' | sed 's/Gi/G/')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PCT=$(df -h / | awk 'NR==2 {print $5}')
UPTIME=$(uptime -p | sed 's/up //')

echo "  Ubuntu 24.04  |  Intel Xeon E5-1620v2  |  ${RAM_USED} / ${RAM_TOTAL} RAM"
echo "  Uptime: ${UPTIME}  |  Disk: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT})"

# Docker status
TOTAL=$(docker ps -a --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')
RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')
FILLED=$(( RUNNING * 10 / (TOTAL > 0 ? TOTAL : 1) ))
BAR=''
for i in $(seq 1 10); do
  if [ $i -le $FILLED ]; then BAR="${BAR}█"; else BAR="${BAR}░"; fi
done
echo ''
echo "  Docker: ${BAR} ${RUNNING}/${TOTAL} running"

# Active containers
if [ $RUNNING -gt 0 ]; then
  docker ps --format '  ▸ {{.Names}} ({{.Status}})' 2>/dev/null | sed 's/ Up / ↑ /' | sed 's/ (healthy)/ ✅/' | sed 's/ (unhealthy)/ ❌/'
fi
echo ''
