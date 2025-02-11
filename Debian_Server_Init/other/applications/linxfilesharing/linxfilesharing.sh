#!/bin/bash
## 需要有人职守，需要sudo
# https://github.com/ZizzyDizzyMC/linx-server
# 要求非root用户
# 自定义主页请修改./templates/文件夹
# 要求sudo git go acl
# 详情见readme
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=linx-server
# 指定运行端口
RUN_PORT=8087
# 你的域名
YOUR_DOMAIN="example.com"
# 运行的共享文件目录
LFSS_ROOT="$HOME/lfss-file-share"
# LFSS仓库
LFSS_REPO="https://github.com/ZizzyDizzyMC/linx-server"

# 保存当前目录
SET_DIR=$(pwd)
#### 正文
### 准备工作
# 检查包是否已安装 git go acl
t_pkg="git"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install $t_pkg  # 更新包列表并安装
fi
t_pkg="go"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install golang  # 更新包列表并安装
fi
t_pkg="acl"
if ! command -v setfacl &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Installing $t_pkg...\033[0m" # 输出红色提示
    sudo apt update && sudo apt install -y $t_pkg                   # 更新包列表并安装
    if [ $? -ne 0 ]; then
        echo -e "\033[31mFailed to install $t_pkg. Please check your package manager.\033[0m"
        exit 1
    fi
else
    echo -e "\033[32m$t_pkg is already installed.\033[0m" # 输出绿色提示
fi

### 安装软件
if ! [ -d $HOME/Applications ];then
    mkdir $HOME/Applications
fi
# 建立ROOT文件夹
if ! [ -d "$LFSS_ROOT" ];then
    mkdir -p "$LFSS_ROOT"
fi

# 安装
cd $HOME/Applications
git clone "$LFSS_REPO" linx-file-share-repo
# 检查 git clone 是否成功
if [ $? -eq 0 ]; then
    echo "✅ Git clone 成功!"
    # 进入克隆的目录
    cd linx-file-share-repo || { echo "❌ 无法进入目录 linx-file-share-repo"; exit 1; }
else
    echo "❌ Git clone 失败，请检查仓库地址或网络连接。"
    exit 1
fi

# 编译
# 主文件
go build
# 编译清理文件
mv ./linx-cleanup/ ./linx-cleanup-export/
cd ./linx-cleanup-export/
go build
cp ./linx-cleanup ./../
cd ./../
# 编译API Key文件
mv ./linx-genkey/ ./linx-genkey-export/
cd ./linx-genkey-export/
go build
cp ./linx-genkey ./../
cd ./../
# 设置可执行
chmod +x ./linx-server
chmod +x ./linx-genkey
chmod +x ./linx-cleanup
# 复制文件
sudo cp ./linx-server "$LFSS_ROOT"
sudo cp ./linx-genkey "$LFSS_ROOT"
sudo cp ./linx-cleanup "$LFSS_ROOT"
# 复制文件夹
sudo cp -r ./templates/ "$LFSS_ROOT"
# 生成配置文件
cd "$SET_DIR"
replace_placeholders_with_values linx-server.conf.src
sudo cp linx-server.conf "$LFSS_ROOT"/linx-server.conf

sudo chown www-date "$LFSS_ROOT"
sudo chown www-date "$LFSS_ROOT"/*
sudo chgrp www-date "$LFSS_ROOT"
sudo chgrp www-date "$LFSS_ROOT"/*

### 服务生成
cd "$SET_DIR"
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
cd "$SET_DIR"
prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"

