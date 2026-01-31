#!/bin/bash
## 需要有人职守，需要sudo(但是脚本请不要用sudo)
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

# 保存当前目录（运行脚本时应在 frp/ 下）
SET_DIR=$(pwd)

#### CONF
# 服务名(一个服务端一个客户端)
SRV_NAME_A=frp-client
SRV_NAME_B=frp-server

# 未使用的参数
REVERSE_PROXY_PORT=2053
RUN_PORT=7500
# nginx 片段中管理页面的路径（如 /frp/），用户 include 后通过该路径访问
REVERSE_PROXY_URL="/frp/"
SRV_NAME=${SRV_NAME_B}

# Docs: https://github.com/fatedier/frp/blob/dev/README_zh.md
# https://gofrp.org/zh-cn/
# https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_linux_arm64.tar.gz
FRP_DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_linux_amd64.tar.gz"
# 本地压缩包（tar.gz）注意：需要将上面设置为空
LOCAL_FRP_TAR=frp_0.61.1_linux_amd64.tar.gz

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="wget"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

### 安装软件
mkdir -p "$HOME/Applications"

# 安装
cd "$HOME/Applications"

if [ -n "$FRP_DOWNLOAD_URL" ]; then
    # 非空
    # 检查是否已下载 frp.tar.gz
    if ! [ -f "frp.tar.gz" ]; then
        prompt -x "Downloading frp...."
        wget -c "$FRP_DOWNLOAD_URL" -O frp.tar.gz
        if ! [ -f "frp.tar.gz" ]; then
            prompt -x "Wget seems error. Stopping ..."
            exit 1
        fi
    else
        prompt -x "frp.tar.gz already exists."
    fi
else
    if [ -n "$LOCAL_FRP_TAR" ] && [ -f "$LOCAL_FRP_TAR" ]; then
        # 直接使用本地压缩包
        prompt -x "Move $LOCAL_FRP_TAR to $(pwd)..."
        mv "$LOCAL_FRP_TAR" ./frp.tar.gz
    else
        prompt -e "未指定本地 frp 压缩包或文件不存在（LOCAL_FRP_TAR）"
        exit 1
    fi
fi

FRP_DIR="frp"
if [ -d "$FRP_DIR" ]; then
    prompt -x "Directory $FRP_DIR already exists. Creating backup..."
    mv "$FRP_DIR" "${FRP_DIR}_bak_$(date +%Y%m%d%H%M%S)"  # 使用时间戳创建备份
    prompt -x "Backup created: ${FRP_DIR}_bak_$(date +%Y%m%d%H%M%S)"
fi

prompt -x "Unzip frp...."
# 解压
tar xzvf frp.tar.gz
prompt -x "Rename...."
# 重命名文件夹 (如果是arm记得修改)
mv frp*amd64 frp
cd frp
mkdir -p archive
mv frpc.toml archive
mv frps.toml archive
# 请手动删除
# rm frp.tar.gz
cd "$SET_DIR"

# 拷贝配置文件
prompt -x "Set up server and client sample..."
# replace_placeholders_with_values frpc_conf/frpc.toml.src
cp -r ./frpc-conf "$HOME/Applications/frp/frpc-conf"
replace_placeholders_with_values frps_conf/frps.toml.src
cp -r ./frps-conf "$HOME/Applications/frp/frps-conf"

### 服务生成
# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME_A" ]; then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME_A..."
    sudo mkdir -p "$HOME/Services/$SRV_NAME_A"
else
    prompt -x "$HOME/Services/$SRV_NAME_A already exists."
fi
if ! [ -d "$HOME/Services/$SRV_NAME_B" ]; then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME_B..."
    sudo mkdir -p "$HOME/Services/$SRV_NAME_B"
else
    prompt -x "$HOME/Services/$SRV_NAME_B already exists."
fi

# 检查服务是否已安装，询问是否重新安装
if [ -f "$HOME/Services/$SRV_NAME_A/$SRV_NAME_A.service" ]; then
    prompt -y "Service $SRV_NAME_A already exists. Do you want to reinstall? (y/n)"
    if [ "$REPLY" == "y" ]; then
        mv "$HOME/Services/$SRV_NAME_A/$SRV_NAME_A.service" "$HOME/Services/$SRV_NAME_A/$SRV_NAME_A.service.bak"
        prompt -x "Backup existing $SRV_NAME_A service file."
    fi
fi

if [ -f "$HOME/Services/$SRV_NAME_B/$SRV_NAME_B.service" ]; then
    prompt -y "Service $SRV_NAME_B already exists. Do you want to reinstall? (y/n)"
    if [ "$REPLY" == "y" ]; then
        mv "$HOME/Services/$SRV_NAME_B/$SRV_NAME_B.service" "$HOME/Services/$SRV_NAME_B/$SRV_NAME_B.service.bak"
        prompt -x "Backup existing $SRV_NAME_B service file."
    fi
fi

# 生成服务
prompt -x "Making Service..."
replace_placeholders_with_values frp-client.service.src
sudo mv frp-client.service "$HOME/Services/$SRV_NAME_A.service"
replace_placeholders_with_values frp-server.service.src
sudo mv frp-server.service "$HOME/Services/$SRV_NAME_B.service"

# 安装服务
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"

# 拷贝启动和停止的脚本
prompt -x "Make start and stop script..."
replace_placeholders_with_values start_client.sh
replace_placeholders_with_values start_server.sh
sudo cp start_client.sh "$HOME/Services/$SRV_NAME_A/start_${SRV_NAME_A}.sh"
sudo cp start_server.sh "$HOME/Services/$SRV_NAME_B/start_${SRV_NAME_B}.sh"
sudo chmod +x "$HOME/Services/$SRV_NAME_A"/*.sh
sudo chmod +x "$HOME/Services/$SRV_NAME_B"/*.sh

### Nginx 配置（与 fmgr 一致：配置写入 nginx 目录，不覆盖原机 site）
cd "$SET_DIR"
if [ -f setupNginxForFrp.sh ]; then
    prompt -x "运行 setupNginxForFrp.sh（写入 /etc/nginx/snippets/frp.conf）"
    export RUN_PORT REVERSE_PROXY_URL
    bash setupNginxForFrp.sh
else
    prompt -w "未找到 setupNginxForFrp.sh，请手动运行以写入 nginx 片段。"
fi

replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "完整 server 示例（仅供参考，勿直接覆盖原机）："
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
prompt -i "若使用片段方式，只需在自己的 site 里加一行： include /etc/nginx/snippets/frp.conf;"

