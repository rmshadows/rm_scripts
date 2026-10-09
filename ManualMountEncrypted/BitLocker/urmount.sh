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
acted=0
if is_mountpoint "$readMount"; then
    acted=1
    if sudo umount "$readMount"; then
        remove_empty_media_dir "$readMount"
    else
        failed=1
        show_mount_holders "$readMount"
    fi
fi
sleep 1
if is_mountpoint "$dislockMount"; then
    acted=1
    if ! sudo umount "$dislockMount"; then
        failed=1
        show_mount_holders "$dislockMount"
    fi
fi

if [ "$failed" -ne 0 ]; then
    print_result_banner fail "卸载失败" "占用进程见上方，关掉后再卸"
    exit 1
fi
if [ "$acted" -eq 0 ]; then
    echo
    echo "目录: $readMount"
    echo "解密点: $dislockMount"
    echo "状态: 未挂载"
    print_result_banner fail "卸载失败" "现在没有挂载"
    exit 1
fi
rm -f "$SCRIPT_DIR/.last-readmount" 2>/dev/null || true
echo
echo "目录: $readMount"
echo "解密点: $dislockMount"
echo "状态: 已卸载"
print_result_banner ok "卸载成功" "$readMount"
exit 0
