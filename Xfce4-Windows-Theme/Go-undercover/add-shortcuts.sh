#!/bin/bash
# 把 config.sh 里打开的快捷键写进当前用户的 XFCE。可由 deploy.sh 调用，也可单独运行。
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$HERE/config.sh"

CHANNEL="xfce4-keyboard-shortcuts"
STAMP="${HOME}/.local/share/go-undercover/managed-shortcuts.txt"
WIN_DESKTOP="${HOME}/.config/autostart/xcape-whisker.desktop"

if [[ "$(id -u)" -eq 0 ]]; then
	echo "快捷键要写到桌面用户。请不要用 root 运行本脚本。" >&2
	echo "用桌面用户执行：sudo ./deploy.sh" >&2
	exit 1
fi

if [[ "${ADD_SHORTCUTS:-1}" != "1" ]]; then
	echo "快捷键总开关是关的，跳过。"
	exit 0
fi

if [[ -z "${DISPLAY:-}" ]]; then
	export DISPLAY=:0
fi
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
	uid=$(id -u)
	if [[ -S "/run/user/${uid}/bus" ]]; then
		export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus"
	fi
fi
if ! command -v xfconf-query >/dev/null 2>&1; then
	echo "没有 xfconf-query，跳过快捷键。" >&2
	exit 0
fi
bus="${DBUS_SESSION_BUS_ADDRESS:-}"
bus="${bus#unix:path=}"
if [[ -z "$bus" || ! -S "$bus" ]]; then
	echo "没有 XFCE 会话，跳过快捷键。登录图形界面后再运行一次。" >&2
	exit 0
fi

mkdir -p "$(dirname "$STAMP")" "${HOME}/.config/autostart"
: >"$STAMP"

have_cmd() {
	command -v "$1" >/dev/null 2>&1
}

is_bad_cmd() {
	case "$1" in
		*kylin-screenshot* | *"/home/ryan/"* | */home/ryan/* | i3lock-fancy | "i3lock-fancy "*)
			return 0
			;;
	esac
	return 1
}

remember() {
	printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$STAMP"
}

# 应用命令。$1 开关 $2 按键 $3 命令
apply_command() {
	local on="$1" key="$2" cmd="$3" bin prop cur
	prop="/commands/custom/${key}"
	cur=$(xfconf-query -c "$CHANNEL" -p "$prop" 2>/dev/null || true)
	if [[ "$on" != "1" ]]; then
		if [[ -n "$cur" && "$cur" == "$cmd" ]]; then
			xfconf-query -c "$CHANNEL" -p "$prop" -r >/dev/null
			echo "已关闭  ${key}"
		fi
		return 0
	fi
	bin=${cmd%% *}
	if ! have_cmd "$bin"; then
		echo "跳过    ${key}  （没有 ${bin}）"
		return 0
	fi
	if [[ -z "$cur" ]]; then
		xfconf-query -c "$CHANNEL" -p "$prop" -n -t string -s "$cmd" >/dev/null
		echo "已添加  ${key}  ->  ${cmd}"
		remember commands "$prop" "$cmd"
	elif [[ "$cur" == "$cmd" ]]; then
		echo "已正确  ${key}  ->  ${cmd}"
		remember commands "$prop" "$cmd"
	elif is_bad_cmd "$cur"; then
		xfconf-query -c "$CHANNEL" -p "$prop" -t string -s "$cmd" >/dev/null
		echo "已改正  ${key}  ->  ${cmd}  （原来是 ${cur}）"
		remember commands "$prop" "$cmd"
	else
		echo "保留    ${key}  （当前是 ${cur}）"
	fi
}

# xfwm4 动作。$1 开关 $2 按键 $3 动作名
apply_action() {
	local on="$1" key="$2" action="$3" prop cur
	prop="/xfwm4/custom/${key}"
	cur=$(xfconf-query -c "$CHANNEL" -p "$prop" 2>/dev/null || true)
	if [[ "$on" != "1" ]]; then
		if [[ -n "$cur" && "$cur" == "$action" ]]; then
			xfconf-query -c "$CHANNEL" -p "$prop" -r >/dev/null
			echo "已关闭  ${key}"
		fi
		return 0
	fi
	if [[ -z "$cur" ]]; then
		xfconf-query -c "$CHANNEL" -p "$prop" -n -t string -s "$action" >/dev/null
		echo "已添加  ${key}  ->  ${action}"
		remember xfwm4 "$prop" "$action"
	elif [[ "$cur" == "$action" ]]; then
		echo "已正确  ${key}  ->  ${action}"
		remember xfwm4 "$prop" "$action"
	else
		echo "保留    ${key}  （当前是 ${cur}）"
	fi
}

apply_win() {
	local prop="/commands/custom/<Primary>Escape" cur
	cur=$(xfconf-query -c "$CHANNEL" -p "$prop" 2>/dev/null || true)
	if [[ "${SHORTCUT_WIN:-1}" != "1" ]]; then
		if [[ -f "$WIN_DESKTOP" ]] && grep -q "managed-by-go-undercover" "$WIN_DESKTOP"; then
			rm -f "$WIN_DESKTOP"
			pkill -x xcape 2>/dev/null || true
			echo "已关闭  单击 Win"
		fi
		if [[ "$cur" == "xfce4-popup-whiskermenu" ]]; then
			xfconf-query -c "$CHANNEL" -p "$prop" -r >/dev/null
		fi
		return 0
	fi
	if ! have_cmd xcape || ! have_cmd xfce4-popup-whiskermenu; then
		echo "跳过    单击 Win  （没有 xcape 或 xfce4-popup-whiskermenu）"
		return 0
	fi
	if [[ -z "$cur" || "$cur" == "xfdesktop --menu" ]]; then
		xfconf-query -c "$CHANNEL" -p "$prop" -n -t string -s "xfce4-popup-whiskermenu" >/dev/null
		echo "已设置  单击 Win  ->  Whisker 菜单"
	elif [[ "$cur" == "xfce4-popup-whiskermenu" ]]; then
		echo "已正确  单击 Win  ->  Whisker 菜单"
	else
		echo "保留    Ctrl+Esc  （当前是 ${cur}），单击 Win 不改"
		return 0
	fi
	remember commands "$prop" "xfce4-popup-whiskermenu"
	cat >"$WIN_DESKTOP" <<'EOF'
[Desktop Entry]
Type=Application
Name=xcape Whisker Menu
Comment=单击 Win 打开 Whisker 菜单
Exec=xcape -e Super_L=Control_L|Escape
OnlyShowIn=XFCE;
StartupNotify=false
X-GNOME-Autostart-enabled=true
# managed-by-go-undercover
EOF
	remember xcape autostart 1
	if pgrep -x xcape >/dev/null 2>&1; then
		echo "已正确  xcape 已在运行"
	else
		nohup xcape -e 'Super_L=Control_L|Escape' >/dev/null 2>&1 &
		sleep 0.3
		if pgrep -x xcape >/dev/null 2>&1; then
			echo "已启动  xcape"
		else
			echo "xcape 没能启动。注销后再登录会由自启动拉起。" >&2
		fi
	fi
}

apply_command "${SHORTCUT_TERMINAL:-0}" "${SHORTCUT_TERMINAL_KEY}" "${SHORTCUT_TERMINAL_CMD}"
apply_command "${SHORTCUT_TERMINAL2:-0}" "${SHORTCUT_TERMINAL2_KEY}" "${SHORTCUT_TERMINAL2_CMD}"
apply_command "${SHORTCUT_FILES:-0}" "${SHORTCUT_FILES_KEY}" "${SHORTCUT_FILES_CMD}"
apply_command "${SHORTCUT_MONITOR:-0}" "${SHORTCUT_MONITOR_KEY}" "${SHORTCUT_MONITOR_CMD}"
apply_command "${SHORTCUT_BROWSER:-0}" "${SHORTCUT_BROWSER_KEY}" "${SHORTCUT_BROWSER_CMD}"
apply_command "${SHORTCUT_SHOT:-0}" "${SHORTCUT_SHOT_KEY}" "${SHORTCUT_SHOT_CMD}"
apply_command "${SHORTCUT_LOCK:-0}" "${SHORTCUT_LOCK_KEY}" "${SHORTCUT_LOCK_CMD}"
apply_command "${SHORTCUT_FINDER:-0}" "${SHORTCUT_FINDER_KEY}" "${SHORTCUT_FINDER_CMD}"
apply_command "${SHORTCUT_MENU:-0}" "${SHORTCUT_MENU_KEY}" "${SHORTCUT_MENU_CMD}"
apply_action "${SHORTCUT_DESKTOP:-0}" "${SHORTCUT_DESKTOP_KEY}" "${SHORTCUT_DESKTOP_ACTION}"
apply_win
