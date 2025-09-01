#!/bin/bash

### === 参数区域 === ###
# 留空则默认使用当前用户
TARGET_USER="${TARGET_USER:-$(logname)}"
# TARGET_USER="${TARGET_USER:-$(logname)}"
SUDOERS_FILE="/etc/sudoers.d/nopasswd_$TARGET_USER"
ENABLE_NOPASSWD=true   # 设置为 false 将移除免密码；或用参数 --undo

### === 函数定义 === ###

grant_nopasswd() {
    if [ -f "$SUDOERS_FILE" ]; then
        echo "[✔] Sudoers 文件已存在: $SUDOERS_FILE"
    else
        echo "[+] 添加 sudo 免密码权限给用户: $TARGET_USER"
        echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
        sudo chmod 440 "$SUDOERS_FILE"
        echo "[✔] 添加完成"
    fi
}

revoke_nopasswd() {
    if [ -f "$SUDOERS_FILE" ]; then
        echo "[+] 移除 sudo 免密码权限: $TARGET_USER"
        sudo rm -f "$SUDOERS_FILE"
        echo "[✔] 已移除"
    else
        echo "[!] 没有找到对应的 sudoers 文件，无需移除"
    fi
}

### === 主程序入口 === ###

if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 或 sudo 权限运行本脚本"
    exit 1
fi

if [ -z "$(id -u "$TARGET_USER" 2>/dev/null)" ]; then
    echo "❌ 用户 $TARGET_USER 不存在"
    exit 2
fi

if [ "$1" == "--undo" ]; then
    revoke_nopasswd
elif [ "$ENABLE_NOPASSWD" == "true" ]; then
    grant_nopasswd
else
    echo "[i] 配置设定为不启用 sudo 免密码"
    revoke_nopasswd
fi

