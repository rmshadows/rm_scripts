#!/bin/bash
# interactive-time-sync.sh - 交互式时间同步工具 (适配 Debian 13)
# 作者: 你的AI助手

echo "=== Debian 13 时间同步工具 ==="

# 询问是否要执行时间同步
read -p "是否要进行网络时间同步？(y/N): " do_sync
if [[ "$do_sync" != "y" && "$do_sync" != "Y" ]]; then
    echo "→ 已取消时间同步。"
    exit 0
fi

# 提供常见 NTP 服务器选项
echo "请选择时间同步服务器:"
echo "  1) ntp.aliyun.com (推荐，上海地区)"
echo "  2) cn.pool.ntp.org (中国公共池)"
echo "  3) time.windows.com (微软)"
echo "  4) 自定义"
read -p "请输入选项 [1-4，默认1]: " choice

case "$choice" in
    2) NTP_SERVER="cn.pool.ntp.org" ;;
    3) NTP_SERVER="time.windows.com" ;;
    4) read -p "请输入自定义NTP服务器: " NTP_SERVER ;;
    *) NTP_SERVER="ntp.aliyun.com" ;;
esac

echo "→ 将使用 NTP 服务器: $NTP_SERVER"

# 确认是否使用 chrony 或 systemd-timesyncd
if command -v chronyd &>/dev/null; then
    echo "检测到 chrony，使用 chrony 对时..."
    sudo chronyd -q "server $NTP_SERVER iburst"
else
    echo "未检测到 chrony，改用 systemd-timesyncd..."
    sudo timedatectl set-ntp true
    sudo systemctl restart systemd-timesyncd
    echo "正在尝试手动一次性同步..."
    sudo ntpdate -u $NTP_SERVER 2>/dev/null || echo "提示: ntpdate 未安装，建议安装 chrony 更好。"
fi

# 显示当前时间
echo "=== 当前系统时间 ==="
date

# 询问是否要同步硬件时间 (BIOS/RTC)
read -p "是否要将系统时间写入硬件时钟(防止开机漂移)? (y/N): " sync_hw
if [[ "$sync_hw" == "y" || "$sync_hw" == "Y" ]]; then
    sudo hwclock --systohc
    echo "→ 已将系统时间同步到硬件时钟。"
else
    echo "→ 已跳过硬件时钟同步。"
fi

echo "=== 时间同步完成 ==="
