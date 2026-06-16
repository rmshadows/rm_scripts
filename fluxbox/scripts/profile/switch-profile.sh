#!/bin/bash
# 应用场景 profile：profiles/*.profile

set -euo pipefail
source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

PROFILE="${1:-}"
PROFILES_DIR="${HOME}/.fluxbox/profiles"

if [ -z "$PROFILE" ]; then
    command -v zenity >/dev/null 2>&1 && \
        PROFILE=$(zenity --list --title="选择场景" --column="Profile" $(ls "$PROFILES_DIR"/*.profile 2>/dev/null | xargs -n1 basename | sed 's/.profile//')) || exit 0
fi

FILE="${PROFILES_DIR}/${PROFILE}.profile"
if [ ! -f "$FILE" ]; then
    echo "找不到 profile: $FILE" >&2
    exit 1
fi

CONKY_CMD=""
while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    if [[ "$line" =~ ^CONKY= ]]; then
        CONKY_CMD="${line#CONKY=}"
        continue
    fi
    key="${line%%=*}"
    val="${line#*=}"
    fluxbox_set_init "$key" "$val"
done < "$FILE"

fluxbox_reconfigure

pkill conky 2>/dev/null || true
if [ "$CONKY_CMD" = "off" ]; then
    :
elif [ -n "$CONKY_CMD" ]; then
    if [[ "$CONKY_CMD" == *"&"* ]]; then
        eval "$CONKY_CMD"
    else
        bash "$CONKY_CMD" &
    fi
fi
