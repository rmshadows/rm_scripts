#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名(一个服务端一个客户端)
SRV_NAME_A=frp-client
SRV_NAME_B=frp-server

# 未使用的参数
REVERSE_PROXY_PORT=2053
RUN_PORT=7500
SRV_NAME=${SRV_NAME_B}

# Docs: https://gofrp.org/docs/
FRP_DOWNLOAD="https://github.com/fatedier/frp/releases/download/v0.54.0/frp_0.54.0_linux_amd64.tar.gz"
# 本地压缩包（tar.gz）注意：需要将上面设置为0
LOCAL_FRP=0

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="wget"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

### 安装软件
if ! [ -d $HOME/Applications ]; then
    mkdir $HOME/Applications
fi

# 安装
cd "$HOME/Applications/"
# 不等于0
if [ "$FRP_DOWNLOAD" -ne 0 ]; then
    # 下载安装包
    prompt -x "Downloading frp...."
    wget "$FRP_DOWNLOAD" -O frp.tar.gz
    if ! [ -f "frp.tar.gz" ]; then
        prompt -x "Wget seems error. Stopping ..."
        exit 1
    fi
else
    if [ "$LOCAL_FRP" -ne 0 ]; then
        # 直接使用本地压缩包
        prompt -x "Move $LOCAL_FRP to $(pwd)..."
        mv "$LOCAL_FRP" ./frp.tar.gz
    else
        prompt -e "未指定本地frp压缩包"
    fi
fi
prompt -x "Unzip frp...."
# 解压
tar xzvf frp.tar.gz
prompt -x "Rename...."
# 重命名文件夹
mv frp*amd64 frp
rm frp.tar.gz
# 返回之前的目录
cd -
# pwd
# 拷贝配置文件
prompt -x "Set up server and client sample..."
# replace_placeholders_with_values frpc_conf/frpc.toml.src
cp -r ./frpc_conf "$HOME/Applications/frp/frpc_conf"
replace_placeholders_with_values frps_conf/frps.toml.src
cp -r ./frps_conf "$HOME/Applications/frp/frps_conf"

### 服务生成
# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME_A" ]; then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME_A..."
    sudo mkdir "$HOME/Services/$SRV_NAME_A"
fi
if ! [ -d "$HOME/Services/$SRV_NAME_B" ]; then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME_B..."
    sudo mkdir "$HOME/Services/$SRV_NAME_B"
fi

# 生成服务
prompt -x "Making Service..."
replace_placeholders_with_values frp-client.service.src
sudo mv frp-client.service /home/$USER/Services/$SRV_NAME_A.service
replace_placeholders_with_values frp-server.service.src
sudo mv frp-server.service /home/$USER/Services/$SRV_NAME_B.service
# 安装服务
prompt -x "Install service..."
cd $HOME/Services/
sudo $HOME/Services/Install_Servces.sh
# 拷贝启动和停止的脚本
prompt -x "Make start and stop script..."
# Start and stop script
replace_placeholders_with_values start_client.sh
replace_placeholders_with_values start_server.sh
sudo cp start_client.sh /home/$USER/Services/$SRV_NAME_A/start_"$SRV_NAME_A".sh
sudo cp start_server.sh /home/$USER/Services/$SRV_NAME_B/start_"$SRV_NAME_B".sh
sudo chmod +x /home/$USER/Services/$SRV_NAME_A/*.sh
sudo chmod +x /home/$USER/Services/$SRV_NAME_B/*.sh

### 反向代理配置
prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
