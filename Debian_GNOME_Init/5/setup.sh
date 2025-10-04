#!/bin/bash
: <<检查点五
配置字体
配置中州韵输入法
https://wiki.archlinuxcn.org/wiki/Fcitx5
检查点五

source "cfg.sh"

# 添加字体到Home
if [ "$SET_FONTS" -eq 1 ]; then
    if [ -d "/home/$CURRENT_USER/.fonts" ]; then
        addFolder /home/$CURRENT_USER/.fonts
    fi
    cp "$SET_FONTS_SOURCE"/* /home/$CURRENT_USER/.fonts/
fi

# 配置Fcitx 中州韵输入法
# 注意：据说 pam-env 已不再读取 ~/.pam_environment 文件。
if [ "$SET_INSTALL_RIME" -eq 1 ]; then
    prompt -m "通常建议是：在 运行于xorg的GNOME 模式下使用Fcitx输入法(而不是Wayland！)， 模式切换在用户登录页面的小齿轮可以配置。"
    prompt -m "如果出现异常，x11用户可能得检查下~/.xprofile，wayland用户可能得检查下~/.profile"
    sleep 8
    doApt update
    # 移除fcitx5
    doApt remove fcitx5
    doApt remove fcitx5-"*"
    doApt install fcitx
    doApt install fcitx-rime
    doApt install fcitx-googlepinyin
    doApt install fcitx-module-cloudpinyin
    fcitx &
    sleep 3
    prompt -x "检查 /etc/environment 文件"
    source "fcitx/fcitx4_Lib.sh"
    update_fcitx4_etc_environment_vars
    if ! [ -f "/home/$CURRENT_USER/.pam_environment" ]; then
        prompt -x "复制到 ~/.pam_environment 文件"
        cp "fcitx/pam_environment" "/home/$CURRENT_USER/.pam_environment"
    else
        prompt -w "如果是Wayland，请自行设置~/.pam_environment(如果Fcitx不运行的话)"
    fi
    if ! [ -f "/home/$CURRENT_USER/.xprofile" ]; then
        prompt -x "复制到 ~/.xprofile 文件"
        cp "fcitx/xprofile" "/home/$CURRENT_USER/.xprofile"
    else
        prompt -w "如果是WPS等应用无法使用fcitx，请自行设置 ~/.xprofile"
    fi
    prompt -m "检查中州韵输入法安装情况……"
    if ! [ -d "/home/$CURRENT_USER/.config/fcitx" ]; then
        prompt -e "找不到fcitx的配置文件夹/home/$CURRENT_USER/.config/fcitx"
        quitThis
    fi
    if ! [ -d "/home/$CURRENT_USER/.config/fcitx/rime" ]; then
        prompt -e "找不到fcitx-rime的配置文件夹/home/$CURRENT_USER/.config/fcitx/rime"
        addFolder /home/$CURRENT_USER/.config/fcitx/rime
    fi
    prompt -x "im-config 切换 fcitx, 注销生效"
    im-config -n fcitx
    rime_config_dir="/home/$CURRENT_USER/.config/fcitx/rime/"
elif [ "$SET_INSTALL_RIME" -eq 2 ]; then
    # https://wiki.archlinuxcn.org/wiki/IBus
    doApt update
    doApt install ibus
    doApt install ibus-rime
    if ! [ -f "/home/$CURRENT_USER/.profile" ]; then
        prompt -x "生成 .profile 文件(注意，如果不是wayland，可能需要使用.xprofile)"
        cp "ibus/profile" "/home/$CURRENT_USER/.profile"
    else
        prompt -w "如果你在输入中文时遇到问题，检查你的 locale 设置。并自行设置~/.profile或者xprofile"
    fi
    prompt -w "如果 IBus 确实已经启动，但是在 LibreOffice 里没有出现输入窗口，你需要在 ~/.bashrc (或者.zshrc) 里加入这行：export XMODIFIERS=@im=ibus"
    prompt -m "检查中州韵输入法安装情况……"
    if ! [ -d "/home/$CURRENT_USER/.config/ibus" ]; then
        prompt -e "找不到ibus的配置文件夹/home/$CURRENT_USER/.config/ibus"
        quitThis
    fi
    if ! [ -d "/home/$CURRENT_USER/.config/ibus/rime" ]; then
        prompt -e "找不到ibus-rime的配置文件夹/home/$CURRENT_USER/.config/ibus/rime"
        addFolder /home/$CURRENT_USER/.config/ibus/rime
    fi
    rime_config_dir="/home/$CURRENT_USER/.config/ibus/rime"
    im-config -n ibus
elif [ "$SET_INSTALL_RIME" -eq 3 ]; then
    doApt update
    # 移除fcitx
    doApt remove fcitx
    doApt remove fcitx-"*"
    doApt install fcitx5
    doApt install fcitx5-rime
    doApt install fcitx5-module-cloudpinyin
    fcitx5 &
    sleep 5
    prompt -w "注意：Fcitx5 默认不再设置.pam_environment和.xprofile，如安装后不正常，请手动检查。"
    sleep 5
    prompt -x "检查 /etc/environment 文件"
    source "fcitx/fcitx5_Lib.sh"
    update_fcitx5_etc_environment_vars
    prompt -m "检查中州韵输入法安装情况……"
    if ! [ -d "/home/$CURRENT_USER/.local/share/fcitx5" ]; then
        prompt -e "找不到fcitx5的配置文件夹/home/$CURRENT_USER/.local/share/fcitx5"
        addFolder /home/$CURRENT_USER/.local/share/fcitx5
        # 这里就不退出了，新建文件夹就是
        # quitThis
    fi
    if ! [ -d "/home/$CURRENT_USER/.local/share/fcitx5/rime" ]; then
        prompt -e "找不到fcitx5-rime的配置文件夹/home/$CURRENT_USER/.local/share/fcitx5/rime"
        addFolder /home/$CURRENT_USER/.config/fcitx5/rime
    fi
    rime_config_dir="/home/$CURRENT_USER/.local/share/fcitx5/rime"
    im-config -n fcitx5
fi

# 开始配置词库
if [ "$SET_INSTALL_RIME" -ne 0 ]; then
    prompt -m "检查完成，开始配置词库"
    if [ "$SET_IMPORT_RIME_DICT" -eq 0 ]; then
        prompt -m "不导入词库,但保留词库添加功能。"
        cp rime_base_config/* $rime_config_dir
    elif [ "$SET_IMPORT_RIME_DICT" -eq 1 ]; then
        prompt -x "从Github导入词库。"
        if ! [ -x "$(command -v git)" ]; then
            doApt install git
        fi
        git clone "$SET_RIME_DICT_GITREPO" RGIT_REPO
        if [ $? -ne 0 ]; then
            prompt -e "Git克隆公开词库出错。"
            quitThis
        fi
        backupFile $rime_config_dir
        # 重命名
        if [ -d "$rime_config_dir(src)" ];then
            backupFile "$rime_config_dir"
            prompt -e "存在 $rime_config_dir(src) ,似乎已经配置过词库了，本次不再配置"
        else
            mv "$rime_config_dir" "$rime_config_dir(src)"
        fi
        cp RGIT_REPO/* $rime_config_dir
    elif [ "$SET_IMPORT_RIME_DICT" -eq 2 ]; then
        prompt -x "导入本地词库。"
        sudo cp $SET_RIME_DICT_DIR/* $rime_config_dir
    fi
fi

