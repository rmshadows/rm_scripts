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
# 修改端口号和语言 获取新的端口 默认１００００
NEW_PORT=20001
# 新的语言
NEW_LANG="zh"

# 保存当前目录
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
# 目标配置文件路径（安装后才有）
WEBMIN_CONFIG_FILE="/etc/webmin/config"
MINISERV_CONFIG_FILE="/etc/webmin/miniserv.conf"

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
  echo -e "\033[33mWebmin 已安装，仅修改端口/语言配置。\033[0m"
fi

### 修改端口与语言

# 检查是否提供了端口和语言
if [ -z "$NEW_PORT" ]; then
  echo "端口未提供，跳过端口设置。"
else
  # 修改 Webmin 配置中的端口
  echo "修改 Webmin 端口为 $NEW_PORT ..."
  sed -i "s/^port=.*$/port=$NEW_PORT/" "$MINISERV_CONFIG_FILE"
  # 如果配置文件中没有 `port`，手动添加
  grep -q "^port=" "$MINISERV_CONFIG_FILE" || echo "port=$NEW_PORT" | sudo tee -a "$MINISERV_CONFIG_FILE"
fi

if [ -z "$NEW_LANG" ]; then
  echo "语言未提供，跳过语言设置。"
else
  # 修改 Webmin 配置中的语言
  echo "修改 Webmin 语言为 $NEW_LANG ..."
  sed -i "s/^lang_root=.*$/lang_root=$NEW_LANG/" "$WEBMIN_CONFIG_FILE"
  # 如果配置文件中没有 `lang_root`，手动添加
  grep -q "^lang_root=" "$WEBMIN_CONFIG_FILE" || echo "lang_root=$NEW_LANG" | sudo tee -a "$WEBMIN_CONFIG_FILE"
fi

# 重启 Webmin 服务使改动生效
echo "重启 Webmin 服务 ..."
sudo systemctl restart webmin

# 输出修改后的配置
echo "Webmin 配置已更新："
echo "端口: $NEW_PORT"
echo "语言: $NEW_LANG"

### 反向代理配置
cd "$SET_DIR"
prompt -i "Check manually and set up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
