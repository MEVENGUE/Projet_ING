#!/bin/bash
# role-monitor.sh — Wazuh SIEM + Prometheus + Grafana (Toronto monitoring VM)
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "▶ monitor: Toronto"

ufw allow 1514/tcp comment "wazuh-syslog"
ufw allow 1515/tcp comment "wazuh-enrollment"
ufw allow 55000/tcp comment "wazuh-api"
ufw allow 443/tcp  comment "wazuh-dashboard"
ufw allow 9090/tcp comment "prometheus"
ufw allow 3000/tcp comment "grafana"
ufw allow 9100/tcp comment "node-exporter"

# Node Exporter
NE_VER="1.7.0"
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NE_VER}/node_exporter-${NE_VER}.linux-amd64.tar.gz" -O /tmp/ne.tar.gz
tar xf /tmp/ne.tar.gz -C /tmp
cp /tmp/node_exporter-${NE_VER}.linux-amd64/node_exporter /usr/local/bin/
rm -rf /tmp/node_exporter* /tmp/ne.tar.gz
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

printf '[Unit]\nDescription=Prometheus Node Exporter\nAfter=network.target\n[Service]\nUser=node_exporter\nExecStart=/usr/local/bin/node_exporter\nRestart=always\n[Install]\nWantedBy=multi-user.target\n' \
  > /etc/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable --now node_exporter

# Prometheus
PROM_VER="2.51.1"
wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz" -O /tmp/prom.tar.gz
tar xf /tmp/prom.tar.gz -C /tmp
cp /tmp/prometheus-${PROM_VER}.linux-amd64/{prometheus,promtool} /usr/local/bin/
rm -rf /tmp/prometheus* /tmp/prom.tar.gz
mkdir -p /etc/prometheus /var/lib/prometheus
useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true

cat > /etc/prometheus/prometheus.yml <<'PROMCFG'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: paris-nodes
    static_configs:
      - targets:
          - '100.69.138.20:9100'
          - '100.112.202.64:9100'
          - '100.95.209.14:9100'
          - '100.122.223.27:9100'
          - '100.79.11.48:9100'
          - '100.65.222.115:9100'
          - '100.126.63.76:9100'
          - '100.97.25.14:9100'
    labels:
      site: paris

  - job_name: ny-nodes
    static_configs:
      - targets:
          - '100.84.166.8:9100'
          - '100.102.26.5:9100'
          - '100.114.39.112:9100'
          - '100.93.154.48:9100'
          - '100.103.234.33:9100'
          - '100.121.176.58:9100'
          - '100.105.116.110:9100'
          - '100.100.6.35:9100'
    labels:
      site: ny

  - job_name: toronto-nodes
    # Toronto consolidated on single VM: 100.126.8.98
    static_configs:
      - targets: ['100.126.8.98:9100']
        labels:
          site: toronto

  - job_name: haproxy-paris
    static_configs:
      - targets: ['100.69.138.20:8404']
    labels:
      site: paris

  - job_name: haproxy-ny
    static_configs:
      - targets: ['100.84.166.8:8404']
    labels:
      site: ny
PROMCFG

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

printf '[Unit]\nDescription=Prometheus Monitoring\nAfter=network.target\n[Service]\nUser=prometheus\nExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus --storage.tsdb.retention.time=30d --web.listen-address=0.0.0.0:9090\nRestart=always\n[Install]\nWantedBy=multi-user.target\n' \
  > /etc/systemd/system/prometheus.service

systemctl daemon-reload
systemctl enable --now prometheus

# Grafana
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -qq
apt-get install -yq grafana
mkdir -p /etc/grafana/provisioning/datasources
cat > /etc/grafana/provisioning/datasources/prometheus.yml <<'DS'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://localhost:9090
    isDefault: true
DS
systemctl enable --now grafana-server

# Wazuh (only if enough RAM — needs >1.8GB)
RAM_MB=$(free -m | awk '/Mem:/{print $2}')
if [ "$RAM_MB" -gt 1800 ]; then
  echo "▶ Installing Wazuh manager..."
  curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
  cat > config.yml <<'WZ'
nodes:
  indexer:   [{name: node-1, ip: "127.0.0.1"}]
  server:    [{name: wazuh-1, ip: "127.0.0.1"}]
  dashboard: [{name: dashboard, ip: "127.0.0.1"}]
WZ
  bash wazuh-install.sh -a -i 2>&1 | tee /var/log/wazuh-install.log
  rm -f wazuh-install.sh config.yml
else
  echo "▶ SKIP Wazuh: only ${RAM_MB}MB RAM. Install manually after adding more RAM:"
  echo "    curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh && bash wazuh-install.sh -a"
fi

echo "▶ monitor done:"
echo "  Prometheus : http://${MGMT_IP:-192.168.99.91}:9090"
echo "  Grafana    : http://${MGMT_IP:-192.168.99.91}:3000  (admin/admin)"
