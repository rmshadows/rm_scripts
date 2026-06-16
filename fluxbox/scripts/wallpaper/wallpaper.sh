#!/bin/bash
# 壁纸切换：扫描 backgrounds/ 目录，用 fbsetbg 设置桌面背景
# 用法: wallpaper.sh next|prev|random|pick|browse|set <路径>|restore|open|current

set -euo pipefail

ACTION="${1:-}"
ARG="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUXBOX_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CONF="${FLUXBOX_ROOT}/config/wallpaper.conf"
STATE="${FLUXBOX_ROOT}/config/wallpaper.current"
LAST="${FLUXBOX_ROOT}/lastwallpaper"

WALLPAPER_DIR="${FLUXBOX_ROOT}/backgrounds"
WALLPAPER_DEFAULT=""
FBSETBG_OPTS="-a"

# shellcheck source=/dev/null
[ -f "$CONF" ] && source "$CONF"

WALLPAPER_DIR="${WALLPAPER_DIR:-${FLUXBOX_ROOT}/backgrounds}"
WALLPAPER_DIR="$(eval echo "$WALLPAPER_DIR")"

die() {
    echo "$1" >&2
    if command -v zenity >/dev/null 2>&1; then
        zenity --error --text="$1" 2>/dev/null || true
    fi
    exit 1
}

notify() {
    if command -v zenity >/dev/null 2>&1; then
        zenity --info --title="壁纸" --text="$1" --timeout=2 2>/dev/null || true
    else
        echo "$1"
    fi
}

abs_path() {
    local p="$1"
    p="$(eval echo "$p")"
    if command -v realpath >/dev/null 2>&1; then
        realpath "$p" 2>/dev/null && return
    fi
    readlink -f "$p" 2>/dev/null && return
    echo "$p"
}

collect_wallpapers() {
    if [ ! -d "$WALLPAPER_DIR" ]; then
        return 0
    fi
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( \
        -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
        -iname '*.gif' -o -iname '*.webp' -o -iname '*.bmp' \
    \) -printf '%f\t%p\n' 2>/dev/null | sort -f | cut -f2-
}

write_lastwallpaper() {
    local path="$1"
    local disp="${DISPLAY:-:0.0}"
    mkdir -p "$(dirname "$LAST")"
    {
        echo "\$aspect \$full|${path}||${disp}"
        echo "\$aspect \$full|${path}||${disp%.*}"
    } > "$LAST"
}

apply_wallpaper() {
    local path="$1"
    path="$(eval echo "$path")"

    if [ ! -f "$path" ] && [[ "$path" != */* ]]; then
        path="${WALLPAPER_DIR}/${path}"
    fi

    path="$(abs_path "$path")"

    if [ ! -f "$path" ]; then
        die "壁纸不存在: $path"
    fi

    if ! command -v fbsetbg >/dev/null 2>&1; then
        die "未找到 fbsetbg，请安装: sudo apt install feh"
    fi

  # shellcheck disable=SC2086
    fbsetbg $FBSETBG_OPTS "$path"

    mkdir -p "$(dirname "$STATE")"
    echo "$path" > "$STATE"
    write_lastwallpaper "$path"
}

get_current_path() {
    local p

    if [ -f "$STATE" ]; then
        p="$(tr -d '[:space:]' < "$STATE")"
        p="$(eval echo "$p")"
        [ -f "$p" ] && echo "$(abs_path "$p")" && return 0
    fi

    if [ -f "$LAST" ]; then
        p=$(grep -m1 '|' "$LAST" | sed -E 's/.*\|([^|]+)\|.*/\1/')
        p="$(eval echo "$p")"
        [ -f "$p" ] && echo "$(abs_path "$p")" && return 0
    fi

    if [ -n "${WALLPAPER_DEFAULT:-}" ]; then
        p="$(eval echo "$WALLPAPER_DEFAULT")"
        [ -f "$p" ] && echo "$(abs_path "$p")" && return 0
    fi

    return 1
}

load_wallpaper_list() {
    mapfile -t WALLPAPERS < <(collect_wallpapers)
}

find_current_index() {
    local cur="$1" i
    CURRENT_IDX=-1
    for i in "${!WALLPAPERS[@]}"; do
        if [ "$(abs_path "${WALLPAPERS[$i]}")" = "$cur" ]; then
            CURRENT_IDX=$i
            return 0
        fi
    done
    return 1
}

step_wallpaper() {
    local delta="$1"
    local cur idx next

    load_wallpaper_list
    [ ${#WALLPAPERS[@]} -gt 0 ] || die "目录内无壁纸: $WALLPAPER_DIR"

    cur="$(get_current_path 2>/dev/null || true)"
    if [ -n "$cur" ] && find_current_index "$cur"; then
        idx=$CURRENT_IDX
    else
        idx=-1
    fi

    next=$(( (idx + delta + ${#WALLPAPERS[@]}) % ${#WALLPAPERS[@]} ))
    apply_wallpaper "${WALLPAPERS[$next]}"
    notify "已切换\n$(basename "${WALLPAPERS[$next]}")"
}

pick_wallpaper() {
    local names=() paths=() args=() choice i

    load_wallpaper_list
    [ ${#WALLPAPERS[@]} -gt 0 ] || die "目录内无壁纸: $WALLPAPER_DIR"

    for p in "${WALLPAPERS[@]}"; do
        names+=("$(basename "$p")")
        paths+=("$p")
    done

    if command -v zenity >/dev/null 2>&1; then
        for i in "${!names[@]}"; do
            args+=("${names[$i]}" "${paths[$i]}")
        done
        choice=$(zenity --list --title="选择壁纸" --width=520 --height=480 \
            --column="文件名" --column="路径" \
            --hide-column=2 --print-column=2 \
            "${args[@]}") || exit 0
        apply_wallpaper "$choice"
        notify "已设置\n$(basename "$choice")"
        return
    fi

    echo "可选壁纸:"
    select choice in "${names[@]}"; do
        [ -n "$choice" ] || continue
        for i in "${!names[@]}"; do
            [ "${names[$i]}" = "$choice" ] && apply_wallpaper "${paths[$i]}" && return
        done
    done
}

browse_wallpaper() {
    local path filter="图片 | *.jpg *.jpeg *.png *.gif *.webp *.bmp"

    if ! command -v zenity >/dev/null 2>&1; then
        die "browse 需要 zenity"
    fi

    path=$(zenity --file-selection --title="选择壁纸文件" \
        --filename="${WALLPAPER_DIR}/" \
        --file-filter="$filter") || exit 0

    apply_wallpaper "$path"
    notify "已设置\n$(basename "$path")"
}

open_wallpaper_dir() {
  mkdir -p "$WALLPAPER_DIR"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$WALLPAPER_DIR" >/dev/null 2>&1 &
    elif command -v nautilus >/dev/null 2>&1; then
        nautilus "$WALLPAPER_DIR" >/dev/null 2>&1 &
    elif command -v thunar >/dev/null 2>&1; then
        thunar "$WALLPAPER_DIR" >/dev/null 2>&1 &
    else
        die "无法打开目录，请手动访问: $WALLPAPER_DIR"
    fi
}

case "$ACTION" in
    next)
        step_wallpaper 1
        ;;
    prev)
        step_wallpaper -1
        ;;
    random)
        load_wallpaper_list
        [ ${#WALLPAPERS[@]} -gt 0 ] || die "目录内无壁纸: $WALLPAPER_DIR"
        apply_wallpaper "${WALLPAPERS[$(( RANDOM % ${#WALLPAPERS[@]} ))]}"
        ;;
    pick)
        pick_wallpaper
        ;;
    browse)
        browse_wallpaper
        ;;
    set)
        [ -n "$ARG" ] || die "用法: $0 set <图片路径>"
        apply_wallpaper "$ARG"
        ;;
    restore|current)
        if cur="$(get_current_path 2>/dev/null)"; then
            apply_wallpaper "$cur"
        else
            load_wallpaper_list
            [ ${#WALLPAPERS[@]} -gt 0 ] || die "无可用壁纸，请将图片放入: $WALLPAPER_DIR"
            apply_wallpaper "${WALLPAPERS[0]}"
        fi
        ;;
    open)
        open_wallpaper_dir
        ;;
    status)
        if cur="$(get_current_path 2>/dev/null)"; then
            notify "当前壁纸\n$(basename "$cur")\n${cur}"
        else
            notify "未设置壁纸\n目录: ${WALLPAPER_DIR}"
        fi
        ;;
    *)
        echo "用法: $0 next|prev|random|pick|browse|set <路径>|restore|open|status" >&2
        exit 1
        ;;
esac
