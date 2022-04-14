#!/bin/bash
# 简单粗暴删除rss后重装 要求安装有Docker
# 要求非root用户
# 要求sudo
# 详情见readme

# 指定运行端口(默认1200)
RUN_PORT=1200
# 反向代理的端口
REVERSE_PROXY_URL=/rsshub/

# Reverse Proxy 反向代理
APACHE2_CONF="<VirtualHost *:$REVERSE_PROXY_PORT>
    CustomLog $HOME/Logs/apache/rsshub-$RUN_PORT.log common
    ServerName xxx_server
    ProxyPass / http://127.0.0.1:$RUN_PORT/
    ProxyPassReverse / http://127.0.0.1:$RUN_PORT/
    SSLEngine on
    SSLProxyEngine on
    SSLCertificateFile /etc/ssl/xxx.pem
    SSLCertificateKeyFile /etc/ssl/xxx.key
</VirtualHost>
"

NGINX_CONF="location /rsshub/ {
    access_log $HOME/Logs/nginx/rsshub.log;
    proxy_pass http://127.0.0.1:$RUN_PORT/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    expires 1d;
  }

  or (Choose one) 

server {
  listen xxx_port;
  server_name xxx_server;
  
  access_log $HOME/Logs/nginx/rsshub.log;
  proxy_pass http://127.0.0.1:$RUN_PORT/;
  proxy_set_header Host \$host;
  proxy_set_header X-Real-IP \$remote_addr;
  expires 1d;

  # SSL setting
  # ssl_certificate /etc/ssl/xxx.pem;
  # ssl_certificate_key /etc/ssl/xxx.key;
}
"

## 控制台颜色输出
# 红色：警告、重点
# 黄色：警告、一般打印
# 绿色：执行日志
# 蓝色、白色：常规信息
# 颜色colors
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # warning color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"  
# echo like ...  with  flag type  and display message  colors
# -s 绿
# -e 红
# -w 黄
# -i 蓝
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
    "-x"|"--exec")
      echo -e "Exec：${b_CGSC}${@/-x/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-m"|"--msg")
      echo -e "Info：${b_CCIN}${@/-m/}${CDEF}";;          # print iinfo message
    "-k"|"--kv")  # 三个参数
      echo -e "${b_CCIN} ${2} ${b_CWAR} ${3} ${CDEF}";;          # print success message
    *)
    echo -e "$@"
    ;;
  esac
}

### 预先检查
# 检查是否有root权限，有则退出，提示用户使用普通用户权限。
prompt -i "\n检查权限  ——    Checking for root access...\n"
if [ "$UID" -eq 0 ]; then
    # Error message
    prompt -e "\n [ Error ] -> 请不要使用管理员权限运行 Please DO NOT run as root  \n"
    exit 1
else
    prompt -w "\n——————————  Unit Ready  ——————————\n"
fi

# 临时加入sudoer所使用的语句
TEMPORARILY_SUDOER_STRING="$USER ALL=(ALL)NOPASSWD:ALL"
# 检查是否在sudo组中 0 false 1 true
IS_SUDOER=-1
is_sudoer=-1
IS_SUDO_NOPASSWD=-1
is_sudo_nopasswd=-1
# 检查是否在sudo组
if groups| grep sudo > /dev/null ;then
    # 是sudo组
    IS_SUDOER=1
    is_sudoer="TRUE"
    # 检查是否免密码sudo 括号得注释
    check_var="ALL=\(ALL\)NOPASSWD:ALL"
    if doAsRoot "cat '/etc/sudoers' | grep ^$USER | grep $check_var > /dev/null" ;then
        # sudo免密码
        IS_SUDO_NOPASSWD=1
        is_sudo_nopasswd="TRUE"
    else
        # sudo要密码
        IS_SUDO_NOPASSWD=0
        is_sudo_nopasswd="FALSE"
    fi
else
    # 不是sudoer
    IS_SUDOER=0
    IS_SUDO_NOPASSWD=0
    is_sudoer="FALSE"
    is_sudo_nopasswd="No a sudoer"
fi

prompt -i "__________________________________________________________"
prompt -i "系统信息: "
prompt -k "用户名：" "$CURRENT_USER"
prompt -k "终端：" "$CURRENT_SHELL"
prompt -k "是否为Sudo组成员：" "$is_sudoer"
prompt -k "Sudo是否免密码：" "$is_sudo_nopasswd"
prompt -k "是否是GNOME：" "$IS_GNOME_DE ( $DESKTOP_SESSION )"
prompt -i "__________________________________________________________"
prompt -e "以上信息如有错误，或者出现了-1，请按 Ctrl + c 中止运行。"



# 检查命令
if ! [ -x "$(command -v docker)" ]; then
    prompt -e "Docker not found! Install docker first!"
    exit 1
fi

# 检查文件夹
if ! [ -d $HOME/Services ];then
    mkdir $HOME/Services
    echo "#!/bin/bash
cp *.service /lib/systemd/system/
sudo systemctl daemon-reload
" > $HOME/Services/Install_Servces.sh
    chmod +x $HOME/Services/Install_Servces.sh
fi

if ! [ -d $HOME/Applications ];then
    mkdir $HOME/Applications
fi

# 安装RSSHUB
if ! [ -x "$(command -v docker)" ]; then
    prompt -x "Stopping rsshub & Removing rsshub..."
    docker stop rsshub
    docker rm rsshub
    prompt -x "Installing rsshub..."
    docker pull diygod/rsshub
    prompt -x "Running rsshub on $RUN_PORT..."
    docker run -d --name rsshub -p $RUN_PORT:$RUN_PORT diygod/rsshub
fi

prompt -i "Check manully and setting up reverse proxy by yourself."
prompt -i "========================================================"
prompt -s "For Nginx:"
echo $NGINX_CONF
prompt -i "========================================================"
prompt -s "For Apache2:"
echo $APACHE2_CONF
prompt -i "========================================================"





