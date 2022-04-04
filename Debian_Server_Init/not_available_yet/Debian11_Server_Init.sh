#!/bin/bash
# https://github.com/rmshadows/rm_scripts
# 未完成！

:<<!About-说明
Version：0.0.1
============================================
0 for No.
1 for Yes.
============================================
预设参数（在这里修改预设参数, 谢谢）
注意：如果没有注释，默认0 为否 1 为是。
if [ "$" -eq 1 ];then
    [Your Code]
fi
!About-说明

## Check-1-检查点一：
# Set APT source 0:skip(跳过) 1:Tsinghua Mirror for Chinese(清华大学镜像源) 2.Your Souce (你自定义的源)     Preset:0
SET_APT_SOURCE=0
# Your apt source Preset=""
SET_YOUR_APT_SOURCE=""
# Install without asking(更新与安装是否不过问) Preset:1
SET_APT_RUN_WITHOUT_ASKING=1
# Disable unattended-upgrades.service ? (禁用unattended-upgrades.service?) 0:skip(跳过) 1:enable(启用) 2:disable(禁用)  Preset=0
SET_ENABLE_UNATTENDED_UPGRADE=0
# Update system with apt(是否在安装软件前更新整个系统) 0:just apt update 1:apt dist-upgrade 2:apt upgrade   Preset:1
SET_APT_UPGRADE=1

## Check-2-检查点二：
# Set to 1 will specify a user.User will be created if not exist.If set to 0, continue with root(是否指定某用户进行配置，否的话将以root用户继续)  Preset:1
SET_USER=1
# Change bash to zsh 是否替换Bash为Zsh（包括root用户） Preset:1
SET_BASH_TO_ZSH=1
# Change zshrc file for all user 是否配置ZSHRC Preset:1
SET_ZSHRC=1
# User Name in lower case(要新建的用户名-必须小写英文！) Preset="admin"
SET_USER_NAME="admin"
# User password(要新建的用户密码) Preset="passwd"
SET_USER_PASSWD="passwd"
# User should be a sudoer?(是否加入sudo用户组) Preset:1
SET_USER_SUDOER=1
# User should run `sudo` without passwd(是否设置sudo无需密码) Preset:1
SET_SUDOER_NOPASSWD=1

## Check-3-检查点三：
# Uninstall vim-tiny and install vim-full(是否卸载vim-tiny，安装vim-full) Preset:1
SET_VIM_TINY_TO_FULL=1
# Create folders in User Home path (新建home文件夹中的目录Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service) Preset:1
SET_HOME=1
# Add sbin to env (添加/usr/sbin到用户环境变量) Preset=1
SET_ADD_SBIN_ENV=1
# Install bash-completion (是否安装bash-completion) Preset=1
SET_BASH_COMPLETION=1
# Install zsh-autosuggestions (是否安装zsh-autosuggestions) Preset=1
SET_ZSH_AUTOSUGGESTIONS=1

## Check-4-检查点四：
# Create a /lib/systemd/system/customize-autorun.service(自定义自己的服务（运行一个shell脚本）) Preset:1
SET_SYSTEMCTL_SERVICE=1
# Set hostname(设置HostName) Preset=0
SET_HOST_NAME=0
# Set locales(If you do not need this, just set 0) (设置语言支持，不需要请设置为0) Preset="en_US.UTF-8 UTF-8"
SET_LOCALES="# Setup locales
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
"
# Set time zone (zoneinfo file path)(设置时间支持) Preset=0
# e.g.:Shanghai China,You need to set this: /usr/share/zoneinfo/Asia/Shanghai 
SET_TIME_ZONE=0

## Check-5-检查点五：
# 从apt仓库拉取常用软件
# Install packages from apt repo (是否从APT源安装常用软件) Preset=1
SET_APT_INSTALL=1
:<<注释
要安装的的软件的列表,列表在下方！！往下一直拉
有几个预选的安装列表供参考:
0.自定义列表
1.轻便安装
2.部分安装
3.全部安装
Preset=1
注释
# Which package list should be installed.
SET_APT_INSTALL_LIST_INDEX=1
# Install python3(安装Python3) Preset=1
SET_PYTHON3_INSTALL=1
# [Chinese only!]Config Pip mirror to tsinghua,for other mirror, replace 0 or 1 with mirror addr(string) (配置Python3源为清华大学镜像,自定义源请用字符串) Preset=0
SET_PYTHON3_MIRROR=0
# Install git (安装配置git) Preset=1
SET_INSTALL_GIT=1
# Git User & E-mail(Git用户名、邮箱地址 默认$CURRENT_USER & $CURRENT_USER@$HOST) Preset=0
SET_GIT_USER=0
SET_GIT_EMAIL=0
# Install openssh-server(安装配置ssh) Preset=1
SET_INSTALL_OPENSSH=1
# Enable ssh server(SSH开机是否自启 默认启用) Preset=1 
SET_ENABLE_SSH=1
# Install npm(安装配置npm) Preset=0
SET_INSTALL_NPM=0
# Install nodejs(是否安装Nodejs) Preset=0
SET_INSTALL_NODEJS=0
# Install cnpm (For Chinese) (是否安装CNPM) Preset=0
SET_INSTALL_CNPM=0

# Config SSH Key(配置SSH Key) Preset=1
SET_CONFIG_SSH_KEY=1
# Generate New SSH Key(是否生成新的SSH Key 0:新的密钥 1:从文件夹导入现有密钥 2:从文本导入现有密钥) Preset=0
SET_SSH_KEY_SOURCE=0
# New ssh key file name(新生成的、或者导入文本生成的SSH密钥名称) Preset=id_rsa
SET_SSH_KEY_NAME=id_rsa
# ssh key passwd(新生成的SSH密钥密码) Preset=""
SET_NEW_SSH_KEY_PASSWD=""
# 新密钥的备注 "A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian 11_Server_Deploy_Script")
SET_SSH_KEY_COMMENT=0
# 存放已存在的SSH密钥文件夹名称 1:从文件夹导入
SET_EXISTED_SSH_KEY_SRC=SSH_KEY
# SSH 密钥文本 2:从文本导入
# 私钥
SET_SSH_KEY_PRIVATE_TEXT=""
# 公钥
SET_SSH_KEY_PUBLIC_TEXT=""

## Check-6-检查点六：


## Check-7-检查点七：
# Install http server安装配置Apache2 Preset=1
SET_INSTALL_APACHE2=1
# 是否设置Apache2开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_APACHE2=0


:<<注释
下面是需要填写的列表，要安装的软件。注意，格式是短杠空格接软件包名接破折号接软件包描述“- 【软件包名】——【软件包描述】”
注意：列表中请不要使用中括号
注释

# Customize 自定义列表
SET_APT_TO_INSTALL_INDEX_0="

"

# 这里是 脚本运行后 要安装的软件。格式同上，注意是稍后安装的，所以会放在脚本执行结束后才安装。
SET_APT_TO_INSTALL_LATER="
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
"

# 轻便安装 (仅我个人认为必要的常用软件)
APT_TO_INSTALL_INDEX_1="
- apt-listbugs——apt_list_bug
- apt-listchanges——apt_list_change
- apt-transport-https——apt-transport-https
- axel——axel_downloader
- bash-completion——bash_completion
- build-essential——build-essential
- ca-certificates——ca-certificates
- curl——curl
- gnupg——GPG
- htop——colored_top
- httrack——website_clone
- lsb-release——lsb-release
- make——make
- net-tools——ifconfig
- screenfetch——display_system_info
- sed——text_edit
- silversearcher-ag——Ag_searcher
- tcpdump——tcpdump
- tree——ls_dir_as_tree
- traceroute——trace_route
- wget——wget
- zhcon——tty_display_Chinese
- zsh——zsh
- zsh-autosuggestions——zsh_plugin
"


### 配置文件
# Zshrc文件
ZSHRC_CONFIG=""

### 脚本变量
# Root用户UID
ROOT_UID=0
# 当前 Shell名称
CURRENT_SHELL=$SHELL
# 用户路径
HOME_INDEX=""

#### 脚本内置函数调用

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

## 询问函数 Yes:1 No:2 ???:5
:<<!询问函数
函数调用请使用：
comfirm "\e[1;33m? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  yes
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi
!询问函数
comfirm () {
  flag=true
  ask=$1
  while $flag
  do
    echo -e "$ask"
    read -r input
    if [ -z "${input}" ];then
      # 默认选择N
      input='n'
    fi
    case $input in [yY][eE][sS]|[yY])
      return 1
      flag=false
    ;;
    [nN][oO]|[nN])
      return 2
      flag=false
    ;;
    *)
      prompt -w "Invalid option..."
    ;;
    esac
  done
}

# 备份配置文件。先检查是否有bak结尾的备份文件，没有则创建，有则另外覆盖一个newbak文件。$1 :文件名
backupFile () {
    if [ -f "$1" ];then
        # 如果有bak备份文件 ，生成newbak
        if [ -f "$1.bak" ];then
            # bak文件存在
            prompt -x "正在备份 $1 文件到 $1.newbak (覆盖) "
            cp $1 $1.newbak
        else
            # 没有bak文件，创建备份
            prompt -x "正在备份 $1 文件到 $1.bak"
            cp $1 $1.bak
        fi
    else
        # 如果不存在要备份的文件,不执行
        prompt -e "没有$1文件，不做备份"
    fi
} 

# 执行apt命令 注意，检查点一后才能使用这个方法
doApt () {
    prompt -x "doApt: $@"
    if [ "$1" = "install" ] || [ "$1" = "remove" ] || [ "$1" = "dist-upgrade" ] || [ "$1" = "upgrade" ];then
        if [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 0 ];then
            apt $@
        elif [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 1 ];then
            apt $@ -y
        fi
    else
        apt $@
    fi
}

# 新建文件夹 $1
addFolder () {
    if [ $# -ne 1 ];then
        prompt -e "addFolder () 只能有一个参数"
        exit 5
    fi
    if ! [ -d $1 ];then
        prompt -x "新建文件夹$1 "
        mkdir $1
    fi
}




#### 正文
echo -e "\e[1;31m
_________  .___ ____   ____.___ _________  _________  _________  _________  _________  
\_   ___ \ |   |\   \ /   /|   |\_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ 
/    \  \/ |   | \   Y   / |   |/    \  \/ /    \  \/ /    \  \/ /    \  \/ /    \  \/ 
\     \____|   |  \     /  |   |\     \____\     \____\     \____\     \____\     \____
 \______  /|___|   \___/   |___| \______  / \______  / \______  / \______  / \______  /
        \/                              \/         \/         \/         \/         \/ 
\e[1;32m
==========================================
┏ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┓ 
┃        欢迎使用Debian服务部署          ┃
┃使用须知：                              ┃
┃\e[1;31m运行环境：Linux Terminal(终端)          \e[1;32m┃
┃\e[1;31m权限要求：需要管理员权限                \e[1;32m┃
┃\e[1;32m——————————————————————————————————————— ┃
┗ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┛ 
==========================================

\e[0m"
# R
echo -e "\e[1;31m Preparing(1s)...\n\e[0m" # TODO
# sleep 1

:<<Prep-预备步骤
获取当前用户名
Prep-预备步骤
# Get Current User获取当前用户名(root,后面如果有指定用户，则是指定用户)
CURRENT_USER_SET=$USER
# 用户目录
HOME_INDEX="$HOME"
# 主机名
if [ "$SET_HOST_NAME" -ne 0 ];then
    HOSTNAME=$SET_HOST_NAME
else
    HOSTNAME=$HOST
fi

# 设置用户目录
if [ "$SET_USER" -eq 1 ];then
    CURRENT_USER_SET=$SET_USER_NAME
    HOME_INDEX="/home/$SET_USER_NAME"
else
    CURRENT_USER_SET=root
    HOME_INDEX="/root"
fi
prompt -i "Current User Set: $CURRENT_USER_SET"
prompt -i "Current Shell: $CURRENT_SHELL"
prompt -i "Current User Set Home: $HOME_INDEX"
# 检查是否有root权限，无则退出，提示用户使用root权限。
prompt -i "\nChecking for root access...\n"
if [ "$UID" -eq "$ROOT_UID" ]; then
  prompt -s "\n——————————  Unit Ready  ——————————\n"
else
  # Error message
  prompt -e "\n [ Error ] -> Please run with root(ROOT, NOT SUDO !)  \n"
  exit 1
fi

#### 预运行
# 参数赋值
# Git
if [ "$SET_GIT_USER" -eq 0 ];then
    SET_GIT_USER=$CURRENT_USER_SET
fi
if [ "$SET_GIT_EMAIL" -eq 0 ];then
    SET_GIT_EMAIL=$CURRENT_USER_SET@$HOSTNAME
fi
# SSH
if [ "$SET_SSH_KEY_COMMENT" -eq 0 ];then
    SET_SSH_KEY_COMMENT="A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian 11_GNOME_Deploy_Script"
fi


### 确认运行模块
# R
comfirm "\e[1;31m Improperly usage of this script may has potential harm to your computer「If you don't know what you're doing, just press ENTER」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  prompt -s "\n"
elif [ $choice == 2 ];then
  prompt -w "Looking forward to the next meeting ——  https://rmshadows.gitee.io"
  exit 0
else
  prompt -e "ERROR:Unknown Option..."
  exit 5
fi


:<<Check-1-检查点一
更改镜像（针对国内服务器）
系统更新
默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
更新源、更新系统。
配置unattended-upgrades
Check-1-检查点一
prompt -i "——————————  Check 1  ——————————"

# 预安装 安装部分先决软件包 后面还有
prompt -x "Install pre-required packages..."
doApt update
# 确保https源可用 
doApt install apt-transport-https
doApt install ca-certificates
# 添加清华大学 Debian 11 镜像源
if [ "$SET_APT_SOURCE" -eq 1 ];then
    backupFile "/etc/apt/sources.list"
    prompt -x "Set Tsinghua Debian 11 mirror..."
    echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free" | tee /etc/apt/sources.list
# 添加自己的Debian源
elif [ "$SET_APT_SOURCE" -eq 2 ];then
    backupFile "/etc/apt/sources.list"
    prompt -x "Set your apt source..."
    echo "$SET_YOUR_APT_SOURCE" | tee /etc/apt/sources.list
fi

# 配置unattended-upgrades
if [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 0 ];then
    prompt -m "Leave unattended-upgrades.service nothing done...."
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 1 ];then
    prompt -x "Enable unattended-upgrades.service"
    systemctl enable unattended-upgrades.service
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 2 ];then
    prompt -x "Disable unattended-upgrades.service"
    systemctl disable unattended-upgrades.service
fi

# 更新源-预先安装的软件
doApt update
# 保证sudo添加可用
doApt install gawk
# 保证后面Vbox密钥添加
doApt install wget
doApt install gnupg2
doApt install gnupg
doApt install lsb-release

# 更新系统
if [ "$SET_APT_UPGRADE" -eq 0 ];then
    prompt -x "Apt update only...."
    doApt update
elif [ "$SET_APT_UPGRADE" -eq 1 ];then
    prompt -x "Apt Dist-upgrade...."
    doApt update && doApt dist-upgrade
elif [ "$SET_APT_UPGRADE" -eq 2 ];then
    prompt -x "Apt upgrade...."
    doApt update && doApt upgrade
fi

:<<Check-2-检查点二
安装sudo openssh-server zsh(必选)
配置root用户zsh
新建用户
配置用户zsh
添加用户到sudo组。
设置用户sudo免密码。
Check-2-检查点二

# 安装sudo openssh-server zsh
prompt -i "sudo openssh-server will be installed."
doApt install sudo
doApt install openssh-server

# 设置root用户使用zsh 注意，这里还不能用$HOME_INDEX
# 配置root用户zsh
prompt -i "Current shell：$CURRENT_SHELL"
if [ "$CURRENT_SHELL" == "/bin/bash" ]; then
    shell_conf=".bashrc"
    if [ "$SET_BASH_TO_ZSH" -eq 1 ];then
        # 判断是否安装zsh
        if ! [ -x "$(command -v zsh)" ]; then
            prompt -i 'Error: Zsh is not installed.' >&2
            prompt -x "Install Zsh..."
            doApt install zsh
        fi
        if ! [ -x "$(command -v zsh)" ]; then
            prompt -e "ZSH install failed !"
            exit 1
        else
            shell_conf=".zshrc"
            prompt -x "Config ZSHRC...."
            echo "$ZSHRC_CONFIG" > /root/$shell_conf
            prompt -x "Set zsh for root."
            usermod -s /bin/zsh root
        fi
    fi
elif [ "$CURRENT_SHELL" == "/bin/zsh" ];then
    # 如果使用zsh，则更改zsh配置
    shell_conf=".zshrc"
    if [ "$SET_ZSHRC" -eq 1 ];then
        backupFile "/root/$shell_conf"
        prompt -x "Config root's ZSHRC"
        echo "$ZSHRC_CONFIG" > /root/$shell_conf
    elif [ "$SET_ZSHRC" -eq 0 ];then
        prompt -m "Keep original ZSHRC file."
    fi
else
    prompt -e "Unknown shell: $CURRENT_SHELL"
    exit 1
fi

# 新建用户 如果已经存在，不添加，直接配置该用户
if [ "$SET_USER" -eq 1 ];then
    prompt -x "Creating user $CURRENT_USER_SET...."
    # 检测是否存在该用户
    egrep "^$CURRENT_USER_SET" /etc/passwd >/dev/null
    if [ $? -eq 0 ]; then
        # 存在用户 
        prompt -e "Failed to add $CURRENT_USER_SET. Username already exists! Continue with $CURRENT_USER_SET"
    else
        # 不存在则新建
        encrypt_pass=$(perl -e 'print crypt($ARGV[0], "password")' $SET_USER_PASSWD)
        useradd -m -s /bin/zsh -G sudo -p $encrypt_pass $CURRENT_USER_SET
        if [ $? -eq 0 ];then
            prompt -i "User has been added to system!"
        else
            echo "Failed to add a user!"
            exit 1
        fi
    fi
fi

# 设置用户zsh
if [ "$SET_USER_ZSH" -eq 1 ];then
    prompt -x "Set zsh for $CURRENT_USER_SET"
    usermod -s /bin/zsh $CURRENT_USER_SET
fi

# 检查是否在sudoer
prompt -i "Check if $CURRENT_USER_SET in sudoers"
# 检查是否在sudo组中 0 false 1 true
IS_SUDOER=-1
IS_SUDO_NOPASSWD=-1
# 检查是否在sudo组
if groups $CURRENT_USER_SET | grep sudo > /dev/null ;then
    # 是sudo组
    IS_SUDOER=1
    # 检查是否免密码sudo
    check_var="ALL=(ALL)NOPASSWD:ALL"
    if cat '/etc/sudoers' | grep $check_var | grep $CURRENT_USER_SET > /dev/null ;then
        # sudo免密码
        IS_SUDO_NOPASSWD=1
    else
        # sudo要密码
        IS_SUDO_NOPASSWD=0
    fi
else
    # 不是sudoer
    IS_SUDOER=0
    IS_SUDO_NOPASSWD=0
fi

# 配置用户为sudo
if [ "$CURRENT_USER_SET" == "root" ];then
    prompt -w "Not sudo for root, pass."
elif [ "$IS_SUDOER" -eq 0 ];then
    # 如果没有在sudo组,添加用户到sudo组
    if [ "$SET_USER_SUDOER" -eq 1 ];then
        prompt -x "Add $CURRENT_USER_SET to sudo group...."
        usermod -a -G sudo $CURRENT_USER_SET
        IS_SUDOER=1
    fi
    # 配置sudo免密码
    if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ] && [ "$SET_SUDOER_NOPASSWD" -eq 1 ];then
        prompt -x "Set $CURRENT_USER_SET sudo nopasswd...."
        SUDOER_STRING="$CURRENT_USER_SET ALL=(ALL)NOPASSWD:ALL"
        echo $SUDOER_STRING >> /etc/sudoers
        IS_SUDO_NOPASSWD=1
    fi
elif [ "$IS_SUDOER" -eq 1 ];then
    # 如果已经是sudoer 配置是否免密码
    if [ "$IS_SUDO_NOPASSWD" -eq 0 ] && [ "$SET_SUDOER_NOPASSWD" -eq 1 ];then
        prompt -x "Set $CURRENT_USER_SET sudo not passwd."
        check_var="ALL=(ALL:ALL) ALL"
        # 获取行号
        idx=`cat Text.txt | grep -n ^$CURRENT_USER_SET | grep $check_var | gawk '{print $1}' FS=":"`
        # echo $idx
        # 找到的Index
        idxl=($idx)
        idxlen=${#idxl[@]}  
        # echo $idxlen
        if [ $idxlen -ne 1 ];then
          prompt -e "Find duplicate user setting in /etc/sudoers! Check manually!"
          exit 1
        fi
        SUDO_STRING="$CURRENT_USER_SET  ALL=(ALL)NOPASSWD:ALL"
        sed -i "$idx d" /etc/sudoers
        echo $SUDO_STRING >> /etc/sudoers
        IS_SUDO_NOPASSWD=1
    elif [ "$IS_SUDO_NOPASSWD" -eq 1 ] && [ "$SET_SUDOER_NOPASSWD" -eq 0 ];then
        prompt -x "Set $CURRENT_USER_SET sudo required passwd."
        check_var="ALL=(ALL)NOPASSWD:ALL"
        # 获取行号
        idx=`cat Text.txt | grep -n ^$CURRENT_USER_SET | grep $check_var | gawk '{print $1}' FS=":"`
        # echo $idx
        # 找到的Index
        idxl=($idx)
        idxlen=${#idxl[@]}  
        # echo $idxlen
        if [ $idxlen -ne 1 ];then
          prompt -e "Find duplicate user setting in /etc/sudoers! Check manually!"
          exit 1
        fi
        SUDO_STRING="$CURRENT_USER_SET  ALL=(ALL:ALL) ALL"
        sed -i "$idx d" /etc/sudoers
        echo $SUDO_STRING >> /etc/sudoers
        IS_SUDO_NOPASSWD=0
    fi
else
    prompt -e "$IS_SUDOER 不等于 0 or 1 ."
    exit 1
fi


:<<Check-3-检查点三
安装vim-full，卸载vim-tiny；
添加/usr/sbin到环境变量；
添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）；
安装bash-completion；
安装zsh-autosuggestions
Check-3-检查点三
# 安装vim-full，卸载vim-tiny；
if [ "$SET_VIM_TINY_TO_FULL" -eq 1 ];then
    prompt -x "Uninstall vim-tiny and install vim-full."
    doApt remove vim-tiny
    doApt install vim
fi

# 添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）；
if [ "$SET_HOME" -eq 1 ];then
    prompt -x "Creating folders in $HOME_INDEX..."
    mkdir $HOME_INDEX/Data
    mkdir $HOME_INDEX/Applications
    mkdir $HOME_INDEX/Temp
    mkdir $HOME_INDEX/Workplace
    mkdir $HOME_INDEX/Services
    mkdir $HOME_INDEX/Logs
    mkdir $HOME_INDEX/Logs/apache2
    mkdir $HOME_INDEX//Logs/nginx
    chown $CURRENT_USER_SET -hR $HOME_INDEX
fi

# 添加/usr/sbin到环境变量；
if [ "$SET_ADD_SBIN_ENV" -eq 1 ];then
    prompt -x "Add sbin to path..."
    check_var="export PATH=\"\$PATH:/usr/sbin\""
    # G
    echo -e "\e[1;32m Checking path in $shell_conf…… \e[0m"
    if cat '$HOME_INDEX/$shell_conf' | grep "$check_var"
    then
        # B
        echo -e "\e[1;34m $check_var  detected, path already existd, pass.\e[0m"
    else
        # G
        echo -e "\e[1;32m Add /usr/sbin to $shell_conf. \e[0m"
        echo "export PATH=\"\$PATH:/usr/sbin\"" >> $HOME_INDEX/$shell_conf
    fi
fi

# 安装bash-completion；
if [ "$SET_BASH_COMPLETION" -eq 1 ];then
    prompt -x "Install bash-completion..."
    doApt install bash-completion
fi

# 安装zsh-autosuggestions
if [ "$SET_ZSH_AUTOSUGGESTIONS" -eq 1 ];then
    prompt -x "Install zsh-autosuggestions..."
    doApt install zsh-autosuggestions
fi

:<<Check-4-检查点四
自定义自己的服务（运行一个shell脚本）
Check-4-检查点四
# 自定义自己的服务（运行一个shell脚本）
if [ "$SET_SYSTEMCTL_SERVICE" -eq 1 ];then
    prompt -x "Create a /lib/systemd/system/customize-autorun.service."
    addFolder $HOME_INDEX/.$CURRENT_USER_SET/
    addFolder $HOME_INDEX/.$CURRENT_USER_SET/scripts/
    prompt -x "Generate file: $HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh "
    echo "#!/bin/bash
echo -e \"\e[1;33m Hello World \e[0m\"
" > $HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh
    chmod +x $HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh
    prompt -x "Build /lib/systemd/system/customize-autorun.service."
    if ! [ -f /lib/systemd/system/customize-autorun.service ];then
        echo "[Unit]
Description=自定义的服务，用于开启启动/home/用户/.用户名/script下的shell脚本，配置完成请手动启用。注意，此脚本将以root身份运行！
After=network.target 

[Service]
ExecStart=$HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh
Type=forking
PrivateTmp=True

[Install]
WantedBy=multi-user.target
" > /lib/systemd/system/customize-autorun.service
    fi
fi

# 设置主机名
if [ "$SET_HOST_NAME" -ne 0 ];then
    prompt -x "Setup hostname"
    echo $hostname > /etc/hostname
    echo "127.0.1.1	$hostname" >> /etc/hosts
fi

# 设置语言支持
if [ "$SET_LOCALES" -ne 0 ];then
    prompt -x "Setup locales"
    backupFile /etc/locale.gen
    echo "$SET_LOCALES" > /etc/locale.gen
    locale-gen
fi

# 设置时区
if [ "$SET_TIME_ZONE" -ne 0 ];then
    prompt -x "Setup timezone"
    backupFile /etc/localtime
    # echo "ZONE=Asia/Shanghai" >> /etc/sysconfig/clock
    # rm -f /etc/localtime
    ln -sf "$SET_TIME_ZONE" /etc/localtime
fi

:<<Check-5-检查点五
从apt仓库拉取常用软件
安装Python3
配置Python3源为清华大学镜像
安装配置Apache2
安装配置Git(配置User Email)
安装配置SSH
安装配置npm
Check-5-检查点五
# 从APT仓库安装常用软件包
if [ "$SET_APT_INSTALL" -eq 1 ];then
    # 准备安装的包名列表
    immediately_task=()
    # 脚本运行结束后要安装的包名
    later_task=()
    # 先判断要安装的列表
    if [ "$SET_APT_INSTALL_LIST_INDEX" -eq 0 ];then
        # 自定义安装
        app_list=$SEAPT_TO_INSTALL_INDEX_0
    elif [ "$SET_APT_INSTALL_LIST_INDEX" -eq 1 ];then
        app_list=$APT_TO_INSTALL_INDEX_1
    else
        prompt -e "APT_TO_INSTALL_INDEX List not found !"
        exit 2
    fi
    # 首先，处理稍后要安装的软件包
    later_list=$SET_APT_TO_INSTALL_LATER
    later_list=$(echo $later_list | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
    later_list=($later_list)
    later_len=${#later_list[@]}
    prompt -m "Packages below will be installed: "
    for ((i=0;i<$later_len;i++));do
        each=${later_list[$i]}
        index=`expr index "$each" —`
        # 软件包名
        name=${later_list[$i]/$each/${each:0:($index-1)}}
        # 添加到列表
        later_task[$num]=${name}
        prompt -i "$each"
    done
    sleep 8
    echo -e "\n\n\n"
    # 处理app_list列表
    # 把“- ”转为换行符 然后删除所有空格 最后删除第一行。echo $LST | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d'
    app_list=$(echo $app_list | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
    # 生成新的列表
    app_list=($app_list)
    # 接下来打印要安装的软件包列表, 显示的序号从0开始
    num=0
    app_len=${#app_list[@]}
    prompt -m "Begin installation: "
    for ((i=0;i<$app_len;i++));do
        # 显示序号
        echo -en "\e[1;35m$num)\e[0m"
        each=${app_list[$i]}
        index=`expr index "$each" —`
        # 软件包名
        name=${app_list[$i]/$each/${each:0:($index-1)}}
        immediately_task[$num]=${name}
        prompt -i "$each"
        num=$((num+1))
    done
    sleep 10
    doApt install ${immediately_task[@]}
    if [ $? != 0 ];then
        prompt -e "Continue...."
        sleep 2
        num=1
        for var in ${immediately_task[@]}
        do
            prompt -m "Install package: $num - $var ..."
            doApt install $var
            num=$((num+1))
        done
    fi 
fi

# 安装Python3
if [ "$SET_PYTHON3_INSTALL" -eq 1 ];then
    prompt -x "Install Python3 and pip3..."
    doApt install python3
    doApt install python3-pip
fi

# 配置Python3源为清华大学镜像
if [ "$SET_PYTHON3_MIRROR" -eq 1 ];then
    prompt -x "Setup pip mirror "
    doApt install software-properties-common
    doApt install python3-software-properties
    doApt install python3-pip
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
elif [ "$SET_PYTHON3_MIRROR" -eq 0 ];then
    prompt -i "Pass pip mirror site setup."
else
    prompt -w "Setup customize pip mirror !"
    doApt install software-properties-common
    doApt install python3-software-properties
    doApt install python3-pip
    pip install -i $SET_PYTHON3_MIRROR -U
    pip config set global.index-url $SET_PYTHON3_MIRROR
    pip3 install -i $SET_PYTHON3_MIRROR pip -U
    pip3 config set global.index-url $SET_PYTHON3_MIRROR
fi


# 安装配置Git(配置User Email)
# 安装配置Git(配置User Email)
if [ "$SET_INSTALL_GIT" -eq 1 ];then
    prompt -x "Install Git"
    doApt install git
    if [ $? -eq 0 ];then
        git config --global user.name $SET_GIT_USER
        git config --global user.email $SET_GIT_EMAIL
    else
        prompt -e "Failed to install git"
        exit 2
    fi
fi

# 安装配置SSH
if [ "$SET_INSTALL_OPENSSH" -eq 1 ];then
    doApt install openssh-server
    if [ "$SET_ENABLE_SSH" -eq 1 ];then
        prompt -x "Enable sh.service"
        sudo systemctl enable ssh.service
    elif [ "$SET_ENABLE_SSH" -eq 0 ];then
        prompt -x "Disable sh.service"
        sudo systemctl disable ssh.service
    fi
fi
# 安装配置npm
if [ "$SET_INSTALL_NPM" -eq 1 ];then
    doApt install npm
    if [ "$SET_INSTALL_CNPM" -eq 1 ];then
        if ! [ -x "$(command -v cnpm)" ]; then
            prompt -x "Install CNPM"
            npm install cnpm -g --registry=https://r.npm.taobao.org
        fi
    fi
fi

# Nodejs
if [ "$SET_INSTALL_NODEJS" -eq 1 ];then
    doApt install nodejs
fi


# 安装配置Apache2
if [ "$SET_INSTALL_APACHE2" -eq 1 ];then
    prompt -x "安装Apache2"
    doApt install apache2
    prompt -m "配置Apache2 共享目录为 /home/HTML"
    addFolder /home/HTML
    prompt -x "设置/home/HTML读写权限为755"
    sudo chmod 755 /home/HTML
    if [ $? -eq 0 ];then
        backupFile /etc/apache2/apache2.conf
        prompt -x "修改Apache2配置文件中的共享目录为/home/HTML"
        sudo sed -i 's/\/var\/www\//\/home\/HTML\//g' /etc/apache2/apache2.conf
        sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/home\/HTML/g' /etc/apache2/sites-available/000-default.conf
        if [ "$SET_ENABLE_APACHE2" -eq 0 ];then
            prompt -x "禁用Apache2服务开机自启"
            sudo systemctl disable apache2.service
        elif [ "$SET_ENABLE_APACHE2" -eq 1 ];then
            prompt -x "配置Apache2服务开机自启"
            sudo systemctl enable apache2.service
        fi
    else
        prompt -e "Apache2似乎安装失败了。"
        quitThis
    fi
fi











# Y
echo -e "\e[1;32m
_________  .___ ____   ____.___ _________  _________  _________  _________  _________  
\_   ___ \ |   |\   \ /   /|   |\_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ 
/    \  \/ |   | \   Y   / |   |/    \  \/ /    \  \/ /    \  \/ /    \  \/ /    \  \/ 
\     \____|   |  \     /  |   |\     \____\     \____\     \____\     \____\     \____
 \______  /|___|   \___/   |___| \______  / \______  / \______  / \______  / \______  /
        \/                              \/         \/         \/         \/         \/ 
        "
# G
echo -e "\e[1;32m ————————————    感谢使用    ———————————— \e[0m"
