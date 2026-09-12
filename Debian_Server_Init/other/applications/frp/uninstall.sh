#!/bin/bash
## 卸载 frp（客户端 + 服务端）
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

# 1. 停止并卸载两个 systemd 服务
app_remove_service frp-client
app_remove_service frp-server

# 2. 删除 nginx 配置
app_remove_nginx frp.conf

# 3. 删除应用文件
[ -d "$HOME/Applications/frp" ] && rm -rf "$HOME/Applications/frp"

# 4. 清空断点标记
prompt -s "frp 已卸载"
