: <<检查点六
配置SSH Key
配置Shorewall防火墙
检查点六

# 配置SSH Key
if [ "$SET_CONFIG_SSH_KEY" -eq 1 ]; then
    mkdir -p "/home/$CURRENT_USER/.ssh"
    if [ -f "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME" ] | [ -f "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub" ]; then
        prompt -e "/home/$CURRENT_USER/.ssh/似乎已经存在 "$SET_SSH_KEY_NAME" 的SSH Key,跳过配置。"
    else
        if [ "$SET_SSH_KEY_SOURCE" -eq 0 ]; then
            prompt -x "生成新的SSH Key 密码:"
            ssh-keygen -t rsa -N "$SET_NEW_SSH_KEY_PASSWD" -C "$SET_SSH_KEY_COMMENT" -f /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME
        elif [ "$SET_SSH_KEY_SOURCE" -eq 1 ]; then
            prompt -x "将存在的SSH Key从 $SET_EXISTED_SSH_KEY_SRC 移动到 /home/$CURRENT_USER/.ssh/"
            sudo chmod 600 $SET_EXISTED_SSH_KEY_SRC/*
            mv $SET_EXISTED_SSH_KEY_SRC /home/$CURRENT_USER/.ssh/
            # 设置ssh密钥
            eval "$(ssh-agent -s)"
            ssh-add
        elif [ "$SET_SSH_KEY_SOURCE" -eq 2 ]; then
            prompt -x "从文本导入SSH Key到 /home/$CURRENT_USER/.ssh/"
            echo $SET_SSH_KEY_PRIVATE_TEXT >/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME
            echo $SET_SSH_KEY_PUBLIC_TEXT >/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub
            # 设置权限
            sudo chmod 600 /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME
            sudo chmod 600 /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub
            # 设置ssh密钥
            eval "$(ssh-agent -s)"
            ssh-add
        fi
    fi
fi

# 配置shorewall防火墙
if [ "$SET_SHOREWALL_SETTING" -eq 1 ]; then
    # 检查是否安装了shorewall
    if command -v shorewall &>/dev/null; then
        prompt -i "Shorewall is installed."
    else
        prompt -x "Shorewall is not installed, installing..."
        if ! doApt install shorewall; then
            prompt -e "Failed to install Shorewall. Please check your package manager."
            exit 1
        fi
    fi
    # 安装完shorewall后开始配置
    backupFile "/etc/shorewall/"
    sudo cp SW_CONF/* /etc/shorewall/
    prompt -w "为防止意外，请手动修改、启用Shorewall。"
fi

