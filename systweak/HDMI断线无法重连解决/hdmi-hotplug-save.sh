#!/usr/bin/env bash
# 画面正常时记录当前 xrandr 布局（输出名、分辨率、刷新率、位置、主屏、旋转）。
# 用法：在桌面终端执行  ./hdmi-hotplug-save.sh
#       诊断：           ./hdmi-hotplug-save.sh doctor
# 布局：~/.config/hdmi-kvm-fix/layout.conf ；sudo 则写 /var/lib/hdmi-kvm-fix/layout.conf

set -u
export LC_ALL=C

for _lib in "$(cd "$(dirname "$0")" && pwd)/hdmi-hotplug-lib.sh" \
	/usr/local/lib/hdmi-hotplug/hdmi-hotplug-lib.sh; do
	if [ -f "$_lib" ]; then
		# shellcheck source=/dev/null
		. "$_lib"
		break
	fi
done
type layout_path >/dev/null 2>&1 || {
	echo "找不到 hdmi-hotplug-lib.sh" >&2
	exit 1
}

case "${1:-save}" in
doctor) cmd_doctor ;;
save | "") cmd_save ;;
*)
	echo "用法: $0 [save|doctor]" >&2
	exit 1
	;;
esac
