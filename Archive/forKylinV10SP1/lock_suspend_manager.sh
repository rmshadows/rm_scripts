#!/bin/bash
# 银河麒麟 LightDM + GNOME 休眠锁屏管理脚本
# Author: ChatGPT
# Version: 1.0

# 颜色输出
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }

check_status() {
    echo "========== 当前配置检测 =========="
    echo "1. GNOME 锁屏状态："
    gsettings get org.gnome.desktop.screensaver lock-enabled

    echo "2. GNOME 空闲锁屏延时（秒）："
    gsettings get org.gnome.desktop.session idle-delay

    echo "3. GNOME 电源管理（插电/电池）休眠设置："
    gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
    gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type

    echo "4. systemd 休眠目标状态："
    for t in suspend.target sleep.target hibernate.target; do
        echo -n "$t: "
        systemctl is-enabled $t 2>/dev/null || echo "disabled"
        systemctl status $t --no-pager | grep "Loaded:" | sed 's/   Loaded: //'
    done

    echo "5. LightDM 锁屏触发脚本："
    if grep -q "gnome-screensaver-command -l" /etc/lightdm/lightdm.conf 2>/dev/null; then
        green "已配置锁屏命令"
    else
        yellow "未配置锁屏命令"
    fi

    echo "6. logind.conf 电源事件："
    grep -E "HandleLidSwitch|HandleLidSwitchDocked" /etc/systemd/logind.conf 2>/dev/null || yellow "未配置，使用系统默认"
    echo "================================="
}

enable_lock_suspend() {
    green "[+] 启用并修复休眠锁屏功能..."
    # GNOME 设置
    gsettings set org.gnome.desktop.screensaver lock-enabled true
    gsettings set org.gnome.desktop.session idle-delay 300
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'

    # systemd 解锁休眠
    sudo systemctl unmask suspend.target sleep.target hibernate.target

    # LightDM 配置
    sudo mkdir -p /etc/lightdm
    if ! grep -q "gnome-screensaver-command -l" /etc/lightdm/lightdm.conf 2>/dev/null; then
        echo "[Seat:*]" | sudo tee /etc/lightdm/lightdm.conf
        echo "session-setup-script=/usr/bin/gnome-screensaver-command -l" | sudo tee -a /etc/lightdm/lightdm.conf
    fi

    # logind.conf
    sudo sed -i '/HandleLidSwitch/d;/HandleLidSwitchDocked/d' /etc/systemd/logind.conf
    echo "HandleLidSwitch=suspend" | sudo tee -a /etc/systemd/logind.conf
    echo "HandleLidSwitchDocked=suspend" | sudo tee -a /etc/systemd/logind.conf
    sudo systemctl restart systemd-logind

    green "[√] 休眠锁屏功能已启用并修复完成"
}

disable_lock_suspend() {
    red "[!] 禁用休眠锁屏功能..."
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

    sudo systemctl mask suspend.target sleep.target hibernate.target

    sudo sed -i '/HandleLidSwitch/d;/HandleLidSwitchDocked/d' /etc/systemd/logind.conf
    echo "HandleLidSwitch=ignore" | sudo tee -a /etc/systemd/logind.conf
    echo "HandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf
    sudo systemctl restart systemd-logind

    red "[√] 休眠锁屏功能已禁用"
}

# 主菜单
while true; do
    echo ""
    green "=== 银河麒麟 LightDM + GNOME 休眠锁屏管理 ==="
    echo "1) 查看当前配置"
    echo "2) 启用/修复休眠锁屏"
    echo "3) 禁用休眠锁屏"
    echo "4) 退出"
    read -p "请选择操作 [1-4]: " choice
    case $choice in
        1) check_status ;;
        2) enable_lock_suspend ;;
        3) disable_lock_suspend ;;
        4) exit 0 ;;
        *) echo "无效选项" ;;
    esac
done
