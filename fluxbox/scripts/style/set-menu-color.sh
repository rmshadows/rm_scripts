#!/bin/bash
# 菜单字色（写入 overlay，不改动 ryan 主题）
# 用法: set-menu-color.sh 预设名|default|ryan|toggle

set -euo pipefail

source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

PRESET="${1:-}"
CONF="${HOME}/.fluxbox/config/menu-colors.conf"
OVERLAY="${HOME}/.fluxbox/overlay"
STATE="${HOME}/.fluxbox/config/menu.color.preset"
RYAN="${HOME}/.fluxbox/styles/Ryan"

MENU_COLOR_KEYS=(
    menu.title.textColor
    menu.frame.textColor
    menu.hilite.textColor
    menu.frame.disableColor
)

ensure_overlay() {
    if [ ! -f "$OVERLAY" ]; then
        cat > "$OVERLAY" <<'EOF'
! overlay
background: unset
EOF
    fi
}

remove_menu_colors() {
    local tmp="${OVERLAY}.tmp.$$"
    grep -vE '^[[:space:]]*menu\.' "$OVERLAY" > "$tmp" 2>/dev/null || cp "$OVERLAY" "$tmp"
    mv "$tmp" "$OVERLAY"
}

set_menu_color() {
    local key="$1" val="$2"
    ensure_overlay
    if grep -qE "^[[:space:]]*${key}:" "$OVERLAY"; then
        sed -i "s|^[[:space:]]*${key}:.*|${key}:\t${val}|" "$OVERLAY"
    else
        printf '%s:\t%s\n' "$key" "$val" >> "$OVERLAY"
    fi
}

resolve_theme_file() {
    local path="$1"
    path=$(eval echo "$path")
    [ -L "$path" ] && path=$(readlink -f "$path")
    if [ -d "$path" ]; then
        [ -f "${path}/theme.cfg" ] && echo "${path}/theme.cfg" && return
    fi
    [ -f "$path" ] && echo "$path"
}

theme_get_color() {
    local file="$1" key="$2"
    grep -E "^[[:space:]]*${key}:" "$file" 2>/dev/null | head -1 \
        | sed -E "s/^[[:space:]]*${key}:[[:space:]]*//"
}

restore_ryan_menu_colors() {
    local theme_file resolved count=0

    remove_menu_colors

    if [ ! -e "$RYAN" ]; then
        echo default > "$STATE"
        fluxbox_reconfigure
        return
    fi

    theme_file=$(resolve_theme_file "$RYAN") || true
    if [ -z "${theme_file:-}" ] || [ ! -f "$theme_file" ]; then
        echo default > "$STATE"
        fluxbox_reconfigure
        return
    fi

    ensure_overlay
    for key in "${MENU_COLOR_KEYS[@]}"; do
        val=$(theme_get_color "$theme_file" "$key")
        if [ -n "$val" ]; then
            set_menu_color "$key" "$val"
            count=$((count + 1))
        fi
    done

    echo ryan > "$STATE"
    fluxbox_reconfigure
}

apply_preset() {
    local name="$1"
    local line title frame hilite disable

    if [ "$name" = "default" ] || [ "$name" = "ryan" ]; then
        restore_ryan_menu_colors
        return
    fi

    line=$(grep -E "^${name}\|" "$CONF" | head -1)
    if [ -z "$line" ]; then
        echo "未知预设: $name（见 config/menu-colors.conf）" >&2
        exit 1
    fi

    IFS='|' read -r _ title frame hilite disable <<< "$line"
    remove_menu_colors
    ensure_overlay
    [ -n "$title" ] && set_menu_color menu.title.textColor "$title"
    [ -n "$frame" ] && set_menu_color menu.frame.textColor "$frame"
    [ -n "$hilite" ] && set_menu_color menu.hilite.textColor "$hilite"
    [ -n "$disable" ] && set_menu_color menu.frame.disableColor "$disable"

    echo "$name" > "$STATE"
    fluxbox_reconfigure
}

if [ -z "$PRESET" ]; then
    echo "用法: $0 default|ryan|blue|white|...|toggle" >&2
    exit 1
fi

if [ "$PRESET" = "toggle" ]; then
    presets=(ryan)
    while IFS='|' read -r n _ _ _ _; do
        [[ "$n" =~ ^[[:space:]]*# ]] && continue
        [[ "$n" == "default" ]] && continue
        [ -n "$n" ] && presets+=("$n")
    done < "$CONF"
    cur="ryan"
    [ -f "$STATE" ] && cur="$(tr -d '[:space:]' < "$STATE")"
    idx=0
    for i in "${!presets[@]}"; do
        [ "${presets[$i]}" = "$cur" ] && idx=$i && break
    done
    next=$(( (idx + 1) % ${#presets[@]} ))
    PRESET="${presets[$next]}"
fi

apply_preset "$PRESET"
