#!/bin/bash
:<<!说明
这里是执行的配置
另外，记得配置GlobalVariables中的# root用户密码ROOT_PASSWD！
!说明

## 检查点一 ##==
# 是否使用DEB822 Preset=1
SET_DEB822=1
# 使用的APT源 0:跳过 1:清华大学镜像源 2:清华大学Sid镜像源 3:你的源  Preset:3
SET_APT_SOURCE=3
#==== 自定义源请在检查的1文件夹中定义!
# 更新与安装是否不过问 Preset:1
SET_APT_RUN_WITHOUT_ASKING=1
# 是否禁用unattended-upgrades.service 0:不做处理 1:启用 2:禁用  Preset=0
SET_ENABLE_UNATTENDED_UPGRADE=0
# 是否在安装软件前更新整个系统 0:just apt update 1:apt dist-upgrade 2:apt upgrade   Preset:1
SET_APT_UPGRADE=1
# 是否加入sudo组 Preset:1
SET_SUDOER=1
# 是否设置sudo无需密码 Preset:1
SET_SUDOER_NOPASSWD=1

## 检查点二 ##==
# 是否卸载vim-tiny（vim -N），安装vim-full Preset:1
SET_VIM_TINY_TO_FULL=1
# 是否替换Bash为Zsh（包括root用户） Preset:1
SET_BASH_TO_ZSH=1
# 是否配置ZSHRC Preset:1
SET_ZSHRC=1
# 是否替换root用户的shell配置文件(如.bashrc)为用户配置文件 Preset:1
SET_REPLACE_ROOT_RC_FILE=1
# 添加/usr/sbin到环境变量 Preset=0
SET_ADD_SBIN_ENV=0
# 是否安装bash-completion Preset=1
SET_BASH_COMPLETION=1
# 是否安装zsh-autosuggestions Preset=1
SET_ZSH_AUTOSUGGESTIONS=1

## 检查点三 ##==
# 是否自定义一个systemctl服务(customize-autorun) Preset=1
SET_SYSTEMCTL_SERVICE=1
# 是否配置Nautilus右键菜单以及Data、Project、VM_Share、Prog、Mounted文件夹 Preset=1
SET_NAUTILUS_MENU=1
# 启用办公右键脚本：把仓库根目录 Office/ 同步到 ~/.local/share/nautilus/lib/Office，
# 再把 Office/NautilusScripts/Office/ 平铺到 scripts/（脚本用 ../lib/Office）Preset=1
SET_NAUTILUS_OFFICE=1
# 复制模板文件夹内容(注意：有些系统可能在~/.Templates，这个不在本脚本考虑范围) Preset=1
SET_GNOME_FILE_TEMPLATES=1
# 配置启用NetworkManager、安装net-tools Preset=1
SET_NETWORK_MANAGER=1
# 设置有线网卡xxxx如:eth0为热拔插模式以缩短开机时间。
# 如果没有xxx网卡，发出警告、跳过 Preset=1 如果有，直接填写网卡名称
# 1:如果只有一个有线网卡，那就配置，多个就跳过
SET_WIRED_ALLOW_HOTPLUG=1
# 配置GRUB网卡默认命名方式 传统的 ethX 名称（例如 eth0, eth1）(注意：启用此选项可能导致SET_WIRED_ALLOW_HOTPLUG失效) Preset=0
SET_GRUB_NETCARD_NAMING=0

## 检查点四 ##==
# 从APT源安装常用软件
# 是否从APT源安装常用软件 Preset=1
SET_APT_INSTALL=1
:<<注释
有几个预选的安装列表供参考（内容在 4/cfg.sh）:
0.自定义（空，建议用 3）
1.轻量：网络 debug + 编程 + 仅 VLC + 实际在用的扩展
2.日用影音：1 的全部 + GIMP/Kdenlive/OBS/HandBrake 等
3.自定义（空，自行填写 APT_TO_INSTALL_INDEX_3）
Preset=1
注释
SET_APT_INSTALL_LIST_INDEX=1
# 警告：Debian 12中 pip install可能破坏系统稳定性！谨慎使用
# 安装Python3 Preset=1
SET_PYTHON3_INSTALL=1
# 配置Python3源为清华大学镜像 Preset=1
SET_PYTHON3_MIRROR=1
# 配置Python3全局虚拟环境（Debian12中无法直接使用pip了） Preset=1
SET_PYTHON3_VENV=1
# 安装配置Apache2 Preset=0 (新版本默认安装Nginx，并配置PHP)
SET_INSTALL_APACHE2=0
# 是否设置Apache2开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_APACHE2=0
# 是否安装Nginx Preset=1
SET_INSTALL_NGINX=1
# 是否安装PHP（包括php fpm） Preset=1
SET_INSTALL_PHP=1
# 是否指定PHP运行端口 Preset=0
SET_PHP_FPM_PORT=0
# 是否设置php fpm开机自启,默认禁用 Preset=0
SET_PHP_FPM_ENABLE=0
# 是否设置Nginx开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_NGINX=0
# 配置 fmgr 文件共享（仓库 fmgr文件传输 → /home/HTML/fmgr）。仅当上面 Nginx 与 PHP 都安装时生效。不启动服务，自行 systemctl start php*-fpm nginx。 Preset=1
SET_CONFIG_FMGR=1
# 安装配置git Preset=1
SET_INSTALL_GIT=1
# Git用户名、邮箱地址 默认$CURRENT_USER & $CURRENT_USER@$HOST
SET_GIT_USER=0
SET_GIT_EMAIL=0
# 安装配置ssh Preset=1
SET_INSTALL_OPENSSH=1
# SSH开机是否自启 Preset=0 默认禁用
SET_ENABLE_SSH=0
# 安装配置npm Preset=0
SET_INSTALL_NPM=0
# 是否安装Nodejs(注意：nodejs来源于apt仓库！如需nvm请手动安装) Preset=0
SET_INSTALL_NODEJS=0
# 是否安装CNPM Preset=0
SET_INSTALL_CNPM=0
# 是否安装Hexo Preset=0
SET_INSTALL_HEXO=0

#### 下列软件安装时间较长，故放在最后安装
# 是否安装Virtual Box Preset=0
SET_INSTALL_VIRTUALBOX=0
# 设置vbox仓库，0:官网 1:清华大学镜像站 注意：如果是sid源，则使用sid仓库 Preset=1
SET_VIRTUALBOX_REPO=0
# 是否安装anydesk (受国外仓库限制，安装慢) Preset=0
SET_INSTALL_ANYDESK=0
# 是否设置anydesk开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_ANYDESK=0
# 是否安装typora  Preset=1
SET_INSTALL_TYPORA=0
# 是否安装sublime text  (受国外仓库限制，安装慢) Preset=0
SET_INSTALL_SUBLIME_TEXT=0
# 是否安装teamviewer (受国外仓库限制，安装慢) Preset=0
SET_INSTALL_TEAMVIEWER=0
# 是否设置teamviewer开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_TEAMVIEWER=0
# 是否安装WPS (APT安装慢) Preset=1 注：2024年8月起可能失效
SET_INSTALL_WPS_OFFICE=0
# 是否安装Docker-ce Preset=0
SET_INSTALL_DOCKER_CE=0
# 是否彻底清除后重装 Docker（1=删除镜像/容器数据再装；0=保留已有数据）Preset=0
SET_DOCKER_PURGE_REINSTALL=0
# Manage Docker as a non-root user? Preset=0
SET_DOCKER_NON_ROOT=0
# 设置Docker-ce仓库来源 0:官方 1:清华大学镜像仓库 Preset：1
SET_DOCKER_CE_REPO=1
# 是否设置Docker-ce开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_DOCKER_CE=0
# 安装Google-Chrome（for CN） Preset=1
SET_INSTALL_GOOGLE_CHROME=1

## 检查点五 ##==
# 拷贝字体到~/.fonts文件夹下。默认是FONTS文件夹，如果需要，请到对应文件夹中的cfg.sh设置存放字体的文件夹路径(e.g.: FONTS). Preset=1
SET_FONTS=1
# 注意：xdotool不支持在wayland运行，fcitx也建议在x11下运行。注销、登录界面选择运行于xorg的GNOME
# 注意：fcitx 和 fcitx5 无法共存！参见：https://lists.debian.org/debian-chinese-gb/2021/12/msg00000.html 和 https://www.debian.org/releases/bookworm/amd64/release-notes/ch-information.en.html
# 配置 中州韵输入法 0: 不配置 1: fcitx-rime 2.ibus-rime 3.fcitx5-rime Preset=3
SET_INSTALL_RIME=3
# RIME 词库（离线）0: 基础明月拼音（兼容 fcitx4/fcitx5/ibus） 1: 白霜拼音（需 fcitx5，见 5/RIME_FROST/） Preset=1
SET_IMPORT_RIME_DICT=1


## 检查点六 ##
# 配置SSH Key Preset=1
SET_CONFIG_SSH_KEY=1
# 是否生成新的SSH Key 0:新的密钥 1:从文件夹导入现有密钥 2:从文本导入现有密钥 Preset=0
SET_SSH_KEY_SOURCE=0
# 新生成的、或者导入文本生成的SSH密钥名称 Preset=id_rsa
SET_SSH_KEY_NAME=id_rsa
# 新生成的SSH密钥密码 Preset=""
SET_NEW_SSH_KEY_PASSWD=""
# 新密钥的备注 默认："A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian11_GNOME_Deploy_Script" Preset=0 （0就是默认备注！）
SET_SSH_KEY_COMMENT=0
# 存放已存在的SSH密钥文件夹名称(SET_SSH_KEY_SOURCE=1时有效) 1:从文件夹导入
SET_EXISTED_SSH_KEY_SRC=SSH_KEY
# SSH 密钥文本 (SET_SSH_KEY_SOURCE=2时有效)2:从文本导入
# 私钥
SET_SSH_KEY_PRIVATE_TEXT=""
# 公钥
SET_SSH_KEY_PUBLIC_TEXT=""

## 检查点七(谨慎！可能弄坏您的应用软件) ##==
# 是否接受dconf配置带来的风险 Preset=1
SET_DCONF_SETTING=1
# 导入GNOME Terminal的dconf配置 0:否 Preset=1
SET_IMPORT_GNOME_TERMINAL_DCONF=1
# 导入GNOME 您自定义修改的系统内置快捷键的dconf配置 0:否 Preset=1
SET_IMPORT_GNOME_WM_KEYBINDINGS_DCONF=1
# 导入GNOME 自定义快捷键的dconf配置 0: 否 Preset=1
SET_IMPORT_GNOME_CUSTOM_KEYBINDINGS_DCONF=1
# 导入GNOME 屏幕放大镜配置 Preset=1
SET_IMPORT_GNOME_MAGNIFIER_KEYBINDINGS=1
# 导入切换窗口配置（将会禁用切换应用程序快捷键）
SET_IMPORT_GNOME_SWITCH_WINDOWS_KEYBINDINGS=1
# 导入显示桌面快捷键
SET_IMPORT_GNOME_SHOW_DESKTOP_KEYBINDINGS=1
# 导入关机快捷键（会清空注销按键）
SET_IMPORT_GNOME_SHUTDOWN_KEYBINDINGS=1
# 导入GNOME 电源配置
SET_IMPORT_GNOME_POWER_DCONF=1
# GNOME Tweaks「窗口：副键调整窗口」Preset=1
SET_GNOME_RESIZE_WITH_RIGHT_BUTTON=1
# 固定工作区数量（0=不改；4=固定 4 个，并关闭动态工作区）Preset=4
SET_GNOME_FIXED_WORKSPACES=4
# 启用下列 GNOME 扩展（按当前机器实际在用的 UUID）Preset=1
# 完整 apt 扩展清单见 4/README.md。安装 ≠ 启用。
SET_GNOME_ENABLE_EXTENSIONS=1
SET_GNOME_EXTENSIONS_ENABLE="
dash-to-dock@micxgx.gmail.com
ubuntu-appindicators@ubuntu.com
drive-menu@gnome-shell-extensions.gcampax.github.com
freon@UshakovVasilii_Github.yahoo.com
harddiskled@bijidroid.gmail.com
impatience@gfxmonk.net
noannoyance-fork@vrba.dev
"
# 写入扩展偏好（Dash 位置、Freon 传感器、Impatience 速度等）Preset=1
SET_GNOME_EXTENSIONS_CONFIG=1

## 检查点八 ##
# 是否配置Shorewall防火墙(但是需要手动启用) Preset=1
SET_SHOREWALL_SETTING=1

###
# 是否禁用第三方软件仓库更新（检查点一之后新增的 sources.list.d 挪到 backup）。Preset=1
SET_DISABLE_THIRD_PARTY_REPO=1
# 是否启用 os-prober -> 自Debian 12 开始，GRUB检测其他系统的 os-prober 被禁用了。0:不处理 1:启用 2:禁用 Preset=0
SET_ENABLE_GRUB_OS_PROBER=0
# 最后一步 设置用户目录所属 Preset=1
SET_USER_HOME=1

## 部署续跑 ##
# 失败后续跑时跳过已完成步骤 Preset:1
SET_DEPLOY_RESUME=1
# 设为1则清除进度、从头运行 Preset:0
SET_DEPLOY_RESET=0
# 续跑时跳过「是否开始」确认（首次仍必须输入 y） Preset:1
SET_DEPLOY_SKIP_CONFIRM=1
# 全文终端录像（script -f）。默认 0：直接用真实终端，wireshark/显示管理器/pager 可交互。需要完整日志再设 1
SET_DEPLOY_FULL_LOG=0




############################################################################
#### 默认变量赋值
# Git
if [ "$SET_GIT_USER" -eq 0 ];then
    SET_GIT_USER=$CURRENT_USER
fi
if [ "$SET_GIT_EMAIL" -eq 0 ];then
    SET_GIT_EMAIL=$CURRENT_USER@$HOSTNAME
fi
# SSH
if [ "$SET_SSH_KEY_COMMENT" -eq 0 ];then
    SET_SSH_KEY_COMMENT="A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian_GNOME_Deploy_Script"
fi
