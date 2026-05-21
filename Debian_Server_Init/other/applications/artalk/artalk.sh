#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=artalk
# 指定运行端口
RUN_PORT=23366
# 反向代理的地址
REVERSE_PROXY_URL=/artalk/
# 域名
YOUR_DOMAIN="example.com"
# 管理员
ADMIN_NAME=admin
# 管理员邮箱
ADMIN_EMAIL=admin@example.com
# 管理员密码
ADMIN_PASSWD=your_password
# 名称
BADGE_NAME=管理员
# 颜色
BADGE_COLOR='#0083FF'

# 生成密码(根据需要注释)
# 临时禁用 history 防止密码在历史记录中出现
unset HISTFILE 
# htpasswd -bnBC 10 "" "$ADMIN_PASSWD" | tr -d ':'
# 生成加密后的密码并存储到变量中
ENCRYPTED_PASSWD=$(htpasswd -bnBC 10 "" "$ADMIN_PASSWD" | tr -d ':')
# 输出加密后的密码（仅为验证）
echo "(bcrypt)$ENCRYPTED_PASSWD"

# 保存当前目录（运行脚本时应在 artalk/ 下）
SET_DIR=$(pwd)

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="wget"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install $t_pkg  # 更新包列表并安装
fi

t_pkg="jq"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install $t_pkg  # 更新包列表并安装
fi

### 安装软件
# 获取非pre-release版本的最新版本 https://github.com/ArtalkJS/Artalk/releases
# 设置 GitHub 仓库
REPO="ArtalkJS/Artalk"
# 获取最新发布版本的信息
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
# 筛选出包含 "linux_amd64" 的下载链接(或者arm64)
DOWNLOAD_LINK=$(echo "$LATEST_RELEASE" | jq -r '.assets[] | select(.name | test("linux_amd64")) | .browser_download_url')

# https://github.com/ArtalkJS/Artalk/releases/download/v2.9.1/artalk_v2.9.1_linux_amd64.tar.gz
# 检查是否找到了正确的下载链接
if [ -z "$DOWNLOAD_LINK" ]; then
    echo "No valid download link found for linux_amd64"
    exit 1
fi

echo "Downloading from: $DOWNLOAD_LINK"
# 下载文件
FILE="artalk.tar.gz"
wget "$DOWNLOAD_LINK" -O "$FILE"
# 检查文件是否存在
if [ -f "$FILE" ]; then
    echo "$FILE exists, extracting..."
    # 解压 tar.gz 文件
    tar -zxvf "$FILE" -C .  # -C 选项用于指定解压目录，如果不指定，默认解压到当前目录
    # 解压成功后输出提示
    if [ $? -eq 0 ]; then
        echo "Extraction completed successfully!"
        mv artalk_v* artalk
    else
        echo "Extraction failed!"
        exit 1
    fi
else
    echo "$FILE does not exist!"
    exit 1
fi
cd artalk
chmod +x artalk

### 服务生成
cd "$SET_DIR"
prompt -e "创建名为 artalk 的用户组"
sudo groupadd --system artalk
prompt -e "创建一个名为 artalk 的用户，并且拥有一个可写的 home 目录"
sudo useradd --system \
    --gid artalk \
    --create-home \
    --home-dir /home/artalk \
    --shell /usr/sbin/nologin \
    --comment "Artalk server" \
    artalk

# 移动文件夹
# artalk
# artalk.yml
# LICENSE
# README.md
# README.zh.md
sudo mv artalk/* /home/artalk/
# 新建数据文件夹
sudo mkdir -p /home/artalk/data/
sudo chown artalk /home/artalk/data/
sudo chgrp artalk /home/artalk/data/
# ip数据库
sudo wget https://github.com/lionsoul2014/ip2region/raw/master/data/ip2region.xdb -O /home/artalk/data/ip2region.xdb
sudo chown artalk /home/artalk/data/*
sudo chgrp artalk /home/artalk/data/*
sudo chown artalk /home/artalk/*
sudo chgrp artalk /home/artalk/*

cd "$SET_DIR"
replace_placeholders_with_values artalk.yml.src
backupFile /home/artalk/artalk.yml
sudo cp artalk.yml /home/artalk/artalk.yml

# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME" ];then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME..."
    sudo mkdir "$HOME/Services/$SRV_NAME"
fi
# 生成服务
cd "$SET_DIR"
prompt -x "Making Service..."
replace_placeholders_with_values artalk.service.src 2>/dev/null || true
sudo mv artalk.service "$HOME/Services/$SRV_NAME.service"
# 安装服务
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"

### Nginx 配置（与 fmgr 一致：配置写入 nginx 目录，不覆盖原机 site）
cd "$SET_DIR"
if [ -f setupNginxForArtalk.sh ]; then
    prompt -x "运行 setupNginxForArtalk.sh（写入 /etc/nginx/snippets/artalk.conf）"
    export RUN_PORT REVERSE_PROXY_URL
    bash setupNginxForArtalk.sh
else
    prompt -w "未找到 setupNginxForArtalk.sh，请手动运行以写入 nginx 片段。"
fi

replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "完整 server 示例（仅供参考，勿直接覆盖原机）："
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
prompt -i "若使用片段方式，只需在自己的 site 里加一行： include /etc/nginx/snippets/artalk.conf;"

