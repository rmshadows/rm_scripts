#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

# https://webmin.com/download/
#### CONF
# 服务名
SRV_NAME=webmin
# Webmin 本机端口（默认 10000）
NEW_PORT=20001
# 新的语言
NEW_LANG="zh"
# 有 nginx 时写入独立站 sites-available/webmin.conf（默认不启用）。设 0 则只改端口/语言。
SET_NGINX_PROXY=1
# 独立站监听端口（不要用 80/443）
SITE_LISTEN=2053
# 独立站标识：用于生成 nginx 站点配置的 server_name，以及 SSL 证书文件名。
# 留空 = 从 ssl.conf / acme.conf 自动读取 server_name。
SITE_NAME=

# 保存当前目录
SET_DIR=$(pwd)

#### 正文
WEBMIN_CONFIG_FILE="/etc/webmin/config"
MINISERV_CONFIG_FILE="/etc/webmin/miniserv.conf"

set_webmin_kv() {
  local file="$1"
  local key="$2"
  local value="$3"
  if sudo grep -q "^${key}=" "$file"; then
    sudo sed -i "s|^${key}=.*$|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" | sudo tee -a "$file" >/dev/null
  fi
}

### 安装 Webmin（仅未安装时执行）
if [ ! -d /etc/webmin ]; then
  echo -e "\033[32mWebmin 未安装，开始安装...\033[0m"
  curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
  sudo sh webmin-setup-repo.sh
  sudo apt update
  sudo apt-get install webmin --install-recommends
  if [ ! -d /etc/webmin ]; then
    prompt -e "找不到 /etc/webmin，似乎安装失败"
    exit 1
  fi
else
  echo -e "\033[33mWebmin 已安装，仅修改端口/语言/反代配置。\033[0m"
fi

### 修改端口与语言
if [ -z "$NEW_PORT" ]; then
  echo "端口未提供，跳过端口设置。"
else
  echo "修改 Webmin 端口为 $NEW_PORT ..."
  set_webmin_kv "$MINISERV_CONFIG_FILE" port "$NEW_PORT"
  set_webmin_kv "$MINISERV_CONFIG_FILE" listen "$NEW_PORT"
fi

if [ -z "$NEW_LANG" ]; then
  echo "语言未提供，跳过语言设置。"
else
  echo "修改 Webmin 语言为 $NEW_LANG ..."
  set_webmin_kv "$WEBMIN_CONFIG_FILE" lang_root "$NEW_LANG"
fi

### 有 nginx 时只听本机，对外走独立站
USE_NGINX_PROXY=0
if [ "$SET_NGINX_PROXY" = "1" ] && [ -d /etc/nginx ] && command -v nginx >/dev/null 2>&1; then
  USE_NGINX_PROXY=1
fi

if [ "$USE_NGINX_PROXY" = "1" ]; then
  echo "Webmin 只听 127.0.0.1:$NEW_PORT，对外用独立 Nginx 站"
  set_webmin_kv "$MINISERV_CONFIG_FILE" bind "127.0.0.1"
  set_webmin_kv "$MINISERV_CONFIG_FILE" ipv6 "0"
  if [ -z "$SITE_NAME" ]; then
    SITE_NAME="$(guess_nginx_site_name || true)"
  fi
  if [ -n "$SITE_NAME" ]; then
    echo "Webmin 可信推荐人：$SITE_NAME $SITE_NAME:$SITE_LISTEN"
    set_webmin_kv "$WEBMIN_CONFIG_FILE" referers "$SITE_NAME $SITE_NAME:$SITE_LISTEN"
    set_webmin_kv "$WEBMIN_CONFIG_FILE" relative_redir "1"
  else
    prompt -w "SITE_NAME 未确定，跳过 referers。请在 CONF 里填写后重跑。"
  fi
fi

echo "重启 Webmin 服务 ..."
sudo systemctl restart webmin

echo "Webmin 配置已更新："
echo "端口: $NEW_PORT"
echo "语言: $NEW_LANG"

### Nginx 独立站（始终重跑，覆盖式）
cd "$SET_DIR"
if [ "$USE_NGINX_PROXY" = "1" ] && [ -f setupNginxForWebmin.sh ]; then
  prompt -x "运行 setupNginxForWebmin.sh（写入 /etc/nginx/sites-available/webmin.conf，不启用）"
  export NEW_PORT SITE_LISTEN SITE_NAME HOME
  bash setupNginxForWebmin.sh
  prompt -i "启用独立站： sudo ngx-site"
elif [ "$SET_NGINX_PROXY" = "1" ]; then
  prompt -w "未检测到 nginx，Webmin 仍听 0.0.0.0:$NEW_PORT。"
  prompt -i "访问：https://<主机>:${NEW_PORT}/"
fi
