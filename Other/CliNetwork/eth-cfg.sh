#!/usr/bin/env bash
# 有线网络配置（修改连接配置文件，需要 root）
# 适用后端：NetworkManager / nmcli
#
# 用法：
#   ./eth-cfg.sh                                       进入交互菜单
#   ./eth-cfg.sh list                                  查看所有有线连接（含自动连接/优先级）
#   ./eth-cfg.sh static <网卡> <IP/前缀> [网关] [选项]  设置手动 IP
#       例: ./eth-cfg.sh static enp7s0 192.168.31.81/24 192.168.31.1 \
#                 --dns 8.8.8.8,114.114.114.114 --no-auto-dns -y
#       --dns <a,b>          DNS 列表
#       --no-auto-dns        填了 DNS 后，忽略路由器自动下发的 DNS（默认）
#       --auto-dns           同时使用自动下发 DNS
#       无网关时用 --no-gw，或者交互菜单操作
#   ./eth-cfg.sh dhcp <网卡> [--keep-dns] [-y]         切回 DHCP（默认清除手动 DNS）
#   ./eth-cfg.sh dns <网卡> <DNS列表|--auto|--clear>   只改 DNS
#       例: ./eth-cfg.sh dns enp7s0 8.8.8.8,1.1.1.1
#           ./eth-cfg.sh dns enp7s0 --auto             清除手动 DNS，恢复自动下发
#   ./eth-cfg.sh autoconnect <网卡> on|off [--priority N]
#   ./eth-cfg.sh priority <网卡> <N>                   优先级（越大越优先，-999~999）
#   ./eth-cfg.sh add <网卡> <名称> [dhcp|static IP/前缀 [网关]] [--dns a,b] [-y]
#   ./eth-cfg.sh delete <名称|UUID> [-y]               删除配置文件（忘记）
#   -h, --help
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=net_lib.sh
. "$SCRIPT_DIR/net_lib.sh"

PROG="$(basename "$0")"

usage() {
	sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# 选网卡并拿到其活动连接的 uuid 与名称；没有活动连接时提示新建
pick_active() {
	local given="${1:-}" dev con uuid
	dev=$(net_pick_device ethernet "$given") || return 1
	con=$(net_active_con "$dev")
	if [ -z "$con" ]; then
		net_err "网卡 $dev 当前没有任何活动连接配置"
		if tty -s && net_ask_yes "是否立即新建一个有线连接？" "y"; then
			do_add "$dev"
			return $?
		fi
		return 1
	fi
	uuid=$(nmcli -g connection.uuid con show "$con" 2>/dev/null)
	printf '%s\t%s\t%s\n' "$dev" "$uuid" "$con"
}

##################################### 动作 #########################################

do_list() {
	net_section "有线连接配置（按优先级降序）"
	net_list_profiles ethernet
}

do_static() {
	local dev cidr gw dns ignore="yes"
	dev=$(net_pick_device ethernet "${1:-}") || return 1
	cidr="${2:-}"
	gw="${3:-}"
	[[ "$gw" == --* ]] && gw=""
	# 参数解析（位置参数之后的选项）
	local dns_set=0
	while [ $# -gt 0 ]; do
		case "$1" in
			--dns) dns=$(net_norm_dns "$2"); dns_set=1; shift 2 ;;
			--no-auto-dns) ignore="yes"; shift ;;
			--auto-dns) ignore="no"; shift ;;
			--no-gw) gw=""; shift ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			*) shift ;;
		esac
	done
	[ -z "$cidr" ] && { net_err "缺少 IP/前缀，例：static enp7s0 192.168.1.10/24 192.168.1.1"; return 1; }
	net_valid_cidr "$cidr" || { net_err "IP/前缀不合法：$cidr"; return 1; }
	if [ -n "$gw" ]; then net_valid_ip4 "$gw" || { net_err "网关不合法：$gw"; return 1; }; fi
	[ $dns_set -eq 1 ] && { net_valid_dns_list "$dns" || return 1; }
	net_warn_cross_subnet "$cidr" "$gw"

	local row uuid con
	row=$(pick_active "$dev") || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	[ $dns_set -eq 0 ] && ignore="keep"
	net_apply_ipv4 "$uuid" "$dev" manual "$cidr" "$gw" "$dns" "$ignore"
}

do_dhcp() {
	local given dns_mode="clear" dev row uuid con
	while [ $# -gt 0 ]; do
		case "$1" in
			--keep-dns) dns_mode="keep"; shift ;;
			--clear-dns) dns_mode="clear"; shift ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			*) if [ -z "${given:-}" ]; then given="$1"; fi; shift ;;
		esac
	done
	row=$(pick_active "$given") || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	net_apply_ipv4 "$uuid" "$dev" dhcp "" "" "$([ "$dns_mode" = clear ] && echo __CLEAR__)" keep
}

do_dns() {
	local given dns="" ignore="yes"
	while [ $# -gt 0 ]; do
		case "$1" in
			--auto|--clear) dns="__CLEAR__"; ignore="no"; shift ;;
			--ignore-auto) ignore="$2"; shift 2 ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			--dns) dns=$(net_norm_dns "$2"); shift 2 ;;
			*) if [ -z "${given:-}" ]; then given="$1"; else dns=$(net_norm_dns "$1"); fi; shift ;;
		esac
	done
	if [ -z "$dns" ]; then
		net_err "用法：dns <网卡> 8.8.8.8,1.1.1.1 | --auto | --clear"
		return 1
	fi
	if [ "$dns" != "__CLEAR__" ]; then net_valid_dns_list "$dns" || return 1; fi
	local row dev uuid con
	row=$(pick_active "$given") || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	if [ "$dns" = "__CLEAR__" ]; then
		# 清空手动 DNS，并恢复接受自动下发
		net_apply_dns "$uuid" "$dev" "" "no"
	else
		net_apply_dns "$uuid" "$dev" "$dns" "$ignore"
	fi
}

do_autoconnect() {
	local given="" onoff="" pri=""
	while [ $# -gt 0 ]; do
		case "$1" in
			on|off|yes|no) onoff="$1"; shift ;;
			--priority) pri="$2"; shift 2 ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			*) if [ -z "${given:-}" ]; then given="$1"; fi; shift ;;
		esac
	done
	case "${onoff:-}" in
		yes) onoff=on ;;
		on|off) ;;
		*) net_err "用法：autoconnect <网卡> on|off [--priority N]"; return 1 ;;
	esac
	[ -n "$pri" ] && { net_valid_priority "$pri" || { net_err "优先级需为 -999~999 的整数"; return 1; }; }
	local row dev uuid con
	row=$(pick_active "$given") || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	net_apply_autoconnect "$uuid" "$dev" "$onoff" || return 1
	if [ -n "$pri" ]; then net_apply_priority "$uuid" "$pri"; fi
	return 0
}

do_priority() {
	local given="" pri=""
	while [ $# -gt 0 ]; do
		case "$1" in
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			*) if [ -z "${given:-}" ]; then given="$1"; elif [ -z "${pri:-}" ]; then pri="$1"; fi; shift ;;
		esac
	done
	net_valid_priority "${pri:-}" || { net_err "用法：priority <网卡> <-999~999 整数>"; return 1; }
	local row dev uuid con
	row=$(pick_active "$given") || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	net_apply_priority "$uuid" "$pri"
}

do_add() {
	local given="${1:-}" name="${2:-}" mode="dhcp" cidr="" gw="" dns="" ignore="yes" dns_set=0
	shift 2 2>/dev/null || true
	while [ $# -gt 0 ]; do
		case "$1" in
			dhcp) mode=dhcp; shift ;;
			static)
				mode=manual; cidr="${2:-}"
				# static 后跟一个可选网关；若第三段是 -- 选项则视为无网关
				if [ "$#" -ge 3 ] && [[ "${3:-}" != --* ]]; then
					gw="$3"; shift 3
				else
					shift 2
				fi
				;;
			--dns) dns=$(net_norm_dns "$2"); dns_set=1; shift 2 ;;
			--no-auto-dns) ignore="yes"; shift ;;
			--auto-dns) ignore="no"; shift ;;
			--no-gw) gw=""; shift ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			*) shift ;;
		esac
	done

	local dev
	dev=$(net_pick_device ethernet "$given") || return 1

	if [ -z "$name" ]; then
		net_require_tty
		local n=1
		while nmcli -g connection.uuid con show "Wired connection $n" >/dev/null 2>&1; do n=$((n+1)); done
		net_ask "新连接名称" "Wired connection $n"
		name="$NET_ASK"
	fi
	if nmcli -g connection.uuid con show "$name" >/dev/null 2>&1; then
		net_err "已存在同名连接：$name（可先 delete 或换名）"
		return 1
	fi

	if [ "$mode" = manual ]; then
		if [ -z "$cidr" ]; then
			net_require_tty
			net_ask_static "$dev"
			cidr="$NET_IP_CIDR"; gw="$NET_IP_GW"; dns="$NET_IP_DNS"; ignore="$NET_IP_IGNORE"
		fi
		net_valid_cidr "$cidr" || { net_err "IP/前缀不合法：$cidr"; return 1; }
		[ -n "$gw" ] && { net_valid_ip4 "$gw" || { net_err "网关不合法：$gw"; return 1; }; }
		[ $dns_set -eq 0 ] && [ -n "$dns" ] && dns_set=1
		[ -n "$dns" ] && net_valid_dns_list "$dns" || return 1
		net_warn_cross_subnet "$cidr" "$gw"
	fi

	# 预览
	net_hr
	printf '将在网卡 %s 上新建有线连接：%s（%s）\n' "$dev" "$name" \
		"$([ "$mode" = manual ] && echo "手动 $cidr" || echo DHCP)"
	[ -n "$gw" ] && printf '  网关: %s\n' "$gw"
	[ -n "$dns" ] && printf '  DNS : %s（忽略自动 DNS: %s）\n' "$dns" "$ignore"
	net_hr
	net_ssh_guard "$dev"
	net_confirm "确认创建并立即连接？" || return 1

	local -a args=(con add type ethernet ifname "$dev" con-name "$name")
	if [ "$mode" = manual ]; then
		args+=(ipv4.method manual ipv4.addresses "$cidr")
		if [ -n "$gw" ]; then args+=(ipv4.gateway "$gw"); fi
		if [ -n "$dns" ]; then
			args+=(ipv4.dns "$dns" ipv4.ignore-auto-dns "$ignore")
		fi
	fi
	net_run_root nmcli "${args[@]}" || { net_err "创建连接失败"; return 1; }
	net_run_root nmcli con up "$name" ifname "$dev"
}

do_delete() {
	local given=""
	while [ $# -gt 0 ]; do
		case "$1" in
			-y|--yes) NET_ASSUME_YES=1 ;;
			*) [ -z "$given" ] && given="$1" ;;
		esac
		shift
	done
	local row uuid name adev
	row=$(net_pick_profile ethernet "$given") || return 1
	IFS=$'\t' read -r uuid name <<<"$row"
	adev=$(net_active_dev_of "$name" ethernet)
	net_apply_delete "$uuid" "$adev"
}

##################################### 菜单 #########################################

menu_static() {
	local row dev uuid con
	row=$(pick_active) || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	net_ask_static "$dev" "$uuid"
	net_apply_ipv4 "$uuid" "$dev" manual "$NET_IP_CIDR" "$NET_IP_GW" "$NET_IP_DNS" "$NET_IP_IGNORE"
}

menu_dhcp() {
	local row dev uuid con
	row=$(pick_active) || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	if net_ask_yes "清除当前手动 DNS，完全使用 DHCP 下发？" "y"; then
		net_apply_ipv4 "$uuid" "$dev" dhcp "" "" __CLEAR__ keep
	else
		net_apply_ipv4 "$uuid" "$dev" dhcp "" "" "" keep
	fi
}

menu_dns() {
	local row dev uuid con ans
	row=$(pick_active) || return 1
	IFS=$'\t' read -r dev uuid con <<<"$row"
	net_ask "输入 DNS（逗号分隔）；输入 auto 恢复自动下发；直接回车取消" "$(net_con_val "$uuid" ipv4.dns)"
	ans="$NET_ASK"
	[ -z "$ans" ] && return 0
	if [ "$ans" = "auto" ]; then
		net_apply_dns "$uuid" "$dev" "" "no"
		return $?
	fi
	ans=$(net_norm_dns "$ans")
	net_valid_dns_list "$ans" || return 1
	local ignore="yes"
	net_ask_yes "忽略路由器自动下发的 DNS？" "y" || ignore="no"
	net_apply_dns "$uuid" "$dev" "$ans" "$ignore"
}

menu_autoconnect() {
	local row uuid name dev onoff
	row=$(net_pick_profile ethernet) || return 1
	IFS=$'\t' read -r uuid name <<<"$row"
	dev=$(net_active_dev_of "$name" ethernet)
	if [ "$(net_con_val "$uuid" connection.autoconnect)" = "yes" ]; then
		net_ask_yes "连接「$name」当前自动连接=是，是否关闭？" "n" && onoff=off || onoff=on
	else
		net_ask_yes "连接「$name」当前自动连接=否，是否开启？" "y" && onoff=on || onoff=off
	fi
	net_apply_autoconnect "$uuid" "$dev" "$onoff"
}

menu_priority() {
	local row uuid name cur
	row=$(net_pick_profile ethernet) || return 1
	IFS=$'\t' read -r uuid name <<<"$row"
	cur=$(net_con_val "$uuid" connection.autoconnect-priority)
	while true; do
		net_ask "「$name」的自动连接优先级（-999~999，越大越优先）" "$cur"
		if net_valid_priority "$NET_ASK"; then break; fi
		net_warn "请输入 -999~999 的整数"
	done
	net_apply_priority "$uuid" "$NET_ASK"
}

menu() {
	net_require_tty
	while true; do
		printf '\n======== 有线网络配置（修改配置，需 sudo）========\n'
		printf '  1) 查看所有有线连接（自动连接 / 优先级 / 在用）\n'
		printf '  2) 设置手动 IP（地址 / 网关 / DNS）\n'
		printf '  3) 切回 DHCP 自动获取\n'
		printf '  4) 只修改 DNS\n'
		printf '  5) 自动连接 开 / 关\n'
		printf '  6) 设置自动连接优先级\n'
		printf '  7) 新建有线连接（配置乱了可删后重建）\n'
		printf '  8) 删除有线连接（忘记）\n'
		printf '  q) 退出\n'
		local choice
		read -r -p "请选择（空回车退出）: " choice </dev/tty || true
		case "$choice" in
			1) do_list ;;
			2) menu_static ;;
			3) menu_dhcp ;;
			4) menu_dns ;;
			5) menu_autoconnect ;;
			6) menu_priority ;;
			7) do_add ;;
			8) do_delete ;;
			''|q|Q) exit 0 ;;
			*) net_warn "无效选择: $choice" ;;
		esac
		net_pause
	done
}

##################################### 入口 #########################################

main() {
	net_require_nm
	[ $# -eq 0 ] && { menu; exit 0; }
	local cmd="$1"; shift || true
	case "$cmd" in
		-h|--help) usage ;;
		list) do_list "$@" ;;
		static) do_static "$@" ;;
		dhcp) do_dhcp "$@" ;;
		dns) do_dns "$@" ;;
		autoconnect) do_autoconnect "$@" ;;
		priority) do_priority "$@" ;;
		add) do_add "$@" ;;
		delete) do_delete "$@" ;;
		*) net_err "未知参数: $cmd"; echo; usage; exit 1 ;;
	esac
}

main "$@"
