#!/bin/bash
# 将当前主题保存为 ryan 默认主题（~/.fluxbox/styles/Ryan）
# 不会把 Font-* 字号样式包存为 ryan

set -euo pipefail

FLUX="${HOME}/.fluxbox"
INIT="${FLUX}/init"
RYAN="${FLUX}/styles/Ryan"
DEFAULT="${FLUX}/default.theme"
PATH_FILE="${FLUX}/default.style.path"
RYAN_PATH='~/.fluxbox/styles/Ryan'

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

# 若当前误选为 Font-* 字号包，用已有 ryan 指向的真实主题
if [[ "$target" =~ /Font-[0-9]+$ ]] || [[ "$current" =~ Font-[0-9]+ ]]; then
    if [ -L "$RYAN" ] && [ -e "$RYAN" ]; then
        target=$(readlink -f "$RYAN")
    else
        echo "当前是字号样式包，请先选择系统主题或 ryan 主题，再设为 ryan 默认" >&2
        exit 1
    fi
fi

# 若当前就是 Ryan 入口，解析到真实主题
if [ "$(basename "$target")" = "Ryan" ] && [ -L "$target" ]; then
    target=$(readlink -f "$target")
fi

if [ ! -e "$target" ]; then
    echo "主题不存在: $target" >&2
    exit 1
fi

mkdir -p "${FLUX}/styles"
rm -f "$RYAN"
ln -sf "$target" "$RYAN"

rm -f "$DEFAULT"
ln -sf "$RYAN" "$DEFAULT"

echo "$RYAN_PATH" > "$PATH_FILE"

if grep -qE '^session\.styleFile:' "$INIT"; then
    sed -i "s|^session\.styleFile:.*|session.styleFile:\t${RYAN_PATH}|" "$INIT"
fi

fluxbox-remote reconfigure 2>/dev/null || true
fluxbox-remote reloadstyle 2>/dev/null || true

msg="已设为 ryan 默认主题 → ${target}"
echo -e "$msg"
