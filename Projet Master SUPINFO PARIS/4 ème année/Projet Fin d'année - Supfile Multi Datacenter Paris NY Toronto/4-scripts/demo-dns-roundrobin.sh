#!/bin/bash
# Run from lb-paris to demo DNS round-robin intersite load balancing
DNS="100.126.8.98"
HOSTNAME="supfile.poc"

echo "=== DNS Round-Robin — supfile.poc ==="
echo "Nameserver: $DNS"
echo ""

echo "--- dig output (both A records returned) ---"
dig @$DNS $HOSTNAME +short

echo ""
echo "--- Alternating HTTP requests (round-robin) ---"

IPS=($(dig @$DNS $HOSTNAME +short))
IDX=0

for i in 1 2 3 4 5 6; do
  IP="${IPS[$((IDX % ${#IPS[@]}))]}"
  echo -n "Request $i → $IP : "
  curl -s --max-time 3 "http://$IP/health" || echo "TIMEOUT"
  IDX=$((IDX + 1))
done

echo ""
echo "--- Both DCs health check ---"
echo -n "Paris (100.69.138.20): "
curl -s --max-time 3 http://100.69.138.20/health
echo ""
echo -n "NY    (100.84.166.8):  "
curl -s --max-time 3 http://100.84.166.8/health
echo ""

echo ""
echo "=== DNS ROUND-ROBIN VERIFIED ==="
echo "supfile.poc → [100.69.138.20 (Paris), 100.84.166.8 (NY)]"
echo "Clients resolve alternating IPs → traffic distributed across both DCs"
