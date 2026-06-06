#!/bin/bash
# base.sh — runs on EVERY VM before role script
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ base: ${ROLE}-${SITE}  web=${WEB_IP}  mgmt=${MGMT_IP}"

apt-get update -qq
apt-get install -yq curl wget vim htop net-tools dnsutils tcpdump \
  ufw fail2ban rsync cron apt-transport-https ca-certificates gnupg2 \
  wireguard wireguard-tools jq

hostnamectl set-hostname "${ROLE}-${SITE}"

# /etc/hosts — full cluster
grep -q "supfile-cluster-start" /etc/hosts && \
  sed -i '/supfile-cluster-start/,/supfile-cluster-end/d' /etc/hosts

cat >> /etc/hosts <<'HOSTS'
# supfile-cluster-start
# Paris — web VLAN
10.10.1.10  lb-paris
10.10.1.11  web1-paris
10.10.1.12  web2-paris
10.10.1.21  storage1-paris
10.10.1.22  storage2-paris
10.10.1.23  storage3-paris
10.10.1.31  db-paris
10.10.1.32  proxysql-paris
10.10.1.100 vip-paris
192.168.1.200 san-vip-paris
# New York — web VLAN
10.10.2.10  lb-ny
10.10.2.11  web1-ny
10.10.2.12  web2-ny
10.10.2.21  storage1-ny
10.10.2.22  storage2-ny
10.10.2.23  storage3-ny
10.10.2.31  db-ny
10.10.2.32  proxysql-ny
10.10.2.100 vip-ny
192.168.2.200 san-vip-ny
# Toronto — web VLAN (logical architecture; POC runs all roles on 100.126.8.98)
10.10.3.11  backup-toronto
10.10.3.12  coldweb-toronto
10.10.3.31  db-toronto
10.10.3.41  monitor-toronto
# Management IPs (intra-site, same physical machine)
192.168.99.10 mgmt-lb-paris
192.168.99.11 mgmt-web1-paris
192.168.99.12 mgmt-web2-paris
192.168.99.21 mgmt-storage1-paris
192.168.99.22 mgmt-storage2-paris
192.168.99.23 mgmt-storage3-paris
192.168.99.31 mgmt-db-paris
192.168.99.32 mgmt-proxysql-paris
192.168.99.40 mgmt-lb-ny
192.168.99.41 mgmt-web1-ny
192.168.99.42 mgmt-web2-ny
192.168.99.51 mgmt-storage1-ny
192.168.99.52 mgmt-storage2-ny
192.168.99.53 mgmt-storage3-ny
192.168.99.61 mgmt-db-ny
192.168.99.62 mgmt-proxysql-ny
# Toronto consolidated on single VM: 100.126.8.98 (Nadia — Debian 13)
192.168.99.70 mgmt-backup-toronto
192.168.99.71 mgmt-coldweb-toronto
192.168.99.81 mgmt-db-toronto
192.168.99.91 mgmt-monitor-toronto
# WireGuard production gateway IPs
10.20.0.1 gw-paris
10.20.0.2 gw-ny
10.20.0.3 gw-toronto
# supfile-cluster-end
HOSTS

# SSH keypair for inter-VM operations (rsync, backup, ban-sync)
[ -f /root/.ssh/id_rsa ] || \
  ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa -C "supfile-infra"
[ -f /tmp/supfile_id_rsa.pub ] && {
  cat /tmp/supfile_id_rsa.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
}

# SSH client config — includes 100.* for Tailscale cross-DC IPs
cat > /root/.ssh/config <<'SSHCFG'
Host 10.10.* 192.168.* 10.20.* 100.*
    StrictHostKeyChecking no
    ConnectTimeout 5
SSHCFG

# UFW — allow web VLANs, SAN, management, WireGuard backbone, and Tailscale
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow in on lo
ufw allow 22/tcp                                    comment "ssh"
ufw allow from 10.10.0.0/16   comment "web-vlans"
ufw allow from 192.168.0.0/16 comment "san-and-mgmt"
ufw allow from 10.20.0.0/24   comment "wireguard-backbone"
ufw allow from 100.64.0.0/10  comment "tailscale"
ufw --force enable

# Fail2ban
cp /tmp/configs/fail2ban/jail.local /etc/fail2ban/jail.local
systemctl enable fail2ban && systemctl restart fail2ban

# Tailscale — install then auto-connect
command -v tailscale &>/dev/null || curl -fsSL https://tailscale.com/install.sh | sh

# ── Tailscale Key ──────
AUTHKEY="tskey-auth-ke3ytLUm7y11CNTRL-63asr4BxqmMrMTYV2ZRimMY1pbPiG26qX"
# ─────────────────────────────────────────────────────────────

tailscale up \
  --authkey="$AUTHKEY" \
  --hostname="${ROLE}-${SITE}" \
  --accept-routes

echo "▶ Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'pending')"
echo "▶ base done: ${ROLE}-${SITE}"