#!/bin/bash
## 卸载 linx-server 文件共享
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=linx-server
LFSS_ROOT="${LFSS_ROOT:-/home/lfss-file-share}"

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置
app_remove_nginx linx.conf

# 3. 共享文件目录（含程序二进制 + 用户上传文件）：删除前先确认
confirm_remove_data "$LFSS_ROOT" "linx 共享文件（程序及所有用户上传的文件）"

# 4. 清理源码目录（编译产物，可重新 clone，无用户数据）
[ -d "$HOME/Applications/linx-file-share-repo" ] && rm -rf "$HOME/Applications/linx-file-share-repo"

prompt -s "linx-server 卸载流程结束。"
