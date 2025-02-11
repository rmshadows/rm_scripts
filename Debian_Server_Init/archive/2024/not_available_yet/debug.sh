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

## Check 1 检查点一：
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

## Check 2 检查点二：
# Set to 1 will specify a user.User will be created if not exist.If set to 0, continue with root(是否指定某用户进行配置，否的话将以root用户继续)  Preset:1
SET_USER=1
# User Name(要新建的用户名) Preset="admin"
SET_USER_NAME="admin"
# User password(要新建的用户密码) Preset="passwd"
SET_USER_PASSWD="passwd"
# User should be a sudoer?(是否加入sudo用户组) Preset:1
SET_SUDOER=1
# User should run `sudo` without passwd(是否设置sudo无需密码) Preset:1
SET_SUDOER_NOPASSWD=0

### 脚本变量
# Root用户UID
ROOT_UID=0
# 当前 Shell名称
CURRENT_SHELL=$SHELL

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
      echo -e "日志：${b_CGSC}${@/-x/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-m"|"--msg")
      echo -e "信息：${b_CCIN}${@/-m/}${CDEF}";;          # print iinfo message
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
            prompt -x "(sudo)正在备份 $1 文件到 $1.newbak (覆盖) "
            cp $1 $1.newbak
        else
            # 没有bak文件，创建备份
            prompt -x "(sudo)正在备份 $1 文件到 $1.bak"
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
┃使用方法：                              ┃
┃\e[1;33m1.首先给予运行权限：                    \e[1;32m┃
┃\e[1;34msudo chmod +x 「这个脚本的文件名」      \e[1;32m┃
┃\e[1;33m2.运行脚本：                            \e[1;32m┃
┃\e[1;34msudo 「脚本的路径(包括脚本文件名)」     \e[1;32m┃
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

##########################################################################################
CURRENT_USER_SET="ryan"

SET_UFW_ALLOW="22 80 443"


# 端口列表
    idxl=($SET_UFW_ALLOW)
    idxlen=${#idxl[@]}
    # echo $idxlen
    if [ $idxlen -eq 0 ];then
        prompt -w "Are you sure to have UFW not allow anything ?!...ENEN SSH PORT???!"
        exit 1
    else
        for var in ${idxl[@]}
        do
            prompt -m "正在安装第 $num 个软件包: $var。"
        done
    fi











