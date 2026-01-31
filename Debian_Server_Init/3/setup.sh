:<<检查点三
配置家目录文件夹
配置自定义的systemtl服务
配置启用NetworkManager、安装net-tools
配置GRUB网卡默认命名方式
配置主机名
配置语言支持
配置时区
设置TTY1自动登录
检查点三


# 修改customize-autorun.service中用户名 生成customize-autorun.service
# replace_username "customize_systemd_service/customize-autorun.service.src"
replace_placeholders_with_values "customize_systemd_service/customize-autorun.service.src"

prompt -i "——————————  检查点三  ——————————"

# 配置家文件夹
# 添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）；
if [ "$SET_BASE_HOME" -eq 1 ];then
    prompt -x "配置主目录文件夹"
    addFolder "$HOME_INDEX/Data" # 数据
    addFolder "$HOME_INDEX/Applications" # 存放应用
    addFolder "$HOME_INDEX/Applications/app_bak" # 存放应用备份副本
    addFolder "$HOME_INDEX/Temp" # 临时
    addFolder "$HOME_INDEX/Workplace" # 工作区
    addFolder "$HOME_INDEX/Services" # 服务
    addFolder "$HOME_INDEX/Logs" # 日志
    # 生成脚本，用于安装服务
    echo "#!/bin/bash
sudo cp *.service /lib/systemd/system/
sudo systemctl daemon-reload
" > "$HOME_INDEX/Services/Install_Services.sh"
    chmod +x "$HOME_INDEX/Services/Install_Services.sh"
    # sudo chown $CURRENT_USER -hR $HOME_INDEX
fi


# 配置自定义的systemtl服务
if [ "$SET_SYSTEMCTL_SERVICE" -eq 1 ];then
    prompt -x "配置自定义的Systemctl服务"
    addFolder /home/$CURRENT_USER/.$CURRENT_USER/
    addFolder /home/$CURRENT_USER/.$CURRENT_USER/scripts/
    prompt -x "复制到 /home/$CURRENT_USER/.$CURRENT_USER/scripts/autorun.sh 脚本"
    cp "customize_systemd_service/autorun.sh" "/home/$CURRENT_USER/.$CURRENT_USER/scripts/autorun.sh"
    sudo chmod +x /home/$CURRENT_USER/.$CURRENT_USER/scripts/autorun.sh
    
    prompt -x "复制 /lib/systemd/system/customize-autorun.service 服务"
    if ! [ -f /lib/systemd/system/customize-autorun.service ];then
        sudo cp "customize_systemd_service/customize-autorun.service" "/lib/systemd/system/customize-autorun.service"
    fi
fi


# 配置启用NetworkManager、安装net-tools
if [ "$SET_NETWORK_MANAGER" -eq 1 ];then
    prompt -x "配置启用NetworkManager"
    prompt -m "检查NetworkManager /etc/NetworkManager/NetworkManager.conf 是否有激活"
    check_var="managed=true"
    if sudo cat '/etc/NetworkManager/NetworkManager.conf' | grep "$check_var" > /dev/null
    then
        echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
        sudo cat /etc/NetworkManager/NetworkManager.conf
        prompt -w "您的 NetworkManager 似乎已经启用（如上所列），不做处理。"
    else
        prompt -x "启用NetworkManager"
        sudo sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
        prompt -m "重启NetworkManager.service"
        sudo systemctl enable NetworkManager.service 
        sudo systemctl restart NetworkManager.service
    fi
    prompt -x "安装Net-tools"
    doApt install net-tools
fi


# 配置GRUB无线网卡默认命名方式
if [ "$SET_GRUB_NETCARD_NAMING" -eq 1 ];then
    prompt -x "配置GRUB网卡默认命名方式"
    prompt -m "检查该变量是否已经添加…… "
    check_var="GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\""
    if cat /etc/default/grub | grep "$check_var" > /dev/null
    then
        prompt -w "您似乎已经配置过了，本次不执行添加。"
    else
        backupFile /etc/default/grub
        prompt -x "添加 GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\" 到 /etc/default/grub文件中"
        sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
        prompt -x "更新GRUB"
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi


# 设置主机名
if [ -n "$SET_HOST_NAME" ] && [ "$SET_HOST_NAME" != "0" ]; then
    prompt -x "Setup hostname"
    echo "$HOSTNAME" > /etc/hostname
    check_var="127.0.1.1"
    # 获取行号
    idx=$(cat /etc/hosts | grep -n ^$check_var | gawk '{print $1}' FS=":")
    # 找到的Index
    idxl=($idx)
    idxlen=${#idxl[@]}  
    # echo $idxlen
    # 127.0.1.1 vultr.guest vultr xxx
    if [ $idxlen -eq 1 ];then
        # 获取旧行
        line=$(awk "NR==$idx" /etc/hosts)
        # 拼
        I_STRING="$line\t$HOSTNAME"
        # 删除行
        sed -i "$idx d" /etc/hosts
        # 在前面插入
        sed -i "$idx i $I_STRING" /etc/hosts
    elif [ $idxlen -eq 0 ];then
        prompt -w "Setting not found in /etc/hosts!"
        I_STRING="127.0.1.1	$HOSTNAME"
        echo "$I_STRING" >> /etc/hosts
    else
        prompt -e "Find duplicate user setting 127.0.1.1 in /etc/hosts! Check manually!"
        exit 1
    fi
fi

# 设置语言支持
if ! [ "$SET_LOCALES" == 0 ];then
    check_var=$SET_LOCALES
    if cat '/etc/locale.gen' | grep "$check_var" > /dev/null ;then
        prompt -w "Locales may SET! Pass!"
    else
        prompt -x "Setup locales..."
        backupFile /etc/locale.gen
        echo "$SET_LOCALES" > /etc/locale.gen
        locale-gen
    fi
fi

# 设置时区
if ! [ "$SET_TIME_ZONE" == 0 ];then
    prompt -x "Setup timezone"
    backupFile /etc/localtime
    ln -sf "$SET_TIME_ZONE" /etc/localtime
fi

# 设置TTY1自动登录
if [ "$SET_TTY_AUTOLOGIN" -eq 1 ];then
    prompt -x "Setup tty1 automatic login..."
    sed -i "s/#NAutoVTs=6/NAutoVTs=1/g" /etc/systemd/logind.conf
    addFolder /etc/systemd/system/getty@tty1.service.d
    echo "[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
" > /etc/systemd/system/getty@tty1.service.d/override.conf
fi