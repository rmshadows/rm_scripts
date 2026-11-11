#!/bin/bash
# 卸掉 deploy.sh 装进系统的主题和本工具写过的快捷键。
# 不卸载 xfce4。REMOVE_PACKAGES=1 时只删除 config.sh 里的 EXTRA_PACKAGES。
# 用法：sudo ./uninstall.sh
# 必须从桌面用户 sudo 上来，才能清掉这个用户会话里的快捷键。
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$HERE/config.sh"

STAMP_REL=".local/share/go-undercover/managed-shortcuts.txt"
WIN_REL=".config/autostart/xcape-whisker.desktop"
CHANNEL="xfce4-keyboard-shortcuts"

remove_path() {
	local target="$1" desc="$2"
	if [[ -e "$target" ]]; then
		rm -rf "$target"
		echo "已删除  ${desc}"
	else
		echo "没有    ${desc}"
	fi
}

session_remove() {
	local stamp="${HOME}/${STAMP_REL}" win="${HOME}/${WIN_REL}"
	if [[ -z "${DISPLAY:-}" ]]; then
		export DISPLAY=:0
	fi
	if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
		export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
	fi
	if [[ -x /usr/bin/go-undercover && -f "${HOME}/.local/share/go-undercover/lock" ]]; then
		if [[ -S "/run/user/$(id -u)/bus" ]]; then
			/usr/bin/go-undercover --disable || true
			echo "已恢复打开 Windows 外观之前的桌面。"
		else
			echo "Windows 外观还开着，但当前没有图形会话，没法自动恢复。登录后再运行一次 ./uninstall.sh。" >&2
		fi
	fi
	if [[ -f "$stamp" && -S "/run/user/$(id -u)/bus" ]] && command -v xfconf-query >/dev/null 2>&1; then
		while IFS=$'\t' read -r kind prop val; do
			[[ -z "${kind:-}" ]] && continue
			case "$kind" in
				commands | xfwm4)
					cur=$(xfconf-query -c "$CHANNEL" -p "$prop" 2>/dev/null || true)
					if [[ "$cur" == "$val" ]]; then
						xfconf-query -c "$CHANNEL" -p "$prop" -r >/dev/null
						echo "已去掉快捷键  ${prop}"
					else
						echo "保留快捷键  ${prop}  （已经改成别的）"
					fi
					;;
				xcape)
					if [[ -f "$win" ]] && grep -q "managed-by-go-undercover" "$win"; then
						rm -f "$win"
						pkill -x xcape 2>/dev/null || true
						echo "已去掉单击 Win"
					fi
					;;
			esac
		done <"$stamp"
		rm -f "$stamp"
	elif [[ -f "$stamp" ]]; then
		echo "快捷键记录还在，当前没有图形会话。登录后再运行一次 ./uninstall.sh 才会清掉。"
	fi
	rm -f "${HOME}/.local/share/go-undercover/deploy.state"
}

if [[ "${1:-}" == "--session" ]]; then
	session_remove
	exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
	echo "请用 sudo 运行：" >&2
	echo "  sudo ./uninstall.sh" >&2
	exit 1
fi

target="${SUDO_USER:-}"
if [[ -z "$target" || "$target" == "root" ]]; then
	echo "请从桌面用户执行：sudo ./uninstall.sh" >&2
	echo "直接用 root 跑清不到你会话里的配置。" >&2
	exit 1
fi

target_home=$(getent passwd "$target" | cut -d: -f6)
target_uid=$(id -u "$target")
sudo -u "$target" env \
	HOME="$target_home" \
	USER="$target" \
	LOGNAME="$target" \
	DISPLAY="${DISPLAY:-:0}" \
	XAUTHORITY="${target_home}/.Xauthority" \
	XDG_RUNTIME_DIR="/run/user/${target_uid}" \
	DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${target_uid}/bus" \
	bash "$HERE/uninstall.sh" --session

remove_path /usr/share/themes/Windows-10 "Windows-10 主题"
remove_path /usr/share/icons/Windows-10-Icons "Windows-10 图标"
remove_path /usr/share/go-undercover "go-undercover 数据"
remove_path /usr/bin/go-undercover "go-undercover 命令"
remove_path /usr/share/icons/go-undercover.svg "图标"
remove_path /usr/share/applications/go-undercover.desktop "菜单项"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
	gtk-update-icon-cache /usr/share/icons >/dev/null 2>&1 || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi

if [[ "${REMOVE_PACKAGES}" == "1" ]]; then
	echo "正在删除额外软件包：${EXTRA_PACKAGES}"
	apt-get remove -y $EXTRA_PACKAGES
else
	echo "软件包保留。要连 xcape、i3lock、flameshot 一起删，把 config.sh 里的 REMOVE_PACKAGES 改成 1 再运行。"
fi

echo "卸载完成。xfce4 本身还在。"
