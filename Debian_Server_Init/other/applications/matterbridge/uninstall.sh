#!/bin/bash
## 卸载 matterbridge
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=matterbridge

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除应用文件
[ -d "$HOME/Applications/matterbridge" ] && rm -rf "$HOME/Applications/matterbridge"
[ -d "$HOME/Logs/matterbridge" ] && rm -rf "$HOME/Logs/matterbridge"

# 3. 清空断点标记
prompt -s "matterbridge 已卸载"
