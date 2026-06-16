#!/bin/bash
# Fluxbox init 读写辅助（被其他脚本 source）

FLUXBOX_INIT="${HOME}/.fluxbox/init"

fluxbox_get_init() {
    local key="$1"
    grep -E "^${key}:" "$FLUXBOX_INIT" 2>/dev/null | head -1 | sed -E "s/^${key}:[[:space:]]*//"
}

fluxbox_set_init() {
    local key="$1"
    local val="$2"
    if grep -qE "^${key}:" "$FLUXBOX_INIT"; then
        sed -i "s|^${key}:.*|${key}:\t${val}|" "$FLUXBOX_INIT"
    else
        printf '%s\t%s\n' "$key" "$val" >> "$FLUXBOX_INIT"
    fi
}

fluxbox_toggle_init() {
    local key="$1"
    local a="$2"
    local b="$3"
    local cur
    cur="$(fluxbox_get_init "$key")"
    if [ "$cur" = "$a" ]; then
        fluxbox_set_init "$key" "$b"
    else
        fluxbox_set_init "$key" "$a"
    fi
}

fluxbox_reconfigure() {
    fluxbox-remote reloadstyle 2>/dev/null || true
    fluxbox-remote reconfigure 2>/dev/null || true
}
