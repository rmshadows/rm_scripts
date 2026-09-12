#!/usr/bin/env bash
# 有线网络控制（只读 + 开关，不修改任何配置文件）
# 适用后端：NetworkManager / nmcli
# 用法：
#   ./eth-ctrl.sh                    进入交互菜单
#   ./eth-ctrl.sh status [网卡]       查看网卡状态详情
#   ./eth-ctrl.sh up [网卡]           连接/启用网卡
#   ./eth-ctrl.sh down [网卡]         断开网卡（不删配置，自动连接仍会触发）
#   ./eth-ctrl.sh reconnect [网卡]    断开后重新激活当前连接
#   ./eth-ctrl.sh reapply [网卡]      续租 DHCP / 让配置即时生效
#   ./eth-ctrl.sh test [网卡]         连通性测试（网关/外网/DNS）
#   -h, --help                       显示帮助
# 注意：up/down/reconnect/reapply 需要 root（自动 sudo）；status/test 不需要。
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=net_lib.sh
. "$SCRIPT_DIR/net_lib.sh"

PROG="$(basename "$0")"

usage() {
	sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

##################################### 动作 #########################################

do_status() {
	local dev
	dev=$(net_pick_device ethernet "${1:-}") || return 1
	net_show_status "$dev" ethernet
}

do_up() {
	local dev con
	dev=$(net_pick_device ethernet "${1:-}") || return 1
	con=$(net_active_con "$dev")
	net_ssh_guard "$dev"
	if [ -n "$con" ]; then
		net_run_root nmcli con up "$con" ifname "$dev"
	else
		net_run_root nmcli dev connect "$dev"
	fi
}

do_down() {
	local dev
	dev=$(net_pick_device ethernet "${1:-}") || return 1
	net_warn "断开后若存在自动连接配置，NetworkManager 可能自动重连"
	net_ssh_guard "$dev"
	net_confirm "确认断开网卡 $dev？" || return 1
	net_run_root nmcli dev disconnect "$dev"
}

do_reconnect() {
	local dev con
	dev=$(net_pick_device ethernet "${1:-}") || return 1
	con=$(net_active_con "$dev")
	net_ssh_guard "$dev"
	net_confirm "确认重连网卡 $dev？（会短暂断网）" || return 1
	net_run_root nmcli dev disconnect "$dev" >/dev/null 2>&1 || true
	if [ -n "$con" ]; then
		net_run_root nmcli con up "$con" ifname "$dev"
	else
		net_run_root nmcli dev connect "$dev"
	fi
}

do_reapply() {
	local dev con
	dev=$(net_pick_device ethernet "${1:-}") || return 1
	con=$(net_active_con "$dev")
	if [ -z "$con" ]; then
		net_err "网卡 $dev 当前没有活动连接，无法续租/生效"
		return 1
	fi
	net_run_root nmcli -w 12 dev reapply "$dev" || {
		net_warn "reapply 失败，尝试重新激活连接…"
		net_ssh_guard "$dev"
		net_run_root nmcli con up "$con" ifname "$dev"
	}
}

do_test() {
	local dev
	dev=$(net_pick_device ethernet "${1:-}") || return 1
	net_connectivity_test "$dev"
}

##################################### 菜单 #########################################

menu() {
	net_require_tty
	while true; do
		printf '\n======== 有线网络控制（不修改配置）========\n'
		printf '  1) 网卡状态详情\n'
		printf '  2) 连接 / 启用\n'
		printf '  3) 断开\n'
		printf '  4) 重新连接\n'
		printf '  5) 续租 DHCP / 配置即时生效\n'
		printf '  6) 连通性测试\n'
		printf '  q) 退出\n'
		local choice
		read -r -p "请选择（空回车退出）: " choice </dev/tty || true
		case "$choice" in
			1) do_status ;;
			2) do_up ;;
			3) do_down ;;
			4) do_reconnect ;;
			5) do_reapply ;;
			6) do_test ;;
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
	case "${1:-}" in
		-h|--help) usage ;;
		status)    shift; do_status "$@" ;;
		up)        shift; do_up "$@" ;;
		down)      shift; do_down "$@" ;;
		reconnect) shift; do_reconnect "$@" ;;
		reapply)   shift; do_reapply "$@" ;;
		test)      shift; do_test "$@" ;;
		*) net_err "未知参数: $1"; echo; usage; exit 1 ;;
	esac
}

main "$@"
