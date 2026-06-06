#!/bin/bash
# role-lb.sh — HAProxy + Keepalived VIP + WireGuard gateway
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ lb: ${SITE}"
apt-get install -yq haproxy keepalived

case "$SITE" in
  paris) WEB1="10.10.1.11"; WEB2="10.10.1.12"; VIP="10.10.1.100"
         PROXY="10.10.1.32"; REMOTE_WEB="10.10.2.11"
         WG_ADDR="10.20.0.1/24" ;;
  ny)    WEB1="10.10.2.11"; WEB2="10.10.2.12"; VIP="10.10.2.100"
         PROXY="10.10.2.32"; REMOTE_WEB="10.10.1.11"
         WG_ADDR="10.20.0.2/24" ;;
esac

WEB_IF=$(ip -o addr show | awk -v ip="$WEB_IP" '$4~ip{print $2}' | head -1)

# HAProxy
mkdir -p /etc/haproxy /var/run/haproxy
cat > /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log local0
    maxconn 10000
    user haproxy
    group haproxy
    daemon
    stats socket /var/run/haproxy/admin.sock mode 660 level admin

defaults
    log     global
    mode    http
    option  httplog
    option  forwardfor
    option  http-server-close
    timeout connect 5s
    timeout client  30s
    timeout server  30s

# Stats (management interface only)
frontend stats
    bind ${MGMT_IP}:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:SUPFile2024!
    stats show-node

# Main HTTP entry point
frontend http_front
    bind *:80
    # IP ban — list populated by ban-sync cron every 5 min
    acl banned src -f /etc/haproxy/banned_ips.txt
    http-request deny deny_status 403 if banned
    # Brute-force rate limit
    stick-table type ip size 100k expire 30s store http_req_rate(10s)
    http-request track-sc0 src
    acl rate_abuse sc_http_req_rate(0) gt 200
    http-request deny deny_status 429 if rate_abuse
    http-response set-header X-Served-By "${SITE}"
    default_backend local_web

# Active/Passive local cluster
# web1 = ACTIVE (primary), web2 = PASSIVE (backup keyword)
backend local_web
    balance roundrobin
    option httpchk GET /health HTTP/1.1\r\nHost:\ localhost
    http-check expect status 200
    server web1 ${WEB1}:80 check inter 2s rise 2 fall 3
    server web2 ${WEB2}:80 check inter 2s rise 2 fall 3 backup

# Cross-DC fallback — Active/Active behaviour
# Only used when ALL local servers are down
backend remote_dc
    option httpchk GET /health HTTP/1.1\r\nHost:\ localhost
    server remote ${REMOTE_WEB}:80 check inter 5s
EOF

touch /etc/haproxy/banned_ips.txt
mkdir -p /etc/haproxy/peer-bans
ufw allow 80/tcp; ufw allow 443/tcp; ufw allow 8404/tcp
systemctl enable haproxy && systemctl restart haproxy

# Keepalived — floating VIP (Active/Passive inside DC)
cat > /etc/keepalived/keepalived.conf <<EOF
global_defs { router_id LB_${SITE^^}; enable_script_security }
vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2; weight 2; user root
}
vrrp_instance VI_1 {
    state MASTER
    interface ${WEB_IF}
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication { auth_type PASS; auth_pass SUPFileVRRP }
    virtual_ipaddress { ${VIP}/24 }
    track_script { chk_haproxy }
    notify_master  "/bin/echo MASTER  >> /var/log/keepalived.log"
    notify_backup  "/bin/echo BACKUP  >> /var/log/keepalived.log"
    notify_fault   "/bin/echo FAULT   >> /var/log/keepalived.log"
}
EOF
ufw allow 51820/udp comment "wireguard"
systemctl enable keepalived && systemctl restart keepalived

# WireGuard — inter-DC encryption
# Keys generated at provision; share pubkey with teammates (see README Phase 3)
mkdir -p /etc/wireguard && chmod 700 /etc/wireguard
[ -f /etc/wireguard/privatekey ] || {
  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
  chmod 600 /etc/wireguard/privatekey
}
PRIVKEY=$(cat /etc/wireguard/privatekey)
cat > /etc/wireguard/wg0.conf <<EOF
# SUPFile WireGuard — ${SITE^^} gateway
# Algorithm: ChaCha20-Poly1305 (encryption) + Curve25519 (key exchange) + BLAKE2s (MAC)
# Fill in peer PublicKey and Endpoint after key exchange with teammates (see README Phase 3)
[Interface]
Address    = ${WG_ADDR}
PrivateKey = ${PRIVKEY}
ListenPort = 51820
PostUp     = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${WEB_IF} -j MASQUERADE
PostDown   = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${WEB_IF} -j MASQUERADE

[Peer]
# Teammate 1 — fill in after key exchange
PublicKey  = REPLACE_WITH_PEER1_PUBKEY
AllowedIPs = 10.20.0.X/32,10.10.X.0/24,192.168.X.0/24
Endpoint   = REPLACE_WITH_PEER1_MGMT_IP:51820
PersistentKeepalive = 25

[Peer]
# Teammate 2 — fill in after key exchange
PublicKey  = REPLACE_WITH_PEER2_PUBKEY
AllowedIPs = 10.20.0.X/32,10.10.X.0/24
Endpoint   = REPLACE_WITH_PEER2_MGMT_IP:51820
PersistentKeepalive = 25
EOF
chmod 600 /etc/wireguard/wg0.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p

# Ban-sync: merge fail2ban + DB bans → reload HAProxy every 5 min
cat > /usr/local/bin/ban-sync.sh <<'BAN'
#!/bin/bash
BANFILE="/etc/haproxy/banned_ips.txt"
TMP=$(mktemp)
# Local fail2ban
fail2ban-client banned 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' >> "$TMP" || true
# Peer bans synced from other DCs (rsync job on backup-toronto pushes these)
cat /etc/haproxy/peer-bans/*.txt 2>/dev/null >> "$TMP" || true
# DB-driven permanent bans
mysql -u supfile_ro -pReadOnly2024 -h "${WEB_NET}.32" supfile \
  -se "SELECT ip_address FROM ip_bans WHERE expires_at IS NULL OR expires_at>NOW();" \
  2>/dev/null >> "$TMP" || true
sort -u "$TMP" | grep -E '^[0-9]' > "$BANFILE"
rm "$TMP"
echo "[$(date)] Ban list: $(wc -l < $BANFILE) entries"
BAN
chmod +x /usr/local/bin/ban-sync.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/ban-sync.sh >> /var/log/ban-sync.log 2>&1") | crontab -

echo "▶ lb done: vip=${VIP} wg=$(cat /etc/wireguard/publickey)"
