#!/bin/bash
# Relay: run from lb-paris, pushes dns setup to toronto
sshpass -p 'root' scp -o StrictHostKeyChecking=no /vagrant/scripts/setup-dns-roundrobin.sh nadia@100.126.8.98:/tmp/dns-setup.sh
sshpass -p 'root' ssh -o StrictHostKeyChecking=no nadia@100.126.8.98 "echo root | su -c 'bash /tmp/dns-setup.sh' 2>&1"
