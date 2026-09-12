#!/bin/bash
# 安装一个 ffmpegL-N 推流实例。1G 内存请用这个，不要用 kplayer。
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
# 旧 Lib.sh / GlobalVariables 里有当注释的 heredoc，未加引号时 set -u 会展开里面的 $choice/$line。
# source 时先关掉 nounset，库加载完再开回来。
set +u
source "../GlobalVariables.sh"
source "../Lib.sh"
set -u

SRV_NAME=ffmpegL
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications/broadcast}"
SET_DIR="$(pwd)"

need_pkg() {
	local t_pkg="$1"
	if ! command -v "$t_pkg" &>/dev/null; then
		echo -e "\033[31m$t_pkg not found, installing...\033[0m"
		sudo apt update && sudo apt install -y "$t_pkg"
	fi
}
need_pkg nano
need_pkg ffmpeg

mkdir -p "$INSTALL_DIR/videos"

existing_count=0
for d in "$INSTALL_DIR"/${SRV_NAME}-*; do
	[[ -d "$d" ]] || continue
	n="${d##*-}"
	[[ "$n" =~ ^[0-9]+$ ]] || continue
	if ((n > existing_count)); then
		existing_count=$n
	fi
done

if [[ "$existing_count" -eq 0 ]]; then
	echo "当前没有已安装的 ${SRV_NAME} 服务。"
	new_srv_number=1
else
	echo "当前已安装到 ${SRV_NAME}-${existing_count}。"
	new_srv_number=$((existing_count + 1))
fi

read -r -p "是否安装新的 ${SRV_NAME}-${new_srv_number}？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
	echo "取消安装。"
	exit 0
fi

new_srv_name="${SRV_NAME}-${new_srv_number}"
new_srv_path="$INSTALL_DIR/$new_srv_name"
mkdir -p "$new_srv_path"

cp -a ffmpegL_sample/conf.txt ffmpegL_sample/reset_rtmp.sh ffmpegL_sample/removeServices.sh "$new_srv_path"/
: >"$new_srv_path/stream.log"
chmod +x "$new_srv_path"/reset_rtmp.sh "$new_srv_path"/removeServices.sh

cd "$new_srv_path"
replace_placeholders_with_values conf.txt
replace_placeholders_with_values reset_rtmp.sh
replace_placeholders_with_values removeServices.sh

cd "$SET_DIR"
replace_placeholders_with_values live.sh.src
mv -f live.sh "$new_srv_path/${new_srv_name}.sh"
chmod +x "$new_srv_path/${new_srv_name}.sh"

replace_placeholders_with_values ctl.sh.src
mv -f ctl.sh "$new_srv_path/ctl.sh"
chmod +x "$new_srv_path/ctl.sh"
install -m 755 livectl "$INSTALL_DIR/livectl"

replace_placeholders_with_values srv.service.src
echo
echo "MemoryMax 是可选的：1G 建议开（推流打满只杀自己），内存多的机器不必开。"
read -r -p "给该服务加上 MemoryMax=384M？(y/N): " memc
if [[ "$memc" =~ ^[Yy]$ ]]; then
	sed -i 's/^# MemoryMax=/MemoryMax=/' srv.service
	sed -i 's/^# MemoryHigh=/MemoryHigh=/' srv.service
	echo "已启用 MemoryMax=384M"
else
	echo "不限制内存。以后要加：sudo systemctl edit ${new_srv_name}"
fi
sudo mv -f srv.service "/lib/systemd/system/${new_srv_name}.service"
sudo systemctl daemon-reload

echo
echo "已安装: $new_srv_name"
echo "目录:   $new_srv_path"
echo "视频:   $INSTALL_DIR/videos"
echo
echo "接下来："
echo "  1) 把 mp4 放到 $INSTALL_DIR/videos"
echo "  2) 编辑推流地址: $new_srv_path/reset_rtmp.sh"
echo "  3) 启动: sudo systemctl enable --now $new_srv_name"
echo "  控制: $INSTALL_DIR/livectl $new_srv_name status"
echo "        $INSTALL_DIR/livectl $new_srv_name next"
echo "        $new_srv_path/ctl.sh list"
echo "  看日志: journalctl -u $new_srv_name -f"
echo "         tail -f $new_srv_path/stream.log"
echo "  卸载:   $SET_DIR/uninstall.sh"
echo
read -r -p "现在编辑 conf.txt / RTMP？(Y/n): " editc
if [[ ! "${editc:-y}" =~ ^[Nn]$ ]]; then
	nano "$new_srv_path/conf.txt"
fi
read -r -p "现在 enable --now 启动服务？(y/N): " startc
if [[ "$startc" =~ ^[Yy]$ ]]; then
	sudo systemctl enable --now "$new_srv_name"
	sudo systemctl --no-pager --full status "$new_srv_name" || true
fi
