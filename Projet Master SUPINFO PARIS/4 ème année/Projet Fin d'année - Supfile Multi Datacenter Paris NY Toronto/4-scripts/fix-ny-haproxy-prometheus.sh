#!/bin/bash
ssh -o StrictHostKeyChecking=no root@100.84.166.8 \
  "sed -i '/stats show-node/a\\    http-request use-service prometheus-exporter if { path /metrics }' /etc/haproxy/haproxy.cfg && haproxy -c -f /etc/haproxy/haproxy.cfg 2>&1 | grep -v WARNING && systemctl reload haproxy && echo NY_PROMETHEUS_OK"
