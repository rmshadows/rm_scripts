#!/usr/bin/env bash
# 安装前预检：X11 / xrandr / DRM / udev 热插拔是否像能用。
# 不改系统、不重置屏幕。
#
#   ./hdmi-hotplug-check.sh
#   ./hdmi-hotplug-check.sh --wait-hotplug     # 再等一次真实 KVM/HDMI 热插拔
#   sudo ./setup.sh check
#
# 退出码：0 通过；2 有警告（尤其是未能确认 udev HOTPLUG）；1 有失败项（装了也可能无效）

set -u
export LC_ALL=C

HERE="$(cd "$(dirname "$0")" && pwd)"
WAIT_SECS=0
n_ok=0
n_warn=0
n_fail=0

usage() {
	cat <<'EOF'
用法: hdmi-hotplug-check.sh [--wait-hotplug] [--wait-hotplug=秒]

静态检查 X11、xrandr、DRM、systemd/udev。
--wait-hotplug  再监听 udev drm 事件（默认 25 秒），请在期间切换一次 KVM。

退出码: 0 通过  2 警告  1 失败（仍允许 setup 继续装，但会提示）
EOF
}

for arg in "$@"; do
	case "$arg" in
	-h | --help)
		usage
		exit 0
		;;
	--wait-hotplug)
		WAIT_SECS="${HDMI_HOTPLUG_WAIT_SECS:-25}"
		;;
	--wait-hotplug=*)
		WAIT_SECS="${arg#*=}"
		;;
	*)
		echo "未知参数: $arg" >&2
		usage >&2
		exit 1
		;;
	esac
done
case "$WAIT_SECS" in
'' | *[!0-9]*)
	echo "错误: --wait-hotplug 秒数必须是整数" >&2
	exit 1
	;;
esac

for _lib in "$HERE/hdmi-hotplug-lib.sh" /usr/local/lib/hdmi-hotplug/hdmi-hotplug-lib.sh; do
	if [ -f "$_lib" ]; then
		# shellcheck source=/dev/null
		. "$_lib"
		break
	fi
done
type have >/dev/null 2>&1 || {
	echo "找不到 hdmi-hotplug-lib.sh" >&2
	exit 1
}

ok() { echo "  [通过] $*"; n_ok=$((n_ok + 1)); }
note() { echo "  [提示] $*"; }
warn() { echo "  [警告] $*"; n_warn=$((n_warn + 1)); }
fail() { echo "  [失败] $*"; n_fail=$((n_fail + 1)); }

target_user() {
	if [ -n "${SETUP_USER:-}" ]; then
		echo "$SETUP_USER"
		return 0
	fi
	if [ "$(id -u)" -eq 0 ]; then
		if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
			echo "$SUDO_USER"
			return 0
		fi
		graphical_user 2>/dev/null && return 0
		echo "root"
		return 0
	fi
	id -un
}

session_type_of() {
	local user="$1" s _uid u typ saw=
	have loginctl || return 1
	while read -r s _uid u _; do
		[ "$u" = "$user" ] || continue
		typ="$(loginctl show-session "$s" -p Type --value 2>/dev/null || true)"
		case "$typ" in
		x11)
			echo x11
			return 0
			;;
		wayland)
			saw=wayland
			;;
		esac
	done < <(loginctl list-sessions --no-legend 2>/dev/null || true)
	[ -n "$saw" ] && echo "$saw" && return 0
	return 1
}

echo "=== HDMI/KVM 预检 ==="
u="$(target_user)"
echo "检查对象用户: $u  (当前 $(id -un))"
echo

# --- 基础 ---
if [ "$(uname -s)" = Linux ]; then
	ok "操作系统是 Linux"
else
	fail "不是 Linux（$(uname -s)）。这套脚本只针对 Linux + KVM 黑屏。"
fi

if [ -d /run/systemd/system ] && have systemctl; then
	ok "systemd 可用（udev 自动恢复靠 systemctl start）"
else
	fail "没有 systemd。热插拔自动恢复不会跑；最多还能手跑 recover.sh now"
fi

if have udevadm; then
	if pgrep -x systemd-udevd >/dev/null 2>&1 || pgrep -x udevd >/dev/null 2>&1; then
		ok "udev 在跑（udevadm）"
	else
		warn "有 udevadm，但没看到 udevd 进程"
	fi
else
	fail "没有 udevadm。无法用 DRM HOTPLUG 自动触发恢复"
fi

# --- DRM ---
if [ -d /sys/class/drm ]; then
	conn=""
	connected_sys=0
	for p in /sys/class/drm/card*-*; do
		[ -e "$p" ] || continue
		[ -f "$p/status" ] || continue
		st="$(cat "$p/status" 2>/dev/null || true)"
		bn="$(basename "$p")"
		conn="${conn}${conn:+, }${bn}=${st}"
		[ "$st" = connected ] && connected_sys=$((connected_sys + 1))
	done
	if [ -n "$conn" ]; then
		ok "内核 DRM 连接口: $conn"
		[ "$connected_sys" -gt 0 ] || warn "DRM 里目前没有 status=connected 的口（可能已切走 KVM，或驱动没报连接）"
	else
		fail "有 /sys/class/drm 但没有 card*-* 连接口。内核可能没走 DRM，udev 规则对不上"
	fi
else
	fail "没有 /sys/class/drm。udev 规则 SUBSYSTEM=drm 不会触发"
fi

if have lsmod && lsmod 2>/dev/null | grep -q '^nvidia '; then
	if lsmod 2>/dev/null | grep -q '^nvidia_drm '; then
		ok "NVIDIA 专有驱动带 nvidia_drm（有机会报 DRM 热插拔）"
	else
		warn "已加载 nvidia，但没有 nvidia_drm。KVM 切回时内核常常不发 HOTPLUG=1，自动恢复可能无效"
	fi
fi

# --- 会话 / xrandr ---
if have xrandr || [ -x /usr/bin/xrandr ]; then
	ok "已安装 xrandr"
else
	fail "没有 xrandr（Debian 包名 x11-xserver-utils）。save / recover 都依赖它"
fi

st="$(session_type_of "$u" || true)"
case "$st" in
x11)
	ok "图形会话是 X11（用户 $u）"
	;;
wayland)
	fail "图形会话是 Wayland。xrandr 管不到真实输出；请改用 GNOME on Xorg / Xfce / Fluxbox。装了也多半无效"
	;;
*)
	if [ -n "${XDG_SESSION_TYPE:-}" ]; then
		if [ "$XDG_SESSION_TYPE" = x11 ]; then
			ok "当前 XDG_SESSION_TYPE=x11"
		elif [ "$XDG_SESSION_TYPE" = wayland ]; then
			fail "当前 XDG_SESSION_TYPE=wayland。xrandr 管不到真实输出"
		else
			warn "会话类型不明（XDG_SESSION_TYPE=${XDG_SESSION_TYPE}）。请在已登录的 X11 桌面再跑一次预检"
		fi
	else
		warn "现在看不到图形会话（SSH/TTY 很常见）。请在桌面终端再跑一次；否则无法确认 X11"
	fi
	;;
esac

xr="$(xrandr_bin)"
if [ -n "$xr" ]; then
	if [ "$(id -u)" -eq 0 ] && [ "$u" != root ]; then
		setup_x11_env "$u" >/dev/null 2>&1 || true
	else
		setup_x11_env >/dev/null 2>&1 || true
	fi
	if [ -z "${DISPLAY:-}" ]; then
		fail "找不到 DISPLAY。recover.sh now 也连不上这台机的 X"
	elif q="$("$xr" --query 2>&1)"; then
		outs="$(printf '%s\n' "$q" | awk '/ connected/{print $1}' | tr '\n' ' ')"
		outs="${outs%" "}"
		if [ -n "$outs" ]; then
			ok "xrandr 能查询（DISPLAY=${DISPLAY}）：$outs"
		else
			fail "xrandr 能跑，但没有 connected 输出。KVM 若已切走，请切回后再预检/save"
		fi
	else
		fail "xrandr --query 失败（DISPLAY=${DISPLAY:-?}）。本机 X11 权限或会话不对，安装后可能无效"
		printf '%s\n' "$q" | sed 's/^/           /' | head -n 8
	fi
fi

# --- 历史 HOTPLUG（不能代替真切一次 KVM）---
hotplug_hist=0
if have journalctl; then
	if journalctl -k -b --no-pager 2>/dev/null | grep -qiE 'drm.*hotplug|[hH]otplug.*drm'; then
		hotplug_hist=1
	fi
fi
if [ "$hotplug_hist" -eq 0 ] && have dmesg; then
	if dmesg 2>/dev/null | grep -qiE 'drm.*hotplug|[hH]otplug.*drm'; then
		hotplug_hist=1
	fi
fi
if [ "$hotplug_hist" -eq 1 ]; then
	ok "本机内核日志里出现过 drm hotplug（驱动会报热插拔；不保证每次 KVM 都报）"
elif [ "$WAIT_SECS" -eq 0 ]; then
	note "静态检查无法证明 KVM 切回时 udev 会发 HOTPLUG=1。"
	echo "           要实锤： $0 --wait-hotplug    然后在倒计时内切换一次 KVM"
	echo "           或：     udevadm monitor --property --subsystem-match=drm"
fi

# --- 可选：等一次真事件 ---
if [ "$WAIT_SECS" -gt 0 ] 2>/dev/null; then
	if ! have udevadm; then
		fail "--wait-hotplug 需要 udevadm"
	else
		echo
		echo "  请在 ${WAIT_SECS} 秒内切换一次 KVM（或拔插 HDMI）……"
		tmp="$(mktemp)"
		udevadm monitor --udev --property --subsystem-match=drm >"$tmp" 2>/dev/null &
		mon_pid=$!
		slept=0
		caught=0
		while [ "$slept" -lt "$WAIT_SECS" ]; do
			if grep -q '^HOTPLUG=1' "$tmp" 2>/dev/null; then
				caught=1
				break
			fi
			sleep 1
			slept=$((slept + 1))
		done
		kill "$mon_pid" 2>/dev/null || true
		wait "$mon_pid" 2>/dev/null || true
		if [ "$caught" -eq 1 ]; then
			ok "捕获到 udev：SUBSYSTEM=drm 且 HOTPLUG=1（自动恢复路径预期可触发）"
		else
			warn "${WAIT_SECS} 秒内没有 HOTPLUG=1。若你确实切换了 KVM，则自动恢复安装后可能无效；手动 recover.sh now 仍可能有用"
		fi
		rm -f "$tmp"
	fi
fi

echo
echo "--- 结论 ---"
if [ "$n_fail" -gt 0 ]; then
	echo "未通过：有 ${n_fail} 项失败、${n_warn} 项警告、${n_ok} 项通过。"
	echo "可以继续安装，但安装后很可能无效（尤其是自动热插拔）。"
	echo "若只是 Wayland / 没 DISPLAY：先改 Xorg 再装；若只是没捕获 HOTPLUG：手动 now 有时仍能救黑屏。"
	exit 1
fi
if [ "$n_warn" -gt 0 ]; then
	echo "部分通过：${n_ok} 项通过、${n_warn} 项警告。"
	echo "手动 hdmi-hotplug-recover.sh now 预期可用（前提是上面 xrandr 已通过）。"
	echo "KVM 自动恢复未经确认，装了也可能不会在切回时触发。允许安装，但请心里有数。"
	exit 2
fi
echo "通过：可以安装。X11 手动重置（recover.sh now）预期可用。"
echo "udev 自动恢复具备 DRM 条件；是否每次 KVM 都报警，请再跑 --wait-hotplug 实锤。"
echo "装完后画面正常时再 save 一次布局。"
exit 0
