#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=matterbridge
# 媒体域名 Include https:// no end : /
DOMAIN_MEDIA="https://yourdomain"

# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
### 安装软件
if ! [ -d $HOME/Applications ];then
    mkdir $HOME/Applications
fi

if ! [ -d $HOME/Applications/matterbridge/ ];then
    mkdir $HOME/Applications/matterbridge/
fi

if ! [ -d $HOME/Logs ];then
    mkdir $HOME/Logs/
fi

if ! [ -d $HOME/Logs/matterbridge/ ];then
    mkdir $HOME/Logs/matterbridge/
fi

# 安装
wget -O matterbridge-linux https://github.com/42wim/matterbridge/releases/download/v1.25.2/matterbridge-1.25.2-linux-64bit
# 配置文件
replace_placeholders_with_values matterbridge.toml.src
sudo cp matterbridge.toml "$HOME/Applications/matterbridge/matterbridge.toml"


### 服务生成
# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME" ];then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME..."
    sudo mkdir "$HOME/Services/$SRV_NAME"
fi
# 生成服务
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo mv srv.service /home/$USER/Services/$SRV_NAME.service
# 安装服务
prompt -x "Install service..."
cd $HOME/Services/
sudo $HOME/Services/Install_Servces.sh
# 拷贝启动和停止的脚本
prompt -x "Make start and stop script..."
# Start and stop script
replace_placeholders_with_values start.sh.src
sudo cp start.sh /home/$USER/Services/$SRV_NAME/start_"$SRV_NAME".sh
sudo chmod +x /home/$USER/Services/$SRV_NAME/*.sh

### 反向代理配置
prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"

