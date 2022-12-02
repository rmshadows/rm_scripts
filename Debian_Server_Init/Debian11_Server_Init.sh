#!/bin/bash
# https://github.com/rmshadows/rm_scripts

:<<!About-说明
Version：0.0.8
============================================
0 for No.
1 for Yes.
============================================
预设参数（在这里修改预设参数, 谢谢）
注意：如果没有注释，默认0 为否 1 为是。
if [ "$" -eq 1 ];then
    [Your Code]
fi
!About-说明

## Check-1-检查点一：
# Set APT source 0:skip(跳过) 1:Tsinghua Mirror for Chinese(清华大学镜像源) 2.Your Souce (你自定义的源)     Preset:0
SET_APT_SOURCE=0
# Your apt source Preset=""
SET_YOUR_APT_SOURCE=""
# Install without asking(更新与安装是否不过问) Preset:1
SET_APT_RUN_WITHOUT_ASKING=1
# Disable unattended-upgrades.service ? (禁用unattended-upgrades.service?) 0:skip(跳过) 1:enable(启用) 2:disable(禁用)  Preset=0
SET_ENABLE_UNATTENDED_UPGRADE=0
# Update system with apt(是否在安装软件前更新整个系统) 0:just apt update 1:apt dist-upgrade 2:apt upgrade   Preset:1
SET_APT_UPGRADE=1

## Check-2-检查点二：
# Set to 1 will specify a user.User will be created if not exist.If set to 0, continue with root(是否指定某用户进行配置，否的话将以root用户继续)  Preset:1
SET_USER=1
# Change bash to zsh 是否替换Bash为Zsh（包括root用户） Preset:1
SET_BASH_TO_ZSH=1
# Change zshrc file for all user 是否配置ZSHRC Preset:1
SET_ZSHRC=1
# User Name in lower case(要新建的用户名-必须小写英文！) Preset="admin"
SET_USER_NAME="admin"
# User password(要新建的用户密码) Preset="passwd"
SET_USER_PASSWD="passwd"
# User should be a sudoer?(是否加入sudo用户组) Preset:1
SET_USER_SUDOER=1
# User should run `sudo` without passwd(是否设置sudo无需密码) Preset:1
SET_SUDOER_NOPASSWD=1

## Check-3-检查点三：
# Uninstall vim-tiny and install vim-full(是否卸载vim-tiny，安装vim-full) Preset:1
SET_VIM_TINY_TO_FULL=1
# Add sbin to env (添加/usr/sbin到用户环境变量) Preset=1
SET_ADD_SBIN_ENV=1
# Install bash-completion (是否安装bash-completion) Preset=1
SET_BASH_COMPLETION=1
# Install zsh-autosuggestions (是否安装zsh-autosuggestions) Preset=1
SET_ZSH_AUTOSUGGESTIONS=1

## Check-4-检查点四：
# Create a /lib/systemd/system/customize-autorun.service(自定义自己的服务（运行一个shell脚本）) Preset:1
SET_SYSTEMCTL_SERVICE=1
# Set hostname(设置HostName) Preset=0
SET_HOST_NAME=0
# Set locales(If you do not need this, just set 0) (设置语言支持，不需要请设置为0) Preset="en_US.UTF-8 UTF-8"
SET_LOCALES="# Setup locales
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
"
# Set time zone (zoneinfo file path)(设置时间支持) Preset=0
# e.g.:Shanghai China,You need to set this: /usr/share/zoneinfo/Asia/Shanghai 
SET_TIME_ZONE=0

# Set tty1 auto-login (设置TTY1自动登录) Preset=1
SET_TTY_AUTOLOGIN=1

## Check-5-检查点五：
# 从apt仓库拉取常用软件
# Install packages from apt repo (是否从APT源安装常用软件) Preset=1
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
# Which package list should be installed.
SET_APT_INSTALL_LIST_INDEX=1
# Install python3(安装Python3) Preset=1
SET_PYTHON3_INSTALL=1
# [Chinese only!]Config Pip mirror to tsinghua,for other mirror, replace 0 or 1 with mirror addr(string) (配置Python3源为清华大学镜像,自定义源请用字符串) Preset=0
SET_PYTHON3_MIRROR=0
# Install git (安装配置git) Preset=1
SET_INSTALL_GIT=1
# Git User & E-mail(Git用户名、邮箱地址 默认$CURRENT_USER & $CURRENT_USER@$HOST) Preset=0
SET_GIT_USER=0
SET_GIT_EMAIL=0
# Install openssh-server(安装配置ssh) Preset=1
SET_INSTALL_OPENSSH=1
# Enable ssh server(SSH开机是否自启 默认启用) Preset=1 
SET_ENABLE_SSH=1
# Install npm(安装配置npm) Preset=0
SET_INSTALL_NPM=0
# Install nodejs(是否安装Nodejs) Preset=0
SET_INSTALL_NODEJS=0
# Install cnpm (For Chinese) (是否安装CNPM) Preset=0
SET_INSTALL_CNPM=0

# Config SSH Key(配置SSH Key) Preset=1
SET_CONFIG_SSH_KEY=1
# Generate New SSH Key(是否生成新的SSH Key 0:新的密钥 1:从文件夹导入现有密钥 2:从文本导入现有密钥) Preset=0
SET_SSH_KEY_SOURCE=0
# New ssh key file name(新生成的、或者导入文本生成的SSH密钥名称) Preset=id_rsa
SET_SSH_KEY_NAME=id_rsa
# ssh key passwd(新生成的SSH密钥密码) Preset=""
SET_NEW_SSH_KEY_PASSWD=""
# 新密钥的备注 "A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian 11_Server_Deploy_Script")
SET_SSH_KEY_COMMENT=0
# 存放已存在的SSH密钥文件夹名称 1:从文件夹导入
SET_EXISTED_SSH_KEY_SRC=SSH_KEY
# SSH 密钥文本 2:从文本导入
# 私钥
SET_SSH_KEY_PRIVATE_TEXT=""
# 公钥
SET_SSH_KEY_PUBLIC_TEXT=""

## Check-6-检查点六：
# Install http server(安装HTTP服务) [0:No 1:nginx 2:apache2] Preset=1
SET_INSTALL_HTTP_SERVER=1
# Enable http server (允许开机自启) Preset=1
SET_ENABLE_HTTP_SERVICE=1
# Disable default site and enable https site (禁用默认网页，启用https网页。) Preset=1
SET_ENABLE_HTTPS_SITE=1
# Set server domain (设置域名) Preset=localhost
SET_SERVER_NAME=localhost
# If NGINX: set ~/nginx/res passwd (如果是nginx，配置~/nginx/res的访问用户、密码) Preset:default nginxLogin 
SET_NGINX_RES_USER=default
SET_NGINX_RES_PASSWD=nginxLogin
# If APACHE Deny access /usr/share (配置禁止访问/usr/share目录) Preset=0
SET_APACHE_DENY_USR_SHARE=0

## Check-7-检查点七：
# Install docker-ce (安装docker-ce)(0:No 1:Offcial 2:tsinghua mirror) Preset=1
SET_INSTALL_DOCKER_CE=1

## Check-8-检查点八：
# Install ufw [WARN(IMPORTANT): If your ssh port is not 22, you may LOSS CONTROL of the server ! ](安装ufw 默认开放22，80，443) Preset=1
SET_INSTALL_UFW=1
# UFW allow port (UFW允许的端口) Preset=22 80 443
SET_UFW_ALLOW="22 80 443"

#### 这里为后面配置文件赋值
# Get Current User获取当前用户名(root,后面如果有指定用户，则是指定用户)
CURRENT_USER_SET=$USER
# 用户目录
HOME_INDEX="$HOME"
# 主机名
if [ "$SET_HOST_NAME" == 0 ];then
    # 如果没有配置主机名
    if [ "$HOSTNAME" == "" ];then
        HOSTNAME=$HOST
    fi
else
    HOSTNAME=$SET_HOST_NAME
fi

# 设置用户目录
if [ "$SET_USER" -eq 1 ];then
    CURRENT_USER_SET=$SET_USER_NAME
    HOME_INDEX="/home/$SET_USER_NAME"
else
    CURRENT_USER_SET=root
    HOME_INDEX="/root"
fi

:<<注释
下面是需要填写的列表，要安装的软件。注意，格式是短杠空格接软件包名接破折号接软件包描述“- 【软件包名】——【软件包描述】”
注意：列表中请不要使用中括号
注释

# Customize 自定义列表
SET_APT_TO_INSTALL_INDEX_0="

"

# 这里是 脚本运行后 要安装的软件。格式同上，注意是稍后安装的，所以会放在脚本执行结束后才安装。
SET_APT_TO_INSTALL_LATER="
- apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
- apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
"

# 轻便安装 (仅我个人认为必要的常用软件)
APT_TO_INSTALL_INDEX_1="
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


### 配置文件
# Zshrc文件
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
# alias ffmpegss='ffmpegCutVideo(){ffmpeg -ss \$2 -to \$3 -i \$1 -vcodec copy -acodec copy \$4};ffmpegCutVideo'
# HTTP服务器
# alias apastart='sudo systemctl start apache2.service'
# alias apastop='sudo systemctl stop apache2.service'
# alias ngxstart='sudo systemctl stop nginx.service'
# alias ngxstop='sudo systemctl stop nginx.service'
# alias ngxr='sudo systemctl restart nginx.service'
# alias ngxhttps='sudo nano /etc/apache2/sites-available/https && sudo nginx -t'
# 其他
alias duls='du -sh ./*'
alias dulsd='du -sh \`la\`'
alias zshrc='vim '\$HOME'/.zshrc'
alias szsh='source '\$HOME'/.zshrc'
alias systemctl='sudo systemctl'
alias apt='sudo apt-get'
alias upgrade='sudo apt update && sudo apt upgrade'
alias ssa='sudo systemctl start'
alias sss='sudo systemctl status'
alias ssd='sudo systemctl stop'
alias ssf='sudo systemctl restart'

# unset _JAVA_OPTIONS

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi
"

#### Nginx
NGINX_GLOBAL_CONF="#### nginx配置
# nginx用户
user www-data;
# 工作核心数量
worker_processes auto;
# 指定nginx进程运行文件存放地址
pid /run/nginx.pid;
# 包含启用的模块
include /etc/nginx/modules-enabled/*.conf;# 

#制定日志路径，级别。这个设置可以放入全局块，http块，server块，级别以此为：debug|info|notice|warn|error|crit|alert|emerg
error_log $HOME_INDEX/Logs/nginx/error.log crit; 
error_log $HOME_INDEX/Logs/nginx/info.log info;
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
  include block_ip.conf;
  access_log $HOME_INDEX/Logs/nginx/access.log;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  # log_format main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
  #            '\$status \$body_bytes_sent \"\$http_referer\" '
  #            '\"\$http_user_agent\" \$http_x_forwarded_for';
  
  # charset gb2312;
  charset utf-8;

  limit_req_zone \$binary_remote_addr zone=one:10m rate=1r/s;
  
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
  # proxy_method post;
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

NGINX_BLOCK_IP="deny 45.155.205.211;
deny 34.251.241.226;
deny 13.233.73.212;
deny 54.176.188.51;
deny 13.233.73.21;
deny 13.232.96.1;
deny 51.38.40.95;
deny 46.101.207.180;
deny 3.143.11.66;
deny 211.40.129.246;
deny 157.230.114.6;
"

NGINX_HTTP_SITE="##
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
  server_name $SET_SERVER_NAME;#域名
  index index.html index.htm index.php;
  root $HOME_INDEX/nginx;#站点目录
  
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
}"

NGINX_HTTPS_SITE="# generated 2021-03-20, Mozilla Guideline v5.6, nginx 1.14.2, OpenSSL 1.1.1d, modern configuration
# https://ssl-config.mozilla.org/#server=nginx&version=1.14.2&config=modern&openssl=1.1.1d&guideline=5.6

# rewrite module from firefox ssl config generator
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  #域名
  server_name $SET_SERVER_NAME;
  index index.html index.htm index.php;
  #站点目录
  root $HOME_INDEX/nginx/; 
  #错误页
  error_page 301 302 403 404 502 https://$SET_SERVER_NAME/404.html; #错误页
  
  # 不是GET POST HEAD就返回空响应
  if (\$request_method !~ ^(GET|HEAD|POST|DELETE)$) {
    return 444;
  }
  
  # 主页
  location / {
    access_log $HOME_INDEX/Logs/nginx/home.log;
    error_log $HOME_INDEX/Logs/nginx/home_error.log;
    proxy_pass http://127.0.0.1:8000/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    expires 1d;
  }
  
#   # preset
#   location /preset/ {
#     access_log $HOME_INDEX/Logs/nginx/preset.log;
#     error_log $HOME_INDEX/Logs/nginx/preset_error.log;
#     proxy_pass http://127.0.0.1:8001/;
#     proxy_set_header Host \$host;
#     proxy_set_header X-Real-IP \$remote_addr;
#     expires 1d;
#   }
  
#   # preset资源文件  
#   location /share/ {
#     root $HOME_INDEX/nginx/preset;
#     # rewrite ^/www/(.*)$ /preset/share/\$1;
#     # autoindex on;
#   }

#   # Hack chat 8002 8003
#   location /hc/ {
#     access_log $HOME_INDEX/Logs/nginx/hackchat.log;
#     error_log $HOME_INDEX/Logs/nginx/hackchat_error.log;
#     proxy_set_header Host \$host;
#     proxy_set_header X-Real-IP \$remote_addr;
#     #rewrite /\$1 ^/hackchat(.*);
#     proxy_pass http://127.0.0.1:8002/;
#     #proxy_redirect http://\$proxy_host/ \$scheme://\$host:\$server_port/hackchat/;
#     #sub_filter 'href=\"/' 'href=\"/hackchat';
#   }
#   location /hc-wss {
#     proxy_pass http://127.0.0.1:8003;
#     proxy_http_version 1.1;    
#     proxy_set_header Upgrade \$http_upgrade;
#     proxy_set_header Connection \"Upgrade\";
#   }

#   # isso 评论系统 8004
#   location /isso {
#     access_log $HOME_INDEX/Logs/nginx/isso.log;
#     error_log $HOME_INDEX/Logs/nginx/isso_error.log;
#     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#     proxy_set_header X-Script-Name /isso;
#     proxy_set_header Host \$host;
#     proxy_set_header X-Real-IP \$remote_addr;
#     proxy_set_header X-Forwarded-Proto \$scheme;
#     proxy_pass http://127.0.0.1:8004;
#   }

  # file pizza 8005
#  location /filepizza/ {
#    proxy_pass http://127.0.0.1:8005/;
#  }

  # 用户分享的文件
  location  /nres {
    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime off;
  }
  # 加密的目录
  location /res {
    autoindex on;
    # 突发请求不超过10个
    limit_req zone=one burst=10; 
    auth_basic \"Passwd required\";       #提示信息(自定义)
    auth_basic_user_file $HOME_INDEX/nginx_res_login;   #生成的密码文件
  }

  # 负载均衡
  # location  ~*^.+$ {         
  #    proxy_pass  http://mysvr;  #请求转向mysvr 定义的服务器列表
  # }
  
  # access_log off;

  ssl_certificate /etc/ssl/$SET_SERVER_NAME.pem;
  ssl_certificate_key /etc/ssl/$SET_SERVER_NAME.key;
  ssl_session_timeout 180m;
  ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
  ssl_session_tickets off;

  # modern configuration
  #ssl_protocols TLSv1.3;
  #ssl_prefer_server_ciphers off;
  
  # ali_cloud_config
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2; #表示使用的TLS协议的类型。
  ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4; #表示使用的加密套件的类型。
  ssl_prefer_server_ciphers on;

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

# 主页
server {
  listen 8000;#监听端口
  server_name $SET_SERVER_NAME;#域名
  index index.html index.htm index.php;
  root $HOME_INDEX/nginx/home_page;#站点目录
  error_page 301 302 403 404 502 https://$SET_SERVER_NAME/404.html; #错误页
  
  # 不是GET POST HEAD就返回空响应
  if (\$request_method !~ ^(GET|HEAD|POST)$) {
    return 444;
  }

  location ~* ^/sample.html {
    return 301 /404.html;
  }

  location ~* \.(ini|php|cfg|sh|py|conf)$ {
    return 301 /404.html;
    deny all;
  }
  
  # 根目录下的部分文件夹全为404
  location ~* ^/(.git) {
    return 301 /404.html;
  }
}


# preset
# server {
#   listen 8001;#监听端口
#   server_name $SET_SERVER_NAME;#域名
#   index index.html index.htm index.php;
#   root $HOME_INDEX/nginx/preset;#站点目录
#   error_page 301 302 502 403 404 https://$SET_SERVER_NAME/404.html; #错误页
  
#   # 不是GET POST HEAD就返回空响应
#   if (\$request_method !~ ^(GET|HEAD|POST)$) {
#     return 444;
#   }
  
#   location ~ ^/(.git) {
#     return 301 /404.html;
#   }
# }
"

#### Apache2
APACHE2_GLOBAL_CONF="# This is the main Apache server configuration file.  It contains the
# configuration directives that give the server its instructions.
# See http://httpd.apache.org/docs/2.4/ for detailed information about
# the directives and /usr/share/doc/apache2/README.Debian about Debian specific
# hints.
#
#
# Summary of how the Apache 2 configuration works in Debian:
# The Apache 2 web server configuration in Debian is quite different to
# upstream's suggested way to configure the web server. This is because Debian's
# default Apache2 installation attempts to make adding and removing modules,
# virtual hosts, and extra configuration directives as flexible as possible, in
# order to make automating the changes and administering the server as easy as
# possible.

# It is split into several files forming the configuration hierarchy outlined
# below, all located in the /etc/apache2/ directory:
#
#	/etc/apache2/
#	|-- apache2.conf
#	|	\`--  ports.conf
#	|-- mods-enabled
#	|	|-- *.load
#	|	\`-- *.conf
#	|-- conf-enabled
#	|	\`-- *.conf
# 	\`-- sites-enabled
#	 	\`-- *.conf
#
#
# * apache2.conf is the main configuration file (this file). It puts the pieces
#   together by including all remaining configuration files when starting up the
#   web server.
#
# * ports.conf is always included from the main configuration file. It is
#   supposed to determine listening ports for incoming connections which can be
#   customized anytime.
#
# * Configuration files in the mods-enabled/, conf-enabled/ and sites-enabled/
#   directories contain particular configuration snippets which manage modules,
#   global configuration fragments, or virtual host configurations,
#   respectively.
#
#   They are activated by symlinking available configuration files from their
#   respective *-available/ counterparts. These should be managed by using our
#   helpers a2enmod/a2dismod, a2ensite/a2dissite and a2enconf/a2disconf. See
#   their respective man pages for detailed information.
#
# * The binary is called apache2. Due to the use of environment variables, in
#   the default configuration, apache2 needs to be started/stopped with
#   /etc/init.d/apache2 or apache2ctl. Calling /usr/bin/apache2 directly will not
#   work with the default configuration.


# Global configuration
#

#
# ServerRoot: The top of the directory tree under which the server's
# configuration, error, and log files are kept.
#
# NOTE!  If you intend to place this on an NFS (or otherwise network)
# mounted filesystem then please read the Mutex documentation (available
# at <URL:http://httpd.apache.org/docs/2.4/mod/core.html#mutex>);
# you will save yourself a lot of trouble.
#
# Do NOT add a slash at the end of the directory path.
#
#ServerRoot \"/etc/apache2\"

#
# The accept serialization lock file MUST BE STORED ON A LOCAL DISK.
#
#Mutex file:\${APACHE_LOCK_DIR} default

#
# The directory where shm and other runtime files will be stored.
#

DefaultRuntimeDir \${APACHE_RUN_DIR}

#
# PidFile: The file in which the server should record its process
# identification number when it starts.
# This needs to be set in /etc/apache2/envvars
#
PidFile \${APACHE_PID_FILE}

#
# Timeout: The number of seconds before receives and sends time out.
#
Timeout 300

#
# KeepAlive: Whether or not to allow persistent connections (more than
# one request per connection). Set to \"Off\" to deactivate.
#
KeepAlive On

#
# MaxKeepAliveRequests: The maximum number of requests to allow
# during a persistent connection. Set to 0 to allow an unlimited amount.
# We recommend you leave this number high, for maximum performance.
#
MaxKeepAliveRequests 100

#
# KeepAliveTimeout: Number of seconds to wait for the next request from the
# same client on the same connection.
#
KeepAliveTimeout 5


# These need to be set in /etc/apache2/envvars
User \${APACHE_RUN_USER}
Group \${APACHE_RUN_GROUP}

#
# HostnameLookups: Log the names of clients or just their IP addresses
# e.g., www.apache.org (on) or 204.62.129.132 (off).
# The default is off because it'd be overall better for the net if people
# had to knowingly turn this feature on, since enabling it means that
# each client request will result in AT LEAST one lookup request to the
# nameserver.
#
HostnameLookups Off

# ErrorLog: The location of the error log file.
# If you do not specify an ErrorLog directive within a <VirtualHost>
# container, error messages relating to that virtual host will be
# logged here.  If you *do* define an error logfile for a <VirtualHost>
# container, that host's errors will be logged there and not here.
#
ErrorLog \${APACHE_LOG_DIR}/error.log

#
# LogLevel: Control the severity of messages logged to the error_log.
# Available values: trace8, ..., trace1, debug, info, notice, warn,
# error, crit, alert, emerg.
# It is also possible to configure the log level for particular modules, e.g.
# \"LogLevel info ssl:warn\"
#
LogLevel warn

# Include module configuration:
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf

# Include list of ports to listen on
Include ports.conf


# Sets the default security model of the Apache2 HTTPD server. It does
# not allow access to the root filesystem outside of /usr/share and /var/www.
# The former is used by web applications packaged in Debian,
# the latter may be used for local directories served by the web server. If
# your system is serving content from a sub-directory in /srv you must allow
# access here, or in any related virtual host.
<Directory />
	Options FollowSymLinks
	AllowOverride None
	Require all denied
</Directory>

<Directory /usr/share>
	AllowOverride None
	Require all granted
</Directory>

<Directory $HOME_INDEX/apache2>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>

#<Directory /srv/>
#	Options Indexes FollowSymLinks
#	AllowOverride None
#	Require all granted
#</Directory>

# AccessFileName: The name of the file to look for in each directory
# for additional configuration directives.  See also the AllowOverride
# directive.
#
AccessFileName .htaccess

#
# The following lines prevent .htaccess and .htpasswd files from being
# viewed by Web clients.
#
<FilesMatch \"^\.ht\">
	Require all denied
</FilesMatch>

#
# The following directives define some format nicknames for use with
# a CustomLog directive.
#
# These deviate from the Common Log Format definitions in that they use %O
# (the actual bytes sent including headers) instead of %b (the size of the
# requested file), because the latter makes it impossible to detect partial
# requests.
#
# Note that the use of %{X-Forwarded-For}i instead of %h is not recommended.
# Use mod_remoteip instead.
#
LogFormat \"%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"\" vhost_combined
LogFormat \"%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"\" combined
LogFormat \"%h %l %u %t \"%r\" %>s %O\" common
LogFormat \"%{Referer}i -> %U\" referer
LogFormat \"%{User-agent}i\" agent

# Include of directories ignores editors' and dpkg's backup files,
# see README.Debian for details.

# Include generic snippets of statements
IncludeOptional conf-enabled/*.conf

# Include the virtual host configurations:
IncludeOptional sites-enabled/*.conf

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
ServerName $SET_SERVER_NAME"

APACHE2_HTTP_SITE="<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	#ServerName www.example.com

	ServerAdmin webmaster@$SET_SERVER_NAME
	DocumentRoot $HOME_INDEX/apache2
	ServerAdmin  $SET_SERVER_NAME@example.com邮箱  # 错误页面将会显示这个邮箱
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

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet"

APACHE2_HTTPS_SITE="# generated 2021-03-20, Mozilla Guideline v5.6, Apache 2.4.38, OpenSSL 1.1.1d, modern configuration
# https://ssl-config.mozilla.org/#server=apache&version=2.4.38&config=modern&openssl=1.1.1d&guideline=5.6

# this configuration requires mod_ssl, mod_socache_shmcb, mod_rewrite, and mod_headers
<VirtualHost *:80>
    ServerName $SET_SERVER_NAME
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName $SET_SERVER_NAME  #修改为申请证书时绑定的域名www.YourDomainName1.com
    DocumentRoot  $HOME_INDEX/apache2
    ServerAdmin  ServerName $SET_SERVER_NAME@example.com邮箱  # 错误页面将会显示这个邮箱
    ServerSignature Off    # 关闭服务器签名
    ServerTokens Prod    # 隐藏 Apache 和 PHP 版本等属性
    
    SSLEngine on
    
    # SSLCertificateFile /etc/ssl/$SET_SERVER_NAME.crt   # 将domain name1_public.crt替换成您证书文件名。/path/to/signed_cert_and_intermediate_certs
    # SSLCertificateKeyFile /etc/ssl/$SET_SERVER_NAME.key   # 将domain name1.key替换成您证书的密钥文件名。/path/to/private_key
    # SSLCertificateChainFile /etc/ssl/$SET_SERVER_NAME.crt  # 将domain name1_chain.crt替换成您证书的密钥文件名；证书链开头如果有#字符，请删除。

    SSLCertificateFile /etc/ssl/$SET_SERVER_NAME.pem
    SSLCertificateKeyFile /etc/ssl/$SET_SERVER_NAME.key

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


# <!--Preset-->
# <!--VirtualHost *:8888>
#     # CustomLog with explicit format string
#     CustomLog \"$HOME_INDEX/Logs/apache2/preset_access_log\" \"%h %l %u %t \"%r\" %>s %b\"
#     ServerName $SET_SERVER_NAME
#     DocumentRoot \"$HOME_INDEX/apache2\"
#     SSLEngine on
#     SSLProxyEngine on
#     SSLCertificateFile /etc/ssl/$SET_SERVER_NAME.pem
#     SSLCertificateKeyFile /etc/ssl/$SET_SERVER_NAME.key
# </VirtualHost-->

# # FRP
# <!--VirtualHost *:8889>
#     CustomLog \"$HOME_INDEX/Logs/apache2/frp_access_log\" common
#     ServerName $SET_SERVER_NAME
#     # DocumentRoot \"$HOME_INDEX/apache2\"
#     ProxyPass / http://127.0.0.1:7500/
#     ProxyPassReverse / http://127.0.0.1:7500/
#     # RewriteRule ^/preset(.*) http://127.0.0.1:8889/\$1
#     SSLEngine on
#     SSLProxyEngine on
#     SSLCertificateFile /etc/ssl/$SET_SERVER_NAME.pem
#     SSLCertificateKeyFile /etc/ssl/$SET_SERVER_NAME.key
# </VirtualHost-->

# <!--VirtualHost *:8890>
#     CustomLog \"$HOME_INDEX/Logs/apache2/8890_access_log\" common
#     ServerName $SET_SERVER_NAME
#     ProxyPass / http://127.0.0.1:1000/
#     ProxyPassReverse / http://127.0.0.1:1000/
#     # RewriteRule ^/preset(.*) http://127.0.0.1:8888/\$1
#     SSLEngine on
#     SSLProxyEngine on
#     SSLCertificateFile /etc/ssl/$SET_SERVER_NAME.pem
#     SSLCertificateKeyFile /etc/ssl/$SET_SERVER_NAME.key
# </VirtualHost-->
"

APACHE2_PROXYTEST_SITE="<VirtualHost *:80>
    ServerName $SET_SERVER_NAME
    ProxyRequests Off
    # 末尾记得加斜杠
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
</VirtualHost>
"


### 脚本变量
# Root用户UID
ROOT_UID=0
# 当前 Shell名称
CURRENT_SHELL=$SHELL

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
      echo -e "Exec：${b_CGSC}${@/-x/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-m"|"--msg")
      echo -e "Info：${b_CCIN}${@/-m/}${CDEF}";;          # print iinfo message
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
            prompt -x "Backup $1 as $1.newbak (rewrite) "
            cp $1 $1.newbak
        else
            # 没有bak文件，创建备份
            prompt -x "Backup $1 as $1.bak"
            cp $1 $1.bak
        fi
    else
        # 如果不存在要备份的文件,不执行
        prompt -e "File $1 not found, pass."
    fi
} 

# 执行apt命令 注意，检查点一后才能使用这个方法
doApt () {
    prompt -x "doApt: $@"
    if [ "$1" = "install" ] || [ "$1" = "remove" ] || [ "$1" = "dist-upgrade" ] || [ "$1" = "upgrade" ];then
        if [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 0 ];then
            apt $@
        elif [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 1 ];then
            apt $@ -y
        fi
    else
        apt $@
    fi
}

# 新建文件夹 $1
addFolder () {
    if [ $# -ne 1 ];then
        prompt -e "addFolder () can only have one param"
        exit 5
    fi
    if ! [ -d $1 ];then
        prompt -x "Mkdir $1 "
        mkdir $1
    fi
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
┗ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┛ 
==========================================

\e[0m"
# R
echo -e "\e[1;31m Preparing(1s)...\n\e[0m" 
sleep 1

# Prep-预备步骤

prompt -i "Current User Set: $CURRENT_USER_SET"
prompt -i "Current Shell: $CURRENT_SHELL"
prompt -i "Current User Set Home: $HOME_INDEX"
prompt -i "Current Hostname Set: $HOSTNAME"
# 检查是否有root权限，无则退出，提示用户使用root权限。
prompt -i "\nChecking for root access...\n"
if [ "$UID" -eq "$ROOT_UID" ]; then
  prompt -s "\n——————————  Unit Ready  ——————————\n"
else
  # Error message
  prompt -e "\n [ Error ] -> Please run with root user(ROOT, NOT SUDO !)  \n"
  exit 1
fi

#### 预运行
# 参数赋值(从已经初始化的参数中获得)
# Git
if [ "$SET_GIT_USER" -eq 0 ];then
    SET_GIT_USER=$CURRENT_USER_SET
fi
if [ "$SET_GIT_EMAIL" -eq 0 ];then
    SET_GIT_EMAIL=$CURRENT_USER_SET@$HOSTNAME
fi
# SSH
if [ "$SET_SSH_KEY_COMMENT" -eq 0 ];then
    SET_SSH_KEY_COMMENT="A New SSH Key Generate for "$CURRENT_USER"@"$HOSTNAME" By Debian 11_GNOME_Deploy_Script"
fi


### 确认运行模块
# R
comfirm "\e[1;31m Improperly usage of this script may has potential harm to your computer「If you don't know what you're doing, just press ENTER」[y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  prompt -s "\n"
elif [ $choice == 2 ];then
  prompt -w "Looking forward to the next meeting ——  https://rmshadows.gitee.io"
  exit 0
else
  prompt -e "ERROR:Unknown Option..."
  exit 5
fi


:<<Check-1-检查点一
更改镜像（针对国内服务器）
系统更新
默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
更新源、更新系统。
配置unattended-upgrades
Check-1-检查点一
prompt -i "——————————  Check 1  ——————————"

# 预安装 安装部分先决软件包 后面还有
prompt -x "Install pre-required packages..."
doApt update
# 确保https源可用 
doApt install apt-transport-https
doApt install ca-certificates
# 添加清华大学 Debian 11 镜像源
if [ "$SET_APT_SOURCE" -eq 1 ];then
    backupFile "/etc/apt/sources.list"
    prompt -x "Set Tsinghua Debian 11 mirror..."
    echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free" | tee /etc/apt/sources.list
# 添加自己的Debian源
elif [ "$SET_APT_SOURCE" -eq 2 ];then
    backupFile "/etc/apt/sources.list"
    prompt -x "Set your apt source..."
    echo "$SET_YOUR_APT_SOURCE" | tee /etc/apt/sources.list
fi

# 配置unattended-upgrades
if [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 0 ];then
    prompt -m "Leave unattended-upgrades.service nothing done...."
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 1 ];then
    prompt -x "Enable unattended-upgrades.service"
    systemctl enable unattended-upgrades.service
elif [ "$SET_ENABLE_UNATTENDED_UPGRADE" -eq 2 ];then
    prompt -x "Disable unattended-upgrades.service"
    systemctl disable unattended-upgrades.service
fi

# 更新源-预先安装的软件
doApt update
# 保证sudo添加可用
doApt install gawk
# 保证后面Vbox密钥添加
doApt install wget
doApt install gnupg2
doApt install gnupg
doApt install lsb-release

# 更新系统
if [ "$SET_APT_UPGRADE" -eq 0 ];then
    prompt -x "Apt update only...."
    doApt update
elif [ "$SET_APT_UPGRADE" -eq 1 ];then
    prompt -x "Apt Dist-upgrade...."
    doApt update && doApt dist-upgrade
elif [ "$SET_APT_UPGRADE" -eq 2 ];then
    prompt -x "Apt upgrade...."
    doApt update && doApt upgrade
fi

:<<Check-2-检查点二
安装sudo openssh-server zsh(必选)
配置root用户zsh
新建用户
配置用户zsh
添加用户到sudo组。
设置用户sudo免密码。
Check-2-检查点二

# 安装sudo openssh-server zsh
prompt -i "sudo openssh-server will be installed."
doApt install sudo
doApt install openssh-server

# 设置root用户使用zsh 注意，这里还不能用$HOME_INDEX
# 配置root用户zsh
prompt -i "Current shell：$CURRENT_SHELL"
if [ "$CURRENT_SHELL" == "/bin/bash" ]; then
    shell_conf=".bashrc"
    if [ "$SET_BASH_TO_ZSH" -eq 1 ];then
        # 判断是否安装zsh
        if ! [ -x "$(command -v zsh)" ]; then
            prompt -i 'Error: Zsh is not installed.' >&2
            prompt -x "Install Zsh..."
            doApt install zsh
        fi
        if ! [ -x "$(command -v zsh)" ]; then
            prompt -e "ZSH install failed !"
            exit 1
        else
            shell_conf=".zshrc"
            prompt -x "Config ZSHRC...."
            echo "$ZSHRC_CONFIG" > /root/$shell_conf
            prompt -x "Set zsh for root."
            usermod -s /bin/zsh root
        fi
    fi
elif [ "$CURRENT_SHELL" == "/bin/zsh" ];then
    # 如果使用zsh，则更改zsh配置
    shell_conf=".zshrc"
    if [ "$SET_ZSHRC" -eq 1 ];then
        backupFile "/root/$shell_conf"
        prompt -x "Config root's ZSHRC"
        echo "$ZSHRC_CONFIG" > /root/$shell_conf
    elif [ "$SET_ZSHRC" -eq 0 ];then
        prompt -m "Keep original ZSHRC file."
    fi
else
    prompt -e "Unknown shell: $CURRENT_SHELL"
    exit 1
fi

# 新建用户 如果已经存在，不添加，直接配置该用户
if [ "$SET_USER" -eq 1 ];then
    prompt -x "Creating user $CURRENT_USER_SET...."
    # 检测是否存在该用户
    egrep "^$CURRENT_USER_SET" /etc/passwd >/dev/null
    if [ $? -eq 0 ]; then
        # 存在用户 
        prompt -e "Failed to add $CURRENT_USER_SET. Username already exists! Continue with $CURRENT_USER_SET"
    else
        # 不存在则新建
        encrypt_pass=$(perl -e 'print crypt($ARGV[0], "password")' $SET_USER_PASSWD)
        useradd -m -s /bin/zsh -G sudo -p $encrypt_pass $CURRENT_USER_SET
        if [ $? -eq 0 ];then
            prompt -i "User has been added to system!"
        else
            echo "Failed to add a user!"
            exit 1
        fi
    fi
fi

# 设置用户zsh
if [ "$SET_BASH_TO_ZSH" -eq 1 ];then
    prompt -x "Set zsh for $CURRENT_USER_SET"
    usermod -s /bin/zsh $CURRENT_USER_SET
    if [ "$SET_ZSHRC" -eq 1 ];then
        backupFile "$HOME_INDEX/$shell_conf"
        prompt -x "Config user's ZSHRC"
        echo "$ZSHRC_CONFIG" > $HOME_INDEX/$shell_conf
    fi
fi

# 检查是否在sudoer
prompt -i "Check if $CURRENT_USER_SET in sudoers"
# 检查是否在sudo组中 0 false 1 true
IS_SUDOER=-1
IS_SUDO_NOPASSWD=-1
# 检查是否在sudo组
if groups $CURRENT_USER_SET | grep sudo > /dev/null ;then
    # 是sudo组
    IS_SUDOER=1
    # 检查是否免密码sudo
    check_var="ALL=(ALL)NOPASSWD:ALL"
    if cat '/etc/sudoers' | grep $check_var | grep $CURRENT_USER_SET > /dev/null ;then
        # sudo免密码
        IS_SUDO_NOPASSWD=1
    else
        # sudo要密码
        IS_SUDO_NOPASSWD=0
    fi
else
    # 不是sudoer
    IS_SUDOER=0
    IS_SUDO_NOPASSWD=0
fi

# 配置用户为sudo
if [ "$CURRENT_USER_SET" == "root" ];then
    prompt -w "Not sudo for root, pass."
elif [ "$IS_SUDOER" -eq 0 ];then
    # 如果没有在sudo组,添加用户到sudo组
    if [ "$SET_USER_SUDOER" -eq 1 ];then
        prompt -x "Add $CURRENT_USER_SET to sudo group...."
        usermod -a -G sudo $CURRENT_USER_SET
        IS_SUDOER=1
    fi
    # 配置sudo免密码
    if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ] && [ "$SET_SUDOER_NOPASSWD" -eq 1 ];then
        prompt -x "Set $CURRENT_USER_SET sudo nopasswd...."
        SUDOER_STRING="$CURRENT_USER_SET ALL=(ALL)NOPASSWD:ALL"
        echo $SUDOER_STRING >> /etc/sudoers
        IS_SUDO_NOPASSWD=1
    fi
elif [ "$IS_SUDOER" -eq 1 ];then
    # 如果已经是sudoer 配置是否免密码
    if [ "$IS_SUDO_NOPASSWD" -eq 0 ] && [ "$SET_SUDOER_NOPASSWD" -eq 1 ];then
        prompt -x "Set $CURRENT_USER_SET sudo not passwd."
        check_var="ALL=(ALL:ALL) ALL"
        # 获取行号
        idx=`cat /etc/sudoers | grep -n ^$CURRENT_USER_SET | grep $check_var | gawk '{print $1}' FS=":"`
        # echo $idx
        # 找到的Index
        idxl=($idx)
        idxlen=${#idxl[@]}  
        # echo $idxlen
        SUDO_STRING="$CURRENT_USER_SET  ALL=(ALL)NOPASSWD:ALL"
        if [ $idxlen -eq 1 ];then
            sed -i "$idx d" /etc/sudoers
            echo $SUDO_STRING >> /etc/sudoers
        elif [ $idxlen -eq 0 ];then
            prompt -w "Setting not found in /etc/sudoers!"
            echo $SUDO_STRING >> /etc/sudoers
        else
            prompt -e "Find duplicate user setting in /etc/sudoers! Check manually!"
            exit 1
        fi
        IS_SUDO_NOPASSWD=1
    elif [ "$IS_SUDO_NOPASSWD" -eq 1 ] && [ "$SET_SUDOER_NOPASSWD" -eq 0 ];then
        prompt -x "Set $CURRENT_USER_SET sudo required passwd."
        check_var="ALL=(ALL)NOPASSWD:ALL"
        # 获取行号
        idx=`cat /etc/sudoers | grep -n ^$CURRENT_USER_SET | grep $check_var | gawk '{print $1}' FS=":"`
        # echo $idx
        # 找到的Index
        idxl=($idx)
        idxlen=${#idxl[@]}  
        # echo $idxlen
        SUDO_STRING="$CURRENT_USER_SET  ALL=(ALL:ALL) ALL"
        if [ $idxlen -eq 1 ];then
            sed -i "$idx d" /etc/sudoers
            echo $SUDO_STRING >> /etc/sudoers
        elif [ $idxlen -eq 0 ];then
            prompt -w "Setting not found in /etc/sudoers!"
            echo $SUDO_STRING >> /etc/sudoers
        else
            prompt -e "Find duplicate user setting in /etc/sudoers! Check manually!"
            exit 1
        fi
        IS_SUDO_NOPASSWD=0
    fi
else
    prompt -e "$IS_SUDOER not 0 or 1 ."
    exit 1
fi


:<<Check-3-检查点三
安装vim-full，卸载vim-tiny；
添加/usr/sbin到环境变量；
添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）；
安装bash-completion；
安装zsh-autosuggestions
Check-3-检查点三
# 安装vim-full，卸载vim-tiny；
if [ "$SET_VIM_TINY_TO_FULL" -eq 1 ];then
    prompt -x "Uninstall vim-tiny and install vim-full."
    doApt remove vim-tiny
    doApt install vim
fi

# 添加添加HOME目录文件夹（Data for data;Applications for apps;Temp for file transport;Workplace for work;Services for service）；
prompt -x "Creating folders in $HOME_INDEX..."
addFolder $HOME_INDEX/Data
addFolder $HOME_INDEX/Applications
addFolder $HOME_INDEX/Temp
addFolder $HOME_INDEX/Workplace
addFolder $HOME_INDEX/Services
echo "#!/bin/bash
cp *.service /lib/systemd/system/
sudo systemctl daemon-reload
" > $HOME_INDEX/Services/Install_Servces.sh
chmod +x $HOME_INDEX/Services/Install_Servces.sh
addFolder $HOME_INDEX/Logs
addFolder $HOME_INDEX/Logs/apache2
addFolder $HOME_INDEX/Logs/nginx
chown $CURRENT_USER_SET -hR $HOME_INDEX

# 添加/usr/sbin到环境变量；
if [ "$SET_ADD_SBIN_ENV" -eq 1 ];then
    prompt -x "Add sbin to path..."
    check_var="export PATH=\"\$PATH:/usr/sbin\""
    # G
    echo -e "\e[1;32m Checking path in $shell_conf…… \e[0m"
    if cat '$HOME_INDEX/$shell_conf' | grep "$check_var"
    then
        # B
        echo -e "\e[1;34m $check_var  detected, path already existd, pass.\e[0m"
    else
        # G
        echo -e "\e[1;32m Add /usr/sbin to $shell_conf. \e[0m"
        echo "export PATH=\"\$PATH:/usr/sbin\"" >> $HOME_INDEX/$shell_conf
    fi
fi

# 安装bash-completion；
if [ "$SET_BASH_COMPLETION" -eq 1 ];then
    prompt -x "Install bash-completion..."
    doApt install bash-completion
fi

# 安装zsh-autosuggestions
if [ "$SET_ZSH_AUTOSUGGESTIONS" -eq 1 ];then
    prompt -x "Install zsh-autosuggestions..."
    doApt install zsh-autosuggestions
fi

:<<Check-4-检查点四
自定义自己的服务（运行一个shell脚本）
配置主机名
配置语言支持
配置时区
设置TTY1自动登录
Check-4-检查点四
# 自定义自己的服务（运行一个shell脚本）
if [ "$SET_SYSTEMCTL_SERVICE" -eq 1 ];then
    prompt -x "Create a /lib/systemd/system/customize-autorun.service."
    addFolder $HOME_INDEX/.$CURRENT_USER_SET/
    addFolder $HOME_INDEX/.$CURRENT_USER_SET/scripts/
    prompt -x "Generate file: $HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh "
    echo "#!/bin/bash
echo -e \"\e[1;33m Hello World \e[0m\"
" > $HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh
    chmod +x $HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh
    prompt -x "Build /lib/systemd/system/customize-autorun.service."
    if ! [ -f /lib/systemd/system/customize-autorun.service ];then
        echo "[Unit]
Description=自定义的服务，用于开启启动/home/用户/.用户名/script下的shell脚本，配置完成请手动启用。注意，此脚本将以root身份运行！
After=network.target 

[Service]
ExecStart=$HOME_INDEX/.$CURRENT_USER_SET/scripts/autorun.sh
Type=forking
PrivateTmp=True

[Install]
WantedBy=multi-user.target
" > /lib/systemd/system/customize-autorun.service
    fi
fi

# 设置主机名
if ! [ "$SET_HOST_NAME" -eq 0 ];then
    prompt -x "Setup hostname"
    echo "$HOSTNAME" > /etc/hostname
    check_var="127.0.1.1"
    # 获取行号
    idx=`cat /etc/hosts | grep -n ^$check_var | gawk '{print $1}' FS=":"`
    # 找到的Index
    idxl=($idx)
    idxlen=${#idxl[@]}  
    # echo $idxlen
    I_STRING="127.0.1.1\t$HOSTNAME"
    if [ $idxlen -eq 1 ];then
        # 删除行
        sed -i "$idx d" /etc/hosts
        # echo "127.0.1.1	$HOSTNAME" >> /etc/hosts
        # 在前面插入
        sed -i "$idx i $I_STRING" /etc/hosts
    elif [ $idxlen -eq 0 ];then
        prompt -w "Setting not found in /etc/hosts!"
        echo $I_STRING >> /etc/hosts
    else
        prompt -e "Find duplicate user setting 127.0.1.1 in /etc/hosts! Check manually!"
        exit 1
    fi
fi

# 设置语言支持
if ! [ "$SET_LOCALES" == 0 ];then
    check_var=$SET_LOCALES
    if cat '/etc/locale.gen' | grep "$check_var" > /dev/null ;then
        prompt -w "Locales NOT SET! Pass!"
    else
        prompt -x "Setup locales"
        backupFile /etc/locale.gen
        echo "$SET_LOCALES" > /etc/locale.gen
        locale-gen  
    fi
fi

# 设置时区
if ! [ "$SET_TIME_ZONE" == 0 ];then
    prompt -x "Setup timezone"
    backupFile /etc/localtime
    ln -sf "$SET_TIME_ZONE" /etc/localtime
fi

# 设置TTY1自动登录
if [ "$SET_TTY_AUTOLOGIN" -eq 1 ];then
    prompt -x "Setup tty1 automatic login..."
    sed -i "s/#NAutoVTs=6/NAutoVTs=1/g" /etc/systemd/logind.conf
    addFolder /etc/systemd/system/getty@tty1.service.d
    echo "[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin $CURRENT_USER_SET --noclear %I \$TERM
" > /etc/systemd/system/getty@tty1.service.d/override.conf
fi

:<<Check-5-检查点五
从apt仓库拉取常用软件
安装Python3
配置Python3源为清华大学镜像
安装配置Git(配置User Email)
安装配置SSH
安装配置npm
安装nodejs
Check-5-检查点五
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
        app_list=$APT_TO_INSTALL_INDEX_1
    else
        prompt -e "APT_TO_INSTALL_INDEX List not found !"
        exit 2
    fi
    # 首先，处理稍后要安装的软件包
    later_list=$SET_APT_TO_INSTALL_LATER
    later_list=$(echo $later_list | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
    later_list=($later_list)
    later_len=${#later_list[@]}
    prompt -m "Packages below will be installed: "
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
    prompt -m "Begin installation: "
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
        prompt -e "Continue...."
        sleep 2
        num=1
        for var in ${immediately_task[@]}
        do
            prompt -m "Install package: $num - $var ..."
            doApt install $var
            num=$((num+1))
        done
    fi 
fi

# 安装Python3
if [ "$SET_PYTHON3_INSTALL" -eq 1 ];then
    prompt -x "Install Python3 and pip3..."
    doApt install python3
    doApt install python3-pip
fi

# 配置Python3源为清华大学镜像
if [ "$SET_PYTHON3_MIRROR" -eq 1 ];then
    prompt -x "Setup pip mirror "
    doApt install software-properties-common
    doApt install python3-software-properties
    doApt install python3-pip
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
elif [ "$SET_PYTHON3_MIRROR" -eq 0 ];then
    prompt -i "Pass pip mirror site setup."
else
    prompt -w "Setup customize pip mirror !"
    doApt install software-properties-common
    doApt install python3-software-properties
    doApt install python3-pip
    pip install -i $SET_PYTHON3_MIRROR -U
    pip config set global.index-url $SET_PYTHON3_MIRROR
    pip3 install -i $SET_PYTHON3_MIRROR pip -U
    pip3 config set global.index-url $SET_PYTHON3_MIRROR
fi


# 安装配置Git(配置User Email)
# 安装配置Git(配置User Email)
if [ "$SET_INSTALL_GIT" -eq 1 ];then
    prompt -x "Install Git"
    doApt install git
    if [ $? -eq 0 ];then
        git config --global user.name $SET_GIT_USER
        git config --global user.email $SET_GIT_EMAIL
    else
        prompt -e "Failed to install git"
        exit 2
    fi
fi

# 安装配置SSH
if [ "$SET_INSTALL_OPENSSH" -eq 1 ];then
    doApt install openssh-server
    prompt -x "SSH keep alive interval set 60s."
    check_var="ClientAliveInterval"
    # 获取行号
    idx=`cat /etc/ssh/sshd_config | grep -n ^$check_var | gawk '{print $1}' FS=":"`
    # 找到的Index
    idxl=($idx)
    idxlen=${#idxl[@]}  
    # echo $idxlen
    I_STRING="ClientAliveInterval 60"
    if [ $idxlen -eq 1 ];then
        # 删除行
        sed -i "$idx d" /etc/ssh/sshd_config
        # 在前面插入
        sed -i "$idx i $I_STRING" /etc/ssh/sshd_config
    elif [ $idxlen -eq 0 ];then
        prompt -w "Setting not found in /etc/ssh/sshd_config!"
        echo $I_STRING >> /etc/ssh/sshd_config
    else
        prompt -e "Find duplicate user setting 'ClientAliveInterval' in /etc/ssh/sshd_config! Check manually!"
        exit 1
    fi

    check_var="ClientAliveCountMax"
    # 获取行号
    idx=`cat /etc/ssh/sshd_config | grep -n ^$check_var | gawk '{print $1}' FS=":"`
    # 找到的Index
    idxl=($idx)
    idxlen=${#idxl[@]}  
    # echo $idxlen
    I_STRING="ClientAliveCountMax 3"
    if [ $idxlen -eq 1 ];then
        # 删除行
        sed -i "$idx d" /etc/ssh/sshd_config
        # 在前面插入
        sed -i "$idx i $I_STRING" /etc/ssh/sshd_config
    elif [ $idxlen -eq 0 ];then
        prompt -w "Setting not found in /etc/ssh/sshd_config!"
        echo $I_STRING >> /etc/ssh/sshd_config
    else
        prompt -e "Find duplicate user setting 'ClientAliveCountMax' in /etc/ssh/sshd_config! Check manually!"
        exit 1
    fi

    if [ "$SET_ENABLE_SSH" -eq 1 ];then
        prompt -x "Enable sh.service"
        sudo systemctl enable ssh.service
    elif [ "$SET_ENABLE_SSH" -eq 0 ];then
        prompt -x "Disable sh.service"
        sudo systemctl disable ssh.service
    fi
fi

# 安装配置npm
if [ "$SET_INSTALL_NPM" -eq 1 ];then
    doApt install npm
    if [ "$SET_INSTALL_CNPM" -eq 1 ];then
        if ! [ -x "$(command -v cnpm)" ]; then
            prompt -x "Install CNPM"
            npm install cnpm -g --registry=https://r.npm.taobao.org
        fi
    fi
fi

# Nodejs
if [ "$SET_INSTALL_NODEJS" -eq 1 ];then
    doApt install nodejs
fi

:<<Check-6-检查点六
安装HTTP服务
Check-6-检查点六
# 安装HTTP Server
if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ];then
    if [ -x "$(command -v apache2ctl)" ]; then
        prompt -x 'Stop apache2...' >&2
        systemctl stop apache2.service
        systemctl disable apache2.service
    fi
    prompt -x "Install nginx..."
    doApt install nginx
    prompt -m "Set nginx share directory $HOME_INDEX/nginx "
    addFolder $HOME_INDEX/nginx
    addFolder $HOME_INDEX/nginx/home_page
    addFolder $HOME_INDEX/nginx/nres
    addFolder $HOME_INDEX/nginx/res
    prompt -x "Set $HOME_INDEX/nginx mode 755"
    chmod 755 $HOME_INDEX/nginx
    chmod 755 $HOME_INDEX/nginx/home_page
    chmod 755 $HOME_INDEX/nginx/nres
    chmod 755 $HOME_INDEX/nginx/res
    prompt -x "Set $HOME_INDEX/nginx own by $CURRENT_USER_SET"
    chown $CURRENT_USER_SET $HOME_INDEX/nginx
    chown $CURRENT_USER_SET $HOME_INDEX/nginx/home_page
    chown $CURRENT_USER_SET $HOME_INDEX/nginx/nres
    chown $CURRENT_USER_SET $HOME_INDEX/nginx/res
    if ! [ -x "$(command -v htpasswd)" ]; then
        prompt -x 'Install apache2-utils...'
        doApt install apache2-utils
    fi
    prompt -x "Generate a passwd file at user home."
    htpasswd -bc "$HOME_INDEX"/nginx_res_login $SET_NGINX_RES_USER $SET_NGINX_RES_PASSWD
    if [ $? -eq 0 ];then
        backupFile /etc/nginx/nginx.conf
        backupFile /etc/nginx/sites-available/default.conf
        prompt -i "Set up a new nginx.conf"
        echo "$NGINX_GLOBAL_CONF" > /etc/nginx/nginx.conf
        echo "$NGINX_BLOCK_IP" > /etc/nginx/block_ip.conf
        prompt -i "Genarate a http website and a https website."
        echo "$NGINX_HTTP_SITE" > /etc/nginx/sites-available/http
        echo "$NGINX_HTTPS_SITE" > /etc/nginx/sites-available/https
        if [ "$SET_ENABLE_HTTPS_SITE" -eq 1 ];then
            prompt -x "Disable default site and Enable nginx https site."
            if [ -f /etc/nginx/sites-enabled/default ];then
                rm /etc/nginx/sites-enabled/default
            fi
            if ! [ -f /etc/nginx/sites-enabled/https ];then
                # 请使用绝对路径
                ln -s /etc/nginx/sites-available/https /etc/nginx/sites-enabled/https
            fi
        fi
        if [ "$SET_ENABLE_HTTP_SERVICE" -eq 0 ];then
            prompt -x "Disable Nginx service."
            systemctl disable nginx.service
        elif [ "$SET_ENABLE_HTTP_SERVICE" -eq 1 ];then
            prompt -x "Enable Nginx service."
            systemctl enable nginx.service
        fi
    else
        prompt -e "Nginx's installation seems failed."
        exit 1
    fi
elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ];then
    if ! [ -x "$(command -v nginx)" ]; then
        prompt -x 'Stop nginx...' >&2
        systemctl stop nginx.service
        systemctl disable nginx.service
    fi
    prompt -x "Install apache2..."
    doApt install apache2
    prompt -m "Make a Apache2 share directory $HOME_INDEX/apache2 "
    addFolder $HOME_INDEX/apache2
    prompt -x "Set $HOME_INDEX/apache2 mode 755"
    chmod 755 $HOME_INDEX/apache2
    prompt -x "Set $HOME_INDEX/apache2 own by $CURRENT_USER_SET"
    chown $CURRENT_USER_SET $HOME_INDEX/apache2
    prompt -i "Genarate a http website and a https website."
    echo "$APACHE2_HTTP_SITE" > /etc/apache2/sites-available/http.conf
    echo "$APACHE2_HTTPS_SITE" > /etc/apache2/sites-available/https.conf
    echo "$APACHE2_PROXYTEST_SITE" > /etc/apache2/sites-available/proxy_test.conf
    if [ $? -eq 0 ];then
        backupFile /etc/apache2/apache2.conf
        prompt -x "Set Apache2 directory $HOME_INDEX/apache2 "
        echo $APACHE2_GLOBAL_CONF > /etc/apache2/apache2.conf
        # sed -i 's#/var/www/#'$HOME_INDEX'/apache2/#g' /etc/apache2/apache2.conf
        # sed -i 's#DocumentRoot /var/www/html#DocumentRoot '$HOME_INDEX'/apache2#g' /etc/apache2/sites-available/000-default.conf
        # 禁止浏览/usr/share
        if [ "$SET_APACHE_DENY_USR_SHARE" -eq 0 ];then
            backupFile /etc/apache2/apache2.conf
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
        fi
        if [ "$SET_ENABLE_HTTPS_SITE" -eq 0 ];then
            prompt -x "Disable default site and Enable nginx https site."
            a2enmod ssl
            a2enmod socache_shmcb
            a2enmod rewrite
            a2enmod headers
            a2enmod proxy proxy_http
            a2dissite 000-default.conf
            a2ensite https.conf
            # if [ -f /etc/apache2/sites-enabled/default ];then
            #     rm /etc/apache2/sites-enabled/default
            # fi
            # if ! [ -f /etc/apache2/sites-enabled/https ];then
            #     ln -s /etc/apache2/sites-available/https /etc/nginx/sites-enabled/https
            # fi
        fi
        if [ "$SET_ENABLE_HTTP_SERVICE" -eq 0 ];then
            prompt -x "Disable Apache2 service."
            systemctl disable apache2.service
        elif [ "$SET_ENABLE_HTTP_SERVICE" -eq 1 ];then
            prompt -x "Enable Apache2 service."
            systemctl enable apache2.service
        fi
    else
        prompt -e "Apache2's installation seems failed."
        exit 1
    fi
fi

:<<Check-7-检查点七
安装docker-ce
Check-7-检查点七
if [ "$SET_INSTALL_DOCKER_CE" -eq 1 ];then
    prompt -x "Install Docker-ce(Official)"
    doApt remove docker docker-engine docker.io containerd runc
    
    doApt install apt-transport-https ca-certificates curl gnupg lsb-release
    # /usr/share/keyrings/docker-archive-keyring.gpg
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
    chmod 644 /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    doApt update
    doApt install docker-ce
    
    if [ $? == 0 ]
    then
        usermod -aG docker $CURRENT_USER_SET  
    else
        prompt -e "It seems some error has occurred while installation, is docker installed correctly ?"
    fi
elif [ "$SET_INSTALL_DOCKER_CE" -eq 2 ];then
    prompt -x "Install Docker-ce(Tsinghua mirror site)"
    doApt remove docker docker-engine docker.io containerd runc
    
    doApt install apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl https://download.docker.com/linux/debian/gpg | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/docker-archive-keyring.gpg --import
    chmod 644 /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
    echo \
       "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian \
       $(lsb_release -cs) \
       stable" > /etc/apt/sources.list.d/docker.list
    doApt update
    doApt install docker-ce

    if [ $? == 0 ]
    then
        usermod -aG docker $CURRENT_USER_SET  
    else
        prompt -e "It seems some error has occurred while installation, is docker installed correctly ?"
    fi
fi


:<<Check-8-检查点八
安装UFW
Check-8-检查点八
# 安装UFW，默认开放22 ，80，443
if [ "$SET_INSTALL_UFW" -eq 1 ];then
    prompt -x "Install UFW"
    doApt install ufw
    ufw default deny incoming
    ufw default allow outgoing
    # 端口列表
    idxl=($SET_UFW_ALLOW)
    idxlen=${#idxl[@]}
    # echo $idxlen
    if [ $idxlen -eq 0 ];then
        prompt -w "Are you sure to have UFW not allow anything ?!...ENEN SSH PORT???!"
        exit 1
    else
        for var in ${idxl[@]}
        do
            prompt -m "UFW Allow: $var "
            ufw allow $var
        done   
    fi
    prompt -x "Enable UFW"
    ufw enable
fi


#### 最后的步骤
# 安装later_task中的软件
if [ "$SET_APT_INSTALL" -eq 1 ];then
    doApt install ${later_task[@]}
    if [ $? != 0 ];then
        prompt -e "Continue installation..."
        sleep 2
        num=1
        for var in ${later_task[@]}
        do
            prompt -m "$num : $var。"
            doApt install $var
            num=$((num+1))
        done
    fi 
fi

prompt -i "=================================================="

if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ];then
    prompt -w "NGINX: Check config: If error reported, fix it manually.Else: home_page to place static sites and nres for file sharing."
    nginx -t
elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ];then
    prompt -w "APACHE2: Check config: If error reported, fix it manually.Else: home_page to place static sites and nres for file sharing."
    apache2ctl configtest
fi

prompt -s "Finally ,use (ssh-copy-id -i .ssh/id_rsa.pub User@IP) to add your local ssh_pub_key to remote server."

prompt -i "=================================================="

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
