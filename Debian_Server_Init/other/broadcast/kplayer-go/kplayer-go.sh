#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

#### CONF
#### 配置部分
# 服务名 将生成kplayer-1、kplayer-2、kplayer-3以此类推
# 服务名前缀
SRV_NAME=kplayer
INSTALL_DIR="$HOME/Applications/broadcast" 

# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"
t_pkg="nano"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"  # 输出红色提示
    sudo apt update && sudo apt install $t_pkg  # 更新包列表并安装
fi

#### 正文
# 首先检查目前已经安装了几个kplayer服务
# 确保安装目录存在
mkdir -p "$INSTALL_DIR"

# 获取已有 kplayer 服务数量
existing_count=$(ls "$INSTALL_DIR" | grep -E "^${SRV_NAME}-[0-9]+$" | awk -F '-' '{print $2}' | sort -n | tail -n 1)

# 显示当前已安装的服务数量
if [[ -z "$existing_count" ]]; then
    echo "当前没有已安装的 ${SRV_NAME} 服务。"
    new_srv_number=1
else
    echo "当前已安装 $existing_count 个 ${SRV_NAME} 服务。"
    new_srv_number=$((existing_count + 1))
fi

# 询问用户是否安装新的服务
read -p "是否安装新的 ${SRV_NAME}-${new_srv_number}？(y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # 确定新服务名称
    new_srv_name="${SRV_NAME}-${new_srv_number}"
    new_srv_path="$INSTALL_DIR/$new_srv_name"
    # 创建新的服务目录
    mkdir -p "$new_srv_path"
    echo "✅ 已创建新服务: $new_srv_name"
    echo "📂 安装路径: $new_srv_path"
    # 跳到后面安装软件
else
    echo "❌ 取消安装，退出脚本。"
    exit 0
fi

### 安装软件
sudo cp kplayer_sample/* "$new_srv_path"/
cd $new_srv_path
replace_placeholders_with_values removeServices.sh
# 回到配置目录
cd "$SET_DIR"
replace_placeholders_with_values srv.service.src
sudo mv srv.service /lib/systemd/system/{$new_srv_name}.service
sudo systemctl daemon-reload

