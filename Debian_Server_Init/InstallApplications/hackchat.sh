#!/bin/bash
# Hackchat安装
# 需要交互！
# 要求非root用户
# 要求sudo
# 详情见readme

# 指定运行端口(默认) Preset:3000
RUN_PORT=3000
# 服务名
SRV_NAME=hackchat
# 反向代理的端口
REVERSE_PROXY_URL=/hc/
# 是否配置中文首页 Preset=0
CN_INDEX=0

CN_INDEX_CONFIG="
var frontpage = [
	\"                            _           _         _       _   \",
	\"                           | |_ ___ ___| |_   ___| |_ ___| |_ \",
	\"                           |   |_ ||  _| ' _| |  _|   |_ ||  _|\",
	\"                           |_|_|__/|___|_,_|.|___|_|_|__/|_|  \",
	\"\",
	\"\",
	\"欢迎使用hack.chat，这是一个迷你的、无干扰的加密聊天应用程序。\",
	\"频道是通过url创建、加入和共享的，通过更改问号后的文本来创建自己的频道(请使用英文字母)。\",
	\"如果您希望频道名称(房间名)为：‘ hello ’,请在浏览器地址栏输入： https://civiccccc.ltd/hc/?hello\",
	\"这里没有公开频道列表，因此你可以使用秘密的频道名称(也就是别人都猜不到的房间名)进行私人讨论。在这里，聊天记录不会被记录，聊天信息传输也是加密的(除非你不是用的https访问本站，或者你的电脑遭到攻击)。\",
	\"下面是预设的房间：休息室、元数据、数学、物理、化学、科技、编程、游戏、香蕉\",
	\"\",
	\"\",
	\"?lounge ?meta\",
	\"?math ?physics ?chemistry\",
	\"?technology ?programming\",
	\"?games ?banana\",
	\"\",
	\"\",
	\"\",
	\"\",
	\"# 这里为你随机生成了一个聊天室（请点击链接进入房间）: ?\" + Math.random().toString(36).substr(2, 8),
	\"\",
	\"\",
	\"\",
	\"\",
	\"语法支持(支持部分Markdown语法)：\",
	\"空格缩进(两个或四个空格)、Tab键是保留字符，因此可以逐字粘贴源代码(回车请用Shift+Enter)。比如：\",
	\"\`\`\`	\# 这是代码\`\`\`\",
	\"\`\`\`	\#\!/bin/bash\`\`\`\",
	\"\`\`\`	echo hello\`\`\`\",
	\"支持LaTeX语法(数学公式)，单行显示请用一个美元符号包围数学公式，多行显示(展示公式)请用两个美元符号包围。\",
	\"单行：\`\`\`$\"zeta(2) = \\\\pi^2/6$\`\`\`  $\\\\zeta(2) = \\\\pi^2/6$\",
	\"多行：\`\`\`\$\$\\\\int_0^1 \\\\int_0^1 \\\\frac{1}{1-xy} dx dy = \\\\frac{\\\\pi^2}{6}\$\$\`\`\`  \$\$\\\\int_0^1 \\\\int_0^1 \\\\frac{1}{1-xy} dx dy = \\\\frac{\\\\pi^2}{6}\$\$\",
	\"对于语法突出显示，将代码包装为：\`\`\`\<language\> \<the code\>\`\`\`其中<language>是任何已知的编程语言。\",
	\"\",
	\"当前的Github代码仓库: https://github.com/hack-chat\",
	\"旧版GitHub代码仓库: https://github.com/AndrewBelt/hack.chat\",
	\"\",

	\"机器人，Android客户端，桌面客户端，浏览器扩展，Docker映像，编程库，服务器模块等:\",
	\"https://github.com/hack-chat/3rd-party-software-list\",
	\"根据WTFPL和MIT开源许可证发布的服务器和Web客户端。\",
	\"hack.chat服务器不会保留任何聊天记录。\",
	\"\",
	\"\",
	\"Welcome to hack.chat, a minimal, distraction-free chat application.\",
	\"Channels are created, joined and shared with the url, create your own channel by changing the text after the question mark.\",
	\"If you wanted your channel name to be 'your-channel': https://hack.chat/?your-channel\",
	\"There are no channel lists, so a secret channel name can be used for private discussions.\",
	\"\",
	\"\",
	\"Here are some pre-made channels you can join:\",
	\"?lounge ?meta\",
	\"?math ?physics ?chemistry\",
	\"?technology ?programming\",
	\"?games ?banana\",
	\"And here's a random one generated just for you: ?\" + Math.random().toString(36).substr(2, 8),
	\"\",
	\"\",
	\"Formatting:\",
	\"Whitespace is preserved, so source code can be pasted verbatim.\",
	\"Surround LaTeX with a dollar sign for inline style $\\\\zeta(2) = \\\\pi^2/6$, and two dollars for display. \$\$\\\\int_0^1 \\\\int_0^1 \\\\frac{1}{1-xy} dx dy = \\\\frac{\\\\pi^2}{6}\$\$\",
	\"For syntax highlight, wrap the code like: \`\`\`\<language\> \<the code\>\`\`\` where <language> is any known programming language.\",
	\"\",
	\"Current Github: https://github.com/hack-chat\",
	\"Legacy GitHub: https://github.com/AndrewBelt/hack.chat\",
	\"\",
	\"Bots, Android clients, desktop clients, browser extensions, docker images, programming libraries, server modules and more:\",
	\"https://github.com/hack-chat/3rd-party-software-list\",
	\"\",
	\"Server and web client released under the WTFPL and MIT open source license.\",
	\"No message history is retained on the hack.chat server.\"
].join(\"\n\");
"

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

NGINX_CONF="
# Hack chat
location $REVERSE_PROXY_URL {
  access_log $HOME/Logs/nginx/$SRV_NAME.log;
  proxy_pass http://127.0.0.1:$RUN_PORT/;
}
location /hc-wss {
  proxy_pass http://127.0.0.1:6060;
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
if ! [ -x "$(command -v git)" ]; then
    prompt -e "Git not found! Install git..."
    sudo apt install git
fi
if ! [ -x "$(command -v npm)" ]; then
    prompt -e "Npm not found! Install npm..."
    sudo apt install npm
fi
if ! [ -x "$(command -v nodejs)" ]; then
    prompt -e "Nodejs not found! Install nodejs..."
    sudo apt install nodejs
fi
if ! [ -x "$(command -v gawk)" ]; then
    prompt -e "Gawk not found! Install gawk..."
    sudo apt install gawk
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

# 安装
prompt -x "Install hackchat..."
cd $HOME/Applications
git clone https://github.com/hack-chat/main.git hackchat
cd hackchat
npm install

prompt -i "Back to home."
cd
pwd
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
cd $HOME/Applications/hackchat
npm start
" > /home/$USER/Services/$SRV_NAME/start_"$SRV_NAME".sh
echo "#!/bin/bash
cd $HOME/Applications/hackchat
npm stop
" > /home/$USER/Services/$SRV_NAME/stop_"$SRV_NAME".sh
chmod +x /home/$USER/Services/$SRV_NAME/*.sh

# 修改端口号
if [ "$RUN_PORT" -ne 3000 ];then
    prompt -x "Change web page port at $WEB_PORT"
    cd $HOME/Applications/hackchat
    pwd
    # pm2.config.js
    sed -i s/client\ -p\ 3000\ -o/client\ -p\ $WEB_PORT\ -o/g pm2.config.js
fi
# 修改主页
if [ "$CN_INDEX" -eq 1 ];then
    ss="var frontpage"
    se="function \$(query)"

fi


prompt -i "Check manully and setting up reverse proxy by yourself."
prompt -i "========================================================"
prompt -s "For Nginx:"
echo "$NGINX_CONF"
prompt -i "========================================================"
prompt -s "For Apache2:"
echo "$APACHE2_CONF"
prompt -i "========================================================"





