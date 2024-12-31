#!/bin/bash


source "GlobalVariables.sh"
source "Lib.sh"


# 检查有线网卡的函数
check_wired_network() {
    # 获取所有以 en 或 enx 开头的有线网卡接口
    wired_interfaces=$(ip link show | grep -E '^[0-9]+: (en|enx|ens|enp)' | awk '{print $2}' | sed 's/://')
    # 打印调试信息
    echo "Found interfaces: $wired_interfaces"
    # 获取网卡数量
    num_interfaces=$(echo "$wired_interfaces" | wc -l)
    echo "Number of interfaces: $num_interfaces"  # 打印网卡数量
    # 如果只有一个有线网卡，返回网卡名；如果没有或有多个，返回 0
    if [ "$num_interfaces" -eq 1 ]; then
        check_wired_network_result="$wired_interfaces"
    else
        check_wired_network_result=0
    fi
}

# 调用函数
echo 111
echo "1: $SET_WIRED_ALLOW_HOTPLUG"
echo 111
check_wired_network
SET_WIRED_ALLOW_HOTPLUG=$check_wired_network_result
echo 222
echo "2:  $SET_WIRED_ALLOW_HOTPLUG"
echo 111
echo "3: $SET_WIRED_ALLOW_HOTPLUG"