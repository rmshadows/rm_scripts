#!/bin/bash
## 需要有人职守，需要sudo
# https://github.com/ZizzyDizzyMC/linx-server
# 要求非root用户
# 自定义主页请修改./templates/文件夹
# 要求sudo git go acl
# 详情见readme
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=linx-server
# 指定运行端口
RUN_PORT=8087
# Nginx 独立站端口（不要用 80/443）
SITE_LISTEN=8083
# 独立站标识：用于生成 nginx 站点配置的 server_name，以及 SSL 证书文件名 /etc/ssl/<SITE_NAME>.pem。
# 留空 = 不生成独立站点，仅做子路径反代（需在主站 include linx.conf）。
# 独立域名部署时，通常与 YOUR_DOMAIN 填同一个域名。
SITE_NAME=
# 应用访问域名：linx 生成的下载链接前缀 https://<YOUR_DOMAIN>/...
# （子路径反代时填主站域名，如 example.com；独立站时填本站域名）
YOUR_DOMAIN="example.com"
# 运行的共享文件目录
LFSS_ROOT="/home/lfss-file-share"
# LFSS仓库
LFSS_REPO="https://github.com/ZizzyDizzyMC/linx-server"

# 保存当前目录（运行脚本时应在 linxfilesharing/ 下）
SET_DIR=$(pwd)
#### 正文
### 准备工作
# 检查包是否已安装 git go acl
t_pkg="git"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install $t_pkg  # 更新包列表并安装
fi
t_pkg="go"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    # sudo apt update && sudo apt install golang  # 更新包列表并安装
    echo "See https://go.dev/dl/"
    exit 1
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
# 检测最终产物：linx-server 二进制已部署到 $LFSS_ROOT 则跳过编译
if [ -f "$LFSS_ROOT/linx-server" ]; then
  prompt -i "[跳过] linx-server 已编译安装"
else
mkdir -p "$HOME/Applications"
sudo mkdir -p "$LFSS_ROOT"

# 安装
cd "$HOME/Applications"
if [ -d linx-file-share-repo ]; then
    echo "linx-file-share-repo 已存在，跳过 clone。"
    cd linx-file-share-repo
else
    git clone "$LFSS_REPO" linx-file-share-repo
    cd linx-file-share-repo || { echo "❌ 无法进入目录 linx-file-share-repo"; exit 1; }
fi

# 编译
# 主文件 
go build
# 编译清理文件
mv ./linx-cleanup/ ./linx-cleanup-export/
cd ./linx-cleanup-export/
go build
cp ./linx-cleanup-export ./../linx-cleanup
cd ./../
# 编译API Key文件
mv ./linx-genkey/ ./linx-genkey-export/
cd ./linx-genkey-export/
go build
cp ./linx-genkey-export ./../linx-genkey
cd ./../
# 设置可执行
chmod +x ./linx-server
chmod +x ./linx-genkey
chmod +x ./linx-cleanup
# 复制文件
sudo cp ./linx-server "$LFSS_ROOT"
sudo cp ./linx-genkey "$LFSS_ROOT"
sudo cp ./linx-cleanup "$LFSS_ROOT"
# 复制文件夹
sudo cp -r ./templates/ "$LFSS_ROOT"
fi

# 生成配置文件（始终覆盖）
cd "$SET_DIR"
replace_placeholders_with_values linx-server.conf.src
sudo cp linx-server.conf "$LFSS_ROOT"/linx-server.conf

sudo chown www-data "$LFSS_ROOT"
sudo chown www-data "$LFSS_ROOT"/* 2>/dev/null || true
sudo chgrp www-data "$LFSS_ROOT"
sudo chgrp www-data "$LFSS_ROOT"/* 2>/dev/null || true

### 服务生成（始终重跑，覆盖式）
sudo mkdir -p "$HOME/Services/$SRV_NAME"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo cp srv.service "$HOME/Services/$SRV_NAME.service"
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"
prompt -x "Make start and stop script..."
replace_placeholders_with_values start.sh.src
sudo cp start.sh "$HOME/Services/$SRV_NAME/start_${SRV_NAME}.sh"
sudo chmod +x "$HOME/Services/$SRV_NAME"/*.sh

### Nginx 独立站（始终重跑，覆盖式）
cd "$SET_DIR"
if [ -f setupNginxForLinx.sh ]; then
    prompt -x "运行 setupNginxForLinx.sh（写入 /etc/nginx/sites-available/linx.conf，不启用）"
    export RUN_PORT SITE_LISTEN SITE_NAME YOUR_DOMAIN HOME
    bash setupNginxForLinx.sh
    prompt -i "启用独立站： sudo ngx-site"
else
    prompt -w "未找到 setupNginxForLinx.sh。"
fi

