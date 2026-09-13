#!/bin/bash
## 卸载 GoAccess
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=goaccess
GOACCESS_DIR="$HOME/Applications/goaccess"

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置和 htpasswd
app_remove_nginx goaccess.conf
[ -f /etc/nginx/.htpasswd_goaccess ] && sudo rm -f /etc/nginx/.htpasswd_goaccess

# 3. 删除用户数据（询问，默认保留）
confirm_remove_data "$GOACCESS_DIR" "GoAccess 配置与报告"

# 4. apt 包默认不卸载（按项目约定，避免误伤）
if dpkg -l goaccess >/dev/null 2>&1; then
  prompt -w "goaccess apt 包未卸载（如需：sudo apt remove -y goaccess）"
fi

prompt -s "GoAccess 已卸载"
