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
# Nginx 子路径（挂在主站域名下，不用独立端口）
REVERSE_PROXY_PATH="/isso/"
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
sudo apt-get install -y python3-setuptools python3-virtualenv python3-dev

mkdir -p "$HOME/Applications/isso" "$HOME/Logs/isso"

# 安装
if [ "$PY_VENV" -eq 0 ]; then
    if ! command -v isso &>/dev/null; then
        pip3 install --upgrade pip
        pip3 install isso
        if [ -f "/opt/isso/bin/isso" ]; then
            sudo ln -sf /opt/isso/bin/isso /usr/bin/isso
        elif [ -f "/home/$CURRENT_USER/.local/bin/isso" ]; then
            sudo ln -sf "/home/$CURRENT_USER/.local/bin/isso" /usr/bin/isso
        fi
    else
        prompt -i "[跳过] isso 已安装"
    fi
elif [ "$PY_VENV" -eq 1 ]; then
    # venv 已存在则跳过创建
    if [ -f "$INSTALL_DIR/bin/isso" ]; then
        prompt -i "[跳过] isso venv 已存在"
    else
        # venv 目录非空但不是有效 venv 时先清理
        [ -d "$INSTALL_DIR" ] && [ ! -f "$INSTALL_DIR/bin/activate" ] && sudo rm -rf "$INSTALL_DIR"
        sudo python3 -m venv "$INSTALL_DIR"
        sudo "$INSTALL_DIR"/bin/pip install --upgrade pip
        sudo "$INSTALL_DIR"/bin/pip install isso
    fi
    sudo ln -sf "$INSTALL_DIR"/bin/isso /usr/bin/isso
else
    prompt -e "PY_VENV 变量设置错误，1:是 0:否"
    exit 1
fi

# 配置文件：始终覆盖
replace_placeholders_with_values isso.conf.src
sudo cp isso.conf "$HOME/Applications/isso/isso.conf"

### 服务生成（始终重跑，覆盖式）
sudo mkdir -p "$HOME/Services/$SRV_NAME"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo cp srv.service "/home/$USER/Services/$SRV_NAME.service"
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"

### Nginx 子路径片段（始终重跑，覆盖式）
if [ -f setupNginxForIsso.sh ]; then
    prompt -x "运行 setupNginxForIsso.sh（写入 /etc/nginx/snippets/isso.conf，子路径 $REVERSE_PROXY_PATH）"
    export RUN_PORT REVERSE_PROXY_PATH
    bash setupNginxForIsso.sh
    prompt -i "启用：在主站 server { } 内加 include /etc/nginx/snippets/isso.conf; 然后 sudo nginx -t && sudo systemctl reload nginx"
    prompt -i "前端 data-isso 填 https://<域名>${REVERSE_PROXY_PATH}"
else
    prompt -w "未找到 setupNginxForIsso.sh。"
fi
