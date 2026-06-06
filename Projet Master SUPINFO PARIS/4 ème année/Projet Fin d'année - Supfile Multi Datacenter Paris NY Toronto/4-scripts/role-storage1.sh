#!/bin/bash
# role-storage1.sh — iSCSI SAN primary, RAID-1, Heartbeat master, GlusterFS
# SAN traffic is isolated on VLAN 2 (192.168.X.0/24) — separate from web traffic
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ storage1: ${SITE} san=${SAN_IP}"
apt-get install -yq tgt mdadm heartbeat glusterfs-server

SAN_IF=$(ip -o addr show | awk -v ip="$SAN_IP" '$4~ip{print $2}' | head -1)
SAN2="${SAN_NET}.22"; SAN_VIP="${SAN_NET}.200"
PEER_ST1="192.168.99.51"  # mgmt IP of storage1-ny (for GlusterFS)

echo "SAN iface: ${SAN_IF}"

# RAID-1 on /dev/sdb (extra disk added by Vagrant)
# sdb1 → iSCSI LUN (RAID-1 mirror), sdb2 → GlusterFS brick
if ! blkid /dev/sdb1 &>/dev/null 2>&1; then
  parted -s /dev/sdb mklabel gpt
  parted -s /dev/sdb mkpart primary 0%  60%
  parted -s /dev/sdb mkpart primary 60% 100%
  sleep 2; partprobe /dev/sdb
fi

# Create RAID-1 degraded (storage2 joins later to complete mirror)
if ! mdadm --detail /dev/md0 &>/dev/null 2>&1; then
  mdadm --create /dev/md0 --level=1 --raid-devices=2 \
    --metadata=1.2 --name=supfile-san /dev/sdb1 missing
  echo "RAID-1 created degraded — storage2 will complete the mirror"
fi

# GlusterFS brick partition (ext4, no RAID — GlusterFS replication handles redundancy)
blkid /dev/sdb2 | grep -q ext4 || mkfs.ext4 -F -L "gluster-${SITE}-1" /dev/sdb2
mkdir -p /data/brick1
mount /dev/sdb2 /data/brick1 || true
grep -q "/dev/sdb2" /etc/fstab || echo "/dev/sdb2 /data/brick1 ext4 defaults,nofail 0 2" >> /etc/fstab
mkdir -p /data/brick1/gluster

mdadm --detail --scan >> /etc/mdadm/mdadm.conf 2>/dev/null || true

# iSCSI target — binds to SAN VLAN IP only (NOT web IP)
mkdir -p /data/iscsi
[ -f /data/iscsi/lun0.img ] || dd if=/dev/zero of=/data/iscsi/lun0.img bs=1M count=4096 status=progress

cat > /etc/tgt/conf.d/supfile.conf <<EOF
<target iqn.2024-01.com.supfile:storage>
    bind-address  ${SAN_IP}
    backing-store /dev/md0
    incominguser  supfile-initiator SecurePass2024!
    initiator-address ${SAN_NET}.0/24
    write-cache   off
</target>
EOF
ufw allow from "${SAN_NET}.0/24" to any port 3260 comment "iscsi"
ufw allow from "${WEB_NET}.0/24" to any port 24007:24008 comment "glusterd"
ufw allow from "${WEB_NET}.0/24" to any port 49152:49200 comment "gluster-bricks"
ufw allow from "192.168.99.0/24" to any port 24007:24008 comment "glusterd-mgmt"
ufw allow from "192.168.99.0/24" to any port 49152:49200 comment "gluster-bricks-mgmt"
systemctl enable tgt && systemctl restart tgt

# Heartbeat — SAN VIP failover (storage1 = MASTER, storage2 = SLAVE)
# When storage1 dies: storage2 acquires SAN_VIP and starts tgt
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

echo "▶ storage1 done: san_vip=${SAN_VIP} iscsi=iqn.2024-01.com.supfile:storage"
echo "▶ NEXT: run post-provision/gluster-setup.sh after all sites are up"
