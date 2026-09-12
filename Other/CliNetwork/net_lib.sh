#!/usr/bin/env bash
# CliNetwork 公共函数库：由 eth-ctrl.sh / eth-cfg.sh / wifi-ctrl.sh / wifi-cfg.sh source。
# 仅支持 NetworkManager（nm），不直接运行。
#
# 约定：
#   - 只读操作不需要 root；写操作统一走 net_run_root（非 root 自动 sudo）
#   - 任何写操作执行前必须 net_preview + net_confirm（默认否）
#   - 通过被操作网卡 SSH 在线时，net_ssh_guard 强制二次确认（不接受 -y 跳过）

##################################### 基础输出 #####################################

net_info() { printf '%s\n' "$*"; }
net_ok()   { printf '✔ %s\n' "$*"; }
net_warn() { printf '⚠ 警告: %s\n' "$*" >&2; }
net_err()  { printf '✘ 错误: %s\n' "$*" >&2; }

net_section() { printf '\n── %s ────────────────────────────\n' "$*"; }
net_hr() { printf '%s\n' "------------------------------------------------------------"; }

net_pause() {
	if tty -s; then
		local _x=""
		read -r -p "回车继续… " _x </dev/tty || true
	fi
}

##################################### 环境检查 #####################################

net_require_nm() {
	if ! command -v nmcli >/dev/null 2>&1; then
		net_err "未找到 nmcli，请先安装 network-manager（apt install network-manager）"
		exit 1
	fi
	local r
	r=$(nmcli -t -f RUNNING general 2>/dev/null) || {
		net_err "无法与 NetworkManager 通信，确认服务已安装"
		exit 1
	}
	if [ "$r" != "running" ]; then
		net_err "NetworkManager 当前未运行：sudo systemctl start NetworkManager"
		exit 1
	fi
	return 0
}

# 以 root 执行；非 root 时自动 sudo
net_run_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

##################################### TTY / 输入 ###################################

net_require_tty() {
	if ! tty -s; then
		net_err "当前不是交互终端，请改用命令参数（-h 查看用法），或在终端中运行"
		exit 1
	fi
}

# net_ask <提示> [默认值]  -> 答案存入全局 NET_ASK
NET_ASK=""
net_ask() {
	local prompt="$1" def="${2:-}" ans=""
	if [ -n "$def" ]; then
		printf '%s [%s]: ' "$prompt" "$def" >&2
	else
		printf '%s: ' "$prompt" >&2
	fi
	read -r ans </dev/tty || true
	NET_ASK="${ans:-$def}"
}

# net_ask_secret <提示> [再次确认提示] -> NET_ASK
net_ask_secret() {
	local prompt="$1" confirm="${2:-}" a="" b=""
	while true; do
		printf '%s: ' "$prompt" >&2
		read -r -s a </dev/tty || true
		printf '\n' >&2
		if [ -z "$a" ]; then
			net_warn "密码不能为空"
			continue
		fi
		if [ -n "$confirm" ]; then
			printf '%s: ' "$confirm" >&2
			read -r -s b </dev/tty || true
			printf '\n' >&2
			if [ "$a" != "$b" ]; then
				net_warn "两次输入不一致，重新输入"
				continue
			fi
		fi
		NET_ASK="$a"
		return 0
	done
}

# net_ask_yes <提示> [默认 y|n] -> 返回 0=yes 1=no
net_ask_yes() {
	local prompt="$1" def="${2:-n}" hint ans
	if [ "$def" = "y" ]; then hint="[Y/n]"; else hint="[y/N]"; fi
	printf '%s %s: ' "$prompt" "$hint" >&2
	read -r ans </dev/tty || true
	ans="${ans:-$def}"
	case "$ans" in
		y|Y|yes|YES) return 0 ;;
		*) return 1 ;;
	esac
}

# 通用确认，默认否。-y 时（NET_ASSUME_YES=1）直接通过
net_confirm() {
	local prompt="${1:-确认执行以上操作?}"
	if [ "${NET_ASSUME_YES:-0}" = "1" ]; then
		net_warn "已通过 -y 跳过确认：$prompt"
		return 0
	fi
	net_require_tty
	local ans
	printf '%s [y/N]: ' "$prompt" >&2
	read -r ans </dev/tty || true
	case "$ans" in
		y|Y|yes|YES) return 0 ;;
		*) net_info "已取消"; return 1 ;;
	esac
}

# 强制确认：要求原样输入指定字符串，-y 不能跳过
net_force_confirm() {
	local expect="$1" prompt="${2:-}" ans
	net_require_tty
	printf '%s\n' "$prompt" >&2
	printf '如确认，请输入 %s 后回车（其它输入取消）: ' "$expect" >&2
	read -r ans </dev/tty || true
	[ "$ans" = "$expect" ]
}

##################################### 校验 #########################################

net_is_int() {
	case "${1:-}" in
		''|*[!0-9-]*) return 1 ;;
		*) return 0 ;;
	esac
}

# 正规 IPv4 校验（0-255 四段）
net_valid_ip4() {
	local ip="${1:-}" o
	IFS='.' read -ra o <<<"$ip"
	[ "${#o[@]}" -eq 4 ] || return 1
	for o in "${o[@]}"; do
		case "$o" in ''|*[!0-9]*) return 1 ;; esac
		{ [ "$o" -ge 0 ] && [ "$o" -le 255 ]; } 2>/dev/null || return 1
	done
	return 0
}

# CIDR（192.168.1.10/24）校验
net_valid_cidr() {
	local v="${1:-}" ip pfx
	ip="${v%/*}"; pfx="${v#*/}"
	[ "$ip" != "$v" ] || return 1
	case "$pfx" in ''|*[!0-9]*) return 1 ;; esac
	{ [ "$pfx" -ge 1 ] && [ "$pfx" -le 32 ]; } 2>/dev/null || return 1
	net_valid_ip4 "$ip"
}

net_ip2int() {
	local o
	IFS='.' read -ra o <<<"$1"
	echo $(( (o[0]<<24) + (o[1]<<16) + (o[2]<<8) + o[3] ))
}

# 网关与地址不在同一 IPv4 网段时告警
net_warn_cross_subnet() {
	local cidr="${1:-}" gw="${2:-}"
	[ -n "$gw" ] || return 0
	net_valid_cidr "$cidr" && net_valid_ip4 "$gw" || return 0
	local ip pfx a m n1 n2
	ip="${cidr%/*}"; pfx="${cidr#*/}"
	a=$(net_ip2int "$ip"); m=$(( (0xFFFFFFFF << (32 - pfx)) & 0xFFFFFFFF ))
	n2=$(net_ip2int "$gw")
	n1=$(( a & m )); n2=$(( n2 & m ))
	if [ "$n1" -ne "$n2" ]; then
		net_warn "网关 $gw 与地址 $cidr 不在同一网段，确认是否正确？"
	fi
}

# 归一化 DNS 列表（逗号/空格/中文逗号分隔）-> 逗号
net_norm_dns() {
	local raw="$*"
	raw="${raw//，/,}"
	raw=$(printf '%s' "$raw" | tr ' ' ',')
	printf '%s' "$raw" | sed 's/,\+/,/g; s/^,//; s/,$//'
}

# DNS 列表逐项校验（仅 IPv4），非法项输出到 stderr 并返回 1
net_valid_dns_list() {
	local list="${1:-}" d bad=""
	IFS=',' read -ra list_arr <<<"$list"
	for d in "${list_arr[@]}"; do
		net_valid_ip4 "$d" || bad="$bad $d"
	done
	if [ -n "$bad" ]; then
		net_err "不是合法 IPv4 DNS：$bad"
		return 1
	fi
	return 0
}

# 网卡活动连接的 UUID（无则空）
net_active_uuid() {
	local con
	con=$(net_active_con "$1") || return 1
	[ -n "$con" ] || return 0
	nmcli -g connection.uuid con show "$con" 2>/dev/null
}

# 判断某连接是否正在某 kind 网卡上活动，输出该网卡名
net_active_dev_of() {
	local name="$1" kind="$2" dev state con
	while IFS=$'\t' read -r dev state con; do
		[ "$con" = "$name" ] && { printf '%s' "$dev"; return 0; }
	done < <(net_dev_rows "$kind")
	return 0
}

# 优先级范围校验（NM connection.autoconnect-priority 为 int32）
net_valid_priority() {
	local p="${1:-}"
	net_is_int "$p" || return 1
	[ "$p" -ge -999 ] && [ "$p" -le 999 ]
}

##################################### nmcli 转义/字段 ##############################

# nmcli -t 输出中 \: 和 \\ 为转义，还原
net_unesc() {
	sed -e 's/\\\\/\x01/g' -e 's/\\:/:/g' -e 's/\\ / /g' -e 's/\x01/\\/g'
}

# net_con_val <name|uuid> <nmcli 字段> （多行/多值统一逗号连接）
net_con_val() {
	nmcli -g "$2" con show "$1" 2>/dev/null | sed 's/ | /,/g' | tr '\n' ',' | sed 's/,$//'
}

# 连接类型对应的 NM TYPE
net_nmtype() {
	case "$1" in
		ethernet) echo "802-3-ethernet" ;;
		wifi)     echo "802-11-wireless" ;;
		*) return 1 ;;
	esac
}

# 网卡行：dev<TAB>state<TAB>active-con（无连接时空）
net_dev_rows() {
	local kind="$1"
	nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null \
		| awk -F: -v k="$( [ "$kind" = wifi ] && echo wifi || echo ethernet )" '
			$2==k { con=$4; for(i=5;i<=NF;i++) con=con":"$i; print $1"\t"$3"\t"con }' \
		| net_unesc
}

# 配置文件行（原始 -t）：name:uuid:type:device
net_con_rows() {
	local kind="$1" t
	t=$(net_nmtype "$kind") || return 1
	nmcli -t -f NAME,UUID,TYPE,DEVICE con show 2>/dev/null | awk -F: -v t="$t" '$3==t'
}

# 选择网卡。$1=kind  $2=用户给定（可空） -> 输出网卡名
net_pick_device() {
	local kind="$1" given="${2:-}" line dev state con
	if [ -n "$given" ]; then
		while IFS=$'\t' read -r dev state con; do
			if [ "$dev" = "$given" ]; then echo "$dev"; return 0; fi
		done < <(net_dev_rows "$kind")
		net_err "未找到 $kind 网卡：$given"
		return 1
	fi
	mapfile -t _NET_DEVS < <(net_dev_rows "$kind")
	if [ "${#_NET_DEVS[@]}" -eq 0 ]; then
		net_err "系统中没有被 NetworkManager 识别的 $kind 网卡"
		return 1
	fi
	if [ "${#_NET_DEVS[@]}" -eq 1 ]; then
		printf '%s' "${_NET_DEVS[0]%%$'\t'*}"
		return 0
	fi
	net_require_tty
	local i=1
	net_section "选择网卡"
	for line in "${_NET_DEVS[@]}"; do
		IFS=$'\t' read -r dev state con <<<"$line"
		printf '  %d) %-18s 状态:%-12s %s\n' "$i" "$dev" "$state" "${con:+（$con）}"
		i=$((i+1))
	done
	local sel
	printf '请输入序号: ' >&2
	read -r sel </dev/tty || true
	case "$sel" in
		''|*[!0-9]*) net_err "无效序号"; return 1 ;;
	esac
	if [ "$sel" -ge 1 ] && [ "$sel" -le "${#_NET_DEVS[@]}" ]; then
		printf '%s' "${_NET_DEVS[$((sel-1))]%%$'\t'*}"
	else
		net_err "序号超出范围"; return 1
	fi
}

# 网卡当前活动的连接名（无则输出空）
net_active_con() {
	local c
	c=$(nmcli -g GENERAL.CONNECTION dev show "$1" 2>/dev/null)
	[ "$c" != "/" ] && printf '%s' "$c"
}

# 选择配置文件。$1=kind $2=name|uuid（可空）$3=限定网卡（可空）
# 输出：uuid<TAB>name
net_pick_profile() {
	local kind="$1" given="${2:-}" onlydev="${3:-}" line name uuid dev
	local -a rows=()
	while IFS= read -r line; do
		# -t 行：name:uuid:type:device（name 可能含转义冒号；uuid 固定 36 字符）
		uuid=$(printf '%s' "$line" | awk -F: '{print $(NF-2)}')
		dev=$(printf '%s' "$line" | awk -F: '{print $NF}')
		name=$(printf '%s' "$line" | sed 's/:[0-9a-f-]\{36\}:.*$//' | net_unesc)
		[ -n "$onlydev" ] && [ "$dev" != "$onlydev" ] && continue
		rows+=("$uuid"$'\t'"$name"$'\t'"$dev")
	done < <(net_con_rows "$kind")

	if [ "${#rows[@]}" -eq 0 ]; then
		net_err "没有找到 $kind 配置文件"
		return 1
	fi

	if [ -n "$given" ]; then
		local -a hits=()
		for line in "${rows[@]}"; do
			IFS=$'\t' read -r uuid name dev <<<"$line"
			if [ "$given" = "$uuid" ] || [ "$given" = "$name" ]; then
				hits+=("$line")
			fi
		done
		if [ "${#hits[@]}" -eq 1 ]; then
			IFS=$'\t' read -r uuid name dev <<<"${hits[0]}"
			printf '%s\t%s\n' "$uuid" "$name"
			return 0
		fi
		if [ "${#hits[@]}" -eq 0 ]; then
			# 形如 UUID 却没匹配上时直接报错，绝不回退到第一条配置
			if [[ "$given" =~ ^[0-9a-fA-F-]{36}$ ]]; then
				net_err "未找到 UUID：$given"
				return 1
			fi
			net_err "未找到配置文件：$given（可用 list 查看）"
			return 1
		fi
		rows=("${hits[@]}")
	fi

	if [ "${#rows[@]}" -eq 1 ]; then
		IFS=$'\t' read -r uuid name dev <<<"${rows[0]}"
		printf '%s\t%s\n' "$uuid" "$name"
		return 0
	fi

	net_require_tty
	net_section "选择配置文件（同名时以 UUID 区分）"
	local i=1 active
	for line in "${rows[@]}"; do
		IFS=$'\t' read -r uuid name dev <<<"$line"
		active=""
		[ "$(net_active_con "$dev" 2>/dev/null)" = "$name" ] && active=" ◄ 在用"
		printf '  %d) %-28s %s%s\n' "$i" "$name" "${dev:+[$dev] }" "$active"
		printf '     UUID: %s\n' "$uuid"
		i=$((i+1))
	done
	local sel
	printf '请输入序号: ' >&2
	read -r sel </dev/tty || true
	case "$sel" in ''|*[!0-9]*) net_err "无效序号"; return 1 ;; esac
	if [ "$sel" -ge 1 ] && [ "$sel" -le "${#rows[@]}" ]; then
		IFS=$'\t' read -r uuid name dev <<<"${rows[$((sel-1))]}"
		printf '%s\t%s\n' "$uuid" "$name"
	else
		net_err "序号超出范围"; return 1
	fi
}

##################################### 预览 / SSH 保护 ##############################

# net_preview <标题> ；随后读取三列：每行 "标签|当前|目标"（stdin）
net_preview() {
	local title="$1" label cur new
	net_hr
	printf '即将修改：%s\n' "$title"
	net_hr
	while IFS='|' read -r label cur new; do
		[ -z "$label" ] && continue
		printf '  %s\n' "$label"
		printf '      当前: %s\n' "${cur:-（空）}"
		printf '      改为: %s\n' "${new:-（空）}"
	done
	net_hr
}

# SSH 会话中，若被操作网卡正是到本机的路由出口，强制确认
net_ssh_guard() {
	local dev="$1" cip edev
	[ -n "${SSH_CONNECTION:-}" ] || return 0
	cip=${SSH_CONNECTION%% *}
	edev=$(ip -o route get "$cip" 2>/dev/null | sed -n 's/.* dev \([A-Za-z0-9_.:-]*\).*/\1/p' | head -1)
	if [ "$edev" = "$dev" ]; then
		net_warn "你正通过 SSH 使用网卡 $dev 操作（客户端 $cip）！"
		net_warn "配置错误会导致 SSH 断开且无法远程恢复！"
		net_force_confirm "$dev" "必须输入网卡名 $dev 才能继续" || {
			net_info "已取消"; exit 1
		}
	fi
}

##################################### 应用配置 #####################################

# reapply 不掉线生效，失败回退为 con up
net_reapply() {
	local dev="$1" uuid="$2" errf
	errf=$(mktemp)
	if net_run_root nmcli -w 12 dev reapply "$dev" 2>"$errf"; then
		rm -f "$errf"
		return 0
	fi
	net_warn "即时生效失败：$(tr '\n' ' ' <"$errf")"
	rm -f "$errf"
	net_info "尝试断开后重新激活连接…"
	net_run_root nmcli con up uuid "$uuid" ifname "$dev"
}

# 修改 IPv4 配置并应用
# 参数：uuid dev mode(dhcp|manual) [cidr] [gw] [dns] [ignore-auto-dns: yes|no|<保持>]
net_apply_ipv4() {
	local uuid="$1" dev="$2" mode="$3" cidr="${4:-}" gw="${5:-}" dns="${6:-}" ignore="${7:-keep}"
	local cur_method cur_addr cur_gw cur_dns cur_ignore
	cur_method=$(net_con_val "$uuid" ipv4.method)
	cur_addr=$(net_con_val "$uuid" ipv4.addresses)
	cur_gw=$(net_con_val "$uuid" ipv4.gateway)
	cur_dns=$(net_con_val "$uuid" ipv4.dns)
	cur_ignore=$(net_con_val "$uuid" ipv4.ignore-auto-dns)

	local -a modargs=()
	{
		echo "IPv4 方式|$cur_method|$([ "$mode" = manual ] && echo 手动/static || echo 自动/DHCP)"
		if [ "$mode" = manual ]; then
			echo "IP 地址|$cur_addr|$cidr"
			echo "网关|$cur_gw|$gw"
			echo "DNS|$cur_dns|$dns"
			[ "$ignore" != keep ] && echo "忽略自动下发 DNS|$cur_ignore|$ignore"
		else
			local dns_show
			case "$dns" in
				__CLEAR__) dns_show="（清除手动 DNS）" ;;
				'') dns_show="（保持不变）" ;;
				*) dns_show="$dns" ;;
			esac
			echo "DNS|$cur_dns|$dns_show"
		fi
	} | net_preview "网卡 ${dev:-（未激活）} 的 IPv4 配置（连接 $(net_con_val "$uuid" connection.id)）"

	[ -n "$dev" ] && net_ssh_guard "$dev"
	net_confirm || return 1

	# nmcli 的 IPv4 方法取值是 auto/manual（dhcp 是我们对用户的说法）
	local nm="auto"; [ "$mode" = manual ] && nm="manual"
	modargs+=(ipv4.method "$nm")
	if [ "$mode" = manual ]; then
		# 注意：nmcli 1.46+ 不再把 addresses 里逗号后的项当网关，网关必须单独给
		modargs+=(ipv4.addresses "$cidr")
		if [ -n "$gw" ]; then
			modargs+=(ipv4.gateway "$gw")
		else
			modargs+=(ipv4.gateway "")
		fi
		if [ -n "$dns" ]; then
			modargs+=(ipv4.dns "$dns")
			[ "$ignore" != keep ] && modargs+=(ipv4.ignore-auto-dns "$ignore")
		fi
	else
		modargs+=(ipv4.addresses "" ipv4.gateway "")
		if [ "$dns" = "__CLEAR__" ]; then
			modargs+=(ipv4.dns "")
		elif [ -n "$dns" ]; then
			modargs+=(ipv4.dns "$dns")
		fi
	fi

	net_run_root nmcli con mod "$uuid" "${modargs[@]}" || { net_err "配置写入失败"; return 1; }
	if [ -n "$dev" ]; then net_reapply "$dev" "$uuid"; else net_ok "已保存，该连接下次激活时生效"; fi
}

# 仅改 DNS（不动 IP 获取方式）
net_apply_dns() {
	local uuid="$1" dev="$2" dns="$3" ignore="${4:-keep}"
	local cur_dns cur_ignore
	cur_dns=$(net_con_val "$uuid" ipv4.dns)
	cur_ignore=$(net_con_val "$uuid" ipv4.ignore-auto-dns)
	{
		echo "DNS|$cur_dns|$dns"
		[ "$ignore" != keep ] && echo "忽略自动下发 DNS|$cur_ignore|$ignore"
	} | net_preview "网卡 ${dev:-（未激活）} 的 DNS（连接 $(net_con_val "$uuid" connection.id)）"
	[ -n "$dev" ] && net_ssh_guard "$dev"
	net_confirm || return 1
	local -a modargs=(ipv4.dns "$dns")
	[ "$ignore" != keep ] && modargs+=(ipv4.ignore-auto-dns "$ignore")
	net_run_root nmcli con mod "$uuid" "${modargs[@]}" || { net_err "配置写入失败"; return 1; }
	if [ -n "$dev" ]; then net_reapply "$dev" "$uuid"; else net_ok "已保存，该连接下次激活时生效"; fi
}

# 自动连接开关
net_apply_autoconnect() {
	local uuid="$1" dev="$2" onoff="$3"
	local cur
	cur=$(net_con_val "$uuid" connection.autoconnect)
	echo "自动连接|$cur|$onoff" | net_preview "连接 $(net_con_val "$uuid" connection.id)"
	[ -n "$dev" ] && net_ssh_guard "$dev"
	net_confirm || return 1
	net_run_root nmcli con mod "$uuid" connection.autoconnect "$onoff" && net_ok "已保存"
}

# 自动连接优先级
net_apply_priority() {
	local uuid="$1" pri="$2"
	local cur
	cur=$(net_con_val "$uuid" connection.autoconnect-priority)
	echo "自动连接优先级|$cur|$pri（数值越大越优先）" \
		| net_preview "连接 $(net_con_val "$uuid" connection.id)"
	net_confirm "确认修改优先级？" || return 1
	net_run_root nmcli con mod "$uuid" connection.autoconnect-priority "$pri"
}

# 删除连接（忘记网络）。若该连接正在某网卡上活动先断开
net_apply_delete() {
	local uuid="$1" active_dev="${2:-}"
	local name ts bssid="" pri auto
	name=$(net_con_val "$uuid" connection.id)
	ts=$(net_con_val "$uuid" connection.timestamp)
	pri=$(net_con_val "$uuid" connection.autoconnect-priority)
	auto=$(net_con_val "$uuid" connection.autoconnect)
	bssid=$(net_con_val "$uuid" 802-11-wireless.bssid)
	net_hr
	printf '即将删除连接配置文件：%s\n' "$name"
	printf '  UUID      : %s\n' "$uuid"
	[ -n "$bssid" ] && printf '  指定 BSSID: %s\n' "$bssid"
	printf '  自动连接  : %s   优先级: %s\n' "$auto" "$pri"
	if [ "${ts:-0}" != "0" ] && [ -n "$ts" ]; then
		printf '  最近使用  : %s\n' "$(date -d "@$ts" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$ts")"
	fi
	net_hr
	if [ -n "$active_dev" ]; then
		net_warn "该连接正在网卡 $active_dev 上使用，删除会立即断网"
		net_ssh_guard "$active_dev"
	fi
	net_confirm "确认删除「$name」？删除后需重新配置才能再次连接" || return 1
	if [ -n "$active_dev" ]; then
		net_run_root nmcli dev disconnect "$active_dev" >/dev/null 2>&1 || true
	fi
	net_run_root nmcli con delete uuid "$uuid"
}

##################################### WiFi 扫描 ####################################

# 解析 -t 扫描行（BSSID 含转义冒号，从右侧固定字段反解）
# 输出：ssid<TAB>bssid<TAB>mode<TAB>chan<TAB>freq<TAB>signal<TAB>security<TAB>inuse
net_wifi_parse_scan_row() {
	awk -F: '
		{
			inuse=$NF; sec=$(NF-1); sig=$(NF-2); freq=$(NF-3)
			chan=$(NF-4); mode=$(NF-5)
			bssid=$(NF-6)
			for (i=NF-10;i<=NF-6;i++) bssid=(i==NF-10?$i:bssid":"$i)
			ssid=""
			for (i=1;i<=NF-11;i++) ssid=(i==1?$i:ssid":"$i)
			printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
				ssid,bssid,mode,chan,freq,sig,sec,inuse
		}'
}

# 扫描并打印表格；结果存入全局数组 _NET_SCAN（每行 ssid<TAB>security<TAB>bssid）
# 参数：dev [--no-rescan]
_NET_SCAN=()
net_wifi_scan() {
	local dev="$1" do_rescan=1
	[ "${2:-}" = "--no-rescan" ] && do_rescan=0
	_NET_SCAN=()

	if [ "$(nmcli -t -f WIFI general 2>/dev/null)" != "enabled" ]; then
		net_err "WiFi 无线电关闭中，无法扫描（nmcli radio wifi on 开启）"
		return 1
	fi
	if [ $do_rescan -eq 1 ]; then
		net_info "正在扫描（$dev）…"
		if ! out=$(net_run_root nmcli -w 10 dev wifi rescan ifname "$dev" 2>&1); then
			# 刚扫过会被限流，直接使用缓存列表即可
			net_warn "触发重新扫描失败，使用最近一次扫描结果（${out//$'\n'/ }）"
		fi
	fi

	# 已保存 SSID 集合
	local -A saved=()
	local s
	while IFS= read -r s; do [ -n "$s" ] && saved["$s"]=1; done \
		< <(nmcli -g 802-11-wireless.ssid con show 2>/dev/null)

	local raw
	raw=$(nmcli -t -f SSID,BSSID,MODE,CHAN,FREQ,SIGNAL,SECURITY,IN-USE \
		dev wifi list ifname "$dev" 2>&1) || {
		net_err "获取扫描列表失败：${raw//$'\n'/ }"
		return 1
	}

	local i=0 ssid bssid mode chan freq signal security inuse band mark
	net_hr
	printf '%-3s %-2s %-26s %-5s %-4s %-7s %-16s %s\n' \
		"#" "" "SSID" "信号" "信道" "频段" "加密" "标记"
	while IFS= read -r raw; do
		[ -z "$raw" ] && continue
		IFS=$'\t' read -r ssid bssid mode chan freq signal security inuse \
			<<<"$(printf '%s' "$raw" | net_wifi_parse_scan_row)"
		ssid=$(printf '%s' "$ssid" | net_unesc)
		bssid=$(printf '%s' "$bssid" | net_unesc)
		i=$((i+1))
		mark=""
		[ "$inuse" = "*" ] && mark="◄ 在用"
		if [ -z "$ssid" ]; then
			ssid="（隐藏网络）"
		elif [ -n "${saved[$ssid]:-}" ]; then
			mark="$mark 已保存"
		else
			:
		fi
		if [ "${freq:-0}" -ge 6000 ] 2>/dev/null; then band="6G";
		elif [ "${freq:-0}" -ge 5000 ] 2>/dev/null; then band="5G";
		else band="2.4G"; fi
		printf '%-3d %-2s %-26s %-5s %-4s %-7s %-16s %s\n' \
			"$i" "$inuse" "${ssid:0:26}" "$signal%" "$chan" "$band" "${security:-开放}" "$mark"
		_NET_SCAN+=("${ssid}"$'\t'"${security}"$'\t'"${bssid}")
	done <<<"$raw"
	net_hr
	net_info "共 ${#_NET_SCAN[@]} 个网络"
}

##################################### 状态展示 / 测试 ##############################

# 网卡状态详情
net_show_status() {
	local dev="$1" kind="$2"
	local -a v
	mapfile -t v < <(nmcli -g GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.HWADDR,GENERAL.MTU,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS dev show "$dev" 2>/dev/null | sed 's/ | /,/g')
	v[3]=$(printf '%s' "${v[3]:-}" | net_unesc)
	net_hr
	printf '网卡 %s（%s）\n' "${v[0]:-?}" "$kind"
	printf '  状态   : %s\n' "${v[2]:-?}"
	printf '  MAC    : %s\n' "${v[3]:-?}"
	printf '  MTU    : %s\n' "${v[4]:-?}"
	printf '  活动连接: %s\n' "${v[5]:-/}"
	printf '  IPv4   : %s\n' "${v[6]:-（无）}"
	printf '  网关   : %s\n' "${v[7]:-（无）}"
	printf '  DNS    : %s\n' "${v[8]:-（无）}"
	if [ "$kind" = ethernet ]; then
		if [ -r "/sys/class/net/$dev/speed" ]; then
			printf '  速率   : %s Mbps  双工: %s\n' \
				"$(cat "/sys/class/net/$dev/speed" 2>/dev/null)" \
				"$(cat "/sys/class/net/$dev/duplex" 2>/dev/null)"
		fi
		printf '  链路   : %s\n' "$(cat "/sys/class/net/$dev/carrier" 2>/dev/null | sed 's/^1$/已连接/; s/^0$/未插线/' || echo '?')"
	else
		local radio
		radio=$(nmcli -t -f WIFI general 2>/dev/null)
		printf '  WiFi 无线电: %s\n' "$radio"
		local sig
		sig=$(nmcli -t -f SIGNAL,IN-USE dev wifi list ifname "$dev" 2>/dev/null | awk -F: '$2=="*"{print $1}')
		[ -n "$sig" ] && printf '  信号强度: %s%%\n' "$sig"
	fi
	if [ -n "${v[5]:-}" ] && [ "${v[5]}" != "/" ]; then
		printf '  自动连接: %s   优先级: %s\n' \
			"$(net_con_val "${v[5]}" connection.autoconnect)" \
			"$(net_con_val "${v[5]}" connection.autoconnect-priority)"
	fi
	net_hr
}

# 列出配置文件（含优先级），按优先级降序
net_list_profiles() {
	local kind="$1" line name uuid dev ssid ts auto pri active
	printf '%-3s %-28s %-14s %-6s %-6s %s\n' "#" "名称/SSID" "网卡" "自动" "优先级" "状态/UUID"
	printf '%s\n' "------------------------------------------------------------------------------------------"
	local -a rows=()
	while IFS= read -r line; do
		uuid=$(printf '%s' "$line" | awk -F: '{print $(NF-2)}')
		dev=$(printf '%s' "$line" | awk -F: '{print $NF}')
		name=$(printf '%s' "$line" | sed 's/:[0-9a-f-]\{36\}:.*$//' | net_unesc)
		auto=$(net_con_val "$uuid" connection.autoconnect)
		pri=$(net_con_val "$uuid" connection.autoconnect-priority)
		ssid=""
		[ "$kind" = wifi ] && ssid=$(net_con_val "$uuid" 802-11-wireless.ssid)
		rows+=("${pri:-0}|$name|$ssid|$dev|$auto|$uuid")
	done < <(net_con_rows "$kind")
	local i=1
	while IFS='|' read -r pri name ssid dev auto uuid; do
		active=""
		[ -n "$dev" ] && [ "$(net_active_con "$dev" 2>/dev/null)" = "$name" ] && active="◄ 在用"
		local show="$name"
		[ -n "$ssid" ] && [ "$ssid" != "$name" ] && show="$name (SSID:$ssid)"
		printf '%-3d %-28s %-14s %-6s %-6s %s %s\n' \
			"$i" "$show" "${dev:-*}" "${auto#*}" "${pri:-0}" "$active" "$uuid"
		i=$((i+1))
	done < <(printf '%s\n' "${rows[@]}" | sort -t'|' -k1 -nr)
}

# 连通性测试
net_connectivity_test() {
	local dev="$1" gw ok=0
	gw=$(nmcli -g IP4.GATEWAY dev show "$dev" 2>/dev/null | head -1)
	net_section "连通性测试（$dev）"
	if [ -n "$gw" ]; then
		if ping -c 2 -W 2 -I "$dev" "$gw" >/dev/null 2>&1; then
			net_ok "网关 $gw 可达"; ok=$((ok+1))
		else
			net_warn "网关 $gw 不可达"
		fi
	else
		net_warn "当前没有默认网关"
	fi
	if ping -c 2 -W 2 -I "$dev" 223.5.5.5 >/dev/null 2>&1; then
		net_ok "外网 223.5.5.5 可达（IP 层正常）"; ok=$((ok+1))
	else
		net_warn "外网 223.5.5.5 不可达"
	fi
	if getent hosts www.baidu.com >/dev/null 2>&1; then
		net_ok "DNS 解析正常（www.baidu.com）"; ok=$((ok+1))
	else
		net_warn "DNS 解析失败（getent www.baidu.com）"
	fi
	net_hr
	[ "$ok" -eq 3 ] && net_ok "全部正常" || net_warn "$ok/3 项正常"
}

# 交互式收集手动 IP 参数，结果存入全局 NET_*
NET_IP_CIDR=""; NET_IP_GW=""; NET_IP_DNS=""; NET_IP_IGNORE="keep"
net_ask_static() {
	local dev="$1" uuid="${2:-}"
	local d_cidr="" d_gw="" d_dns=""
	if [ -n "$uuid" ]; then
		d_cidr=$(net_con_val "$uuid" ipv4.addresses | sed 's/,.*//')
		d_gw=$(net_con_val "$uuid" ipv4.gateway)
		[ -z "$d_gw" ] && d_gw=$(net_con_val "$uuid" ipv4.addresses | sed -n 's#.*/[0-9]*,##p')
		d_dns=$(net_con_val "$uuid" ipv4.dns)
	fi
	net_info "设置手动 IPv4（直接回车使用括号内默认值）"
	while true; do
		net_ask "  IP 地址/前缀，如 192.168.1.10/24" "$d_cidr"
		NET_IP_CIDR="$NET_ASK"
		if net_valid_cidr "$NET_IP_CIDR"; then break; fi
		net_warn "格式不正确，应为 IP/前缀（1-32）"
	done
	while true; do
		net_ask "  网关（无网关直接留空）" "$d_gw"
		NET_IP_GW="$NET_ASK"
		if [ -z "$NET_IP_GW" ]; then break; fi
		if net_valid_ip4 "$NET_IP_GW"; then
			net_warn_cross_subnet "$NET_IP_CIDR" "$NET_IP_GW"
			break
		fi
		net_warn "网关不是合法 IPv4 地址"
	done
	net_ask "  DNS（多个用逗号分隔，留空=不设置；输入 none=清除）" "$d_dns"
	case "$NET_ASK" in
		"") NET_IP_DNS="" ;;
		none|NONE) NET_IP_DNS="" ;;
		*) NET_IP_DNS=$(net_norm_dns "$NET_ASK") ;;
	esac
	NET_IP_IGNORE="keep"
	if [ -n "$NET_IP_DNS" ]; then
		if net_ask_yes "  是否忽略 DHCP/路由器自动下发的 DNS（只使用上面填写的）？" "y"; then
			NET_IP_IGNORE="yes"
		else
			NET_IP_IGNORE="no"
		fi
	fi
}
