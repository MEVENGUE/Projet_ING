#!/bin/bash
curl -s http://100.126.8.98:9090/api/v1/targets | python3 -c "
import sys, json
d = json.load(sys.stdin)
for t in d['data']['activeTargets']:
    print(t['labels']['job'], t['labels'].get('instance',''), t['health'])
"

echo "=== Sample metrics available ==="
curl -s 'http://100.126.8.98:9090/api/v1/label/__name__/values' | python3 -c "
import sys, json
d = json.load(sys.stdin)
metrics = d['data']
# Show relevant ones
keywords = ['node_', 'haproxy_', 'mysql_', 'process_', 'up']
for m in sorted(metrics):
    for k in keywords:
        if m.startswith(k):
            print(m)
            break
" | head -80
