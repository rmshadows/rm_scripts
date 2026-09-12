#!/bin/bash
## 卸载 hackchat
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=hackchat

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置
app_remove_nginx hackchat.conf

# 3. 应用目录（含 session.key / salt.key / config.json 管理员配置）：删除前先确认
confirm_remove_data "$HOME/Applications/hackchat" "hackchat 应用及密钥/管理员配置（config.json、session.key、salt.key）"

prompt -s "hackchat 卸载流程结束。"
