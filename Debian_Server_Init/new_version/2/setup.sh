: <<检查点二
新建用户
检查是否在sudo组中
是的话检查是否免密码
询问是否将当前用户加入sudo组, 是否sudo免密码（如果已经是sudoer且免密码则跳过）。
临时成为免密sudoer(必选)。
添加用户到sudo组。
设置用户sudo免密码。
卸载vim-tiny，安装vim-full
替换Bash为Zsh
添加/usr/sbin到环境变量
替换root用户shell配置文件
安装bash-completion
安装zsh-autosuggestions
检查点二
prompt -i "——————————  检查点二  ——————————"

source "cfg.sh"

# 新建用户 如果已经存在，不添加，直接配置该用户
if [ "$SET_USER" -eq 1 ];then
    prompt -x "Creating user $CURRENT_USER...."
    # 检测是否存在该用户
    egrep "^$CURRENT_USER" "/etc/passwd >/dev/null"
    if [ $? -eq 0 ]; then
        # 存在用户 
        prompt -e "Failed to add $CURRENT_USER. Username already exists! Continue with $CURRENT_USER"
    else
        # 不存在则新建
        encrypt_pass=$(perl -e 'print crypt($ARGV[0], "password")' $SET_USER_PASSWD)
        useradd -m -s /bin/zsh -G sudo -p $encrypt_pass $CURRENT_USER
        if [ $? -eq 0 ];then
            prompt -i "User has been added to system!"
        else
            echo "Failed to add a user!"
            exit 1
        fi
    fi
fi


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

prompt -i "__________________________________________________________"
prompt -i "系统信息: "
prompt -k "用户名：" "$CURRENT_USER"
prompt -k "终端：" "$CURRENT_SHELL"
prompt -k "是否为Sudo组成员：" "$is_sudoer"
prompt -k "Sudo是否免密码：" "$is_sudo_nopasswd"
prompt -k "家目录：" "$HOME_INDEX"
prompt -k "设置的主机名：" "$HOSTNAME"
prompt -i "__________________________________________________________"
prompt -e "以上信息如有错误，或者出现了-1，请按 Ctrl + c 中止运行。"


# 如果没有sudo免密码，临时加入。
# 这里之后才能使用quitThis
# 这里之后才能使用quitThis
# 这里之后才能使用quitThis
if [ "$IS_SUDO_NOPASSWD" -ne 1 ]; then
    beTempSudoer
    TEMPORARILY_SUDOER=1
fi


# 如果没有在sudo组,添加用户到sudo组
# 不是sudoer，要设置sudoer的
if [ "$IS_SUDOER" -eq 0 ] && [ "$SET_SUDOER" -eq 1 ]; then
    prompt -x "添加用户 $CURRENT_USER 到sudo组。"
    sudo usermod -a -G sudo $CURRENT_USER
    IS_SUDOER=1
fi

# 如果已经是sudoer，但没有免密码，先设置免密码
# 是sudoer的，但没有免密码的，要设置免密码的
if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ] && [ "$SET_SUDOER_NOPASSWD" -eq 1 ]; then
    prompt -x "设置用户 $CURRENT_USER sudo免密码"
    TEMPORARILY_SUDOER_STRING="$USER ALL=(ALL)NOPASSWD:ALL"
    doAsRoot "echo '$TEMPORARILY_SUDOER_STRING' >> /etc/sudoers"
    # 检查状态
    if [ $? -ne 0 ]; then
        prompt -e "sudo免密码似乎配置失败了"
        quitThis
    else
        cancelTempSudoer
        TEMPORARILY_SUDOER=0
    fi
fi


# 修改zshrc中用户名
# replace_username "$ZSHRC_CONFIG"
replace_placeholders_with_values "$ZSHRC_CONFIG"
# 去掉后面的.src
ZSHRC_CONFIG="${ZSHRC_CONFIG%.src}"


# 卸载vim-tiny，安装vim-full
if [ "$SET_VIM_TINY_TO_FULL" -eq 0 ];then
    prompt -m "保留vim-tiny"
elif [ "$SET_VIM_TINY_TO_FULL" -eq 1 ];then
    prompt -x "替换vim-tiny为vim-full"
    doApt remove vim-tiny
    doApt install vim
fi
# 替换Bash为Zsh
prompt -i "当前终端：$CURRENT_SHELL"
if [ "$CURRENT_SHELL" == "/bin/bash" ]; then
    shell_conf=".bashrc"
    if [ "$SET_BASH_TO_ZSH" -eq 1 ];then
        # 判断是否安装zsh
        if ! [ -x "$(command -v zsh)" ]; then
            prompt -i 'Error: Zsh is not installed.' >&2
            prompt -x "安装Zsh"
            doApt install zsh
        fi
        if ! [ -x "$(command -v zsh)" ]; then
            prompt -x "ZSH安装失败"
            quitThis
        else
            shell_conf=".zshrc"
            prompt -x "配置ZSHRC"
            cp "$ZSHRC_CONFIG" "/home/$CURRENT_USER/$shell_conf"
            prompt -x "为root用户和当前用户设置ZSH"
            sudo usermod -s /bin/zsh root
            sudo usermod -s /bin/zsh $CURRENT_USER
        fi
    elif [ "$SET_BASH_TO_ZSH" -eq 0 ];then
        prompt -m "保留原有SHELL"
    fi
elif [ "$CURRENT_SHELL" == "/bin/zsh" ];then
    # 如果使用zsh，则更改zsh配置
    shell_conf=".zshrc"
    if [ "$SET_ZSHRC" -eq 1 ];then
        backupFile "/home/$CURRENT_USER/$shell_conf"
        prompt -x "配置ZSHRC"
        cp "$ZSHRC_CONFIG" "/home/$CURRENT_USER/$shell_conf"
    elif [ "$SET_ZSHRC" -eq 0 ];then
      prompt -m "保留原有的ZSHRC配置"
    fi
fi
# 添加/usr/sbin到环境变量
if [ "$SET_REPLACE_ROOT_RC_FILE" -eq 0 ];then
    prompt -m "保留root用户SHELL配置"
elif [ "$SET_REPLACE_ROOT_RC_FILE" -eq 1 ];then
    prompt -x "替换root用户的SHELL配置文件"
    prompt -m "检查该变量是否已经添加…… "
    check_var="export PATH=\"\$PATH:/usr/sbin\""
    if cat /home/$CURRENT_USER/$shell_conf | grep "$check_var" > /dev/null
    then
        prompt -w "环境变量  $check_var  已存在,不执行添加。"
    else
        prompt -x "添加/usr/sbin到用户变量"
        echo "export PATH=\"\$PATH:/usr/sbin\"" >> /home/$CURRENT_USER/$shell_conf
    fi
fi
# 替换root用户的SHELL配置
if [ "$SET_REPLACE_ROOT_RC_FILE" -eq 0 ];then
    prompt -m "保留root用户SHELL配置"
elif [ "$SET_REPLACE_ROOT_RC_FILE" -eq 1 ];then
    backupFile "/root/$shell_conf"
    prompt -x "替换root用户的SHELL配置文件"
    sudo cp /home/$CURRENT_USER/$shell_conf /root/
fi
# 安装bash-completion
if [ "$SET_BASH_COMPLETION" -eq 1 ];then
    prompt -x "安装bash-completion"
    doApt install bash-completion
fi

# 安装zsh-autosuggestions
if [ "$SET_ZSH_AUTOSUGGESTIONS" -eq 1 ];then
    if [ "$shell_conf" == ".zshrc" ];then
        prompt -x "安装zsh-autosuggestions"
        doApt install zsh-syntax-highlighting
        doApt install zsh-autosuggestions
    else
        prompt -e "非ZSH，不安装zsh-autosuggestions"
    fi
fi
