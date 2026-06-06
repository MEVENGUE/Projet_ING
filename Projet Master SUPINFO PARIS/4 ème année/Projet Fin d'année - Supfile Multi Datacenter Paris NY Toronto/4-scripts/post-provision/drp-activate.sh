#!/bin/bash
# post-provision/drp-activate.sh — Toronto emergency DRP activation
# Only run when BOTH Paris AND NY are unreachable. RTO target: <15 min.
set -euo pipefail
echo "╔══════════════════════════════════════════╗"
echo "║   SUPFile DRP ACTIVATION — Toronto       ║"
echo "╚══════════════════════════════════════════╝"
read -rp "Type 'ACTIVATE' to confirm: " C; [ "$C" = "ACTIVATE" ] || { echo "Cancelled"; exit 0; }
T=$(date +%s)
echo "[$(date)] DRP activation started by $(whoami)"

echo "[$(date)] 1/4 Starting Nginx cold standby..."
systemctl start nginx php8.1-fpm

echo "[$(date)] 2/4 Mounting backup data as storage..."
mkdir -p /mnt/supfile-storage/user-files
mount --bind /backup/paris/ /mnt/supfile-storage/ 2>/dev/null || \
  echo "WARNING: bind-mount failed — storage is read-only (last backup)"

echo "[$(date)] 3/4 Promoting Galera node to primary..."
systemctl start mariadb 2>/dev/null || true
mysql -u root -e "SET GLOBAL wsrep_provider_options='pc.bootstrap=YES';" 2>/dev/null || true
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

echo "[$(date)] 4/4 Starting WireGuard gateway..."
wg-quick up wg0 2>/dev/null || true

T2=$(date +%s); RTO=$((T2-T))
echo ""
echo "==> DRP ACTIVE in ${RTO} seconds"
echo "==> Toronto web: http://100.126.8.98 (consolidated VM — nginx, then DRP nginx takeover)"
echo "==> ACTION REQUIRED: Update DNS supfile.io → Toronto IP"
echo "==> RPO: up to 24h (last nightly backup)"
echo "[$(date)] DRP activation complete. RTO=${RTO}s" >> /var/log/drp.log
