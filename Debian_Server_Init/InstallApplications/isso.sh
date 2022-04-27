#!/bin/bash
# 
# 要求非root用户
# 要求sudo
# 详情见readme
# https://posativ.org/isso/

# 指定运行端口(默认)
RUN_PORT=3500
# 服务名
SRV_NAME=isso
# 反向代理的端口
REVERSE_PROXY_URL=/isso/
# 你的域名 Include https://
DOMAIN_N="https://127.0.0.1/"

# ISSO配置
ISSO_CONFIG="[general]
dbpath = $HOME/Applications/isso/comments.db
name = default
host = "$DOMAIN_N"
#notify = smtp
log-file = $HOME/Logs/isso/isso.log

[server]
listen = http://localhost:$RUN_PORT/

#[moderation]
#enabled = true
#purge-after = 30d

#[smtp]
#username = .com
#password = m
#host = 127.0.0.1
#port = 587
#security = starttls
#to = @.com
#from = \"Isso Comment\"<username@example.com>
#timeout = 10

[markup]
options = strikethrough, superscript, autolink

[guard]
enabled = true
ratelimit = 5
direct-reply = 30
reply-to-self = true
require-author = true
require-email = true

[hash]
salt = Eech7co8Ohloopo9Ol6baimi
algorithm = pbkdf2
"

# Reverse Proxy 反向代理
APACHE2_CONF="<VirtualHost *:$REVERSE_PROXY_PORT>
    CustomLog $HOME/Logs/apache/$SRV_NAME-$RUN_PORT.log common
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
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Script-Name $REVERSE_PROXY_URL;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_pass http://127.0.0.1:$RUN_PORT/;
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
if ! [ -x "$(command -v python3)" ]; then
    prompt -e "Python3 not found! Install it first!"
    quitThis
fi

# sudo apt-get install python-setuptools python-virtualenv
sudo apt-get install python-dev sqlite3 build-essential

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

if ! [ -d $HOME/Applications/isso/ ];then
    mkdir $HOME/Applications/isso/
fi

if ! [ -d $HOME/Logs ];then
    mkdir $HOME/Logs/
fi

if ! [ -d $HOME/Logs/isso/ ];then
    mkdir $HOME/Logs/isso/
fi

# 安装
pip3 install --upgrade pip && pip3 install isso
sudo apt-get install sqlite3

echo "$ISSO_CONFIG" > $HOME/Applications/isso/isso.conf

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
ExecStart=/home/admin/.local/bin/isso -c $HOME/Applications/isso/isso.conf run
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
prompt -s "For Web Site:"
echo "
<script data-isso=\"http://example.com/isso/\"
        data-isso-css=\"true\"
        data-isso-lang=\"en\"
        data-isso-reply-to-self=\"false\"
        data-isso-require-author=\"false\"
        data-isso-require-email=\"false\"
        data-isso-max-comments-top=\"10\"
        data-isso-max-comments-nested=\"5\"
        data-isso-reveal-on-click=\"5\"
        data-isso-avatar=\"true\"
        data-isso-avatar-bg=\"#f0f0f0\"
        data-isso-avatar-fg=\"#9abf88 #5698c4 #e279a3 #9163b6 ...\"
        data-isso-vote=\"true\"
        data-vote-levels=\"\"
        src=\"http://example.com/isso/js/embed.min.js\"></script>
<section id=\"isso-thread\"></section>
"
prompt -i "========================================================"



