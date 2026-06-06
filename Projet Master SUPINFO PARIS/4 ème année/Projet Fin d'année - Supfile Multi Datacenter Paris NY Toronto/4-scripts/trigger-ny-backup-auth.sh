#!/bin/bash
# Trigger Tailscale SSH auth from toronto to NY storage nodes
# Run from lb-paris — output will contain the auth URL
echo "=== Triggering Tailscale SSH auth from toronto to NY storage ==="
sshpass -p 'root' ssh -o StrictHostKeyChecking=no nadia@100.126.8.98 \
  "echo root | su -c 'ssh -o StrictHostKeyChecking=no root@100.93.154.48 echo reachable 2>&1 | head -10' 2>&1"
echo ""
echo "=== If URL above — open it in browser to authenticate, then re-run backup ==="
