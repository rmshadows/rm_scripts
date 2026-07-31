#!/bin/bash
# 银河麒麟安装GNOME桌面
# 检查是否是银河麒麟v10sp1
OS_NAME=$(lsb_release -d | grep -i "Kylin" | grep -i "V10 SP1")
if [ -z "$OS_NAME" ]; then
    echo "此脚本仅适用于银河麒麟 v10sp1 系统"
    exit 1
fi

# 更新系统并回答提示
echo "正在升级系统..."
sudo apt update
# sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
# sudo apt-get -o Dpkg::Options::="--force-confold" -y upgrade
sudo apt dist-upgrade

# 安装 GNOME 桌面环境
echo "安装 GNOME 桌面环境..."
sudo apt install gnome gdm3

# 安装 lightdm 和 lightdm-gtk-greeter
echo "安装 lightdm 和 lightdm-gtk-greeter..."
sudo apt install lightdm lightdm-gtk-greeter

# 配置 lightdm 使用 lightdm-gtk-greeter
echo "配置 lightdm 使用 lightdm-gtk-greeter..."
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# 备份当前的 lightdm.conf 文件
sudo cp $LIGHTDM_CONF ${LIGHTDM_CONF}.${TIMESTAMP}.bak
if [ "$?" -ne 0 ]; then
    echo "文件备份失败，退出"
    exit 1
fi

# [SeatDefaults]
# autologin-user=user
# greeter-session=lightdm-gtk-greeter

# 检查并修改 greeter-session 配置行
if grep -q "greeter-session=lightdm-gtk-greeter" $LIGHTDM_CONF; then
    echo "配置已经正确，无需修改"
else
    if grep -q "greeter-session=" $LIGHTDM_CONF; then
        sudo sed -i 's/^greeter-session=.*/greeter-session=lightdm-gtk-greeter/' $LIGHTDM_CONF
    else
        sudo bash -c 'echo "[SeatDefaults]" >> /etc/lightdm/lightdm.conf'
        sudo bash -c 'echo "greeter-session=lightdm-gtk-greeter" >> /etc/lightdm/lightdm.conf'
    fi
    echo "配置已更新为使用 lightdm-gtk-greeter"
fi

# 确认 lightdm 是默认显示管理器
CURRENT_DISPLAY_MANAGER=$(cat /etc/X11/default-display-manager)
if [ "$CURRENT_DISPLAY_MANAGER" != "/usr/sbin/lightdm" ]; then
    echo "设置 lightdm 为默认显示管理器..."
    echo "/usr/sbin/lightdm" | sudo tee /etc/X11/default-display-manager
    sudo dpkg-reconfigure lightdm
fi

echo "所有任务完成，请重启系统以应用更改。"

