#!/bin/bash
# Get Tailscale SSH auth URL from toronto trying to reach NY storage
# Run from lb-paris
sshpass -p 'root' ssh -o StrictHostKeyChecking=no nadia@100.126.8.98 \
  "echo root | su -c 'ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@100.93.154.48 echo ok 2>&1'" 2>&1
