#!/bin/bash

netid="bd5iv8fjb"

# 检查 ZeroTier 是否处于 offline 状态
status=$(sudo zerotier-cli status | grep "$netid" |grep -o "offline")

# 如果 status 变量中包含 "offline" 字符串，则重新连接 ZeroTier
if [ -n "$status" ]; then
    echo "ZeroTier is offline. Reconnecting..."
    sudo systemctl restart zerotier-one.service
else
    echo "ZeroTier is online."
fi

