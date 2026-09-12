#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 指定运行端口(默认1200)
RUN_PORT=1200
# 服务名
SRV_NAME=rsshub
# Nginx 子路径（挂在主站域名下，不用独立端口）
REVERSE_PROXY_PATH="/rsshub/"


# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
# 检查命令
if ! [ -x "$(command -v docker)" ]; then
    prompt -e "Docker not found! Install docker first!"
    exit 1
fi

# 安装RSSHUB（容器已存在则跳过创建）
if sudo docker ps -a --format '{{.Names}}' | grep -qx rsshub; then
  prompt -i "[跳过] rsshub 容器已存在"
else
  prompt -x "Installing rsshub..."
  sudo docker pull diygod/rsshub
  prompt -x "Creating rsshub container on $RUN_PORT..."
  sudo docker create --name rsshub -p "$RUN_PORT:$RUN_PORT" diygod/rsshub
fi

# 服务（始终重跑，覆盖式）
mkdir -p "$HOME/Services/$SRV_NAME"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo cp srv.service "/home/$USER/Services/$SRV_NAME.service"
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
sudo chmod +x "/home/$USER/Services/$SRV_NAME/"*.sh
cd "$SET_DIR"

### Nginx 子路径片段（始终重跑，覆盖式）
if [ -f setupNginxForRsshub.sh ]; then
    prompt -x "运行 setupNginxForRsshub.sh（写入 /etc/nginx/snippets/rsshub.conf，子路径 $REVERSE_PROXY_PATH）"
    export RUN_PORT REVERSE_PROXY_PATH
    bash setupNginxForRsshub.sh
    prompt -i "启用：在主站 server { } 内加 include /etc/nginx/snippets/rsshub.conf; 然后 sudo nginx -t && sudo systemctl reload nginx"
else
    prompt -w "未找到 setupNginxForRsshub.sh。"
fi

