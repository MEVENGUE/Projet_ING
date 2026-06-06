#!/bin/bash
# post-provision/deploy-node-exporters.sh
# Run from monitor-toronto. Installs Prometheus node_exporter on all VMs.
set -euo pipefail
NE="1.7.0"
INSTALL='VER=1.7.0; wget -q "https://github.com/prometheus/node_exporter/releases/download/v${VER}/node_exporter-${VER}.linux-amd64.tar.gz" -O /tmp/ne.tar.gz; tar xf /tmp/ne.tar.gz -C /tmp; cp /tmp/node_exporter-${VER}.linux-amd64/node_exporter /usr/local/bin/; useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null||true; printf "[Unit]\nDescription=Node Exporter\n[Service]\nUser=node_exporter\nExecStart=/usr/local/bin/node_exporter\nRestart=always\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/node_exporter.service; systemctl daemon-reload; systemctl enable --now node_exporter; ufw allow 9100/tcp 2>/dev/null||true; echo "OK $(hostname)"'

HOSTS=(
  # Paris (Tailscale IPs — management IPs unreachable cross-DC)
  100.69.138.20 100.112.202.64 100.95.209.14
  100.122.223.27 100.79.11.48 100.65.222.115 100.126.63.76 100.97.25.14
  # NY (Tailscale IPs)
  100.84.166.8 100.102.26.5 100.114.39.112
  100.93.154.48 100.103.234.33 100.121.176.58 100.105.116.110 100.100.6.35
  # Toronto consolidated on single VM: 100.126.8.98 (Nadia — Debian 13, Tailscale)
  100.126.8.98
)
for H in "${HOSTS[@]}"; do
  printf "%-20s" "${H}..."
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=4 "root@${H}" "bash -s" <<< "$INSTALL" 2>/dev/null || echo "SKIP"
done
echo "Done. Prometheus targets: http://100.126.8.98:9090/targets"
