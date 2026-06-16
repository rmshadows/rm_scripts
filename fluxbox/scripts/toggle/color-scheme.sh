#!/bin/bash
# 亮色 / 暗色 / 切换（仅 GTK 应用，不改变 Fluxbox 主题）
# 用法: color-scheme.sh light|dark|toggle|status

set -euo pipefail

MODE="${1:-toggle}"
CONF="${HOME}/.fluxbox/config/color-scheme.conf"
STATE="${HOME}/.fluxbox/config/color-scheme.mode"

# shellcheck source=/dev/null
[ -f "$CONF" ] && source "$CONF"

GTK_COLOR_SCHEME_LIGHT="${GTK_COLOR_SCHEME_LIGHT:-default}"
GTK_COLOR_SCHEME_DARK="${GTK_COLOR_SCHEME_DARK:-prefer-dark}"
GTK_THEME_LIGHT="${GTK_THEME_LIGHT:-Adwaita}"
GTK_THEME_DARK="${GTK_THEME_DARK:-Adwaita-dark}"
GTK_ICON_LIGHT="${GTK_ICON_LIGHT:-Adwaita}"
GTK_ICON_DARK="${GTK_ICON_DARK:-Adwaita}"
GTK2_THEME_LIGHT="${GTK2_THEME_LIGHT:-niroki}"
GTK2_THEME_DARK="${GTK2_THEME_DARK:-Adwaita-dark}"

source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

notify() {
    echo "$1"
}

apply_gtk3() {
    local scheme="$1" theme="$2" icon="$3"
    if ! command -v gsettings >/dev/null 2>&1; then
        return 0
    fi
    gsettings set org.gnome.desktop.interface color-scheme "$scheme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$icon" 2>/dev/null || true

    mkdir -p "${HOME}/.config/gtk-3.0"
    local ini="${HOME}/.config/gtk-3.0/settings.ini"
    if [ ! -f "$ini" ]; then
        cat > "$ini" <<'EOF'
[Settings]
EOF
    fi
    if grep -q '^gtk-application-prefer-dark-theme=' "$ini"; then
        if [ "$scheme" = "prefer-dark" ]; then
            sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$ini"
        else
            sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=0/' "$ini"
        fi
    else
        if [ "$scheme" = "prefer-dark" ]; then
            echo 'gtk-application-prefer-dark-theme=1' >> "$ini"
        else
            echo 'gtk-application-prefer-dark-theme=0' >> "$ini"
        fi
    fi
}

apply_gtk2() {
    local theme="$1"
    local rc="${HOME}/.gtkrc-2.0"
    [ -f "$rc" ] || return 0
    if grep -q '^ gtk-theme-name' "$rc"; then
        sed -i "s|^ gtk-theme-name = .*| gtk-theme-name = \"${theme}\"|" "$rc"
    else
        echo " gtk-theme-name = \"${theme}\"" >> "$rc"
    fi
}

apply_mode() {
    local mode="$1"
    local fb_style
    fb_style="$(fluxbox_get_init session.styleFile 2>/dev/null || echo n/a)"
    case "$mode" in
        light)
            apply_gtk3 "$GTK_COLOR_SCHEME_LIGHT" "$GTK_THEME_LIGHT" "$GTK_ICON_LIGHT"
            apply_gtk2 "$GTK2_THEME_LIGHT"
            echo light > "$STATE"
            notify "GTK 亮色\n主题: ${GTK_THEME_LIGHT}\nFluxbox 未改变: ${fb_style}"
            ;;
        dark)
            apply_gtk3 "$GTK_COLOR_SCHEME_DARK" "$GTK_THEME_DARK" "$GTK_ICON_DARK"
            apply_gtk2 "$GTK2_THEME_DARK"
            echo dark > "$STATE"
            notify "GTK 暗色\n主题: ${GTK_THEME_DARK}\nFluxbox 未改变: ${fb_style}"
            ;;
        *)
            echo "未知模式: $mode" >&2
            exit 1
            ;;
    esac
}

case "$MODE" in
    light|dark)
        apply_mode "$MODE"
        ;;
    toggle)
        cur="light"
        [ -f "$STATE" ] && cur="$(tr -d '[:space:]' < "$STATE")"
        if [ "$cur" = "dark" ]; then
            apply_mode light
        else
            apply_mode dark
        fi
        ;;
    status)
        cur="unknown"
        [ -f "$STATE" ] && cur="$(tr -d '[:space:]' < "$STATE")"
        gtk_scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo n/a)"
        gtk_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo n/a)"
        fb_style="$(fluxbox_get_init session.styleFile 2>/dev/null || echo n/a)"
        font_size="n/a"
        [ -f "${HOME}/.fluxbox/config/menu.font.size" ] && font_size="$(cat "${HOME}/.fluxbox/config/menu.font.size")"
        notify "GTK: ${cur}\nFluxbox: ${fb_style}\n字号: ${font_size}\nGTK theme: ${gtk_theme}\nscheme: ${gtk_scheme}"
        ;;
    *)
        echo "用法: $0 light|dark|toggle|status" >&2
        exit 1
        ;;
esac
