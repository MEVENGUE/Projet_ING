#!/bin/bash
# Relay: push HAProxy setup to toronto from lb-paris
sshpass -p 'root' scp -o StrictHostKeyChecking=no \
  /vagrant/scripts/setup-haproxy-toronto.sh nadia@100.126.8.98:/tmp/setup-haproxy.sh
sshpass -p 'root' ssh -o StrictHostKeyChecking=no nadia@100.126.8.98 \
  "echo root | su -c 'bash /tmp/setup-haproxy.sh' 2>&1"
