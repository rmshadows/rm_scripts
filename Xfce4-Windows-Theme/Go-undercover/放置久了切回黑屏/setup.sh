#!/bin/bash
# 放置久了，KVM 切回来画面拉不起来。
# 一切就黑的那件事仍由 systweak 里的 HDMI udev 规则处理，本脚本不动它。
#
# 用法（桌面用户）：
#   sudo ./setup.sh
#   sudo ./setup.sh --undo
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
XORG_DEST=/etc/X11/xorg.conf.d/10-no-blank.conf
MARKER="managed-by-idle-blank-fix"

if [[ "${1:-}" == "--session" ]]; then
	shift
	action="${1:-apply}"
	if [[ "$(id -u)" -eq 0 ]]; then
		echo "会话设置不能用 root 写。" >&2
		exit 1
	fi
	if [[ "$action" == "undo" ]]; then
		rm -f "${HOME}/.config/autostart/zz-noblank.desktop"
		rm -f "${HOME}/.local/bin/no-blank.sh" "${HOME}/.local/bin/kvm-rescue.sh"
		pkill -f "${HOME}/.local/bin/no-blank.sh --loop" 2>/dev/null || true
		echo "已去掉 ${USER} 的自启动和救援脚本。"
		exit 0
	fi
	bin="${HOME}/.local/bin"
	mkdir -p "$bin" "${HOME}/.config/autostart"
	install -m 755 "$HERE/no-blank.sh" "$bin/no-blank.sh"
	install -m 755 "$HERE/kvm-rescue.sh" "$bin/kvm-rescue.sh"
	cat >"${HOME}/.config/autostart/zz-noblank.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=禁止屏幕涂黑
Comment=每 5 分钟关掉 X 屏保和 DPMS
Exec=${bin}/no-blank.sh --loop
OnlyShowIn=XFCE;
StartupNotify=false
X-GNOME-Autostart-enabled=true
# ${MARKER}
EOF
	if command -v xfconf-query >/dev/null 2>&1; then
		set_num() {
			local prop="$1" value="$2"
			if xfconf-query -c xfce4-power-manager -p "$prop" >/dev/null 2>&1; then
				xfconf-query -c xfce4-power-manager -p "$prop" -s "$value" >/dev/null
			else
				xfconf-query -c xfce4-power-manager -p "$prop" -n -t int -s "$value" >/dev/null \
					|| xfconf-query -c xfce4-power-manager -p "$prop" -n -t uint -s "$value" >/dev/null
			fi
		}
		set_bool() {
			local prop="$1" value="$2"
			if xfconf-query -c xfce4-power-manager -p "$prop" >/dev/null 2>&1; then
				xfconf-query -c xfce4-power-manager -p "$prop" -s "$value" >/dev/null
			else
				xfconf-query -c xfce4-power-manager -p "$prop" -n -t bool -s "$value" >/dev/null
			fi
		}
		set_num /xfce4-power-manager/blank-on-ac 0
		set_num /xfce4-power-manager/blank-on-battery 0
		set_num /xfce4-power-manager/dpms-on-ac-off 0
		set_num /xfce4-power-manager/dpms-on-ac-sleep 0
		set_num /xfce4-power-manager/dpms-on-battery-off 0
		set_num /xfce4-power-manager/dpms-on-battery-sleep 0
		set_num /xfce4-power-manager/inactivity-on-ac 0
		set_num /xfce4-power-manager/inactivity-on-battery 0
		set_bool /xfce4-power-manager/dpms-enabled false
		set_bool /xfce4-power-manager/lock-screen-suspend-hibernate false
		echo "已关掉 ${USER} 的 XFCE 熄屏和空闲睡眠。"
	else
		echo "没有 xfconf-query，跳过 XFCE 电源设置。"
	fi
	if command -v xset >/dev/null 2>&1; then
		"$bin/no-blank.sh" --once || echo "当前会话没能立刻关掉涂黑，登录 XFCE 后自启动会处理。"
	fi
	if ! pgrep -u "$USER" -f "$bin/no-blank.sh --loop" >/dev/null 2>&1; then
		nohup "$bin/no-blank.sh" --loop >/dev/null 2>&1 &
		echo "已开始每 5 分钟再关一次涂黑。"
	else
		echo "每 5 分钟再关一次的进程已在跑。"
	fi
	echo "黑了可手动跑：${bin}/kvm-rescue.sh"
	exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
	echo "请用 sudo 运行：" >&2
	echo "  sudo ./setup.sh" >&2
	exit 1
fi

target="${SUDO_USER:-}"
if [[ -z "$target" || "$target" == "root" ]]; then
	echo "请从桌面用户执行：sudo ./setup.sh" >&2
	echo "直接用 root 跑会把自启动写到 /root。" >&2
	exit 1
fi

undo=0
if [[ "${1:-}" == "--undo" ]]; then
	undo=1
fi

target_home=$(getent passwd "$target" | cut -d: -f6)
target_uid=$(id -u "$target")

run_session() {
	sudo -u "$target" env \
		HOME="$target_home" \
		USER="$target" \
		LOGNAME="$target" \
		DISPLAY="${DISPLAY:-:0}" \
		XAUTHORITY="${target_home}/.Xauthority" \
		XDG_RUNTIME_DIR="/run/user/${target_uid}" \
		DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${target_uid}/bus" \
		bash "$HERE/setup.sh" --session "$@"
}

if [[ "$undo" -eq 1 ]]; then
	if [[ -f "$XORG_DEST" ]] && grep -q "$MARKER" "$XORG_DEST"; then
		rm -f "$XORG_DEST"
		echo "已删除 $XORG_DEST"
	else
		echo "没有本脚本写的 $XORG_DEST"
	fi
	run_session undo
	echo "撤销完成。重新进入图形界面后，登录屏的涂黑设置才恢复。"
	exit 0
fi

mkdir -p /etc/X11/xorg.conf.d
if [[ -f "$XORG_DEST" ]] && cmp -s "$HERE/10-no-blank.conf" "$XORG_DEST"; then
	echo "X 涂黑配置已是这份，跳过。"
else
	install -m 644 "$HERE/10-no-blank.conf" "$XORG_DEST"
	echo "已写入 $XORG_DEST"
	echo "重新进入图形界面后，登录屏也不会再涂黑。"
fi

run_session apply
echo "完成。HDMI 热插拔那套 udev 规则没有改。"
