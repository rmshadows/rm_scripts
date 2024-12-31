: <<检查点一
询问是否将当前用户加入sudo组, 是否sudo免密码（如果已经是sudoer且免密码则跳过）。
临时成为免密sudoer(必选)。
添加用户到sudo组。
设置用户sudo免密码。
默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
更新源、更新系统。
配置unattended-upgrades
检查点一
prompt -i "——————————  检查点一  ——————————"
source "cfg.sh"

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

# 预安装
prompt -x "安装部分先决软件包"
doApt update
# 确保https源可用
doApt install apt-transport-https
doApt install ca-certificates
# 确保查询功能可用
doApt install gawk
# 保证后面Vbox密钥添加
doApt install wget
doApt install gnupg2
doApt install gnupg
doApt install lsb-release

# 添加清华大学 Debian 12 镜像源
if [ "$SET_APT_SOURCE" -eq 1 ]; then
    backupFile "/etc/apt/sources.list"
    prompt -x "添加清华大学 Debian 12 镜像源"
    sudo echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware

# deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
# # deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list
# 添加清华大学Debian sid 镜像源
elif [ "$SET_APT_SOURCE" -eq 2 ]; then
    backupFile "/etc/apt/sources.list"
    prompt -x "添加清华大学 Debian sid 镜像源"
    sudo echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free" | sudo tee /etc/apt/sources.list
elif [ "$SET_APT_SOURCE" -eq 3 ]; then
    backupFile "/etc/apt/sources.list"
    prompt -x "添加你自己的源"
    sudo echo "$SET_YOUR_APT_SOURCE" | sudo tee /etc/apt/sources.list
fi

# 配置unattended-upgrades
if [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 0 ]; then
    prompt -m "保持原有unattended-upgrades.service状态"
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 1 ]; then
    prompt -x "启用unattended-upgrades.service"
    sudo systemctl enable unattended-upgrades.service
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 2 ]; then
    prompt -x "禁用unattended-upgrades.service"
    sudo systemctl disable unattended-upgrades.service
fi

# 更新系统
if [ "$SET_APT_UPGRADE" -eq 0 ]; then
    prompt -x "仅更新仓库索引"
    doApt update
elif [ "$SET_APT_UPGRADE" -eq 1 ]; then
    prompt -x "更新整个系统中"
    doApt update && doApt dist-upgrade
elif [ "$SET_APT_UPGRADE" -eq 2 ]; then
    prompt -x "仅更新软件"
    doApt update && doApt upgrade
fi

# 检查APT状态
if [ $? -ne 0 ]; then
    prompt -e "APT配置似乎失败了(比如需要手动解锁、网络连接失败，更新失败等)，请手动检查下APT运行状态。"
    quitThis
fi

# 第二次更新系统(作为确认)
if [ "$SET_APT_UPGRADE" -eq 0 ]; then
    prompt -x "仅更新仓库索引"
    doApt update
elif [ "$SET_APT_UPGRADE" -eq 1 ]; then
    prompt -x "更新整个系统中"
    doApt update && doApt dist-upgrade
elif [ "$SET_APT_UPGRADE" -eq 2 ]; then
    prompt -x "仅更新软件"
    doApt update && doApt upgrade
fi

# 检查APT状态
if [ $? -ne 0 ]; then
    prompt -e "第二次更新失败，请手动检查下APT运行状态。"
    quitThis
fi
