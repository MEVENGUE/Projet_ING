#!/bin/bash
set -e

DIST="/vagrant/webapp/SUPFile-VB-App/frontend/dist"
NY_WEB1="100.102.26.5"
NY_WEB2="100.114.39.112"

NGINX_CONF='server {
    listen 80;
    server_name _;

    root /opt/supfile-app;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300;
    }

    location /health {
        return 200 "{\"node\":\"web1-ny\",\"status\":\"ok\"}";
        add_header Content-Type application/json;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}'

deploy_to() {
    local HOST=$1
    local NODE=$2
    echo "=== Deploying to $HOST ($NODE) ==="

    # Create app dir and copy files
    ssh -o StrictHostKeyChecking=no root@$HOST "mkdir -p /opt/supfile-app"
    rsync -az --delete "$DIST/" root@$HOST:/opt/supfile-app/

    # Deploy nginx config (node-specific health response)
    CONF="${NGINX_CONF/web1-ny/$NODE}"
    echo "$CONF" | ssh -o StrictHostKeyChecking=no root@$HOST \
      "cat > /etc/nginx/sites-available/supfile && \
       ln -sf /etc/nginx/sites-available/supfile /etc/nginx/sites-enabled/supfile && \
       rm -f /etc/nginx/sites-enabled/default && \
       nginx -t && systemctl reload nginx && echo ${NODE}_OK"
}

deploy_to $NY_WEB1 "web1-ny"

# web2-ny offline, skip
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$NY_WEB2 'echo reachable' 2>/dev/null; then
    deploy_to $NY_WEB2 "web2-ny"
else
    echo "web2-ny unreachable, skipping"
fi

echo "=== Verify ==="
curl -s http://$NY_WEB1/health
