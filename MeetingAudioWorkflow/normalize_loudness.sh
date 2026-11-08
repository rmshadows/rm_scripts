#!/bin/bash
# 把会议录音音量拉齐（EBU R128 loudnorm），方便回听和送 vibe。
#
# 用法：
#   ./normalize_loudness.sh 会议_compressed.m4a
#   ./normalize_loudness.sh -y *.m4a

# ===== 默认参数（直接改这里）=====
# 目标响度（LUFS）。语音常用 -16；再大声可改 -14，更保守用 -18。
TARGET_I=-16
# 真峰值上限（dBTP）。
TARGET_TP=-1.5
# 响度范围（LU）。会议语音 11 左右即可。
TARGET_LRA=11
BITRATE=96k
OUTPUT_SUFFIX=_norm
# =================================

set -euo pipefail
export LC_ALL=C

OVERWRITE=0

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 录音文件 ...

按 loudnorm 拉齐音量，输出 AAC .m4a。

选项:
  -I, --target-i LUFS     目标响度，默认 ${TARGET_I}
  -T, --target-tp DB      真峰值上限，默认 ${TARGET_TP}
  -L, --target-lra LU     响度范围，默认 ${TARGET_LRA}
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
	-I | --target-i)
		need_arg "$@"
		TARGET_I="$2"
		shift 2
		;;
	-T | --target-tp)
		need_arg "$@"
		TARGET_TP="$2"
		shift 2
		;;
	-L | --target-lra)
		need_arg "$@"
		TARGET_LRA="$2"
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

awk -v i="$TARGET_I" -v t="$TARGET_TP" -v l="$TARGET_LRA" 'BEGIN {
	if (i !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (t !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (l !~ /^[0-9]+(\.[0-9]+)?$/ || l + 0 <= 0) exit 1
}' || die "响度参数不合法。"

process_one() {
	local in="$1" dir base stem out
	[[ -f "$in" ]] || die "找不到文件: $in"
	dir=$(dirname "$in")
	base=$(basename "$in")
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	out="${dir}/${stem}${OUTPUT_SUFFIX}.m4a"
	if [[ -e "$out" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $out（加 -y 覆盖）"
	fi

	echo "拉齐音量: $in → $out（I=${TARGET_I} TP=${TARGET_TP} LRA=${TARGET_LRA}）"
	ffmpeg -hide_banner -y -i "$in" \
		-af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}" \
		-c:a aac -b:a "$BITRATE" -movflags +faststart \
		"$out"
	echo "完成: $out"
}

for f in "$@"; do
	process_one "$f"
done
