#!/usr/bin/env bash
# 无线网络控制（只读 + 开关，不修改任何配置文件）
# 适用后端：NetworkManager / nmcli
#
# 用法：
#   ./wifi-ctrl.sh                     进入交互菜单
#   ./wifi-ctrl.sh status [网卡]        查看无线网卡状态
#   ./wifi-ctrl.sh radio on|off        开关 WiFi 无线电（飞行模式相关）
#   ./wifi-ctrl.sh scan [网卡]          扫描并列出附近 WiFi（标注已保存/在用）
#   ./wifi-ctrl.sh up [网卡] [SSID]     连接已保存的 WiFi
#   ./wifi-ctrl.sh down [网卡]          断开（不删配置）
#   ./wifi-ctrl.sh reconnect [网卡]     断开后连回当前网络
#   ./wifi-ctrl.sh reapply [网卡]       续租 DHCP / 让已改的配置即时生效
#   ./wifi-ctrl.sh test [网卡]          连通性测试
#   -h, --help
# 注意：radio/up/down/reconnect 需要 root（自动 sudo）；status/scan 的读取不需要。
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=net_lib.sh
. "$SCRIPT_DIR/net_lib.sh"

PROG="$(basename "$0")"

usage() {
	sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

wifi_radio_state() {
	nmcli -t -f WIFI general 2>/dev/null
}

require_radio_on() {
	if [ "$(wifi_radio_state)" != "enabled" ]; then
		net_err "WiFi 无线电当前关闭，先执行：sudo $PROG radio on"
		return 1
	fi
}

##################################### 动作 #########################################

do_status() {
	local dev
	dev=$(net_pick_device wifi "${1:-}") || return 1
	net_show_status "$dev" wifi
}

do_radio() {
	local state="${1:-}"
	case "$state" in
		on|enable|enabled)
			net_run_root nmcli radio wifi on
			net_ok "WiFi 无线电已开启" ;;
		off|disable|disabled)
			net_warn "关闭无线电将断开所有无线网络"
			net_confirm "确认关闭 WiFi 无线电？" || return 1
			net_run_root nmcli radio wifi off
			net_ok "WiFi 无线电已关闭" ;;
		*) net_err "用法：radio on|off"; return 1 ;;
	esac
}

# 扫描并打印附近 WiFi（实现见 net_lib.sh，结果存 _NET_SCAN）
do_scan() {
	local given="${1:-}"
	local dev
	dev=$(net_pick_device wifi "$given") || return 1
	net_wifi_scan "$dev" "${2:-}"
}

do_up() {
	local given="${1:-}" ssid_name="${2:-}" dev uuid name
	dev=$(net_pick_device wifi "$given") || return 1
	require_radio_on || return 1
	# 指定了 SSID/名称：从已保存配置中解析
	if [ -n "$ssid_name" ]; then
		local row
		row=$(net_pick_profile wifi "$ssid_name" "$dev") || return 1
		IFS=$'\t' read -r uuid name <<<"$row"
	else
		# 未指定：展示已保存列表选择
		local row
		row=$(net_pick_profile wifi "" "$dev") || return 1
		IFS=$'\t' read -r uuid name <<<"$row"
	fi
	net_ssh_guard "$dev"
	net_confirm "连接 WiFi「$name」？" || return 1
	net_run_root nmcli con up uuid "$uuid" ifname "$dev"
}

do_down() {
	local dev
	dev=$(net_pick_device wifi "${1:-}") || return 1
	net_warn "断开后若该网络开了自动连接，NetworkManager 可能自动重连"
	net_ssh_guard "$dev"
	net_confirm "确认断开无线网卡 $dev？" || return 1
	net_run_root nmcli dev disconnect "$dev"
}

do_reconnect() {
	local dev con
	dev=$(net_pick_device wifi "${1:-}") || return 1
	require_radio_on || return 1
	con=$(net_active_con "$dev")
	[ -n "$con" ] || { net_err "$dev 当前没有活动的无线连接"; return 1; }
	net_ssh_guard "$dev"
	net_confirm "确认重连无线网卡 $dev？（会短暂断网）" || return 1
	net_run_root nmcli dev disconnect "$dev" >/dev/null 2>&1 || true
	net_run_root nmcli con up "$con" ifname "$dev"
}

do_reapply() {
	local dev con
	dev=$(net_pick_device wifi "${1:-}") || return 1
	con=$(net_active_con "$dev")
	[ -n "$con" ] || { net_err "$dev 当前没有活动连接，无法续租/生效"; return 1; }
	net_run_root nmcli -w 12 dev reapply "$dev" || {
		net_warn "reapply 失败，尝试重新激活连接…"
		net_ssh_guard "$dev"
		net_run_root nmcli con up "$con" ifname "$dev"
	}
}

do_test() {
	local dev
	dev=$(net_pick_device wifi "${1:-}") || return 1
	net_connectivity_test "$dev"
}

##################################### 菜单 #########################################

menu_scan_connect() {
	local dev
	dev=$(net_pick_device wifi) || return 0
	net_wifi_scan "$dev" || return 0
	[ "${#_NET_SCAN[@]}" -eq 0 ] && return 0
	local sel
	read -r -p "输入序号可直接连接【已保存】的网络（回车返回）: " sel </dev/tty || true
	[ -z "$sel" ] && return 0
	case "$sel" in ''|*[!0-9]*) net_warn "无效序号"; return 0 ;; esac
	if [ "$sel" -lt 1 ] || [ "$sel" -gt "${#_NET_SCAN[@]}" ]; then
		net_warn "序号超出范围"; return 0
	fi
	local ssid security bssid
	IFS=$'\t' read -r ssid security bssid <<<"${_NET_SCAN[$((sel-1))]}"
	if [ "$ssid" = "（隐藏网络）" ]; then
		net_warn "隐藏网络无法从扫描列表直接连接，请用 wifi-cfg.sh connect --hidden"
		return 0
	fi
	if ! nmcli -g 802-11-wireless.ssid con show 2>/dev/null | grep -qxF "$ssid"; then
		net_warn "「$ssid」尚未保存，连接新网络属于配置操作，请运行 ./wifi-cfg.sh connect"
		return 0
	fi
	local row uuid name
	row=$(net_pick_profile wifi "$ssid") || return 0
	IFS=$'\t' read -r uuid name <<<"$row"
	net_run_root nmcli con up uuid "$uuid" ifname "$dev"
}

menu() {
	net_require_tty
	while true; do
		printf '\n======== 无线网络控制（不修改配置）========\n'
		printf '  WiFi 无线电: %s\n' "$(wifi_radio_state)"
		printf '  1) 网卡状态详情\n'
		printf '  2) 开 / 关 WiFi 无线电\n'
		printf '  3) 扫描附近 WiFi（可直连已保存网络）\n'
		printf '  4) 连接已保存的 WiFi\n'
		printf '  5) 断开\n'
		printf '  6) 重新连接\n'
		printf '  7) 续租 DHCP / 配置即时生效\n'
		printf '  8) 连通性测试\n'
		printf '  q) 退出\n'
		local choice
		read -r -p "请选择（空回车退出）: " choice </dev/tty || true
		case "$choice" in
			1) do_status ;;
			2) if [ "$(wifi_radio_state)" = enabled ]; then do_radio off; else do_radio on; fi ;;
			3) menu_scan_connect ;;
			4) do_up ;;
			5) do_down ;;
			6) do_reconnect ;;
			7) do_reapply ;;
			8) do_test ;;
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
		radio)     shift; do_radio "$@" ;;
		scan)      shift; do_scan "$@" ;;
		up)        shift; do_up "$@" ;;
		down)      shift; do_down "$@" ;;
		reconnect) shift; do_reconnect "$@" ;;
		reapply)   shift; do_reapply "$@" ;;
		test)      shift; do_test "$@" ;;
		*) net_err "未知参数: $1"; echo; usage; exit 1 ;;
	esac
}

main "$@"
