#!/bin/bash
# 已挂载则询问卸载，未挂载则询问挂载。参数在 config.sh。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib.sh"

if detect_existing_veracrypt_mount; then
    comfirmy "\e[1;33m VeraCrypt 卷已挂载在 $readMount ，是否卸载？ [Y/n]\e[0m"
    choice=$?
    if [ "$choice" -eq 1 ]; then
        umount_veracrypt
        exit $?
    elif [ "$choice" -eq 2 ]; then
        prompt -i "已取消。"
        exit 0
    else
        prompt -e "ERROR:未知返回值!"
        exit 5
    fi
fi

comfirmy "\e[1;33m VeraCrypt 卷未挂载，是否挂载？ [Y/n]\e[0m"
choice=$?
if [ "$choice" -eq 1 ]; then
    mount_veracrypt
    exit $?
elif [ "$choice" -eq 2 ]; then
    prompt -i "已取消。"
    exit 0
else
    prompt -e "ERROR:未知返回值!"
    exit 5
fi
