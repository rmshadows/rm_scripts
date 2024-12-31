: <<检查点二
卸载vim-tiny，安装vim-full
替换Bash为Zsh
添加/usr/sbin到环境变量
替换root用户shell配置文件
安装bash-completion
安装zsh-autosuggestions
检查点二
prompt -i "——————————  检查点二  ——————————"

source "cfg.sh"
# 修改zshrc中用户名
replace_username "$ZSHRC_CONFIG"
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
