#!/bin/bash
# role-coldweb.sh — Toronto cold standby web server
# Nginx is STOPPED in normal operation. Started only during DRP activation.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "▶ coldweb: Toronto (DRP standby)"

apt-get install -yq nginx php8.1-fpm php8.1-mysql
mkdir -p /var/www/supfile/public /mnt/supfile-storage

cat > /etc/nginx/sites-available/supfile << 'NGINX'
server {
    listen 80;
    server_name _;
    root /var/www/supfile/public;
    index index.php index.html;

    location = /health {
        access_log off;
        return 200 "OK-DRP\n";
        add_header Content-Type text/plain;
    }

    location /api/ {
        try_files $uri $uri/ /index.php?$query_string;
        add_header Content-Type application/json;
    }

    location /internal/ {
        internal;
        alias /mnt/supfile-storage/user-files/;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    add_header X-Datacenter "toronto-drp" always;
    add_header X-Frame-Options SAMEORIGIN;
    location ~ /\. { deny all; }
}
NGINX

ln -sf /etc/nginx/sites-available/supfile /etc/nginx/sites-enabled/supfile
rm -f /etc/nginx/sites-enabled/default

cat > /var/www/supfile/public/index.php << 'PHP'
<?php
header('Content-Type: application/json');
echo json_encode([
    'service'  => 'SUPFile',
    'node'     => gethostname(),
    'site'     => 'toronto-drp',
    'status'   => 'drp-active',
    'note'     => 'This is the Toronto cold standby. Paris and NY are down.'
]);
PHP

ufw allow 80/tcp comment "nginx-drp"

# Nginx intentionally STOPPED — DRP activates it
systemctl enable nginx php8.1-fpm
systemctl stop nginx

echo "▶ coldweb done: STOPPED (normal). Start with: systemctl start nginx"
echo "▶ To activate during DRP: run post-provision/drp-activate.sh on backup-toronto"
