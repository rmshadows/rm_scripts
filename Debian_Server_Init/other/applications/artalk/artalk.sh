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
# Nginx 子路径（挂在主站域名下，不用独立端口）
REVERSE_PROXY_PATH="/artalk/"
# 应用访问域名：用于 artalk.yml 的 site_url（默认站点 URL），即前端评论区实际访问的域名。
# 例：civiccccc.ltd
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
# App Key (JWT 密钥)，留空则自动生成随机字符串
APP_KEY=""

# 生成密码(根据需要注释)
# 临时禁用 history 防止密码在历史记录中出现
unset HISTFILE 
# htpasswd -bnBC 10 "" "$ADMIN_PASSWD" | tr -d ':'
# 生成加密后的密码并存储到变量中
ENCRYPTED_PASSWD=$(htpasswd -bnBC 10 "" "$ADMIN_PASSWD" | tr -d ':')
# 输出加密后的密码（仅为验证）
echo "(bcrypt)$ENCRYPTED_PASSWD"

# 生成 App Key（留空则随机生成 32 位字母数字，确保 YAML 安全）
if [ -z "$APP_KEY" ]; then
  APP_KEY=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
fi

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
# 检测最终产物：本地已解压 或 已部署到 /home/artalk，任一存在则跳过下载
if [ -f "/home/artalk/artalk" ] || [ -f "$SET_DIR/artalk/artalk" ]; then
  prompt -i "[跳过] artalk 已下载解压"
else
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
fi

### 部署：用户 + 文件 + 配置（幂等，可重复运行）
cd "$SET_DIR"
# 用户/组：存在则跳过
getent group artalk >/dev/null 2>&1 || { prompt -e "创建名为 artalk 的用户组"; sudo groupadd --system artalk; }
id artalk >/dev/null 2>&1 || {
  prompt -e "创建一个名为 artalk 的用户，并且拥有一个可写的 home 目录"
  sudo useradd --system \
      --gid artalk \
      --create-home \
      --home-dir /home/artalk \
      --shell /usr/sbin/nologin \
      --comment "Artalk server" \
      artalk
}
# 移动文件：源目录非空才移动（已移动过则跳过）
if [ -d "artalk" ] && [ -n "$(ls -A artalk 2>/dev/null)" ]; then
  sudo mv artalk/* /home/artalk/
fi
# 新建数据文件夹
sudo mkdir -p /home/artalk/data/
sudo chown artalk:artalk /home/artalk/data/
# ip数据库（始终覆盖最新）
sudo wget https://github.com/lionsoul2014/ip2region/raw/master/data/ip2region_v4.xdb -O /home/artalk/data/ip2region.xdb
sudo chown -R artalk:artalk /home/artalk/data/
sudo chown artalk:artalk /home/artalk/* 2>/dev/null || true

# 配置文件：始终覆盖
cd "$SET_DIR"
replace_placeholders_with_values artalk.yml.src
backupFile /home/artalk/artalk.yml
sudo cp artalk.yml /home/artalk/artalk.yml

### 服务（始终重跑，幂等覆盖）
sudo mkdir -p "$HOME/Services/$SRV_NAME"
cd "$SET_DIR"
prompt -x "Making Service..."
replace_placeholders_with_values artalk.service.src 2>/dev/null || true
sudo cp artalk.service "$HOME/Services/$SRV_NAME.service"
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"

### Nginx 子路径片段（始终重跑，覆盖式更新）
if [ -f setupNginxForArtalk.sh ]; then
    prompt -x "运行 setupNginxForArtalk.sh（写入 /etc/nginx/snippets/artalk.conf，子路径 $REVERSE_PROXY_PATH）"
    export RUN_PORT REVERSE_PROXY_PATH
    bash setupNginxForArtalk.sh
    prompt -i "启用：在主站 server { } 内加 include /etc/nginx/snippets/artalk.conf; 然后 sudo nginx -t && sudo systemctl reload nginx"
else
    prompt -w "未找到 setupNginxForArtalk.sh。"
fi

