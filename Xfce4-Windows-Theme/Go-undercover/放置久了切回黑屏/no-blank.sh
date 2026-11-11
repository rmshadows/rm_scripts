#!/bin/bash
# 关掉当前会话的 X 屏保涂黑和 DPMS。
# --loop：每 5 分钟再关一次。xfce4-power-manager 会把 DPMS 重新打开。
# managed-by-idle-blank-fix

set -u

once() {
	export DISPLAY="${DISPLAY:-:0}"
	if [[ -z "${XAUTHORITY:-}" && -r "${HOME}/.Xauthority" ]]; then
		export XAUTHORITY="${HOME}/.Xauthority"
	fi
	xset s off
	xset s noblank
	xset -dpms
}

case "${1:-}" in
	--loop)
		while true; do
			once >/dev/null 2>&1 || true
			sleep 300
		done
		;;
	--once | "")
		once
		;;
	*)
		echo "用法: no-blank.sh [--once|--loop]" >&2
		exit 1
		;;
esac
