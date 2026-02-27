#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# -----------------------------
# GitHub Runner (existing)
# -----------------------------
ORG="${ORG}"
SSM_PARAM_NAME="${SSM_PARAM_NAME}"
RUNNER_LABELS="${RUNNER_LABELS}"

RUNNER_USER="runner"
RUNNER_DIR="/opt/actions-runner"

log() { echo "[runner-bootstrap] $*"; }

TOKEN="$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"

imds() {
  local path="$1"
  if [ -n "$${TOKEN}" ]; then
    curl -fsS -H "X-aws-ec2-metadata-token: $${TOKEN}" \
      "http://169.254.169.254/latest/meta-data/$${path}"
  else
    curl -fsS "http://169.254.169.254/latest/meta-data/$${path}"
  fi
}

IID="$(imds instance-id)"
AZ="$(imds placement/availability-zone)"
AWS_REGION="$${AZ%?}"
RUNNER_NAME="Monitoring-Runner-$${IID}"

log "Runner name: $${RUNNER_NAME}"
log "Region: $${AWS_REGION}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  ca-certificates curl jq tar gzip git \
  awscli software-properties-common \
  python3-pip python3-boto3 python3-botocore

log "Setting default AWS region"
cat >/etc/profile.d/aws-region.sh <<EOF
export AWS_REGION="$${AWS_REGION}"
export AWS_DEFAULT_REGION="$${AWS_REGION}"
EOF
chmod 644 /etc/profile.d/aws-region.sh

if ! grep -q '^AWS_REGION=' /etc/environment 2>/dev/null; then
  echo "AWS_REGION=$${AWS_REGION}" >> /etc/environment
fi
if ! grep -q '^AWS_DEFAULT_REGION=' /etc/environment 2>/dev/null; then
  echo "AWS_DEFAULT_REGION=$${AWS_REGION}" >> /etc/environment
fi

add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

if ! id -u "$${RUNNER_USER}" >/dev/null 2>&1; then
  useradd -m -r -s /bin/bash "$${RUNNER_USER}"
fi

mkdir -p "$${RUNNER_DIR}"
chown -R "$${RUNNER_USER}:$${RUNNER_USER}" "$${RUNNER_DIR}"

log "Fetching PAT from SSM"
GH_PAT="$(aws --region "$${AWS_REGION}" ssm get-parameter \
  --name "${SSM_PARAM_NAME}" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)"

GH_API="https://api.github.com"
AUTH_HEADER="Authorization: token $${GH_PAT}"
ACCEPT_HEADER="Accept: application/vnd.github+json"

cd "$${RUNNER_DIR}"
LATEST_TAG="$(curl -fsS "$${GH_API}/repos/actions/runner/releases/latest" | jq -r '.tag_name')"
RUNNER_VERSION="$${LATEST_TAG#v}"

su -s /bin/bash -c "cd $${RUNNER_DIR} && curl -fsSL -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz" "$${RUNNER_USER}"
su -s /bin/bash -c "cd $${RUNNER_DIR} && tar xzf actions-runner.tar.gz" "$${RUNNER_USER}"

cd "$${RUNNER_DIR}"
./bin/installdependencies.sh || true

REG_TOKEN="$(curl -fsS -X POST -H "$${AUTH_HEADER}" -H "$${ACCEPT_HEADER}" \
  "$${GH_API}/orgs/${ORG}/actions/runners/registration-token" \
  | jq -r '.token')"

su -s /bin/bash -c "cd $${RUNNER_DIR} && ./config.sh \
  --unattended \
  --url https://github.com/${ORG} \
  --token $${REG_TOKEN} \
  --name $${RUNNER_NAME} \
  --labels ${RUNNER_LABELS} \
  --work _work \
  --replace" "$${RUNNER_USER}"

cd "$${RUNNER_DIR}"
./svc.sh install "$${RUNNER_USER}"
./svc.sh start

log "Runner setup complete"

# -----------------------------
# Monitoring Stack (Docker + repo + compose)
# -----------------------------
log "Starting Monitoring stack bootstrap"

REPO_URL="https://github.com/ktcloudmini/monitoring.git"
DIR="/home/ubuntu/monitoring"
BRANCH="main"
PROFILE="monitoring"

apt-get update -y
apt-get install -y ca-certificates curl git

install_docker() {
  log "Installing Docker from official repo"

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  . /etc/os-release

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable --now docker
}

if ! command -v docker >/dev/null 2>&1; then
  install_docker
else
  systemctl enable --now docker
fi

usermod -aG docker ubuntu || true

# repo clone/update
if [ ! -d "$${DIR}/.git" ]; then
  log "Cloning monitoring repo"
  sudo -u ubuntu git clone -b "$${BRANCH}" "$${REPO_URL}" "$${DIR}"
else
  log "Updating monitoring repo"
  sudo -u ubuntu bash -lc "cd '$${DIR}' && git fetch origin && git checkout '$${BRANCH}' && git pull --rebase"
fi

# compose up
log "Running docker compose profile=$${PROFILE}"
sudo -u ubuntu bash -lc "cd '$${DIR}' && docker compose --profile '$${PROFILE}' up -d"
sudo -u ubuntu bash -lc "cd '$${DIR}' && docker compose ps"

log "Monitoring stack started"
