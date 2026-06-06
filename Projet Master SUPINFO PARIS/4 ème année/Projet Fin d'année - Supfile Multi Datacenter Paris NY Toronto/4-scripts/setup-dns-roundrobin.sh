#!/bin/bash
# DNS round-robin via dnsmasq on toronto
# supfile.poc resolves to both lb-paris (100.69.138.20) and lb-ny (100.84.166.8)
# Run from lb-paris via: sshpass -p 'root' ssh nadia@100.126.8.98 "echo root | su -c 'bash -s'" < setup-dns-roundrobin.sh

set -e

echo "=== Install dnsmasq ==="
apt-get install -yq dnsmasq

echo "=== Configure round-robin DNS ==="
cat > /etc/dnsmasq.d/supfile.conf << 'EOF'
# SUPFile Active/Active DNS round-robin
# supfile.poc resolves to lb-paris AND lb-ny alternating
address=/supfile.poc/100.69.138.20
address=/supfile.poc/100.84.166.8

# Also serve individual DC entries
address=/paris.supfile.poc/100.69.138.20
address=/ny.supfile.poc/100.84.166.8

# Listen on all interfaces
listen-address=0.0.0.0
bind-interfaces

# Don't forward plain hostname queries upstream
domain-needed
bogus-priv
EOF

echo "=== Disable systemd-resolved conflict on port 53 ==="
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true
# Point /etc/resolv.conf to localhost
echo "nameserver 127.0.0.1" > /etc/resolv.conf

echo "=== Start dnsmasq ==="
systemctl enable dnsmasq
systemctl restart dnsmasq
sleep 2
systemctl status dnsmasq --no-pager | head -5

echo "=== Open DNS port in UFW ==="
ufw allow 53/tcp 2>/dev/null || true
ufw allow 53/udp 2>/dev/null || true

echo "=== Verify round-robin resolution ==="
echo "--- Query 1 ---"
dig @127.0.0.1 supfile.poc +short
echo "--- Query 2 ---"
dig @127.0.0.1 supfile.poc +short
echo "--- Query 3 ---"
dig @127.0.0.1 supfile.poc +short

echo "=== Test HTTP round-robin ==="
for i in 1 2 3 4; do
  echo -n "Request $i: "
  curl -s --resolve supfile.poc:80:$(dig @127.0.0.1 supfile.poc +short | head -1) \
    http://supfile.poc/health 2>/dev/null || \
  curl -s http://$(dig @127.0.0.1 supfile.poc +short | head -1)/health
  echo ""
done

echo ""
echo "DNS nameserver: 100.126.8.98"
echo "Hostname: supfile.poc"
echo "Records: 100.69.138.20 (Paris), 100.84.166.8 (NY)"
echo "DONE"
