#!/bin/sh
# udev 调用：立刻返回。HDMI_HOTPLUG_RESET=0 时不启动恢复服务。
CONF=/etc/hdmi-hotplug.conf
if [ -f "$CONF" ] && grep -q '^[[:space:]]*HDMI_HOTPLUG_RESET=0' "$CONF"; then
	exit 0
fi
exec /usr/bin/systemctl start --no-block hdmi-hotplug-recover.service
