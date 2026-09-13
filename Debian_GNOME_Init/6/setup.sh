#!/bin/bash
:<<检查点六
配置SSH Key
配置fail2ban SSH 爆破防护
检查点六

# 配置SSH Key
if [ "$SET_CONFIG_SSH_KEY" -eq 1 ];then
    sudo mkdir -p "/home/$CURRENT_USER/.ssh"
    sudo chown "$CURRENT_USER:$CURRENT_USER" "/home/$CURRENT_USER/.ssh"
    if [ -f "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME" ] || [ -f "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub" ];then
        prompt -e "/home/$CURRENT_USER/.ssh/似乎已经存在 "$SET_SSH_KEY_NAME" 的SSH Key,跳过配置。"
    else
        if [ "$SET_SSH_KEY_SOURCE" -eq 0 ];then
            prompt -x "生成新的SSH Key 密码:"
            ssh-keygen -t rsa -N "$SET_NEW_SSH_KEY_PASSWD" -C "$SET_SSH_KEY_COMMENT" -f "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME"
        elif [ "$SET_SSH_KEY_SOURCE" -eq 1 ];then
            prompt -x "将存在的SSH Key从 $SET_EXISTED_SSH_KEY_SRC 移动到 /home/$CURRENT_USER/.ssh/"
            sudo chmod 600 "$SET_EXISTED_SSH_KEY_SRC"/*
            mv "$SET_EXISTED_SSH_KEY_SRC"/* "/home/$CURRENT_USER/.ssh/"
            # 设置ssh密钥
            eval "$(ssh-agent -s)"
            ssh-add
        elif [ "$SET_SSH_KEY_SOURCE" -eq 2 ];then
            prompt -x "从文本导入SSH Key到 /home/$CURRENT_USER/.ssh/"
            printf '%s' "$SET_SSH_KEY_PRIVATE_TEXT" > "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME"
            printf '%s' "$SET_SSH_KEY_PUBLIC_TEXT" > "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub"
            # 设置权限
            sudo chmod 600 /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME
            sudo chmod 600 /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub
            # 设置ssh密钥
            eval "$(ssh-agent -s)"
            ssh-add
        fi
    fi
fi

# 配置 fail2ban SSH 爆破防护
if [ "$SET_FAIL2BAN_SSH" -eq 1 ]; then
    # 检查是否安装了fail2ban
    if command -v fail2ban-client &>/dev/null; then
        prompt -i "fail2ban is installed."
    else
        prompt -x "fail2ban is not installed, installing..."
        if ! doApt install fail2ban; then
            prompt -e "Failed to install fail2ban. Please check your package manager."
            exit 1
        fi
    fi
    # 写入 SSH 防护配置（始终覆盖；覆盖前备份）
    backupFile /etc/fail2ban/jail.local
    prompt -x "写入 /etc/fail2ban/jail.local（sshd 爆破防护）"
    sudo tee /etc/fail2ban/jail.local >/dev/null <<EOF
# 由部署脚本检查点六生成。保留 SSH 密码登录（不设 PasswordAuthentication no），靠封 IP 防爆破。
# backend=systemd：Debian 13 默认无 rsyslog/auth.log，sshd 日志走 journald（与 trixie fail2ban 默认一致，显式写明以防上游变动）。
[sshd]
enabled = true
backend = systemd
findtime = ${SET_FAIL2BAN_FINDTIME}
maxretry = ${SET_FAIL2BAN_MAXRETRY}
bantime = ${SET_FAIL2BAN_BANTIME}
EOF
    # 检查配置 → 开机自启并立即启动 → 重新加载
    if sudo fail2ban-client -t; then
        sudo systemctl enable --now fail2ban
        sudo fail2ban-client reload
        prompt -s "fail2ban sshd 防护已启用：${SET_FAIL2BAN_FINDTIME} 内失败 ${SET_FAIL2BAN_MAXRETRY} 次封 ${SET_FAIL2BAN_BANTIME}"
        prompt -i "查看封禁： sudo fail2ban-client status sshd ；解封： sudo fail2ban-client set sshd unbanip IP"
    else
        prompt -e "fail2ban 配置检查未通过，请手动检查 /etc/fail2ban/jail.local 后 sudo fail2ban-client reload"
    fi
fi