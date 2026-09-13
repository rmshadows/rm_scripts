#!/bin/bash
## 3x-ui 一键部署 / 更新
## 需要有人职守，需要 sudo
## https://github.com/MHSanaei/3x-ui
## 本脚本直接调用 3x-ui 官方 install.sh（每次运行从 GitHub 拉取最新），保证与上游仓库同步。
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名（3x-ui 官方服务名固定为 x-ui，勿改）
SRV_NAME=x-ui
# 安装版本：
#   留空        = 最新稳定版（推荐，始终与仓库同步）
#   v3.7.0      = 固定版本（可复现部署）
#   dev-latest  = 开发版
SET_XUI_VERSION=""
# 非交互模式：
#   1 = 自动生成随机账号/密码/端口/路径，写入 /etc/x-ui/install-result.env（推荐无人值守）
#   0 = 交互模式，安装后可手动设置
SET_XUI_NONINTERACTIVE=1
# Nginx 独立站反代（默认开启，单独监听端口，不占用 80/443）
SET_NGINX_PROXY=1
# Nginx 独立站监听端口（不要用 80/443，那是 acme.conf / ssl.conf）
SITE_LISTEN=2053
# 独立站标识：用于 nginx server_name 与 SSL 证书文件名。
# 留空 = 从 /etc/nginx/sites-available/ssl.conf 或 acme.conf 自动读取 server_name。
SITE_NAME=
# 面板监听 IP：设为 127.0.0.1 则面板仅本机可访问，对外走 Nginx（推荐）。
# 留空 = 保持官方默认（0.0.0.0，所有网卡可访问）。
# SET_PANEL_LISTEN_IP="127.0.0.1"
SET_PANEL_LISTEN_IP=""

# 保存当前目录（运行脚本时应在 3x-ui/ 下）
SET_DIR=$(pwd)

#### 正文
### 准备工作
# 检查依赖
for t_pkg in wget curl tar; do
    if ! command -v "$t_pkg" &>/dev/null; then
        prompt -x "安装依赖 $t_pkg"
        sudo apt update && sudo apt install -y "$t_pkg"
    fi
done

### 下载官方安装脚本（始终拉取最新，保证与仓库同步）
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/mhsanaei/3x-ui/main/install.sh"
INSTALL_SCRIPT="/tmp/3x-ui-install-$$.sh"
prompt -x "下载官方安装脚本（与仓库同步）..."
curl -fLs "$INSTALL_SCRIPT_URL" -o "$INSTALL_SCRIPT"
if [ ! -s "$INSTALL_SCRIPT" ]; then
    prompt -e "下载安装脚本失败，请检查网络或 GitHub 可达性"
    exit 1
fi

### 版本选择
if [ -n "$SET_XUI_VERSION" ]; then
    prompt -i "安装版本：$SET_XUI_VERSION"
    VERSION_ARG="$SET_XUI_VERSION"
else
    prompt -i "安装版本：最新稳定版"
    VERSION_ARG=""
fi

### 执行安装（官方脚本要求 root，使用 sudo）
prompt -x "开始安装 3x-ui..."
if [ "$SET_XUI_NONINTERACTIVE" = "1" ]; then
    prompt -i "非交互模式：自动生成随机账号密码"
    sudo XUI_NONINTERACTIVE=1 bash "$INSTALL_SCRIPT" $VERSION_ARG
else
    sudo bash "$INSTALL_SCRIPT" $VERSION_ARG
fi

if [ ! -f /usr/local/x-ui/x-ui ]; then
    prompt -e "安装失败：未找到 /usr/local/x-ui/x-ui"
    rm -f "$INSTALL_SCRIPT"
    exit 1
fi

### 读取面板实际监听端口与 webBasePath
XUI_INFO=$(sudo /usr/local/x-ui/x-ui setting -show true 2>/dev/null)
XUI_PORT=$(echo "$XUI_INFO" | grep -Eo 'port: .+' | awk '{print $2}')
XUI_WEB_BASE_PATH=$(echo "$XUI_INFO" | grep -Eo 'webBasePath: .+' | awk '{print $2}')

if [ -z "$XUI_PORT" ]; then
    prompt -w "未能读取面板端口，使用默认 2053"
    XUI_PORT=2053
fi
prompt -i "面板端口：$XUI_PORT  webBasePath：${XUI_WEB_BASE_PATH:-(空)}"

### 设置面板监听 IP（安全：仅本机可访问，对外走 Nginx）
if [ -n "$SET_PANEL_LISTEN_IP" ]; then
    XUI_LISTEN_IP=$(sudo /usr/local/x-ui/x-ui setting -getListen true 2>/dev/null | grep -Eo 'listenIP: .+' | awk '{print $2}')
    if [ "$XUI_LISTEN_IP" != "$SET_PANEL_LISTEN_IP" ]; then
        prompt -x "设置面板监听 IP 为 $SET_PANEL_LISTEN_IP ..."
        sudo /usr/local/x-ui/x-ui setting -listen "$SET_PANEL_LISTEN_IP" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            prompt -s "面板监听 IP 已设为 $SET_PANEL_LISTEN_IP"
        else
            prompt -w "设置监听 IP 失败，请在面板 Web 设置中手动修改"
        fi
    else
        prompt -i "面板监听 IP 已是 $SET_PANEL_LISTEN_IP，跳过"
    fi
fi

### 重启面板使监听 IP 生效
prompt -x "重启 x-ui 服务..."
sudo systemctl restart x-ui

### 显示安装结果（非交互模式）
if [ "$SET_XUI_NONINTERACTIVE" = "1" ] && [ -f /etc/x-ui/install-result.env ]; then
    prompt -s "安装完成，登录信息（来自 /etc/x-ui/install-result.env）："
    sudo cat /etc/x-ui/install-result.env
    prompt -w "请妥善保管以上信息，文件权限 600"
fi

### 服务状态
sudo systemctl status x-ui --no-pager -l 2>/dev/null | head -15

### Nginx 独立站反代
cd "$SET_DIR"
if [ "$SET_NGINX_PROXY" = "1" ] && [ -d /etc/nginx ] && command -v nginx >/dev/null 2>&1; then
    if [ -f setupNginxForXui.sh ]; then
        prompt -x "运行 setupNginxForXui.sh（写入 /etc/nginx/sites-available/xui.conf，不启用）"
        export RUN_PORT="$XUI_PORT" SITE_LISTEN SITE_NAME HOME
        bash setupNginxForXui.sh
        prompt -i "启用独立站： sudo ngx-site"
        prompt -i "访问： https://<域名>:${SITE_LISTEN}/${XUI_WEB_BASE_PATH}/"
    else
        prompt -w "未找到 setupNginxForXui.sh，跳过 Nginx 配置"
    fi
elif [ "$SET_NGINX_PROXY" = "1" ]; then
    prompt -w "未检测到 nginx，面板仍监听 ${SET_PANEL_LISTEN_IP:-0.0.0.0}:${XUI_PORT}"
    prompt -i "直接访问： http://<主机>:${XUI_PORT}/${XUI_WEB_BASE_PATH}/"
fi

# 清理临时文件
rm -f "$INSTALL_SCRIPT"

prompt -s "3x-ui 部署完成"
prompt -i "管理命令： x-ui"
prompt -i "查看日志： x-ui log"
prompt -i "更新版本： 重跑本脚本（SET_XUI_VERSION 留空即拉最新）"
