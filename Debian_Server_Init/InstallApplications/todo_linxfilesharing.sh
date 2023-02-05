#!/bin/bash
# https://github.com/ZizzyDizzyMC/linx-server
# 要求非root用户
# 要求sudo git
# 详情见readme

RUN_PORT=8087

# LFSS仓库
LFSS_REPO="https://github.com/ZizzyDizzyMC/linx-server"

# 配置文件
LFSS_CONFIG="bind = 127.0.0.1:$RUN_PORT
sitename = File Sharing
siteurl = YourServer.com
selifpath = s
maxsize = 4294967296
maxexpiry = 86400
allowhotlink = true
remoteuploads = true
nologs = true
force-random-filename = false
cleanup-every-minutes = 5
extra-footer-text = "footer"
realip = true
fastcgi = true
"

SRV_RUN="#!/bin/bash
cd linx-file-sharing/
./linx-server -config linx-server.conf"

SRV_UTIL-"[Unit]
Description=Self-hosted file/code/media sharing website
After=network.target

[Service]
User=www-data
Group=www-data
ExecStart=linx-file-sharing/run.sh

[Install]
WantedBy=multi-user.target"

NGINX_CONF="server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;   
    root $HOME/linx-file-sharing;
    index index.html index.htm index.nginx-debian.html;
    server_name YourServerName.com;
    client_max_body_size 4096M;
    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        fastcgi_pass 127.0.0.1:$RUN_PORT;
        include fastcgi_params;
    }
    ssl_certificate /etc/ssl/xxx.pem;
    ssl_certificate_key /etc/ssl/xxx.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;
    # curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam
    # ssl_dhparam /path/to/dhparam;
    # intermediate configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security \"max-age=63072000\" always;
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
if ! [ xxx ]; then
    prompt -x "Stopping ..."
fi

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
sudo docker run -d --name rsshub -p $RUN_PORT:$RUN_PORT diygod/rsshub
" > /home/$USER/Services/$SRV_NAME/start_"$SRV_NAME".sh
echo "#!/bin/bash
sudo docker stop rsshub
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




