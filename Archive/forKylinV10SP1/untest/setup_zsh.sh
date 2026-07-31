#!/usr/bin/env bash
# 仅将 root + 当前用户 的 shell 切换为 zsh
# 不影响系统中的其他用户
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "请用 root 运行：sudo bash $0"
  exit 1
fi

log() { echo -e "[+] $*"; }
warn() { echo -e "[!] $*" >&2; }

# ---- 0) 仅支持 apt 的发行版（Debian / Ubuntu）----
if ! command -v apt-get >/dev/null 2>&1; then
  warn "未检测到 apt-get。此脚本仅支持 Debian/Ubuntu。"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ---- 1) 基础工具 ----
log "安装 bash-completion / ag / zsh 及插件..."
apt-get update -y
apt-get install -y \
  bash-completion \
  silversearcher-ag \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions

ZSH_PATH="$(command -v zsh)"
log "zsh 路径：${ZSH_PATH}"

# ---- 2) 确保 bash-completion 生效 ----
if [[ -f /usr/share/bash-completion/bash_completion ]] \
   && ! grep -q bash_completion /etc/bash.bashrc; then
  log "为 /etc/bash.bashrc 启用 bash-completion"
  cat >> /etc/bash.bashrc <<'EOF'

# --- added by setup_zsh.sh ---
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi
# --- end ---
EOF
fi

# ---- 3) 确保 zsh 在 /etc/shells ----
grep -qx "${ZSH_PATH}" /etc/shells || echo "${ZSH_PATH}" >> /etc/shells

# ---- 4) 当前用户判定 ----
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  CURRENT_USER="${SUDO_USER}"
else
  CURRENT_USER="$(whoami)"
fi
log "当前用户：${CURRENT_USER}"

# ---- 5) zshrc 模板 ----
read -r -d '' ZSHRC_TEMPLATE <<'EOF'
# ryan
# ~/.zshrc file for zsh non-login shells.
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

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# hide EOL sign ('%')
export PROMPT_EOL_MARK=""

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
alias history="history 0"

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)──}(%B%F{%(#.red.blue)}%n%(#.💀.㉿)%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '
    RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'

    # enable syntax-highlighting
    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && [ "$color_prompt" = yes ]; then
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
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%# '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    TERM_TITLE='\e]0;${debian_chroot:+($debian_chroot)}%n@%m: %~\a'
    ;;
*)
    ;;
esac

new_line_before_prompt=yes
precmd() {
    # Print the previously configured title
    print -Pn "$TERM_TITLE"

    # Print a new line before the prompt, but only if it is not the first line
    if [ "$new_line_before_prompt" = yes ]; then
	if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
	    _NEW_LINE_BEFORE_PROMPT=1
	else
	    print ""
	fi
    fi
}

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

    # Take advantage of $LS_COLORS for completion as well
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# some more ls aliases
# 默认
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Git
git-switch() {
    local current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 1
    local main_branch=""

    # 检测主分支名（优先 main）
    if git show-ref --verify --quiet refs/heads/main; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        main_branch="master"
    fi

    if [ "$current" = "dev" ] && [ -n "$main_branch" ]; then
        echo "切换 dev → $main_branch"
        git checkout "$main_branch"
    elif [ "$current" = "$main_branch" ]; then
        echo "切换 $main_branch → dev"
        git checkout dev
    else
        echo "当前分支: $current (未定义切换规则)"
    fi
}
alias gswitch=git-switch
alias gitac='git add . -A && git commit -m "add and update ———— `date` "'
# alias gitfindhistory='gitsearch(){git log --all --pretty=oneline -- $1};gitsearch'
alias gitam='git add . -A && git commit -m '
# alias githardpull='git fetch --all && git reset --hard'
alias gplb='git pull && git branch -a'


# SSH
alias ssh-key-install='ssh-copy-id -i /home/ryan/.ssh/id_rsa.pub'
alias sshpwdconnect='pwdconnect(){sshpass -p "$1" ssh};pwdconnect'

# 代理
alias all_proxy_sock5='export ALL_PROXY=socks5://127.0.0.1:20170'

# 应用程序
# alias ffmpegss='ffmpegCutVideo(){ffmpeg -ss $3 -to $4 -i $1 -vcodec copy -acodec copy $2};ffmpegCutVideo'
# alias hcg='hexo clean && hexo g'
# alias p3='python3'

# 系统
alias ssa='sudo systemctl start'
alias sss='sudo systemctl status'
alias ssd='sudo systemctl stop'
alias ssf='sudo systemctl restart'
alias zshrc='vim /home/ryan/.zshrc'
alias szsh='source /home/ryan/.zshrc'
alias upgrade='sudo apt update && sudo apt upgrade'
alias duls='du -sh ./*'
alias dulsd='du -sh `la`'
alias p3='python3'
alias cc='conky -c'

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

# Python3自定义的全局环境激活
alias acpy='activatePythonVenv'
function activatePythonVenv(){
    # 如果存在Python虚拟环境激活文件
    if [ -f "/home/ryan/.python_venv_activate" ];then
        source /home/ryan/.python_venv_activate
    fi
}

# 默认激活Python环境 
activatePythonVenv
# export PATH="$PATH:/usr/sbin"

# Created by `pipx` on 2023-06-30 12:10:31
# :/usr/games:/usr/local/games
export PATH="$PATH:/home/ryan/.local/bin"
EOF

# ---- 6) 写入 .zshrc ----
write_zshrc() {
  local user="$1"
  local home="$2"
  local zshrc="${home}/.zshrc"

  tmp="$(mktemp)"
  printf "%s\n" "${ZSHRC_TEMPLATE}" \
    | sed "s|^# ryan$|# ${user}|" \
    | sed "s|/home/ryan|${home}|g" \
    > "${tmp}"

  mkdir -p "${home}/.cache"
  [[ -f "${zshrc}" ]] && cp -a "${zshrc}" "${zshrc}.bak.$(date +%Y%m%d%H%M%S)"
  install -m 0644 "${tmp}" "${zshrc}"
  chown "${user}:${user}" "${zshrc}" 2>/dev/null || true
  rm -f "${tmp}"

  log "已写入 ${zshrc}"
}

# ---- 7) 切换 shell ----
set_shell() {
  local user="$1"
  local current_shell
  current_shell="$(getent passwd "${user}" | cut -d: -f7)"

  [[ "${current_shell}" == "${ZSH_PATH}" ]] && {
    log "${user} 已是 zsh（跳过）"
    return
  }

  usermod -s "${ZSH_PATH}" "${user}"
  log "已将 ${user} 的 shell 设置为 zsh"
}

# ---- 8) 处理 root ----
log "处理 root 用户"
write_zshrc root /root
set_shell root

# ---- 9) 处理当前用户（非 root）----
if [[ "${CURRENT_USER}" != "root" ]]; then
  USER_HOME="$(getent passwd "${CURRENT_USER}" | cut -d: -f6)"
  log "处理当前用户 ${CURRENT_USER}"
  write_zshrc "${CURRENT_USER}" "${USER_HOME}"
  set_shell "${CURRENT_USER}"
fi

log "全部完成。重新登录或执行 exec zsh 生效。"

