#!/bin/bash
## 需要有人职守，需要sudo
# https://posativ.org/isso/
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=isso
# 指定运行端口
RUN_PORT=3500
# 反向代理的地址
REVERSE_PROXY_URL=/isso/
# 你的域名 Include https://
DOMAIN_N="https://127.0.0.1/"
# 使用python虚拟环境安装(推荐)
PY_VENV=1
# 安装位置
INSTALL_DIR="$HOME/Applications/isso"

# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="python3"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

### 安装软件
# sudo apt-get install python-setuptools python-virtualenv
# sudo apt-get install python-dev sqlite3 build-essential python3-venv
# sudo apt install libaugeas0
sudo apt-get install python3-setuptools python3-virtualenv python3-dev

if ! [ -d $HOME/Applications ]; then
    mkdir $HOME/Applications
fi

if ! [ -d $HOME/Applications/isso/ ]; then
    mkdir $HOME/Applications/isso/
fi

if ! [ -d $HOME/Logs ]; then
    mkdir $HOME/Logs/
fi

if ! [ -d $HOME/Logs/isso/ ]; then
    mkdir $HOME/Logs/isso/
fi

# 安装
if [ "$PY_VENV" -eq 0 ]; then
    pip3 install --upgrade pip
    pip3 install isso
    if [ -f "/opt/isso/bin/isso" ]; then
        sudo ln -s /opt/isso/bin/isso /usr/bin/isso
    elif [ -f "/home/$CURRENT_USER/.local/bin/isso" ]; then
        sudo ln -s "/home/$CURRENT_USER/.local/bin/isso" /usr/bin/isso
    fi
elif [ "$PY_VENV" -eq 1 ]; then
    # Set up a Python virtual environment/opt/isso/
    sudo python3 -m venv "$INSTALL_DIR"
    sudo "$INSTALL_DIR"/bin/pip install --upgrade pip
    sudo "$INSTALL_DIR"/bin/pip install isso
    sudo ln -s "$INSTALL_DIR"/bin/isso /usr/bin/isso

else
    prompt -e "PY_VENV 变量设置错误，1:是 0:否"
    exit 1
fi

replace_placeholders_with_values isso.conf.src
sudo cp isso.conf "$HOME/Applications/isso/isso.conf"

### 服务生成
# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME" ]; then
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

### 反向代理配置
cd "$SET_DIR"
prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
