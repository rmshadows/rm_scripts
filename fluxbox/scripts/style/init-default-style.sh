#!/bin/bash
# 初始化 ryan 主题链：styles/Ryan → 实际主题，default.theme → Ryan

FLUX="${HOME}/.fluxbox"
RYAN="${FLUX}/styles/Ryan"
DEFAULT="${FLUX}/default.theme"
PATH_FILE="${FLUX}/default.style.path"
INIT="${FLUX}/init"
RYAN_PATH='~/.fluxbox/styles/Ryan'

mkdir -p "${FLUX}/styles"

# 若 Ryan 不存在，从 default.style.path / init / Font-14 推断
if [ ! -e "$RYAN" ]; then
    if [ -f "$PATH_FILE" ]; then
        target=$(tr -d '[:space:]' < "$PATH_FILE")
    elif [ -f "$INIT" ]; then
        target=$(grep -E '^session\.styleFile:' "$INIT" | sed -E 's/^session\.styleFile:[[:space:]]*//')
    else
        target="~/.fluxbox/styles/Font-14"
    fi
    target_expanded=$(eval echo "$target")
    if [ -e "$target_expanded" ] && [ "$target_expanded" != "$(eval echo "$RYAN")" ]; then
        ln -sf "$target_expanded" "$RYAN"
    elif [ -f "${FLUX}/styles/Font-14" ]; then
        ln -sf "${FLUX}/styles/Font-14" "$RYAN"
    fi
fi

# default.theme 始终指向 Ryan
if [ ! -L "$DEFAULT" ] || [ "$(readlink "$DEFAULT")" != "$RYAN" ]; then
    rm -f "$DEFAULT"
    ln -sf "$RYAN" "$DEFAULT"
fi

echo "$RYAN_PATH" > "$PATH_FILE"
