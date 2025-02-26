#!/bin/bash
# 安装go
# https://go.dev/doc/install
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# golang的压缩包https://go.dev/dl/
golangtar="https://go.dev/dl/go1.24.0.linux-amd64.tar.gz"

# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="wget"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install $t_pkg  # 更新包列表并安装
fi

### 安装软件
wget -c "$golangtar" -O golang.tar.gz
sudo tar -C /usr/local -xzf golang.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version


