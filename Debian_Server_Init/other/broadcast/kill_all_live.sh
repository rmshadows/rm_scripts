#!/bin/bash
# 只停本仓库安装的直播服务，不杀系统里其它 ffmpeg
set -u

units=$(systemctl list-units --type=service --all --no-legend 'ffmpegL-*.service' 'kplayer-*.service' 2>/dev/null | awk '{print $1}')
if [[ -z "${units}" ]]; then
	echo "没有找到 ffmpegL-*.service / kplayer-*.service"
else
	echo "将停止并 disable："
	echo "$units"
	# shellcheck disable=SC2086
	sudo systemctl disable --now $units || true
fi

# 残留进程（手动跑的脚本）
pkill -f '/Applications/broadcast/ffmpegL-' 2>/dev/null || true
pkill -f '/Applications/broadcast/kplayer-' 2>/dev/null || true

echo "---- 仍在跑的相关进程 ----"
pgrep -af 'ffmpegL-|kplayer' || echo "(无)"
