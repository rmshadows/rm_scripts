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
SERVER_ROOT="$HOME/nginx"

# 保存脚本所在目录（运行脚本时应在 phptinyfilemanager/ 下）
SET_DIR=$(pwd)

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
if [ ! -d fmgr ]; then
    prompt -e "当前目录下未找到 fmgr 目录，请先放置 tinyfilemanager（或从 https://github.com/prasathmani/tinyfilemanager 获取）后再运行。"
    exit 1
fi
mkdir -p "$SERVER_ROOT"
sudo mv fmgr "$SERVER_ROOT/fmgr"
# 之后操作都在安装目录下进行（$SERVER_ROOT/fmgr）
INSTALLED_FMGR="$SERVER_ROOT/fmgr"
cd "$INSTALLED_FMGR"
# 设置权限（若 tinyfilemanager 含 files/readonly 目录）
[ -d files ] && sudo chown -R www-data:www-data files
[ -d readonly ] && sudo chown -R www-data:www-data readonly
[ -f index.php ] && sudo setfacl -m u:www-data:rx index.php
[ -f uploader.php ] && sudo setfacl -m u:www-data:rx uploader.php

prompt -w "If user www-data still cannot write, try acl(e.g: setfacl -m u:www-data:rwx files)"

### Nginx 配置（与 fmgr 一致：配置写入 nginx 目录，不覆盖原机 site）
if [ -f NginxSetup/setupNginxForFmgr.sh ]; then
    prompt -x "运行 NginxSetup/setupNginxForFmgr.sh（安装 php-fpm 并写入 /etc/nginx/snippets/fmgr.conf）"
    bash NginxSetup/setupNginxForFmgr.sh
else
    prompt -w "未找到 NginxSetup/setupNginxForFmgr.sh，请手动运行以写入 nginx 片段并安装 php-fpm。"
fi

if [ -f NginxSetup/http.src ]; then
    replace_placeholders_with_values NginxSetup/http.src
fi
prompt -i "完整 server 示例（仅供参考，勿直接覆盖原机）："
prompt -i "========================================================"
cat NginxSetup/http
prompt -i "========================================================"
prompt -i "示例文件: $INSTALLED_FMGR/NginxSetup/http"

# 回到运行脚本时的目录
cd "$SET_DIR"

