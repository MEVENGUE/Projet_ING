#!/bin/bash
# role-backup.sh — Toronto daily backup + ban-sync distributor
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
apt-get install -yq rsync cron tar mariadb-client
mkdir -p /backup/{paris,ny,tapes,logs}

cat > /usr/local/bin/supfile-backup.sh <<'BACKUP'
#!/bin/bash
DATE=$(date +%Y-%m-%d); LOG="/backup/logs/${DATE}.log"
SSH="ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no"
echo "[$(date)] ===== Backup ${DATE} =====" >> "$LOG"

sync() { rsync -avz --delete -e "$SSH" "root@$1:$2/" "$3/" >> "$LOG" 2>&1 && echo "[$(date)] OK  $4" >> "$LOG" || echo "[$(date)] ERR $4" >> "$LOG"; }

sync 100.122.223.27 /data/brick1/gluster /backup/paris/s1 paris-storage1
sync 100.79.11.48   /data/brick2/gluster /backup/paris/s2 paris-storage2
sync 100.65.222.115 /data/brick3/gluster /backup/paris/s3 paris-storage3
sync 100.93.154.48  /data/brick1/gluster /backup/ny/s1    ny-storage1
sync 100.103.234.33 /data/brick2/gluster /backup/ny/s2    ny-storage2
sync 100.121.176.58 /data/brick3/gluster /backup/ny/s3    ny-storage3

# DB dump from Paris Galera (Tailscale IP — management IP unreachable cross-DC)
mysqldump -h 100.126.63.76 -u supfile_ro -pReadOnly2024 \
  --single-transaction --routines supfile 2>>"$LOG" \
  | gzip > "/backup/paris/db-${DATE}.sql.gz" && echo "[$(date)] OK  db-dump" >> "$LOG"

# Tape archive (simulated: timestamped compressed archive)
tar czf "/backup/tapes/supfile-${DATE}.tar.gz" /backup/paris /backup/ny 2>>"$LOG"
echo "[$(date)] Tape: supfile-${DATE}.tar.gz" >> "$LOG"
find /backup/tapes -name "*.tar.gz" -mtime +30 -delete
echo "[$(date)] ===== Done =====" >> "$LOG"
BACKUP
chmod +x /usr/local/bin/supfile-backup.sh

# Ban-sync: pull DB bans → push to all LB nodes every 5 min
cat > /usr/local/bin/ban-distribute.sh <<'BANS'
#!/bin/bash
SSH="ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no"
TMP=$(mktemp)
mysql -h 100.126.63.76 -u supfile_ro -pReadOnly2024 supfile \
  -se "SELECT ip_address FROM ip_bans WHERE expires_at IS NULL OR expires_at>NOW();" \
  2>/dev/null > "$TMP" || true
for LB in 100.69.138.20 100.84.166.8; do
  rsync -q "$TMP" -e "$SSH" "root@${LB}:/etc/haproxy/peer-bans/toronto-db.txt" 2>/dev/null || true
done
rm "$TMP"
BANS
chmod +x /usr/local/bin/ban-distribute.sh

(crontab -l 2>/dev/null; cat <<'CRONS'
0  2  * * *  /usr/local/bin/supfile-backup.sh
*/5 * * * *  /usr/local/bin/ban-distribute.sh >> /var/log/ban-sync.log 2>&1
CRONS
) | crontab -
echo "▶ backup done: cron 02:00 daily, ban-sync every 5min"
