#!/bin/bash
# Version：3.3.7
# https://github.com/rmshadows/rm_scripts

# 红色：警告、重点
# 黄色：询问
# 绿色：执行
# 蓝色、白色：常规信息

# Root用户UID
ROOT_UID=0
# Shell名称
Shell=$SHELL
# 是否使用的是sid
sid=false


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

# zshrc 配置文件。修改：所有的“$”“\”“`”“"”全都加\转义
zshrc_config="# ~/.zshrc file for zsh non-login shells.
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
# alias gitac='git add . -A && git commit -m \"update\"'
# alias hcg='hexo clean && hexo g'
# alias gitam='git add . -A && git commit -m '
# alias githardpull='git fetch --all && git reset --hard origin/master && git pull'
alias duls='du -sh ./*'
alias dulsd='du -sh \`la\`'
alias zshrc='vim '\$HOME'/.zshrc'
alias szsh='source '\$HOME'/.zshrc'
alias apastart='sudo systemctl start apache2.service'
alias apastop='sudo systemctl stop apache2.service'
alias ngxstop='sudo systemctl stop nginx.service'
alias ngxstop='sudo systemctl stop nginx.service'
alias systemctl='sudo systemctl'
alias apt='sudo apt-get'
alias update='sudo apt update && sudo apt upgrade'
unset _JAVA_OPTIONS

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi
"

#### 函数调用
## 控制台颜色输出
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
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

## 询问函数 Yes:1 No:2 ???:5
:<<!
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
!
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
┃使用须知：                              ┃
┃\e[1;31m运行环境：Linux Terminal(终端)          \e[1;32m┃
┃\e[1;31m系统要求：Debian Buster GNOME Desktop   \e[1;32m┃
┃\e[1;31m权限要求：需要管理员权限                \e[1;32m┃
┃\e[1;31m使用前请用普通用户身份执行\"xhost +\"命令 \e[1;32m┃
┃\e[1;32m——————————————————————————————————————— ┃
┃使用方法：                              ┃
┃\e[1;33m1.首先给予运行权限：                    \e[1;32m┃
┃\e[1;34msudo chmod +x 「这个脚本的文件名」      \e[1;32m┃
┃\e[1;33m2.运行脚本：                            \e[1;32m┃
┃\e[1;34msudo 「脚本的路径(包括脚本文件名)」     \e[1;32m┃
┃\e[1;33m3.分步运行，需要根据提示进行操作！      \e[1;32m┃
┗ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┛ 
==========================================

\e[0m"
# R
echo -e "\e[1;31m接下来请根据提示进行操作，正在准备(1s)...\n\e[0m"
sleep 1

# 检查是否有root权限，无则退出，提示用户使用root权限。
prompt -i "\n检查权限  ——    Checking for root access...\n"
if [ "$UID" -eq "$ROOT_UID" ]; then
  prompt -s "\n——————————  Unit Ready  ——————————\n"
else
  # Error message
  prompt -e "\n [ Error ] -> 请使用管理员权限(sudo)运行 Please run as root  \n"
  exit 1
fi


###############################################################一

# 检查点一：读取用户输入的用户名，如果是root，则退出。如果是Bash，询问是否更改为Zsh。询问是否替换zsh配置文件。
# R
comfirm "\e[1;31m『1』您已知晓该一键部署脚本的内容、作用、使用方法以及对您的计算机可能造成的潜在的危害「如果你不知道你在做什么，请直接回车」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # 读取用户名并判断是否为root
  # R
  echo -e "\e[1;31m请输入指定用户的用户名「一般是你当前用户的用户名」！用户名请使用小写 ！：\e[0m"
  read -r username
  if [ $username == 'root' ]
  then
    # R
    echo -e "\e[1;31m请不要指定超级用户！
退出！\e[0m"
    exit 1
  fi
  
  # 判断当前Shell，如果不是bash或者zsh，退出，不执行此脚本。
  prompt -i "当前终端：$Shell"
  if [ "$Shell" == "/bin/bash" ]; then
    shell_conf=".bashrc"
    # 询问用户是否将root和当前用户的shell替换为zsh
    comfirm "\e[1;33m是否将root用户和当前用户的Shell更改为zsh? [y/N]\e[0m"
    choice=$?
    if [ $choice == 1 ];then
      # 判断是否安装zsh
      if ! [ -x "$(command -v zsh)" ]; then
        echo 'Error: Zsh is not installed.' >&2
        sudo apt update && sudo apt install zsh -y
      fi
    shell_conf=".zshrc"
    echo "$zshrc_config" > /home/$username/$shell_conf
    sudo usermod -s /bin/zsh root
    sudo usermod -s /bin/zsh $username
    prompt -i "现在请重新打开终端验证更改是否完成，验证成功后请重新执行本脚本！"
    exit 0
    elif [ $choice == 2 ];then
      prompt -w "用户拒绝更换Shell，略过……"
    else
      prompt -e "ERROR:未知返回值!"
      exit 5
    fi
  elif [ "$Shell" == "/bin/zsh" ];then
    shell_conf=".zshrc"
    comfirm "\e[1;33m已检测到您用的是zsh，是否替换用户本地“.zshrc”为博主CIVICCCCC的配置【将会备份旧的zsh配置文件】? [y/N]\e[0m"
    choice=$?
    if [ $choice == 1 ];then
      if [ -f "/home/$username/$shell_conf.bak" ];then
        # B
        echo -e "\e[1;34m用户的$shell_conf.bak文件存在,将新建baknew文件。\e[0m"
        cp /home/$username/$shell_conf /home/$username/$shell_conf.baknew
      else
        # B
        echo -e "\e[1;34m正在备份原$shell_conf文件。\e[0m"
        cp /home/$username/$shell_conf /home/$username/$shell_conf.bak
      fi
      echo "$zshrc_config" > /home/$username/$shell_conf
    elif [ $choice == 2 ];then
      prompt -i "Pass"
    else
      prompt -e "ERROR:未知返回值!"
  exit 5
fi
    
  else
    # Error message
    prompt -e "\n [ Error ] -> 无法识别的shell: $Shell  \n"
    exit 1
  fi
elif [ $choice == 2 ];then
  prompt -w "感谢您的关注！——  https:rmshadows.gitee.io"
  exit 1
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################二

# 检查点二：更新apt镜像
# Y
comfirm "\e[1;33m『2』是否更改Debian镜像源为清华大学[仅支持Buster、Bullseye或者Sid]? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m开始更改镜像，更改为清华大学镜像源。\e[0m"
  # 如果有bak备份文件会直接覆盖生成baknew文件后修改
  if [ -f "/etc/apt/sources.list.bak" ];then
    # R
    echo -e "\e[1;31m检测到sources.list.bak旧备份文件存在,将生成（覆盖）新备份baknew文件\e[0m"
    cp /etc/apt/sources.list /etc/apt/sources.list.baknew
  else
    # G
    echo -e "\e[1;32m备份sources.list文件到sources.list.bak\e[0m"
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
  fi
  prompt -i "支持的源："
  # B
  echo -en "\e[1;34m
1）buster
2）bullseye
3）sid
\e[0m"
  # Y
  echo -en "\e[1;33m备份完成，请输入要更改的镜像源：\e[0m"
  read -r inp
  if [ $inp == 1 ]
  then
      echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free" > /etc/apt/sources.list
  elif [ $inp == 2 ]
  then
    echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free" > /etc/apt/sources.list
  elif [ $inp == 3 ]
  then
    echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free" > /etc/apt/sources.list
  else
    exit 1
  fi

  # B
  echo -e "\e[1;34m显示sources文件内容
=============================================================================\e[0m"
  cat /etc/apt/sources.list
  # B
  echo -e "\e[1;34m=============================================================================\e[0m"
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################三

# 检查点三：更新软件索引、系统
# Y
comfirm "\e[1;33m『3』是否更新软件索引? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m开始更新软件仓库索引\e[0m"
  apt update && apt dist-upgrade -y
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################四

# 检查点四：添加nautilus右键菜单
# Y
comfirm "\e[1;33m『4』是否添加nautilus右键菜单模板并添加Prog等文件夹? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # B
  echo -e "\e[1;34m新建Data、Project、Vbox-Tra、Prog、Mounted\e[0m"
  mkdir /home/$username/Data
  mkdir /home/$username/Project
  mkdir /home/$username/Vbox-Tra
  mkdir /home/$username/Prog
  mkdir /home/$username/Mounted
  echo -e "\e[1;32m 配置nautilus右键菜单 \e[0m"
  mkdir /home/$username/.$username
  echo "echo 'Hello'" | sudo tee /home/$username/.local/share/nautilus/scripts/模板
  sudo chmod +x /home/$username/.local/share/nautilus/scripts/*
  sudo chown $username -hR /home/$username
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################五

# 检查点五：安装vim-full，卸载vim-tiny；
# Y
comfirm "\e[1;33m『5』是否卸载vim-tiny? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m 正在卸载vim-tiny，将安装vim-full \e[0m"
  apt remove vim-tiny -y && apt install vim -y
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################六

# 检查点六：用户shell配置文件覆盖root用户的
# Y
comfirm "\e[1;33m『6』是否覆盖root用户的$shell_conf文件? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  if [ -f "/root/$shell_conf.bak" ];then
    # B
    echo -e "\e[1;34m$shell_conf.bak文件存在,将新建baknew文件。\e[0m"
    cp /root/$shell_conf /root/$shell_conf.baknew
  else
    # B
    echo -e "\e[1;34m正在备份原$shell_conf文件。\e[0m"
    cp /root/$shell_conf /root/$shell_conf.bak
  fi
  echo -e "\e[1;32m 拷贝用户$shell_conf文件到root用户目录。 \e[0m"
  cp /home/$username/$shell_conf /root/
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################七

# 检查点七：添加/usr/sbin到环境变量
# Y
comfirm "\e[1;33m『7』是否添加/usr/sbin到环境变量? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  if [ -f "/home/$username/$shell_conf.bak" ];then
    # B
    echo -e "\e[1;34m用户的$shell_conf.bak文件存在,将新建baknew文件。\e[0m"
    cp /home/$username/$shell_conf /home/$username/$shell_conf.baknew
  else
    # B
    echo -e "\e[1;34m正在备份原用户$shell_conf文件。\e[0m"
    cp /home/$username/$shell_conf /home/$username/$shell_conf.bak
  fi
  check_var="export PATH=\"\$PATH:/usr/sbin\""
  # G
  echo -e "\e[1;32m 检查是否已经添加…… \e[0m"
  if cat '/home/$username/$shell_conf' | grep "$check_var"
  then
    # B
    echo -e "\e[1;34m环境变量  $check_var  已存在,不执行添加。\e[0m"
  else
    # G
    echo -e "\e[1;32m 添加/usr/sbin到用户变量 \e[0m"
    echo "export PATH=\"\$PATH:/usr/sbin\"" >> /home/$username/$shell_conf
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################八
# 检查点八：从apt仓库拉取以上常用软件
# Y
comfirm "\e[1;33m『8』是否从apt仓库拉取常用软件『强烈不建议跳过此检查点』? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  #答案是“Y”，执行这里。
  prompt -i "正在检查例外软件列表....."
  prompt -i "例外软件有 ${#EX_LST[@]} 个。\n"
  ex_len=${#EX_LST[@]}
  # 分离得到的例外包名列表
  NAME_LST=()
  # 分离得到的例外包指定例外的原因列表
  REASON_LST=()
  num=1
  # 历遍EX_LST数组
  for ((i=0;i<$ex_len;i++));do
    each=${EX_LST[$i]}
    OLD_IFS="$IFS"
    IFS="；"
    SPLIT_LST=($each)
    IFS="$OLD_IFS"
    for item in ${SPLIT_LST[@]}
    do
      NAME_LST[$i]=${SPLIT_LST[0]}
      REASON_LST[$i]=${SPLIT_LST[1]}
    done
    prompt -e "$num - Package Name:${SPLIT_LST[0]}..........${SPLIT_LST[1]}"
    num=$((num+1))
  done
  # echo ${NAME_LST[@]}
  # echo ${REASON_LST[@]}
  prompt -e "\n\n[1/5]警告:例外的软件将会在常规软件安装之后再询问您是否安装『请仔细阅读被指定例外的原因，并记住您的选择，因为此信息只显示一次！』 ,  回车继续......"
  # 停顿一下，回车继续
  read -r res
  
  # 处理APP_LST
  # 把“- ”转为换行符 然后删除所有空格 最后删除第一行。
  # echo $LST | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d'
  LST=$(echo $LST | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
  APP_LST=($LST)
  # 显示的序号从零开始
  num=0
  # 生成的例外软件编号记录
  rec=0
  EX_INDEX=()
  # 显示软件列表
  app_len=${#APP_LST[@]}
  for ((i=0;i<$app_len;i++));do
    each=${APP_LST[$i]}
    index=`expr index "$each" —`
    # 软件包名
    name=${APP_LST[$i]/$each/${each:0:($index-1)}}
    # 检查是否在EX_LST例外数组中
    flag=false
    for var in ${NAME_LST[@]}
    do
      if [ "$var" == "$name" ];then
        flag=true
      fi
    done
    # P
    echo -en "\e[1;35m$num)\e[0m"
    # 如果flag=true，说明该软件包在EX_LST例外列表中，显示为红色。
    if ($flag);then
      prompt -e "$each"
      EX_INDEX[$rec]=$num
      rec=$((rec+1))
    else
      # G
      prompt -i "$each"
    fi
    num=$((num+1))
  done
  
  # Y
  echo -e "\e[1;33m\n[2/5]所列出的软件包个数为: \e[1;31m ${#APP_LST[@]} \e[1;33m,请输入不想安装的软件序号(多个请用空格隔开，如：2 5 7 8)\n\e[0m"
  # B
  echo -en "\e[1;34m您的选择『无则直接回车』：  "
  read -r ex_item
  
  # 生成临时数组
  cos_ext_item=($ex_item)
  # 去除cos_ext_item中相同元素
  len=${#cos_ext_item[@]}
  for((i=0;i<$len;i++)) 
  do
    for((j=$len-1;j>i;j--)) 
    do
      if [[ ${cos_ext_item[i]} = ${cos_ext_item[j]} ]];then 
        unset cos_ext_item[i] 
      fi 
    done 
  done
  cos_ex_item=()
  index=0
  for each in ${cos_ext_item[@]}
  do
    cos_ex_item[$index]=$each
    index=$((index+1))
  done
  
  # 遍历数组，生成新的APP_LST
  len=${#APP_LST[@]}
  for ((i=0;i<$len;i++));do
    # echo ${APP_LST[$i]}
    each=${APP_LST[$i]}
    # 查找子字符串“—”的位置。
    # 如：“zhcon——tty中文虚拟” index=6,所以要截取“zhcon”，即 0:5
    index=`expr index "$each" —`
    # ${APP_LST[$i]}=
    # echo "${string:0:($index-1)}"
    # APP_LST=${APP_LST[$i]/$each/${each:0:($index-1)}}
    # echo "${APP_LST[$i]/$each/${each:0:($index-1)}}"
    # 下面一行将生成新的APP列表
    APP_LST[$i]=${APP_LST[$i]/$each/${each:0:($index-1)}}
  done
  
  # echo ${cos_ex_item[@]}
  # 拒绝安装的软件数量
  echo -en "\e[1;34m您已拒绝安装 \e[1;31m${#cos_ex_item[@]} \e[1;34m个应用。"
  for each in ${cos_ex_item[@]};do
    echo -en " \e[1;31m${APP_LST[$each]}"
  done
  
  # echo ${EX_INDEX[@]}
  # 合并成一个临时列表，将不会在常规软件包中安装。
  apt_ex_temp=(${cos_ex_item[@]} ${EX_INDEX[@]})
  apt_ext_len=${#apt_ex_temp[@]}
  # 去除apt_ex_temp中相同元素
  for ((i=0;i<$apt_ext_len;i++)) 
  do
    for ((j=$apt_ext_len-1;j>i;j--)) 
    do
      if [[ ${apt_ex_temp[i]} = ${apt_ex_temp[j]} ]];then 
        unset apt_ex_temp[i] 
      fi 
    done 
  done
  apt_ex=()
  index=0
  for each in ${apt_ex_temp[@]}
  do
    apt_ex[$index]=$each
    index=$((index+1))
  done
  # echo ${apt_ex[@]}
  
  # 常规软件列表
  apt_install_in=()
  # 例外列表
  apt_install_ex=()
  # 常规、例外软件列表索引
  in_index=0
  ex_index=0
  len=${#APP_LST[@]}
  for ((i=0;i<$len;i++));do
    each=${APP_LST[$i]}
    # 检查$i是否在EX_LST例外数组中
    flag=false
    for var in ${apt_ex[@]}
    do
      if [ "$var" == "$i" ];then
        flag=true
      fi
    done
    # 如果$i在apt_ex列表中，则添加到例外列表
    if ($flag);then
      apt_install_ex[$ex_index]=${APP_LST[$i]}
      ex_index=$((ex_index+1))
    else
      apt_install_in[$in_index]=${APP_LST[$i]}
      in_index=$((in_index+1))
    fi
  done
  # echo "${apt_install_ex[@]}"
  
  # Y
  comfirm "\e[1;33m\n\n\e[1;33m[3/5]是否从apt仓库拉取上述常用软件『已经排除例外软件以及您拒绝安装的软件包』? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    # G
    echo -e "\e[1;32m 正在安装常规软件  \e[0m"
    apt install ${apt_install_in[@]} -y
    if [ $? != 0 ];then
      prompt -i "安装出错，列表中有仓库中没有的软件包。下面将进行逐个安装，按任意键继续。"
      read temp
      for var in ${apt_install_in[@]}
      do
        apt install $var -y
      done
    fi 
    # echo "${apt_install_in[@]}"
  elif [ $choice == 2 ];then
  prompt -i "Pass"
  else
    prompt -e "ERROR:未知返回值!"
    exit 5
  fi
  
  # 列出例外软件
  num=0
  for ex in ${apt_install_ex[@]}
  do
    # P
    echo -en "\e[1;35m$num)\e[0m"
    prompt -i "$ex"
    num=$((num+1))
  done
  # Y
  echo -e "\e[1;33m\n[4/5]所列出的例外软件包个数为: \e[1;31m $num \e[1;33m,请输入想安装的例外软件序号(多个请用空格隔开，如：0 2 5)\n\e[0m"
  # B
  echo -en "\e[1;34m您的选择『不安装例外软件请直接回车』：  "
  read -r inc_item
  # echo $inc_item
  cos_item=($inc_item)
  # echo ${cos_item[@]}
  # 去除cos_item中相同元素,生成cos_inc_item
  len=${#cos_item[@]}
  for ((i=0;i<$len;i++)) 
  do
    for ((j=$len-1;j>i;j--)) 
    do
      if [[ ${cos_item[i]} = ${cos_item[j]} ]];then 
        unset cos_item[i] 
      fi 
    done 
  done
  cos_inc_item=()
  index=0
  for each in ${cos_item[@]}
  do
    cos_inc_item[$index]=$each
    index=$((index+1))
  done
  # echo ${cos_inc_item[@]}
  
  # 例外列表长度
  ex_len=${#apt_install_ex[@]}
  # 这个是选择安装的例外软件
  cos_install_ex=()
  cos_index=0
  for ((i=0;i<$ex_len;i++));do
    each=${apt_install_ex[$i]}
    # 如果i在cos_inc_item中，则添加安装列表
    flag=false
    for var in ${cos_inc_item[@]}
    do
      if [ "$var" == "$i" ];then
        flag=true
      fi
    done
    # 如果$i在$cos_inc_item列表中，则添加到例外列表
    if ($flag);then
      cos_install_ex[$cos_index]=${apt_install_ex[$i]}
      cos_index=$((cos_index+1))
    fi
  done
  
  echo -e "\e[1;34m\n您已选择安装 \e[1;31m${#cos_inc_item[@]} \e[1;34m个应用。分别是：\n"
  num=0
  for each in ${cos_install_ex[@]};do
    prompt -i "$num)  $each"
    num=$((num+1))
  done
  # Y
  comfirm "\e[1;33m[5/5]是否从apt仓库拉取以上您自选的例外软件『指定例外的原因相信您已经获悉！』? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    # G
    echo -e "\e[1;32m 正在安装例外软件  \e[0m"
    apt install ${cos_install_ex[@]} -y
    prompt -i "安装出错，列表中有仓库中没有的软件包。下面将进行逐个安装，按任意键继续。"
    read temp
    if [ $? != 0 ];then
      for var in ${cos_install_ex[@]}
      do
        apt install $var -y
      done
    fi
  elif [ $choice == 2 ];then
    prompt -i "Pass"
  else
    prompt -e "ERROR:未知返回值!"
    exit 5
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################九

# 检查点九：添加Anydesk、teamviewer、sublime、docker-ce、virtualbox、typora仓库
# Y
comfirm "\e[1;33m『9』是否添加Anydesk、teamviewer、sublime、docker-ce、virtualbox、typora仓库? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m 下面将添加Anydesk、teamviewer、sublime、docker-ce、virtualbox仓库 \e[0m"
  wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add -
  echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk-stable.list
  wget -O - https://download.teamviewer.com/download/linux/signature/TeamViewer2017.asc | apt-key add -
  echo "###   TeamViewer DEB repository list
### NOTE: Manual changes to this file
###        - prevent it from being updated by TeamViewer package updates
###        - will be lost after using the 'teamviewer repo' command
###       The original file can be restored with this command:
###       cp /opt/teamviewer/tv_bin/script/teamviewer.list /etc/apt/sources.list.d/teamviewer.list
###       which has the same effect as 'teamviewer repo default'
### NOTE: It is preferred to use the following commands to edit this file:
###       teamviewer repo                - show current repository configuration
###       teamviewer repo default        - restore default configuration
###       teamviewer repo disable        - disable the repository
###       teamviewer repo stable         - make all regular TeamViewer packages available (default)
###       teamviewer repo preview        - additionally, make feature preview packages available
###       teamviewer repo development    - additionally, make the latest development packages available
deb http://linux.teamviewer.com/deb stable main
# deb http://linux.teamviewer.com/deb preview main
# deb http://linux.teamviewer.com/deb development main" > /etc/apt/sources.list.d/teamviewer.list
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  sudo apt-get remove docker docker-engine docker.io -y
  sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  echo "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian buster stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list
  wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
  sudo add-apt-repository 'deb https://typora.io/linux ./'
  if [ $sid == true ]
  then
    echo -e "\e[1;33m检测到您使用的是sid源，是否添加virtualbox仓库（y/N）？\e[0m"
    read -r res
    for i in ${YES[@]}
    do
      if [ "$i" == "$res" ]
      then
        echo "deb http://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/ buster contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
        wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
      fi
    done
  else
    comfirm "\e[1;33m是否添加virtualbox仓库【如果您使用的是sid源，请直接回车跳过此步】? [y/N]\e[0m"
    choice=$?
    if [ $choice == 1 ];then
      echo "deb http://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/ buster contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
      wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    elif [ $choice == 2 ];then
      prompt -i "Pass"
    else
      prompt -e "ERROR:未知返回值!"
      exit 5
    fi
  fi
  # G
  echo -e "\e[1;32m 更新软件索引…… \e[0m"
  apt update
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十

# 检查点十：安装docker-ce和VirtualBox并添加当前用户到docker-ce和vbox
# Y
comfirm "\e[1;33m『10』是否现在安装docker-ce、virtualbox「镜像安装，速度快」? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # Y
  echo -e "\e[1;33m 请选择要安装的virtualbox来源「其他键跳过」：
  
(1) VirtualBox官方源  -   将安装virtualbox-6.1
(2) Debian sid源      -   将安装virtualbox

注意：如果你使用的是sid源，请选择(2)，如果您不是使用sid源且已经在上一步骤添加了VirtualBox官方源的请选择(1)[输入“1”或者“2”]
\e[0m"
  f=true
  while $f
  do
    read -r inp
    case $inp in [1])
      f=false
    ;;
    [2])
      f=false
    ;;
    *)
      prompt -w "Invalid option..."
    ;;
    esac
  done
  # G
  echo -e "\e[1;32m 正在安装VBox和Docker-ce \e[0m"
  apt install docker-ce -y
  if [ $? == 0 ]
  then
    sudo usermod -aG docker $username
  else
    prompt -e "请手动检查Docker-ce是否成功安装！"
  fi
  if [ $inp == 1 ]
  then
    apt install virtualbox-6.1 -y
  elif [ $inp == 2 ]
  then
    apt install virtualbox -y
  fi
  if [ $? == 0 ]
  then
    sudo usermod -aG vboxusers $username
  else
    prompt -e "请手动检查Virtual Box是否成功安装！"
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十一

# 检查点十一：配置networkmanager
# Y
comfirm "\e[1;33m『11』是否启用NetworkManager并修改开机延时等待时间为5秒? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # 检查源文件是否有激活
  check_var="managed=true"
  echo $check_var
  if cat '/etc/NetworkManager/NetworkManager.conf' | grep "$check_var" > /dev/null
  then
    # 有则核对
    # B
    echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
    cat /etc/NetworkManager/NetworkManager.conf
    # B
    echo -e "\e[1;34m===============================================================\e[0m"
    echo -e "检测到NetworkManager \e[1;33m似乎\e[0m 已经启用（如上所列），是否继续修改(y/N)？"
    read -r res
    for i in ${YES[@]}
    do
      if [ "$i" == "$res" ]
      then
        # 继续修改
        if [ -f "/etc/NetworkManager/NetworkManager.conf.bak" ];then
          # B
          echo -e "\e[1;34mbak文件存在,将备份到baknew\e[0m"
          cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.baknew
        else
          echo -e "\e[1;32m 正在备份/etc/NetworkManager/NetworkManager.conf \e[0m"
          cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.bak
          echo -e "\e[1;32m 激活Network Manager \e[0m"
          sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
        fi
      else
        # B
        echo -e "\e[1;34m不做任何修改。\e[0m"
      fi
    done
  else
    # 如果未发现激活,直接修改
    if [ -f "/etc/NetworkManager/NetworkManager.conf.bak" ];then
      # B
      echo -e "\e[1;34mbak文件存在,将备份到baknew\e[0m"
      cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.baknew
    else
      echo -e "\e[1;32m 正在备份/etc/NetworkManager/NetworkManager.conf \e[0m"
      cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.bak
    fi
  fi
  # G
  echo -e "\e[1;32m 激活Network Manager \e[0m"
  sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
  # G
  echo -e "\e[1;32m 重启NetworkManager.service \e[0m"
  systemctl enable NetworkManager.service 
  systemctl restart NetworkManager.service
  # G
  echo -e "\e[1;32m 修改等待时间——/etc/systemd/system/network-online.target.wants/networking.service \e[0m"
  sed -i 's/TimeoutStartSec=5min/TimeoutStartSec=5sec/g' /etc/systemd/system/network-online.target.wants/networking.service
  # B
  echo -e "\e[1;34m请核对修改——如未修改成功请手动修改TimeoutStartSec的参数，命令：\"sudo vim /etc/systemd/system/network-online.target.wants/networking.service\"
===============================================================\e[0m"
  cat /etc/NetworkManager/NetworkManager.conf
  # B
  echo -e "\e[1;34m===============================================================\e[0m"
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十二

# 检查点十二：配置grub网卡默认命名
# Y
comfirm "\e[1;33m『12』是否修改grub默认网卡命名规则? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  if [ -f "/etc/default/grub.bak" ];then
    # B
    echo -e "\e[1;34m备份文件存在，将生成baknew\e[0m"
    cp /etc/default/grub /etc/default/grub.baknew
  else
    # G
    echo -e "\e[1;32m 备份/etc/default/grub \e[0m"
    cp /etc/default/grub /etc/default/grub.bak
  fi
  echo -e "\e[1;32m 更改Debian默认网卡命名规则 \e[0m"
  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
  echo -e "\e[1;32m 更新GRUB \e[0m"
  grub-mkconfig -o /boot/grub/grub.cfg
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十三

# 检查点十三：配置apache2
# Y
comfirm "\e[1;33m『13』是否配置apache2? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m 配置Apache2 共享目录为 /home/HTML \e[0m"
  # B
  echo -e "\e[1;34m新建/home/HTML文件夹\e[0m"
  mkdir /home/HTML
  # B
  echo -e "\e[1;34m设置读写权限为755\e[0m"
  chmod 755 /home/HTML
  if [ -f "/etc/apache2/apache2.conf.bak" ];then
    # B
    echo -e "\e[1;34m备份文件/etc/apache2/apache2.conf.bak存在，将生成baknew\e[0m"
    cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.baknew
  else
    # G
    echo -e "\e[1;32m 备份/etc/apache2/apache2.conf \e[0m"
    cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
  fi
  if [ -f "/etc/apache2/sites-available/000-default.conf.bak" ];then
    # B
    echo -e "\e[1;34m备份文件/etc/apache2/sites-available/000-default.conf.bak存在，将生成baknew\e[0m"
    cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.baknew
  else
    # G
    echo -e "\e[1;32m 备份/etc/apache2/sites-available/000-default.conf \e[0m"
    cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
  fi
  # B
  echo -e "\e[1;34m备份完成，开始修改apache2配置文件。\e[0m"
  sed -i 's/\/var\/www\//\/home\/HTML\//g' /etc/apache2/apache2.conf
  sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/home\/HTML/g' /etc/apache2/sites-available/000-default.conf
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十四

# 检查点十四：配置pypi源为清华镜像并更新系统。
# Y
comfirm "\e[1;33m『14』是否配置pypi「包括pip和pip3」源为清华镜像? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m 安装Python PyPI \e[0m"
  apt-get install software-properties-common python-software-properties -y
  pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
  pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
  pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
  pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
  # Y
  comfirm "\e[1;33m是否现在更新软件索引并更新系统? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    apt update && apt dist-upgrade -y
  elif [ $choice == 2 ];then
    prompt -i "Pass"
  else
    prompt -e "ERROR:未知返回值!"
    exit 5
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十五

# 检查点十五：配置安装hexo
# Y
comfirm "\e[1;33m『15』是否配置安装hexo、cnpm? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  apt install nodejs npm -y
  npm install cnpm -g --registry=https://r.npm.taobao.org
  cnpm install -g hexo-cli
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十六

# 检查点十六：从互联网安装第三方应用（网易云音乐、WPS等）
# Y
comfirm "\e[1;33m『16』是否从互联网安装第三方应用[ 网易云音乐、WPS ]? \e[1;31m「安装速度较快」\e[1;33m [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  wget http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb
  sudo apt install ./netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb
  wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9615/wps-office_11.1.0.9615_amd64.deb
  sudo apt install ./wps-office_11.1.0.9615_amd64.deb 
  sudo chown $username -hR /home/$username
  prompt -i "安装包将保留在HOME目录。"
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十七

# 检查点十七：从第三方apt仓库安装anydesk、teamviewer和sublime
# Y
comfirm "\e[1;33m『17』是否从第三方apt仓库安装anydesk、teamviewer、typora和sublime? \e[1;31m「安装速度较慢」\e[1;33m [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  apt install anydesk sublime-text typora teamviewer -y
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十八

# 检查点十八：从互联网安装第三方应用[ Skype ]
# Y
comfirm "\e[1;33m『18』是否从互联网安装第三方应用[ Skype ]? \e[1;31m「安装速度慢」\e[1;33m [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  wget https://go.skype.com/skypeforlinux-64.deb
  sudo apt install ./skypeforlinux-64.deb
  sudo chown $username /home/$username/*
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################十九

# 检查点十九：用火狐浏览器(Firefox)打开推荐的仓库和第三方软件官网
# Y
comfirm "\e[1;33m『19』是否用火狐浏览器(Firefox)打开推荐的仓库和第三方软件官网? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  firefox https://github.com/ksnip/ksnip
  firefox https://github.com/oblique/create_ap
  firefox https://github.com/lakinduakash/linux-wifi-hotspot
  firefox https://deadbeef.sourceforge.io/download.html
  firefox https://www.wps.cn/product/wpslinux
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################二十

# 检查点二十：禁用teamviewer、anydesk、docker、apache2服务
# Y
comfirm "\e[1;33m『20』是否禁用teamviewer、anydesk、docker、apache2服务? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  sudo systemctl stop docker.service
  sudo systemctl disable docker.service
  sudo systemctl stop anydesk.service
  sudo systemctl disable anydesk.service
  sudo systemctl stop teamviewerd.service 
  sudo systemctl disable teamviewerd.service 
  sudo systemctl stop apache2.service
  sudo systemctl disable apache2.service
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################二十一

# 检查点二十一：自定义自己的服务
# Y
comfirm "\e[1;33m『21』是否自定义自己的服务，启动一个shell脚本? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  mkdir /home/$username/.$username/
  mkdir /home/$username/.$username/scripts/
  echo "#!/bin/bash
echo -e \"\e[1;33m Hello World \e[0m\"
" > /home/$username/.$username/scripts/autorun.sh
  chmod +x /home/$username/.$username/scripts/autorun.sh
  echo "[Unit]
Description=自定义的服务，用于开启启动/home/用户/.用户名/script下的shell脚本。
After=network.target 

[Service]
ExecStart=/home/$username/.$username/scripts/autorun.sh
Type=forking
PrivateTmp=True

[Install]
WantedBy=multi-user.target
" > /lib/systemd/system/customize-autorun.service
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi

###############################################################收尾工作

# Y
comfirm "\e[1;33m『最后一步』是否设置文件所属、用户目录所属? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # R
  echo -e "\e[1;31m !设置文件所属！\e[0m"
  chown $username -hR /home/$username
  # R
  echo -e "\e[1;31m !设置用户目录权限! \e[0m"
  chmod 700 /home/$username
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
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
