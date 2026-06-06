#!/bin/bash
# role-storage3.sh — 3rd storage node (required: brief says "minimum 3 storage servers")
# Role: GlusterFS 3rd replica brick + iSCSI standby (manual DRP promotion)
# NOT in Heartbeat cluster (keeps HB simple). IS in GlusterFS (3-way replica = no split-brain)
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ storage3: ${SITE} san=${SAN_IP}"
apt-get install -yq tgt glusterfs-server mdadm

if ! blkid /dev/sdb1 &>/dev/null 2>&1; then
  parted -s /dev/sdb mklabel gpt
  parted -s /dev/sdb mkpart primary 0%  60%
  parted -s /dev/sdb mkpart primary 60% 100%
  sleep 2; partprobe /dev/sdb
fi
blkid /dev/sdb2 | grep -q ext4 || mkfs.ext4 -F -L "gluster-${SITE}-3" /dev/sdb2
mkdir -p /data/brick3
mount /dev/sdb2 /data/brick3 || true
grep -q "/dev/sdb2.*brick3" /etc/fstab || echo "/dev/sdb2 /data/brick3 ext4 defaults,nofail 0 2" >> /etc/fstab
mkdir -p /data/brick3/gluster

ufw allow from "${WEB_NET}.0/24" to any port 24007:24008 comment "glusterd"
ufw allow from "${WEB_NET}.0/24" to any port 49152:49200 comment "gluster-bricks"
ufw allow from "192.168.99.0/24" to any port 24007:24008 comment "glusterd-mgmt"
ufw allow from "192.168.99.0/24" to any port 49152:49200 comment "gluster-bricks-mgmt"
systemctl enable glusterd && systemctl start glusterd
echo "▶ storage3 done: GlusterFS 3rd brick ready at /data/brick3/gluster"
