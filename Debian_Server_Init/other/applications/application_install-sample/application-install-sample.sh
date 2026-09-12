#!/bin/bash
## 需要有人职守，需要 sudo
## 本目录为「应用安装」模板：复制整目录并重命名为你的应用后，将 CONF 与 myapp 相关命名改为实际服务名，再按需填写安装逻辑。
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名（复制模板后改为实际服务名，并同步改 myapp.conf.src、setupNginxForMyapp.sh 中的 myapp）
SRV_NAME=myapp
# 指定运行端口
RUN_PORT=1200
# Nginx 独立站端口（不要用 80/443）
SITE_LISTEN=1213
# 独立站标识：用于生成 nginx 站点配置的 server_name，以及 SSL 证书文件名。
# 留空 = 不生成独立站点，仅做子路径反代。
SITE_NAME=

# 保存当前目录（运行脚本时应在本应用目录下）
SET_DIR=$(pwd)

#### 正文
### 准备工作
# 检查依赖包是否已安装
t_pkg="your_pkg"
if ! command -v "$t_pkg" &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m"
    sudo apt update && sudo apt install "$t_pkg"
fi

### 安装软件（幂等：检测最终产物是否存在，存在则跳过）
# 示例：if [ -f "$HOME/Applications/myapp/myapp" ]; then
#         prompt -i "[跳过] myapp 已安装"
#       else
#         ... 下载、解压、编译、复制 ...
#       fi
# 在此填写你的应用安装步骤


### 服务生成（始终重跑，覆盖式）
mkdir -p "$HOME/Services/$SRV_NAME"
cd "$SET_DIR"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo cp srv.service "/home/$USER/Services/$SRV_NAME.service"
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
prompt -x "Make start and stop script..."
sudo cp "$SET_DIR/start.sh" "/home/$USER/Services/$SRV_NAME/start_$SRV_NAME.sh"
sudo cp "$SET_DIR/stop.sh" "/home/$USER/Services/$SRV_NAME/stop_$SRV_NAME.sh"
sudo chmod +x "/home/$USER/Services/$SRV_NAME/"*.sh
cd "$SET_DIR"

### Nginx 独立站（始终重跑，覆盖式）
if [ -f setupNginxForMyapp.sh ]; then
    prompt -x "运行 setupNginxForMyapp.sh（写入 /etc/nginx/sites-available/myapp.conf，不启用）"
    export RUN_PORT SITE_LISTEN SITE_NAME HOME
    bash setupNginxForMyapp.sh
    prompt -i "启用独立站： sudo ngx-site"
else
    prompt -w "未找到 setupNginxForMyapp.sh。"
fi
