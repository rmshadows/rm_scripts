: <<检查点一
默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
更新源、更新系统。
配置unattended-upgrades
检查点一
prompt -i "——————————  检查点一  ——————————"
source "cfg.sh"


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

if [ "$SET_DEB822" -eq 1 ]; then
    backupFile "/etc/apt/sources.list"
    # 清空文件内容！
    sudo tee /etc/apt/sources.list </dev/null
    # 添加清华大学 Debian 13 镜像源
    if [ "$SET_APT_SOURCE" -eq 1 ]; then
        prompt -x "添加清华大学 Debian 13 镜像源"
        sudo echo "Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
# Suites: trixie trixie-updates trixie-backports
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: https://mirrors.tuna.tsinghua.edu.cn/debian-security
# Suites: trixie-security
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" | sudo tee /etc/apt/sources.list.d/debian.sources
    # 添加清华大学Debian sid 镜像源
    elif [ "$SET_APT_SOURCE" -eq 2 ]; then
        prompt -x "添加清华大学 Debian sid 镜像源"
        sudo echo "Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
# Suites: sid
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" | sudo tee /etc/apt/sources.list.d/debian.sources
    elif [ "$SET_APT_SOURCE" -eq 3 ]; then
        prompt -x "添加你自己的源"
        sudo echo "$SET_YOUR_APT_SOURCE" | sudo tee /etc/apt/sources.list.d/debian.sources
    fi
else
    # 添加清华大学 Debian 13 镜像源
    if [ "$SET_APT_SOURCE" -eq 1 ]; then
        backupFile "/etc/apt/sources.list"
        prompt -x "添加清华大学 Debian 13 镜像源"
        sudo echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-updates main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-updates main contrib non-free non-free-firmware

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-backports main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-backports main contrib non-free non-free-firmware

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security trixie-security main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security trixie-security main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list
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
fi

# 检测当前自动更新状态(临时函数)
check_unattended_status() {
    if systemctl list-unit-files | grep -q "unattended-upgrades.service"; then
        # 旧版本 (Debian 10/11 常见)
        if systemctl is-enabled unattended-upgrades.service >/dev/null 2>&1; then
            echo "unattended-upgrades.service 已启用"
        else
            echo "unattended-upgrades.service 已禁用"
        fi
    else
        # 新版本 (Debian 12/13 使用 apt-daily) Declare and assign separately to avoid masking return values.shellcheckSC2155
        local daily_enabled=$(systemctl is-enabled apt-daily.timer 2>/dev/null)
        local upgrade_enabled=$(systemctl is-enabled apt-daily-upgrade.timer 2>/dev/null)
        if [ "$daily_enabled" = "enabled" ] || [ "$upgrade_enabled" = "enabled" ]; then
            echo "APT 自动更新 (apt-daily/upgrade) 已启用"
        else
            echo "APT 自动更新 (apt-daily/upgrade) 已禁用"
        fi
    fi
}

# 配置 unattended-upgrades / APT 自动更新
if [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 0 ]; then
    prompt -m "保持原有 unattended-upgrades/apt-daily 状态"
    check_unattended_status
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 1 ]; then
    prompt -x "启用自动更新 (unattended-upgrades 或 apt-daily)"
    if systemctl list-unit-files | grep -q "unattended-upgrades.service"; then
        sudo systemctl enable --now unattended-upgrades.service
    else
        sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
    fi
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 2 ]; then
    prompt -x "禁用自动更新 (unattended-upgrades 或 apt-daily)"
    if systemctl list-unit-files | grep -q "unattended-upgrades.service"; then
        sudo systemctl disable --now unattended-upgrades.service
    else
        sudo systemctl disable --now apt-daily.timer apt-daily-upgrade.timer
        # sudo systemctl mask apt-daily.service apt-daily-upgrade.service
    fi
fi

# 更新系统
if [ "$SET_APT_UPGRADE" -eq 0 ]; then
    prompt -x "仅更新仓库索引"
    doApt update
elif [ "$SET_APT_UPGRADE" -eq 1 ]; then
    prompt -x "更新整个系统中"
    doApt update && doApt full-upgrade
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
    doApt update && doApt full-upgrade
elif [ "$SET_APT_UPGRADE" -eq 2 ]; then
    prompt -x "仅更新软件"
    doApt update && doApt upgrade
fi

# 检查APT状态
if [ $? -ne 0 ]; then
    prompt -e "第二次更新失败，请手动检查下APT运行状态。"
    quitThis
fi
