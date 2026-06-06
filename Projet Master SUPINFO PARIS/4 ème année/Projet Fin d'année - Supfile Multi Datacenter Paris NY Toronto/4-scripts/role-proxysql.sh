#!/bin/bash
# role-proxysql.sh — ProxySQL read/write splitting in front of Galera
# App connects to :6033 → ProxySQL routes writes to primary, reads to all nodes
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ proxysql: ${SITE}"

wget -q https://github.com/sysown/proxysql/releases/download/v2.5.5/proxysql_2.5.5-ubuntu22_amd64.deb -O /tmp/proxysql.deb
apt-get install -yq /tmp/proxysql.deb; rm /tmp/proxysql.deb

DB_LOCAL="${WEB_NET}.31"
DB_PARIS="192.168.99.31"; DB_NY="192.168.99.61"
DB_TOR="100.126.8.98"  # Toronto consolidated on single VM: 100.126.8.98

cat > /etc/proxysql.cnf <<EOF
datadir="/var/lib/proxysql"
admin_variables={ admin_credentials="admin:Admin2024!"; mysql_ifaces="127.0.0.1:6032" }
mysql_variables={
    threads=4; max_connections=2048; interfaces="0.0.0.0:6033"
    monitor_username="proxysql_mon"; monitor_password="ProxyMon2024!"
    default_schema="supfile"
}
mysql_servers=(
    { address="${DB_LOCAL}", port=3306, hostgroup_id=10, weight=1000, comment="local-writer" },
    { address="${DB_LOCAL}", port=3306, hostgroup_id=20, weight=1000, comment="local-reader" },
    { address="${DB_PARIS}", port=3306, hostgroup_id=20, weight=300,  comment="paris-reader" },
    { address="${DB_NY}",    port=3306, hostgroup_id=20, weight=300,  comment="ny-reader" },
)
mysql_users=(
    { username="supfile_app", password="AppPass2024!", default_hostgroup=10, transaction_persistent=1 },
)
mysql_query_rules=(
    { rule_id=1, active=1, match_digest="^SELECT .* FOR UPDATE", destination_hostgroup=10, apply=1 },
    { rule_id=2, active=1, match_digest="^SELECT",               destination_hostgroup=20, apply=1 },
)
EOF

ufw allow from "${WEB_NET}.0/24"   to any port 6033 comment "proxysql-app"
ufw allow from "192.168.99.0/24"   to any port 6032 comment "proxysql-admin"
systemctl enable proxysql && systemctl start proxysql
echo "▶ proxysql done: app→:6033 admin→:6032 (admin/Admin2024!)"
