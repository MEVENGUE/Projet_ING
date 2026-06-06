#!/bin/bash
set -e
NY_WEB1="100.102.26.5"
SRC="/vagrant/webapp/SUPFile-VB-App/backend"

echo "=== Check python on web1-ny ==="
ssh -o StrictHostKeyChecking=no root@$NY_WEB1 "python3 --version"

echo "=== Setup /opt/supfile on web1-ny ==="
ssh -o StrictHostKeyChecking=no root@$NY_WEB1 "mkdir -p /opt/supfile/backend /opt/supfile/venv"

echo "=== Sync backend source ==="
rsync -az --delete "$SRC/" root@$NY_WEB1:/opt/supfile/backend/

echo "=== Install venv + deps on web1-ny ==="
ssh -o StrictHostKeyChecking=no root@$NY_WEB1 "
  python3 -m venv /opt/supfile/venv && \
  /opt/supfile/venv/bin/pip install --quiet --upgrade pip && \
  /opt/supfile/venv/bin/pip install --quiet -r /opt/supfile/backend/requirements.txt && \
  echo DEPS_OK
"

echo "=== Write NY env file ==="
ssh -o StrictHostKeyChecking=no root@$NY_WEB1 "mkdir -p /etc/supfile && cat > /etc/supfile/supfile.env << 'EOF'
DEPLOYMENT_MODE=hybrid
APP_ENV=production
DEBUG=false
PRIMARY_DC=NEW_YORK
FAILOVER_DC=PARIS
ACTIVE_ACTIVE=true

SECRET_KEY=supfile-paris-secret-key-32chars!!
JWT_SECRET_KEY=supfile-paris-jwt-secret-32chars!
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

HOST=0.0.0.0
PORT=8080

DATABASE_URL=mysql+pymysql://supfile_app:AppPass2024!@10.10.2.32:6033/supfile

STORAGE_BACKEND=local
UPLOAD_PATH=/mnt/supfile-storage/uploads
UPLOAD_REGION=ny-dc
CHUNK_UPLOAD_ENABLED=true
CHUNK_SIZE_MB=8
CHUNK_TMP_PATH=/tmp/supfile-chunks

AZURE_STORAGE_ACCOUNT_NAME=supfilestorage1407
AZURE_STORAGE_ACCOUNT_KEY=7kf+pmiomhKRHtmEmdIlo2yzEqLQ6ypCPT0d5tfe8Qr6acGCFphRn06xbQwSXv62U3lvvB71VPG9+AStd+4qAg==
AZURE_STORAGE_CONTAINER_NAME=supfile-files

BCRYPT_ROUNDS=12
MAX_FILE_SIZE_MB=100
ALLOWED_EXTENSIONS=txt,pdf,png,jpg,jpeg,gif,doc,docx,xls,xlsx,zip,mp4,avi,mkv,mov,wmv,flv,webm,mp3,wav,ogg,flac,aac,m4a,wma,ppt,pptx,rtf,csv,json,xml,html,css,js,py,java,cpp,c,md,rar,7z,tar,gz

BACKEND_PUBLIC_URL=http://100.84.166.8
OAUTH_CALLBACK_BASE_URL=http://100.84.166.8
CORS_ORIGINS=http://100.84.166.8,http://100.69.138.20,http://localhost:3000,http://localhost:5173

WAZUH=false
SURICATA=false
FAIL2BAN=true
UFW=true

TRUST_PROXY_HEADERS=true
HAPROXY_COMPAT=true
TAILSCALE_FUNNEL_COMPAT=true
EOF"

echo "=== Write systemd service ==="
ssh -o StrictHostKeyChecking=no root@$NY_WEB1 "cat > /etc/systemd/system/supfile.service << 'EOF'
[Unit]
Description=SUPFile API (FastAPI / Uvicorn)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=vagrant
Group=vagrant
WorkingDirectory=/opt/supfile/backend
EnvironmentFile=-/etc/supfile/supfile.env
ExecStart=/opt/supfile/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8080 --proxy-headers --forwarded-allow-ips=*
Restart=always
RestartSec=5
TimeoutStopSec=30
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF"

echo "=== Fix ownership + start ==="
ssh -o StrictHostKeyChecking=no root@$NY_WEB1 "
  chown -R vagrant:vagrant /opt/supfile && \
  systemctl daemon-reload && \
  systemctl enable supfile && \
  systemctl restart supfile && \
  sleep 5 && \
  systemctl status supfile --no-pager | head -6
"

echo "=== Health check via LB ==="
sleep 2
curl -s http://100.84.166.8/health
