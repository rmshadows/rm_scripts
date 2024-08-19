#!/bin/bash
#
# 要求非root用户
# 要求sudo
# 详情见readme

# 服务名
SRV_NAME=php-frp
# php fpm监听端口（默认使用fastcgi_pass unix:/run/php/php7.4-fpm.sock; ，设置为0。也可以使用端口号，如：9000）
LISTEN_PORT=0

NGINX_CONF="
    location / {
        # proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        # proxy_set_header X-Real-IP \$remote_addr;
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
    }
"

## 控制台颜色输出
# 红色：警告、重点
# 黄色：警告、一般打印
# 绿色：执行日志
# 蓝色、白色：常规信息
# 颜色colors
CDEF=" \033[0m"      # default color
CCIN=" \033[0;36m"   # info color
CGSC=" \033[0;32m"   # success color
CRER=" \033[0;31m"   # error color
CWAR=" \033[0;33m"   # warning color
b_CDEF=" \033[1;37m" # bold default color
b_CCIN=" \033[1;36m" # bold info color
b_CGSC=" \033[1;32m" # bold success color
b_CRER=" \033[1;31m" # bold error color
b_CWAR=" \033[1;33m"
# echo like ...  with  flag type  and display message  colors
# -s 绿
# -e 红
# -w 黄
# -i 蓝
prompt() {
    case ${1} in
    "-s" | "--success")
        echo -e "${b_CGSC}${@/-s/}${CDEF}"
        ;; # print success message
    "-x" | "--exec")
        echo -e "Exec：${b_CGSC}${@/-x/}${CDEF}"
        ;; # print exec message
    "-e" | "--error")
        echo -e "${b_CRER}${@/-e/}${CDEF}"
        ;; # print error message
    "-w" | "--warning")
        echo -e "${b_CWAR}${@/-w/}${CDEF}"
        ;; # print warning message
    "-i" | "--info")
        echo -e "${b_CCIN}${@/-i/}${CDEF}"
        ;; # print info message
    "-m" | "--msg")
        echo -e "Info：${b_CCIN}${@/-m/}${CDEF}"
        ;;                                                 # print iinfo message
    "-k" | "--kv")                                         # 三个参数
        echo -e "${b_CCIN} ${2} ${b_CWAR} ${3} ${CDEF}" ;; # print success message
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

sudo ls >/dev/null
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
if groups | grep sudo >/dev/null; then
    # 是sudo组
    IS_SUDOER=1
    is_sudoer="TRUE"
    # 检查是否免密码sudo 括号得注释
    check_var="ALL=(ALL)NOPASSWD:ALL"
    # cat /etc/sudoers
    if sudo cat /etc/sudoers | grep ^$USER | grep $check_var >/dev/null; then
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
onSigint() {
    prompt -w "捕获到中断信号..."
    onExit
    exit 1
}

# 正常退出需要执行的
onExit() {
    # 临时加入sudoer，退出时清除
    if [ $TEMPORARILY_SUDOER -eq 1 ]; then
        prompt -x "Clean temp sudoer no-passwd..."
        # sudo sed -i "s/$TEMPORARILY_SUDOER_STRING/ /g" /etc/sudoers
        # 获取最后一行
        tail_sudo=$(sudo tail -n 1 /etc/sudoers)
        if [ "$tail_sudo" = "$TEMPORARILY_SUDOER_STRING" ] >/dev/null; then
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
quitThis() {
    onExit
    exit
}
if [ "$IS_SUDOER" -eq 0 ]; then
    prompt -e "Not a sudoer!"
    exit 1
fi
# 如果是sudoer，但没有免密码，临时配置
if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ]; then
    echo "$TEMPORARILY_SUDOER_STRING" | sudo tee -a /etc/sudoers
    TEMPORARILY_SUDOER=1
fi

##############################################################
# 获取php-fpm版本
# php-fpm:
r=$(whereis php-fpm) >/dev/null
# echo $r
PF_VERSION=${r#*\/php-fpm}
# echo $PF_VERSION
php-fpm$PF_VERSION -v >/dev/null
if [ "$?" -ne 0 ]; then
    prompt -e "PHP-FPM not found!"
    sudo apt install php-fpm
    if [ "$?" -ne 0 ]; then
        prompt -e "APT: PHP-FPM install seems incorrect!"
        quitThis
    fi
fi

r=$(whereis php-fpm)
# echo $r
PF_VERSION=${r#*\/php-fpm}
# echo $PF_VERSION
php-fpm$PF_VERSION -v >/dev/null
if [ "$?" -ne 0 ]; then
    prompt -e "Check PHP-FPM installation!"
    quitThis
fi

# 检查命令
# if ! [ -x "$(command -v php-fpm)" ]; then
#    prompt -e "Python3 not found! Install it first!"
#    quitThis
# fi

if [ "$LISTEN_PORT" -ne 0 ]; then
    # 修改端口号
    PFW_CONF="/etc/php/$PF_VERSION/fpm/pool.d/www.conf"

    # listen = /run/php/php7.4-fpm.sock
    if [ -f "$PFW_CONF" ]; then
        prompt -m "检查该变量是否已经添加…… "
        check_var="listen = /run/php/php$PF_VERSION-fpm.sock"
        if cat "$PFW_CONF" | grep "^$check_var" >/dev/null; then
            prompt -x "开始修改端口号"
            pfwo=$(cat "$PFW_CONF" | grep "^listen ")
            # echo "$pfwo"
            # 注释原来的
            sudo sed -i "s?$pfwo?# $pfwo \nlisten = $LISTEN_PORT ?g" "$PFW_CONF"
            sudo systemctl restart php$PF_VERSION-fpm.service
        else
            check_var="listen = $LISTEN_PORT"
            if cat "$PFW_CONF" | grep "$check_var" >/dev/null; then
                prompt -m "No change."
            else
                prompt -w "WARN: Manually edit $PFW_CONF yourself(Set “listen = $LISTEN_PORT” ). "
            fi
        fi
    else
        prompt -e "$PFW_CONF not found!"
        quitThis
    fi
fi

prompt -i "\n  Check manully and setting up nginx by yourself."
prompt -i "========================================================"
prompt -s "For Nginx:"
echo "$NGINX_CONF"
prompt -i "========================================================"
onExit
