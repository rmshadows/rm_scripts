#!/bin/bash
:<<!说明
此脚本获取sudo
!说明

:<<!预先检查
确认运行
!预先检查

### 部署前警告 + 必须确认（续跑才跳过 y/N）
# 直接跑也会走到这里。没现成账号时，确认后选择自动生成或自己输入。
deploy_print_preflight
deploy_confirm_start $'\e[1;31m 已阅读以上警告？输入 y 开始部署（将改系统）。直接回车取消 [y/N]\e[0m'

# 有 .deploy_credentials 或强账号就用；否则询问 1=自动生成 / 2=自己输入。
force_change_default_credentials

t_pkg="acl"
if ! command -v setfacl &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Installing $t_pkg...\033[0m" # 输出红色提示
    sudo apt update && sudo apt install -y $t_pkg                   # 更新包列表并安装
    if [ $? -ne 0 ]; then
        echo -e "\033[31mFailed to install $t_pkg. Please check your package manager.\033[0m"
        exit 1
    fi
else
    echo -e "\033[32m$t_pkg is already installed.\033[0m" # 输出绿色提示
fi
