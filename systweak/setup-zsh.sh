#!/usr/bin/env bash
# 安装 zsh + 插件，将 root 与当前用户改为 zsh，并写入 Debian_GNOME_Init 同款 zshrc（已内嵌）
# --undo：还原 shell 与 .zshrc；不卸载 apt 包
# 用法: sudo ./setup-zsh.sh [--apply|--undo|--status]
# 模板来源: Debian_GNOME_Init/2/zshrc.src
set -euo pipefail

NAME="setup-zsh"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root/sudo 运行"
command -v apt-get >/dev/null 2>&1 || die "仅支持 apt 系发行版"

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  CURRENT_USER="$SUDO_USER"
else
  CURRENT_USER="root"
fi

# 内嵌自 Debian_GNOME_Init/2/zshrc.src（占位符 【$CURRENT_USER】）
emit_zshrc_template() {
  cat <<'ZSHRC_TEMPLATE_EOF'
# 【$CURRENT_USER】
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

# Git #
# 基础
# alias gst='git status'
# alias gss='git status --short'
alias gsb='git status --short --branch'

# add / commit
# alias ga='git add'
# alias gaa='git add --all'
# alias gapa='git add --patch'
# alias gc='git commit'
# alias gcm='git commit -m'
# alias gca='git commit --amend'
# 拉取代码
# 配置GPG:  git config --global user.signingkey XXX 和 git config --global commit.gpgsign true 确保你的 Git 提交邮箱和这个 key 的 uid 邮箱一致（很重要）
alias gplb='git pull --rebase --autostash && git branch -vv'
alias gcur='git branch --show-current'
# add all + commit with auto message (no sign)
gitac() {
  git add -A || return
  git commit -m "update —— ($(date '+%Y-%m-%d %H:%M:%S'))"
}
# add all + commit with auto message (GPG sign)
gitacs() {
  git add -A || return
  git commit -S -m "update —— ($(date '+%Y-%m-%d %H:%M:%S'))"
}
# add all + commit with custom message (no sign)
gitam() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: gitam \"commit message\""
    return 1
  fi
  git add -A || return
  git commit -m "$*"
}
# add all + commit with custom message (GPG sign)
gitams() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: gitams \"commit message\""
    return 1
  fi
  git add -A || return
  git commit -S -m "$*"
}

# 快速查看某个文件（或目录）在整个仓库历史中出现在哪些提交里
gitFindFileHistory() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: gitfindhistory <file-or-dir>"
    return 1
  fi
  git log --all --oneline -- "$@"
}
# git切换分支(main dev)
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

# diff / log
# 查看已经 add（暂存区）的改动
alias gds='git diff --staged'
# 用一行一条的方式查看提交历史（含分支/标签）
alias gl='git log --oneline --decorate'
# 以图形方式查看提交历史和分支走向
alias glog='git log --oneline --decorate --graph'

# branch / checkout / switch
# 查看 / 管理本地分支
# alias gb='git branch'
# 查看所有分支（本地 + 远程）
# alias gba='git branch -a'
# 切换分支 / 恢复文件（旧命令）
# alias gco='git checkout'
# 新建并切换到一个分支
# alias gcb='git checkout -b'
# 切换分支（新推荐命令）
# alias gsw='git switch'
# 新建并切换到一个分支（新推荐命令）
alias gswc='git switch -c'

# pull / push（不带 force）
# alias gl='git pull'
# alias gp='git push'
alias gpv='git push --verbose'

# rebase / merge
# alias grb='git rebase'
# alias grbi='git rebase -i'
# alias gm='git merge'
# alias gma='git merge --abort'

# stash
# alias gsta='git stash'
# alias gstp='git stash pop'
# alias gstl='git stash list'
# alias gstd='git stash drop'

# reset（非 hard）
# alias grs='git restore'
# alias grst='git restore --staged'

# HARD PULL: make local EXACTLY match remote (1:1)
# Usage:
#   githardpull                 # origin + current branch (or upstream if set)
#   githardpull upstream        # upstream + current branch
#   githardpull origin main     # origin/main
githardpull() {
  local remote="${1:-origin}"
  local branch="${2:-}"

  # Must be inside a git repo
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository."; return 1; }

  # Determine branch
  if [[ -z "$branch" ]]; then
    branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"
    if [[ -z "$branch" ]]; then
      # Detached HEAD fallback: try upstream
      local up
      up="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)"
      if [[ -n "$up" ]]; then
        remote="${up%%/*}"
        branch="${up#*/}"
      else
        echo "Detached HEAD and no upstream configured. Use: githardpull <remote> <branch>"
        return 1
      fi
    fi
  fi

  echo "This will make LOCAL exactly match REMOTE:"
  echo "  LOCAL  : $(git rev-parse --show-toplevel)"
  echo "  TARGET : ${remote}/${branch}"
  echo "It will DISCARD:"
  echo "  - uncommitted changes"
  echo "  - staged changes"
  echo "  - local commits not on ${remote}/${branch}"
  echo
  echo -n "Type: RESET-LOCAL to continue: "
  local confirm
  read -r confirm
  [[ "$confirm" == "RESET-LOCAL" ]] || { echo "Cancelled."; return 1; }

  git fetch --prune "$remote" || return 1
  git reset --hard "${remote}/${branch}" || return 1
  git clean -df || return 1
  echo "Done. Local is now identical to ${remote}/${branch}."
}

# HARD PUSH: make remote EXACTLY match local (1:1)
# Usage:
#   githardpush                 # origin + current branch
#   githardpush upstream        # upstream + current branch
#   githardpush origin main     # push current HEAD to origin/main (force)
githardpush() {
  local remote="${1:-origin}"
  local branch="${2:-}"

  git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository."; return 1; }

  # Determine current local branch
  local local_branch
  local_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"
  if [[ -z "$local_branch" ]]; then
    echo "Detached HEAD. Checkout a branch first (or specify remote branch explicitly)."
    return 1
  fi

  # Default target branch = local branch
  [[ -z "$branch" ]] && branch="$local_branch"

  # Refuse if working tree dirty (optional but safer for “restore” workflows)
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree or index has changes. Commit/stash or discard before hard-push."
    echo "If you REALLY want to proceed, clean it first or commit it."
    return 1
  fi

  echo "This will make REMOTE exactly match LOCAL:"
  echo "  LOCAL  : ${local_branch} @ $(git rev-parse --short HEAD)"
  echo "  REMOTE : ${remote}/${branch}"
  echo
  echo "WARNING: This can OVERWRITE remote history (other people's commits)."
  echo -n "Type: RESET-REMOTE to continue: "
  local confirm
  read -r confirm
  [[ "$confirm" == "RESET-REMOTE" ]] || { echo "Cancelled."; return 1; }

  git fetch --prune "$remote" || return 1

  # Use --force-with-lease for safety: force, but only if remote hasn't moved unexpectedly.
  # If you truly want unconditional overwrite, replace with: --force
  git push --force-with-lease "$remote" "HEAD:refs/heads/${branch}" || return 1

  echo "Done. Remote ${remote}/${branch} now matches local HEAD."
}

## conda
alias cna='conda activate'
alias cnde='conda deactivate'
# conda env list
alias cncur='conda info --envs'
# alias cnab='conda activate base'
# alias cncf='conda env create -f'
# alias cncn='conda create -y -n'
# alias cnconf='conda config'
# alias cncp='conda create -y -p'
# alias cncr='conda create -n'
# alias cncss='conda config --show-source'
# alias cnel='conda env list'
# alias cni='conda install'
# alias cniy='conda install -y'
# alias cnl='conda list'
# alias cnle='conda list --export'
# alias cnles='conda list --explicit > spec-file.txt'
# alias cnr='conda remove'
# alias cnrn='conda remove -y --all -n'
# alias cnrp='conda remove -y --all -p'
# alias cnry='conda remove -y'
# alias cnsr='conda search'
# alias cnu='conda update'
# alias cnua='conda update --all'
# alias cnuc='conda update conda'

# SSH
alias ssh-key-install='ssh-copy-id -i /home/【$CURRENT_USER】/.ssh/id_rsa.pub'
alias sshpwdconnect='pwdconnect(){sshpass -p "$1" ssh};pwdconnect'

# 代理
alias all_proxy_sock5='export ALL_PROXY=socks5://127.0.0.1:10808'

# 应用程序
# alias ffmpegss='ffmpegCutVideo(){ffmpeg -ss $3 -to $4 -i $1 -vcodec copy -acodec copy $2};ffmpegCutVideo'
# alias hcg='hexo clean && hexo g'
# alias p3='python3'

# 系统
alias ssa='sudo systemctl start'
alias sss='sudo systemctl status'
alias ssd='sudo systemctl stop'
alias ssf='sudo systemctl restart'
alias ssaa='sudo systemctl enable'
alias ssdd='sudo systemctl disable'
alias zshrc='vim /home/【$CURRENT_USER】/.zshrc'
alias szsh='source /home/【$CURRENT_USER】/.zshrc'
alias upgrade='sudo apt update && sudo apt upgrade'
alias lsx='ls -1 | tee >(xclip -selection clipboard)'
# alias grep='grep --color=always'

# ag搜文件内容
alias agc='ag -i --numbers --color --color-path "1;33" --color-line-number "1;32" --color-match "1;31"'
# 搜文件名（高亮关键字）
agf() {
    ag -g "$1" | GREP_COLORS='ms=1;31' grep --color=always -i "$1"
}
# Office 文档搜索（包装 nautilus lib 里的 searchDocx.sh）
OFFICE_LIB="$HOME/.local/share/nautilus/lib/Office"
_SEARCH_DOCX="$OFFICE_LIB/searchDocx.sh"

if [[ -x $_SEARCH_DOCX ]]; then
  # 搜 Word（.doc/.docx）
  agw() { "$_SEARCH_DOCX" "$@" }
  # Word + Excel
  agx() { "$_SEARCH_DOCX" -x "$@" }
  # 只搜 Excel
  agX() { "$_SEARCH_DOCX" -X "$@" }
fi

# alias duls='du -sh ./*'
alias duls='du -hd 0 ./* | sort -hr'
# alias dulsd='du -sh `la`'
alias dulsa='du -hd 0 ./* ./.??* | sort -hr'
# du：当前目录下一层（不含隐藏），按大小从大到小
# alias dusort='du -hd 1 ./* 2>/dev/null | sort -hr'
# alias dusort='du -hd 1 ./* | sort -hr'
# du：当前目录下一层（含隐藏，排除 . 和 ..），按大小从大到小
# alias dusorta='du -hd 1 ./* ./.??* 2>/dev/null | sort -hr'
alias dusorta='du -hd 1 ./* ./.??* | sort -hr'

# Debian 13: 递归监控当前目录文件变化（实时）依赖：inotify-tools（sudo apt install inotify-tools）
alias watchchg='inotifywait -m -r -e modify,create,delete,move --format "%T  %e  %w%f" --timefmt "%F %T" .'
# 只关心文件内容变更（不看 create/delete/move）
alias watchmod='inotifywait -m -r -e modify --format "%T  %e  %w%f" --timefmt "%F %T" .'
# 忽略一些常见大目录（node_modules/.git 等）
# alias watchchgfast='inotifywait -m -r -e modify,create,delete,move --exclude "(\.git|node_modules|\.cache|dist|build)/" --format "%T  %e  %w%f" --timefmt "%F %T" .'
# 只关心：新建 / 删除 / 移动（重命名也算 move）
alias watchfs='inotifywait -m -r -e create,delete,move --format "%T  %e  %w%f" --timefmt "%F %T" .'

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
    if [ -f "/home/【$CURRENT_USER】/.python_venv_activate" ];then
        source /home/【$CURRENT_USER】/.python_venv_activate
    fi
}

# 默认激活Python环境 
activatePythonVenv
# export PATH="$PATH:/usr/sbin"

# Created by `pipx` on 2023-06-30 12:10:31
# :/usr/games:/usr/local/games
export PATH="$PATH:/home/【$CURRENT_USER】/.local/bin"

ZSHRC_TEMPLATE_EOF
}

write_gnome_zshrc() {
  local user="$1" home="$2" zshrc_path="${2}/.zshrc"
  local tmp
  tmp="$(mktemp)"
  mkdir -p "${home}/.cache"
  emit_zshrc_template >"$tmp"
  sed -i "s|【\$CURRENT_USER】|${user}|g" "$tmp"
  if [[ "$user" == "root" ]]; then
    sed -i "s|/home/root|/root|g" "$tmp"
  fi
  install -m 0644 "$tmp" "$zshrc_path"
  chown "${user}:${user}" "$zshrc_path" 2>/dev/null || true
  rm -f "$tmp"
  log "已写入 GNOME 风格 .zshrc -> $zshrc_path"
}

backup_user() {
  local user="$1" home="$2"
  local udir="$BACKUP_DIR/users/${user}"
  mkdir -p "$udir"
  if [[ ! -f "$udir/shell.prev" ]]; then
    getent passwd "$user" | cut -d: -f7 >"$udir/shell.prev"
  fi
  if [[ -f "${home}/.zshrc" && ! -f "$udir/zshrc.bak" ]]; then
    cp -a "${home}/.zshrc" "$udir/zshrc.bak"
  elif [[ ! -f "${home}/.zshrc" && ! -f "$udir/zshrc.missing" ]]; then
    touch "$udir/zshrc.missing"
  fi
}

apply_user() {
  local user="$1" home="$2" zsh_path="$3"
  backup_user "$user" "$home"
  write_gnome_zshrc "$user" "$home"
  local cur
  cur="$(getent passwd "$user" | cut -d: -f7)"
  if [[ "$cur" != "$zsh_path" ]]; then
    usermod -s "$zsh_path" "$user"
    log "$user: shell $cur -> $zsh_path"
  else
    log "$user: 已是 zsh"
  fi
}

cmd_status() {
  echo "备份: $BACKUP_DIR"
  echo "目标用户: $CURRENT_USER (+ root)"
  echo "zshrc: 内嵌自 Debian_GNOME_Init/2/zshrc.src"
  command -v zsh >/dev/null && echo "zsh: $(command -v zsh)" || echo "zsh: 未安装"
  for u in root "$CURRENT_USER"; do
    echo "$u shell: $(getent passwd "$u" | cut -d: -f7)"
  done
}

cmd_apply() {
  export DEBIAN_FRONTEND=noninteractive
  mkdir -p "$BACKUP_DIR"
  log "安装 zsh 及插件..."
  apt-get update -y
  apt-get install -y zsh zsh-syntax-highlighting zsh-autosuggestions bash-completion silversearcher-ag || \
    apt-get install -y zsh zsh-syntax-highlighting zsh-autosuggestions bash-completion

  local zsh_path
  zsh_path="$(command -v zsh)"
  grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" >>/etc/shells

  apply_user root /root "$zsh_path"
  if [[ "$CURRENT_USER" != "root" ]]; then
    local home
    home="$(getent passwd "$CURRENT_USER" | cut -d: -f6)"
    apply_user "$CURRENT_USER" "$home" "$zsh_path"
  fi
  log "完成。重新登录或 exec zsh。--undo 不卸载软件包。"
  cmd_status
}

cmd_undo() {
  [[ -d "$BACKUP_DIR/users" ]] || die "无用户备份"
  for udir in "$BACKUP_DIR"/users/*; do
    [[ -d "$udir" ]] || continue
    local user home
    user="$(basename "$udir")"
    home="$(getent passwd "$user" | cut -d: -f6)"
    [[ -n "$home" ]] || continue
    if [[ -f "$udir/shell.prev" ]]; then
      usermod -s "$(cat "$udir/shell.prev")" "$user"
      log "$user: 已还原 shell"
    fi
    if [[ -f "$udir/zshrc.bak" ]]; then
      cp -a "$udir/zshrc.bak" "${home}/.zshrc"
      chown "${user}:${user}" "${home}/.zshrc" 2>/dev/null || true
      log "$user: 已还原 .zshrc"
    elif [[ -f "$udir/zshrc.missing" ]]; then
      rm -f "${home}/.zshrc"
      log "$user: 原先无 .zshrc，已删除"
    fi
  done
  cmd_status
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help) echo "用法: sudo $0 [--apply|--undo|--status]" ;;
  *) die "未知参数: $1" ;;
esac
