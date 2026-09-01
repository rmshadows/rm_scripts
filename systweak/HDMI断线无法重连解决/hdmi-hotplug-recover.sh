#!/usr/bin/env bash
# 热插拔（systemd/udev）：默认无参数 → 受 /etc/hdmi-hotplug.conf 控制。
# 手动立刻重置（不管开关）：  hdmi-hotplug-recover.sh now
# 无布局则对所有 connected 输出 --off 再 --auto。

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
type cmd_recover >/dev/null 2>&1 || {
	echo "找不到 hdmi-hotplug-lib.sh" >&2
	exit 1
}

case "${1:-}" in
now)
	# 用户临时需要：不读 HDMI_HOTPLUG_RESET、不等待热插拔稳定
	cmd_restore
	;;
"" | recover)
	cmd_recover
	;;
*)
	echo "用法: $0          # 热插拔路径（受 conf 开关约束）" >&2
	echo "      $0 now      # 立刻 xrandr 重置（手动，不受开关约束）" >&2
	exit 1
	;;
esac
