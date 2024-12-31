:<<检查点三
配置自定义的systemtl服务
配置Nautilus右键菜单以及Data、Project、VM_Share、Prog、Mounted文件夹
复制模板文件夹内容
配置启用NetworkManager、安装net-tools
设置网卡eth0为热拔插模式以缩短开机时间。如果没有eth0网卡，发出警告、跳过 Preset=0
配置GRUB网卡默认命名方式
检查点三


# 修改customize-autorun.service中用户名 生成customize-autorun.service
replace_username "customize_systemd_service/customize-autorun.service.src"

# 检查有线网卡的函数
check_wired_network() {
    # 获取所有以 en 或 enx 开头的有线网卡接口
    wired_interfaces=$(ip link show | grep -E '^[0-9]+: (en|enx|ens|enp)' | awk '{print $2}' | sed 's/://')
    # 打印调试信息
    echo "Found interfaces: $wired_interfaces"
    # 获取网卡数量
    num_interfaces=$(echo "$wired_interfaces" | wc -l)
    echo "Number of interfaces: $num_interfaces"  # 打印网卡数量
    # 如果只有一个有线网卡，返回网卡名；如果没有或有多个，返回 0
    if [ "$num_interfaces" -eq 1 ]; then
        check_wired_network_result="$wired_interfaces"
    else
        check_wired_network_result=0
    fi
}

# 检查有线网卡数量
if [ "$SET_WIRED_ALLOW_HOTPLUG" -eq 1 ];then
    check_wired_network
    SET_WIRED_ALLOW_HOTPLUG=$check_wired_network_result
fi

prompt -i "——————————  检查点三  ——————————"
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

# 配置Nautilus右键菜单以及Data、Project、VM_Share、Prog、Mounted文件夹
if [ "$SET_NAUTILUS_MENU" -eq 1 ];then
    prompt -x "配置Nautilus右键菜单以及Data、Project、VM_Share、Prog、Mounted文件夹"
    addFolder /home/$CURRENT_USER/Data
    addFolder /home/$CURRENT_USER/Project
    addFolder /home/$CURRENT_USER/VM_Share
    addFolder /home/$CURRENT_USER/Prog
    addFolder /home/$CURRENT_USER/Mounted
    addFolder /home/$CURRENT_USER/.$CURRENT_USER/
    prompt -x "创建 Nautilus 右键菜单"
    sudo cp NautilusScripts/* /home/$CURRENT_USER/.local/share/nautilus/scripts/
    sudo chmod +x /home/$CURRENT_USER/.local/share/nautilus/scripts/*
    # sudo chown $CURRENT_USER -hR /home/$CURRENT_USER
fi


# 复制模板文件夹内容
if [ "$SET_GNOME_FILE_TEMPLATES" -eq 1 ];then
    prompt -x "配置GNOME模板文件夹"
    addFolder "/home/$CURRENT_USER/模板"
    cp "模板/*" "/home/$CURRENT_USER/模板/"
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

# 设置网卡eth0为热拔插模式以缩短开机时间 Preset=1
if [ "$SET_WIRED_ALLOW_HOTPLUG" -ne 0 ];then
    prompt -m "设置网卡 $SET_WIRED_ALLOW_HOTPLUG 为热拔插模式以缩短开机时间。"
    # Not /etc/network/interfaces !
    # 如果不存在/etc/network/interfaces.d/setup这个文件就新建
    if ! [ -f "/etc/network/interfaces.d/setup" ];then
        prompt -x "没有找到 /etc/network/interfaces.d/setup 文件，新建文件中..."
        echo "# tee by rm_scripts.
allow-hotplug $SET_WIRED_ALLOW_HOTPLUG" | sudo tee /etc/network/interfaces.d/setup
    else
        # 如果存在/etc/network/interfaces.d/setup文件 就检查
        prompt -m "检查 /etc/network/interfaces.d/setup 中 $SET_WIRED_ALLOW_HOTPLUG 设备是否设置为热拔插..."
        backupFile /etc/network/interfaces.d/setup
        check_var="allow-hotplug $SET_WIRED_ALLOW_HOTPLUG"
        # 检查是否已经设置热拔插
        if sudo cat '/etc/network/interfaces.d/setup' | grep "$check_var" > /dev/null
        then
            echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
            sudo cat /etc/network/interfaces.d/setup
            prompt -w "您的 $SET_WIRED_ALLOW_HOTPLUG 设备似乎已经允许热拔插（如上所列），不做处理。"
        else
            # 没有检查到是否允许热拔插则检查是否有此网卡，没有此网卡会跳过
            prompt -m "检查 /etc/network/interfaces.d/setup 中是否有$SET_WIRED_ALLOW_HOTPLUG 设备..."
            # auto开头加网卡名称
            check_var="^auto $SET_WIRED_ALLOW_HOTPLUG"
            if sudo cat '/etc/network/interfaces.d/setup' | grep "$check_var" > /dev/null
            then
                # 如果有auto xxxx 改为 allow-hotplug xxxx
                # sudo sed -i 's/auto eth0/# auto eth0\nallow-hotplug eth0/g' /etc/network/interfaces.d/setup
                prompt -x "添加 allow-hotplug $SET_WIRED_ALLOW_HOTPLUG 到 /etc/network/interfaces.d/setup 中"
                sudo sed -i 's/auto '$SET_WIRED_ALLOW_HOTPLUG'/# auto '$SET_WIRED_ALLOW_HOTPLUG'\nallow-hotplug '$SET_WIRED_ALLOW_HOTPLUG'/g' /etc/network/interfaces.d/setup
            else
                prompt -e "似乎没有$SET_WIRED_ALLOW_HOTPLUG 这个设备或者$SET_WIRED_ALLOW_HOTPLUG 已被手动配置！"
            fi
        fi
    fi
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