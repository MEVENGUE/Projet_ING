#!/bin/bash
# Build comprehensive SUPFile Grafana dashboard
GRAFANA="http://100.126.8.98:3000"
AUTH="admin:admin"

# Delete existing SUPFile dashboard if present
EXISTING=$(curl -s -u $AUTH "$GRAFANA/api/search?query=SUPFile" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['uid'] if d else '')" 2>/dev/null)
if [ -n "$EXISTING" ]; then
  curl -s -u $AUTH -X DELETE "$GRAFANA/api/dashboards/uid/$EXISTING" > /dev/null
  echo "Deleted old dashboard"
fi

DASHBOARD='{
  "dashboard": {
    "id": null,
    "uid": "supfile-infra-v2",
    "title": "SUPFile Infrastructure Overview",
    "tags": ["supfile","infrastructure"],
    "timezone": "browser",
    "refresh": "30s",
    "time": { "from": "now-1h", "to": "now" },
    "panels": [

      {
        "id": 1,
        "title": "Nodes Online (Paris + NY + Toronto)",
        "type": "stat",
        "gridPos": { "x": 0, "y": 0, "w": 4, "h": 4 },
        "options": {
          "reduceOptions": { "calcs": ["lastNotNull"] },
          "colorMode": "background",
          "graphMode": "none",
          "textMode": "auto",
          "thresholds": { "steps": [
            { "color": "red", "value": null },
            { "color": "orange", "value": 15 },
            { "color": "green", "value": 18 }
          ]}
        },
        "targets": [{
          "expr": "count(up == 1)",
          "legendFormat": "Up"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 2,
        "title": "HAProxy Active Servers — Paris",
        "type": "stat",
        "gridPos": { "x": 4, "y": 0, "w": 4, "h": 4 },
        "options": {
          "reduceOptions": { "calcs": ["lastNotNull"] },
          "colorMode": "background",
          "graphMode": "none",
          "thresholds": { "steps": [
            { "color": "red", "value": null },
            { "color": "orange", "value": 1 },
            { "color": "green", "value": 2 }
          ]}
        },
        "targets": [{
          "expr": "sum(haproxy_backend_active_servers{instance=\"100.69.138.20:8404\"})",
          "legendFormat": "Active"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 3,
        "title": "HAProxy Active Servers — NY",
        "type": "stat",
        "gridPos": { "x": 8, "y": 0, "w": 4, "h": 4 },
        "options": {
          "reduceOptions": { "calcs": ["lastNotNull"] },
          "colorMode": "background",
          "graphMode": "none",
          "thresholds": { "steps": [
            { "color": "red", "value": null },
            { "color": "orange", "value": 1 },
            { "color": "green", "value": 2 }
          ]}
        },
        "targets": [{
          "expr": "sum(haproxy_backend_active_servers{instance=\"100.84.166.8:8404\"})",
          "legendFormat": "Active"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 4,
        "title": "HAProxy Backend Status (1=UP)",
        "type": "stat",
        "gridPos": { "x": 12, "y": 0, "w": 4, "h": 4 },
        "options": {
          "reduceOptions": { "calcs": ["lastNotNull"] },
          "colorMode": "background",
          "graphMode": "none",
          "thresholds": { "steps": [
            { "color": "red", "value": null },
            { "color": "green", "value": 1 }
          ]}
        },
        "targets": [{
          "expr": "min(haproxy_backend_status)",
          "legendFormat": "Min status"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 5,
        "title": "Down Targets",
        "type": "stat",
        "gridPos": { "x": 16, "y": 0, "w": 4, "h": 4 },
        "options": {
          "reduceOptions": { "calcs": ["lastNotNull"] },
          "colorMode": "background",
          "graphMode": "none",
          "thresholds": { "steps": [
            { "color": "green", "value": null },
            { "color": "orange", "value": 1 },
            { "color": "red", "value": 3 }
          ]}
        },
        "targets": [{
          "expr": "count(up == 0) or vector(0)",
          "legendFormat": "Down"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 6,
        "title": "CPU Usage % — All Nodes",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 4, "w": 12, "h": 8 },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0, "max": 100,
            "thresholds": { "steps": [
              { "color": "green", "value": null },
              { "color": "orange", "value": 70 },
              { "color": "red", "value": 90 }
            ]}
          }
        },
        "options": { "tooltip": { "mode": "multi" } },
        "targets": [
          {
            "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[2m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ],
        "datasource": "Prometheus"
      },

      {
        "id": 7,
        "title": "Memory Usage % — All Nodes",
        "type": "timeseries",
        "gridPos": { "x": 12, "y": 4, "w": 12, "h": 8 },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0, "max": 100,
            "thresholds": { "steps": [
              { "color": "green", "value": null },
              { "color": "orange", "value": 75 },
              { "color": "red", "value": 90 }
            ]}
          }
        },
        "targets": [{
          "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
          "legendFormat": "{{instance}}"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 8,
        "title": "HAProxy HTTP Requests/sec — Paris",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 12, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "reqps" } },
        "targets": [{
          "expr": "rate(haproxy_frontend_http_requests_total{instance=\"100.69.138.20:8404\"}[2m])",
          "legendFormat": "Paris — {{proxy}}"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 9,
        "title": "HAProxy HTTP Requests/sec — NY",
        "type": "timeseries",
        "gridPos": { "x": 12, "y": 12, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "reqps" } },
        "targets": [{
          "expr": "rate(haproxy_frontend_http_requests_total{instance=\"100.84.166.8:8404\"}[2m])",
          "legendFormat": "NY — {{proxy}}"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 10,
        "title": "HAProxy Active Sessions — Both DCs",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 19, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "short" } },
        "targets": [
          {
            "expr": "haproxy_frontend_current_sessions{instance=\"100.69.138.20:8404\"}",
            "legendFormat": "Paris — {{proxy}}"
          },
          {
            "expr": "haproxy_frontend_current_sessions{instance=\"100.84.166.8:8404\"}",
            "legendFormat": "NY — {{proxy}}"
          }
        ],
        "datasource": "Prometheus"
      },

      {
        "id": 11,
        "title": "HAProxy Backend Response Time (avg) — Both DCs",
        "type": "timeseries",
        "gridPos": { "x": 12, "y": 19, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "s" } },
        "targets": [
          {
            "expr": "haproxy_backend_response_time_average_seconds{instance=\"100.69.138.20:8404\"}",
            "legendFormat": "Paris — {{proxy}}"
          },
          {
            "expr": "haproxy_backend_response_time_average_seconds{instance=\"100.84.166.8:8404\"}",
            "legendFormat": "NY — {{proxy}}"
          }
        ],
        "datasource": "Prometheus"
      },

      {
        "id": 12,
        "title": "Network In (bytes/sec) — All Nodes",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 26, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "Bps" } },
        "targets": [{
          "expr": "rate(node_network_receive_bytes_total{device!~\"lo|veth.*|docker.*\"}[2m])",
          "legendFormat": "{{instance}} {{device}}"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 13,
        "title": "Network Out (bytes/sec) — All Nodes",
        "type": "timeseries",
        "gridPos": { "x": 12, "y": 26, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "Bps" } },
        "targets": [{
          "expr": "rate(node_network_transmit_bytes_total{device!~\"lo|veth.*|docker.*\"}[2m])",
          "legendFormat": "{{instance}} {{device}}"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 14,
        "title": "Disk I/O Read (bytes/sec) — All Nodes",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 33, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "Bps" } },
        "targets": [{
          "expr": "rate(node_disk_read_bytes_total[2m])",
          "legendFormat": "{{instance}} {{device}}"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 15,
        "title": "Disk I/O Write (bytes/sec) — All Nodes",
        "type": "timeseries",
        "gridPos": { "x": 12, "y": 33, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "Bps" } },
        "targets": [{
          "expr": "rate(node_disk_written_bytes_total[2m])",
          "legendFormat": "{{instance}} {{device}}"
        }],
        "datasource": "Prometheus"
      },

      {
        "id": 16,
        "title": "HAProxy Bytes In/Out — Paris (total traffic)",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 40, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "Bps" } },
        "targets": [
          {
            "expr": "rate(haproxy_frontend_bytes_in_total{instance=\"100.69.138.20:8404\"}[2m])",
            "legendFormat": "IN — {{proxy}}"
          },
          {
            "expr": "rate(haproxy_frontend_bytes_out_total{instance=\"100.69.138.20:8404\"}[2m])",
            "legendFormat": "OUT — {{proxy}}"
          }
        ],
        "datasource": "Prometheus"
      },

      {
        "id": 17,
        "title": "HAProxy Bytes In/Out — NY (total traffic)",
        "type": "timeseries",
        "gridPos": { "x": 12, "y": 40, "w": 12, "h": 7 },
        "fieldConfig": { "defaults": { "unit": "Bps" } },
        "targets": [
          {
            "expr": "rate(haproxy_frontend_bytes_in_total{instance=\"100.84.166.8:8404\"}[2m])",
            "legendFormat": "IN — {{proxy}}"
          },
          {
            "expr": "rate(haproxy_frontend_bytes_out_total{instance=\"100.84.166.8:8404\"}[2m])",
            "legendFormat": "OUT — {{proxy}}"
          }
        ],
        "datasource": "Prometheus"
      },

      {
        "id": 18,
        "title": "HAProxy Connection Errors — Both DCs",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 47, "w": 12, "h": 6 },
        "fieldConfig": { "defaults": { "unit": "short" } },
        "targets": [
          {
            "expr": "rate(haproxy_backend_connection_errors_total{instance=\"100.69.138.20:8404\"}[2m])",
            "legendFormat": "Paris conn-err {{proxy}}"
          },
          {
            "expr": "rate(haproxy_backend_connection_errors_total{instance=\"100.84.166.8:8404\"}[2m])",
            "legendFormat": "NY conn-err {{proxy}}"
          }
        ],
        "datasource": "Prometheus"
      },

      {
        "id": 19,
        "title": "System Load (1m) — All Nodes",
        "type": "timeseries",
        "gridPos": { "x": 12, "y": 47, "w": 12, "h": 6 },
        "fieldConfig": { "defaults": { "unit": "short" } },
        "targets": [{
          "expr": "node_load1",
          "legendFormat": "{{instance}}"
        }],
        "datasource": "Prometheus"
      }

    ],
    "schemaVersion": 30,
    "version": 1
  },
  "overwrite": true,
  "folderId": 0
}'

echo "=== Pushing dashboard to Grafana ==="
curl -s -u $AUTH \
  -H "Content-Type: application/json" \
  -X POST "$GRAFANA/api/dashboards/db" \
  -d "$DASHBOARD" | python3 -c "import sys,json; d=json.load(sys.stdin); print('URL:', d.get('url','ERROR'), '| Status:', d.get('status','?'))"

echo ""
echo "=== Grafana health ==="
curl -s -u $AUTH "$GRAFANA/api/health" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d)"
