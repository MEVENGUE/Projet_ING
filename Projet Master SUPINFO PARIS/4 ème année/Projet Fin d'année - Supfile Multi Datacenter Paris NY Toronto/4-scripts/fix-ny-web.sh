#!/bin/bash
echo "=== Starting php8.1-fpm on web1-ny ==="
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@100.102.26.5 \
  "systemctl start php8.1-fpm && systemctl enable php8.1-fpm && systemctl is-active php8.1-fpm && curl -s http://localhost/ | head -c 100" 2>&1

echo "=== Testing NY VIP ==="
curl -s -UseBasicParsing http://100.84.166.8/ 2>&1 | Select-String "node|service|html" | head -3
