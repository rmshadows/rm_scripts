#!/bin/bash
# 将当前 session.styleFile 保存为默认主题（更新 default.theme 符号链接）

set -euo pipefail

FLUX="${HOME}/.fluxbox"
INIT="${FLUX}/init"
DEFAULT="${FLUX}/default.theme"
PATH_FILE="${FLUX}/default.style.path"

if [ ! -f "$INIT" ]; then
    echo "找不到 init: $INIT" >&2
    exit 1
fi

current=$(grep -E '^session\.styleFile:' "$INIT" | sed -E 's/^session\.styleFile:[[:space:]]*//')
if [ -z "$current" ]; then
    echo "init 中未找到 session.styleFile" >&2
    exit 1
fi

target=$(eval echo "$current")
if [ ! -e "$target" ]; then
    echo "当前主题不存在: $target" >&2
    exit 1
fi

rm -f "$DEFAULT"
ln -sf "$target" "$DEFAULT"
echo "$current" > "$PATH_FILE"
