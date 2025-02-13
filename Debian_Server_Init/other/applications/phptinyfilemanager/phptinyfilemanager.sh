#!/bin/bash
## 需要有人职守，需要sudo
# https://github.com/prasathmani/tinyfilemanager    
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
# tinyfilemanager的根目录(要求www-data能写入) 
# 默认$HOME/nginx/fmgr
SERVER_ROOT=$HOME/nginx/

# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="git"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install $t_pkg  # 更新包列表并安装
fi

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

### 安装软件

sudo mv fmgr "$SERVER_ROOT"/fmgr
cd "$SERVER_ROOT"/fmgr
# 设置权限
sudo chown -R www-data:www-data files
sudo chown -R www-data:www-data readonly

sudo setfacl -m u:www-data:rx index.php
sudo setfacl -m u:www-data:rx uploader.php

prompt -w "If user www-data still cannot write, try acl(e.g: setfacl -m u:www-data:rwx files)"

### 反向代理配置
prompt -i "Check manully and setting up reverse proxy by yourself."
prompt -i "========================================================"
cat NginxSetup/http
prompt -i "========================================================"

