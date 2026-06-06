#!/bin/bash
echo "=== Stop glusterd ==="
sudo systemctl stop glusterd
sudo pkill -9 glusterfsd 2>/dev/null
sleep 2
echo "=== TS IP ==="
sudo tailscale ip -4 2>&1 | head -2
echo "=== Test port 22 to s1-paris (sanity) ==="
timeout 3 bash -c "echo > /dev/tcp/100.122.223.27/22" && echo SSH_OK || echo SSH_FAIL
echo "=== Start glusterd ==="
sudo systemctl start glusterd
sleep 5
echo "=== Test port 24007 to s1-paris ==="
timeout 3 bash -c "echo > /dev/tcp/100.122.223.27/24007" && echo GD_OK || echo GD_FAIL
echo "=== Peer status ==="
sudo gluster peer status 2>&1 | head -25
echo "=== Brick process ==="
ps aux | grep glusterfsd | grep -v grep | head -3
