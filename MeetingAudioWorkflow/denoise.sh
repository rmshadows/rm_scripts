#!/bin/bash
# 轻量降底噪（ffmpeg afftdn）。干净录音不必跑；空调/风扇明显时再用。
# 跑完对比降噪前后的平均电平和峰值。
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
command -v ffprobe >/dev/null 2>&1 || die "未找到 ffprobe"

NOISE_FLOOR="${NOISE_FLOOR%[dD][bB]}"
awk -v nf="$NOISE_FLOOR" -v nr="$NOISE_REDUCTION" -v hp="$HIGHPASS_HZ" 'BEGIN {
	if (nf !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (nr !~ /^[0-9]+(\.[0-9]+)?$/ || nr + 0 < 0.01 || nr + 0 > 1) exit 1
	if (hp !~ /^[0-9]+(\.[0-9]+)?$/) exit 1
}' || die "降噪参数不合法。reduction 要在 0.01～1。"

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

duration_of() {
	ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1"
}

# 打出 mean max，单位 dB。读不到就空。
volume_pair() {
	local err mean max
	err=$(mktemp)
	if ffmpeg -hide_banner -nostats -i "$1" -af volumedetect -f null - >"$err" 2>&1; then
		mean=$(awk '
			/mean_volume:/ {
				if (match($0, /mean_volume:[[:space:]]*-?[0-9]+(\.[0-9]+)?/)) {
					s = substr($0, RSTART, RLENGTH)
					sub(/^.*:[[:space:]]*/, "", s)
					print s
					exit
				}
			}' "$err")
		max=$(awk '
			/max_volume:/ {
				if (match($0, /max_volume:[[:space:]]*-?[0-9]+(\.[0-9]+)?/)) {
					s = substr($0, RSTART, RLENGTH)
					sub(/^.*:[[:space:]]*/, "", s)
					print s
					exit
				}
			}' "$err")
	fi
	rm -f "$err"
	printf '%s %s\n' "${mean:-}" "${max:-}"
}

process_one() {
	local in="$1" dir base stem out af err
	local before after mean1 max1 mean2 max2
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

	echo "处理: $in"
	echo "正在看降噪前的电平…"
	read -r mean1 max1 < <(volume_pair "$in")

	err=$(mktemp)
	echo "正在写出: $out"
	if ! ffmpeg -hide_banner -nostats -loglevel error -y -i "$in" \
		-af "$af" -map_chapters -1 \
		-c:a aac -b:a "$BITRATE" -movflags +faststart \
		"$out" 2>"$err"; then
		cat "$err" >&2
		rm -f "$err"
		die "写出失败: $out"
	fi
	rm -f "$err"

	echo "正在看降噪后的电平…"
	read -r mean2 max2 < <(volume_pair "$out")

	echo
	echo "---------- 总结 ----------"
	echo "文件: $in"
	if awk -v hp="$HIGHPASS_HZ" 'BEGIN{exit !(hp+0 > 0)}'; then
		echo "参数: 噪声地板 ${NOISE_FLOOR} dB，强度 ${NOISE_REDUCTION}，高通 ${HIGHPASS_HZ} Hz"
	else
		echo "参数: 噪声地板 ${NOISE_FLOOR} dB，强度 ${NOISE_REDUCTION}，未做高通"
	fi
	if [[ -n "$mean1" && -n "$max1" ]]; then
		echo "降噪前: 平均 ${mean1} dB，峰值 ${max1} dB"
	else
		echo "降噪前: 没读到电平"
	fi
	if [[ -n "$mean2" && -n "$max2" ]]; then
		echo "降噪后: 平均 ${mean2} dB，峰值 ${max2} dB"
	else
		echo "降噪后: 没读到电平"
	fi
	if [[ -n "$mean1" && -n "$mean2" ]]; then
		awk -v a="$mean1" -v b="$mean2" -v nr="$NOISE_REDUCTION" 'BEGIN {
			d = b - a
			if (d <= -1) printf "变化: 平均电平下降 %.1f dB，底噪被压下去一些。\n", -d
			else if (d >= 1) printf "变化: 平均电平上升 %.1f dB。\n", d
			else print "变化: 平均电平几乎没变。底噪不明显，或者噪声地板设得偏低。"
			if (nr + 0 >= 0.7) print "提示: 强度偏高，若字头发糊，把强度降到 0.3。"
		}'
	fi
	echo "已写出: $out（$(human_size "$(stat -c %s "$out")")，$(fmt_clock "$(duration_of "$out")")）"
}

for f in "$@"; do
	process_one "$f"
done
