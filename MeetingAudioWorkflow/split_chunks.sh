#!/bin/bash
# 把长录音切成多段再交给 vibe。整段太长时，识别会从某一分钟起反复同一句。
# 默认 20 分钟一段。不够一段就说明没切，并列出每一段的时长。
#
# 用法：
#   ./split_chunks.sh 会议_compressed.m4a
#   ./split_chunks.sh --minutes 15 -y 会议_vibe.wav

# ===== 默认参数（直接改这里）=====
# 每段多少分钟。20 分钟给 vibe 比较稳，再长容易后半段崩掉。
CHUNK_MINUTES=20
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

process_one() {
	local in="$1" dir base stem ext pattern first dur sec err part pd psz n=0
	[[ -f "$in" ]] || die "找不到文件: $in"
	dir=$(dirname "$in")
	base=$(basename "$in")
	ext="${base##*.}"
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base" && ext="m4a"
	# wav 保持 wav；其他格式切出来是 m4a。
	if [[ "$ext" != "wav" ]]; then
		ext=m4a
	fi
	pattern="${dir}/${stem}${OUTPUT_SUFFIX}%03d.${ext}"
	first="${dir}/${stem}${OUTPUT_SUFFIX}001.${ext}"

	dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$in")
	awk -v d="$dur" 'BEGIN{exit !(d+0 > 0)}' || die "读不到时长: $in"
	sec=$(awk -v m="$CHUNK_MINUTES" 'BEGIN{printf "%.3f", m * 60}')

	echo "处理: $in"
	if awk -v d="$dur" -v s="$sec" 'BEGIN{exit !(d + 0 <= s + 0.5)}'; then
		echo
		echo "---------- 总结 ----------"
		echo "原长: $(fmt_clock "$dur")"
		echo "每段: ${CHUNK_MINUTES} 分钟。这段更短，没有切。"
		echo "结果: 仍用 $in"
		return 0
	fi

	if [[ -e "$first" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $first（加 -y 覆盖）"
	fi
	if [[ "$OVERWRITE" -eq 1 ]]; then
		rm -f "${dir}/${stem}${OUTPUT_SUFFIX}"[0-9][0-9][0-9]."${ext}"
	fi

	local expect last_print seen now ffpid
	expect=$(awk -v d="$dur" -v s="$sec" 'BEGIN{ n=int(d/s); if (d > n*s+0.5) n++; if (n<1) n=1; print n }')
	echo "正在按每 ${CHUNK_MINUTES} 分钟切开，预计 ${expect} 段。"
	echo "每写完一段报一次；超过 20 秒没写完，会再报仍在切。"
	err=$(mktemp)
	# 重新编码，避免 copy 在任意时间点切开失败。
	if [[ "$ext" == "wav" ]]; then
		ffmpeg -hide_banner -nostats -loglevel error -y -i "$in" \
			-map_chapters -1 \
			-f segment -segment_time "$sec" -segment_start_number 1 -reset_timestamps 1 \
			-c:a pcm_s16le \
			"$pattern" >"$err" 2>&1 &
	else
		ffmpeg -hide_banner -nostats -loglevel error -y -i "$in" \
			-map_chapters -1 \
			-f segment -segment_time "$sec" -segment_start_number 1 -reset_timestamps 1 \
			-c:a aac -b:a 96k \
			"$pattern" >"$err" 2>&1 &
	fi
	ffpid=$!
	seen=0
	last_print=$SECONDS
	while kill -0 "$ffpid" 2>/dev/null; do
		sleep 1
		now=$(find "$dir" -maxdepth 1 -type f -name "${stem}${OUTPUT_SUFFIX}[0-9][0-9][0-9].${ext}" | wc -l)
		if (( now > seen )); then
			echo "已写出 ${now}/${expect} 段"
			seen=$now
			last_print=$SECONDS
		elif (( SECONDS - last_print >= 20 )); then
			echo "仍在切第 $((seen + 1)) 段…"
			last_print=$SECONDS
		fi
	done
	if ! wait "$ffpid"; then
		cat "$err" >&2
		rm -f "$err"
		die "切段失败: $in"
	fi
	rm -f "$err"

	echo
	echo "---------- 总结 ----------"
	echo "原长: $(fmt_clock "$dur")"
	echo "每段: ${CHUNK_MINUTES} 分钟"
	while IFS= read -r -d '' part; do
		n=$((n + 1))
		pd=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$part")
		psz=$(stat -c %s "$part")
		printf '  %s  %s  %s\n' "$(basename "$part")" "$(fmt_clock "$pd")" "$(human_size "$psz")"
	done < <(find "$dir" -maxdepth 1 -type f -name "${stem}${OUTPUT_SUFFIX}[0-9][0-9][0-9].${ext}" -print0 | sort -z)
	echo "结果: 切成 ${n} 段"
}

for f in "$@"; do
	process_one "$f"
done
