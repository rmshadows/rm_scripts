#!/bin/bash
: <<检查点八
配置Shorewall防火墙
检查点八

# 配置shorewall防火墙
if [ "$SET_SHOREWALL_SETTING" -eq 1 ]; then
    # 检查是否安装了shorewall
    if command -v shorewall &>/dev/null; then
        prompt -i "Shorewall is installed."
    else
        prompt -x "Shorewall is not installed, installing..."
        if ! doApt install shorewall; then
            prompt -e "Failed to install Shorewall. Please check your package manager."
            exit 1
        fi
    fi
    # 安装完shorewall后开始配置
    backupFile "/etc/shorewall/"
    sudo cp -r SW_CONF/* /etc/shorewall/
    prompt -w "为防止意外，请手动修改、启用Shorewall。"
fi
