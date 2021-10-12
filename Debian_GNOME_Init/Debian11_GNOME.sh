#!/bin/bash
# https://github.com/rmshadows/rm_scripts

:<<!说明
Version：0.0.1
预设参数（在这里修改预设参数, 谢谢）
注意：如果没有注释，默认0 为否 1 为是。
!说明
# root用户密码
ROOT_PASSWD=""
## 检查点一：
# 使用的APT源 Preset:1
:<<!
0:跳过
1:清华大学镜像源
2:清华大学Sid镜像源
!
SET_APT_SOURCE=0
# 更新与安装是否不过问 Preset:1
SET_APT_UPGRADE_WITHOUT_ASKING=0
# 是否在安装软件前更新整个系统 Preset:1
:<<!
0:just apt update
1:apt dist-upgrade
2:apt upgrade
!
SET_APT_UPGRADE=0
# 是否加入sudo组 Preset:1
SET_SUDOER=0
# 是否设置sudo无需密码 Preset:1
SET_SUDOER_NOPASSWD=0
## 检查点二：
# 是否卸载vim-tiny，安装vim-full Preset:1
SET_VIM_TINY_TO_FULL=0
# 是否替换Bash为Zsh（包括root用户） Preset:1
SET_BASH_TO_ZSH=1
# 是否配置ZSHRC Preset:1
SET_ZSHRC=0
# 是否替换root用户的shell配置文件(如.bashrc)为用户配置文件 Preset:1
SET_REPLACE_ROOT_RC_FILE=1
## 检查点三：
# 添加/usr/sbin到环境变量 Preset=1
SET_ADD_SBIN_ENV=1


#### 列表项
# 『8』LST列表中请不要使用中括号
LST="
- aircrack-ng——aircrack-ng
- apt-listbugs——apt显示bug信息
- apt-listchanges——apt显示更改
- apt-transport-https——apt-transport-https
- arp-scan——arp-scan
- axel——axel下载器
- bash-completion——终端自动补全
- bleachbit——系统清理软件
- blender——3D开发
- bridge-utils——网桥
- build-essential——开发环境
- bustle——D-Bus记录
- calibre——Epub等多格式电子书阅读器
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
- gnome-recipes——GNOME西餐菜单
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
- pulseeffects——pulse audio的调音器
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
- zenity——显示GTK+对话框
- zhcon——tty中文虚拟
- zsh——zsh
- zsh-autosuggestions——zsh插件
"

# 『8』这个数组列表是指定额外情况的软件列表及指定原因。
# 格式：软件名；原因
# 注意：冒号是中文的冒号，每一项之间用空格或者回车隔开。而且包名和原因中不能出现中文冒号和空格。
EX_LST=(
apt-listbugs；阻碍自动安装，请过后手动安装
apt-listchanges；阻碍自动安装，请过后手动安装
bustle；D-Bus记录器，无需求免安装
calibre；Epub等多格式电子书阅读器，体积较大，87M
extremetuxracer；游戏
freeplane；思维导图，无需求免安装
fritzing；电路设计，无需求免安装
glance；需手动配置，无需求免安装
gnome-recipes；西餐为主的菜单
gtranslator；GNOME本地应用翻译编辑，无需求免安装
hugin；全景照片拼合工具，无需求免安装
homebank；家庭账本，无需求免安装
isc-dhcp-server；DHCP服务器，无需求免安装
linux-headers-$(uname -r)；Linux头部，无需求免安装
paperwork-gtk；办公文档扫描，无需求免安装
pulseeffects；可能影响到原音频系统
supertuxkart；游戏
sweethome3d；室内设计，无需求免安装
)


### 脚本变量
# Root用户UID
ROOT_UID=0
# 当前 Shell名称
CURRENT_SHELL=$SHELL
# 是否临时加入sudoer
TEMPORARILY_SUDOER=0
# 第一次运行DoAsRoot
FIRST_DO_AS_ROOT=1

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
      echo -e "日志：${b_CGSC}${@/-s/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-m"|"--msg")
      echo -e "信息：${b_CCIN}${@/-i/}${CDEF}";;          # print iinfo message
    "-k"|"--kv")  # 三个参数
      echo -e "${b_CCIN} ${2} ${b_CWAR} ${3} ${CDEF}";;          # print success message
    *)
    echo -e "$@"
    ;;
  esac
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
su - root <<!>/dev/null 2>&1
$ROOT_PASSWD
echo " Exec $1 as root"
$1
!
}

# 检查root密码是否正确
checkRootPasswd () {
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

# 执行apt命令
doApt () {
    if [ "$1" = "install" ];then
        if [ "$SET_APT_UPGRADE_WITHOUT_ASKING" -eq 0 ];then
            sudo apt-get $@
        elif [ "$SET_APT_UPGRADE_WITHOUT_ASKING" -eq 1 ];then
            sudo apt-get $@ -y
        fi
    else
        sudo apt $@
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
# git相关偷懒操作
# alias gitac='git add . -A && git commit -m \"update\"'
# alias hcg='hexo clean && hexo g'
# alias gitam='git add . -A && git commit -m '
# alias githardpull='git fetch --all && git reset --hard origin/main && git pull'
# apache2 & nginx
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
# sleep 1 TODO

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


### 这里是确认运行的模块 TODO
:<<!
comfirm "\e[1;31m 您已知晓该一键部署脚本的内容、作用、使用方法以及对您的计算机可能造成的潜在的危害「如果你不知道你在做什么，请直接回车谢谢」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
    prompt -m "开始部署……"
elif [ $choice == 2 ];then
    prompt -w "感谢您的关注！——  https://rmshadows.gitee.io"
    exit 0
fi
!

:<<检查点一
询问是否将当前用户加入sudo组, 是否sudo免密码（如果已经是sudoer且免密码则跳过）。
检查点一

# 如果没有sudo免密码，临时加入。
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

# 更换源
# 确保https源可用
doApt update
doApt install apt-transport-https ca-certificates
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
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free" > /etc/apt/sources.list
# 添加清华大学Debian sid 镜像源
elif [ "$SET_APT_SOURCE" -eq 2 ];then
    backupFile "/etc/apt/sources.list"
    prompt -x "添加清华大学 Debian sid 镜像源"
    sudo echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free" > /etc/apt/sources.list
fi

# 更新系统
if [ "$SET_APT_UPGRADE" -eq 0 ];then
    prompt -x "仅更新仓库索引"
    doApt update
elif [ "$SET_APT_UPGRADE" -eq 1 ];then
    prompt -x "更新整个系统中"
    doApt dist-upgrade
elif [ "$SET_APT_UPGRADE" -eq 2 ];then
    prompt -x "仅更新软件"
    doApt upgrade
fi


:<<检查点二
卸载vim-tiny，安装vim-full
替换Bash为Zsh
替换root用户shell配置文件
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
        shell_conf=".zshrc"
        prompt -x "配置ZSHRC"
        echo "$ZSHRC_CONFIG" > /home/$CURRENT_USER/$shell_conf
        prompt -x "为root用户和当前用户设置ZSH"
        sudo usermod -s /bin/zsh root
        sudo usermod -s /bin/zsh $CURRENT_USER
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
# 替换root用户的SHELL配置
if [ "$SET_REPLACE_ROOT_RC_FILE" -eq 0 ];then
    prompt -m "保留root用户SHELL配置"
elif [ "$SET_REPLACE_ROOT_RC_FILE" -eq 1 ];then
    backupFile "/root/$shell_conf"
    prompt -x "替换root用户的SHELL配置文件"
    sudo cp /home/$CURRENT_SHELL/$shell_conf /root/
fi
# 添加/usr/sbin到环境变量
if [ "$SET_REPLACE_ROOT_RC_FILE" -eq 0 ];then
    prompt -m "保留root用户SHELL配置"
elif [ "$SET_REPLACE_ROOT_RC_FILE" -eq 1 ];then
    prompt -x "替换root用户的SHELL配置文件"
    prompt -m "检查该变量是否已经添加…… "
    check_var="export PATH=\"\$PATH:/usr/sbin\""
    if "cat '/home/$CURRENT_USER/$shell_conf' | grep $check_var > /dev/null" ;then
        prompt -w "环境变量  $check_var  已存在,不执行添加。"
    else
        prompt -x "添加/usr/sbin到用户变量"
        echo "export PATH=\"\$PATH:/usr/sbin\"" >> /home/$CURRENT_USER/$shell_conf
    fi
fi

# TODO


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
