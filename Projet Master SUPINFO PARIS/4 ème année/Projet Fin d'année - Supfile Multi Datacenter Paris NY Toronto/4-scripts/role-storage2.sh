#!/bin/bash
# role-storage2.sh — iSCSI SAN secondary, Heartbeat slave
# Completes the RAID-1 mirror when joined (see post-provision/raid-join.sh)
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ storage2: ${SITE} san=${SAN_IP}"
apt-get install -yq tgt mdadm heartbeat glusterfs-server

SAN_IF=$(ip -o addr show | awk -v ip="$SAN_IP" '$4~ip{print $2}' | head -1)
SAN_VIP="${SAN_NET}.200"

# Partition /dev/sdb (mirror target)
if ! blkid /dev/sdb1 &>/dev/null 2>&1; then
  parted -s /dev/sdb mklabel gpt
  parted -s /dev/sdb mkpart primary 0%  60%
  parted -s /dev/sdb mkpart primary 60% 100%
  sleep 2; partprobe /dev/sdb
fi
blkid /dev/sdb2 | grep -q ext4 || mkfs.ext4 -F -L "gluster-${SITE}-2" /dev/sdb2
mkdir -p /data/brick2
mount /dev/sdb2 /data/brick2 || true
grep -q "/dev/sdb2.*brick2" /etc/fstab || echo "/dev/sdb2 /data/brick2 ext4 defaults,nofail 0 2" >> /etc/fstab
mkdir -p /data/brick2/gluster

# iSCSI config (same as primary — activated by Heartbeat when VIP moves here)
cat > /etc/tgt/conf.d/supfile.conf <<EOF
<target iqn.2024-01.com.supfile:storage>
    bind-address  ${SAN_IP}
    backing-store /dev/sdb1
    incominguser  supfile-initiator SecurePass2024!
    initiator-address ${SAN_NET}.0/24
</target>
EOF
ufw allow from "${SAN_NET}.0/24" to any port 3260 comment "iscsi"
ufw allow from "${WEB_NET}.0/24" to any port 24007:24008 comment "glusterd"
ufw allow from "${WEB_NET}.0/24" to any port 49152:49200 comment "gluster-bricks"
ufw allow from "192.168.99.0/24" to any port 24007:24008 comment "glusterd-mgmt"
ufw allow from "192.168.99.0/24" to any port 49152:49200 comment "gluster-bricks-mgmt"
systemctl enable tgt; systemctl stop tgt || true  # Heartbeat controls this

cat > /etc/ha.d/ha.cf <<EOF
logfacility local0
keepalive 1
deadtime  10
warntime  6
initdead  60
bcast     ${SAN_IF}
node      storage1-${SITE}
node      storage2-${SITE}
EOF
cat > /etc/ha.d/haresources <<EOF
storage1-${SITE} IPaddr::${SAN_VIP}/24/${SAN_IF} tgt
EOF
cat > /etc/ha.d/authkeys <<EOF
auth 1
1 md5 SUPFileHB2024
EOF
chmod 600 /etc/ha.d/authkeys
systemctl enable heartbeat && systemctl restart heartbeat || true
systemctl enable glusterd && systemctl start glusterd
echo "▶ storage2 done: passive, ready to complete RAID-1 mirror"
