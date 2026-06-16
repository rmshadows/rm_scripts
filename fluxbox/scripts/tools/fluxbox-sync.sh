#!/bin/bash
# 部署 / 备份 fluxbox 配置（仓库 <-> ~/.fluxbox）

set -euo pipefail

ACTION="${1:-}"
PATH_FILE="${HOME}/.fluxbox/config/sync.repo.path"
FLUX="${HOME}/.fluxbox"

if [ ! -f "$PATH_FILE" ]; then
    echo "请先配置: $PATH_FILE" >&2
    exit 1
fi

REPO="$(tr -d '[:space:]' < "$PATH_FILE")"
if [ ! -d "$REPO" ]; then
    echo "仓库路径无效: $REPO" >&2
    exit 1
fi

RSYNC_EXCLUDE=(
    --exclude 'log'
    --exclude 'log.old'
    --exclude 'backgrounds/'
    --exclude '.git/'
)

case "$ACTION" in
    deploy)
        rsync -av "${RSYNC_EXCLUDE[@]}" "$REPO/" "$FLUX/"
        msg="已部署: $REPO -> $FLUX"
        ;;
    backup)
        rsync -av "${RSYNC_EXCLUDE[@]}" "$FLUX/" "$REPO/"
        msg="已备份: $FLUX -> $REPO"
        ;;
    *)
        echo "用法: $0 deploy|backup" >&2
        exit 1
        ;;
esac

echo "$msg"
