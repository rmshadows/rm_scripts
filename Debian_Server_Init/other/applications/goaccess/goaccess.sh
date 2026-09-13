#!/bin/bash
## GoAccess 多站点日志报告（https://goaccess.io/）
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=goaccess
# 配置/报告目录
GOACCESS_DIR="$HOME/Applications/goaccess"
# 是否配置 nginx 子路径（主站 /goaccess/ 提供报告目录浏览）
SET_NGINX_SNIPPET=1
# 报告页面访问用户名（留空=默认 goaccess）
GOACCESS_USER=""
# 报告页面访问密码（留空=自动生成 16 位随机字母数字）
GOACCESS_PASS=""

# 保存当前目录（运行脚本时应在 goaccess/ 下）
SET_DIR=$(pwd)

#### 正文
### 安装 goaccess
if command -v goaccess >/dev/null 2>&1; then
  prompt -i "goaccess 已安装"
else
  prompt -x "安装 goaccess"
  sudo apt update
  sudo apt install -y goaccess
fi

### 准备目录
mkdir -p "$GOACCESS_DIR/reports" "$GOACCESS_DIR/pids"

### 生成配置（覆盖式）
cd "$SET_DIR"
replace_placeholders_with_values goaccess.conf.src
cp goaccess.conf "$GOACCESS_DIR/goaccess.conf"

replace_placeholders_with_values sites.conf.src
# 不覆盖用户已有的 sites.conf
if [ ! -f "$GOACCESS_DIR/sites.conf" ]; then
  cp sites.conf "$GOACCESS_DIR/sites.conf"
  prompt -i "已生成 sites.conf，按需增删站点"
else
  prompt -i "sites.conf 已存在，保留不动（如需重置请手动删除后重跑）"
fi

### 服务生成（始终重跑，覆盖式）
mkdir -p "$HOME/Services/$SRV_NAME"
cd "$SET_DIR"
prompt -x "生成服务..."
replace_placeholders_with_values srv.service.src
sudo cp srv.service "$HOME/Services/$SRV_NAME.service"
prompt -x "安装服务..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"
prompt -x "生成 start/stop 脚本..."
replace_placeholders_with_values start.sh.src
replace_placeholders_with_values stop.sh.src
sudo cp start.sh "$HOME/Services/$SRV_NAME/start_${SRV_NAME}.sh"
sudo cp stop.sh "$HOME/Services/$SRV_NAME/stop_${SRV_NAME}.sh"
sudo chmod +x "$HOME/Services/$SRV_NAME/"*.sh

### Nginx 子路径 + 密码保护（始终重跑，覆盖式）
if [ "$SET_NGINX_SNIPPET" = "1" ] && [ -d /etc/nginx ] && command -v nginx >/dev/null 2>&1; then
  # 生成随机凭证（留空时）
  [ -z "$GOACCESS_USER" ] && GOACCESS_USER="goaccess"
  if [ -z "$GOACCESS_PASS" ]; then
    GOACCESS_PASS=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)
    prompt -i "自动生成 GoAccess 访问密码: $GOACCESS_PASS"
  fi
  # 创建 htpasswd 文件（用 openssl passwd -apr1，无需 apache2-utils）
  HTPASSWD_FILE="/etc/nginx/.htpasswd_goaccess"
  HASH=$(openssl passwd -apr1 "$GOACCESS_PASS")
  echo "${GOACCESS_USER}:${HASH}" | sudo tee "$HTPASSWD_FILE" >/dev/null
  sudo chmod 640 "$HTPASSWD_FILE"
  # 凭证存到配置目录，方便用户查看
  printf '用户名: %s\n密码: %s\n' "$GOACCESS_USER" "$GOACCESS_PASS" > "$GOACCESS_DIR/credentials.txt"
  chmod 600 "$GOACCESS_DIR/credentials.txt"
  prompt -i "凭证已保存: $GOACCESS_DIR/credentials.txt（权限 600）"

  if [ -f setupNginxForGoaccess.sh ]; then
    prompt -x "运行 setupNginxForGoaccess.sh"
    export HOME
    bash setupNginxForGoaccess.sh
  fi
else
  prompt -w "未检测到 nginx，跳过 nginx 配置"
fi

echo
prompt -s "GoAccess 安装完成"
echo "  配置目录: $GOACCESS_DIR"
echo "  站点清单: $GOACCESS_DIR/sites.conf（改完 sudo systemctl restart goaccess）"
echo "  报告目录: $GOACCESS_DIR/reports"
echo "  启动:     sudo systemctl enable --now goaccess"
echo "  日志:     journalctl -u goaccess -f"
if [ "$SET_NGINX_SNIPPET" = "1" ]; then
  echo "  访问:     https://<域名>/goaccess/（需在主站 server { } 内 include snippets/goaccess.conf）"
  echo "  账号:     $GOACCESS_USER / $GOACCESS_PASS（也见 $GOACCESS_DIR/credentials.txt）"
fi
