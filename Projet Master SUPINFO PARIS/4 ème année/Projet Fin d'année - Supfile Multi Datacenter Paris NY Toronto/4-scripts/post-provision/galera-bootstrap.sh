#!/bin/bash
# post-provision/galera-bootstrap.sh
# STEP 1 — on db-paris: sudo bash galera-bootstrap.sh --primary
# STEP 2 — on db-ny and db-toronto: sudo bash galera-bootstrap.sh
set -euo pipefail
MODE="${1:-}"
if [ "$MODE" = "--primary" ]; then
  echo "==> Bootstrapping PRIMARY Galera node..."
  galera_new_cluster; sleep 5
  mysql -u root < /tmp/supfile-schema.sql
  mysql -u root -e "SHOW STATUS LIKE 'wsrep_%';" | grep -E "wsrep_cluster_size|wsrep_ready|wsrep_local_state_comment"
  echo "==> PRIMARY done. Now run on db-ny and db-toronto: sudo bash galera-bootstrap.sh"
else
  echo "==> Joining cluster..."; systemctl start mariadb; sleep 5
  mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
fi
