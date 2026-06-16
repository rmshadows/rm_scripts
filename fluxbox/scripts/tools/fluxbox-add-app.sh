#!/bin/bash
# 点击窗口生成 apps 规则片段（追加到 ~/.fluxbox/apps）

set -euo pipefail

APPS="${HOME}/.fluxbox/apps"
TMP="${TMPDIR:-/tmp}/fluxbox-xprop.$$"

if ! command -v xprop >/dev/null 2>&1; then
    echo "需要 xprop" >&2
    exit 1
fi

echo "请点击目标窗口…" >&2

xprop | tee "$TMP" >/dev/null

class_line=$(grep 'WM_CLASS' "$TMP" | head -1)
name_line=$(grep 'WM_NAME' "$TMP" | head -1)
rm -f "$TMP"

if [ -z "$class_line" ]; then
    echo "未获取到 WM_CLASS" >&2
    exit 1
fi

class=$(echo "$class_line" | sed -n 's/.*"\([^"]*\)".*/\1/p' | tail -1)
[ -z "$class" ] && class=$(echo "$class_line" | awk -F'"' '{print $4}')

match_by="class"
if command -v zenity >/dev/null 2>&1; then
    choice=$(zenity --list --title="匹配方式" --column="Type" class name --height=150 2>/dev/null) || choice="class"
    [ "$choice" = "name" ] && match_by="name"
fi

if [ "$match_by" = "name" ]; then
    name=$(echo "$name_line" | sed -n 's/.*"\([^"]*\)".*/\1/p' | head -1)
    [ -z "$name" ] && name="$class"
    app_line="[app] (name=${name})"
else
    app_line="[app] (class=${class})"
fi

snippet=$(cat <<EOF

# 由 fluxbox-add-app.sh 于 $(date '+%Y-%m-%d %H:%M') 添加
${app_line}
  [Deco] {NORMAL}
  [Layer] {NORMAL}
  [Focus] {YES}
[end]
EOF
)

if command -v zenity >/dev/null 2>&1; then
    zenity --text-info --title="将追加到 apps" --editable --width=500 --height=200 <<< "$snippet" > "${TMP}.edit" || exit 0
    snippet=$(cat "${TMP}.edit")
    rm -f "${TMP}.edit"
fi

printf '%s\n' "$snippet" >> "$APPS"
