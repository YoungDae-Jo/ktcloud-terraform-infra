#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# --- node_exporter (for Prometheus) ---
apt-get update -y
apt-get install -y prometheus-node-exporter

systemctl enable --now prometheus-node-exporter
systemctl is-enabled prometheus-node-exporter || true
systemctl is-active  prometheus-node-exporter || true

ss -tulnp | grep 9100 || true
curl -sS localhost:9100/metrics | head -n 5 || true

echo "[DONE] node_exporter installed and started"
