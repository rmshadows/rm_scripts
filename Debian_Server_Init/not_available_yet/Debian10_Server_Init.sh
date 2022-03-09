#!/bin/bash

# 红色：警告、重点
# 黄色：询问
# 绿色：执行
# 蓝色、白色：常规信息

# Root用户UID
ROOT_UID=0
# Shell名称
Shell=$SHELL

#### 列表项
# 『8』LST列表中请不要使用中括号
LST="
- apt-listbugs——apt_list_bug
- apt-listchanges——apt_list_change
- apt-transport-https——apt-transport-https
- axel——axel_downloader
- bash-completion——bash_completion
- build-essential——build-essential
- ca-certificates——ca-certificates
- curl——curl
- gnupg——GPG
- htop——colored_top
- httrack——website_clone
- lsb-release——lsb-release
- make——make
- net-tools——ifconfig
- screenfetch——display_system_info
- sed——text_edit
- silversearcher-ag——Ag_searcher
- tcpdump——tcpdump
- tree——ls_dir_as_tree
- traceroute——trace_route
- wget——wget
- zhcon——tty_display_Chinese
- zsh——zsh
- zsh-autosuggestions——zsh_plugin
"

# 『8』这个数组列表是指定额外情况的软件列表及指定原因。
# 格式：软件名；原因
# 注意：冒号是中文的冒号，每一项之间用空格或者回车隔开。而且包名和原因中不能出现中文冒号和空格。
EX_LST=(
apt-listbugs；Blocking_the_installation_process
apt-listchanges；Blocking_the_installation_process
axel；Unnecessary
build-essential；Unnecessary
httrack；Unnecessary
make；Unnecessary
net-tools；Unnecessary
screenfetch；Unnecessary
tcpdump；Unnecessary
traceroute；Unnecessary
zhcon；Unnecessary
zsh-autosuggestions；Unnecessary
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
alias ngr='sudo systemctl restart nginx.service'
alias systemctl='sudo systemctl'
alias apt='sudo apt-get'
alias update='sudo apt update && sudo apt upgrade'
alias githardpull='git fetch --all && git reset --hard origin/master && git pull'
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
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option!"
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
┃        欢迎使用Debian服务部署          ┃
┃使用须知：                              ┃
┃\e[1;31m运行环境：Linux Terminal(终端)          \e[1;32m┃
┃\e[1;31m权限要求：需要管理员权限                \e[1;32m┃
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
echo -e "\e[1;31m Preparing(1s)...\n\e[0m"
sleep 1

# 检查是否有root权限，无则退出，提示用户使用root权限。
prompt -i "\nChecking for root access...\n"
if [ "$UID" -eq "$ROOT_UID" ]; then
  prompt -s "\n——————————  Unit Ready  ——————————\n"
else
  # Error message
  prompt -e "\n [ Error ] -> Please run as root  \n"
  exit 1
fi

# R
comfirm "\e[1;31m Improperly usage of this script may has potential harm to your computer「If you don't know what you're doing, just press ENTER」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  prompt -s "\n"
elif [ $choice == 2 ];then
  prompt -w "Looking forward to the next meeting ——  https:rmshadows.gitee.io"
  exit 1
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################一

# 检查点一：更新apt镜像
# Y
comfirm "\e[1;33m『1』Change apt source to Tsinghua University mirror website [If your server located in China mainland.]? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32mBackup old apt sources.list file. \e[0m"
  # 如果有bak备份文件会直接覆盖生成baknew文件后修改
  if [ -f "/etc/apt/sources.list.bak" ];then
    # R
    echo -e "\e[1;31msources.list.bak existd, backup as baknew suffix. \e[0m"
    cp /etc/apt/sources.list /etc/apt/sources.list.baknew
  else
    # G
    echo -e "\e[1;32mBackup sources.list as sources.list.bak .\e[0m"
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
  fi
  prompt -i "Tsinghua debian mirror："
  # B
  echo -en "\e[1;34m
1）buster
2）bullseye
3）sid
\e[0m"
  # Y
  echo -en "\e[1;33mChoose a mirror to continue (e.g.: 1 )：\e[0m"
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
  echo -e "\e[1;34mDisplay content of sources.list 
=============================================================================\e[0m"
  cat /etc/apt/sources.list
  # B
  echo -e "\e[1;34m=============================================================================\e[0m"
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################二

# 检查点二：安装SSH zsh sudo更新系统、新建用户
# Y
comfirm "\e[1;33m『2』Do apt to upgrade system ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  #  更新系统
  prompt -i "Update system."
  apt update && sudo apt dist-upgrade
elif [ $choice == 2 ];then
  prompt -w "System not update."
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi
prompt -i "sudo openssh-server zsh will be installed."
sleep 3
# 安装sudo
apt install sudo
# 安装SSH
sudo apt install openssh-server
# 安装zsh
# 判断是否安装zsh
if ! [ -x "$(command -v zsh)" ]; then
  echo 'Error: Zsh is not installed.' >&2
  sudo apt update && sudo apt install zsh -y
fi
# 添加用户，如果已经存在，不添加并询问用户是否继续。
# R
echo -e "\e[1;31mCreating user for the system...Enter a new username(in lower case) ：\e[0m"
read -p "Enter desired username : " username
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
  comfirm "\e[1;33mFailed to add a user $username. Username already exists! Ignore and continue with $username ? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    prompt -i "Continue with user $username"
  elif [ $choice == 2 ];then
    prompt -i Exit.
    exit 2
  else
    prompt -e "ERROR:Unknown Option!"
    exit 5
  fi
else
  read -p "Enter password : " password
  echo "Set passwd = $password"
  pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
  useradd -m -s /bin/zsh -G sudo -p $pass $username
  [ $? -eq 0 ] && echo "User has been added to system!" && echo "$username	ALL=(ALL)NOPASSWD:ALL" >> /etc/sudoers || echo "Failed to add a user!"
fi
# 判断当前Shell，如果不是bash或者zsh，退出，不执行此脚本。
prompt -i "Current shell：$Shell"
if [ "$Shell" == "/bin/bash" ]; then
  shell_conf=".bashrc"
  # 询问用户是否将root和当前用户的shell替换为zsh
  comfirm "\e[1;33mChange bash to zsh for ROOT ? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    shell_conf=".zshrc"
    echo "$zshrc_config" > /home/$username/$shell_conf
    sudo usermod -s /bin/zsh root
    # sudo usermod -s /bin/zsh $username
    prompt -w "\nPress CTRL+c to terminate and restart server if you wanna view zsh, or this script will go ahead.\n"
    # exit 0
  elif [ $choice == 2 ];then
    prompt -w "Pass"
  else
    prompt -e "ERROR:Unknown Option."
    exit 5
  fi
elif [ "$Shell" == "/bin/zsh" ];then
  shell_conf=".zshrc"
  comfirm "\e[1;33m zsh detected, set up a new .zshrc【the old will be backup】? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    if [ -f "/home/$username/$shell_conf.bak" ];then
      # B
      echo -e "\e[1;34m $shell_conf.bak existed, backup as baknew\e[0m"
      cp /home/$username/$shell_conf /home/$username/$shell_conf.baknew
    else
      # B
      echo -e "\e[1;34mBack up $shell_conf\e[0m"
      cp /home/$username/$shell_conf /home/$username/$shell_conf.bak
    fi
    echo "$zshrc_config" > /home/$username/$shell_conf
  elif [ $choice == 2 ];then
    prompt -i "Pass"
  else
    prompt -e "ERROR:Unknown Option."
    exit 5
  fi
else
  # Error message
  prompt -e "\n [ Error ] -> Unkonwn shell: $Shell  Pass...Fix error yourself.\n"
fi
prompt -i "——————————  NEXT  ——————————"

###############################################################三

# 检查点三：添加HOME目录文件夹
# Y
comfirm "\e[1;33m『3』Create folders in User Home path(including Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service)? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  mkdir /home/$username/Data
  mkdir /home/$username/Applications
  mkdir /home/$username/Temp
  mkdir /home/$username/Workplace
  mkdir /home/$username/Services
  mkdir /home/$username/Logs
  mkdir /home/$username/Logs/apache2
  mkdir /home/$username/Logs/nginx
  sudo chown $username -hR /home/$username
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################四

# 检查点四：安装vim-full，卸载vim-tiny；
# Y
comfirm "\e[1;33m『4』Replace vim-tiny with vim-full? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m Removing vim-tiny, vim-full will be installed \e[0m"
  apt remove vim-tiny -y && apt install vim -y
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################五

# 检查点五：用户shell配置文件覆盖root用户的
# Y
comfirm "\e[1;33m『5』Override $shell_conf in /root/ directory ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  if [ -f "/root/$shell_conf.bak" ];then
    # B
    echo -e "\e[1;34m$shell_conf.bak existed, backup with baknew suffix \e[0m"
    cp /root/$shell_conf /root/$shell_conf.baknew
  else
    # B
    echo -e "\e[1;34mBackup root's $shell_conf\e[0m"
    cp /root/$shell_conf /root/$shell_conf.bak
  fi
  echo -e "\e[1;32m Copy $shell_conf to root HOME directory. \e[0m"
  cp /home/$username/$shell_conf /root/
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################六

# 检查点六：添加/usr/sbin到环境变量
# Y
comfirm "\e[1;33m『6』Path to /usr/sbin for $username? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  check_var="export PATH=\"\$PATH:/usr/sbin\""
  # G
  echo -e "\e[1;32m Checking path…… \e[0m"
  if cat '/home/$username/$shell_conf' | grep "$check_var"
  then
    # B
    echo -e "\e[1;34m $check_var  detected, path already existd, pass.\e[0m"
  else
    # G
    echo -e "\e[1;32m Add /usr/sbin to $shell_conf. \e[0m"
    echo "export PATH=\"\$PATH:/usr/sbin\"" >> /home/$username/$shell_conf
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################七

# 检查点七：自定义自己的服务
# Y
comfirm "\e[1;33m『7』Create a /lib/systemd/system/customize-autorun.service ? [y/N]\e[0m"
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
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################八
# 检查点八：从apt仓库拉取以上常用软件
# Y
comfirm "\e[1;33m『8』Install packages from apt? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  #答案是“Y”，执行这里。
  prompt -i "Generate list for unnecessary packages....."
  prompt -i "There are ${#EX_LST[@]} unnecessary packages。\n"
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
  prompt -e "\n\n[1/5]WARN: Unnecessary packages installation is behind the installation of necessary packages 『Pay attention on why those packages are marked as unnecessary. These tip only display once,do remember which you would like to install after necessary packages had installed』 ,  press ENTER to continue......"
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
  echo -e "\e[1;33m\n[2/5]Total of packages : \e[1;31m ${#APP_LST[@]} \e[1;33m, pick up those you DO NOT want to install !(split with BLANK SPACE，e.g.：2 5 7 8)\n\e[0m"
  # B
  echo -en "\e[1;34mYour choice『IF YOU WANT TO INSTALL ALL, JUST PRESS ENTER』：  "
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
  echo -en "\e[1;34mThose packages WILL NOT be installed with a total of \e[1;31m${#cos_ex_item[@]} \e[1;34m :"
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
  comfirm "\e[1;33m\n\n\e[1;33m[3/5]Start with the installation of necessary packages『without those you've pick up』? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    # G
    echo -e "\e[1;32m Install packages...  \e[0m"
    apt install ${apt_install_in[@]} -y
    if [ $? != 0 ];then
      prompt -i "It seems some of them are not in your apt sources, press ENTER to continue the installation."
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
    prompt -e "ERROR:Unknown Option."
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
  echo -e "\e[1;33m\n[4/5]Listing unnecessary packages in total : \e[1;31m $num \e[1;33m, pick up those you want to install(split with BLANK SPACE, e.g.：0 2 5)\n\e[0m"
  # B
  echo -en "\e[1;34mYour choice『abort installation with a directly ENTER』：  "
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
  
  echo -e "\e[1;34m\nThose to be install in total :\e[1;31m${#cos_inc_item[@]} \e[1;34m. They're ：\n"
  num=0
  for each in ${cos_install_ex[@]};do
    prompt -i "$num)  $each"
    num=$((num+1))
  done
  # Y
  comfirm "\e[1;33m[5/5]Start installation of unnecessary packages『You've aware of why these packages have been marked as unnecessary』? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    # G
    echo -e "\e[1;32m Install unnecessary packages  \e[0m"
    apt install ${cos_install_ex[@]} -y
    prompt -i "It seems some of them are not in your apt sources, press ENTER to continue the installation."
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
    prompt -e "ERROR:Unknown Option."
    exit 5
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################九

# 检查点九：设置主机名、语言支持
# Y
comfirm "\e[1;33m『9』Setup hostname and locale ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  read -p "Enter desired host name : " hostname
  echo $hostname > /etc/hostname
  echo "127.0.1.1	$hostname" >> /etc/hosts
  sudo dpkg-reconfigure locales
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十

# 检查点十：设置自动登录tty1
# Y
comfirm "\e[1;33m『10』Automatic login on tty1 ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  sed -i "s/#NAutoVTs=6/NAutoVTs=1/g" /etc/systemd/logind.conf
  mkdir /etc/systemd/system/getty@tty1.service.d
  echo "[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin $username --noclear %I \$TERM
" > /etc/systemd/system/getty@tty1.service.d/override.conf
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十一

# 检查点十一：配置grub网卡默认命名
# Y
comfirm "\e[1;33m『11』Modify the default rules for naming network card in GRUB ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  if [ -f "/etc/default/grub.bak" ];then
    # B
    echo -e "\e[1;34mBackup as baknew suffix.\e[0m"
    cp /etc/default/grub /etc/default/grub.baknew
  else
    # G
    echo -e "\e[1;32m Backup /etc/default/grub \e[0m"
    cp /etc/default/grub /etc/default/grub.bak
  fi
  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
  echo -e "\e[1;32m Update GRUB \e[0m"
  grub-mkconfig -o /boot/grub/grub.cfg
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十二

# 检查点十二：安装docker-ce
# Y
comfirm "\e[1;33m『12』Install docker-ce and configure docker-ce ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # Y
  echo -e "\e[1;33m Choose mirrors to install docker「If your server located in China ,choose Tsinghua mirror site」：
  
(1) Tsinghua University
(2) Docker Official

Just input “1” or “2”]
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
  sudo apt-get remove docker docker-engine docker.io containerd runc -y
  if [ $inp == 1 ]
  then
    sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    echo "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian buster stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list
    sudo apt update
    apt install docker-ce -y
  elif [ $inp == 2 ]
  then
    sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install docker-ce
  fi
  if [ $? == 0 ]
  then
    sudo usermod -aG docker $username
  else
    prompt -e "It seems some error has occurred while installation, is docker installed correctly ?"
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十三

# 检查点十三：配置apache2、SSL
# apache2 SSL站点配置/etc/apache2/sites-available/https.conf

# 简单的http站点
apache2_http_site_conf="<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	#ServerName www.example.com

	ServerAdmin webmaster@localhost
	DocumentRoot /home/$username/apache2
	ServerAdmin  !!you@example.com邮箱  # 错误页面将会显示这个邮箱
	ServerSignature Off    # 关闭服务器签名
	ServerTokens Prod    # 隐藏 Apache 和 PHP 版本等属性

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with \"a2disconf\".
	#Include conf-available/serve-cgi-bin.conf
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
"

# 带重写的https站点
apache2_ssl_site_conf="# generated 2021-03-20, Mozilla Guideline v5.6, Apache 2.4.38, OpenSSL 1.1.1d, modern configuration
# https://ssl-config.mozilla.org/#server=apache&version=2.4.38&config=modern&openssl=1.1.1d&guideline=5.6

# this configuration requires mod_ssl, mod_socache_shmcb, mod_rewrite, and mod_headers
<VirtualHost *:80>
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName  !!  #修改为申请证书时绑定的域名www.YourDomainName1.com
    DocumentRoot  /home/$username/apache2
    ServerAdmin  !!you@example.com邮箱  # 错误页面将会显示这个邮箱
    ServerSignature Off    # 关闭服务器签名
    ServerTokens Prod    # 隐藏 Apache 和 PHP 版本等属性
    
    SSLEngine on
    SSLCertificateFile !!cert/domain name1_public.crt   # 将domain name1_public.crt替换成您证书文件名。/path/to/signed_cert_and_intermediate_certs
    SSLCertificateKeyFile !!cert/domain name1.key   # 将domain name1.key替换成您证书的密钥文件名。/path/to/private_key
    SSLCertificateChainFile !!cert/domain name1_chain.crt  # 将domain name1_chain.crt替换成您证书的密钥文件名；证书链开头如果有#字符，请删除。

    # enable HTTP/2, if available
    Protocols h2 http/1.1

    # HTTP Strict Transport Security (mod_headers is required) (63072000 seconds)
    Header always set Strict-Transport-Security \"max-age=63072000\"
</VirtualHost>

# modern configuration
SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1 -TLSv1.2
SSLHonorCipherOrder     off
SSLSessionTickets       off

SSLUseStapling On
SSLStaplingCache \"shmcb:logs/ssl_stapling(32768)\"
"

apache2_reverse_example="<VirtualHost *:80>
 ServerName example.com
 ProxyRequests Off
 # 末尾记得加斜杠
 ProxyPass / http://localhost:3000/
 ProxyPassReverse / http://localhost:3000/
</VirtualHost>
"
# Y
comfirm "\e[1;33m『13』Install apache2 server and configure it (setup a apache2 directory in HOME) ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  sudo systemctl stop nginx.service
  sudo apt install apache2
  # G
  echo -e "\e[1;32m Create a new folder : /home/$username/apache2 \e[0m"
  mkdir /home/$username/apache2
  # B
  echo -e "\e[1;34mSet mode 755\e[0m"
  chmod 755 /home/$username/apache2
  if [ -f "/etc/apache2/apache2.conf.bak" ];then
    # B
    echo -e "\e[1;34m/etc/apache2/apache2.conf.bak existed, backup with a baknew suffix \e[0m"
    cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.baknew
  else
    # G
    echo -e "\e[1;32m Backup /etc/apache2/apache2.conf \e[0m"
    cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
  fi
  if [ -f "/etc/apache2/sites-available/000-default.conf.bak" ];then
    # B
    echo -e "\e[1;34mBackup /etc/apache2/sites-available/000-default.conf as a baknew suffix \e[0m"
    cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.baknew
  else
    # G
    echo -e "\e[1;32m Backup /etc/apache2/sites-available/000-default.conf \e[0m"
    cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
  fi
  # B
  echo -e "\e[1;34mChange work directory apache2...\e[0m"
  sed -i 's|/var/www/|/home/'$username'/apache2|g' /etc/apache2/apache2.conf
  # sed -i 's|DocumentRoot /var/www/html/DocumentRoot|/home/$username/apache2|g' /etc/apache2/sites-available/000-default.conf
  echo "$apache2_http_site_conf" > /etc/apache2/sites-available/http-site.conf
  prompt -i "Disable stie 000-default.conf and enable http-site.conf"
  sudo a2dissite 000-default.conf
  sudo a2ensite http-site.conf
  
  # 配置SSL
  comfirm "\e[1;33mGenerate a https.conf site for Apache2 「Complete the configuration file manually」 ? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    a2enmod ssl
    a2enmod socache_shmcb
    a2enmod rewrite
    a2enmod headers
    if [ -f "/etc/apache2/sites-available/https.conf" ];then
      prompt -e "/etc/apache2/sites-available/https.conf existed! Process terminated!"
    fi
    echo "$apache2_ssl_site_conf" > /etc/apache2/sites-available/https.conf
    a2ensite https.conf
    prompt -w "Then, you need to fill paras prefixed with a “!!” in /etc/apache2/sites-available/https.conf"
  elif [ $choice == 2 ];then
    prompt -i "Pass"
  else
    prompt -e "ERROR:Unknown Option!"
    exit 5
  fi
  
  # 配置Apache2反向代理
  comfirm "\e[1;33mGenerate a /etc/apache2/sites-available/reverse_proxy_example.conf for Apache2 「Complete the configuration file and merge it to your sites manually」? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    a2enmod proxy proxy_http
    if [ -f "/etc/apache2/sites-available/reverse_proxy_example.conf" ];then
      prompt -e "/etc/apache2/sites-available/reverse_proxy_example.conf existed! Process terminated!"
    fi
    echo "$apache2_reverse_example" > /etc/apache2/sites-available/reverse_proxy_example.conf
  elif [ $choice == 2 ];then
    prompt -i "Pass"
  else
    prompt -e "ERROR:Unknown Option!"
    exit 5
  fi
  # 禁止浏览/usr/share
  search_line=`nl -b a /etc/apache2/apache2.conf | sed -n '/share>/p'`
  OLD_IFS="$IFS"
  IFS="	"
  # 第几行
  line=($search_line)
  IFS="$OLD_IFS"
  line=$((line+1))
  d_line=$((line+1))
  # 删除Require all granted改为Require all denied
  # <Directory /usr/share>
  #	AllowOverride None
  #	Require all granted
  # </Directory>
  sed -i "$d_line d" /etc/apache2/apache2.conf && sed -i "$line a\	Require all denied" /etc/apache2/apache2.conf
  
  sudo chmod 775 /home/$username/apache2
  sudo systemctl stop apache2.service
  sudo systemctl disable apache2.service
  prompt -i "Stop and disable apache2.service"
  prompt -i "Check config: If error reported, fix it manually."
  apachectl configtest
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十四

# 检查点十四：配置nginx
# https://www.runoob.com/w3cnote/nginx-install-and-config.html
# 反向代理 负载均衡 https://www.runoob.com/w3cnote/nginx-proxy-balancing.html

nginx_global_config="#### nginx配置
# nginx用户
user www-data;
# 工作核心数量
worker_processes auto;
# 指定nginx进程运行文件存放地址
pid /run/nginx.pid;
# 包含启用的模块
include /etc/nginx/modules-enabled/*.conf;# 

#制定日志路径，级别。这个设置可以放入全局块，http块，server块，级别以此为：debug|info|notice|warn|error|crit|alert|emerg
error_log /home/$username/Logs/nginx/nginx_error.log crit; 
# Specifies the value for maximum file descriptors that can be opened by this process.# nginx worker进程最大打开文件数
worker_rlimit_nofile 4028;

events
{
  # 在linux下，nginx使用epoll的IO多路复用模型
  use epoll; 
  # nginx worker单个进程允许的客户端最大连接数
  worker_connections 1024; 
  # 设置网路连接序列化，防止惊群现象发生，默认为on.惊群现象：一个网路连接到来，多个睡眠的进程被同时叫醒，但只有一个进程能获得链接，这样会影响系统性能。
  accept_mutex on; 
  # 设置一个进程是否同时接受多个网络连接，默认为off。如果web服务器面对的是一个持续的请求流，那么启用multi_accept可能会造成worker进程一次接受的请求大于worker_connections指定可以接受的请求数。这就是overflow，这个overflow会造成性能损失，overflow这部分的请求不会受到处理。
  # multi_accept on; 
}

http
{
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  log_format main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
               '\$status \$body_bytes_sent \"\$http_referer\" '
               '\"\$http_user_agent\" \$http_x_forwarded_for';
  
  # charset gb2312;
  charset utf-8;
  
  # 一秒处理不超过1个请求，防止暴力破解res目录
  limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
  
  server_names_hash_bucket_size 128;
  # server_name_in_redirect off;
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  # 允许客户端请求的最大单文件字节数。如果有上传较大文件，请设置它的限制值
  client_max_body_size 25m; 
  
  types_hash_max_size 2048;
  # 禁用服务器版本显示
  server_tokens off;
  sendfile on;
  # 只有sendfile开启模式下有效
  tcp_nopush on; 
  # 长连接超时时间，单位是秒，这个参数很敏感，涉及浏览器的种类、后端服务器的超时设置、操作系统的设置，可以另外起一片文章了。长连接请求大量小文件的时候，可以减少重建连接的开销，但假如有大文件上传，65s内没上传完成会导致失败。如果设置时间过长，用户又多，长时间保持连接会占用大量资源。
  keepalive_timeout 60; 
  # 设置客户端连接保持会话的超时时间，超过这个时间，服务器会关闭该连接。
  tcp_nodelay on; 
  fastcgi_connect_timeout 300;
  fastcgi_send_timeout 300;
  fastcgi_read_timeout 300;
  fastcgi_buffer_size 64k;
  fastcgi_buffers 4 64k;
  fastcgi_busy_buffers_size 128k;
  fastcgi_temp_file_write_size 128k;
 
  #limit_zone crawler \$binary_remote_addr 10m;
  
  ##
  # SSL Settings
  ##
  # ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
  # ssl_prefer_server_ciphers on;

  ##
  # Logging Settings
  ##
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  ##
  # Gzip Settings
  ##
  gzip on;
  gzip_min_length 1k;
  gzip_buffers 4 16k;
  gzip_http_version 1.0;
  gzip_comp_level 2;
  gzip_types text/plain application/x-javascript text/css application/xml;
  gzip_vary on;
  # Nginx作为反向代理的时候启用，决定开启或者关闭后端服务器返回的结果是否压缩，匹配的前提是后端服务器必须要返回包含\"Via\"的 header头。
  # gzip_proxied any; 

  ##
  # Virtual Host Configs
  ##
  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;

  ##
  # http_proxy 设置
  ##
  #支持客户端的请求方法。post/get；
  # proxy_method get; 
  # client_max_body_size   10m;
  client_body_buffer_size   128k;
  # nginx跟后端服务器连接超时时间(代理连接超时)
  proxy_connect_timeout   75; 
  proxy_send_timeout   75;
  # 连接成功后，与后端服务器两个成功的响应操作之间超时时间(代理接收超时)
  proxy_read_timeout   75;
  # 设置代理服务器（nginx）从后端realserver读取并保存用户头信息的缓冲区大小，默认与proxy_buffers大小相同，其实可以将这个指令值设的小一点
  proxy_buffer_size   4k; 
  # proxy_buffers缓冲区，nginx针对单个连接缓存来自后端realserver的响应，网页平均在32k以下的话，这样设置
  proxy_buffers   4 32k; 
  # 高负荷下缓冲大小（proxy_buffers*2）
  proxy_busy_buffers_size 64k;
  # 当缓存被代理的服务器响应到临时文件时，这个选项限制每次写临时文件的大小。proxy_temp_path（可以在编译的时候）指定写到哪那个目录。
  # proxy_temp_file_write_size  64k; 
  # proxy_temp_path   /usr/local/nginx/proxy_temp 1 2;
  proxy_hide_header X-Powered-By; 
  proxy_hide_header Server;
  
  ##
  # 设定负载均衡后台服务器列表 
  ##
  ## down，表示当前的server暂时不参与负载均衡。
  ## backup，预留的备份机器。当其他所有的非backup机器出现故障或者忙的时候，才会请求backup机器，因此这台机器的压力最轻。
  # upstream mysvr { 
  #  #ip_hash; 
  #  server   192.168.10.100:8080 max_fails=2 fail_timeout=30s ;  
  #  server   192.168.10.101:8080 max_fails=2 fail_timeout=30s ;  
  # }
}

#mail {
#	# See sample authentication script at:
#	# http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
# 
#	# auth_http localhost/auth.php;
#	# pop3_capabilities \"TOP\" \"USER\";
#	# imap_capabilities \"IMAP4rev1\" \"UIDPLUS\";
# 
#	server {
#		listen     localhost:110;
#		protocol   pop3;
#		proxy      on;
#	}
# 
#	server {
#		listen     localhost:143;
#		protocol   imap;
#		proxy      on;
#	}
#}
"

nginx_http="
##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# https://www.nginx.com/resources/wiki/start/
# https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/
# https://wiki.debian.org/Nginx/DirectoryStructure
#
# In most cases, administrators will remove this file from sites-enabled/ and
# leave it as reference inside of sites-available where it will continue to be
# updated by the nginx packaging team.
#
# This file will automatically load configuration files provided by other
# applications, such as Drupal or Wordpress. These applications will be made
# available underneath a path with that package name, such as /drupal8.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##

server
{
  listen 80;#监听端口
  server_name localhost;#域名
  index index.html index.htm index.php;
  root /home/$username/nginx;#站点目录
  
  # error_page 404 https://www.baidu.com; #错误页
  # error_page  500 502 503 504  /50x.html;
  
  # 不是GET POST HEAD就返回空响应
  if (\$request_method !~ ^(GET|HEAD|POST)$) {
    return 444;
  }

  location ~ .*\.(php|php5)?$
  {
    # fastcgi_pass unix:/tmp/php-cgi.sock;
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    include fastcgi.conf;
  }
  location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ico)$
  {
    expires 30d;
    # access_log off;
  }
  location ~ .*\.(js|css)?$
  {
    expires 15d;
    # access_log off;
  }
  
  # 负载均衡
  # location  ~*^.+$ {         
  #    proxy_pass  http://mysvr;  #请求转向mysvr 定义的服务器列表
  # }
  access_log off;
}
"

# 带有重写的nginx ssl配置
nginx_ssl="# generated 2021-03-20, Mozilla Guideline v5.6, nginx 1.14.2, OpenSSL 1.1.1d, modern configuration
# https://ssl-config.mozilla.org/#server=nginx&version=1.14.2&config=modern&openssl=1.1.1d&guideline=5.6

# rewrite module from ali cloud
# server {
#     listen 80;
#     server_name yourdomain.com; #需要将yourdomain.com替换成证书绑定的域名。
#     rewrite ^(.*)$ https://\$host\$1; #将所有HTTP请求通过rewrite指令重定向到HTTPS。
#     location / {
#         index index.html index.htm;
#     }
# }

# rewrite module from firefox ssl config generator
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  
  server_name localhost;#域名
  index index.html index.htm index.php;
  root /home/$username/nginx; #站点目录
  
  # error_page 404 https://www.baidu.com; #错误页
  # error_page  500 502 503 504  /50x.html;
  
  # 不是GET POST HEAD就返回空响应
  if (\$request_method !~ ^(GET|HEAD|POST)$) {
    return 444;
  }

  # home_page文件夹
  location  /home_page {
    # autoindex on;
    # autoindex_exact_size off;
    # autoindex_localtime off;
  }

  # 用户分享的文件(Nopasswd)
  location  /nres {
    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime off;
  }
  
  # 用户分享的文件(Passwd)
  location  /res {
    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime off;
    # 突发请求不超过10个，否则返回错误信息。
    limit_req zone=one burst=10;
    # default user: default passwd: morenyonghu File: ~/Logs/nginx_login
    auth_basic "Passwd required";       #提示信息(自定义)
    auth_basic_user_file /home/jessie/Logs/nginx_login;   #生成的密码文件
  }
  

#  location ~ .*\.(php|php5)?$
#  {
#    #fastcgi_pass unix:/tmp/php-cgi.sock;
#    fastcgi_pass 127.0.0.1:9000;
#    fastcgi_index index.php;
#    include fastcgi.conf;
#  }
#  location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ico)$
#  {
#    expires 30d;
#    # access_log off;
#  }
#  location ~ .*\.(js|css)?$
#  {
#    expires 15d;
#    # access_log off;
#  }
  
  # 负载均衡
  # location  ~*^.+$ {         
  #    proxy_pass  http://mysvr;  #请求转向mysvr 定义的服务器列表
  # }
  
  #location /some/path/ {
  #  proxy_pass http://www.example.com/link/;
  #}
  
  access_log off;

  ssl_certificate /path/to/signed_cert_plus_intermediates;
  ssl_certificate_key /path/to/private_key;
  ssl_session_timeout 180m;
  ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
  ssl_session_tickets off;

  # modern configuration
  ssl_protocols TLSv1.3;
  ssl_prefer_server_ciphers off;
  
  # ali_cloud_config
  # ssl_protocols TLSv1 TLSv1.1 TLSv1.2; #表示使用的TLS协议的类型。
  # ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4; #表示使用的加密套件的类型。
  # ssl_prefer_server_ciphers on;

  # HSTS (ngx_http_headers_module is required) (63072000 seconds)
  add_header Strict-Transport-Security \"max-age=63072000\" always;

  # OCSP stapling
  # ssl_stapling on; # 启用OCSP响应验证，OCSP信息响应适用的证书
  # ssl_stapling_verify on;
  # verify chain of trust of OCSP response using Root CA and Intermediate certs
  # ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;
  # replace with the IP address of your resolver
  # resolver 127.0.0.1;
}
"

comfirm "\e[1;33m『13』Install nginx and configurate ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  sudo systemctl stop apache2.service
  sudo apt install nginx -y
  # G
  echo -e "\e[1;32m Create a new folder : /home/$username/nginx and home_page and nres ,res \e[0m"
  mkdir /home/$username/nginx
  mkdir /home/$username/nginx/home_page
  mkdir /home/$username/nginx/nres
  mkdir /home/$username/nginx/res
  # add user
  htpasswd -bc /home/$username/Logs/nginx_login default morenyonghu
  sudo chown jessie -hR /home/$username/nginx
  # B
  echo -e "\e[1;34mSet mode 755\e[0m"
  chmod 775 /home/$username/nginx
  if [ -f "/etc/nginx/nginx.conf.bak" ];then
    # B
    echo -e "\e[1;34m/etc/nginx/nginx.conf.bak existed, backup with a baknew suffix \e[0m"
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.baknew
  else
    # G
    echo -e "\e[1;32m Backup /etc/nginx/nginx.conf \e[0m"
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
  fi
  if [ -f "/etc/nginx/sites-available/default.conf.bak" ];then
    # B
    echo -e "\e[1;34mBackup /etc/nginx/sites-available/default as a baknew suffix \e[0m"
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.baknew
  else
    # G
    echo -e "\e[1;32m Backup /etc/nginx/sites-available/default \e[0m"
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.conf.bak
  fi
  prompt -i "Set up a new nginx.conf"
  echo "$nginx_global_config" > /etc/nginx/nginx.conf
  prompt -i "Genarate a http website and a https website."
  echo "$nginx_http" > /etc/nginx/sites-available/http
  echo "$nginx_ssl" > /etc/nginx/sites-available/https
  comfirm "\e[1;33mEnable ssl sites ? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    sudo rm /etc/nginx/sites-enabled/default
    sudo ln -s /etc/nginx/sites-available/https /etc/nginx/sites-enabled/https
  elif [ $choice == 2 ];then
    prompt -i "Pass"
  else
    prompt -e "ERROR:Unknown Option!"
    exit 5
  fi
  sudo systemctl stop nginx.service
  sudo systemctl disable nginx.service
  prompt -i "Stop and disable nginx.service"
  prompt -i "Check config: If error reported, fix it manually.Else: home_page to place static sites and nres for file sharing."
  sudo nginx -t
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option!"
  exit 5
fi


###############################################################十五

# 检查点十五：配置Python支持和pypi源为清华镜像
# Y
comfirm "\e[1;33m『15』Config python3 enviroment ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  # G
  echo -e "\e[1;32m Install python 3 \e[0m"
  apt update && apt install python3 python3-pip
  apt-get install software-properties-common python-software-properties -y
  
  # Y
  comfirm "\e[1;33m Config pip mirror to Tsinghua University (If your server located in China) ? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
  elif [ $choice == 2 ];then
    prompt -i "Pass"
  else
    prompt -e "ERROR:Unknown Option."
    exit 5
  fi
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十六

# 检查点十六：配置nodejs npm 自选是否安装hexo
# Y
comfirm "\e[1;33m『15』Install Nodejs and npm from apt ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  apt install nodejs npm -y
  comfirm "\e[1;33m Install cnpm (If your server located in China) ? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    npm install cnpm -g --registry=https://r.npm.taobao.org
  elif [ $choice == 2 ];then
    prompt -i "——————————  NEXT  ——————————"
  else
    prompt -e "ERROR:Unknown Option."
    exit 5
  fi
  cnpm install -g hexo-cli
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十七

# 检查点十七：配置SSH

ssh_keep_alive="ClientAliveInterval 60
ClientAliveCountMax 3
"
# Y
comfirm "\e[1;33m『17』Install openssh-server ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  apt install openssh-server -y
  prompt -i "SSH keep alive interval set 60s."
  echo "$ssh_keep_alive" >> /etc/ssh/sshd_config
  prompt -i "Finally ,use (ssh-copy-id -i .ssh/id_rsa.pub User@IP) to add your local ssh_pub_key to remote server."
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

###############################################################十八

# 检查点十八：安装ufw
# Y
comfirm "\e[1;33m『18』Install ufw [WARN(IMPORTANT): If your ssh port is not 22, you may LOSS CONTROL of the server ! ] ? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  sudo apt install ufw -y
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 22
  sudo ufw enable
elif [ $choice == 2 ];then
  prompt -i "——————————  NEXT  ——————————"
else
  prompt -e "ERROR:Unknown Option."
  exit 5
fi

prompt -i "The last one: Setting directory own."
sudo chown -hR $username /home/$username
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
