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
# 域名 会用在jitsi的public url
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
prompt -x "Create required CONFIG directories ~/.jitsi-meet-cfg/{web/crontabs,web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}..."
mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
prompt -x "Access the web UI at https://localhost:8443 (or a different port, in case you edited the compose file)."
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

### 服务生成
# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME" ]; then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME..."
    sudo mkdir "$HOME/Services/$SRV_NAME"
fi
# 生成服务
cd "$SET_DIR"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo mv srv.service /home/$USER/Services/$SRV_NAME.service
# 安装服务
prompt -x "Install service..."
cd $HOME/Services/
sudo $HOME/Services/Install_Servces.sh

### 反向代理配置
cd "$SET_DIR"
prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
