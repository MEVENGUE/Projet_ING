#!/bin/bash
# Global HAProxy entry point on toronto — health-aware intersite load balancing
# Balances between lb-paris (100.69.138.20) and lb-ny (100.84.166.8)
# Run from lb-paris via run-toronto-haproxy.sh

set -e

echo "=== Install HAProxy ==="
apt-get install -yq haproxy

echo "=== Write HAProxy config ==="
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    maxconn 4096
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor
    option  http-server-close
    timeout connect 5s
    timeout client  30s
    timeout server  30s
    retries 3

# Global stats + Prometheus
frontend stats
    bind 0.0.0.0:8405
    stats enable
    stats uri /stats
    stats refresh 5s
    stats auth admin:SUPFile2024!
    stats show-node
    http-request use-service prometheus-exporter if { path /metrics }

# Global HTTP entry point
frontend supfile-global
    bind 0.0.0.0:80
    default_backend supfile-dcs

backend supfile-dcs
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200

    server paris 100.69.138.20:80 check inter 5s fall 2 rise 2
    server ny    100.84.166.8:80  check inter 5s fall 2 rise 2
EOF

echo "=== Enable + start HAProxy ==="
systemctl enable haproxy
systemctl restart haproxy
sleep 3
systemctl status haproxy --no-pager | head -5

echo "=== Open port 80 and 8405 ==="
ufw allow 80/tcp 2>/dev/null || true
ufw allow 8405/tcp 2>/dev/null || true

echo "=== Health check — round-robin test ==="
for i in 1 2 3 4; do
  echo -n "Request $i: "
  curl -s --max-time 3 http://127.0.0.1/health || echo "FAIL"
done

echo ""
echo "=== HAProxy stats ==="
curl -s --user admin:SUPFile2024! "http://127.0.0.1:8405/stats;csv" \
  | grep -v "^#" | cut -d"," -f1,2,18,19 | head -10

echo "DONE — global entry point: http://100.126.8.98"
