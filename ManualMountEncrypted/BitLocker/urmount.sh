#!/bin/bash
# 直接卸载。挂载点在 config.sh / .last-readmount。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/config.sh"
if [ "$?" -ne 0 ]; then
    echo "\033[0;31m Source config.sh: An error occurred and exited. \033[0m"
    exit 1
fi
source "$SCRIPT_DIR/Profile.sh"
if [ "$?" -ne 0 ]; then
    echo "\033[0;31m Source Profile.sh: An error occurred and exited. \033[0m"
    exit 1
fi

detect_existing_bitlocker_mount || true

failed=0
if is_mountpoint "$readMount"; then
    if sudo umount "$readMount"; then
        prompt -s "已卸载 $readMount"
        remove_empty_media_dir "$readMount"
    else
        failed=1
        show_mount_holders "$readMount"
    fi
else
    prompt -w "可读挂载点未挂载: $readMount"
fi
sleep 1
if is_mountpoint "$dislockMount"; then
    if sudo umount "$dislockMount"; then
        prompt -s "已卸载 $dislockMount"
    else
        failed=1
        show_mount_holders "$dislockMount"
    fi
else
    prompt -w "dislocker 挂载点未挂载: $dislockMount"
fi

if [ "$failed" -eq 0 ]; then
    rm -f "$SCRIPT_DIR/.last-readmount" 2>/dev/null || true
fi
exit "$failed"
