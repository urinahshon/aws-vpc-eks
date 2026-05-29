#!/bin/bash
# Terraform templatefile — ${github_repo}, ${github_pat}, ${aws_region}
# are replaced at plan time.  All other shell variables use $VAR (no braces).
set -euxo pipefail

REPO="${github_repo}"
PAT="${github_pat}"
REGION="${aws_region}"
RUNNER_DIR="/home/runner/actions-runner"

# ── System dependencies ───────────────────────────────────────────────────────
dnf install -y jq git libicu tar

# kubectl (used by the k8s-deploy-backend workflow)
KUBE_VER=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -sLo /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/$KUBE_VER/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

# ── Runner user ───────────────────────────────────────────────────────────────
useradd -m -s /bin/bash runner 2>/dev/null || true

# ── Resolve latest GitHub Actions runner version + SHA256 ─────────────────────
RELEASE_JSON=$(curl -sf \
  -H "Authorization: Bearer $PAT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/actions/runner/releases/latest")

RUNNER_VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name' | sed 's/^v//')
RUNNER_HASH=$(echo "$RELEASE_JSON" | jq -r '.body' \
  | grep "linux-x64-$RUNNER_VERSION" | grep -oE '[0-9a-f]{64}' | head -1)

# ── Download, validate, and extract runner ────────────────────────────────────
TARBALL="/tmp/runner.tar.gz"
curl -sLo "$TARBALL" \
  "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"

echo "$RUNNER_HASH  $TARBALL" | sha256sum -c

mkdir -p $RUNNER_DIR
tar xzf "$TARBALL" -C $RUNNER_DIR
chown -R runner:runner $RUNNER_DIR

# ── Exchange PAT for a short-lived runner registration token ─────────────────
REG_TOKEN=$(curl -sf \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PAT" \
  "https://api.github.com/repos/$REPO/actions/runners/registration-token" \
  | jq -r '.token')

# ── Register runner (must run as non-root) ────────────────────────────────────
sudo -u runner $RUNNER_DIR/config.sh \
  --url "https://github.com/$REPO" \
  --token "$REG_TOKEN" \
  --name "backend-vpc-runner" \
  --labels "self-hosted,backend-vpc" \
  --unattended \
  --replace

# ── Install systemd service and start ─────────────────────────────────────────
cd $RUNNER_DIR
./svc.sh install runner
./svc.sh start