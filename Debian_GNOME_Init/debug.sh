#!/bin/bash



:<<!说明
Version：0.0.1
预设参数（在这里修改预设参数, 谢谢）
注意：如果没有注释，默认0 为否 1 为是。
!说明
# root用户密码
ROOT_PASSWD=""
## 检查点一：
# 使用的APT源
:<<!
0:跳过
1:清华大学镜像源
2:清华大学Sid镜像源
!
SET_APT_SOURCE=0
# 更新与安装是否不过问
SET_APT_UPGRADE_WITHOUT_ASKING=1
# 是否在安装软件前更新整个系统
:<<!
0:just apt update
1:apt dist-upgrade
2:apt upgrade
!
SET_APT_UPGRADE=0
# 是否加入sudo组
SET_SUDOER=0
# 是否设置sudo无需密码
SET_SUDOER_NOPASSWD=0
## 检查点二：
# 是否卸载vim-tiny，安装vim-full
SET_VIM_TINY_TO_FULL=1


#################################################################################

### 脚本变量
# Root用户UID
ROOT_UID=0
# 当前 Shell名称
CURRENT_SHELL=$SHELL
# 是否临时加入sudoer
TEMPORARILY_SUDOER=0
# 第一次运行DoAsRoot
FIRST_DO_AS_ROOT=1

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

# 如果用户按下Ctrl+c
trap "onSigint" SIGINT

# 程序中断处理方法,包含正常退出该执行的代码
onSigint () {
    prompt -w "捕获到中断信号..."
    onExit # TODO
    exit 1
}

# 正常退出需要执行的
onExit () {
    # 临时加入sudoer，退出时清除
    if [ $TEMPORARILY_SUDOER -eq 1 ] ;then
        prompt -x "清除临时sudoer免密权限。"
        # sudo sed -i "s/$TEMPORARILY_SUDOER_STRING/ /g" /etc/sudoers
        # 获取最后一行
        tail_sudo=`sudo tail -n 1 /etc/sudoers`
        if [ "$tail_sudo" = "$TEMPORARILY_SUDOER_STRING" ] > /dev/null ;then
            # 删除最后一行
            sudo sed -i '$d' /etc/sudoers
        else
            # 一般不会出现这个情况吧。。
            prompt -e "警告：未知错误，请手动删除 $TEMPORARILY_SUDOER_STRING "
            exit 1
        fi
    fi
}


# 以root身份运行
doAsRoot () {
# 第一次运行需要询问root密码
if [ "$FIRST_DO_AS_ROOT" -eq 1 ];then
    if [ "$ROOT_PASSWD" == "" ] && [ "$IS_SUDOER" -ne 1 ] ;then
        prompt -w "未在脚本里定义root用户密码，请输入root用户密码: "
        read -r input
        ROOT_PASSWD=$input
    fi
    # 检查密码
    checkRootPasswd
    FIRST_DO_AS_ROOT=0
fi
su - root <<!>/dev/null 2>&1
$ROOT_PASSWD
echo " Exec $1 as root"
$1
!
}

# 检查root密码是否正确
checkRootPasswd () {
su - root <<! >/dev/null 2>/dev/null
$ROOT_PASSWD
pwd
!
# echo $?
if [ "$?" -ne 0 ] ;then
    prompt -e "Root 用户密码不正确！"
    exit 1
fi
}

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
    # 如果有bak备份文件 ，生成newbak
    if [ -f "$1.bak" ];then
        # bak文件存在
        prompt -x "(sudo)正在备份 $1 文件到 $1.newbak (覆盖) "
        sudo cp $1 $1.newbak
    else
        # 没有bak文件，创建备份
        prompt -x "(sudo)正在备份 $1 文件到 $1.bak"
        sudo cp $1 $1.bak
    fi
} 

# 执行apt命令
doApt () {
    if [ "$1" = "install" ];then
        if [ "$SET_APT_UPGRADE_WITHOUT_ASKING" -eq 0 ];then
            sudo apt-get $@
        elif [ "$SET_APT_UPGRADE_WITHOUT_ASKING" -eq 1 ];then
            sudo apt-get $@ -y
        fi
    else
        sudo apt $@
    fi
}

addFolder () {
    if [ $# -ne 1 ];then
        prompt -e "addFolder () 只能有一个参数"
        exit 1
    fi
    if ! [ -d $1 ];then
        prompt -x "新建文件夹$1 "
        mkdir $1
    fi
}

CURRENT_USER=$USER



#######################################################################
if ! [ -x "$(command -v virtualboxx)" ]; then
        prompt -m "检查是否为Sid源"
        is_debian_sid=0
        #sid_var1="debian/ sid main"
        #sid_var2="debian sid main"
        sid_var1="kali kali-rolling main"
        sid_var2="kali/ kali-rolling main"
        if sudo cat '/etc/apt/sources.list' | grep "$sid_var1"
        then
            is_debian_sid=1
        fi
        if sudo cat '/etc/apt/sources.list' | grep "$sid_var2"
        then
            is_debian_sid=1
        fi
        if [ "$is_debian_sid" -eq 1 ];then
            prompt -m "检测到使用的是Debian sid源，直接从源安装"
        else
            if [ 0 -eq 0 ];then
                prompt -m "不是sid源，添加官方仓库"
            elif [ 1 -eq 1 ];then
                prompt -m "不是sid源，添加清华大学镜像仓库"
            fi
        fi
    else
        prompt -m "您可能已经安装了VirtualBox"
    fi







