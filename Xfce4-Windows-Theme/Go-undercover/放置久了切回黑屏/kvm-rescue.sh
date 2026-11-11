#!/bin/bash
# 放久了切回来仍是黑的：Ctrl+Alt+F2 登录后执行本脚本，不必强制重启。
# 把已经连接的显示口重新点亮，并关掉涂黑。
# managed-by-idle-blank-fix

set -u

export DISPLAY="${DISPLAY:-:0}"
if [[ -z "${XAUTHORITY:-}" && -r "${HOME}/.Xauthority" ]]; then
	export XAUTHORITY="${HOME}/.Xauthority"
fi

if ! command -v xrandr >/dev/null 2>&1; then
	echo "没有 xrandr。" >&2
	exit 1
fi

xrandr --auto
xset s off 2>/dev/null || true
xset s noblank 2>/dev/null || true
xset -dpms 2>/dev/null || true
echo "已让显示器重新点亮。切回图形界面：Ctrl+Alt+F7（有的机器是 F1）。"
