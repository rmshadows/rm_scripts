#!/bin/bash
# 轻量降底噪（ffmpeg afftdn）。干净录音不必跑；空调/风扇明显时再用。
#
# 用法：
#   ./denoise.sh 会议_compressed_norm.m4a
#   ./denoise.sh --noise-floor -20 -y 会议.m4a

# ===== 默认参数（直接改这里）=====
# 噪声地板估计（dB）。绝对值越大（如 -30）越保守，-18～-25 更敢降。
NOISE_FLOOR=-25
# 降噪强度 0.01～1。会议语音 0.5 左右，太大容易糊字。
NOISE_REDUCTION=0.5
# 先切掉这么低的低频嗡声（Hz）。0 表示不做高通。
HIGHPASS_HZ=80
BITRATE=96k
OUTPUT_SUFFIX=_denoise
# =================================

set -euo pipefail
export LC_ALL=C

OVERWRITE=0

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 录音文件 ...

用 afftdn 降底噪，输出 AAC .m4a。字头发糊就把 NOISE_REDUCTION 调小。

选项:
  -n, --noise-floor DB    噪声地板，默认 ${NOISE_FLOOR}
  -r, --reduction N       降噪强度 0.01～1，默认 ${NOISE_REDUCTION}
  -H, --highpass HZ       高通频率，默认 ${HIGHPASS_HZ}；0 关闭
  -b, --bitrate RATE      输出码率，默认 ${BITRATE}
  -y, --overwrite         覆盖已有输出
  -h, --help              显示本说明
EOF
}

die() {
	echo "错误: $*" >&2
	exit 1
}

need_arg() {
	[[ $# -ge 2 ]] || die "选项 $1 需要一个值"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	-n | --noise-floor)
		need_arg "$@"
		NOISE_FLOOR="$2"
		shift 2
		;;
	-r | --reduction)
		need_arg "$@"
		NOISE_REDUCTION="$2"
		shift 2
		;;
	-H | --highpass)
		need_arg "$@"
		HIGHPASS_HZ="$2"
		shift 2
		;;
	-b | --bitrate)
		need_arg "$@"
		BITRATE="$2"
		shift 2
		;;
	-y | --overwrite) OVERWRITE=1; shift ;;
	-h | --help)
		usage
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		die "未知选项: $1（用 -h 查看）"
		;;
	*) break ;;
	esac
done

[[ $# -ge 1 ]] || {
	usage >&2
	exit 1
}

command -v ffmpeg >/dev/null 2>&1 || die "未找到 ffmpeg"

NOISE_FLOOR="${NOISE_FLOOR%[dD][bB]}"
awk -v nf="$NOISE_FLOOR" -v nr="$NOISE_REDUCTION" -v hp="$HIGHPASS_HZ" 'BEGIN {
	if (nf !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (nr !~ /^[0-9]+(\.[0-9]+)?$/ || nr + 0 < 0.01 || nr + 0 > 1) exit 1
	if (hp !~ /^[0-9]+(\.[0-9]+)?$/) exit 1
}' || die "降噪参数不合法。reduction 要在 0.01～1。"

process_one() {
	local in="$1" dir base stem out af
	[[ -f "$in" ]] || die "找不到文件: $in"
	dir=$(dirname "$in")
	base=$(basename "$in")
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	out="${dir}/${stem}${OUTPUT_SUFFIX}.m4a"
	if [[ -e "$out" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $out（加 -y 覆盖）"
	fi

	af="afftdn=nf=${NOISE_FLOOR}:nr=${NOISE_REDUCTION}"
	if awk -v hp="$HIGHPASS_HZ" 'BEGIN{exit !(hp+0 > 0)}'; then
		af="highpass=f=${HIGHPASS_HZ},${af}"
	fi

	echo "降噪: $in → $out（nf=${NOISE_FLOOR} nr=${NOISE_REDUCTION}）"
	ffmpeg -hide_banner -y -i "$in" \
		-af "$af" \
		-c:a aac -b:a "$BITRATE" -movflags +faststart \
		"$out"
	echo "完成: $out"
}

for f in "$@"; do
	process_one "$f"
done
