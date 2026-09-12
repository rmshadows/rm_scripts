#!/bin/bash
# 卸载已安装的 ffmpegL-N（不删 $INSTALL_DIR/videos）
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications/broadcast}"
SRV_NAME=ffmpegL

mapfile -t INST < <(find "$INSTALL_DIR" -maxdepth 1 -mindepth 1 -type d -name "${SRV_NAME}-*" | sort -V)
if [ "${#INST[@]}" -eq 0 ]; then
	echo "没有已安装的 ${SRV_NAME}-N（$INSTALL_DIR）"
	exit 0
fi

echo "已安装："
i=1
for d in "${INST[@]}"; do
	name=$(basename "$d")
	echo "  $i) $name    $d"
	i=$((i + 1))
done
echo "  a) 全部"
echo
read -r -p "卸载哪个编号（或 a）: " CHOICE

do_one() {
	local dir="$1"
	local name
	name=$(basename "$dir")
	echo "卸载 $name …"
	sudo systemctl disable --now "$name" 2>/dev/null || true
	sudo rm -f "/lib/systemd/system/${name}.service"
	sudo systemctl daemon-reload
	rm -rf "$dir"
	echo "已删除服务和目录 $dir"
}

if [[ "$CHOICE" =~ ^[Aa]$ ]]; then
	for d in "${INST[@]}"; do
		do_one "$d"
	done
elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#INST[@]}" ]; then
	do_one "${INST[$((CHOICE - 1))]}"
else
	echo "无效编号"
	exit 1
fi

# 没有实例了就去掉 livectl
shopt -s nullglob
left=("$INSTALL_DIR"/${SRV_NAME}-*)
shopt -u nullglob
if [ "${#left[@]}" -eq 0 ] && [ -f "$INSTALL_DIR/livectl" ]; then
	rm -f "$INSTALL_DIR/livectl"
	echo "已去掉 $INSTALL_DIR/livectl"
fi

echo "视频目录未动: $INSTALL_DIR/videos"
