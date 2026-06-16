#!/bin/bash
# 从仓库运行 setup/deploy.sh（setup/ 不会部署到 ~/.fluxbox）

set -euo pipefail

PATH_FILE="${HOME}/.fluxbox/config/sync.repo.path"
if [ ! -f "$PATH_FILE" ]; then
    echo "请先配置: $PATH_FILE" >&2
    echo "或直接在仓库目录运行: ./setup/deploy.sh" >&2
    exit 1
fi

REPO="$(tr -d '[:space:]' < "$PATH_FILE")"
DEPLOY="${REPO}/setup/deploy.sh"

if [ ! -x "$DEPLOY" ]; then
  if [ -f "$DEPLOY" ]; then
    bash "$DEPLOY" "$@"
  else
    echo "找不到: $DEPLOY" >&2
    exit 1
  fi
else
  exec bash "$DEPLOY" "$@"
fi
