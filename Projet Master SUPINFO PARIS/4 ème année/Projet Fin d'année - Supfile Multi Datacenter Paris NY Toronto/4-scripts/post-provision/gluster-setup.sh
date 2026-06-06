#!/bin/bash
# post-provision/gluster-setup.sh — 3-way replica GlusterFS across Paris + NY
# Run ONCE from storage1-paris after ALL storage VMs on both sites are up
# Usage: vagrant ssh storage1-paris; sudo bash /tmp/scripts/post-provision/gluster-setup.sh
set -euo pipefail

P1="100.122.223.27"; P2="100.79.11.48"; P3="100.65.222.115"  # Paris Tailscale IPs
N1="100.93.154.48";  N2="100.103.234.33"; N3="100.121.176.58"  # NY Tailscale IPs

echo "==> Probing all GlusterFS peers..."
for PEER in $P2 $P3 $N1 $N2 $N3; do
  gluster peer probe "$PEER" || true; sleep 1
done
sleep 3; gluster peer status

echo "==> Creating 3-way replicated volume (6 bricks — 3 per site)..."
gluster volume create supfile-vol replica 3 \
  "${P1}:/data/brick1/gluster" \
  "${P2}:/data/brick2/gluster" \
  "${P3}:/data/brick3/gluster" \
  "${N1}:/data/brick1/gluster" \
  "${N2}:/data/brick2/gluster" \
  "${N3}:/data/brick3/gluster" \
  force

gluster volume set supfile-vol cluster.quorum-type auto
gluster volume set supfile-vol network.ping-timeout 10
gluster volume start supfile-vol
gluster volume info supfile-vol

mkdir -p /mnt/supfile-storage
mount -t glusterfs "localhost:/supfile-vol" /mnt/supfile-storage
grep -q "supfile-vol" /etc/fstab || \
  echo "localhost:/supfile-vol /mnt/supfile-storage glusterfs defaults,_netdev 0 0" >> /etc/fstab

mkdir -p /mnt/supfile-storage/user-files
echo "gluster-ok-$(date)" > /mnt/supfile-storage/.health

echo ""
echo "==> GlusterFS DONE. Now mount on web VMs:"
for VM in web1-paris web2-paris web1-ny web2-ny; do
  SITE="${VM##*-}"
  IP="${VM%%-*}" # just for display
  echo "    vagrant ssh ${VM} -- \"sudo mount -t glusterfs ${P1}:/supfile-vol /mnt/supfile-storage\""
done
