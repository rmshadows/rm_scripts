#!/bin/bash
# 把长录音切成多段，方便上传 vibe / 重试。默认按 25 分钟一段。
#
# 用法：
#   ./split_chunks.sh 会议_vibe.wav
#   ./split_chunks.sh --minutes 20 -y 会议_compressed_norm.m4a

# ===== 默认参数（直接改这里）=====
# 每段多少分钟。
CHUNK_MINUTES=25
OUTPUT_SUFFIX=_part
# =================================

set -euo pipefail
export LC_ALL=C

OVERWRITE=0

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 录音文件 ...

按固定时长切段。输出：原名${OUTPUT_SUFFIX}001.扩展名、002…

选项:
  -m, --minutes N         每段分钟数，默认 ${CHUNK_MINUTES}
  -y, --overwrite         覆盖已有输出（同前缀的分段）
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
	-m | --minutes)
		need_arg "$@"
		CHUNK_MINUTES="$2"
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
command -v ffprobe >/dev/null 2>&1 || die "未找到 ffprobe"

awk -v m="$CHUNK_MINUTES" 'BEGIN {
	if (m !~ /^[0-9]+(\.[0-9]+)?$/ || m + 0 < 1) exit 1
}' || die "每段至少 1 分钟。"

process_one() {
	local in="$1" dir base stem ext pattern first dur sec
	[[ -f "$in" ]] || die "找不到文件: $in"
	dir=$(dirname "$in")
	base=$(basename "$in")
	ext="${base##*.}"
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base" && ext="m4a"
	pattern="${dir}/${stem}${OUTPUT_SUFFIX}%03d.${ext}"
	first="${dir}/${stem}${OUTPUT_SUFFIX}001.${ext}"

	dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$in")
	awk -v d="$dur" 'BEGIN{exit !(d+0 > 0)}' || die "读不到时长: $in"
	sec=$(awk -v m="$CHUNK_MINUTES" 'BEGIN{printf "%.3f", m * 60}')

	if awk -v d="$dur" -v s="$sec" 'BEGIN{exit !(d + 0 <= s + 0.5)}'; then
		echo "跳过切段: $in（${dur}s 不超过 ${CHUNK_MINUTES} 分钟）"
		return 0
	fi

	if [[ -e "$first" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $first（加 -y 覆盖）"
	fi
	if [[ "$OVERWRITE" -eq 1 ]]; then
		rm -f "${dir}/${stem}${OUTPUT_SUFFIX}"[0-9][0-9][0-9]."${ext}"
	fi

	echo "切段: $in → ${stem}${OUTPUT_SUFFIX}XXX.${ext}（每段 ${CHUNK_MINUTES} 分钟）"
	# 重新编码，避免 copy 在任意时间点切开失败。
	case "$ext" in
	wav)
		ffmpeg -hide_banner -y -i "$in" \
			-f segment -segment_time "$sec" -reset_timestamps 1 \
			-c:a pcm_s16le \
			"$pattern"
		;;
	*)
		ffmpeg -hide_banner -y -i "$in" \
			-f segment -segment_time "$sec" -reset_timestamps 1 \
			-c:a aac -b:a 96k \
			"${dir}/${stem}${OUTPUT_SUFFIX}%03d.m4a"
		;;
	esac
	echo "完成: ${dir}/${stem}${OUTPUT_SUFFIX}*.${ext}"
}

for f in "$@"; do
	process_one "$f"
done
