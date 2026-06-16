#!/bin/bash
# Fluxbox 环境 apt 依赖
# 不需要的包可注释掉；安装: ./apt-install.sh  或在 setup/Config.sh 设 SET_INSTALL_APT_DEPS=1

set -euo pipefail

PACKAGES=(
    # --- 核心 ---
    fluxbox
  # conky-all          # 若 conky 包不可用可换此包名
    conky
    feh                  # startup 里 fbsetbg 壁纸
    x11-xserver-utils    # xrandr, xprop, setxkbmap
    zenity               # 菜单脚本：确认框、列表选择
    xdotool

    # --- 启动器 / 锁屏 / 截图 ---
    rofi
    scrot
    flameshot
    i3lock-fancy
  # i3lock               # 锁屏备选（menu 里也有 i3lock -f 用法）

    # --- 系统托盘 / 权限 ---
    lxpolkit             # polkit 认证（关机走 systemctl 时需要）
    nm-tray
  # pasystray            # PulseAudio 托盘（音量，按需）
  # volumeicon-alsa      # ALSA 音量托盘（按需）

    # --- 外观 ---
    lxappearance         # GTK 主题/图标（Appearance 菜单）
  # gtk2-engines         # 部分 GTK2 主题需要

    # --- 终端 / 文件管理 / 工具 ---
    gnome-terminal
    xfce4-terminal
    xfce4-appfinder
    gnome-system-monitor
    nautilus
    thunar
    gnome-settings-daemon
    numlockx
  # leafpad              # 菜单 Edit Menu/Init/Keys 用，可换 mousepad 等

    # --- 媒体键 / 音量 / 亮度 ---
    alsa-utils           # amixer 音量（媒体键脚本）
    brightnessctl        # 笔记本背光（Fn 亮度键）
    pipewire-pulse       # pactl 音量（PipeWire 环境，可选）
  # pulseaudio-utils     # 若不用 pipewire 可换此包
  # playerctl            # 播放/暂停/下一曲媒体键（keys 里默认注释）

    # --- 可选 ---
  # ksnip                # 截图备选（keys 里注释了）
  # wmctrl               # 工作区切换备选（keys 里注释了）
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"
