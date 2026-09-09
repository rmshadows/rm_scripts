#!/usr/bin/env bash
# 管理 update-alternatives：查看、添加、改优先级、按序号删除/切换。
# 用法：
#   sudo ./alternatives_manager.sh              # 交互选组
#   sudo ./alternatives_manager.sh java         # 直接管理 java
#   ./alternatives_manager.sh --help
#
# 补全组名（写入 ~/.bashrc 后新开终端）：
#   source /path/to/alternatives_manager.sh --install-completion
set -u

PROG="$(basename "$0")"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"

usage() {
	cat <<EOF
用法: $PROG [组名]
      $PROG --install-completion   把组名补全写进 ~/.bashrc
      $PROG -h | --help

交互菜单：查看 / 添加 / 改优先级 / 按序号删除 / 切换当前项 / 自动模式。
选组名、填路径时都可以 Tab 补全。
EOF
}

need_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

alt_names() {
	update-alternatives --get-selections 2>/dev/null | awk '{print $1}' | sort -u
}

# 组已登记时读出主链接；否则空
alt_link() {
	local name="$1"
	update-alternatives --query "$name" 2>/dev/null | awk '/^Link:/{print $2; exit}'
}

alt_value() {
	local name="$1"
	update-alternatives --query "$name" 2>/dev/null | awk '/^Value:/{print $2; exit}'
}

# 打印候选项，写入并行数组 ALT_PATHS / ALT_PRIS；返回数量
load_alts() {
	local name="$1"
	ALT_PATHS=()
	ALT_PRIS=()
	local alt="" pri=""
	while IFS= read -r line || [ -n "$line" ]; do
		case "$line" in
		Alternative:*)
			alt="${line#Alternative: }"
			alt="${alt#"${alt%%[![:space:]]*}"}"
			;;
		Priority:*)
			pri="${line#Priority: }"
			pri="${pri#"${pri%%[![:space:]]*}"}"
			if [ -n "$alt" ]; then
				ALT_PATHS+=("$alt")
				ALT_PRIS+=("$pri")
				alt=""
			fi
			;;
		esac
	done < <(update-alternatives --query "$name" 2>/dev/null || true)
}

print_alts() {
	local name="$1"
	local current i mark
	current="$(alt_value "$name")"
	load_alts "$name"
	if [ ${#ALT_PATHS[@]} -eq 0 ]; then
		echo "组「$name」还没有候选项（或尚未登记）。"
		return 1
	fi
	printf "组 %s  主链接 %s  当前 %s\n" "$name" "$(alt_link "$name")" "${current:-?}"
	echo "----------------------------------------------"
	printf "  %-4s %-8s %s\n" "序号" "优先级" "路径"
	for i in "${!ALT_PATHS[@]}"; do
		mark=" "
		[ "${ALT_PATHS[$i]}" = "$current" ] && mark="*"
		printf "%s %-4s %-8s %s\n" "$mark" "$((i + 1))" "${ALT_PRIS[$i]}" "${ALT_PATHS[$i]}"
	done
	echo "----------------------------------------------"
	echo "* 表示当前正在使用"
	return 0
}

pick_index() {
	local prompt="$1"
	local n=${#ALT_PATHS[@]}
	local s
	[ "$n" -gt 0 ] || return 1
	read -r -p "$prompt (1-$n，空回车取消): " s
	[ -n "${s:-}" ] || return 1
	[[ "$s" =~ ^[0-9]+$ ]] || {
		echo "请输入数字。"
		return 1
	}
	if [ "$s" -lt 1 ] || [ "$s" -gt "$n" ]; then
		echo "序号超出范围。"
		return 1
	fi
	REPLY=$((s - 1))
}

show_current() {
	local name="$1"
	if ! print_alts "$name"; then
		return
	fi
	echo
	update-alternatives --display "$name" 2>/dev/null || true
}

add_alternative() {
	local name="$1"
	local link path priority
	link="$(alt_link "$name")"
	if [ -z "$link" ]; then
		read -e -i "/usr/bin/$name" -p "主链接（新组必须指定，一般是 /usr/bin/组名）: " link
		[ -n "${link:-}" ] || {
			echo "已取消。"
			return
		}
	else
		echo "已有主链接: $link"
	fi
	read -e -p "可执行文件完整路径（Tab 补全）: " path
	[ -n "${path:-}" ] || {
		echo "已取消。"
		return
	}
	if [ ! -e "$path" ]; then
		echo "路径不存在: $path"
		return 1
	fi
	read -r -p "优先级（数字越大越优先，默认 50）: " priority
	priority="${priority:-50}"
	[[ "$priority" =~ ^[0-9]+$ ]] || {
		echo "优先级必须是整数。"
		return 1
	}
	need_root update-alternatives --install "$link" "$name" "$path" "$priority"
	echo "已添加: $path  优先级 $priority"
}

change_priority() {
	local name="$1"
	local link idx path old pri
	print_alts "$name" || return
	link="$(alt_link "$name")"
	[ -n "$link" ] || return
	pick_index "改哪一项的优先级" || return
	idx=$REPLY
	path="${ALT_PATHS[$idx]}"
	old="${ALT_PRIS[$idx]}"
	read -r -p "新优先级（当前 $old）: " pri
	[[ "${pri:-}" =~ ^[0-9]+$ ]] || {
		echo "已取消或输入无效。"
		return
	}
	need_root update-alternatives --install "$link" "$name" "$path" "$pri"
	echo "已把 $path 的优先级改为 $pri"
}

remove_alternative() {
	local name="$1"
	local idx path
	print_alts "$name" || return
	pick_index "删除序号几" || return
	idx=$REPLY
	path="${ALT_PATHS[$idx]}"
	read -r -p "确认删除 $path ? [y/N] " ans
	case "${ans:-}" in
	y | Y | yes | YES) ;;
	*)
		echo "已取消。"
		return
		;;
	esac
	need_root update-alternatives --remove "$name" "$path"
	echo "已删除 $path"
}

set_current() {
	local name="$1"
	local idx path
	print_alts "$name" || return
	pick_index "切换到序号几" || return
	idx=$REPLY
	path="${ALT_PATHS[$idx]}"
	need_root update-alternatives --set "$name" "$path"
	echo "当前 $name → $path"
}

set_auto() {
	local name="$1"
	need_root update-alternatives --auto "$name"
	echo "已设为自动（选优先级最高的）。当前: $(alt_value "$name")"
}

# read -e 默认只补全文件名；选组时把 Tab 临时绑到组名列表
ALT_COMPLETE_WORDS=""
_alts_readline_complete() {
	local cur="${READLINE_LINE:-}"
	local -a matches=()
	local p m
	if [ -z "$cur" ]; then
		printf '\n先打几个字母或序号再 Tab。\n' >&2
		return
	fi
	mapfile -t matches < <(compgen -W "${ALT_COMPLETE_WORDS:-}" -- "$cur")
	if [ ${#matches[@]} -eq 0 ]; then
		return
	fi
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
	if [ -n "$p" ] && [ "$p" != "$cur" ]; then
		READLINE_LINE="$p"
		READLINE_POINT=${#READLINE_LINE}
	fi
	printf '\n' >&2
	printf '%s  ' "${matches[@]}" >&2
	printf '\n' >&2
}

# 选中的组名放 SOFTWARE
pick_software() {
	local -a names=()
	local i n input
	SOFTWARE=""
	mapfile -t names < <(alt_names)
	n=${#names[@]}
	if [ "$n" -gt 0 ]; then
		echo "已登记的 alternatives 组（Tab 可补全名字或序号）："
		for i in "${!names[@]}"; do
			printf "  %3d) %s\n" "$((i + 1))" "${names[$i]}"
		done
		echo
	fi
	ALT_COMPLETE_WORDS="$(printf '%s ' "${names[@]}")"
	for i in "${!names[@]}"; do
		ALT_COMPLETE_WORDS+="$((i + 1)) "
	done
	bind -x '"\t": _alts_readline_complete' 2>/dev/null || true
	read -e -p "输入序号，或组名（如 java / editor；新组直接打名字，Tab 补全）: " input
	bind '"\t": complete' 2>/dev/null || true
	input="${input:-}"
	[ -n "$input" ] || return 1
	if [[ "$input" =~ ^[0-9]+$ ]] && [ "$n" -gt 0 ]; then
		if [ "$input" -ge 1 ] && [ "$input" -le "$n" ]; then
			SOFTWARE="${names[$((input - 1))]}"
			return 0
		fi
		echo "序号超出范围。"
		return 1
	fi
	SOFTWARE="$input"
}

install_completion() {
	local rc="${HOME}/.bashrc"
	local marker="# alternatives_manager completion"
	local block
	block=$(
		cat <<EOF
$marker
_alts_mgr_complete() {
	local cur
	cur="\${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=( \$(compgen -W "\$(update-alternatives --get-selections 2>/dev/null | awk '{print \$1}') --help --install-completion" -- "\$cur") )
}
complete -F _alts_mgr_complete alternatives_manager.sh
complete -F _alts_mgr_complete $(printf '%q' "$SCRIPT_PATH")
EOF
	)
	if [ -f "$rc" ] && grep -qF "$marker" "$rc"; then
		echo "已经装过补全（$rc）。新开一个终端后，对脚本名 Tab 即可补全组名。"
		return 0
	fi
	printf '\n%s\n' "$block" >>"$rc"
	echo "已写入 $rc。执行: source $rc   或新开终端。"
	echo "之后: ./alternatives_manager.sh jav<Tab>"
}

menu_for() {
	local software="$1"
	local choice
	while true; do
		echo
		echo "======== $software ========"
		echo "1) 查看"
		echo "2) 添加（可设优先级，路径 Tab 补全）"
		echo "3) 改优先级"
		echo "4) 删除（选序号）"
		echo "5) 切换当前使用（选序号）"
		echo "6) 恢复自动（最高优先级）"
		echo "7) 换一组"
		echo "8) 退出"
		read -r -p "选 [1-8]: " choice
		case "${choice:-}" in
		1) show_current "$software" ;;
		2) add_alternative "$software" ;;
		3) change_priority "$software" ;;
		4) remove_alternative "$software" ;;
		5) set_current "$software" ;;
		6) set_auto "$software" ;;
		7) return 2 ;;
		8) return 0 ;;
		*) echo "无效选项。" ;;
		esac
	done
}

main() {
	local software rc
	if [ "$(id -u)" -ne 0 ]; then
		if ! sudo -n true 2>/dev/null && ! sudo -v; then
			echo "改 alternatives 需要 sudo。"
			exit 1
		fi
	fi
	if [ -n "${1:-}" ]; then
		software="$1"
	else
		pick_software || exit 1
		software="$SOFTWARE"
	fi
	while true; do
		menu_for "$software"
		rc=$?
		[ "$rc" -eq 0 ] && break
		pick_software || break
		software="$SOFTWARE"
	done
}

case "${1:-}" in
-h | --help)
	usage
	exit 0
	;;
--install-completion)
	install_completion
	exit 0
	;;
esac

main "${1:-}"
