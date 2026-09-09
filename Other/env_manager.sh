#!/usr/bin/env bash
# 像 Windows 那样编辑环境变量：用户 / 系统 分开，查看、增减、改 PATH。
# 用法： ./env_manager.sh
# 改系统变量需要 sudo。新开终端或重新登录后生效。
set -u

PROG="$(basename "$0")"

usage() {
	cat <<EOF
用法: $PROG
      $PROG -h | --help

用户变量: ~/.config/env-manager/user.env
用户 PATH: ~/.config/env-manager/user.path（越靠前越优先）
系统变量: /etc/env-manager/system.env（并写入 /etc/environment 标记段，供 PAM）
系统 PATH: /etc/env-manager/system.path

登录挂钩装在 ~/.profile ~/.bashrc ~/.zprofile ~/.zshrc 以及 /etc/profile.d/。
EOF
}

real_user() {
	if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
		echo "$SUDO_USER"
	else
		id -un
	fi
}

real_home() {
	getent passwd "$(real_user)" | cut -d: -f6
}

USER_DIR=""
USER_ENV=""
USER_PATHF=""
USER_LOAD=""
SYS_DIR="/etc/env-manager"
SYS_ENV="$SYS_DIR/system.env"
SYS_PATHF="$SYS_DIR/system.path"
ETC_ENV="/etc/environment"
MARK_B="# BEGIN env-manager"
MARK_E="# END env-manager"

init_paths() {
	USER_DIR="$(real_home)/.config/env-manager"
	USER_ENV="$USER_DIR/user.env"
	USER_PATHF="$USER_DIR/user.path"
	USER_LOAD="$USER_DIR/load.sh"
}

need_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

ensure_user_files() {
	install -d -m 0755 "$USER_DIR"
	[ -f "$USER_ENV" ] || : >"$USER_ENV"
	[ -f "$USER_PATHF" ] || : >"$USER_PATHF"
}

ensure_sys_files() {
	need_root install -d -m 0755 "$SYS_DIR"
	need_root bash -c "[ -f '$SYS_ENV' ] || : >'$SYS_ENV'"
	need_root bash -c "[ -f '$SYS_PATHF' ] || : >'$SYS_PATHF'"
}

write_user_load() {
	cat >"$USER_LOAD" <<'EOF'
# env-manager：由 env_manager.sh 生成，勿手改结构
_em_dir="${XDG_CONFIG_HOME:-$HOME/.config}/env-manager"
if [ -f "$_em_dir/user.env" ]; then
	set -a
	# shellcheck disable=SC1091
	. "$_em_dir/user.env"
	set +a
fi
if [ -f "$_em_dir/user.path" ]; then
	while IFS= read -r _em_p || [ -n "${_em_p:-}" ]; do
		[ -z "${_em_p:-}" ] && continue
		case "$_em_p" in \#*) continue ;; esac
		case ":$PATH:" in
		*":$_em_p:"*) ;;
		*) PATH="$_em_p:$PATH" ;;
		esac
	done <"$_em_dir/user.path"
	export PATH
fi
unset _em_dir _em_p
EOF
	chmod 0644 "$USER_LOAD"
}

# 在 rc 里插入一行 source（有标记则跳过）
hook_line() {
	local file="$1"
	local line="$2"
	local mark="# env-manager load"
	touch "$file"
	grep -qF "$mark" "$file" 2>/dev/null && return 0
	printf '\n%s\n%s\n' "$mark" "$line" >>"$file"
}

install_user_hooks() {
	write_user_load
	local home src
	home="$(real_home)"
	src="[ -f \"$USER_LOAD\" ] && . \"$USER_LOAD\""
	hook_line "$home/.profile" "$src"
	hook_line "$home/.bashrc" "$src"
	hook_line "$home/.zprofile" "$src"
	hook_line "$home/.zshrc" "$src"
	install -d -m 0755 "$home/.config/environment.d"
	# systemd 用户会话（GNOME）：KEY=VALUE，不支持 source
	if [ -f "$USER_ENV" ]; then
		grep -v '^[[:space:]]*#' "$USER_ENV" | grep -v '^[[:space:]]*$' >"$home/.config/environment.d/99-env-manager.conf" || : >"$home/.config/environment.d/99-env-manager.conf"
	fi
	echo "已挂钩用户登录脚本（profile / bashrc / zsh）。新开终端生效。"
}

write_sys_profiled() {
	need_root tee /etc/profile.d/99-env-manager.sh >/dev/null <<'EOF'
# env-manager
if [ -f /etc/env-manager/system.env ]; then
	set -a
	# shellcheck disable=SC1091
	. /etc/env-manager/system.env
	set +a
fi
if [ -f /etc/env-manager/system.path ]; then
	while IFS= read -r _em_p || [ -n "${_em_p:-}" ]; do
		[ -z "${_em_p:-}" ] && continue
		case "$_em_p" in \#*) continue ;; esac
		case ":$PATH:" in
		*":$_em_p:"*) ;;
		*) PATH="$_em_p:$PATH" ;;
		esac
	done </etc/env-manager/system.path
	export PATH
fi
unset _em_p
EOF
	need_root chmod 0644 /etc/profile.d/99-env-manager.sh
}

# 把 system.env 里「字面量」同步进 /etc/environment（PAM / 显示管理器）
sync_etc_environment() {
	local tmp body
	ensure_sys_files
	body="$(grep -v '^[[:space:]]*#' "$SYS_ENV" 2>/dev/null | grep -v '^[[:space:]]*$' | grep -v '\$' || true)"
	tmp="$(mktemp)"
	if [ -f "$ETC_ENV" ]; then
		awk -v b="$MARK_B" -v e="$MARK_E" '
			$0==b {skip=1; next}
			$0==e {skip=0; next}
			!skip {print}
		' "$ETC_ENV" >"$tmp"
	else
		: >"$tmp"
	fi
	{
		cat "$tmp"
		echo "$MARK_B"
		printf '%s\n' "$body"
		echo "$MARK_E"
	} | need_root tee "$ETC_ENV" >/dev/null
	rm -f "$tmp"
}

install_sys_hooks() {
	ensure_sys_files
	write_sys_profiled
	sync_etc_environment
	echo "已安装 /etc/profile.d/99-env-manager.sh 并同步 /etc/environment。重新登录后 PAM 会话也能看到系统变量。"
}

# nameref 删掉数组中第 idx 项（兼容 set -u）
_drop_at() {
	local -n _arr="$1"
	local idx="$2"
	local -a _keep=()
	local i
	for i in "${!_arr[@]}"; do
		[ "$i" -eq "$idx" ] && continue
		_keep+=("${_arr[$i]}")
	done
	_arr=()
	for i in "${!_keep[@]}"; do
		_arr+=("${_keep[$i]}")
	done
}

# ---------- 解析 KEY=VALUE ----------
ENV_KEYS=()
ENV_VALS=()

parse_env_file() {
	local file="$1" line k v
	ENV_KEYS=()
	ENV_VALS=()
	[ -f "$file" ] || return 0
	while IFS= read -r line || [ -n "$line" ]; do
		line="${line#"${line%%[![:space:]]*}"}"
		[ -z "$line" ] && continue
		[[ "$line" == \#* ]] && continue
		[[ "$line" == *"="* ]] || continue
		k="${line%%=*}"
		v="${line#*=}"
		k="${k%"${k##*[![:space:]]}"}"
		if [[ "$v" == \"*\" && "$v" == *\" ]]; then
			v="${v#\"}"
			v="${v%\"}"
		elif [[ "$v" == \'*\' && "$v" == *\' ]]; then
			v="${v#\'}"
			v="${v%\'}"
		fi
		ENV_KEYS+=("$k")
		ENV_VALS+=("$v")
	done <"$file"
}

format_assign() {
	local k="$1" v="$2"
	if [[ "$v" =~ ^[A-Za-z0-9_./:+@%-]*$ ]]; then
		printf '%s=%s\n' "$k" "$v"
	else
		v="${v//\'/\'\\\'\'}"
		printf '%s=%s\n' "$k" "'$v'"
	fi
}

save_env_file() {
	local dest="$1" as_root="${2:-0}"
	local i tmp
	tmp="$(mktemp)"
	{
		echo "# 由 env_manager.sh 管理"
		for i in "${!ENV_KEYS[@]}"; do
			format_assign "${ENV_KEYS[$i]}" "${ENV_VALS[$i]}"
		done
	} >"$tmp"
	if [ "$as_root" -eq 1 ]; then
		need_root install -m 0644 "$tmp" "$dest"
	else
		install -m 0644 "$tmp" "$dest"
	fi
	rm -f "$tmp"
}

print_vars() {
	local i
	if [ ${#ENV_KEYS[@]} -eq 0 ]; then
		echo "（没有由本脚本管理的变量）"
		return 1
	fi
	printf "  %-4s %-24s %s\n" "序号" "变量" "值"
	echo "----------------------------------------------"
	for i in "${!ENV_KEYS[@]}"; do
		printf "  %-4s %-24s %s\n" "$((i + 1))" "${ENV_KEYS[$i]}" "${ENV_VALS[$i]}"
	done
	return 0
}

pick_index() {
	local n=${#ENV_KEYS[@]} s
	[ "$n" -gt 0 ] || return 1
	read -r -p "序号 (1-$n，空回车取消): " s
	[ -n "${s:-}" ] || return 1
	[[ "$s" =~ ^[0-9]+$ ]] && [ "$s" -ge 1 ] && [ "$s" -le "$n" ] || {
		echo "序号无效。"
		return 1
	}
	REPLY=$((s - 1))
}

# ---------- PATH 行文件 ----------
PATH_LINES=()

load_path_file() {
	local file="$1" line
	PATH_LINES=()
	[ -f "$file" ] || return 0
	while IFS= read -r line || [ -n "$line" ]; do
		line="${line%"${line##*[![:space:]]}"}"
		[ -z "$line" ] && continue
		[[ "$line" == \#* ]] && continue
		PATH_LINES+=("$line")
	done <"$file"
}

save_path_file() {
	local dest="$1" as_root="${2:-0}"
	local i tmp
	tmp="$(mktemp)"
	{
		echo "# 每行一个目录，越靠前越优先"
		for i in "${!PATH_LINES[@]}"; do
			printf '%s\n' "${PATH_LINES[$i]}"
		done
	} >"$tmp"
	if [ "$as_root" -eq 1 ]; then
		need_root install -m 0644 "$tmp" "$dest"
	else
		install -m 0644 "$tmp" "$dest"
	fi
	rm -f "$tmp"
}

print_path() {
	local i
	if [ ${#PATH_LINES[@]} -eq 0 ]; then
		echo "（没有由本脚本管理的 PATH 目录）"
		return 1
	fi
	printf "  %-4s %s\n" "序号" "目录"
	echo "----------------------------------------------"
	for i in "${!PATH_LINES[@]}"; do
		printf "  %-4s %s\n" "$((i + 1))" "${PATH_LINES[$i]}"
	done
	return 0
}

swap_path() {
	local a="$1" b="$2" t
	t="${PATH_LINES[$a]}"
	PATH_LINES[$a]="${PATH_LINES[$b]}"
	PATH_LINES[$b]="$t"
}

# ---------- 补全变量名 ----------
ENV_COMPLETE_WORDS=""
_env_readline_complete() {
	local cur="${READLINE_LINE:-}"
	local -a matches=()
	local p m
	[ -n "$cur" ] || return
	mapfile -t matches < <(compgen -W "${ENV_COMPLETE_WORDS:-}" -- "$cur")
	[ ${#matches[@]} -gt 0 ] || return
	if [ ${#matches[@]} -eq 1 ]; then
		READLINE_LINE="${matches[0]}"
		READLINE_POINT=${#READLINE_LINE}
		return
	fi
	p="${matches[0]}"
	for m in "${matches[@]}"; do
		while [ -n "$p" ] && [[ "$m" != "$p"* ]]; do
			p="${p%?}"
		done
	done
	[ -n "$p" ] && READLINE_LINE="$p" && READLINE_POINT=${#READLINE_LINE}
	printf '\n%s\n' "${matches[*]}" >&2
}

# ---------- 菜单 ----------
add_or_edit_var() {
	local file="$1" as_root="$2" name value i
	parse_env_file "$file"
	ENV_COMPLETE_WORDS="${ENV_KEYS[*]:-}"
	bind -x '"\t": _env_readline_complete' 2>/dev/null || true
	read -e -p "变量名（已有则修改，Tab 补全）: " name
	bind '"\t": complete' 2>/dev/null || true
	[[ "${name:-}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
		echo "变量名不合法。"
		return 1
	}
	read -e -p "值: " value
	value="${value:-}"
	for i in "${!ENV_KEYS[@]}"; do
		if [ "${ENV_KEYS[$i]}" = "$name" ]; then
			ENV_VALS[$i]="$value"
			save_env_file "$file" "$as_root"
			echo "已更新 $name"
			return 0
		fi
	done
	ENV_KEYS+=("$name")
	ENV_VALS+=("$value")
	save_env_file "$file" "$as_root"
	echo "已添加 $name"
}

delete_var() {
	local file="$1" as_root="$2" idx i
	parse_env_file "$file"
	print_vars || return
	pick_index || return
	idx=$REPLY
	echo "将删除 ${ENV_KEYS[$idx]}=${ENV_VALS[$idx]}"
	read -r -p "确认? [y/N] " ans
	case "${ans:-}" in y | Y | yes | YES) ;; *) echo "已取消。" && return ;; esac
	_drop_at ENV_KEYS "$idx"
	_drop_at ENV_VALS "$idx"
	save_env_file "$file" "$as_root"
	echo "已删除。"
}

path_menu() {
	local file="$1" as_root="$2" c s idx
	while true; do
		echo
		echo "---- PATH（本脚本管理的目录，越靠前越优先）----"
		load_path_file "$file"
		print_path || true
		echo "1) 添加目录"
		echo "2) 删除（序号）"
		echo "3) 上移"
		echo "4) 下移"
		echo "5) 返回"
		read -r -p "选 [1-5]: " c
		load_path_file "$file"
		case "${c:-}" in
		1)
			read -e -p "目录（Tab 补全）: " s
			[ -n "${s:-}" ] || continue
			PATH_LINES+=("$s")
			save_path_file "$file" "$as_root"
			;;
		2)
			print_path || continue
			n=${#PATH_LINES[@]}
			read -r -p "删除序号 (1-$n): " s
			[[ "${s:-}" =~ ^[0-9]+$ ]] && [ "$s" -ge 1 ] && [ "$s" -le "$n" ] || continue
			idx=$((s - 1))
			_drop_at PATH_LINES "$idx"
			save_path_file "$file" "$as_root"
			;;
		3)
			print_path || continue
			n=${#PATH_LINES[@]}
			read -r -p "上移序号: " s
			[[ "${s:-}" =~ ^[0-9]+$ ]] && [ "$s" -ge 2 ] && [ "$s" -le "$n" ] || continue
			idx=$((s - 1))
			swap_path "$idx" "$((idx - 1))"
			save_path_file "$file" "$as_root"
			;;
		4)
			print_path || continue
			n=${#PATH_LINES[@]}
			read -r -p "下移序号: " s
			[[ "${s:-}" =~ ^[0-9]+$ ]] && [ "$s" -ge 1 ] && [ "$s" -lt "$n" ] || continue
			idx=$((s - 1))
			swap_path "$idx" "$((idx + 1))"
			save_path_file "$file" "$as_root"
			;;
		5) return ;;
		*) echo "无效选项。" ;;
		esac
	done
}

scope_menu() {
	local title="$1" envf="$2" pathf="$3" as_root="$4"
	local c
	while true; do
		echo
		echo "======== $title ========"
		echo "文件: $envf"
		echo "1) 查看变量"
		echo "2) 添加 / 修改变量"
		echo "3) 删除变量（选序号）"
		echo "4) 编辑 PATH"
		echo "5) 安装/刷新登录挂钩（让改动在新终端生效）"
		echo "6) 返回"
		read -r -p "选 [1-6]: " c
		case "${c:-}" in
		1)
			parse_env_file "$envf"
			print_vars || true
			echo
			load_path_file "$pathf"
			echo "PATH 附加："
			print_path || true
			;;
		2)
			add_or_edit_var "$envf" "$as_root"
			[ "$as_root" -eq 1 ] && sync_etc_environment
			install_user_hooks >/dev/null
			[ "$as_root" -eq 1 ] && write_sys_profiled
			;;
		3)
			delete_var "$envf" "$as_root"
			[ "$as_root" -eq 1 ] && sync_etc_environment
			;;
		4)
			path_menu "$pathf" "$as_root"
			;;
		5)
			if [ "$as_root" -eq 1 ]; then
				install_sys_hooks
			else
				install_user_hooks
			fi
			;;
		6) return ;;
		*) echo "无效选项。" ;;
		esac
	done
}

show_live() {
	echo "---- 当前进程环境（只读，含系统已导出的）----"
	printenv | sort | sed 's/=/\t/' | expand -t 28 | less -F -X || printenv | sort
}

main() {
	local c
	init_paths
	ensure_user_files
	echo "当前用户: $(real_user)  家目录: $(real_home)"
	echo "改系统变量需要 sudo。改完请新开终端（或重新登录）。"
	while true; do
		echo
		echo "======== 环境变量 ========"
		echo "1) 用户变量（$(real_user)）"
		echo "2) 系统变量（全体用户，需 sudo）"
		echo "3) 查看当前进程环境（只读）"
		echo "4) 退出"
		read -r -p "选 [1-4]: " c
		case "${c:-}" in
		1)
			ensure_user_files
			scope_menu "用户变量" "$USER_ENV" "$USER_PATHF" 0
			;;
		2)
			ensure_sys_files
			scope_menu "系统变量" "$SYS_ENV" "$SYS_PATHF" 1
			;;
		3) show_live ;;
		4) exit 0 ;;
		*) echo "无效选项。" ;;
		esac
	done
}

case "${1:-}" in
-h | --help)
	usage
	exit 0
	;;
esac

main
