#!/bin/bash
# 仅调整菜单/工具栏字号（写入 overlay，不改动 ryan 主题与 session.styleFile）
# 用法: set-menu-font.sh 12|14|+2|-2

set -euo pipefail

source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

OVERLAY="${HOME}/.fluxbox/overlay"
SIZE_FILE="${HOME}/.fluxbox/config/menu.font.size"
MIN=12
MAX=26
STEP=2
DEFAULT=14

mkdir -p "${HOME}/.fluxbox/config"

current="$DEFAULT"
[ -f "$SIZE_FILE" ] && current="$(tr -d '[:space:]' < "$SIZE_FILE")"

arg="${1:-}"
case "$arg" in
    +2|+) new=$((current + STEP)) ;;
    -2|-) new=$((current - STEP)) ;;
    *)     new="$arg" ;;
esac

if ! [[ "$new" =~ ^[0-9]+$ ]]; then
    echo "用法: $0 12|14|+2|-2" >&2
    exit 1
fi

[ "$new" -lt "$MIN" ] && new=$MIN
[ "$new" -gt "$MAX" ] && new=$MAX

echo "$new" > "$SIZE_FILE"

font_line="*Font:                          DejaVu-${new}:Serif:Condensed"

if [ ! -f "$OVERLAY" ]; then
    cat > "$OVERLAY" <<'EOF'
! overlay - 覆盖当前主题（字号等）
background: unset
EOF
fi

if grep -qE '^\*Font:' "$OVERLAY"; then
    sed -i "s|^\*Font:.*|${font_line}|" "$OVERLAY"
else
    printf '\n%s\n' "$font_line" >> "$OVERLAY"
fi

# 保持 init 指向 ryan，避免误切到 Font-* 样式包
ryan='~/.fluxbox/styles/Ryan'
cur_style="$(fluxbox_get_init session.styleFile)"
if [[ "$cur_style" =~ Font- ]] || [[ "$(eval echo "$cur_style")" =~ /Font-[0-9]+$ ]]; then
    fluxbox_set_init "session.styleFile" "$ryan"
fi

fluxbox_reconfigure
