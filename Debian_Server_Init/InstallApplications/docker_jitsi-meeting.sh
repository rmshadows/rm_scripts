#!/bin/bash
# 注意。此脚本是全局安装！
# 要求非root用户
# 要求sudo
# 详情见readme

# 运行端口
RUN_PORT=
# 服务名
SRV_NAME=jitsi-meet-docker
# 反向代理的端口
REVERSE_PROXY_URL=/jm/
# docker下载地址
DOCKER_STABLE="https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/stable-7001.tar.gz"


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

NGINX_CONF="location $REVERSE_PROXY_URL {
    access_log $HOME/Logs/nginx/$SRV_NAME.log;
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

sudo ls > /dev/null
# 是否临时加入sudoer
TEMPORARILY_SUDOER=0
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
    check_var="ALL=(ALL)NOPASSWD:ALL"
    # cat /etc/sudoers
    if sudo cat /etc/sudoers | grep ^$USER | grep $check_var > /dev/null ;then
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
prompt -k "是否为Sudo组成员：" "$is_sudoer"
prompt -k "Sudo是否免密码：" "$is_sudo_nopasswd"
prompt -i "__________________________________________________________"
echo ""
echo ""
# 如果用户按下Ctrl+c
trap "onSigint" SIGINT

# 程序中断处理方法,包含正常退出该执行的代码
onSigint () {
    prompt -w "捕获到中断信号..."
    onExit 
    exit 1
}

# 正常退出需要执行的
onExit () {
    # 临时加入sudoer，退出时清除
    if [ $TEMPORARILY_SUDOER -eq 1 ] ;then
        prompt -x "Clean temp sudoer no-passwd..."
        # sudo sed -i "s/$TEMPORARILY_SUDOER_STRING/ /g" /etc/sudoers
        # 获取最后一行
        tail_sudo=`sudo tail -n 1 /etc/sudoers`
        if [ "$tail_sudo" = "$TEMPORARILY_SUDOER_STRING" ] > /dev/null ;then
            # 删除最后一行
            sudo sed -i '$d' /etc/sudoers
        else
            # 一般不会出现这个情况吧。。
            prompt -e "WARN: Unknown ERROR.Del $TEMPORARILY_SUDOER_STRING in /etc/sudoers"
            exit 1
        fi
    fi
}
# 中途异常退出脚本要执行的
quitThis () {
    onExit
    exit
}
if [ "$IS_SUDOER" -eq 0 ];then
    prompt -e "Not a sudoer!"
    exit 1
fi
# 如果是sudoer，但没有免密码，临时配置
if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ];then
    echo "$TEMPORARILY_SUDOER_STRING" | sudo tee -a /etc/sudoers
    TEMPORARILY_SUDOER=1
fi

##############################################################

# 检查命令
if ! [ -x "$(command -v docker)" ]; then
    prompt -e "Docker not found! Install docker first!"
    quitThis
fi

if ! [ -x "$(command -v docker-compose)" ]; then
    prompt -e "Docker-compose not found! Install docker-compose first!"
    quitThis
fi

# 检查文件夹
if ! [ -d $HOME/Services ];then
    mkdir $HOME/Services
    echo "#!/bin/bash
sudo cp *.service /lib/systemd/system/
sudo systemctl daemon-reload
" > $HOME/Services/Install_Servces.sh
    chmod +x $HOME/Services/Install_Servces.sh
fi

if ! [ -d $HOME/Applications ];then
    mkdir $HOME/Applications
fi

# 安装
cd $HOME/Applications
prompt -x "Downloading docker"
wget "$DOCKER_STABLE" -O jitsi-meet-docker.tar.gz
if ! [ -f jitsi-meet-docker.tar.gz ]; then
    prompt -e "Wget seems wrong. Stopping ..."
    quitThis
fi
prompt -x "Unzip tar.gz..."
tar xzvf jitsi-meet-docker.tar.gz
prompt -x "Rename..."
mv docker-jitsi-meet-* docker-jitsi-meet
cd docker-jitsi-meet
cp env.example .env
./gen-passwords.sh
prompt -x "Create required CONFIG directories ~/.jitsi-meet-cfg/{web/crontabs,web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}..."
mkdir -p ~/.jitsi-meet-cfg/{web/crontabs,web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
prompt -x "Access the web UI at https://localhost:8443 (or a different port, in case you edited the compose file)."
prompt -w "Testing......"
docker-compose up -d
if [ "$?" -ne 0 ];then
    prompt -e "Docker-compose may wrong....Check manually."
    docker-compose down
    quitThis
else
    prompt -x "Test done."
    docker-compose down
fi

prompt -x "Backhome..."
cd 

# mk srv
prompt -x "Make Service..."
if ! [ -d $HOME/Services/$SRV_NAME ];then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME..."
    mkdir $HOME/Services/$SRV_NAME
fi
echo "[Unit]
Description=自定义的服务，用于启动"$SRV_NAME"
After=network.target 

[Service]
ExecStart=/home/$USER/Services/$SRV_NAME/start_"$SRV_NAME".sh
ExecStop=/home/$USER/Services/$SRV_NAME/stop_"$SRV_NAME".sh
User=$USER
Type=forking
PrivateTmp=True

[Install]
WantedBy=multi-user.target
" > /home/$USER/Services/$SRV_NAME.service

prompt -x "Install service..."
cd $HOME/Services/
sudo $HOME/Services/Install_Servces.sh

prompt -x "Make start and stop script..."
# Start and stop script
echo "#!/bin/bash
cd $HOME/Applications/docker-jitsi-meet/
docker-compose up&
" > /home/$USER/Services/$SRV_NAME/start_"$SRV_NAME".sh
echo "#!/bin/bash
cd $HOME/Applications/docker-jitsi-meet/
docker-compose down&
" > /home/$USER/Services/$SRV_NAME/stop_"$SRV_NAME".sh
chmod +x /home/$USER/Services/$SRV_NAME/*.sh

prompt -i "Check manully and setting up reverse proxy by yourself."
prompt -i "========================================================"
prompt -s "For Nginx:"
echo "$NGINX_CONF"
prompt -i "========================================================"
prompt -s "For Apache2:"
echo "$APACHE2_CONF"
prompt -i "========================================================"
onExit




