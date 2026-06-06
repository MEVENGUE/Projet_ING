#!/bin/bash
# role-web1.sh / role-web2.sh — Nginx + PHP + Suricata IPS
# Both nodes are identical; HAProxy controls which is active/passive
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ ${ROLE}: ${SITE} (${WEB_IP})"
apt-get install -yq nginx php8.1-fpm php8.1-mysql open-iscsi suricata

# iSCSI initiator — connects to SAN VIP (floating between storage1/storage2)
cat > /etc/iscsi/initiatorname.iscsi <<EOF
InitiatorName=iqn.2024-01.com.supfile:init-${ROLE}-${SITE}
EOF
cat >> /etc/iscsi/iscsid.conf <<EOF
node.startup = automatic
node.session.auth.authmethod = CHAP
node.session.auth.username = supfile-initiator
node.session.auth.password = SecurePass2024!
EOF
systemctl enable iscsid open-iscsi; systemctl start iscsid || true
mkdir -p /mnt/supfile-storage

WEB_IF=$(ip -o addr show | awk -v ip="$WEB_IP" '$4~ip{print $2}' | head -1)
suricata-update 2>/dev/null || true
cat > /etc/suricata/suricata.yaml <<EOF
%YAML 1.1
---
vars:
  address-groups:
    HOME_NET: "[10.10.0.0/16,192.168.0.0/16]"
    EXTERNAL_NET: "!HOME_NET"
af-packet:
  - interface: ${WEB_IF}
    threads: 1
    cluster-id: 99
    cluster-type: cluster_flow
outputs:
  - fast:
      enabled: yes
      filename: /var/log/suricata/fast.log
  - eve-log:
      enabled: yes
      filename: /var/log/suricata/eve.json
      types: [alert, http, dns]
rule-files:
  - /var/lib/suricata/rules/suricata.rules
EOF
systemctl enable suricata; systemctl start suricata || true

cat > /etc/nginx/sites-available/supfile <<'NGINX'
server {
    listen 80;
    server_name _;
    root /var/www/supfile/public;
    index index.php index.html;

    location = /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    location /api/ {
        try_files $uri $uri/ /index.php?$query_string;
        add_header Content-Type application/json;
        add_header X-Served-By $hostname;
    }
    # X-Accel-Redirect: app sets header, nginx streams file (inline viewer)
    location /internal/ {
        internal;
        alias /mnt/supfile-storage/user-files/;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    location ~ /\. { deny all; }
}
NGINX
ln -sf /etc/nginx/sites-available/supfile /etc/nginx/sites-enabled/supfile
rm -f /etc/nginx/sites-enabled/default

mkdir -p /var/www/supfile/public
cat > /var/www/supfile/public/index.php <<'PHP'
<?php header('Content-Type: application/json');
echo json_encode(['service'=>'SUPFile','node'=>gethostname(),'status'=>'ok','version'=>'1.0-poc']);
PHP
cat > /var/www/supfile/public/health.php <<'PHP'
<?php http_response_code(200); header('Content-Type: text/plain'); echo "OK";
PHP

ufw allow 80/tcp; ufw allow 443/tcp
systemctl enable nginx php8.1-fpm; systemctl restart nginx php8.1-fpm
echo "▶ ${ROLE} done: Nginx on ${WEB_IP}:80"
