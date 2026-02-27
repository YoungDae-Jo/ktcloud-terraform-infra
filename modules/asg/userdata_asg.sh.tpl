#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "[START] userdata (node_exporter + ansible-pull)"

# =========================
# 0) variables from templatefile()
# =========================
REPO_URL="${REPO_URL}"
BRANCH="${BRANCH}"
PLAYBOOK="${PLAYBOOK}"

# =========================
# 1) node_exporter
# =========================
apt-get update -y
apt-get install -y prometheus-node-exporter

systemctl enable --now prometheus-node-exporter

ss -tulnp | grep 9100 || true
curl -sS localhost:9100/metrics | head -n 5 || true

echo "[DONE] node_exporter installed"

# =========================
# 2) install ansible
# =========================
echo "[STEP] install ansible"

apt-get install -y python3 python3-pip git

python3 -m pip install --upgrade pip
python3 -m pip install "ansible==9.*"

ansible --version

# =========================
# 3) run ansible-pull
# =========================
echo "[STEP] run ansible-pull"

ansible-pull \
  -U "$REPO_URL" \
  -C "$BRANCH" \
  -i "localhost," \
  -c local \
  "$PLAYBOOK"

echo "[DONE] ansible-pull finished"

echo "[END] userdata finished"
