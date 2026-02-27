#!/bin/bash
set -euo pipefail

ORG="${ORG}"
SSM_PARAM_NAME="${SSM_PARAM_NAME}"
RUNNER_LABELS="${RUNNER_LABELS}"
RUNNER_USER="runner"
RUNNER_DIR="/opt/actions-runner"

log() { echo "[runner-bootstrap] $*"; }

# --- IMDSv2 token ---
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

# --- Packages ---
apt-get update -y
apt-get install -y \
  ca-certificates curl jq tar gzip git \
  awscli software-properties-common \
  python3-pip python3-boto3 python3-botocore

# --- Default AWS region (make awscli work without --region) ---
log "Setting default AWS region to $${AWS_REGION} (root/ubuntu/runner + system env)"

# system-wide env (for non-interactive)
cat >/etc/profile.d/aws-region.sh <<EOF
export AWS_REGION="$${AWS_REGION}"
export AWS_DEFAULT_REGION="$${AWS_REGION}"
EOF
chmod 644 /etc/profile.d/aws-region.sh

# also for systemd/services (runner service 포함)
if ! grep -q '^AWS_REGION=' /etc/environment 2>/dev/null; then
  echo "AWS_REGION=$${AWS_REGION}" >> /etc/environment
fi
if ! grep -q '^AWS_DEFAULT_REGION=' /etc/environment 2>/dev/null; then
  echo "AWS_DEFAULT_REGION=$${AWS_REGION}" >> /etc/environment
fi

write_aws_config () {
  local home_dir="$1"
  local owner="$2"
  mkdir -p "$${home_dir}/.aws"
  cat >"$${home_dir}/.aws/config" <<EOF
[default]
region = $${AWS_REGION}
output = json
EOF
  chown -R "$${owner}:$${owner}" "$${home_dir}/.aws" || true
  chmod 700 "$${home_dir}/.aws" || true
  chmod 600 "$${home_dir}/.aws/config" || true
}

write_aws_config "/root" "root"

# ubuntu user home exists on Ubuntu AMI
if id -u ubuntu >/dev/null 2>&1; then
  write_aws_config "/home/ubuntu" "ubuntu"
fi

# --- Ansible (for CD automation) ---
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible
ansible --version || true

# --- Runner user ---
if ! id -u "$${RUNNER_USER}" >/dev/null 2>&1; then
  useradd -m -r -s /bin/bash "$${RUNNER_USER}"
fi

# runner에도 aws 기본 region 적용
write_aws_config "/home/$${RUNNER_USER}" "$${RUNNER_USER}"

mkdir -p "$${RUNNER_DIR}"
chown -R "$${RUNNER_USER}:$${RUNNER_USER}" "$${RUNNER_DIR}"
chmod 755 "$${RUNNER_DIR}"

# --- Fetch PAT from SSM ---
log "Fetching GH_PAT from SSM: ${SSM_PARAM_NAME}"
GH_PAT="$(aws --region "$${AWS_REGION}" ssm get-parameter \
  --name "${SSM_PARAM_NAME}" --with-decryption \
  --query 'Parameter.Value' --output text)"

if [ -z "$${GH_PAT}" ] || [ "$${GH_PAT}" = "None" ]; then
  log "ERROR: GH_PAT is empty (check SSM parameter & IAM permission)"
  exit 1
fi

GH_API="https://api.github.com"
AUTH_HEADER="Authorization: token $${GH_PAT}"
ACCEPT_HEADER="Accept: application/vnd.github+json"

cd "$${RUNNER_DIR}"

# --- Remove existing local runner config if exists ---
if [ -f "$${RUNNER_DIR}/config.sh" ] && [ -f "$${RUNNER_DIR}/.runner" ]; then
  log "Existing local runner config found. Removing..."
  ./svc.sh stop || true
  ./svc.sh uninstall || true

  REMOVE_TOKEN="$(curl -fsS -X POST -H "$${AUTH_HEADER}" -H "$${ACCEPT_HEADER}" \
    "$${GH_API}/orgs/${ORG}/actions/runners/remove-token" | jq -r '.token' || true)"

  if [ -n "$${REMOVE_TOKEN}" ] && [ "$${REMOVE_TOKEN}" != "null" ]; then
    su -s /bin/bash -c "cd $${RUNNER_DIR} && ./config.sh remove --token $${REMOVE_TOKEN}" "$${RUNNER_USER}" || true
  else
    log "WARN: failed to get remove-token, continue anyway"
  fi
fi

log "Fetching latest actions/runner release..."
LATEST_TAG="$(curl -fsS "$${GH_API}/repos/actions/runner/releases/latest" | jq -r '.tag_name')"
RUNNER_VERSION="$${LATEST_TAG#v}"
log "Runner version: $${RUNNER_VERSION}"

if [ ! -f "$${RUNNER_DIR}/config.sh" ]; then
  log "Downloading actions runner..."
  su -s /bin/bash -c "cd $${RUNNER_DIR} && curl -fsSL -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz" "$${RUNNER_USER}"
  su -s /bin/bash -c "cd $${RUNNER_DIR} && tar xzf actions-runner.tar.gz" "$${RUNNER_USER}"
  su -s /bin/bash -c "cd $${RUNNER_DIR} && ./bin/installdependencies.sh" "$${RUNNER_USER}" || true
fi

log "Cleaning up existing org runner with same name (if any)..."
EXISTING_ID="$(curl -fsS -H "$${AUTH_HEADER}" -H "$${ACCEPT_HEADER}" \
  "$${GH_API}/orgs/${ORG}/actions/runners?per_page=100" \
  | jq -r --arg NAME "$${RUNNER_NAME}" '.runners[] | select(.name==$NAME) | .id' | head -n 1 || true)"

if [ -n "$${EXISTING_ID}" ] && [ "$${EXISTING_ID}" != "null" ]; then
  log "Deleting existing runner id=$${EXISTING_ID}"
  curl -fsS -X DELETE -H "$${AUTH_HEADER}" -H "$${ACCEPT_HEADER}" \
    "$${GH_API}/orgs/${ORG}/actions/runners/$${EXISTING_ID}" >/dev/null || true
fi

log "Requesting org registration token..."
REG_TOKEN="$(curl -fsS -X POST -H "$${AUTH_HEADER}" -H "$${ACCEPT_HEADER}" \
  "$${GH_API}/orgs/${ORG}/actions/runners/registration-token" | jq -r '.token')"

if [ -z "$${REG_TOKEN}" ] || [ "$${REG_TOKEN}" = "null" ]; then
  log "ERROR: failed to get registration token (check PAT scopes/org settings)"
  exit 1
fi

log "Configuring runner..."
su -s /bin/bash -c "cd $${RUNNER_DIR} && ./config.sh --unattended --url https://github.com/${ORG} --token $${REG_TOKEN} --name $${RUNNER_NAME} --labels ${RUNNER_LABELS} --work _work --replace" "$${RUNNER_USER}"

log "Installing and starting service..."
cd "$${RUNNER_DIR}"
./svc.sh install "$${RUNNER_USER}"
./svc.sh start

log "Done. Check status with: systemctl status actions.runner.${ORG}.$${RUNNER_NAME}.service"

# ==============================
# Monitoring Stack (Prometheus + Grafana)
# ==============================

REPO_URL="https://github.com/ktcloudmini/monitoring.git"
DIR="/home/ubuntu/monitoring"
BRANCH="main"
PROFILE="monitoring"

echo "[monitoring] Installing Docker"

apt-get update -y
apt-get install -y ca-certificates curl git

if ! command -v docker >/dev/null 2>&1; then

  install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

  chmod a+r /etc/apt/keyrings/docker.asc

  . /etc/os-release

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
> /etc/apt/sources.list.d/docker.list

  apt-get update -y

  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

fi

systemctl enable --now docker
usermod -aG docker ubuntu || true

echo "[monitoring] Clone monitoring repo"

if [ ! -d "$DIR/.git" ]; then
  sudo -u ubuntu git clone -b "$BRANCH" "$REPO_URL" "$DIR"
else
  cd "$DIR"
  sudo -u ubuntu git fetch origin
  sudo -u ubuntu git checkout "$BRANCH"
  sudo -u ubuntu git pull --rebase
fi

echo "[monitoring] Starting docker compose"

cd "$DIR"

sudo -u ubuntu sudo docker compose --profile "$PROFILE" up -d

sudo -u ubuntu sudo docker compose ps

echo "[monitoring] Prometheus/Grafana started"
