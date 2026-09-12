#!/bin/bash
## 卸载 myapp（模板：复制后按需修改）
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=myapp

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置
app_remove_nginx myapp.conf

# 3. 删除应用文件（按需修改路径）
# [ -d "$HOME/Applications/myapp" ] && rm -rf "$HOME/Applications/myapp"

# 4. 清空断点标记
prompt -s "myapp 已卸载"
