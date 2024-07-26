#!/bin/bash

# 定义要添加的条目
TARGET_IP="192.168.1.11"
TARGET_HOSTNAME="meeting.lhqnyncj"
HOSTS_FILE="/etc/hosts"

# 检查是否已有指定条目
EXISTING_ENTRY=$(grep -w "$TARGET_HOSTNAME" $HOSTS_FILE)

TIMESTAMP=$(date +%Y%m%d%H%M%S)

if [ -z "$EXISTING_ENTRY" ]; then
    # 备份当前的 /etc/hosts 文件
    cp $HOSTS_FILE ${HOSTS_FILE}${TIMESTAMP}.bak
    if [ "$?" -ne 0 ]; then
        echo "文件备份失败，退出"
        exit 1
    fi
    # 如果没有条目，则添加新的条目
    echo "$TARGET_IP    $TARGET_HOSTNAME" | sudo tee -a $HOSTS_FILE
    echo "Added $TARGET_IP    $TARGET_HOSTNAME to $HOSTS_FILE"
else
    # 如果有条目，检查IP是否正确
    EXISTING_IP=$(echo $EXISTING_ENTRY | awk '{print $1}')
    if [ "$EXISTING_IP" != "$TARGET_IP" ]; then
        # 如果IP不正确，则修改条目
        sudo sed -i "s/$EXISTING_IP\s\+$TARGET_HOSTNAME/$TARGET_IP    $TARGET_HOSTNAME/" $HOSTS_FILE
        echo "Updated $TARGET_HOSTNAME to $TARGET_IP in $HOSTS_FILE"
    else
        echo "Entry $TARGET_IP    $TARGET_HOSTNAME already exists in $HOSTS_FILE"
    fi
fi

# 刷新 DNS 缓存（如果适用）
if command -v systemd-resolve &> /dev/null; then
    sudo systemd-resolve --flush-caches
    echo "DNS 缓存已刷新"
elif command -v dnsmasq &> /dev/null; then
    sudo systemctl restart dnsmasq
    echo "dnsmasq 服务已重启"
elif command -v nscd &> /dev/null; then
    sudo systemctl restart nscd
    echo "nscd 服务已重启"
fi

# 重新启动网络服务（如果适用）
if command -v nmcli &> /dev/null; then
    sudo nmcli networking off
    sudo nmcli networking on
    echo "NetworkManager 已重启"
elif command -v systemctl &> /dev/null; then
    sudo systemctl restart networking
    echo "网络服务已重启"
fi

echo "更改已生效"

