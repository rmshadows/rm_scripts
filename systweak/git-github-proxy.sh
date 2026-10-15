#!/usr/bin/env bash
# GitHub SSH 代理：平时直连 github.com；某次失败时用本脚本走 SOCKS5。
# 不会改全局 ALL_PROXY，也不会把所有 GitHub 默认改成代理。
#
# 用法:
#   ./git-github-proxy.sh --apply              # 写入 ~/.ssh/config 别名 github-proxy
#   ./git-github-proxy.sh --undo               # 去掉本脚本写入的配置块
#   ./git-github-proxy.sh --status             # 看代理端口与 SSH 配置
#   ./git-github-proxy.sh test                 # ssh -T git@github-proxy
#   ./git-github-proxy.sh clone <仓库> [git参数...]
#   ./git-github-proxy.sh pull [git参数...]    # 当前仓库临时经代理 pull
#   ./git-github-proxy.sh fetch [git参数...]
#   ./git-github-proxy.sh set-url              # 永久把 origin 改成 github-proxy
#   ./git-github-proxy.sh unset-url            # origin 改回 github.com
#
# 环境变量:
#   GIT_SOCKS_PROXY=127.0.0.1:10808   # SOCKS5 地址（默认与本仓库 zshrc 一致）
#   SYSTWEAK_BACKUP=...               # 备份根目录
set -euo pipefail

NAME="git-github-proxy"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
SSH_CONFIG="${HOME}/.ssh/config"
MARKER_BEGIN="# BEGIN systweak-git-github-proxy"
MARKER_END="# END systweak-git-github-proxy"
HOST_ALIAS="github-proxy"
SOCKS="${GIT_SOCKS_PROXY:-127.0.0.1:10808}"

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

socks_host() { printf '%s\n' "${SOCKS%%:*}"; }
socks_port() { printf '%s\n' "${SOCKS##*:}"; }

ensure_backup_dir() {
	mkdir -p "$BACKUP_DIR"
}

find_nc() {
	local c
	for c in nc netcat; do
		if command -v "$c" >/dev/null 2>&1; then
			# OpenSSH ProxyCommand 需要能 socks5：netcat-openbsd 的 -x/-X
			if "$c" -h 2>&1 | grep -qE -- '-x |--proxy'; then
				command -v "$c"
				return 0
			fi
		fi
	done
	return 1
}

proxy_listening() {
	local host port
	host=$(socks_host)
	port=$(socks_port)
	if command -v nc >/dev/null 2>&1; then
		nc -z -w 2 "$host" "$port" >/dev/null 2>&1 && return 0
	fi
	# bash /dev/tcp 兜底
	timeout 2 bash -c "echo >/dev/tcp/${host}/${port}" >/dev/null 2>&1
}

require_proxy_up() {
	if proxy_listening; then
		return 0
	fi
	die "本机 SOCKS5 未监听 ${SOCKS}。先开代理软件，或设 GIT_SOCKS_PROXY=主机:端口"
}

require_nc() {
	local nc
	if nc=$(find_nc); then
		printf '%s\n' "$nc"
		return 0
	fi
	die "需要带 SOCKS5 的 nc（Debian: sudo apt install netcat-openbsd）"
}

config_has_block() {
	[[ -f "$SSH_CONFIG" ]] && grep -qF "$MARKER_BEGIN" "$SSH_CONFIG"
}

backup_ssh_config() {
	ensure_backup_dir
	if [[ -f "$SSH_CONFIG" && ! -f "$BACKUP_DIR/config.bak" ]]; then
		cp -a "$SSH_CONFIG" "$BACKUP_DIR/config.bak"
		log "已备份: $SSH_CONFIG -> $BACKUP_DIR/config.bak"
	elif [[ ! -f "$SSH_CONFIG" && ! -f "$BACKUP_DIR/config.was_missing" ]]; then
		: >"$BACKUP_DIR/config.was_missing"
		log "原先无 $SSH_CONFIG，已记录"
	fi
}

# 从已有 Host github.com 抄 IdentityFile / IdentitiesOnly，代理别名才能用同一把钥匙
github_com_key_lines() {
	[[ -f "$SSH_CONFIG" ]] || return 0
	awk '
		BEGIN { IGNORECASE=0 }
		/^[[:space:]]*Host[[:space:]]+/ {
			in_gh=0
			n=split($0, a, /[[:space:]]+/)
			for (i=2; i<=n; i++) if (a[i]=="github.com") in_gh=1
			next
		}
		in_gh && /^[[:space:]]*IdentityFile[[:space:]]+/ { print; next }
		in_gh && /^[[:space:]]*IdentitiesOnly[[:space:]]+/ { print; next }
		in_gh && /^[[:space:]]*CertificateFile[[:space:]]+/ { print; next }
	' "$SSH_CONFIG"
}

write_ssh_block() {
	local nc proxy_line key_lines
	nc=$(require_nc)
	proxy_line="ProxyCommand ${nc} -x ${SOCKS} -X 5 %h %p"

	mkdir -p "${HOME}/.ssh"
	chmod 700 "${HOME}/.ssh" 2>/dev/null || true
	[[ -f "$SSH_CONFIG" ]] || : >"$SSH_CONFIG"
	chmod 600 "$SSH_CONFIG" 2>/dev/null || true

	backup_ssh_config

	# 去掉旧块再写，便于改端口后重跑 --apply
	if config_has_block; then
		awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
			$0 == b { skip=1; next }
			$0 == e { skip=0; next }
			!skip { print }
		' "$SSH_CONFIG" >"${SSH_CONFIG}.systweak.tmp"
		mv "${SSH_CONFIG}.systweak.tmp" "$SSH_CONFIG"
		chmod 600 "$SSH_CONFIG" 2>/dev/null || true
	fi

	key_lines=$(github_com_key_lines || true)

	{
		echo
		echo "$MARKER_BEGIN"
		echo "# 平时仍用 git@github.com:... 直连。需要代理时用 git@${HOST_ALIAS}:..."
		echo "# SOCKS5=${SOCKS}  nc=${nc}"
		echo "Host ${HOST_ALIAS}"
		echo "  HostName ssh.github.com"
		echo "  Port 443"
		echo "  User git"
		echo "  ${proxy_line}"
		if [[ -n "$key_lines" ]]; then
			printf '%s\n' "$key_lines"
		fi
		echo "$MARKER_END"
	} >>"$SSH_CONFIG"

	log "已写入 Host ${HOST_ALIAS} -> ssh.github.com:443 via ${SOCKS}"
	if grep -qE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$SSH_CONFIG"; then
		log "已有 Host github.com，未改动（直连仍走你原来的配置）"
		if [[ -n "$key_lines" ]]; then
			log "已把 github.com 的密钥相关行同步到 ${HOST_ALIAS}"
		fi
	else
		warn "没有 Host github.com 块也没关系；默认 git@github.com 仍直连。"
	fi
}

remove_ssh_block() {
	[[ -f "$SSH_CONFIG" ]] || die "没有 $SSH_CONFIG"
	config_has_block || die "未找到本脚本配置块，无需 --undo"
	awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
		$0 == b { skip=1; next }
		$0 == e { skip=0; next }
		!skip { print }
	' "$SSH_CONFIG" >"${SSH_CONFIG}.systweak.tmp"
	mv "${SSH_CONFIG}.systweak.tmp" "$SSH_CONFIG"
	chmod 600 "$SSH_CONFIG" 2>/dev/null || true
	log "已从 $SSH_CONFIG 去掉 ${HOST_ALIAS} 配置块"
}

# 把各种仓库写法改成 git@github-proxy:owner/repo.git
to_proxy_url() {
	local in="$1" owner repo
	case "$in" in
	git@"${HOST_ALIAS}":*)
		printf '%s\n' "$in"
		return 0
		;;
	git@github.com:*)
		printf '%s\n' "git@${HOST_ALIAS}:${in#git@github.com:}"
		return 0
		;;
	ssh://git@github.com/*)
		printf '%s\n' "git@${HOST_ALIAS}:${in#ssh://git@github.com/}"
		return 0
		;;
	https://github.com/* | http://github.com/*)
		in="${in#https://github.com/}"
		in="${in#http://github.com/}"
		in="${in%.git}"
		printf 'git@%s:%s.git\n' "$HOST_ALIAS" "$in"
		return 0
		;;
	*/*)
		# owner/repo 或 owner/repo.git
		if [[ "$in" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]]; then
			in="${in%.git}"
			printf 'git@%s:%s.git\n' "$HOST_ALIAS" "$in"
			return 0
		fi
		;;
	esac
	die "无法识别仓库地址: $in（例: owner/repo 或 git@github.com:owner/repo.git）"
}

# github.com SSH/HTTPS -> 提取 owner/repo，再拼直连或代理
github_path_from_url() {
	local u="$1"
	case "$u" in
	git@github.com:* | git@"${HOST_ALIAS}":*)
		u="${u#*:}"
		;;
	ssh://git@github.com/*)
		u="${u#ssh://git@github.com/}"
		;;
	https://github.com/* | http://github.com/*)
		u="${u#https://github.com/}"
		u="${u#http://github.com/}"
		;;
	*)
		return 1
		;;
	esac
	u="${u%.git}"
	printf '%s\n' "$u"
}

ensure_ssh_ready() {
	config_has_block || {
		warn "尚未写入 SSH 配置，先执行 --apply"
		write_ssh_block
	}
	require_proxy_up
	require_nc >/dev/null
}

cmd_status() {
	local nc=""
	echo "SOCKS5:     $SOCKS"
	if proxy_listening; then
		echo "代理端口:   在听"
	else
		echo "代理端口:   未监听（开代理软件后再用 clone/pull）"
	fi
	if nc=$(find_nc 2>/dev/null); then
		echo "nc:         $nc（支持 SOCKS5）"
	else
		echo "nc:         未找到可用的 netcat-openbsd"
	fi
	echo "SSH 配置:   $SSH_CONFIG"
	if config_has_block; then
		echo "github-proxy: 已写入"
		sed -n "/${MARKER_BEGIN}/,/${MARKER_END}/p" "$SSH_CONFIG" | sed 's/^/  /'
	else
		echo "github-proxy: 未写入（先 --apply）"
	fi
	if [[ -d .git ]]; then
		echo "当前仓库 origin: $(git remote get-url origin 2>/dev/null || echo 无)"
	fi
}

cmd_apply() {
	write_ssh_block
	cmd_status
	echo
	log "平时继续: git clone git@github.com:owner/repo.git"
	log "失败时:   $(basename "$0") clone owner/repo"
}

cmd_undo() {
	remove_ssh_block
}

cmd_test() {
	ensure_ssh_ready
	log "测试: ssh -T git@${HOST_ALIAS}"
	# GitHub 认证成功也会返回 1，不算脚本失败
	ssh -o BatchMode=yes -T "git@${HOST_ALIAS}" || true
}

cmd_clone() {
	[[ $# -ge 1 ]] || die "用法: $(basename "$0") clone <owner/repo|git@github.com:...> [git clone 参数...]"
	local url="$1"
	shift
	ensure_ssh_ready
	url=$(to_proxy_url "$url")
	log "经代理克隆: $url"
	git clone "$@" "$url"
}

# 当前仓库：把 origin 临时改成代理 URL 跑一条 git 子命令
cmd_git_via_proxy() {
	local sub="$1"
	shift
	[[ -d .git ]] || die "当前目录不是 git 仓库"
	ensure_ssh_ready
	local origin path proxy_url
	origin=$(git remote get-url origin 2>/dev/null) || die "没有 origin"
	path=$(github_path_from_url "$origin") || die "origin 不是 GitHub 地址: $origin"
	proxy_url="git@${HOST_ALIAS}:${path}.git"
	log "临时经代理 ${sub}: $proxy_url"
	git -c "remote.origin.url=${proxy_url}" "$sub" "$@"
}

cmd_set_url() {
	[[ -d .git ]] || die "当前目录不是 git 仓库"
	ensure_ssh_ready
	local origin path
	origin=$(git remote get-url origin 2>/dev/null) || die "没有 origin"
	path=$(github_path_from_url "$origin") || die "origin 不是 GitHub 地址: $origin"
	git remote set-url origin "git@${HOST_ALIAS}:${path}.git"
	log "origin 已改为: $(git remote get-url origin)"
	warn "以后该仓库会一直走代理。恢复: $(basename "$0") unset-url"
}

cmd_unset_url() {
	[[ -d .git ]] || die "当前目录不是 git 仓库"
	local origin path
	origin=$(git remote get-url origin 2>/dev/null) || die "没有 origin"
	path=$(github_path_from_url "$origin") || die "origin 不是 GitHub 地址: $origin"
	git remote set-url origin "git@github.com:${path}.git"
	log "origin 已改回: $(git remote get-url origin)"
}

usage() {
	cat <<EOF
用法: $(basename "$0") <命令>

配置（一次即可）:
  --apply     写入 ~/.ssh/config 的 Host github-proxy（默认 github.com 仍直连）
  --undo      去掉本脚本写入的配置块
  --status    看 SOCKS5 端口与 SSH 配置

失败时走代理（平时不用）:
  test                          ssh -T 测代理通道
  clone <仓库> [参数...]        经代理克隆
  pull [参数...]                当前仓库临时经代理 pull（不改 origin）
  fetch [参数...]               当前仓库临时经代理 fetch
  set-url                       永久把 origin 改成 github-proxy
  unset-url                     origin 改回 git@github.com:...

例子:
  $(basename "$0") --apply
  $(basename "$0") clone rmshadows/rm_scripts
  $(basename "$0") clone git@github.com:rmshadows/rm_scripts.git --depth=1 --single-branch
  cd 某仓库 && $(basename "$0") pull

SOCKS5 默认 ${SOCKS}，可改: GIT_SOCKS_PROXY=127.0.0.1:端口
EOF
}

main() {
	local cmd="${1:---help}"
	[[ $# -gt 0 ]] && shift || true
	case "$cmd" in
	--apply | apply) cmd_apply ;;
	--undo | undo) cmd_undo ;;
	--status | status) cmd_status ;;
	-h | --help | help) usage ;;
	test) cmd_test ;;
	clone) cmd_clone "$@" ;;
	pull) cmd_git_via_proxy pull "$@" ;;
	fetch) cmd_git_via_proxy fetch "$@" ;;
	set-url) cmd_set_url ;;
	unset-url) cmd_unset_url ;;
	*) die "未知参数: $cmd（见 --help）" ;;
	esac
}

main "$@"
