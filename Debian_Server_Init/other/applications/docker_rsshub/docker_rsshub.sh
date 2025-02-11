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
# 反向代理的地址
REVERSE_PROXY_URL=/rsshub/

#### 正文
# 检查命令
if ! [ -x "$(command -v docker)" ]; then
    prompt -e "Docker not found! Install docker first!"
    exit 1
fi

# 安装RSSHUB
prompt -x "Stopping rsshub & Removing rsshub..."
sudo docker stop rsshub
sudo docker rm rsshub
prompt -x "Installing rsshub..."
sudo docker pull diygod/rsshub
prompt -x "Creating rsshub container on $RUN_PORT..."
sudo docker create --name rsshub -p $RUN_PORT:$RUN_PORT diygod/rsshub
# prompt -x "Running rsshub on $RUN_PORT..."
# sudo docker run -d --name rsshub -p $RUN_PORT:$RUN_PORT diygod/rsshub

# mk srv
# 创建专门文件夹
if ! [ -d $HOME/Services/$SRV_NAME ];then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME..."
    mkdir $HOME/Services/$SRV_NAME
fi
# 生成服务
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo mv srv.service /home/$USER/Services/$SRV_NAME.service
# 安装服务
prompt -x "Install service..."
cd $HOME/Services/
sudo $HOME/Services/Install_Servces.sh

sudo chmod +x /home/$USER/Services/$SRV_NAME/*.sh

prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"

