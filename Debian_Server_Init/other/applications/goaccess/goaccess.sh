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
# 报告界面语言（GoAccess 靠 LANG 选内置翻译）：zh_CN.UTF-8=中文（默认），C=英文
GOACCESS_LANG="zh_CN.UTF-8"

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

### 生成界面语言所需 locale（幂等：只认 locale -a 实际结果，不看 locale.gen 注释）
if [ -n "$GOACCESS_LANG" ] && [ "$GOACCESS_LANG" != "C" ] && [ "$GOACCESS_LANG" != "POSIX" ]; then
  # zh_CN.UTF-8 在 locale -a 里显示为 zh_CN.utf8（编码小写且无连字符）
  lang_short="${GOACCESS_LANG%%.*}"
  lang_enc_lc="$(echo "${GOACCESS_LANG#*.}" | tr '[:upper:]' '[:lower:]' | tr -d '-')"
  if locale -a 2>/dev/null | grep -qi "^${lang_short}\.${lang_enc_lc}$"; then
    prompt -i "locale $GOACCESS_LANG 已生成"
  else
    prompt -x "生成 $GOACCESS_LANG locale（GoAccess 界面语言）"
    sudo apt install -y locales
    # locale.gen 里的行形如「# zh_CN.UTF-8 UTF-8」，取消注释
    sudo sed -i "s/^# *${GOACCESS_LANG} ${GOACCESS_LANG#*.}/${GOACCESS_LANG} ${GOACCESS_LANG#*.}/" /etc/locale.gen
    sudo locale-gen "$GOACCESS_LANG"
    if ! locale -a 2>/dev/null | grep -qi "^${lang_short}\.${lang_enc_lc}$"; then
      prompt -w "locale $GOACCESS_LANG 生成失败，报告将回退英文"
      GOACCESS_LANG="C"
    fi
  fi
fi

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

# 校验：成对占位符【...】必须已全部替换，残留则服务必然起不来，直接中止（fail-fast）
# 用成对括号特征，避免误匹配 start/stop 自检代码里的单个【
for f in "$HOME/Services/$SRV_NAME.service" \
         "$HOME/Services/$SRV_NAME/start_${SRV_NAME}.sh" \
         "$HOME/Services/$SRV_NAME/stop_${SRV_NAME}.sh"; do
  if sudo grep -qP '【.*】' "$f"; then
    prompt -e "占位符未替换，已中止安装：$f"
    prompt -e "请检查上方「变量未设置」警告，确认相关变量非空后重新运行"
    exit 1
  fi
done

### Nginx 子路径 + 密码保护（始终重跑，覆盖式）
if [ "$SET_NGINX_SNIPPET" = "1" ] && [ -d /etc/nginx ] && { [ -x /usr/sbin/nginx ] || command -v nginx >/dev/null 2>&1; }; then
  # 生成凭证：GOACCESS_PASS 留空时，优先复用旧密码（幂等），否则随机生成
  [ -z "$GOACCESS_USER" ] && GOACCESS_USER="goaccess"
  if [ -z "$GOACCESS_PASS" ] && [ -f "$GOACCESS_DIR/credentials.txt" ]; then
    GOACCESS_PASS=$(sed -n 's/^密码: //p' "$GOACCESS_DIR/credentials.txt" | head -1)
    [ -n "$GOACCESS_PASS" ] && prompt -i "复用已有 GoAccess 访问密码（见 credentials.txt）"
  fi
  if [ -z "$GOACCESS_PASS" ]; then
    GOACCESS_PASS=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)
    prompt -i "自动生成 GoAccess 访问密码: $GOACCESS_PASS"
  fi
  # 创建 htpasswd 文件（用 openssl passwd -apr1，无需 apache2-utils）
  # nginx worker 以 www-data 运行，必须让它可读：root:www-data + 640
  HTPASSWD_FILE="/etc/nginx/.htpasswd_goaccess"
  HASH=$(openssl passwd -apr1 "$GOACCESS_PASS")
  echo "${GOACCESS_USER}:${HASH}" | sudo tee "$HTPASSWD_FILE" >/dev/null
  sudo chown root:www-data "$HTPASSWD_FILE"
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
echo "  报错日志: $GOACCESS_DIR/goaccess.log（仅报告生成失败时写入）"
if [ "$SET_NGINX_SNIPPET" = "1" ]; then
  echo "  访问:     https://<域名>/goaccess/（需在主站 server { } 内 include snippets/goaccess.conf）"
  echo "  账号:     $GOACCESS_USER / $GOACCESS_PASS（也见 $GOACCESS_DIR/credentials.txt）"
fi
