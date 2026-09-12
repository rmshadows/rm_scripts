#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=matterbridge
# 媒体域名 Include https:// no end : /
DOMAIN_MEDIA="https://yourdomain"

# 保存当前目录（运行脚本时应在 matterbridge/ 下）
SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

#### 正文
### 安装软件
mkdir -p "$HOME/Applications/matterbridge" "$HOME/Logs/matterbridge"

# 二进制已存在则跳过下载
if [ -f "$HOME/Applications/matterbridge/matterbridge-linux" ]; then
  prompt -i "[跳过] matterbridge 二进制已存在"
else
  wget -O matterbridge-linux https://github.com/42wim/matterbridge/releases/download/v1.26.0/matterbridge-1.26.0-linux-64bit
  if [ ! -f matterbridge-linux ]; then
      prompt -e "下载失败，请检查网络或 GitHub release 地址是否变更。"
      exit 1
  fi
  chmod +x matterbridge-linux
  mv matterbridge-linux "$HOME/Applications/matterbridge/"
fi
# 配置文件：始终覆盖
replace_placeholders_with_values matterbridge.toml.src
sudo cp matterbridge.toml "$HOME/Applications/matterbridge/matterbridge.toml"

### 服务生成（始终重跑，覆盖式）
sudo mkdir -p "$HOME/Services/$SRV_NAME"
cd "$SET_DIR"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo cp srv.service "$HOME/Services/$SRV_NAME.service"
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"
prompt -x "Make start and stop script..."
replace_placeholders_with_values start.sh.src
sudo cp start.sh "$HOME/Services/$SRV_NAME/start_${SRV_NAME}.sh"
sudo chmod +x "$HOME/Services/$SRV_NAME"/*.sh

### 反向代理配置（始终生成）
cd "$SET_DIR"
prompt -i "Check manually and set up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"

