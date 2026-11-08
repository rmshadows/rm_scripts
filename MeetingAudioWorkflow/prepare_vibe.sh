#!/bin/bash
# 转成 vibe / 语音模型更省事的格式：单声道、16 kHz、WAV。
#
# 用法：
#   ./prepare_vibe.sh 会议_compressed_norm.m4a
#   ./prepare_vibe.sh --rate 16000 -y *.m4a

# ===== 默认参数（直接改这里）=====
SAMPLE_RATE=16000
CHANNELS=1
OUTPUT_SUFFIX=_vibe
# 输出容器：wav（无损 PCM，兼容性最好）或 m4a
OUTPUT_FORMAT=wav
# m4a 时的码率
BITRATE=64k
# =================================

set -euo pipefail
export LC_ALL=C

OVERWRITE=0

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 录音文件 ...

转成单声道低采样率，方便上传 vibe / 转写。

选项:
  -r, --rate HZ           采样率，默认 ${SAMPLE_RATE}
  -c, --channels N        声道数，默认 ${CHANNELS}
  -f, --format FMT        wav 或 m4a，默认 ${OUTPUT_FORMAT}
  -b, --bitrate RATE      仅 m4a 用，默认 ${BITRATE}
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
	-r | --rate)
		need_arg "$@"
		SAMPLE_RATE="$2"
		shift 2
		;;
	-c | --channels)
		need_arg "$@"
		CHANNELS="$2"
		shift 2
		;;
	-f | --format)
		need_arg "$@"
		OUTPUT_FORMAT="$2"
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

case "$OUTPUT_FORMAT" in
wav | m4a) ;;
*) die "format 只能是 wav 或 m4a" ;;
esac

awk -v r="$SAMPLE_RATE" -v c="$CHANNELS" 'BEGIN {
	if (r !~ /^[0-9]+$/ || r + 0 < 8000) exit 1
	if (c !~ /^[12]$/) exit 1
}' || die "采样率至少 8000，声道只能是 1 或 2。"

process_one() {
	local in="$1" dir base stem out
	[[ -f "$in" ]] || die "找不到文件: $in"
	dir=$(dirname "$in")
	base=$(basename "$in")
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	out="${dir}/${stem}${OUTPUT_SUFFIX}.${OUTPUT_FORMAT}"
	if [[ -e "$out" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $out（加 -y 覆盖）"
	fi

	echo "准备 vibe: $in → $out（${CHANNELS}ch ${SAMPLE_RATE}Hz）"
	if [[ "$OUTPUT_FORMAT" == "wav" ]]; then
		ffmpeg -hide_banner -y -i "$in" \
			-ac "$CHANNELS" -ar "$SAMPLE_RATE" -c:a pcm_s16le \
			"$out"
	else
		ffmpeg -hide_banner -y -i "$in" \
			-ac "$CHANNELS" -ar "$SAMPLE_RATE" \
			-c:a aac -b:a "$BITRATE" -movflags +faststart \
			"$out"
	fi
	echo "完成: $out"
}

for f in "$@"; do
	process_one "$f"
done
