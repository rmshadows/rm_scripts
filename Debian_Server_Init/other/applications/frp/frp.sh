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

# Nginx 部署模式：
#   子路径反代：REVERSE_PROXY_PATH 设为 "/frp/"，在主站 include snippets/frp.conf
#   独立站点：  REVERSE_PROXY_PATH 设为空 ""，生成 sites-available/frp.conf（独立端口监听）
REVERSE_PROXY_PATH="/frp/"
# 独立站点模式用（REVERSE_PROXY_PATH 为空时生效）：
SITE_LISTEN=7501          # 独立站点监听端口
SITE_NAME=""              # 独立站点域名（留空则从 ssl.conf 自动猜测）
SRV_NAME=${SRV_NAME_B}

# Docs: https://github.com/fatedier/frp/blob/dev/README_zh.md
# https://gofrp.org/zh-cn/
#
# 版本与架构配置：
#   FRP_VERSION  - 版本号（不含 v 前缀），如 "0.61.1"；设为 "latest" 则自动获取 GitHub 最新 release。
#   FRP_ARCH     - 架构，留空自动检测（amd64 / arm64 / arm）。
#   下载 URL 由脚本自动拼接，无需手动填写。
FRP_VERSION="0.61.1"
FRP_ARCH=""
# 本地压缩包（tar.gz）。设为空则从网络下载；指定本地文件则直接使用。
LOCAL_FRP_TAR=""

# ---- frps 服务端配置 ----
# frp 客户端连接服务端的端口
FRPS_BIND_PORT=7000
# 鉴权 token，留空自动生成随机字符串（32 位字母数字）
FRPS_AUTH_TOKEN=""
# Dashboard（Web 管理面板）端口
FRPS_WEB_PORT=7500
# Dashboard 用户名
FRPS_WEB_USER="admin"
# Dashboard 密码，留空自动生成随机字符串
FRPS_WEB_PASSWORD=""
# 允许客户端映射的端口范围（frps.toml allowPorts）
FRPS_ALLOW_PORTS='{ single = 5000 }, { start = 2000, end = 3000 }'
# nginx 反代 dashboard 的后端端口，自动跟随 FRPS_WEB_PORT
RUN_PORT="$FRPS_WEB_PORT"

# ---- frpc 客户端配置（生成本地 frpc.toml 供本机使用）----
# 客户端连接的服务端地址，留空自动取本机公网 IP
FRPC_SERVER_ADDR=""
# 客户端连接的服务端端口（须与 FRPS_BIND_PORT 一致）
FRPC_SERVER_PORT=7000
# 本地代理示例：把本机 80 端口映射到服务端 6000
FRPC_PROXY_NAME="web"
FRPC_PROXY_TYPE="tcp"
FRPC_LOCAL_IP="127.0.0.1"
FRPC_LOCAL_PORT=80
FRPC_REMOTE_PORT=6000

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="wget"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

### 安装软件
# 检测最终产物：frp 二进制已存在则跳过下载
if [ -f "$HOME/Applications/frp/frps" ] && [ -f "$HOME/Applications/frp/frpc" ]; then
  prompt -i "[跳过] frp 已下载解压"
else
mkdir -p "$HOME/Applications"

# ---- 解析版本与架构 ----
# 架构自动检测（FRP_ARCH 留空时）
if [ -z "$FRP_ARCH" ]; then
    case "$(uname -m)" in
        x86_64)  FRP_ARCH="amd64" ;;
        aarch64) FRP_ARCH="arm64" ;;
        armv7l)  FRP_ARCH="arm"   ;;
        *)
            prompt -e "无法识别的架构 $(uname -m)，请手动设置 FRP_ARCH"
            exit 1
            ;;
    esac
fi
# latest 时从 GitHub API 取最新版本号
if [ "$FRP_VERSION" = "latest" ]; then
    prompt -x "获取 frp 最新版本..."
    FRP_VERSION=$(curl -fsSL "https://api.github.com/repos/fatedier/frp/releases/latest" | grep -oP '"tag_name":\s*"v\K[^"]+' | head -1)
    if [ -z "$FRP_VERSION" ]; then
        prompt -e "获取最新版本失败，请手动指定 FRP_VERSION"
        exit 1
    fi
    prompt -i "最新版本: v$FRP_VERSION"
fi
# 拼接下载 URL
FRP_DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz"
prompt -i "frp v${FRP_VERSION} (${FRP_ARCH}) -> $FRP_DOWNLOAD_URL"

# 安装
cd "$HOME/Applications"

if [ -n "$LOCAL_FRP_TAR" ] && [ -f "$LOCAL_FRP_TAR" ]; then
    # 使用本地压缩包
    prompt -x "使用本地压缩包 $LOCAL_FRP_TAR"
    cp "$LOCAL_FRP_TAR" ./frp.tar.gz
elif [ -n "$FRP_DOWNLOAD_URL" ]; then
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
    prompt -e "未指定本地 frp 压缩包且无下载地址"
    exit 1
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
# 重命名文件夹（按架构通配，兼容本地包版本与 FRP_VERSION 不一致的情况）
mv frp*_linux_${FRP_ARCH} frp
cd frp
mkdir -p archive
mv frpc.toml archive
mv frps.toml archive
# 请手动删除
# rm frp.tar.gz
cd "$SET_DIR"
fi

# ---- 自动生成随机密钥 / 检测公网 IP ----
# token：留空则生成 32 位随机字母数字（YAML/TOML 安全，不含特殊字符）
if [ -z "$FRPS_AUTH_TOKEN" ]; then
  FRPS_AUTH_TOKEN=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
  prompt -i "自动生成 frps auth.token: $FRPS_AUTH_TOKEN"
fi
# dashboard 密码：留空则生成 16 位随机
if [ -z "$FRPS_WEB_PASSWORD" ]; then
  FRPS_WEB_PASSWORD=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)
  prompt -i "自动生成 frps webServer.password: $FRPS_WEB_PASSWORD"
fi
# 客户端服务端地址：留空则取本机公网 IP
if [ -z "$FRPC_SERVER_ADDR" ]; then
  FRPC_SERVER_ADDR=$(curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null || curl -fsSL --max-time 5 https://ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
  prompt -i "自动检测公网 IP: $FRPC_SERVER_ADDR"
fi

# 拷贝配置文件（始终覆盖）
prompt -x "Set up server and client conf..."
replace_placeholders_with_values frps-conf/frps.toml.src
replace_placeholders_with_values frpc-conf/frpc.toml.src
replace_placeholders_with_values frpc-conf/frpc.toml.sample.src
cp -rf ./frps-conf "$HOME/Applications/frp/frps-conf"
cp -rf ./frpc-conf "$HOME/Applications/frp/frpc-conf"

# 输出连接信息
echo ""
prompt -s "===== frp 部署信息 ====="
prompt -i "服务端端口 (bindPort): $FRPS_BIND_PORT"
prompt -i "鉴权 token (auth.token): $FRPS_AUTH_TOKEN"
prompt -i "Dashboard: http://$FRPC_SERVER_ADDR:$FRPS_WEB_PORT  (user=$FRPS_WEB_USER, pass=$FRPS_WEB_PASSWORD)"
prompt -i "客户端示例配置已生成: $HOME/Applications/frp/frpc-conf/frpc.toml.sample"
prompt -s "========================"

### 服务生成（始终重跑，覆盖式）
sudo mkdir -p "$HOME/Services/$SRV_NAME_A" "$HOME/Services/$SRV_NAME_B"

# 生成服务
prompt -x "Making Service..."
replace_placeholders_with_values frp-client.service.src
sudo cp frp-client.service "$HOME/Services/$SRV_NAME_A.service"
replace_placeholders_with_values frp-server.service.src
sudo cp frp-server.service "$HOME/Services/$SRV_NAME_B.service"

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

### Nginx 配置（始终重跑，覆盖式）
cd "$SET_DIR"
if [ -f setupNginxForFrp.sh ]; then
    if [ -n "$REVERSE_PROXY_PATH" ]; then
        prompt -x "运行 setupNginxForFrp.sh（子路径反代模式：$REVERSE_PROXY_PATH -> 127.0.0.1:$RUN_PORT）"
    else
        prompt -x "运行 setupNginxForFrp.sh（独立站点模式：监听 $SITE_LISTEN -> 127.0.0.1:$RUN_PORT）"
    fi
    export RUN_PORT REVERSE_PROXY_PATH SITE_LISTEN SITE_NAME
    bash setupNginxForFrp.sh
else
    prompt -w "未找到 setupNginxForFrp.sh。"
fi

