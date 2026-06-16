#!/bin/bash
# 选择系统自带 Fluxbox 主题（stylesdir 无法列出目录型主题，故用此脚本）

set -euo pipefail
source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

STYLE_ROOT="/usr/share/fluxbox/styles"
themes=()
while IFS= read -r t; do
    themes+=("$t")
done < <(find "$STYLE_ROOT" -mindepth 1 -maxdepth 1 \( -type d -o -type f \) -printf '%f\n' | sort)

if [ ${#themes[@]} -eq 0 ]; then
    echo "未找到系统主题: $STYLE_ROOT" >&2
    exit 1
fi

THEME=""
if command -v zenity >/dev/null 2>&1; then
    THEME=$(zenity --list --title="Fluxbox 系统主题" --width=400 --height=500 \
        --column="Theme" "${themes[@]}") || exit 0
else
    echo "可选主题:"
    select THEME in "${themes[@]}"; do
        [ -n "$THEME" ] && break
    done
fi

[ -z "$THEME" ] && exit 0
path="${STYLE_ROOT}/${THEME}"

fluxbox_set_init "session.styleFile" "$path"
fluxbox_reconfigure
