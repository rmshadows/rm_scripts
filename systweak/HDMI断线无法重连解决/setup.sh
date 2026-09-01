#!/usr/bin/env bash
# 可选：把本目录各文件安装到系统路径。也可以不跑本脚本，按 README 手动拷贝。
#   sudo ./setup.sh          安装（先预检；未通过会提示，仍可继续）
#   sudo ./setup.sh uninstall
#   ./setup.sh check         只预检，不安装
#   HDMI_HOTPLUG_SKIP_CHECK=1  跳过预检
#   HDMI_HOTPLUG_FORCE=1       预检未通过也不询问，直接装
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
LIB_DST=/usr/local/lib/hdmi-hotplug/hdmi-hotplug-lib.sh
BIN_RECOVER=/usr/local/bin/hdmi-hotplug-recover.sh
BIN_SAVE=/usr/local/bin/hdmi-hotplug-save.sh
BIN_TRIGGER=/usr/local/bin/hdmi-hotplug-trigger.sh
BIN_CHECK=/usr/local/bin/hdmi-hotplug-check.sh
SERVICE_DST=/etc/systemd/system/hdmi-hotplug-recover.service
UDEV_DST=/etc/udev/rules.d/99-hdmi-hotplug.rules
CONF_DST=/etc/hdmi-hotplug.conf

die() { echo "错误: $*" >&2; exit 1; }

desktop_user() {
	local s uid u t
	if [ -n "${SETUP_USER:-}" ]; then
		echo "$SETUP_USER"
		return 0
	fi
	if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
		echo "$SUDO_USER"
		return 0
	fi
	if command -v loginctl >/dev/null; then
		while read -r s uid u _; do
			t="$(loginctl show-session "$s" -p Type --value 2>/dev/null || true)"
			case "$t" in
			x11 | wayland)
				echo "$u"
				return 0
				;;
			esac
		done < <(loginctl list-sessions --no-legend 2>/dev/null || true)
	fi
	die "无法判断桌面用户。请：sudo SETUP_USER=你的用户名 $0"
}

run_precheck() {
	local rc=0
	"$HERE/hdmi-hotplug-check.sh" || rc=$?
	return "$rc"
}

confirm_install_anyway() {
	if [ "${HDMI_HOTPLUG_FORCE:-0}" = 1 ]; then
		echo "HDMI_HOTPLUG_FORCE=1，忽略预检结果，继续安装。"
		return 0
	fi
	if [ ! -t 0 ]; then
		die "预检未通过且非交互。要继续请：sudo HDMI_HOTPLUG_FORCE=1 $0"
	fi
	echo
	printf "仍要安装吗？安装后可能无效。[y/N] "
	local ans
	read -r ans
	case "$ans" in
	y | Y | yes | YES) return 0 ;;
	*) die "已取消安装" ;;
	esac
}

cmd_check() {
	exec "$HERE/hdmi-hotplug-check.sh" "$@"
}

cmd_install() {
	[ "$(id -u)" -eq 0 ] || die "需要 root：sudo $0"
	local u rc=0
	if [ "${HDMI_HOTPLUG_SKIP_CHECK:-0}" != 1 ]; then
		echo "安装前预检（HDMI_HOTPLUG_SKIP_CHECK=1 可跳过）："
		echo
		run_precheck || rc=$?
		echo
		case "$rc" in
		0)
			echo "预检通过，可以安装。"
			echo
			;;
		2)
			echo "预检未完全通过：自动热插拔可能无效，手动重置多半仍可用。"
			confirm_install_anyway
			echo
			;;
		*)
			echo "预检未通过：安装后可能无效（允许继续，但请看上面的失败项）。"
			confirm_install_anyway
			echo
			;;
		esac
	fi
	u="$(desktop_user)"
	id "$u" >/dev/null 2>&1 || die "用户不存在: $u"

	install -d /usr/local/lib/hdmi-hotplug
	install -m 0644 "$HERE/hdmi-hotplug-lib.sh" "$LIB_DST"
	install -m 0755 "$HERE/hdmi-hotplug-recover.sh" "$BIN_RECOVER"
	install -m 0755 "$HERE/hdmi-hotplug-save.sh" "$BIN_SAVE"
	install -m 0755 "$HERE/hdmi-hotplug-trigger.sh" "$BIN_TRIGGER"
	install -m 0755 "$HERE/hdmi-hotplug-check.sh" "$BIN_CHECK"
	sed "s/__DESKTOP_USER__/$u/g" "$HERE/hdmi-hotplug-recover.service" >"$SERVICE_DST"
	install -m 0644 "$HERE/99-hdmi-hotplug.rules" "$UDEV_DST"
	if [ ! -f "$CONF_DST" ]; then
		install -m 0644 "$HERE/hdmi-hotplug.conf" "$CONF_DST"
	fi
	mkdir -p /var/lib/hdmi-kvm-fix

	systemctl daemon-reload
	udevadm control --reload-rules 2>/dev/null || true

	echo "已安装（桌面用户=$u）："
	echo "  $UDEV_DST"
	echo "  $BIN_TRIGGER"
	echo "  $SERVICE_DST   (User=$u)"
	echo "  $BIN_RECOVER"
	echo "  $BIN_SAVE"
	echo "  $BIN_CHECK"
	echo "  $LIB_DST"
	echo "  $CONF_DST   （HDMI_HOTPLUG_RESET=0 可停用重置，不必卸载）"
	echo

	echo "正在以用户 $u 记录当前屏幕参数……"
	if sudo -u "$u" -H "$BIN_SAVE"; then
		echo "布局已写入该用户 ~/.config/hdmi-kvm-fix/layout.conf"
	else
		echo "警告：此刻未能记录（多半没有可用的 X11）。请稍后在桌面终端执行：$BIN_SAVE" >&2
	fi
	echo
	echo "停用热插拔重置（不卸载）：把 $CONF_DST 里 HDMI_HOTPLUG_RESET 改成 0"
	echo "临时手动重置（不受开关影响）： $BIN_RECOVER now"
	echo "日志： journalctl -t hdmi-hotplug -n 30 --no-pager"
}

cmd_uninstall() {
	[ "$(id -u)" -eq 0 ] || die "需要 root"
	rm -f "$UDEV_DST" "$BIN_TRIGGER" "$SERVICE_DST" "$BIN_RECOVER" "$BIN_SAVE" "$BIN_CHECK" "$LIB_DST"
	rmdir /usr/local/lib/hdmi-hotplug 2>/dev/null || true
	systemctl daemon-reload 2>/dev/null || true
	udevadm control --reload-rules 2>/dev/null || true
	echo "已卸载。未删除：$CONF_DST 、布局文件 /var/lib/hdmi-kvm-fix/ 与 ~/.config/hdmi-kvm-fix/"
}

case "${1:-install}" in
install | "") cmd_install ;;
uninstall) cmd_uninstall ;;
check)
	shift
	cmd_check "$@"
	;;
*)
	echo "用法: sudo $0 [install|uninstall]"
	echo "      $0 check [--wait-hotplug]"
	echo "指定用户: sudo SETUP_USER=alice $0"
	exit 1
	;;
esac
