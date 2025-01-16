#!/bin/bash
: <<!说明
这里是执行的配置
!说明

## 检查点一 ##==
# 使用的APT源 0:跳过 1:清华大学镜像源 2:清华大学Sid镜像源 3:你的源  Preset:3
SET_APT_SOURCE=0
#==== 自定义源请在检查的1文件夹中定义!
# 更新与安装是否不过问 Preset:1
SET_APT_RUN_WITHOUT_ASKING=1
# 是否禁用unattended-upgrades.service 0:不做处理 1:启用 2:禁用  Preset=0
SET_ENABLE_UNATTENDED_UPGRADE=0
# 是否在安装软件前更新整个系统 0:just apt update 1:apt dist-upgrade 2:apt upgrade   Preset:1
SET_APT_UPGRADE=1

## 检查点二 ##==
# Set to 1 will specify a user.User will be created if not exist.If set to 0, continue with root(是否指定某用户进行配置，否的话将以root用户继续)  Preset:1
SET_USER=1
# User Name in lower case(要新建的用户名-必须小写英文！) Preset="admin" SET_USER=1时生效
SET_USER_NAME="admin"
# User password(要新建的用户密码) Preset="passwd" SET_USER=1时生效
SET_USER_PASSWD="passwd"
# Set hostname(设置HostName) Preset=0
SET_HOST_NAME=0
# 是否加入sudo组 Preset:1
SET_SUDOER=1
# 是否设置sudo无需密码 Preset:1
SET_SUDOER_NOPASSWD=1
# 是否卸载vim-tiny，安装vim-full Preset:1
SET_VIM_TINY_TO_FULL=1
# 是否替换Bash为Zsh（包括root用户） Preset:1
SET_BASH_TO_ZSH=1
# 是否配置ZSHRC Preset:1
SET_ZSHRC=1
# 是否替换root用户的shell配置文件(如.bashrc)为用户配置文件 Preset:1
SET_REPLACE_ROOT_RC_FILE=1
# 添加/usr/sbin到环境变量 Preset=0
SET_ADD_SBIN_ENV=0
# 是否安装bash-completion Preset=1
SET_BASH_COMPLETION=1
# 是否安装zsh-autosuggestions Preset=1
SET_ZSH_AUTOSUGGESTIONS=1

## 检查点三 ##==
# 设置家目录文件夹(Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service)
SET_BASE_HOME=1
# 是否自定义一个systemctl服务(customize-autorun) Preset=1
SET_SYSTEMCTL_SERVICE=1
# 配置启用NetworkManager、安装net-tools Preset=1
SET_NETWORK_MANAGER=1
# 配置GRUB网卡默认命名方式 传统的 ethX 名称（例如 eth0, eth1）(注意：启用此选项可能导致SET_WIRED_ALLOW_HOTPLUG失效) Preset=0
SET_GRUB_NETCARD_NAMING=0
# Set hostname(设置HostName) Preset=0
SET_HOST_NAME=0
# Set locales(If you do not need this, just set 0) (设置语言支持，不需要请设置为0) Preset="en_US.UTF-8 UTF-8"
SET_LOCALES="en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
"
# Set time zone (zoneinfo file path)(设置时间支持) Preset=0
# e.g.:Shanghai China,You need to set this: /usr/share/zoneinfo/Asia/Shanghai
SET_TIME_ZONE=0
# Set tty1 auto-login (设置TTY1自动登录) Preset=1
SET_TTY_AUTOLOGIN=1

## 检查点四 ##==
# 从APT源安装常用软件
# 是否从APT源安装常用软件 Preset=1
SET_APT_INSTALL=1
: <<注释
有几个预选的安装列表供参考:
0.自定义列表
1.轻便安装
2.部分安装
3.全部安装
Preset=1
注释
SET_APT_INSTALL_LIST_INDEX=1
# 警告：Debian 12中 pip install可能破坏系统稳定性！谨慎使用
# 安装Python3 Preset=1
SET_PYTHON3_INSTALL=1
# 配置Python3源为清华大学镜像 Preset=0
SET_PYTHON3_MIRROR=0
# 配置Python3全局虚拟环境（Debian12中无法直接使用pip了） Preset=1
SET_PYTHON3_VENV=1
# 安装配置git Preset=1
SET_INSTALL_GIT=1
# Git用户名、邮箱地址 默认$CURRENT_USER & $CURRENT_USER@$HOST
SET_GIT_USER=0
SET_GIT_EMAIL=0
# 安装配置ssh Preset=1
SET_INSTALL_OPENSSH=1
# SSH开机是否自启 Preset=0 默认禁用
SET_ENABLE_SSH=1
# 安装配置npm Preset=0
SET_INSTALL_NPM=0
# 是否安装Nodejs(注意：nodejs来源于apt仓库！) Preset=0
SET_INSTALL_NODEJS=0
# 是否安装CNPM Preset=0
SET_INSTALL_CNPM=0
# 是否安装Hexo Preset=0
SET_INSTALL_HEXO=0

#### 下列软件安装时间较长，故放在最后安装
# 是否安装docker-ce
SET_INSTALL_DOCKER_CE=0
# 是否重装docker？
SET_DOCKER_PURGE_REINSTALL=1
# Manage Docker as a non-root user?
SET_DOCKER_NON_ROOT=0
# 设置Docker-ce仓库来源 0:官方 1:清华大学镜像仓库 Preset：1
SET_DOCKER_CE_REPO=1
# 是否设置Docker-ce开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_DOCKER_CE=0

## 检查点五 ##==
# Install http server(安装HTTP服务) [0:No 1:nginx 2:apache2] Preset=1
SET_INSTALL_HTTP_SERVER=1
# 设置网站根目录 Preset=0 0指的是默认~/nginx/ 其他请指定
SET_HTTP_SERVER_ROOT=0
# Enable http server (允许开机自启) Preset=1
SET_ENABLE_HTTP_SERVICE=1
# Disable default site and enable https site (禁用默认网页，启用https网页。) Preset=0
# 使用Let's Encrypt的用户请使用HTTP站点
# HTTPS证书默认 /etc/ssl/changeSET_SERVER_NAME.pem
SET_ENABLE_HTTPS_SITE=0
# Set server domain (设置域名) Preset=localhost
SET_SERVER_NAME=localhost
# If NGINX: set ~/nginx/res passwd (如果是nginx，配置~/nginx/res的访问用户、密码) Preset:default nginxLogin
SET_NGINX_RES_USER=default
SET_NGINX_RES_PASSWD=nginxLogin
# If APACHE Deny access /usr/share (配置禁止访问/usr/share目录) Preset=0
SET_APACHE_DENY_USR_SHARE=0
# 是否安装PHP（包括php fpm） Preset=1
SET_INSTALL_PHP=1
# 是否指定PHP运行端口 Preset=0
SET_PHP_FPM_PORT=0
# 是否设置php fpm开机自启,默认禁用 Preset=0
SET_PHP_FPM_ENABLE=1

## 检查点六 ##
# 配置SSH Key Preset=1
SET_CONFIG_SSH_KEY=1
# 是否生成新的SSH Key 0:新的密钥 1:从文件夹导入现有密钥 2:从文本导入现有密钥 Preset=0
SET_SSH_KEY_SOURCE=0
# 新生成的、或者导入文本生成的SSH密钥名称 Preset=id_rsa
SET_SSH_KEY_NAME=id_rsa
# 新生成的SSH密钥密码 Preset=""
SET_NEW_SSH_KEY_PASSWD=""
# 新密钥的备注 默认："A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian11_GNOME_Deploy_Script" Preset=0 （0就是默认备注！）
SET_SSH_KEY_COMMENT=0
# 存放已存在的SSH密钥文件夹名称(SET_SSH_KEY_SOURCE=1时有效) 1:从文件夹导入
SET_EXISTED_SSH_KEY_SRC=SSH_KEY
# SSH 密钥文本 (SET_SSH_KEY_SOURCE=2时有效)2:从文本导入
# 私钥
SET_SSH_KEY_PRIVATE_TEXT=""
# 公钥
SET_SSH_KEY_PUBLIC_TEXT=""

## 检查点七(谨慎！可能弄坏您的应用软件) ##==

## 检查点八 ##
# 是否配置Shorewall防火墙(但是需要手动启用) Preset=1
SET_SHOREWALL_SETTING=1

###
# 是否禁用第三方软件仓库更新(提升apt体验) Preset=1
SET_DISABLE_THIRD_PARTY_REPO=1
# 是否启用 os-prober -> 自Debian 12 开始，GRUB检测其他系统的 os-prober 被禁用了。0:不处理 1:启用 2:禁用 Preset=0
SET_ENABLE_GRUB_OS_PROBER=0
# 最后一步 设置用户目录所属 Preset=1
SET_USER_HOME=1

############################################################################
#### 默认变量赋值
# 获取当前用户名和家目录 root 和 /root (如果有指定会在下面被修改，这里只是避免出现Null情况)
# 注意:CURRENT_USER可以被指定
CURRENT_USER="$USER"
HOME_INDEX="$HOME"
# 设置用户目录(如果有指定)
if [ "$SET_USER" -eq 1 ]; then
    CURRENT_USER="$SET_USER_NAME"
    HOME_INDEX="/home/$SET_USER_NAME"
else
    CURRENT_USER=root
    HOME_INDEX="/root"
fi

# 初始化主机名
if [ "$SET_HOST_NAME" == 0 ]; then
    # 如果没有配置主机名
    if [ "$HOSTNAME" == "" ]; then
        HOSTNAME="$HOST"
    fi
else
    HOSTNAME="$SET_HOST_NAME"
fi

# Git
if [ "$SET_GIT_USER" -eq 0 ]; then
    SET_GIT_USER=$CURRENT_USER
fi
if [ "$SET_GIT_EMAIL" -eq 0 ]; then
    SET_GIT_EMAIL=$CURRENT_USER@$HOSTNAME
fi
# SSH
if [ "$SET_SSH_KEY_COMMENT" -eq 0 ]; then
    SET_SSH_KEY_COMMENT="A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian 11_GNOME_Deploy_Script"
fi
# HTTP ROOT
if [ "$SET_HTTP_SERVER_ROOT" -eq 0 ]; then
    if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ]; then
        SET_HTTP_SERVER_ROOT="/home/$CURRENT_USER/nginx"
    elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ]; then
        SET_HTTP_SERVER_ROOT="/home/$CURRENT_USER/apache2"
    else
        SET_HTTP_SERVER_ROOT="/home/HTML"
    fi
fi
