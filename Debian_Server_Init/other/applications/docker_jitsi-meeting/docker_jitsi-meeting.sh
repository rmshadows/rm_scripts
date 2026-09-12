#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=jitsi-meet-docker
# Jitsi 公共访问地址（含协议前缀）：写入 .env 的 PUBLIC_URL，jitsi 客户端会用它连接。
# 例：https://meet.example.com
YOUR_DOMAIN="https://domain.com"
# 反向代理的地址
REVERSE_PROXY_URL=/jm/
# 指定版本的下载地址(会下载tar.gz)
# DOCKER_STABLE="https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/stable-10008.tar.gz"
DOCKER_STABLE="https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/stable-10008.tar.gz"

# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="docker"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    exit 1
fi

t_pkg="docker-compose"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    exit 1
fi

### 安装软件
# 检测：.env 已存在则跳过下载解压（gen-passwords 只跑一次）
if [ -f "$HOME/Applications/docker-jitsi-meet/.env" ]; then
  prompt -i "[跳过] jitsi-meet 已安装"
else
cd $HOME/Applications
prompt -x "Downloading docker-jitsi-meet"
wget "$DOCKER_STABLE" -O jitsi-meet-docker.tar.gz
if ! [ -f jitsi-meet-docker.tar.gz ]; then
    prompt -e "Wget seems wrong. Stopping ..."
    exit 1
fi
prompt -x "Unzip tar.gz..."
tar xzvf jitsi-meet-docker.tar.gz
prompt -x "Rename..."
cp -r docker-jitsi-meet-* docker-jitsi-meet
cd "$SET_DIR"
replace_placeholders_with_values env.src
cp env $HOME/Applications/docker-jitsi-meet/.env
cd $HOME/Applications/docker-jitsi-meet
./gen-passwords.sh
prompt -x "Create required CONFIG directories..."
mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
prompt -x "Access the web UI at https://localhost:8443"
prompt -w "Testing......"
docker-compose up -d
if [ "$?" -ne 0 ]; then
    prompt -e "Docker-compose may wrong....Check manually."
    sudo docker-compose down
    exit 1
else
    prompt -x "Test done."
    sudo docker-compose down
fi
fi

### 服务生成（始终重跑，覆盖式）
sudo mkdir -p "$HOME/Services/$SRV_NAME"
cd "$SET_DIR"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo cp srv.service /home/$USER/Services/$SRV_NAME.service
prompt -x "Install service..."
cd $HOME/Services/
sudo $HOME/Services/Install_Services.sh
cd "$SET_DIR"

### 反向代理配置（始终生成）
cd "$SET_DIR"
prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
