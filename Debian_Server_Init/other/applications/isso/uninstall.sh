#!/bin/bash
## 卸载 isso
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=isso

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置
app_remove_nginx isso.conf

# 3. 删除应用文件与符号链接
sudo rm -f /usr/bin/isso
[ -d "$HOME/Applications/isso" ] && sudo rm -rf "$HOME/Applications/isso"
[ -d "$HOME/Logs/isso" ] && rm -rf "$HOME/Logs/isso"

# 4. 清空断点标记
prompt -s "isso 已卸载"
