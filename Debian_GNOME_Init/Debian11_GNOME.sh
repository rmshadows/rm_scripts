#!/bin/bash
# https://github.com/rmshadows/rm_scripts

:<<!说明
Version：0.0.1
预设参数（在这里修改预设参数, 谢谢）
注意：如果没有注释，默认0 为否 1 为是。
!说明

## 检查点一：
# 使用的APT源
:<<!
0:跳过
1:清华大学镜像源
2:清华大学Sid镜像源
!
SET_APT_SOURCE=0
# 是否加入sudo组
SET_SUDOER=0
# 是否设置sudo无需密码
SET_SUDOER_NOPASSWD=0


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
    "-ss"|"--exec")
      echo -e "日志：${b_CGSC}${@/-s/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-ii"|"--iinfo")
      echo -e "信息：${b_CCIN}${@/-i/}${CDEF}";;          # print iinfo message
    "-k"|"--kv") # TODO
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
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

# 程序中断处理方法
onSigint () {
    # 临时加入sudoer，退出时清除
    if [ $TEMPORARILY_SUDOER -eq 1 ] ;then
        prompt -ss "清除临时sudoer免密权限。"
        sudo sed -i "s/$TEMPORARILY_SUDOER_STRING/ /g" /etc/sudoers
    fi
    prompt -w "捕获到中断信号..."
    exit 1
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
IS_SUDOER=0
is_sudoer=-1
IS_SUDO_NOPASSWD=0
is_sudo_nopasswd=-1
# 检查是否在sudo组
if groups| grep sudo > /dev/null ; then
    # 是sudo组
    IS_SUDOER=1
    is_sudoer="TRUE"
    # 检查是否免密码sudo
    check_var="ALL=(ALL)NOPASSWD:ALL"
    if sudo cat '/etc/sudoers' | grep $check_var | grep $CURRENT_USER > /dev/null ;then
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
prompt -w "用户名：$CURRENT_USER"
prompt -w "终端：$CURRENT_SHELL"
prompt -w "是否为Sudo组成员：$is_sudoer"
prompt -w "Sudo是否免密码：$is_sudo_nopasswd"
prompt -w "是否是Debian Sid：$IS_DEBIAN_SID"
prompt -w "是否是GNOME：$IS_GNOME_DE ( $DESKTOP_SESSION )"
prompt -i "__________________________________________________________"
prompt -e "以上信息如有错误，或者出现了-1，请按 Ctrl + c 中止运行。"


### 这里是确认运行的模块 TODO
:<<!
comfirm "\e[1;31m 您已知晓该一键部署脚本的内容、作用、使用方法以及对您的计算机可能造成的潜在的危害「如果你不知道你在做什么，请直接回车」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
    prompt -ii "开始部署……"
elif [ $choice == 2 ];then
    prompt -w "感谢您的关注！——  https://rmshadows.gitee.io"
    exit 0
fi
!

:<<检查点一
询问是否将当前用户加入sudo组, 是否sudo免密码（如果已经是sudoer且免密码则跳过）。
检查点一

# 如果没有sudo免密码，临时加入。
if [ "$IS_SUDO_NOPASSWD" -nq 1 ];then
    prompt -ss "临时成为免密码sudoer……"
    prompt -w "请输入 root 用户密码："
    # 临时成为sudo用户
    su - root -c "echo $TEMPORARILY_SUDOER_STRING >> /etc/sudoers"
    TEMPORARILY_SUDOER=1
fi

# 如果没有在sudo组,添加用户到sudo组
if [ "$IS_SUDOER" -eq 0 ] && [ "$SET_SUDOER" -eq 1 ];then
    prompt -ss "添加用户 $CURRENT_USER 到sudo组。"
    # TODO sudo usermod -a -G sudo $CURRENT_USER
    IS_SUDOER=1
fi

# 如果已经是sudoer，但没有免密码，询问是否免密码
if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ] && [ "$SET_SUDOER_NOPASSWD" -eq 1 ];then
    prompt -ss "设置用户 $CURRENT_USER sudo免密码"
    TEMPORARILY_SUDOER=0
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
