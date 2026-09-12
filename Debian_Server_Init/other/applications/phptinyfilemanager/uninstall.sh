#!/bin/bash
## 卸载 phptinyfilemanager
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SERVER_ROOT="${SERVER_ROOT:-$HOME/nginx}"

# 1. 删除 nginx 配置
app_remove_nginx fmgr.conf

# 2. 应用目录（含 files/ 用户上传文件）：删除前先确认
confirm_remove_data "$SERVER_ROOT/fmgr" "文件管理器程序及 files/ 目录下的用户上传文件"

prompt -s "phptinyfilemanager 卸载流程结束。"
