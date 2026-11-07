#!/bin/bash
# 把会议录音里的静音段压短，不删掉。短停顿原样保留，长静音加快后仍留一段空隙。
#
# 改默认值：直接改下面这一段。命令行参数只覆盖这一次，不改文件。
#
# 用法：
#   ./compress_silence.sh 会议.m4a
#   ./compress_silence.sh --speed 6 --max-pause 0.8 *.wav
#   ./compress_silence.sh --dry-run 会议.m4a

# ===== 默认参数（直接改这里）=====
# 低于这个电平（dB）才算静音。-35 更敢压，-50 只压很安静的地方。
NOISE_DB=-40
# 短于这么多秒的空隙不动，避免把词和词之间的气口也加快。
MIN_SILENCE=0.80
# 静音段加快的倍数。4 表示 4 秒静音变成约 1 秒。
SPEED=4
# 压缩后这段静音至少留这么多秒，听得出来停过。
MIN_KEEP=0.35
# 静音两端各留这么多秒原速，避免把字头字尾卷进加速段。
EDGE_PAD=0.10
# 压缩后整段停顿最长这么多秒（含两端原速）。0 表示不设上限，只按 SPEED 缩短。
MAX_PAUSE=1.20
# 输出 AAC 码率。会议语音 64k～96k 够用。
BITRATE=96k
# 输出文件名：原名 + 这个后缀 + .m4a
OUTPUT_SUFFIX=_compressed
# =================================

set -euo pipefail
export LC_ALL=C

OVERWRITE=0
DRY_RUN=0

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 录音文件 ...

把长静音加快，不剪掉。短于 MIN_SILENCE 的空隙保持原速。

选项（覆盖脚本顶部的默认值）:
  -n, --noise-db DB       静音阈值，默认 ${NOISE_DB}（dB）
  -d, --min-silence SEC   短于此时长的静音不处理，默认 ${MIN_SILENCE}
  -s, --speed N           静音加快倍数，默认 ${SPEED}
  -k, --min-keep SEC      压缩后至少保留的静音，默认 ${MIN_KEEP}
      --edge-pad SEC      静音两端原速保护，默认 ${EDGE_PAD}
  -m, --max-pause SEC     压缩后停顿上限，默认 ${MAX_PAUSE}；0 为不限制
  -b, --bitrate RATE      输出码率，默认 ${BITRATE}
  -y, --overwrite         覆盖已有输出
      --dry-run           只打印将要压缩的静音段，不写文件
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
	-n | --noise-db)
		need_arg "$@"
		NOISE_DB="$2"
		shift 2
		;;
	-d | --min-silence)
		need_arg "$@"
		MIN_SILENCE="$2"
		shift 2
		;;
	-s | --speed)
		need_arg "$@"
		SPEED="$2"
		shift 2
		;;
	-k | --min-keep)
		need_arg "$@"
		MIN_KEEP="$2"
		shift 2
		;;
	--edge-pad)
		need_arg "$@"
		EDGE_PAD="$2"
		shift 2
		;;
	-m | --max-pause)
		need_arg "$@"
		MAX_PAUSE="$2"
		shift 2
		;;
	-b | --bitrate)
		need_arg "$@"
		BITRATE="$2"
		shift 2
		;;
	-y | --overwrite) OVERWRITE=1; shift ;;
	--dry-run) DRY_RUN=1; shift ;;
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

NOISE_DB="${NOISE_DB%[dD][bB]}"
awk -v n="$NOISE_DB" -v d="$MIN_SILENCE" -v s="$SPEED" -v k="$MIN_KEEP" -v p="$EDGE_PAD" -v m="$MAX_PAUSE" 'BEGIN {
	if (n !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (d !~ /^[0-9]+(\.[0-9]+)?$/ || d + 0 < 0.05) exit 1
	if (s !~ /^[0-9]+(\.[0-9]+)?$/ || s + 0 <= 1) exit 1
	if (k !~ /^[0-9]+(\.[0-9]+)?$/ || k + 0 < 0) exit 1
	if (p !~ /^[0-9]+(\.[0-9]+)?$/ || p + 0 < 0) exit 1
	if (m !~ /^[0-9]+(\.[0-9]+)?$/ || m + 0 < 0) exit 1
}' || die "阈值不合法。SPEED 必须大于 1，MIN_SILENCE 至少 0.05 秒，电平用负数 dB（例如 -40）。"

duration_of() {
	ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1"
}

# 读 silencedetect 日志，打出若干行: start end tempo
# tempo=1 表示原速。
build_segments() {
	local log="$1" dur="$2"
	awk -v dur="$dur" -v speed="$SPEED" -v min_keep="$MIN_KEEP" -v edge="$EDGE_PAD" -v max_pause="$MAX_PAUSE" '
	function emit(s, e, tempo) {
		if (e - s < 0.001) return
		printf "%.6f %.6f %.6f\n", s, e, tempo
		count++
		if (tempo > 1.02) sped++
	}
	function emit_silence(s, e,    dur0, pad, mid_in, mid_out, total, tempo) {
		dur0 = e - s
		if (dur0 < 0.02) return
		pad = edge + 0
		if (2 * pad > dur0 * 0.5) pad = dur0 * 0.2
		mid_in = dur0 - 2 * pad
		if (mid_in < 0.05) {
			emit(s, e, 1)
			return
		}
		mid_out = mid_in / speed
		if (mid_out < min_keep) mid_out = min_keep
		if (mid_out > mid_in) mid_out = mid_in
		total = mid_out + 2 * pad
		if (max_pause > 0 && total > max_pause && dur0 > max_pause) {
			pad = edge + 0
			if (2 * pad > max_pause * 0.5) pad = max_pause * 0.2
			mid_out = max_pause - 2 * pad
			if (mid_out < 0.05) {
				pad = 0
				mid_out = max_pause
			}
			mid_in = dur0 - 2 * pad
			if (mid_in < 0.05) {
				emit(s, e, 1)
				return
			}
		}
		if (mid_out >= mid_in - 0.001) {
			emit(s, e, 1)
			return
		}
		tempo = mid_in / mid_out
		if (tempo < 1.05) {
			emit(s, e, 1)
			return
		}
		if (pad > 0.001) emit(s, s + pad, 1)
		emit(s + pad, e - pad, tempo)
		if (pad > 0.001) emit(e - pad, e, 1)
	}
	function num_after(key,    line, n) {
		line = $0
		if (!match(line, key "[[:space:]]*[0-9.]+")) return -1
		n = substr(line, RSTART, RLENGTH)
		sub(/^[^0-9]*/, "", n)
		return n + 0
	}
	/silence_start:/ {
		start = num_after("silence_start:")
		holding = 1
		next
	}
	/silence_end:/ {
		if (!holding) next
		end = num_after("silence_end:")
		if (end < 0) next
		if (end < start) end = start
		if (start > cursor + 0.001) emit(cursor, start, 1)
		emit_silence(start, end)
		cursor = end
		holding = 0
		next
	}
	END {
		if (holding) {
			if (start > cursor + 0.001) emit(cursor, start, 1)
			emit_silence(start, dur)
			cursor = dur
		}
		if (dur > cursor + 0.001) emit(cursor, dur, 1)
		if (count == 0) emit(0, dur, 1)
		printf "STATS %d %d\n", count, sped > "/dev/stderr"
	}
	' "$log"
}

atempo_filters() {
	local tempo="$1" chain="" piece
	while awk -v t="$tempo" 'BEGIN{exit !(t > 2.0)}'; do
		chain+="atempo=2.0,"
		tempo=$(awk -v t="$tempo" 'BEGIN{printf "%.6f", t/2.0}')
	done
	if awk -v t="$tempo" 'BEGIN{exit !(t > 1.01)}'; then
		piece=$(awk -v t="$tempo" 'BEGIN{printf "%.4f", t}')
		chain+="atempo=${piece},"
	fi
	printf '%s' "${chain%,}"
}

process_one() {
	local in="$1" dur log seg_file fc out stem dir base n=0 sped=0
	local start end tempo filters label concat line stats

	[[ -f "$in" ]] || die "找不到文件: $in"
	dur=$(duration_of "$in")
	awk -v d="$dur" 'BEGIN{exit !(d+0 > 0)}' || die "读不到时长: $in"

	dir=$(dirname "$in")
	base=$(basename "$in")
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	out="${dir}/${stem}${OUTPUT_SUFFIX}.m4a"
	if [[ -e "$out" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $out（加 -y 覆盖）"
	fi

	log=$(mktemp)
	seg_file=$(mktemp)
	fc=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f '$log' '$seg_file' '$fc'" RETURN

	echo "检测静音: $in（阈值 ${NOISE_DB} dB，短于 ${MIN_SILENCE}s 的空隙忽略）"
	ffmpeg -hide_banner -nostats -i "$in" \
		-af "silencedetect=n=${NOISE_DB}dB:d=${MIN_SILENCE}" \
		-f null - >"$log" 2>&1 || die "ffmpeg 检测静音失败: $in"

	build_segments "$log" "$dur" >"$seg_file" 2>"${seg_file}.stats" || die "划分静音段失败: $in"
	stats=$(cat "${seg_file}.stats")
	rm -f "${seg_file}.stats"
	# STATS 总段数 被加速的段数
	sped=$(awk '{print $3}' <<<"$stats")
	sped=${sped:-0}

	echo "  全长 ${dur}s，将加速的静音段: ${sped}"
	if [[ "$sped" -eq 0 ]]; then
		echo "  没有长于 ${MIN_SILENCE}s 的静音。可把 MIN_SILENCE 调小，或把 NOISE_DB 调高（例如 -35）。"
		if [[ "$DRY_RUN" -eq 1 ]]; then
			return 0
		fi
		echo "  跳过，不写文件。"
		return 0
	fi

	if [[ "$DRY_RUN" -eq 1 ]]; then
		printf '  %-12s %-12s %-8s %s\n' "开始" "结束" "倍数" "处理"
		while read -r start end tempo; do
			[[ "$start" == "STATS" ]] && continue
			if awk -v t="$tempo" 'BEGIN{exit !(t > 1.02)}'; then
				printf '  %-12s %-12s %-8s %s\n' "$start" "$end" "$tempo" "压缩"
			fi
		done <"$seg_file"
		echo "  （演习，未写文件）"
		return 0
	fi

	concat=""
	while read -r start end tempo; do
		filters=$(atempo_filters "$tempo")
		label="a${n}"
		{
			printf '[0:a]atrim=start=%s:end=%s,asetpts=PTS-STARTPTS' "$start" "$end"
			if [[ -n "$filters" ]]; then
				printf ',%s' "$filters"
			fi
			printf '[%s];\n' "$label"
		} >>"$fc"
		concat+="[${label}]"
		n=$((n + 1))
	done <"$seg_file"

	[[ "$n" -gt 0 ]] || die "没有可输出的片段: $in"
	printf '%sconcat=n=%d:v=0:a=1[out]\n' "$concat" "$n" >>"$fc"

	echo "写出: $out"
	local ff_major complex_opt
	ff_major=$(ffmpeg -hide_banner -version | awk 'NR==1 { if (match($3, /^[0-9]+/)) print substr($3, RSTART, RLENGTH); exit }')
	if [[ "${ff_major:-0}" -ge 7 ]]; then
		complex_opt=(-/filter_complex "$fc")
	else
		complex_opt=(-filter_complex_script "$fc")
	fi
	ffmpeg -hide_banner -y -i "$in" \
		"${complex_opt[@]}" -map '[out]' \
		-c:a aac -b:a "$BITRATE" -movflags +faststart \
		"$out"

	echo "完成: $out（原 ${dur}s → $(duration_of "$out")s）"
}

for f in "$@"; do
	process_one "$f"
done
