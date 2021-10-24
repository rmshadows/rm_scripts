#!/bin/bash
# https://github.com/rmshadows/rm_scripts

:<<!说明
Version：0.0.1
预设参数（在这里修改预设参数, 谢谢）
注意：如果没有注释，默认0 为否 1 为是。
if [ "$" -eq 1 ];then
    
fi
!说明
# root用户密码
ROOT_PASSWD=""
## 检查点一：
# 使用的APT源 0:跳过 1:清华大学镜像源 2:清华大学Sid镜像源   Preset:1
SET_APT_SOURCE=1
# 更新与安装是否不过问 Preset:1
SET_APT_RUN_WITHOUT_ASKING=1
# 是否禁用unattended-upgrades.service 0:不做处理 1:启用 2:禁用  Preset=0
SET_ENABLE_UNATTENDED_UPGRADE=0
# 是否在安装软件前更新整个系统 0:just apt update 1:apt dist-upgrade 2:apt upgrade   Preset:1
SET_APT_UPGRADE=0
# 是否加入sudo组 Preset:1
SET_SUDOER=1
# 是否设置sudo无需密码 Preset:1
SET_SUDOER_NOPASSWD=1
## 检查点二：
# 是否卸载vim-tiny，安装vim-full Preset:1
SET_VIM_TINY_TO_FULL=1
# 是否替换Bash为Zsh（包括root用户） Preset:1
SET_BASH_TO_ZSH=1
# 是否配置ZSHRC Preset:1
SET_ZSHRC=1
# 是否替换root用户的shell配置文件(如.bashrc)为用户配置文件 Preset:1
SET_REPLACE_ROOT_RC_FILE=1
# 添加/usr/sbin到环境变量 Preset=1
SET_ADD_SBIN_ENV=1
# 是否安装bash-completion Preset=1
SET_BASH_COMPLETION=1
# 是否安装zsh-autosuggestions Preset=1
SET_ZSH_AUTOSUGGESTIONS=1

## 检查点三：
# 是否自定义一个systemctl服务(customize-autorun) Preset=1
SET_SYSTEMCTL_SERVICE=1
# 是否配置Nautilus右键菜单以及Data、Project、Vbox-Tra、Prog、Mounted文件夹 Preset=1
SET_NAUTILUS_MENU=1
# 配置启用NetworkManager、安装net-tools Preset=1
SET_NETWORK_MANAGER=1
# 设置网卡eth0为热拔插模式以缩短开机时间。如果没有eth0网卡，发出警告、跳过 Preset=0
SET_ETH0_ALLOW_HOTPLUG=1
# 配置GRUB网卡默认命名方式 Preset=1
SET_GRUB_NETCARD_NAMING=1

## 检查点四：
#从APT源安装常用软件
# 是否从APT源安装常用软件 Preset=1
SET_APT_INSTALL=1
:<<注释
要安装的的软件的列表,列表在下方！！往下一直拉
有几个预选的安装列表供参考:
0.自定义列表
1.轻便安装
2.部分安装
3.全部安装
Preset=1
注释
SET_APT_INSTALL_LIST_INDEX=1
# 安装Python3 Preset=1
SET_PYTHON3_INSTALL=1
# 配置Python3源为清华大学镜像 Preset=1
SET_PYTHON3_MIRROR=1
# 安装配置Apache2 Preset=1
SET_INSTALL_APACHE2=1
# 是否设置Apache2开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_APACHE2=0
# 安装配置git Preset=1
SET_INSTALL_GIT=1
# Git用户名、邮箱地址 默认$CURRENT_USER & $CURRENT_USER@$HOST
SET_GIT_USER=$CURRENT_USER
SET_GIT_EMAIL=$CURRENT_USER@$HOSTNAME
# 安装配置ssh Preset=1
SET_INSTALL_OPENSSH=1
# SSH开机是否自启 Preset=0 默认禁用
SET_ENABLE_SSH=0
# 安装配置npm Preset=0
SET_INSTALL_NPM=0
# 是否安装Nodejs Preset=0
SET_INSTALL_NODEJS=0
# 是否安装CNPM Preset=0
SET_INSTALL_CNPM=0
# 是否安装Hexo Preset=0
SET_INSTALL_HEXO=0

#### 下列软件安装时间较长，故放在最后安装
# 是否安装Virtual Box Preset=1
SET_INSTALL_VIRTUALBOX=1
# 设置vbox仓库，0:官网(bullseye) 1:清华大学镜像站(Buster) 注意：如果是sid源，则使用sid仓库 Preset=1
SET_VIRTUALBOX_REPO=1
# 是否安装anydesk (受国外仓库限制，安装慢) Preset=1
SET_INSTALL_ANYDESK=1
# 是否设置anydesk开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_ANYDESK=0
# 是否安装typora  Preset=1
SET_INSTALL_TYPORA=1
# 是否安装sublime text  (受国外仓库限制，安装慢) Preset=0
SET_INSTALL_SUBLIME_TEXT=0
# 是否安装teamviewer (受国外仓库限制，安装慢) Preset=0
SET_INSTALL_TEAMVIEWER=0
# 是否设置teamviewer开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_TEAMVIEWER=0
# 是否安装WPS (APT安装慢) Preset=1
SET_INSTALL_WPS_OFFICE=1
# 拷贝字体到wps文件夹下，如果需要，请将该变量设置为存放字体的文件夹路径(e.g.: WPS_FONTS). Preset=0
SET_WPS_FONTS_SRC=0
# 是否安装Skype Preset=1
SET_INSTALL_SKYPE=1
# 是否安装Docker-ce Preset=0
SET_INSTALL_DOCKER_CE=1
# 设置Docker-ce仓库来源 0:官方 1:清华大学镜像仓库 Preset：1
SET_DOCKER_CE_REPO=1
# 是否设置Docker-ce开机自启动(注意，0为禁用，1为启用) Preset=0
SET_ENABLE_DOCKER_CE=0
# 安装网易云音乐 Preset=1
SET_INSTALL_NETEASE_CLOUD_MUSIC=1

## 检查点五
# 注意：xdotool不支持在wayland运行，fcitx也建议在x11下运行。注销、登录界面选择运行于xorg的GNOME
# 配置 中州韵输入法 0: 不配置 1: fcitx-rime 2.ibus-rime 3.fcitx5-rime Preset=1
SET_INSTALL_RIME=1
# 是否导入词库 0: 否 1:从Github导入公共词库 (注意网速！)  2:从本地文件夹导入词库 (请注意导入格式，否则输入法可能用不了) Preset=0
SET_IMPORT_RIME_DICT=0
# 本地词库文件夹位置 Preset=RIME_DICT
SET_RIME_DICT_DIR=RIME_DICT

## 检查点六
# 配置SSH Key Preset=1
SET_CONFIG_SSH_KEY=1
# 是否生成新的SSH Key 0:新的密钥 1:从文件夹导入现有密钥 2:从文本导入现有密钥 Preset=0
SET_SSH_KEY_SOURCE=0
# 新生成的、或者导入文本生成的SSH密钥名称 Preset=id_rsa
SET_SSH_KEY_NAME=id_rsa
# 新生成的SSH密钥密码 Preset=""
SET_NEW_SSH_KEY_PASSWD=""
# 新密钥的备注
SET_SSH_KEY_COMMENT="A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian11_GNOME_Deploy_Script"
# 存放已存在的SSH密钥文件夹名称 1:从文件夹导入
SET_EXISTED_SSH_KEY_SRC=SSH_KEY
# SSH 密钥文本 2:从文本导入
# 私钥
SET_SSH_KEY_PRIVATE_TEXT=""
# 公钥
SET_SSH_KEY_PUBLIC_TEXT=""

## 检查点七(谨慎！可能弄坏您的应用软件)
# 导入GNOME Terminal的dconf配置 0: 否 Other：文件路径(dconf dump /org/gnome/terminal/ > dconf-gonme-terminal) Preset=0
SET_IMPORT_GNOME_TERMINAL_DCONF=0
# 导入GNOME 您自定义修改的系统内置快捷键的dconf配置 0: 否 Other：文件路径(dconf dump /org/gnome/desktop/wm/keybindings/ > dconf-custom-wm-keybindings) Preset=0
SET_IMPORT_GNOME_WM_KEYBINDINGS_DCONF=0
# 导入GNOME 自定义快捷键的dconf配置 0: 否 Other：文件路径(dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > dconf-custom-keybindings) Preset=0
SET_IMPORT_GNOME_CUSTOM_KEYBINDINGS_DCONF=0

###
# 是否禁用第三方软件仓库更新(提升apt体验) Preset=1
SET_DISABLE_THIRD_PARTY_REPO=1
# 最后一步 设置用户目录所属 Preset=1
SET_USER_HOME=1

:<<注释
下面是需要填写的列表，要安装的软件。注意，格式是短杠空格接软件包名接破折号接软件包描述“- 【软件包名】——【软件包描述】”
注意：列表中请不要使用中括号
注释

# 自定义列表请从INDEX 3列表中选取
SET_APT_TO_INSTALL_INDEX_0="

"

# 这里是 脚本运行后 要安装的软件。格式同上，注意是稍后安装的，所以会放在脚本执行结束后才安装。
SET_APT_TO_INSTALL_LATER="
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
"

# 轻便安装 (仅我个人认为必要的常用软件)
APT_TO_INSTALL_INDEX_1="
- aircrack-ng——aircrack-ng
- apt-transport-https——apt-transport-https
- arp-scan——arp-scan
- axel——axel下载器
- bash-completion——终端自动补全
- bleachbit——系统清理软件
- build-essential——开发环境
- clamav——Linux下的杀毒软件
- cmake——cmake
- crunch——字典生成
- cups——cups打印机驱动
- curl——curl
- dislocker——查看bitlocker分区
- dos2unix——将Windows下的文本文档转为Linux下的文本文档
- drawing——GNOME画图
- dsniff——网络审计
- ettercap-graphical——ettercap-graphical
- fcitx-rime——中州韵输入法
- flatpak——flatpak平台
- gedit-plugin*——Gedit插件
- gimp——gimp图片编辑
- gnome-shell-extension-arc-menu——GNOME扩展+ARC菜单
- gnome-shell-extension-autohidetopbar——GNOME扩展+自动隐藏顶栏
- gnome-shell-extension-bluetooth-quick-connect——GNOME扩展+蓝牙快速连接
- gnome-shell-extension-caffeine——GNOME扩展+防止屏幕休眠
- gnome-shell-extension-dashtodock——GNOME扩展+DashtoDock侧栏
- gnome-shell-extension-dash-to-panel——GNOME扩展+任务栏
- gnome-shell-extension-desktop-icons——GNOME扩展+桌面图标
- gnome-shell-extension-disconnect-wifi——GNOME扩展+断开wifi
- gnome-shell-extension-draw-on-your-screen——GNOME扩展+屏幕涂鸦
- gnome-shell-extension-freon——GNOME扩展+顶栏显示磁盘温度
- gnome-shell-extension-gamemode——GNOME扩展+游戏模式
- gnome-shell-extension-hard-disk-led——GNOME扩展
- gnome-shell-extension-hide-activities——GNOME扩展
- gnome-shell-extension-hide-veth——GNOME扩展
- gnome-shell-extension-impatience——GNOME扩展
- gnome-shell-extension-kimpanel——GNOME扩展
- gnome-shell-extension-move-clock——GNOME扩展+移动时钟
- gnome-shell-extension-multi-monitors——GNOME扩展+多屏幕支持
- gnome-shell-extension-no-annoyance——GNOME扩展
- gnome-shell-extension-panel-osd——GNOME扩展
- gnome-shell-extension-pixelsaver——GNOME扩展
- gnome-shell-extension-prefs——GNOME扩展
- gnome-shell-extension-redshift——GNOME扩展
- gnome-shell-extension-remove-dropdown-arrows——GNOME扩展
- gnome-shell-extensions——GNOME扩展
- gnome-shell-extensions-gpaste——GNOME扩展+GNOME剪辑板
- gnome-shell-extension-shortcuts——GNOME扩展
- gnome-shell-extension-show-ip——GNOME扩展+顶栏菜单显示IP
- gnome-shell-extension-tilix-shortcut——GNOME扩展
- gnome-shell-extension-top-icons-plus——GNOME扩展
- gnome-shell-extension-volume-mixer——GNOME扩展
- gnome-shell-extension-weather——GNOME扩展+天气
- gnucash——GNU账本
- grub-customizer——GRUB或BURG定制器
- gufw——防火墙
- handbrake——视频转换
- hping3——hping3
- htop——htop彩色任务管理器
- httrack——网站克隆
- hydra——hydra
- inotify-tools——inotify文件监视
- kompare——文件差异对比
- konversation——IRC客户端
- lshw——显示硬件
- make——make
- masscan——masscan
- mdk3——mdk3
- meld——文件差异合并
- nautilus-extension-*——nautilus插件
- net-tools——ifconfig等工具
- nmap——nmap
- nodejs——nodejs
- npm——nodejs包管理器
- ntpdate——NTP时间同步
- obs-studio——OBS
- openssh-server——SSH
- pwgen——随机密码生成
- python3-pip——pip3
- reaver——无线WPS测试
- screenfetch——显示系统信息
- sed——文本编辑工具
- silversearcher-ag——Ag快速搜索工具
- slowhttptest——慢速HTTP链接测试
- tcpdump——tcpdump
- tree——树状显示文件夹
- traceroute——路由跟踪
- vim——VIM编辑器
- vlc——vlc视频播放器
- wafw00f——网站防火墙检测
- websploit——Web渗透测试
- wget——wget网络下载工具
- wireshark——wireshark
- xdotool——X自动化工具
- xprobe——网页防火墙测试
- xsel——剪贴板操作
- zhcon——tty中文虚拟
"
# 部分安装(含有娱乐项目、行业软件、调试应用)
APT_TO_INSTALL_INDEX_2="
- aircrack-ng——aircrack-ng
- apt-transport-https——apt-transport-https
- arp-scan——arp-scan
- axel——axel下载器
- bash-completion——终端自动补全
- bleachbit——系统清理软件
- blender——3D开发
- bridge-utils——网桥
- build-essential——开发环境
- bustle——D-Bus记录
- calibre——Epub等多格式电子书阅读器。注意：Epub等多格式电子书阅读器，体积较大，87M
- cewl——CeWL网站字典生成(关键词采集)
- cifs-utils——访问Windows共享文件夹
- clamav——Linux下的杀毒软件
- cmake——cmake
- cowpatty——wireless hash
- crunch——字典生成
- cups——cups打印机驱动
- curl——curl
- dislocker——查看bitlocker分区
- dos2unix——将Windows下的文本文档转为Linux下的文本文档
- drawing——GNOME画图
- dsniff——网络审计
- ettercap-graphical——ettercap-graphical
- extremetuxracer——滑雪游戏
- fcitx-rime——中州韵输入法
- flatpak——flatpak平台
- freeplane——思维导图
- fritzing——电路设计
- fping——fping
- fuse——配合dislocker查看bitlocker分区
- g++——C++
- gcc——C
- gedit-plugin*——Gedit插件
- gimp——gimp图片编辑
- glance——一个可以代替htop的软件
- gnome-recipes——GNOME西餐菜单。注意：西餐为主的菜单
- gnome-shell-extension-appindicator——GNOME扩展
- gnome-shell-extension-arc-menu——GNOME扩展+ARC菜单
- gnome-shell-extension-autohidetopbar——GNOME扩展+自动隐藏顶栏
- gnome-shell-extension-bluetooth-quick-connect——GNOME扩展+蓝牙快速连接
- gnome-shell-extension-caffeine——GNOME扩展+防止屏幕休眠
- gnome-shell-extension-dashtodock——GNOME扩展+DashtoDock侧栏
- gnome-shell-extension-dash-to-panel——GNOME扩展+任务栏
- gnome-shell-extension-desktop-icons——GNOME扩展+桌面图标
- gnome-shell-extension-disconnect-wifi——GNOME扩展+断开wifi
- gnome-shell-extension-draw-on-your-screen——GNOME扩展+屏幕涂鸦
- gnome-shell-extension-freon——GNOME扩展+顶栏显示磁盘温度
- gnome-shell-extension-gamemode——GNOME扩展+游戏模式
- gnome-shell-extension-hamster——GNOME扩展+时间追踪器
- gnome-shell-extension-hard-disk-led——GNOME扩展
- gnome-shell-extension-hide-activities——GNOME扩展
- gnome-shell-extension-hide-veth——GNOME扩展
- gnome-shell-extension-impatience——GNOME扩展
- gnome-shell-extension-kimpanel——GNOME扩展
- gnome-shell-extension-move-clock——GNOME扩展+移动时钟
- gnome-shell-extension-multi-monitors——GNOME扩展+多屏幕支持
- gnome-shell-extension-no-annoyance——GNOME扩展+关闭应用准备就绪对话框
- gnome-shell-extension-panel-osd——GNOME扩展
- gnome-shell-extension-pixelsaver——GNOME扩展
- gnome-shell-extension-prefs——GNOME扩展
- gnome-shell-extension-redshift——GNOME扩展
- gnome-shell-extension-remove-dropdown-arrows——GNOME扩展
- gnome-shell-extensions——GNOME扩展
- gnome-shell-extensions-gpaste——GNOME扩展+GNOME剪辑板
- gnome-shell-extension-shortcuts——GNOME扩展
- gnome-shell-extension-show-ip——GNOME扩展+顶栏菜单显示IP
- gnome-shell-extension-system-monitor——GNOME扩展+顶栏资源监视器
- gnome-shell-extension-tilix-dropdown——GNOME扩展
- gnome-shell-extension-tilix-shortcut——GNOME扩展
- gnome-shell-extension-top-icons-plus——GNOME扩展
- gnome-shell-extension-trash——GNOME扩展
- gnome-shell-extension-volume-mixer——GNOME扩展
- gnome-shell-extension-weather——GNOME扩展+天气
- gnome-software-plugin-flatpak——GNOME Flatpak插件
- gnucash——GNU账本
- grub-customizer——GRUB或BURG定制器
- gtranslator——GNOME本地应用翻译编辑
- gufw——防火墙
- handbrake——视频转换
- hugin——全景照片拼合工具
- homebank——家庭账本
- hostapd——AP热点相关
- hping3——hping3
- htop——htop彩色任务管理器
- httrack——网站克隆
- hydra——hydra
- inotify-tools——inotify文件监视
- kdenlive——kdenlive视频编辑
- kompare——文件差异对比
- konversation——IRC客户端
- libblockdev*——文件系统相关的插件
- libgtk-3-dev——GTK3
- linux-headers-$(uname -r)——Linux Headers
- lshw——显示硬件
- make——make
- masscan——masscan
- mc——MidnightCommander
- mdk3——mdk3
- meld——文件差异合并
- nautilus-extension-*——nautilus插件
- ncrack——ncrack
- net-tools——ifconfig等工具
- nmap——nmap
- nodejs——nodejs
- npm——nodejs包管理器
- ntpdate——NTP时间同步
- obs-studio——OBS
- openssh-server——SSH
- paperwork-gtk——办公文档扫描
- pavucontrol——PulseAudioVolumeControl
- pinfo——友好的命令帮助手册
- pkg-config——pkg-config
- pulseeffects——pulse audio的调音器。注意：可能影响到原音频系统
- pwgen——随机密码生成
- python-pip——pip
- python3-pip——pip3
- python3-tk——python3 TK界面
- qmmp——qmmp音乐播放器
- reaver——无线WPS测试
- screenfetch——显示系统信息
- sed——文本编辑工具
- silversearcher-ag——Ag快速搜索工具
- slowhttptest——慢速HTTP链接测试
- sqlmap——sqlmap
- sshfs——挂载远程SSH目录
- sslstrip——https降级
- supertuxkart——Linux飞车游戏
- sweethome3d——室内设计
- synaptic——新立得包本地图形化管理器
- tcpdump——tcpdump
- tig——tig(类似github桌面)
- tree——树状显示文件夹
- traceroute——路由跟踪
- vim——VIM编辑器
- vlc——vlc视频播放器
- wafw00f——网站防火墙检测
- websploit——Web渗透测试
- wget——wget网络下载工具
- wireshark——wireshark
- xdotool——X自动化工具
- xprobe——网页防火墙测试
- xsel——剪贴板操作
- zenity——显示GTK+对话框
- zhcon——tty中文虚拟
- zsh——zsh
- zsh-autosuggestions——zsh插件
"

# 全部安装 请注意查看标记有 注意 二字的条目
APT_TO_INSTALL_INDEX_3="
- aircrack-ng——aircrack-ng
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
- apt-transport-https——apt-transport-https
- arp-scan——arp-scan
- axel——axel下载器
- bash-completion——终端自动补全
- bleachbit——系统清理软件
- blender——3D开发
- bridge-utils——网桥
- build-essential——开发环境
- bustle——D-Bus记录
- calibre——Epub等多格式电子书阅读器。注意：Epub等多格式电子书阅读器，体积较大，87M
- cewl——CeWL网站字典生成(关键词采集)
- cifs-utils——访问Windows共享文件夹
- clamav——Linux下的杀毒软件
- cmake——cmake
- cowpatty——wireless hash
- crunch——字典生成
- cups——cups打印机驱动
- curl——curl
- dislocker——查看bitlocker分区
- dos2unix——将Windows下的文本文档转为Linux下的文本文档
- drawing——GNOME画图
- dsniff——网络审计
- ettercap-graphical——ettercap-graphical
- extremetuxracer——滑雪游戏
- fcitx-rime——中州韵输入法
- flatpak——flatpak平台
- freeplane——思维导图
- fritzing——电路设计
- fping——fping
- fuse——配合dislocker查看bitlocker分区
- g++——C++
- gajim——即时通讯
- gcc——C
- gedit-plugin*——Gedit插件
- gimp——gimp图片编辑
- glance——一个可以代替htop的软件
- gnome-recipes——GNOME西餐菜单。注意：西餐为主的菜单
- gnome-shell-extension-appindicator——GNOME扩展
- gnome-shell-extension-arc-menu——GNOME扩展+ARC菜单
- gnome-shell-extension-autohidetopbar——GNOME扩展+自动隐藏顶栏
- gnome-shell-extension-bluetooth-quick-connect——GNOME扩展+蓝牙快速连接
- gnome-shell-extension-caffeine——GNOME扩展+防止屏幕休眠
- gnome-shell-extension-dashtodock——GNOME扩展+DashtoDock侧栏
- gnome-shell-extension-dash-to-panel——GNOME扩展+任务栏
- gnome-shell-extension-desktop-icons——GNOME扩展+桌面图标
- gnome-shell-extension-disconnect-wifi——GNOME扩展+断开wifi
- gnome-shell-extension-draw-on-your-screen——GNOME扩展+屏幕涂鸦
- gnome-shell-extension-freon——GNOME扩展+顶栏显示磁盘温度
- gnome-shell-extension-gamemode——GNOME扩展+游戏模式
- gnome-shell-extension-hamster——GNOME扩展+时间追踪器
- gnome-shell-extension-hard-disk-led——GNOME扩展
- gnome-shell-extension-hide-activities——GNOME扩展
- gnome-shell-extension-hide-veth——GNOME扩展
- gnome-shell-extension-impatience——GNOME扩展
- gnome-shell-extension-kimpanel——GNOME扩展
- gnome-shell-extension-move-clock——GNOME扩展+移动时钟
- gnome-shell-extension-multi-monitors——GNOME扩展+多屏幕支持
- gnome-shell-extension-no-annoyance——GNOME扩展+关闭应用准备就绪对话框
- gnome-shell-extension-panel-osd——GNOME扩展
- gnome-shell-extension-pixelsaver——GNOME扩展
- gnome-shell-extension-prefs——GNOME扩展
- gnome-shell-extension-redshift——GNOME扩展
- gnome-shell-extension-remove-dropdown-arrows——GNOME扩展
- gnome-shell-extensions——GNOME扩展
- gnome-shell-extensions-gpaste——GNOME扩展+GNOME剪辑板
- gnome-shell-extension-shortcuts——GNOME扩展
- gnome-shell-extension-show-ip——GNOME扩展+顶栏菜单显示IP
- gnome-shell-extension-system-monitor——GNOME扩展+顶栏资源监视器
- gnome-shell-extension-tilix-dropdown——GNOME扩展
- gnome-shell-extension-tilix-shortcut——GNOME扩展
- gnome-shell-extension-top-icons-plus——GNOME扩展
- gnome-shell-extension-trash——GNOME扩展
- gnome-shell-extension-volume-mixer——GNOME扩展
- gnome-shell-extension-weather——GNOME扩展+天气
- gnome-software-plugin-flatpak——GNOME Flatpak插件
- gnucash——GNU账本
- grub-customizer——GRUB或BURG定制器
- gtranslator——GNOME本地应用翻译编辑
- gufw——防火墙
- handbrake——视频转换
- hugin——全景照片拼合工具
- homebank——家庭账本
- hostapd——AP热点相关
- hping3——hping3
- htop——htop彩色任务管理器
- httrack——网站克隆
- hydra——hydra
- inotify-tools——inotify文件监视
- isc-dhcp-server——DHCP服务器
- kdenlive——kdenlive视频编辑
- kompare——文件差异对比
- konversation——IRC客户端
- libblockdev*——文件系统相关的插件
- libgtk-3-dev——GTK3
- linux-headers-$(uname -r)——Linux Headers
- lshw——显示硬件
- make——make
- masscan——masscan
- mc——MidnightCommander
- mdk3——mdk3
- meld——文件差异合并
- nautilus-extension-*——nautilus插件
- ncrack——ncrack
- net-tools——ifconfig等工具
- nmap——nmap
- nodejs——nodejs
- npm——nodejs包管理器
- ntpdate——NTP时间同步
- obs-studio——OBS
- openssh-server——SSH
- paperwork-gtk——办公文档扫描
- pavucontrol——PulseAudioVolumeControl
- pinfo——友好的命令帮助手册
- pkg-config——pkg-config
- pulseeffects——pulse audio的调音器。注意：可能影响到原音频系统
- pwgen——随机密码生成
- python-pip——pip
- python3-pip——pip3
- python3-tk——python3 TK界面
- qmmp——qmmp音乐播放器
- reaver——无线WPS测试
- screenfetch——显示系统信息
- sed——文本编辑工具
- silversearcher-ag——Ag快速搜索工具
- slowhttptest——慢速HTTP链接测试
- smbclient——SMB共享查看
- sqlmap——sqlmap
- sshfs——挂载远程SSH目录
- sslstrip——https降级
- supertuxkart——Linux飞车游戏
- sweethome3d——室内设计
- synaptic——新立得包本地图形化管理器
- tcpdump——tcpdump
- tig——tig(类似github桌面)
- tree——树状显示文件夹
- traceroute——路由跟踪
- vim——VIM编辑器
- vlc——vlc视频播放器
- wafw00f——网站防火墙检测
- websploit——Web渗透测试
- wget——wget网络下载工具
- wireshark——wireshark
- xdotool——X自动化工具
- xprobe——网页防火墙测试
- xsel——剪贴板操作
- zenity——显示GTK+对话框
- zhcon——tty中文虚拟
- zsh——zsh
- zsh-autosuggestions——zsh插件
"


### 脚本变量
# Root用户UID
ROOT_UID=0
# 当前 Shell名称
CURRENT_SHELL=$SHELL
# 是否临时加入sudoer
TEMPORARILY_SUDOER=0
# 第一次运行DoAsRoot
FIRST_DO_AS_ROOT=1
# 第一次运行APT任务
FIRST_DO_APT=1

#### 脚本内置函数调用

## 控制台颜色输出
# 红色：警告、重点
# 黄色：警告、一般打印
# 绿色：执行日志
# 蓝色、白色：常规信息
# 颜色colors
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # warning color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"  
# echo like ...  with  flag type  and display message  colors
# -s 绿
# -e 红
# -w 黄
# -i 蓝
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
    "-x"|"--exec")
      echo -e "日志：${b_CGSC}${@/-x/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-m"|"--msg")
      echo -e "信息：${b_CCIN}${@/-m/}${CDEF}";;          # print iinfo message
    "-k"|"--kv")  # 三个参数
      echo -e "${b_CCIN} ${2} ${b_CWAR} ${3} ${CDEF}";;          # print success message
    *)
    echo -e "$@"
    ;;
  esac
}

# 如果用户按下Ctrl+c
trap "onSigint" SIGINT

# 程序中断处理方法,包含正常退出该执行的代码
onSigint () {
    prompt -w "捕获到中断信号..."
    onExit # TODO
    exit 1
}

# 正常退出需要执行的
onExit () {
    # 临时加入sudoer，退出时清除
    if [ $TEMPORARILY_SUDOER -eq 1 ] ;then
        prompt -x "清除临时sudoer免密权限。"
        # sudo sed -i "s/$TEMPORARILY_SUDOER_STRING/ /g" /etc/sudoers
        # 获取最后一行
        tail_sudo=`sudo tail -n 1 /etc/sudoers`
        if [ "$tail_sudo" = "$TEMPORARILY_SUDOER_STRING" ] > /dev/null ;then
            # 删除最后一行
            sudo sed -i '$d' /etc/sudoers
        else
            # 一般不会出现这个情况吧。。
            prompt -e "警告：未知错误，请手动删除 $TEMPORARILY_SUDOER_STRING "
            exit 1
        fi
    fi
}


# 中途异常退出脚本要执行的 注意，检查点一后才能使用这个方法
quitThis () {
    onExit
    exit
}


# 以root身份运行
doAsRoot () {
# 第一次运行需要询问root密码
if [ "$FIRST_DO_AS_ROOT" -eq 1 ];then
    if [ "$ROOT_PASSWD" == "" ] && [ "$IS_SUDOER" -ne 1 ] ;then
        prompt -w "未在脚本里定义root用户密码，请输入root用户密码: "
        read -r input
        ROOT_PASSWD=$input
    fi
    # 检查密码
    checkRootPasswd
    FIRST_DO_AS_ROOT=0
fi
# 下面不能有缩进！
su - root <<!>/dev/null 2>&1
$ROOT_PASSWD
echo " Exec $1 as root"
$1
!
}

# 检查root密码是否正确
checkRootPasswd () {
# 下面不能有缩进！
su - root <<! >/dev/null 2>/dev/null
$ROOT_PASSWD
pwd
!
# echo $?
if [ "$?" -ne 0 ] ;then
    prompt -e "Root 用户密码不正确！"
    exit 1
fi
}


## 询问函数 Yes:1 No:2 ???:5
:<<!询问函数
函数调用请使用：
comfirm "\e[1;33m? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  yes
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi
!询问函数
comfirm () {
  flag=true
  ask=$1
  while $flag
  do
    echo -e "$ask"
    read -r input
    if [ -z "${input}" ];then
      # 默认选择N
      input='n'
    fi
    case $input in [yY][eE][sS]|[yY])
      return 1
      flag=false
    ;;
    [nN][oO]|[nN])
      return 2
      flag=false
    ;;
    *)
      prompt -w "Invalid option..."
    ;;
    esac
  done
}

# 备份配置文件。先检查是否有bak结尾的备份文件，没有则创建，有则另外覆盖一个newbak文件。$1 :文件名
backupFile () {
    if [ -f "$1" ];then
        # 如果有bak备份文件 ，生成newbak
        if [ -f "$1.bak" ];then
            # bak文件存在
            prompt -x "(sudo)正在备份 $1 文件到 $1.newbak (覆盖) "
            sudo cp $1 $1.newbak
        else
            # 没有bak文件，创建备份
            prompt -x "(sudo)正在备份 $1 文件到 $1.bak"
            sudo cp $1 $1.bak
        fi
    else
        # 如果不存在要备份的文件,不执行
        prompt -e "没有$1文件，不做备份"
    fi
} 

# 执行apt命令 注意，检查点一后才能使用这个方法
doApt () {
    prompt -x "doApt: $@"
    # 如果是第一次运行apt
    if [ "$FIRST_DO_APT" -eq 1 ];then
        prompt -w "如果APT显示被占用，『对此的通常建议是等待』。如果你没有耐心，请尝试根据报错决定是否运行下列所示的命令(删锁、dpkg重配置)，注意：后者是极不建议的！"
        prompt -e "sudo rm /var/lib/dpkg/lock-frontend && sudo rm /var/lib/dpkg/lock && sudo dpkg --configure -a"
        FIRST_DO_APT=0
        sleep 5
    fi
    if [ "$1" = "install" ] || [ "$1" = "remove" ];then
        if [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 0 ];then
            sudo apt $@
        elif [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 1 ];then
            sudo apt $@ -y
        fi
    else
        sudo apt $@
    fi
}

# 新建文件夹 $1
addFolder () {
    if [ $# -ne 1 ];then
        prompt -e "addFolder () 只能有一个参数"
        quitThis
    fi
    if ! [ -d $1 ];then
        prompt -x "新建文件夹$1 "
        mkdir $1
    fi
    if ! [ $? -ne 0 ];then
        prompt -x "(sudo)新建文件夹$1 "
        sudo mkdir $1
    fi
}

:<<配置文件
这里是配置文件
配置文件

# zshrc 配置文件。修改：所有的“$”“\”“`”“"”全都加\转义
ZSHRC_CONFIG="# ~/.zshrc file for zsh non-login shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt ksharrays           # arrays start at 0
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

WORDCHARS=\${WORDCHARS//\\/} # Don't consider certain characters part of the word

# hide EOL sign ('%')
export PROMPT_EOL_MARK=\"\"

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[C' forward-word                       # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[D' backward-word                      # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[Z' undo                               # shift + tab undo last action

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history=\"history 0\"

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval \"\$(SHELL=/bin/sh lesspipe)\"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z \"\${debian_chroot:-}\" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=\$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we \"want\" color)
case \"\$TERM\" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n \"\$force_color_prompt\" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
    else
      color_prompt=
    fi
fi

if [ \"\$color_prompt\" = yes ]; then
    PROMPT=\$'%F{%(#.blue.green)}┌──\${debian_chroot:+(\$debian_chroot)──}(%B%F{%(#.red.blue)}%n%(#.💀.㉿)%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\\n└─%B%(#.%F{red}#.%F{blue}\$)%b%F{reset} '
    RPROMPT=\$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'

    # enable syntax-highlighting
    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && [ \"\$color_prompt\" = yes ]; then
      # ksharrays breaks the plugin. This is fixed now but let's disable it in the
      # meantime.
      # https://github.com/zsh-users/zsh-syntax-highlighting/pull/689
      unsetopt ksharrays
      . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
      ZSH_HIGHLIGHT_STYLES[default]=none
      ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
      ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
      ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
      ZSH_HIGHLIGHT_STYLES[global-alias]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
      ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
      ZSH_HIGHLIGHT_STYLES[path]=underline
      ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
      ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
      ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[command-substitution]=none
      ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[process-substitution]=none
      ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
      ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
      ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
      ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
      ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta
      ZSH_HIGHLIGHT_STYLES[assign]=none
      ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
      ZSH_HIGHLIGHT_STYLES[named-fd]=none
      ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
      ZSH_HIGHLIGHT_STYLES[arg0]=fg=green
      ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
      ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
      ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    fi
else
    PROMPT='\${debian_chroot:+(\$debian_chroot)}%n@%m:%~%# '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case \"\$TERM\" in
xterm*|rxvt*)
    TERM_TITLE='\e]0;\${debian_chroot:+(\$debian_chroot)}%n@%m: %~\\a'
    ;;
*)
    ;;
esac

new_line_before_prompt=yes
precmd() {
    # Print the previously configured title
    print -Pn \"\$TERM_TITLE\"

    # Print a new line before the prompt, but only if it is not the first line
    if [ \"\$new_line_before_prompt\" = yes ]; then
      if [ -z \"\$_NEW_LINE_BEFORE_PROMPT\" ]; then
        _NEW_LINE_BEFORE_PROMPT=1
      else
        print \"\"
      fi
    fi
}

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval \"\$(dircolors -b ~/.dircolors)\" || eval \"\$(dircolors -b)\"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=\$'\\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=\$'\\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=\$'\\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=\$'\\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=\$'\\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=\$'\\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=\$'\\E[0m'        # reset underline

    # Take advantage of \$LS_COLORS for completion as well
    zstyle ':completion:*' list-colors \"\${(s.:.)LS_COLORS}\"
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
# Git相关偷懒操作
# alias gitac='git add . -A && git commit -m \"update\"'
# alias hcg='hexo clean && hexo g'
# alias gitam='git add . -A && git commit -m '
# alias githardpull='git fetch --all && git reset --hard origin/main && git pull'
# FFMPEG
# 裁剪 开始、结尾、文件、输出文件
alias ffmpegss='ffmpegCutVideo(){ffmpeg -ss $1 -to $2 -i $3 -vcodec copy -acodec copy $4};ffmpegCutVideo'
# HTTP服务器
alias apastart='sudo systemctl start apache2.service'
alias apastop='sudo systemctl stop apache2.service'
# alias ngxstop='sudo systemctl stop nginx.service'
# alias ngxstop='sudo systemctl stop nginx.service'
# 其他
alias duls='du -sh ./*'
alias dulsd='du -sh \`la\`'
alias zshrc='vim '\$HOME'/.zshrc'
alias szsh='source '\$HOME'/.zshrc'
alias systemctl='sudo systemctl'
alias apt='sudo apt-get'
alias upgrade='sudo apt update && sudo apt upgrade'

# unset _JAVA_OPTIONS

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi
"

# 中州韵输入法词库配置头文件 luna_pinyin_simp.custom.yaml
RIME_DICT_HEADER="# luna_pinyin.custom.yaml
#
# 補靪功能：將朙月拼音的詞庫修改爲朙月拼音擴充詞庫
#
# 作者：瑾昀 <cokunhui@gmail.com>
#
# 部署位置：
# ~/.config/ibus/rime  (Linux)
# ~/Library/Rime  (Mac OS)
# %APPDATA%\Rime  (Windows)
#
# 於重新部署後生效
#
#
# 注意：本補靪適用於所有朙月拼音系列方案（「朙月拼音」、「朙月拼音·简化字」、「朙月拼音·臺灣正體」、「朙月拼音·語句流」）。
# 只須將本 custom.yaml 的前面名字改爲對應的輸入方案名字然後放入用戶文件夾重新部署即可。如 luna_pinyin_simp.custom.yaml。
# 雙拼用戶請使用 double_pinyin.custom.yaml。
#
#
# 附朙月拼音系列方案與其對應的 id 一覽表：
# 輸入方案	id
# 朙月拼音	luna_pinyin
# 朙月拼音·简化字	luna_pinyin_simp
# 朙月拼音·臺灣正體	luna_pinyin_tw
# 朙月拼音·語句流	luna_pinyin_fluency
#

patch:
  # 載入朙月拼音擴充詞庫
  \"translator/dictionary\": luna_pinyin.udict
  # 改寫拼寫運算，使得含西文的詞彙（位於 luna_pinyin.cn_en.dict.yaml 中）不影響簡拼功能（注意，此功能只適用於朙月拼音系列方案，不適用於各類雙拼方案）
  # 本條補靪只在「小狼毫 0.9.30」、「鼠鬚管 0.9.25 」、「Rime-1.2」及更高的版本中起作用。
  \"speller/algebra/@before 0\": xform/^([b-df-hj-np-tv-z])$/\$1_/
"

# 中州韵输入法，个人词库 luna_pinyin.udict.dict.yaml
RIME_DICT_UDICT="# Rime dictionary
# encoding: utf-8

---
name: luna_pinyin.extended
version: "2021.10.01"
sort: by_weight
use_preset_vocabulary: true
import_tables:
  - luna_pinyin
...

# 在下面添加用户词库
举个例子	jugelizi	1
测试词组	cscz

"


#### 正文
echo -e "\e[1;31m
_________  .___ ____   ____.___ _________  _________  _________  _________  _________  
\_   ___ \ |   |\   \ /   /|   |\_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ 
/    \  \/ |   | \   Y   / |   |/    \  \/ /    \  \/ /    \  \/ /    \  \/ /    \  \/ 
\     \____|   |  \     /  |   |\     \____\     \____\     \____\     \____\     \____
 \______  /|___|   \___/   |___| \______  / \______  / \______  / \______  / \______  /
        \/                              \/         \/         \/         \/         \/ 
\e[1;32m
==========================================
┏ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┓ 
┃        欢迎使用Debian部署脚本          ┃
┗ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┛ 
==========================================

\e[0m"
# R
echo -e "\e[1;31m接下来请根据提示进行操作，正在准备(1s)...\n\e[0m"
sleep 1

### 预先检查
# 检查是否有root权限，有则退出，提示用户使用普通用户权限。
prompt -i "\n检查权限  ——    Checking for root access...\n"
if [ "$UID" -eq "$ROOT_UID" ]; then
    # Error message
    prompt -e "\n [ Error ] -> 请不要使用管理员权限运行 Please DO NOT run as root  \n"
    exit 1
else
    prompt -w "\n——————————  Unit Ready  ——————————\n"
fi

:<<!预先检查
获取当前用户名
获取root密码
检查root密码
检查是否在sudo组中
是的话检查是否免密码
检查是否GNOME
如果不是sudo组，加入sudo组、设置免密码
!预先检查
# 获取当前用户名
CURRENT_USER=$USER

# 临时加入sudoer所使用的语句
TEMPORARILY_SUDOER_STRING="$CURRENT_USER ALL=(ALL)NOPASSWD:ALL"
# 检查是否在sudo组中 0 false 1 true
IS_SUDOER=-1
is_sudoer=-1
IS_SUDO_NOPASSWD=-1
is_sudo_nopasswd=-1
# 检查是否在sudo组
if groups| grep sudo > /dev/null ;then
    # 是sudo组
    IS_SUDOER=1
    is_sudoer="TRUE"
    # 检查是否免密码sudo
    check_var="ALL=(ALL)NOPASSWD:ALL"
    if doAsRoot "cat '/etc/sudoers' | grep $check_var | grep $CURRENT_USER > /dev/null" ;then
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

# 检查是否是GNOME，不是则退出
IS_GNOME_DE=-1
check_var="gnome"
if echo $DESKTOP_SESSION | grep $check_var > /dev/null ;then
    IS_GNOME_DE="TRUE"
else
    IS_GNOME_DE="FALSE"
    prompt -e "警告：不是GNOME桌面环境，慎用。"
    exit 1
fi

prompt -i "__________________________________________________________"
prompt -i "系统信息: "
prompt -k "用户名：" "$CURRENT_USER"
prompt -k "终端：" "$CURRENT_SHELL"
prompt -k "是否为Sudo组成员：" "$is_sudoer"
prompt -k "Sudo是否免密码：" "$is_sudo_nopasswd"
prompt -k "是否是GNOME：" "$IS_GNOME_DE ( $DESKTOP_SESSION )"
prompt -i "__________________________________________________________"
prompt -e "以上信息如有错误，或者出现了-1，请按 Ctrl + c 中止运行。"


### 这里是确认运行的模块
comfirm "\e[1;31m 您已知晓该一键部署脚本的内容、作用、使用方法以及对您的计算机可能造成的潜在的危害「如果你不知道你在做什么，请直接回车谢谢」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
    prompt -m "开始部署……"
elif [ $choice == 2 ];then
    prompt -w "感谢您的关注！——  https://rmshadows.gitee.io"
    exit 0
fi

:<<检查点一
询问是否将当前用户加入sudo组, 是否sudo免密码（如果已经是sudoer且免密码则跳过）。
临时成为免密sudoer(必选)。
添加用户到sudo组。
设置用户sudo免密码。
默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
更新源、更新系统。
配置unattended-upgrades
检查点一
prompt -i "——————————  检查点一  ——————————"
# 如果没有sudo免密码，临时加入。这里之后才能使用quitThis
if [ "$IS_SUDO_NOPASSWD" -ne 1 ];then
    prompt -x "临时成为免密码sudoer……"
    # 临时成为sudo用户
    doAsRoot "echo '$TEMPORARILY_SUDOER_STRING' >> /etc/sudoers"
    TEMPORARILY_SUDOER=1
fi

# 如果没有在sudo组,添加用户到sudo组
if [ "$IS_SUDOER" -eq 0 ] && [ "$SET_SUDOER" -eq 1 ];then
    prompt -x "添加用户 $CURRENT_USER 到sudo组。"
    sudo usermod -a -G sudo $CURRENT_USER
    IS_SUDOER=1
fi

# 如果已经是sudoer，但没有免密码，询问是否免密码
if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ] && [ "$SET_SUDOER_NOPASSWD" -eq 1 ];then
    prompt -x "设置用户 $CURRENT_USER sudo免密码"
    TEMPORARILY_SUDOER=0
fi

# 预安装
prompt -x "安装部分先决软件包"
doApt update
# 确保https源可用
doApt install apt-transport-https
doApt install ca-certificates
# 保证后面Vbox密钥添加
doApt install wget
doApt install gnupg2
doApt install gnupg
doApt install lsb-release
# 添加清华大学 Debian 11 镜像源
if [ "$SET_APT_SOURCE" -eq 1 ];then
    backupFile "/etc/apt/sources.list"
    prompt -x "添加清华大学 Debian 11 镜像源"
    sudo echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free" | sudo tee /etc/apt/sources.list
# 添加清华大学Debian sid 镜像源
elif [ "$SET_APT_SOURCE" -eq 2 ];then
    backupFile "/etc/apt/sources.list"
    prompt -x "添加清华大学 Debian sid 镜像源"
    sudo echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free" | sudo tee /etc/apt/sources.list
fi

# 配置unattended-upgrades
if [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 0 ];then
    prompt -m "保持原有unattended-upgrades.service状态"
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 1 ];then
    prompt -x "启用unattended-upgrades.service"
    sudo systemctl enable unattended-upgrades.service
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 2 ];then
    prompt -x "禁用unattended-upgrades.service"
    sudo systemctl disable unattended-upgrades.service
fi


# 更新系统
if [ "$SET_APT_UPGRADE" -eq 0 ];then
    prompt -x "仅更新仓库索引"
    doApt update
elif [ "$SET_APT_UPGRADE" -eq 1 ];then
    prompt -x "更新整个系统中"
    doApt update && doApt dist-upgrade
elif [ "$SET_APT_UPGRADE" -eq 2 ];then
    prompt -x "仅更新软件"
    doApt update && doApt upgrade
fi

# 检查APT状态
if [ $? -ne 0 ];then
    prompt -e "APT配置似乎失败了(比如需要手动解锁、网络连接失败，更新失败等)，请手动检查下APT运行状态。"
    quitThis
fi

prompt -i "——————————  检查点二  ——————————"

:<<检查点二
卸载vim-tiny，安装vim-full
替换Bash为Zsh
添加/usr/sbin到环境变量
替换root用户shell配置文件
安装bash-completion
安装zsh-autosuggestions
检查点二
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
            echo "$ZSHRC_CONFIG" > /home/$CURRENT_USER/$shell_conf
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
        echo "$ZSHRC_CONFIG" > /home/$CURRENT_USER/$shell_conf
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
if [ "$SET_BASH_COMPLETION" -eq 1 ];then
    if [ "$shell_conf" == ".zshrc" ];then
        prompt -x "安装zsh-autosuggestions"
        doApt install zsh-autosuggestions
    else
        prompt -e "非ZSH，不安装zsh-autosuggestions"
    fi
fi

:<<检查点三
配置自定义的systemtl服务
配置Nautilus右键菜单以及Data、Project、Vbox-Tra、Prog、Mounted文件夹
配置启用NetworkManager、安装net-tools
设置网卡eth0为热拔插模式以缩短开机时间。如果没有eth0网卡，发出警告、跳过 Preset=0
配置GRUB网卡默认命名方式
检查点三
prompt -i "——————————  检查点三  ——————————"
# 配置自定义的systemtl服务
if [ "$SET_SYSTEMCTL_SERVICE" -eq 1 ];then
    prompt -x "配置自定义的Systemctl服务"
    addFolder /home/$CURRENT_USER/.$CURRENT_USER/
    addFolder /home/$CURRENT_USER/.$CURRENT_USER/scripts/
    prompt -x "生成/home/$CURRENT_USER/.$CURRENT_USER/scripts/autorun.sh脚本"
    echo "#!/bin/bash
echo -e \"\e[1;33m Hello World \e[0m\"
" > /home/$CURRENT_USER/.$CURRENT_USER/scripts/autorun.sh
    sudo chmod +x /home/$CURRENT_USER/.$CURRENT_USER/scripts/autorun.sh
    prompt -x "生成/lib/systemd/system/customize-autorun.service服务"
    if ! [ -f /lib/systemd/system/customize-autorun.service ];then
        sudo echo "[Unit]
Description=自定义的服务，用于开启启动/home/用户/.用户名/script下的shell脚本，配置完成请手动启用。注意，此脚本将以root身份运行！
After=network.target 

[Service]
ExecStart=/home/$CURRENT_USER/.$CURRENT_USER/scripts/autorun.sh
Type=forking
PrivateTmp=True

[Install]
WantedBy=multi-user.target
" > /lib/systemd/system/customize-autorun.service
    fi
fi

# 配置Nautilus右键菜单以及Data、Project、Vbox-Tra、Prog、Mounted文件夹
if [ "$SET_NAUTILUS_MENU" -eq 1 ];then
    prompt -x "配置Nautilus右键菜单以及Data、Project、Vbox-Tra、Prog、Mounted文件夹"
    addFolder /home/$CURRENT_USER/Data
    addFolder /home/$CURRENT_USER/Project
    addFolder /home/$CURRENT_USER/Vbox-Tra
    addFolder /home/$CURRENT_USER/Prog
    addFolder /home/$CURRENT_USER/Mounted
    addFolder /home/$CURRENT_USER/.$CURRENT_USER/
    sudo echo "gnome-system-monitor & " > /home/$CURRENT_USER/.local/share/nautilus/scripts/打开任务管理器
    sudo chmod +x /home/$CURRENT_USER/.local/share/nautilus/scripts/*
    # sudo chown $CURRENT_USER -hR /home/$CURRENT_USER
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
    fi
    prompt -m "重启NetworkManager.service"
    sudo systemctl enable NetworkManager.service 
    sudo systemctl restart NetworkManager.service
    prompt -x "安装Net-tools"
    doApt install net-tools
fi

# 设置网卡eth0为热拔插模式以缩短开机时间。如果没有eth0网卡，发出警告、跳过 Preset=0
if [ "$SET_ETH0_ALLOW_HOTPLUG" -eq 1 ];then
    prompt -m "设置网卡eth0为热拔插模式以缩短开机时间。"
    prompt -m "检查 /etc/network/interfaces.d/setup 中eth0设备是否设置为热拔插..."
    check_var="allow-hotplug eth0"
    if sudo cat '/etc/network/interfaces.d/setup' | grep "$check_var" > /dev/null
    then
        echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
        sudo cat /etc/network/interfaces.d/setup
        prompt -w "您的 eth0 设备似乎已经允许热拔插（如上所列），不做处理。"
    else
        prompt -m "检查 /etc/network/interfaces.d/setup 中是否有eth0设备..."
        check_var="^auto eth0"
        if sudo cat '/etc/network/interfaces.d/setup' | grep "$check_var" > /dev/null
        then
            prompt -x "添加 allow-hotplug eth0 到 /etc/network/interfaces.d/setup 中"
            sudo sed -i 's/auto eth0/# auto eth0\nallow-hotplug eth0/g' /etc/network/interfaces.d/setup
        else
            prompt -e "似乎没有eth0这个设备或者eth0已被手动配置！"
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


:<<检查点四
从APT仓库安装常用软件包
安装Python3
配置Python3源为清华大学镜像
安装配置Apache2
安装配置Git(配置User Email)
安装配置SSH
安装配置npm(是否安装hexo)
检查点四
# 从APT仓库安装常用软件包
if [ "$SET_APT_INSTALL" -eq 1 ];then
    # 准备安装的包名列表
    immediately_task=()
    # 脚本运行结束后要安装的包名
    later_task=()
    # 先判断要安装的列表
    if [ "$SET_APT_INSTALL_LIST_INDEX" -eq 0 ];then
        # 自定义安装
        app_list=$SEAPT_TO_INSTALL_INDEX_0
    elif [ "$SET_APT_INSTALL_LIST_INDEX" -eq 1 ];then
        # 精简安装
        app_list=$APT_TO_INSTALL_INDEX_1
    elif [ "$SET_APT_INSTALL_LIST_INDEX" -eq 2 ];then
        # 部分安装
        app_list=$APT_TO_INSTALL_INDEX_2
    elif [ "$SET_APT_INSTALL_LIST_INDEX" -eq 3 ];then
        # 全部安装
        app_list=$APT_TO_INSTALL_INDEX_3
    fi
    # 首先，处理稍后要安装的软件包
    later_list=$SET_APT_TO_INSTALL_LATER
    later_list=$(echo $later_list | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
    later_list=($later_list)
    later_len=${#later_list[@]}
    prompt -m "下列是脚本运行结束后要安装的软件包: "
    for ((i=0;i<$later_len;i++));do
        each=${later_list[$i]}
        index=`expr index "$each" —`
        # 软件包名
        name=${later_list[$i]/$each/${each:0:($index-1)}}
        # 添加到列表
        later_task[$num]=${name}
        prompt -i "$each"
    done
    sleep 8
    echo -e "\n\n\n"
    # 处理app_list列表
    # 把“- ”转为换行符 然后删除所有空格 最后删除第一行。echo $LST | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d'
    app_list=$(echo $app_list | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
    # 生成新的列表
    app_list=($app_list)
    # 接下来打印要安装的软件包列表, 显示的序号从0开始
    num=0
    app_len=${#app_list[@]}
    prompt -m "下列是即将安装的软件包: "
    for ((i=0;i<$app_len;i++));do
        # 显示序号
        echo -en "\e[1;35m$num)\e[0m"
        each=${app_list[$i]}
        index=`expr index "$each" —`
        # 软件包名
        name=${app_list[$i]/$each/${each:0:($index-1)}}
        immediately_task[$num]=${name}
        prompt -i "$each"
        num=$((num+1))
    done
    sleep 10
    doApt install ${immediately_task[@]}
    if [ $? != 0 ];then
        prompt -e "安装出错，列表中有仓库中没有的软件包。下面将进行逐个安装，按任意键继续。"
        sleep 2
        num=1
        for var in ${immediately_task[@]}
        do
            prompt -m "正在安装第 $num 个软件包: $var。"
            doApt install $var
            num=$((num+1))
        done
    fi 
fi

# 安装Python3
if [ "$SET_PYTHON3_INSTALL" -eq 1 ];then
    prompt -x "安装Python3和pip3"
    doApt install python3
    doApt install python3-pip
fi

# 配置Python3源为清华大学镜像
if [ "$SET_PYTHON3_MIRROR" -eq 1 ];then
    prompt -x "更改pip源为清华大学镜像源"
    doApt install software-properties-common
    doApt install python3-software-properties
    doApt install python3-pip
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
fi

# 安装配置Apache2
if [ "$SET_INSTALL_APACHE2" -eq 1 ];then
    prompt -x "安装Apache2"
    doApt install apache2
    prompt -m "配置Apache2 共享目录为 /home/HTML"
    addFolder /home/HTML
    prompt -x "设置/home/HTML读写权限为755"
    sudo chmod 755 /home/HTML
    if [ $? -eq 0 ];then
        backupFile /etc/apache2/apache2.conf
        prompt -x "修改Apache2配置文件中的共享目录为/home/HTML"
        sudo sed -i 's/\/var\/www\//\/home\/HTML\//g' /etc/apache2/apache2.conf
        sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/home\/HTML/g' /etc/apache2/sites-available/000-default.conf
        if [ "$SET_ENABLE_APACHE2" -eq 0 ];then
            prompt -x "禁用Apache2服务开机自启"
            sudo systemctl disable apache2.service
        elif [ "$SET_ENABLE_APACHE2" -eq 1 ];then
            prompt -x "配置Apache2服务开机自启"
            sudo systemctl enable apache2.service
        fi
    else
        prompt -e "Apache2似乎安装失败了。"
        quitThis
    fi
fi

# 安装配置Git(配置User Email)
if [ "$SET_INSTALL_GIT" -eq 1 ];then
    prompt -x "安装Git"
    doApt install git
    if [ $? -eq 0 ];then
        git config --global user.name $SET_GIT_USER
        git config --global user.email $SET_GIT_EMAIL
    else
        prompt -e "Git似乎安装失败了。"
        quitThis
    fi
fi

# 安装配置SSH
if [ "$SET_INSTALL_OPENSSH" -eq 1 ];then
    doApt install openssh-server
    if [ "$SET_ENABLE_SSH" -eq 1 ];then
        prompt -x "配置SSH服务开机自启"
        sudo systemctl enable ssh.service
    elif [ "$SET_ENABLE_SSH" -eq 0 ];then
        prompt -x "禁用SSH服务开机自启"
        sudo systemctl disable ssh.service
    fi
fi

# 安装配置npm(是否安装hexo)
if [ "$SET_INSTALL_NPM" -eq 1 ];then
    doApt install npm
    if [ "$SET_INSTALL_CNPM" -eq 1 ];then
        if ! [ -x "$(command -v cnpm)" ]; then
            prompt -x "安装CNPM"
            npm install cnpm -g --registry=https://r.npm.taobao.org
        fi
        if [ "$SET_INSTALL_HEXO" -eq 1 ];then
            if ! [ -x "$(command -v hexo)" ]; then
                prompt -x "安装HEXO"
                cnpm install -g hexo-cli
            fi
        fi
    fi
    if [ "$SET_INSTALL_HEXO" -eq 1 ];then
        if ! [ -x "$(command -v hexo)" ]; then
            prompt -x "安装HEXO"
            npm install -g hexo-cli
        fi
    fi
fi

if [ "$SET_INSTALL_NODEJS" -eq 1 ];then
    doApt install nodejs
fi


:<<检查点五
配置中州韵输入法
检查点五
# 配置Fcitx 中州韵输入法
if [ "$SET_INSTALL_RIME" -eq 1 ];then
    prompt -m "通常建议是：在 运行于xorg的GNOME 模式下使用Fcitx输入法(而不是Wayland！)， 模式切换在用户登录页面的小齿轮可以配置。"
    sleep 8
    doApt update
    doApt install fcitx
    doApt install fcitx-rime
    doApt install fcitx-googlepinyin
    doApt install fcitx-module-cloudpinyin
    if ! [ -f "/home/$CURRENT_USER/.pam_environment" ];then
        prompt -x "配置~/.pam_environment文件"
        echo "export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
" > "/home/$CURRENT_USER/.pam_environment"
    else
        prompt -w "如果是Wayland，请自行设置~/.pam_environment(如果Fcitx不运行的话)"
    fi
    if ! [ -f "/home/$CURRENT_USER/.xprofile" ];then
        prompt -x "export QT_IM_MODULE=fcitx5" > "/home/$CURRENT_USER/.xprofile"
    else
        prompt -w "如果是WPS等应用无法使用fcitx，请自行设置~/.xprofile"
    fi
    prompt -m "检查中州韵输入法安装情况……"
    if ! [ -d "/home/$CURRENT_USER/.config/fcitx" ];then
        prompt -e "找不到fcitx的配置文件夹/home/$CURRENT_USER/.config/fcitx"
        quitThis
    fi
    if ! [ -d "/home/$CURRENT_USER/.config/fcitx/rime" ];then
        prompt -e "找不到fcitx-rime的配置文件夹/home/$CURRENT_USER/.config/fcitx/rime"
        quitThis
    fi
    prompt -x "im-config 切换 fcitx, 注销生效"
    im-config -n fcitx
    rime_config_dir="/home/$CURRENT_USER/.config/fcitx/rime/"
elif [ "$SET_INSTALL_RIME" -eq 2 ];then
    doApt update
    doApt install ibus
    doApt install ibus-rime
    if ! [ -f "/home/$CURRENT_USER/.xprofile" ];then
        prompt -x "export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
ibus-daemon -d -x
" > "/home/$CURRENT_USER/.xprofile"
    else
        prompt -w "如果你在输入中文时遇到问题，检查你的 locale 设置。并自行设置~/.xprofile"
    fi
    prompt -w "如果 IBus 确实已经启动，但是在 LibreOffice 里没有出现输入窗口，你需要在 ~/.bashrc (或者.zshrc) 里加入这行：export XMODIFIERS=@im=ibus"
    prompt -m "检查中州韵输入法安装情况……"
    if ! [ -d "/home/$CURRENT_USER/.config/ibus" ];then
        prompt -e "找不到ibus的配置文件夹/home/$CURRENT_USER/.config/ibus"
        quitThis
    fi
    if ! [ -d "/home/$CURRENT_USER/.config/ibus/rime" ];then
        prompt -e "找不到ibus-rime的配置文件夹/home/$CURRENT_USER/.config/ibus/rime"
        quitThis
    fi
    rime_config_dir="/home/$CURRENT_USER/.config/ibus/rime"
    im-config -n ibus
elif [ "$SET_INSTALL_RIME" -eq 3 ];then
    doApt update
    doApt install fcitx5
    doApt install fcitx5-rime
    doApt install fcitx5-module-cloudpinyin
    if ! [ -f "/home/$CURRENT_USER/.pam_environment" ];then
        prompt -x "GTK_IM_MODULE DEFAULT=fcitx
QT_IM_MODULE  DEFAULT=fcitx
XMODIFIERS    DEFAULT=\@im=fcitx
SDL_IM_MODULE DEFAULT=fcitx
" > "/home/$CURRENT_USER/.pam_environment"
    else
        prompt -w "如果是Wayland，请自行设置~/.pam_environment(如果Fcitx不运行的话)"
    fi
    if ! [ -f "/home/$CURRENT_USER/.xprofile" ];then
        prompt -x "export QT_IM_MODULE=fcitx5" > "/home/$CURRENT_USER/.xprofile"
    else
        prompt -w "如果是WPS等应用无法使用fcitx，请自行设置~/.xprofile"
    fi
    prompt -m "检查中州韵输入法安装情况……"
    if ! [ -d "/home/$CURRENT_USER/.local/share/fcitx5" ];then
        prompt -e "找不到ibus的配置文件夹/home/$CURRENT_USER/.local/share/fcitx5"
        quitThis
    fi
    if ! [ -d "/home/$CURRENT_USER/.local/share/fcitx5/rime" ];then
        prompt -e "找不到ibus-rime的配置文件夹/home/$CURRENT_USER/.local/share/fcitx5/rime"
        quitThis
    fi
    rime_config_dir="/home/$CURRENT_USER/.local/share/fcitx5/rime"
    im-config -n fcitx5
fi
# 开始配置词库
if [ "$SET_INSTALL_RIME" -ne 0 ];then
    prompt -m "检查完成，开始配置词库"
    if [ "$SET_IMPORT_RIME_DICT" -eq 0 ];then
        prompt -m "不导入词库,但保留词库添加功能。"
        echo "$RIME_DICT_HEADER" > $rime_config_dir/luna_pinyin_simp.custom.yaml
        echo "$RIME_DICT_UDICT" > $rime_config_dir/luna_pinyin.udict.dict.yaml
    elif [ "$SET_IMPORT_RIME_DICT" -eq 1 ];then
        prompt -x "从Github导入词库。"
        if ! [ -x "$(command -v git)" ];then
            doApt install git
        fi
        git clone https://github.com/rime-aca/dictionaries.git
        cp dictionaries/luna_pinyin.dict/* $rime_config_dir
    elif [ "$SET_IMPORT_RIME_DICT" -eq 2 ];then
        prompt -x "导入本地词库。"
        cp $SET_RIME_DICT_DIR/* $rime_config_dir
    fi
fi

:<<检查点六
配置SSH Key
检查点六
# 配置SSH Key
if [ "$SET_CONFIG_SSH_KEY" -eq 1 ];then
    if [ -f "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME" ] | [ -f "/home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub" ];then
        prompt -e "/home/$CURRENT_USER/.ssh/似乎已经存在 "$SET_SSH_KEY_NAME" 的SSH Key,跳过配置。"
    else
        if [ "$SET_SSH_KEY_SOURCE" -eq 0 ];then
            prompt -x "生成新的SSH Key 密码:"
            ssh-keygen -t rsa -N "$SET_NEW_SSH_KEY_PASSWD" -C "$SET_SSH_KEY_COMMENT" -f /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME
        elif [ "$SET_SSH_KEY_SOURCE" -eq 1 ];then
            prompt -x "将存在的SSH Key从 $SET_EXISTED_SSH_KEY_SRC 移动到 /home/$CURRENT_USER/.ssh/"
            mv $SET_EXISTED_SSH_KEY_SRC /home/$CURRENT_USER/.ssh/
        elif [ "$SET_SSH_KEY_SOURCE" -eq 2 ];then
            prompt -x "从文本导入SSH Key到 /home/$CURRENT_USER/.ssh/"
            echo $SET_SSH_KEY_PRIVATE_TEXT > /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME
            echo $SET_SSH_KEY_PUBLIC_TEXT > /home/$CURRENT_USER/.ssh/$SET_SSH_KEY_NAME.pub
        fi
    fi
fi


:<<检查点七
导入GNOME Terminal的dconf配置
导入GNOME 您自定义修改的系统内置快捷键的dconf配置
导入GNOME 自定义快捷键的dconf配置
检查点七
# 导入GNOME Terminal的dconf配置
if [ "$SET_IMPORT_GNOME_TERMINAL_DCONF" -ne 0 ];then
    # dconf reset -f /
    # dconf load / < ostechnix-desktop
fi
# 导入GNOME 您自定义修改的系统内置快捷键的dconf配置
if [ "$SET_IMPORT_GNOME_WM_KEYBINDINGS_DCONF" -ne 0 ];then
    
fi
# 导入GNOME 自定义快捷键的dconf配置
if [ "$SET_IMPORT_GNOME_CUSTOM_KEYBINDINGS_DCONF" -ne 0 ];then
    
fi
# dconf dump /org/gnome/terminal/ > dconf-gonme-terminal
# dconf dump /org/gnome/desktop/wm/keybindings/ > dconf-custom-wm-keybindings
# dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > dconf-custom-keybindings



## 下面是滞后的步骤
:<<安装时间较长的软件包
VirtualBox
Anydesk
typora
sublime text
teamviewer
wps-office
skype
docker-ce
安装网易云音乐
禁用第三方软件仓库更新(提升apt体验)
安装时间较长的软件包
# 安装later_task中的软件
if [ "$SET_APT_INSTALL" -eq 1 ];then
    doApt install ${later_task[@]}
    if [ $? != 0 ];then
        prompt -e "安装出错，列表中有仓库中没有的软件包。下面将进行逐个安装，按任意键继续。"
        sleep 2
        num=1
        for var in ${later_task[@]}
        do
            prompt -m "正在安装第 $num 个软件包: $var。"
            doApt install $var
            num=$((num+1))
        done
    fi 
fi

# 安装Virtual Box
if [ "$SET_INSTALL_VIRTUALBOX" -eq 1 ];then
    prompt -x "安装Virtual Box"
    if ! [ -x "$(command -v virtualbox)" ]; then
        prompt -m "检查是否为Sid源"
        is_debian_sid=0
        sid_var1="debian/ sid main"
        sid_var2="debian sid main"
        if sudo cat '/etc/apt/sources.list' | grep "$sid_var1" > /dev/null
        then
            is_debian_sid=1
        fi
        if sudo cat '/etc/apt/sources.list' | grep "$sid_var2" > /dev/null
        then
            is_debian_sid=1
        fi
        if [ "$is_debian_sid" -eq 1 ];then
            prompt -m "检测到使用的是Debian sid源，直接从源安装"
            doApt install virtualbox
        else
            if [ "$SET_VIRTUALBOX_REPO" -eq 0 ];then
                prompt -m "不是sid源，添加官方仓库"
                # https://suay.site/?p=526
                sudo curl https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg --import
                sudo chmod 644 /etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg
                # wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
                # wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
                sudo echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian bullseye contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
            elif [ "$SET_VIRTUALBOX_REPO" -eq 1 ];then
                prompt -m "不是sid源，添加清华大学镜像仓库"
                curl https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg --import
                sudo chmod 644 /etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg
                # wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
                sudo echo "deb http://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/ bullseye contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
            fi
            doApt update
            doApt install virtualbox
        fi
    else
        prompt -m "您可能已经安装了VirtualBox"
    fi
    prompt -x "添加用户到vboxusers组"
    sudo usermod -aG vboxusers $CURRENT_USER
fi

# 安装Anydesk
if [ "$SET_INSTALL_ANYDESK" -eq 1 ];then
    if ! [ -x "$(command -v anydesk)" ]; then
        prompt -x "安装Anydesk"
        curl https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/anydesk.gpg --import
        sudo chmod 644 /etc/apt/trusted.gpg.d/anydesk.gpg
        # wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add -
        sudo echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
        doApt update
        doApt install anydesk
    else
        prompt -m "您可能已经安装了Anydesk"
    fi
    if [ "$SET_ENABLE_ANYDESK" -eq 0 ];then
        prompt -x "禁用Anydesk服务开机自启"
        sudo systemctl disable anydesk.service
    elif [ "$SET_ENABLE_ANYDESK" -eq 1 ];then
        prompt -x "配置Anydesk服务开机自启"
        sudo systemctl enable anydesk.service
    fi
fi

# 安装typora
if [ "$SET_INSTALL_TYPORA" -eq 1 ];then
    if ! [ -x "$(command -v typora)" ]; then
        prompt -x "安装typora"
        curl https://typora.io/linux/public-key.asc | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/typora.gpg --import
        sudo chmod 644 /etc/apt/trusted.gpg.d/typora.gpg
        sudo echo "deb https://typora.io/linux ./" | sudo tee /etc/apt/sources.list.d/typora.list
        doApt update
        doApt install typora
    else
        prompt -m "您可能已经安装了Typora"
    fi
fi

# 安装sublime-text
if [ "$SET_INSTALL_SUBLIME_TEXT" -eq 1 ];then
    if ! [ -x "$(command -v sublime-text)" ]; then
        prompt -x "安装sublime-text"
        curl https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/sublimehq-pub.gpg --import
        sudo chmod 644 /etc/apt/trusted.gpg.d/sublimehq-pub.gpg
        sudo echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        doApt update
        doApt install sublime-text
    else
        prompt -m "您可能已经安装了Sublime"
    fi
fi

# 安装Teamviewer
if [ "$SET_INSTALL_TEAMVIEWER" -eq 1 ];then
    if ! [ -x "$(command -v teamviewer)" ]; then
        prompt -x "安装teamviewer"
        wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
        doApt install ./teamviewer_amd64.deb
    else
        prompt -m "您可能已经安装了Teamviewer"
    fi
    if [ "$SET_ENABLE_TEAMVIEWER" -eq 0 ];then
        prompt -x "禁用Teamviewer服务开机自启"
        sudo systemctl disable teamviewerd.service
    elif [ "$SET_ENABLE_TEAMVIEWER" -eq 1 ];then
        prompt -x "配置Teamviewer服务开机自启"
        sudo systemctl enable teamviewerd.service
    fi
fi

# 安装wps-office
if [ "$SET_INSTALL_WPS_OFFICE" -eq 1 ];then
    if ! [ -x "$(command -v wps)" ]; then
        prompt -x "安装wps-office"
        # wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9615/wps-office_11.1.0.9615_amd64.deb
        # 较稳定版本
        # wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/10161/wps-office_11.1.0.10161_amd64.deb
        wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/10702/wps-office_11.1.0.10702_amd64.deb
        doApt install ./wps-office*amd64.deb
    else
        prompt -m "您可能已经安装了WPS"
    fi
fi

# 安装skype
if [ "$SET_INSTALL_SKYPE" -eq 1 ];then
    if ! [ -x "$(command -v skypeforlinux)" ]; then
        prompt -x "安装Skype国际版"
        wget https://go.skype.com/skypeforlinux-64.deb
        doApt install ./skypeforlinux-64.deb
    else
        prompt -m "您可能已经安装了Skype"
    fi
fi

# 安装Docker-ce
if [ "$SET_INSTALL_TEAMVIEWER" -eq 1 ];then
    if ! [ -x "$(command -v docker)" ]; then
        prompt -x "安装Docker-ce"
        prompt -x "卸载旧版本"
        sudo doApt remove docker docker-engine docker.io
        if [ "$SET_DOCKER_CE_REPO" -eq 0 ];then
            prompt -m "添加官方仓库"
            # # /usr/share/keyrings/docker-archive-keyring.gpg
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
            sudo chmod 644 /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
            sudo echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        elif [ "$SET_DOCKER_CE_REPO" -eq 1 ];then
            prompt -m "添加清华大学镜像仓库"
            curl https://download.docker.com/linux/debian/gpg | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/docker-archive-keyring.gpg --import
            sudo chmod 644 /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
            sudo echo \
       "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian \
       $(lsb_release -cs) \
       stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        doApt update
        doApt install docker-ce # docker-ce-cli containerd.io
    else
        prompt -m "您可能已经安装了Docker"
    fi
    if [ "$SET_ENABLE_DOCKER_CE" -eq 0 ];then
        prompt -x "禁用docker-ce服务开机自启"
        sudo systemctl disable docker.service
    elif [ "$SET_ENABLE_DOCKER_CE" -eq 1 ];then
        prompt -x "配置docker-ce服务开机自启"
        sudo systemctl enable docker.service
    fi
fi

# 安装网易云音乐
if [ "$SET_INSTALL_NETEASE_CLOUD_MUSIC" -eq 1 ];then
    if ! [ -x "$(command -v netease-cloud-music)" ]; then
        prompt -x "安装网易云音乐"
        wget https://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb
        doApt install ./netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb
    else
        prompt -m "您可能已经安装了netease-cloud-music"
    fi
fi


#### 禁用第三方仓库更新
if [ "$SET_DISABLE_THIRD_PARTY_REPO" -eq 1 ];then
    prompt -x "禁用第三方软件仓库更新"
    addFolder /etc/apt/sources.list.d/backup
    sudo mv /etc/apt/sources.list.d/* /etc/apt/sources.list.d/backup/
fi

# 设置用户目录权限
if [ "$SET_USER_HOME" -eq 1 ];then
    prompt -x "设置用户目录权限"
    sudo chown $CURRENT_USER -hR /home/$CURRENT_USER
    sudo chmod 700 /home/$CURRENT_USER
fi

# Y
echo -e "\e[1;32m
_________  .___ ____   ____.___ _________  _________  _________  _________  _________  
\_   ___ \ |   |\   \ /   /|   |\_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ 
/    \  \/ |   | \   Y   / |   |/    \  \/ /    \  \/ /    \  \/ /    \  \/ /    \  \/ 
\     \____|   |  \     /  |   |\     \____\     \____\     \____\     \____\     \____
 \______  /|___|   \___/   |___| \______  / \______  / \______  / \______  / \______  /
        \/                              \/         \/         \/         \/         \/ 
        "
# G
echo -e "\e[1;32m ————————————    感谢使用    ———————————— \e[0m"
onExit
