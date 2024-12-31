#!/bin/bash
: <<!说明
此脚本获取sudo
!说明

: <<!预先检查
获取当前用户名
获取root密码
检查root密码
检查是否在sudo组中
是的话检查是否免密码
检查是否GNOME
确认运行
!预先检查
# 检查是否在sudo组中 0 false 1 true
IS_SUDOER=-1
is_sudoer=-1
IS_SUDO_NOPASSWD=-1
is_sudo_nopasswd=-1
# 检查是否在sudo组
if groups | grep sudo >/dev/null; then
    # 是sudo组
    IS_SUDOER=1
    is_sudoer="TRUE"
    # 检查是否免密码sudo 括号得注释
    check_var="ALL=\(ALL\)NOPASSWD:ALL"
    if doAsRoot "cat '/etc/sudoers' | grep ^$CURRENT_USER | grep $check_var > /dev/null"; then
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

# 检查是否是GNOME，不是则退出
IS_GNOME_DE=-1
check_var="gnome"
if echo $DESKTOP_SESSION | grep $check_var >/dev/null; then
    IS_GNOME_DE="TRUE"
else
    IS_GNOME_DE="FALSE"
    prompt -e "警告：不是GNOME桌面环境，慎用。"
    exit 1
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

### 这里是确认运行的模块
comfirm "\e[1;31m 您已知晓该一键部署脚本的内容、作用、使用方法以及对您的计算机可能造成的潜在的危害「如果你不知道你在做什么，请直接回车谢谢」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ]; then
    prompt -m "开始部署……"
elif [ $choice == 2 ]; then
    prompt -w "感谢您的关注！——  https://github.com/rmshadows"
    exit 0
fi

# 如果没有sudo免密码，临时加入。
# 这里之后才能使用quitThis
# 这里之后才能使用quitThis
# 这里之后才能使用quitThis
if [ "$IS_SUDO_NOPASSWD" -ne 1 ]; then
    beTempSudoer
    TEMPORARILY_SUDOER=1
fi
