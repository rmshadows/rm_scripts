#!/usr/bin/env bash
# 无线网络配置（连接新 WiFi、改密码、手动 IP、自动连接、忘记网络；需要 root）
# 适用后端：NetworkManager / nmcli
#
# 用法：
#   ./wifi-cfg.sh                                       进入交互菜单
#   ./wifi-cfg.sh list                                  已保存 WiFi（含 BSSID/自动连接/优先级）
#   ./wifi-cfg.sh connect [网卡] <SSID> [密码] [选项]   连接新 WiFi
#       示例: ./wifi-cfg.sh connect wlx08107bbbe420 DXTP2 'pass123' --no-auto-dns
#             ./wifi-cfg.sh connect DXTP2 --open --hidden
#             ./wifi-cfg.sh connect DXTP2 mypass --static 192.168.31.81/24 --gw 192.168.31.1
#       --hidden           隐藏网络（不广播 SSID）
#       --open             无密码开放网络
#       --wep              WEP 加密（老路由器）
#       --static <IP/前缀> 连接同时配手动 IP
#       --gw <网关>        手动 IP 的网关
#       --dns <a,b>        手动 IP 的 DNS
#       --no-auto-dns      填了 DNS 后忽略自动下发 DNS（默认）
#       --auto-dns         同时使用自动下发 DNS
#       -y, --yes          跳过确认（SSH 强制确认不能跳过）
#   ./wifi-cfg.sh password <名称|UUID> [新密码] [-y]     修改 WiFi 密码
#   ./wifi-cfg.sh dhcp <名称|UUID> [--keep-dns] [-y]    改 DHCP 获取
#   ./wifi-cfg.sh static <名称|UUID> <IP/前缀> [网关] [--dns a,b] [-y]
#   ./wifi-cfg.sh dns <名称|UUID> <DNS列表|--auto>      只改 DNS
#   ./wifi-cfg.sh autoconnect <名称|UUID> on|off [--priority N] [-y]
#   ./wifi-cfg.sh priority <名称|UUID> <N>             自动连接优先级（越大越优先）
#   ./wifi-cfg.sh delete <名称|UUID> [-y]               忘记网络
#   -h, --help
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=net_lib.sh
. "$SCRIPT_DIR/net_lib.sh"

PROG="$(basename "$0")"

usage() {
	sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# 判断 SSID 是否已保存
wifi_saved() {
	nmcli -g 802-11-wireless.ssid con show 2>/dev/null | grep -qxF "$1"
}

# 选择 WiFi 目标：$1=名称|UUID（可空）-> uuid<TAB>name<TAB>active_dev
pick_wifi() {
	local given="${1:-}" row uuid name dev
	row=$(net_pick_profile wifi "$given") || return 1
	IFS=$'\t' read -r uuid name <<<"$row"
	dev=$(net_active_dev_of "$name" wifi)
	printf '%s\t%s\t%s\n' "$uuid" "$name" "$dev"
}

##################################### 连接新 WiFi ##################################

# wifi_connect <dev> <ssid> <pw> <auth wpa|open|wep> <hidden yes|no> \
#              <static cidr|''> <gw|''> <dns|''> <ignore yes|no|keep>
wifi_connect() {
	local dev="$1" ssid="$2" pw="$3" auth="$4" hidden="$5"
	local cidr="$6" gw="$7" dns="$8" ignore="${9:-keep}"

	if [ "$(nmcli -t -f WIFI general 2>/dev/null)" != "enabled" ]; then
		net_err "WiFi 无线电关闭中，先 radio on"
		return 1
	fi
	if [ -z "$ssid" ]; then
		net_err "SSID 不能为空"
		return 1
	fi
	if wifi_saved "$ssid"; then
		net_err "「$ssid」已保存：直接用 wifi-ctrl.sh up 连接，或先 delete 再重新添加"
		return 1
	fi
	case "$auth" in
		wpa|wep) [ -z "$pw" ] && { net_err "$auth 网络必须提供密码"; return 1; } ;;
		open) ;;
		*) net_err "未知加密类型: $auth"; return 1 ;;
	esac
	if [ -n "$cidr" ]; then
		net_valid_cidr "$cidr" || { net_err "IP/前缀不合法：$cidr"; return 1; }
		[ -n "$gw" ] && { net_valid_ip4 "$gw" || { net_err "网关不合法：$gw"; return 1; }; }
		[ -n "$dns" ] && { net_valid_dns_list "$dns" || return 1; }
		net_warn_cross_subnet "$cidr" "$gw"
	fi

	# 预览（密码掩码）
	net_hr
	printf '将连接新 WiFi：%s\n' "$ssid"
	printf '  网卡  : %s\n' "$dev"
	printf '  加密  : %s\n' "$([ "$auth" = wpa ] && echo WPA/WPA2/WPA3 || [ "$auth" = wep ] && echo WEP || echo 开放)"
	printf '  隐藏  : %s\n' "$([ "$hidden" = yes ] && echo 是 || echo 否)"
	printf '  密码  : %s\n' "$([ -n "$pw" ] && echo '********' || echo 无)"
	if [ -n "$cidr" ]; then
		printf '  手动IP: %s\n' "$cidr"
		printf '  网关  : %s\n' "${gw:-（无）}"
		printf '  DNS   : %s\n' "${dns:-（无）}"
		printf '  忽略自动DNS: %s\n' "$ignore"
	fi
	net_hr

	net_ssh_guard "$dev"
	net_confirm "确认保存并连接「$ssid」？" || return 1

	local ok=0
	if [ "$auth" = wep ]; then
		# WEP 走 con add（dev wifi connect 对 WEP 支持不完整）
		local -a wargs=(con add type wifi ifname "$dev" con-name "$ssid" ssid "$ssid"
			wifi-sec.key-mgmt none wifi-sec.wep-key-type 1 wifi-sec.wep-key0 "$pw")
		[ "$hidden" = yes ] && wargs+=(802-11-wireless.hidden yes)
		net_run_root nmcli "${wargs[@]}" && \
			net_run_root nmcli con up "$ssid" ifname "$dev" && ok=1
	else
		local -a cargs=(dev wifi connect "$ssid" ifname "$dev")
		[ "$auth" = wpa ] && cargs+=(password "$pw")
		[ "$hidden" = yes ] && cargs+=(hidden yes)
		net_run_root nmcli "${cargs[@]}" && ok=1
	fi

	if [ $ok -ne 1 ]; then
		net_err "连接失败，请确认 SSID/密码/信号后重试（已保存的半成品配置请用 list/delete 清理）"
		return 1
	fi
	net_ok "已连接「$ssid」"

	# 连接成功后追加手动 IP
		if [ -n "$cidr" ]; then
			local uuid
			uuid=$(net_active_uuid "$dev")
			if [ -z "$uuid" ]; then
				net_warn "连接已建立但未读到活动配置 UUID，手动 IP 未设置（可用 static 子命令补设）"
				return 1
			fi
			local -a margs=(ipv4.method manual ipv4.addresses "$cidr")
			if [ -n "$gw" ]; then margs+=(ipv4.gateway "$gw"); fi
			if [ -n "$dns" ]; then margs+=(ipv4.dns "$dns" ipv4.ignore-auto-dns "$ignore"); fi
			net_run_root nmcli con mod "$uuid" "${margs[@]}" || return 1
			net_reapply "$dev" "$uuid"
		fi
}

do_connect() {
	local -a pos=()
	local pw="" auth="" hidden="no" cidr="" gw="" dns="" ignore="yes"
	while [ $# -gt 0 ]; do
		case "$1" in
			--hidden) hidden=yes; shift ;;
			--open) auth=open; shift ;;
			--wep) auth=wep; shift ;;
			--wpa) auth=wpa; shift ;;
			--static) cidr="$2"; shift 2 ;;
			--gw) gw="$2"; shift 2 ;;
			--dns) dns=$(net_norm_dns "$2"); shift 2 ;;
			--no-auto-dns) ignore=yes; shift ;;
			--auto-dns) ignore=no; shift ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			*) pos+=("$1"); shift ;;
		esac
	done

	local dev="" ssid=""
	# 第一个位置参数若恰好是 wifi 网卡名则视为网卡
	if [ "${#pos[@]}" -ge 1 ]; then
		while IFS=$'\t' read -r d _s _c; do
			if [ "$d" = "${pos[0]}" ]; then dev="$d"; break; fi
		done < <(net_dev_rows wifi)
	fi
	if [ -n "$dev" ]; then
		ssid="${pos[1]:-}"; pw="${pos[2]:-}"
	else
		ssid="${pos[0]:-}"; pw="${pos[1]:-}"
	fi
	[ -z "$dev" ] && dev=$(net_pick_device wifi) || true
	[ -z "$dev" ] && return 1

	# 非交互缺参直接报错
	if [ -z "$ssid" ]; then
		if ! tty -s; then net_err "缺少 SSID"; return 1; fi
		connect_wizard "$dev"
		return $?
	fi

	# 推断加密：显式参数优先；有密码默认 WPA；无密码必须交互确认或 --open
	if [ -z "$auth" ]; then
		if [ -n "$pw" ]; then auth=wpa
		else
			if ! tty -s; then net_err "开放网络需加 --open，否则请提供密码"; return 1; fi
			connect_wizard "$dev"
			return $?
		fi
	fi
	if [ -z "$pw" ] && [ "$auth" != open ] && tty -s; then
		net_ask_secret "「$ssid」的 WiFi 密码" "再次输入密码"
		pw="$NET_ASK"
	fi
	wifi_connect "$dev" "$ssid" "$pw" "$auth" "$hidden" "$cidr" "$gw" "$dns" "$ignore"
}

# 交互式：扫描选网或手输隐藏 SSID
connect_wizard() {
	local dev="$1" ssid="" pw="" auth="" hidden="no" security=""
	# 无线电关着则先开
	if [ "$(nmcli -t -f WIFI general 2>/dev/null)" != "enabled" ]; then
		if net_ask_yes "WiFi 无线电当前关闭，是否立即开启？" "y"; then
			net_run_root nmcli radio wifi on || return 1
		else
			return 1
		fi
	fi

	net_wifi_scan "$dev" || return 1
	local sel
	read -r -p "输入序号选择网络，或输入 0 手动填写 SSID（隐藏网络）: " sel </dev/tty || true
	case "${sel:-x}" in
		0)
			net_ask "请输入 SSID"
			ssid="$NET_ASK"
			[ -z "$ssid" ] && return 1
			if net_ask_yes "这是隐藏网络（不广播 SSID）吗？" "y"; then hidden=yes; fi
			net_info "加密类型：1) WPA/WPA2/WPA3  2) 开放（无密码）  3) WEP"
			local k
			read -r -p "选择 [1]: " k </dev/tty || true
			case "${k:-1}" in
				2) auth=open ;;
				3) auth=wep ;;
				*) auth=wpa ;;
			esac
			;;
		''|*[!0-9]*) net_err "无效输入"; return 1 ;;
		*)
			if [ "$sel" -lt 1 ] || [ "$sel" -gt "${#_NET_SCAN[@]}" ]; then
				net_err "序号超出范围"; return 1
			fi
			IFS=$'\t' read -r ssid security _bssid <<<"${_NET_SCAN[$((sel-1))]}"
			if [ "$ssid" = "（隐藏网络）" ]; then
				net_err "该热点未广播 SSID，请选 0 手动填写"; return 1
			fi
			if wifi_saved "$ssid"; then
				net_err "「$ssid」已保存，无需重新添加（菜单选「连接已保存 WiFi」或先删除）"
				return 1
			fi
			case "$security" in
				*WPA*) auth=wpa ;;
				*WEP*) auth=wep ;;
				*)     auth=open ;;
			esac
			;;
	esac

	if [ "$auth" != open ]; then
		net_ask_secret "「$ssid」的 WiFi 密码" "再次输入密码"
		pw="$NET_ASK"
	fi

	local cidr="" gw="" dns="" ignore="keep"
	if net_ask_yes "是否同时为该网络配置手动 IP（默认 DHCP）？" "n"; then
		net_ask_static "$dev"
		cidr="$NET_IP_CIDR"; gw="$NET_IP_GW"; dns="$NET_IP_DNS"; ignore="$NET_IP_IGNORE"
	fi
	wifi_connect "$dev" "$ssid" "$pw" "$auth" "$hidden" "$cidr" "$gw" "$dns" "$ignore"
}

##################################### 修改 / 删除 ##################################

do_password() {
	local given="" pw=""
	while [ $# -gt 0 ]; do
		case "$1" in
			-y|--yes) NET_ASSUME_YES=1 ;;
			*) if [ -z "$given" ]; then given="$1"; else pw="$1"; fi ;;
		esac
		shift
	done
	[ -z "$given" ] && { net_err "用法：password <名称|UUID> [新密码]"; return 1; }
	local row uuid name dev kmgmt field
	row=$(pick_wifi "$given") || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"
	kmgmt=$(net_con_val "$uuid" 802-11-wireless-security.key-mgmt)
	case "$kmgmt" in
		wpa*|sae|ieee8021x) field=wifi-sec.psk ;;
		none) field=wifi-sec.wep-key0 ;;
		'')
			net_err "「$name」是开放网络（无密码）。如需加密请删除后重新添加"
			return 1 ;;
		*) field=wifi-sec.psk ;;
	esac
	if [ -z "$pw" ]; then
		net_require_tty
		net_ask_secret "「$name」的新密码" "再次输入新密码"
		pw="$NET_ASK"
	fi
	net_hr
	printf '将修改 WiFi 密码：%s（字段 %s）\n' "$name" "$field"
	printf '  新密码: ********\n'
	[ -n "$dev" ] && printf '  该网络正在使用，改完会立即重连\n'
	net_hr
	[ -n "$dev" ] && net_ssh_guard "$dev"
	net_confirm "确认修改「$name」的密码？" || return 1

	net_run_root nmcli con mod "$uuid" "$field" "$pw" || { net_err "写入失败"; return 1; }
	if [ -n "$dev" ]; then
		# PSK 变更通常需要重新激活才能生效
		net_run_root nmcli con up uuid "$uuid" ifname "$dev"
	else
		net_ok "已保存，下次连接时使用新密码"
	fi
}

# 解析 wifi 目标后调用 IPv4 通用修改
wifi_ip_change() {
	local mode="$1"; shift
	local given="${1:-}"; shift || true
	local row uuid name dev
	row=$(pick_wifi "$given") || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"

	local cidr="" gw="" dns="" ignore="keep" dns_mode=""
	while [ $# -gt 0 ]; do
		case "$1" in
			--dns) dns=$(net_norm_dns "$2"); shift 2 ;;
			--no-auto-dns) ignore=yes; shift ;;
			--auto-dns) ignore=no; shift ;;
			--keep-dns) dns_mode=keep; shift ;;
			--clear-dns) dns_mode=clear; shift ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			--no-gw) gw=""; shift ;;
			*)
				if [ -z "$cidr" ]; then cidr="$1"
				elif [ -z "$gw" ]; then gw="$1"
				fi
				shift ;;
		esac
	done

	case "$mode" in
		dhcp)
			net_apply_ipv4 "$uuid" "$dev" dhcp "" "" \
				"$([ "$dns_mode" = keep ] && echo "" || echo __CLEAR__)" keep
			;;
		static)
			[ -z "$cidr" ] && { net_err "缺少 IP/前缀"; return 1; }
			net_valid_cidr "$cidr" || { net_err "IP/前缀不合法：$cidr"; return 1; }
			[ -n "$gw" ] && { net_valid_ip4 "$gw" || { net_err "网关不合法：$gw"; return 1; }; }
			[ -n "$dns" ] || ignore=keep
			net_apply_ipv4 "$uuid" "$dev" manual "$cidr" "$gw" "$dns" "$ignore"
			;;
	esac
}

do_dns() {
	local given="" dns="" ignore="yes"
	while [ $# -gt 0 ]; do
		case "$1" in
			--auto|--clear) dns="__CLEAR__"; ignore="no"; shift ;;
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			--dns) dns=$(net_norm_dns "$2"); shift 2 ;;
			*) if [ -z "$given" ]; then given="$1"; else dns=$(net_norm_dns "$1"); fi; shift ;;
		esac
	done
	[ -z "$dns" ] && { net_err "用法：dns <名称|UUID> 8.8.8.8,1.1.1.1 | --auto"; return 1; }
	[ "$dns" != "__CLEAR__" ] && { net_valid_dns_list "$dns" || return 1; }
	local row uuid name dev
	row=$(pick_wifi "$given") || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"
	if [ "$dns" = "__CLEAR__" ]; then
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
			*) given="${given:-$1}"; shift ;;
		esac
	done
	case "${onoff:-}" in
		yes) onoff=on ;;
		on|off) ;;
		*) net_err "用法：autoconnect <名称|UUID> on|off [--priority N]"; return 1 ;;
	esac
	[ -n "$pri" ] && { net_valid_priority "$pri" || { net_err "优先级需为 -999~999 的整数"; return 1; }; }
	local row uuid name dev
	row=$(pick_wifi "$given") || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"
	net_apply_autoconnect "$uuid" "$dev" "$onoff" || return 1
	if [ -n "$pri" ]; then net_apply_priority "$uuid" "$pri"; fi
	return 0
}

do_priority() {
	local given="" pri=""
	while [ $# -gt 0 ]; do
		case "$1" in
			-y|--yes) NET_ASSUME_YES=1; shift ;;
			*) if [ -z "$given" ]; then given="$1"; elif [ -z "$pri" ]; then pri="$1"; fi; shift ;;
		esac
	done
	net_valid_priority "${pri:-}" || { net_err "用法：priority <名称|UUID> <-999~999 整数>"; return 1; }
	local row uuid name dev
	row=$(pick_wifi "$given") || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"
	net_apply_priority "$uuid" "$pri"
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
	local row uuid name dev
	row=$(pick_wifi "$given") || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"
	net_apply_delete "$uuid" "$dev"
}

do_list() {
	net_section "已保存的 WiFi（按优先级降序）"
	net_list_profiles wifi
}

##################################### 菜单 #########################################

menu_modify() {
	local row uuid name dev
	row=$(pick_wifi) || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"
	while true; do
		printf '\n── 修改「%s」%s ──\n' "$name" "$([ -n "$dev" ] && echo "（在用：$dev）" || echo "（当前未连接）")"
		printf '  1) 修改密码\n'
		printf '  2) 设置手动 IP\n'
		printf '  3) 切回 DHCP\n'
		printf '  4) 修改 DNS\n'
		printf '  b) 返回\n'
		local c
		read -r -p "请选择（回车返回）: " c </dev/tty || true
		case "$c" in
			1) do_password "$name" ;;
			2)
				net_ask_static "$dev" "$uuid"
				net_apply_ipv4 "$uuid" "$dev" manual \
					"$NET_IP_CIDR" "$NET_IP_GW" "$NET_IP_DNS" "$NET_IP_IGNORE" ;;
			3)
				if net_ask_yes "清除手动 DNS，完全使用 DHCP 下发？" "y"; then
					net_apply_ipv4 "$uuid" "$dev" dhcp "" "" __CLEAR__ keep
				else
					net_apply_ipv4 "$uuid" "$dev" dhcp "" "" "" keep
				fi ;;
			4)
				local ans ignore="yes"
				net_ask "DNS（逗号分隔）；auto 恢复自动下发；回车取消" "$(net_con_val "$uuid" ipv4.dns)"
				ans="$NET_ASK"
				[ -z "$ans" ] && continue
				if [ "$ans" = auto ]; then
					net_apply_dns "$uuid" "$dev" "" "no"
				else
					ans=$(net_norm_dns "$ans")
					net_valid_dns_list "$ans" || continue
					net_ask_yes "忽略自动下发的 DNS？" "y" || ignore="no"
					net_apply_dns "$uuid" "$dev" "$ans" "$ignore"
				fi ;;
			''|b|B|q|Q) return 0 ;;
			*) net_warn "无效选择" ;;
		esac
		net_pause
	done
}

menu_autoconnect() {
	local row uuid name dev cur onoff
	row=$(pick_wifi) || return 1
	IFS=$'\t' read -r uuid name dev <<<"$row"
	cur=$(net_con_val "$uuid" connection.autoconnect)
	if [ "$cur" = yes ]; then
		net_ask_yes "「$name」自动连接=是，是否关闭？" "n" && onoff=off || onoff=on
	else
		net_ask_yes "「$name」自动连接=否，是否开启？" "y" && onoff=on || onoff=off
	fi
	net_apply_autoconnect "$uuid" "$dev" "$onoff"
}

menu_priority() {
	local row uuid name cur
	row=$(pick_wifi) || return 1
	IFS=$'\t' read -r uuid name _dev <<<"$row"
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
		printf '\n======== 无线网络配置（修改配置，需 sudo）========\n'
		printf '  WiFi 无线电: %s\n' "$(nmcli -t -f WIFI general 2>/dev/null)"
		printf '  1) 查看已保存 WiFi（自动连接 / 优先级 / 在用 / UUID）\n'
		printf '  2) 连接新 WiFi（扫描选择 / 隐藏网络 / 可配手动 IP）\n'
		printf '  3) 修改已存 WiFi（密码 / 手动 IP / DHCP / DNS）\n'
		printf '  4) 自动连接 开 / 关\n'
		printf '  5) 设置自动连接优先级\n'
		printf '  6) 忘记（删除）WiFi\n'
		printf '  q) 退出\n'
		local choice
		read -r -p "请选择（空回车退出）: " choice </dev/tty || true
		case "$choice" in
			1) do_list ;;
			2) do_connect ;;
			3) menu_modify ;;
			4) menu_autoconnect ;;
			5) menu_priority ;;
			6) do_delete ;;
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
		list)        do_list "$@" ;;
		connect)     do_connect "$@" ;;
		password)    do_password "$@" ;;
		static|dhcp) wifi_ip_change "$cmd" "$@" ;;
		dns)         do_dns "$@" ;;
		autoconnect) do_autoconnect "$@" ;;
		priority)    do_priority "$@" ;;
		delete)      do_delete "$@" ;;
		*) net_err "未知参数: $cmd"; echo; usage; exit 1 ;;
	esac
}

main "$@"
