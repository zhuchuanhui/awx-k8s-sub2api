#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

PACKAGE_NAME="awx-k8s-sub2api-distribution-$(date +%Y%m%d-%H%M%S).tar.gz"

tar --exclude-vcs --exclude='.DS_Store' --exclude='*.swp' --exclude='*.pyc' --transform 's|^|awx-k8s-sub2api/|' -czf "$PACKAGE_NAME" \
  AGENTS.md ansible.cfg deploy-awx.yml deploy-sub2api.yml README.md docs inventory k8s roles

echo "Created distribution archive: $PACKAGE_NAME"
