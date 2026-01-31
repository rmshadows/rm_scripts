#!/bin/bash
## 需要有人职守，需要 sudo
## 本目录为「应用安装」模板：复制整目录并重命名为你的应用后，将 CONF 与 myapp 相关命名改为实际服务名，再按需填写安装逻辑。
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名（复制模板后改为实际服务名，并同步改 myapp-snippet.conf、setupNginxForMyapp.sh 中的 myapp 及本脚本中对它们的引用）
SRV_NAME=myapp
# 指定运行端口
RUN_PORT=1200
# 反向代理的地址
REVERSE_PROXY_URL=/myapp/

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

### 安装软件
# 在此填写你的应用安装步骤（下载、解压、编译、复制等）


### 服务生成
# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME" ]; then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME..."
    mkdir -p "$HOME/Services/$SRV_NAME"
fi
# 生成服务
cd "$SET_DIR"
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo mv srv.service "/home/$USER/Services/$SRV_NAME.service"
# 安装服务
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
# 拷贝启动和停止脚本
prompt -x "Make start and stop script..."
sudo cp "$SET_DIR/start.sh" "/home/$USER/Services/$SRV_NAME/start_$SRV_NAME.sh"
sudo cp "$SET_DIR/stop.sh" "/home/$USER/Services/$SRV_NAME/stop_$SRV_NAME.sh"
sudo chmod +x "/home/$USER/Services/$SRV_NAME/"*.sh
cd "$SET_DIR"

### Nginx 配置（片段写入 nginx 目录，不覆盖原机 site）
if [ -f setupNginxForMyapp.sh ]; then
    prompt -x "运行 setupNginxForMyapp.sh（写入 /etc/nginx/snippets/myapp.conf）"
    export RUN_PORT REVERSE_PROXY_URL
    bash setupNginxForMyapp.sh
else
    prompt -w "未找到 setupNginxForMyapp.sh，请手动运行以写入 nginx 片段。"
fi

replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "完整 server 示例（仅供参考，勿直接覆盖原机）："
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"
prompt -i "若使用片段方式，只需在自己的 site 里加一行： include /etc/nginx/snippets/myapp.conf;"
