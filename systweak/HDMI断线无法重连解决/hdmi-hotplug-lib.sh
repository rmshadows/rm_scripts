#!/usr/bin/env bash
# 被 save.sh / recover.sh 引用：探测 X11、读写布局、xrandr off→on。
# 不要单独装到 udev。GNOME 请用 Xorg；Xfce / Fluxbox 即可。

PROG=hdmi-hotplug
VERSION=1
SYS_LAYOUT=/var/lib/hdmi-kvm-fix/layout.conf
USER_LAYOUT="${XDG_CONFIG_HOME:-${HOME:-/tmp}/.config}/hdmi-kvm-fix/layout.conf"
LOCK=/tmp/hdmi-hotplug-recover.lock
CONF=/etc/hdmi-hotplug.conf

log() { logger -t "$PROG" -- "$*" 2>/dev/null || true; echo "$*"; }
die() { echo "错误: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# /etc/hdmi-hotplug.conf 里 HDMI_HOTPLUG_RESET=0 则跳过 xrandr（无需卸 udev）
hotplug_reset_enabled() {
	if [ -f "$CONF" ] && grep -q '^[[:space:]]*HDMI_HOTPLUG_RESET=0' "$CONF"; then
		return 1
	fi
	return 0
}

xrandr_bin() {
	if [ -x /usr/bin/xrandr ]; then
		echo /usr/bin/xrandr
	elif have xrandr; then
		command -v xrandr
	else
		echo ""
	fi
}

layout_path() {
	if [ -f "$SYS_LAYOUT" ]; then
		echo "$SYS_LAYOUT"
	elif [ -f "$USER_LAYOUT" ]; then
		echo "$USER_LAYOUT"
	else
		echo ""
	fi
}

graphical_user() {
	local s uid u typ
	if have loginctl; then
		while read -r s uid u _; do
			typ="$(loginctl show-session "$s" -p Type --value 2>/dev/null || true)"
			case "$typ" in
			x11 | wayland)
				echo "$u"
				return 0
				;;
			esac
		done < <(loginctl list-sessions --no-legend 2>/dev/null || true)
	fi
	[ -n "${SUDO_USER:-}" ] && echo "$SUDO_USER" && return 0
	return 1
}

setup_x11_env() {
	local user uid sid typ disp auth pid envf
	user="${SUDO_USER:-${USER:-$(id -un)}}"
	if [ "$(id -u)" -eq 0 ] && [ -n "${1:-}" ]; then
		user="$1"
	elif [ "$(id -u)" -eq 0 ]; then
		user="$(graphical_user || true)"
	fi
	[ -n "$user" ] || return 1
	uid="$(id -u "$user" 2>/dev/null)" || return 1

	if [ -n "${DISPLAY:-}" ] && [ -n "${XAUTHORITY:-}" ] && [ -e "${XAUTHORITY:-}" ]; then
		return 0
	fi

	sid=""
	if have loginctl; then
		while read -r s _uid _u _; do
			[ "$_u" = "$user" ] || continue
			typ="$(loginctl show-session "$s" -p Type --value 2>/dev/null || true)"
			if [ "$typ" = "x11" ]; then
				sid="$s"
				break
			fi
			if [ -z "$sid" ]; then
				case "$typ" in
				wayland | mir) sid="$s" ;;
				esac
			fi
		done < <(loginctl list-sessions --no-legend 2>/dev/null || true)
		if [ -n "$sid" ]; then
			disp="$(loginctl show-session "$sid" -p Display --value 2>/dev/null || true)"
			typ="$(loginctl show-session "$sid" -p Type --value 2>/dev/null || true)"
			if [ "$typ" = "wayland" ] && [ -z "${ALLOW_WAYLAND:-}" ]; then
				log "当前是 Wayland。请改用 GNOME on Xorg / Xfce / Fluxbox。仍尝试 Xwayland。"
			fi
			[ -n "$disp" ] && [ "$disp" != "-" ] && DISPLAY="$disp"
		fi
	fi

	pid=""
	if have pgrep; then
		pid="$(pgrep -u "$uid" -n gnome-session 2>/dev/null || true)"
		[ -n "$pid" ] || pid="$(pgrep -u "$uid" -n xfce4-session 2>/dev/null || true)"
		[ -n "$pid" ] || pid="$(pgrep -u "$uid" -n fluxbox 2>/dev/null || true)"
		[ -n "$pid" ] || pid="$(pgrep -u "$uid" -n openbox 2>/dev/null || true)"
		[ -n "$pid" ] || pid="$(pgrep -u "$uid" -n xfwm4 2>/dev/null || true)"
		[ -n "$pid" ] || pid="$(pgrep -u "$uid" -n mutter 2>/dev/null || true)"
		[ -n "$pid" ] || pid="$(pgrep -u "$uid" -n Xorg 2>/dev/null | head -n1 || true)"
	fi
	if [ -n "$pid" ] && [ -r "/proc/$pid/environ" ]; then
		envf="$(tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null || true)"
		if [ -z "${DISPLAY:-}" ]; then
			disp="$(printf '%s\n' "$envf" | sed -n 's/^DISPLAY=//p' | head -n1)"
			[ -n "$disp" ] && DISPLAY="$disp"
		fi
		auth="$(printf '%s\n' "$envf" | sed -n 's/^XAUTHORITY=//p' | head -n1)"
		if [ -n "$auth" ] && [ -e "$auth" ]; then
			XAUTHORITY="$auth"
		fi
	fi

	if [ -z "${DISPLAY:-}" ]; then
		if [ -e /tmp/.X11-unix/X0 ]; then
			DISPLAY=:0
		elif [ -e /tmp/.X11-unix/X1 ]; then
			DISPLAY=:1
		fi
	fi

	if [ -z "${XAUTHORITY:-}" ] || [ ! -e "${XAUTHORITY:-}" ]; then
		for auth in \
			"/run/user/$uid/gdm/Xauthority" \
			"/run/user/$uid/Xauthority" \
			"/home/$user/.Xauthority"; do
			if [ -e "$auth" ]; then
				XAUTHORITY="$auth"
				break
			fi
		done
		if [ -z "${XAUTHORITY:-}" ] || [ ! -e "${XAUTHORITY:-}" ]; then
			auth="$(ls -1 /run/user/"$uid"/.mutter-Xwaylandauth.* 2>/dev/null | head -n1 || true)"
			[ -n "$auth" ] && [ -e "$auth" ] && XAUTHORITY="$auth"
		fi
	fi

	export DISPLAY="${DISPLAY:-:0}"
	[ -n "${XAUTHORITY:-}" ] && export XAUTHORITY
	[ -n "${DISPLAY:-}" ]
}

parse_and_save() {
	local xr out dest="$1"
	xr="$(xrandr_bin)"
	[ -n "$xr" ] || die "未找到 xrandr（包名 x11-xserver-utils）"
	setup_x11_env || die "找不到 X11 会话（DISPLAY/XAUTHORITY）"
	mkdir -p "$(dirname "$dest")"

	"$xr" --query >/tmp/hdmi-hotplug.xrandr 2>/dev/null || die "xrandr --query 失败 DISPLAY=$DISPLAY"

	{
		echo "# $PROG layout v$VERSION"
		echo "# generated=$(date -Iseconds 2>/dev/null || date)"
		echo "# DISPLAY=$DISPLAY"
		echo "# user=$(id -un)"
	} >"$dest"

	out=""
	local primary=0 mode="" pos="" rotate=normal rate=""
	flush() {
		if [ -n "$out" ] && [ -n "$mode" ]; then
			printf 'OUTPUT name=%s primary=%s mode=%s rate=%s pos=%s rotate=%s\n' \
				"$out" "$primary" "$mode" "$rate" "$pos" "$rotate" >>"$dest"
		fi
		out=""
		primary=0
		mode=""
		pos=""
		rotate=normal
		rate=""
	}

	while IFS= read -r line || [ -n "$line" ]; do
		if [[ "$line" =~ ^([^[:space:]]+)[[:space:]]+connected ]]; then
			flush
			out="${BASH_REMATCH[1]}"
			primary=0
			[[ "$line" == *" primary "* ]] && primary=1
			if [[ "$line" =~ ([0-9]+x[0-9]+)\+([0-9]+)\+([0-9]+) ]]; then
				mode="${BASH_REMATCH[1]}"
				pos="${BASH_REMATCH[2]}x${BASH_REMATCH[3]}"
			fi
			rotate=normal
			geom="${line%%(*}"
			if [[ "$geom" =~ [[:space:]](left|right|inverted)[[:space:]]*$ ]] ||
				[[ "$geom" =~ [[:space:]](left|right|inverted)[[:space:]] ]]; then
				rotate="${BASH_REMATCH[1]}"
			fi
		elif [[ "$line" =~ ^([^[:space:]]+)[[:space:]]+disconnected ]]; then
			flush
		elif [ -n "$out" ] && [[ "$line" =~ ^[[:space:]]+([0-9]+x[0-9]+)[[:space:]] ]]; then
			if [[ "$line" == *"*"* ]]; then
				mode="${BASH_REMATCH[1]}"
				rate="$(printf '%s\n' "$line" | grep -oE '[0-9]+\.[0-9]+\*|[0-9]+\*' | head -n1 | tr -d '*+')"
			fi
		fi
	done </tmp/hdmi-hotplug.xrandr
	flush
	rm -f /tmp/hdmi-hotplug.xrandr

	if ! grep -q '^OUTPUT ' "$dest"; then
		die "没有已连接输出。请在画面正常时于图形会话执行 save。"
	fi
	log "已保存布局: $dest"
	grep '^OUTPUT ' "$dest"
}

cmd_save() {
	local dest
	if [ "$(id -u)" -eq 0 ]; then
		mkdir -p "$(dirname "$SYS_LAYOUT")"
		dest="$SYS_LAYOUT"
	else
		mkdir -p "$(dirname "$USER_LAYOUT")"
		dest="$USER_LAYOUT"
	fi
	parse_and_save "$dest"
}

connected_names() {
	local xr
	xr="$(xrandr_bin)"
	"$xr" --query 2>/dev/null | awk '/ connected/{print $1}'
}

restore_auto() {
	local xr n
	local -a names=() offs=() ons=()
	xr="$(xrandr_bin)"
	while IFS= read -r n; do
		[ -n "$n" ] && names+=("$n")
	done < <(connected_names)
	if [ ${#names[@]} -eq 0 ]; then
		die "xrandr 无 connected 输出。DISPLAY=$DISPLAY XAUTHORITY=${XAUTHORITY:-}"
	fi
	for n in "${names[@]}"; do
		offs+=(--output "$n" --off)
		ons+=(--output "$n" --auto)
	done
	log "无可用布局，off → auto: ${names[*]}"
	"$xr" "${offs[@]}" || true
	sleep 1
	"$xr" "${ons[@]}"
}

restore_from_file() {
	local xr f="$1" name primary mode rate pos rotate
	local -a offs=() ons=()
	xr="$(xrandr_bin)"
	[ -n "$xr" ] || die "未找到 xrandr"

	while IFS= read -r rec || [ -n "$rec" ]; do
		[[ "$rec" == OUTPUT* ]] || continue
		name="$(echo "$rec" | sed -n 's/.*name=\([^ ]*\).*/\1/p')"
		primary="$(echo "$rec" | sed -n 's/.*primary=\([^ ]*\).*/\1/p')"
		mode="$(echo "$rec" | sed -n 's/.*mode=\([^ ]*\).*/\1/p')"
		rate="$(echo "$rec" | sed -n 's/.*rate=\([^ ]*\).*/\1/p')"
		pos="$(echo "$rec" | sed -n 's/.*pos=\([^ ]*\).*/\1/p')"
		rotate="$(echo "$rec" | sed -n 's/.*rotate=\([^ ]*\).*/\1/p')"
		[ -n "$name" ] || continue
		if ! "$xr" --query 2>/dev/null | grep -q "^${name} connected"; then
			log "跳过未连接: $name"
			continue
		fi
		offs+=(--output "$name" --off)
		ons+=(--output "$name")
		if [ -n "$mode" ]; then
			ons+=(--mode "$mode")
		else
			ons+=(--auto)
		fi
		[ -n "$rate" ] && ons+=(--rate "$rate")
		[ -n "$pos" ] && ons+=(--pos "$pos")
		[ -n "$rotate" ] && ons+=(--rotate "$rotate")
		[ "$primary" = 1 ] && ons+=(--primary)
	done <"$f"

	if [ ${#offs[@]} -eq 0 ]; then
		log "布局中的输出当前都未连接，改用 --auto"
		restore_auto
		return
	fi
	log "xrandr off"
	"$xr" "${offs[@]}" || true
	sleep 1
	log "xrandr on（按布局）"
	if ! "$xr" "${ons[@]}"; then
		log "按布局失败，回退 --auto"
		restore_auto
	fi
}

cmd_restore() {
	local xr f
	xr="$(xrandr_bin)"
	[ -n "$xr" ] || die "未找到 xrandr"
	setup_x11_env "${1:-}" || die "找不到 X11 会话"
	f="$(layout_path)"
	if [ -n "$f" ]; then
		log "使用布局 $f"
		restore_from_file "$f"
	else
		restore_auto
	fi
	log "restore 完成"
}

cmd_recover() {
	if ! hotplug_reset_enabled; then
		log "HDMI_HOTPLUG_RESET=0，跳过 xrandr（改 $CONF 为 1 可再启用）"
		exit 0
	fi
	exec 9>"$LOCK"
	if have flock; then
		flock -n 9 || exit 0
	fi
	sleep "${HDMI_KVM_SETTLE:-2}"
	cmd_restore "${1:-}"
}

cmd_doctor() {
	local f xr
	echo "=== $PROG doctor ==="
	echo "user=$(id -un) uid=$(id -u)"
	echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"
	setup_x11_env 2>/dev/null || true
	echo "DISPLAY=${DISPLAY:-}"
	echo "XAUTHORITY=${XAUTHORITY:-}"
	echo "xrandr=$(xrandr_bin)"
	f="$(layout_path)"
	echo "layout=${f:-无}"
	if [ -f "$CONF" ]; then
		echo "conf=$CONF $(grep -E '^[[:space:]]*HDMI_HOTPLUG_RESET=' "$CONF" | tail -n1)"
	else
		echo "conf=无（默认启用重置）"
	fi
	if have loginctl; then
		echo "--- sessions ---"
		loginctl list-sessions --no-legend 2>/dev/null || true
	fi
	xr="$(xrandr_bin)"
	if [ -n "$xr" ]; then
		echo "--- xrandr --query ---"
		"$xr" --query 2>&1 || true
	fi
}
