#!/bin/bash
# 转成 vibe / 语音模型更省事的格式：单声道、16 kHz、WAV。
# 跑完对比输入和输出的声道、采样率、体积。
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
command -v ffprobe >/dev/null 2>&1 || die "未找到 ffprobe"

case "$OUTPUT_FORMAT" in
wav | m4a) ;;
*) die "format 只能是 wav 或 m4a" ;;
esac

awk -v r="$SAMPLE_RATE" -v c="$CHANNELS" 'BEGIN {
	if (r !~ /^[0-9]+$/ || r + 0 < 8000) exit 1
	if (c !~ /^[12]$/) exit 1
}' || die "采样率至少 8000，声道只能是 1 或 2。"

fmt_clock() {
	awk -v t="$1" 'BEGIN {
		if (t !~ /^-?[0-9]+(\.[0-9]+)?$/) { printf "%s", t; exit }
		t += 0
		if (t < 0) t = 0
		s = int(t + 0.5)
		h = int(s / 3600)
		m = int(s / 60) % 60
		s = s % 60
		if (h > 0) printf "%d:%02d:%02d", h, m, s
		else printf "%d:%02d", m, s
	}'
}

human_size() {
	awk -v n="$1" 'BEGIN {
		if (n !~ /^[0-9]+$/) { printf "%s", n; exit }
		if (n >= 1048576) printf "%.1f MB", n / 1048576
		else if (n >= 1024) printf "%.0f KB", n / 1024
		else printf "%d B", n
	}'
}

audio_brief() {
	local f="$1" ch sr dur sz
	ch=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=nw=1:nk=1 "$f" || true)
	sr=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=nw=1:nk=1 "$f" || true)
	dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$f" || true)
	sz=$(stat -c %s "$f")
	printf '%s 声道，%s Hz，%s，%s' "${ch:-?}" "${sr:-?}" "$(fmt_clock "$dur")" "$(human_size "$sz")"
}

process_one() {
	local in="$1" dir base stem out err in_brief
	[[ -f "$in" ]] || die "找不到文件: $in"
	dir=$(dirname "$in")
	base=$(basename "$in")
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	out="${dir}/${stem}${OUTPUT_SUFFIX}.${OUTPUT_FORMAT}"
	if [[ -e "$out" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $out（加 -y 覆盖）"
	fi

	in_brief=$(audio_brief "$in")
	echo "处理: $in"
	echo "正在转成 ${CHANNELS} 声道 ${SAMPLE_RATE} Hz ${OUTPUT_FORMAT}…"
	err=$(mktemp)
	if [[ "$OUTPUT_FORMAT" == "wav" ]]; then
		if ! ffmpeg -hide_banner -nostats -loglevel error -y -i "$in" \
			-map_chapters -1 \
			-ac "$CHANNELS" -ar "$SAMPLE_RATE" -c:a pcm_s16le \
			"$out" 2>"$err"; then
			cat "$err" >&2
			rm -f "$err"
			die "写出失败: $out"
		fi
	else
		if ! ffmpeg -hide_banner -nostats -loglevel error -y -i "$in" \
			-map_chapters -1 \
			-ac "$CHANNELS" -ar "$SAMPLE_RATE" \
			-c:a aac -b:a "$BITRATE" -movflags +faststart \
			"$out" 2>"$err"; then
			cat "$err" >&2
			rm -f "$err"
			die "写出失败: $out"
		fi
	fi
	rm -f "$err"

	echo
	echo "---------- 总结 ----------"
	echo "输入: ${in_brief}"
	echo "输出: $(audio_brief "$out")"
	echo "已写出: $out"
	if [[ "$OUTPUT_FORMAT" == "wav" ]]; then
		echo "说明: ${CHANNELS} 声道 ${SAMPLE_RATE} Hz 的未压缩 WAV，给 vibe / 转写用。体积通常比压缩格式大。"
	else
		echo "说明: 已收成 ${CHANNELS} 声道 ${SAMPLE_RATE} Hz 的 m4a，给 vibe / 转写用。"
	fi
}

for f in "$@"; do
	process_one "$f"
done
