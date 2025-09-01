#!/bin/bash

# 禁止系统挂起和休眠
# 对 systemd 系统有效
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo systemctl stop sleep.target suspend.target hibernate.target hybrid-sleep.target

# GNOME 设置（如果是 GNOME 环境）
if command -v gsettings >/dev/null 2>&1; then
    echo "配置 GNOME 设置..."
    # 禁止自动挂起
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    # 禁止屏幕锁定
    gsettings set org.gnome.desktop.screensaver lock-enabled false
fi

# XFCE4 设置（如果是 XFCE 环境）
if command -v xfconf-query >/dev/null 2>&1; then
    echo "配置 XFCE 设置..."
    # 禁止休眠和屏幕锁定
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-on-ac -s 0
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-on-battery -s 0
    xfconf-query -c xfce4-session -p /general/LockCommand -s ''
fi

echo "系统休眠、自动挂起和屏幕锁定已禁止。重启或重新登录生效。"
