#!/bin/bash
# 把会议录音音量拉齐（EBU R128 loudnorm），方便回听和送 vibe。
# 先测量整段响度，再按测量值写出，并说明拉齐前后差多少。
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
command -v ffprobe >/dev/null 2>&1 || die "未找到 ffprobe"

awk -v i="$TARGET_I" -v t="$TARGET_TP" -v l="$TARGET_LRA" 'BEGIN {
	if (i !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (t !~ /^-?[0-9]+(\.[0-9]+)?$/) exit 1
	if (l !~ /^[0-9]+(\.[0-9]+)?$/ || l + 0 <= 0) exit 1
}' || die "响度参数不合法。"

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

jfield() {
	local key="$1" json="$2"
	awk -v k="$key" -F'"' '$2 == k { print $4; exit }' <<<"$json"
}

process_one() {
	local in="$1" dir base stem out err json
	local input_i input_tp input_lra input_thresh offset norm_type
	local output_i delta af linear
	[[ -f "$in" ]] || die "找不到文件: $in"
	dir=$(dirname "$in")
	base=$(basename "$in")
	stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	out="${dir}/${stem}${OUTPUT_SUFFIX}.m4a"
	if [[ -e "$out" && "$OVERWRITE" -ne 1 ]]; then
		die "输出已存在: $out（加 -y 覆盖）"
	fi

	err=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f '$err'" RETURN

	echo "处理: $in"
	echo "正在测量整段响度…"
	if ! ffmpeg -hide_banner -nostats -i "$in" \
		-af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" \
		-f null - >"$err" 2>&1; then
		cat "$err" >&2
		die "测量响度失败: $in"
	fi
	json=$(awk 'BEGIN{p=0} /^\{/{p=1} p{print} /^\}/{if (p) exit}' "$err")
	input_i=$(jfield input_i "$json")
	input_tp=$(jfield input_tp "$json")
	input_lra=$(jfield input_lra "$json")
	input_thresh=$(jfield input_thresh "$json")
	offset=$(jfield target_offset "$json")
	norm_type=$(jfield normalization_type "$json")
	output_i=$(jfield output_i "$json")

	echo
	echo "---------- 情况 ----------"
	echo "文件: $in"
	echo "目标: 响度 ${TARGET_I} LUFS，真峰值不超过 ${TARGET_TP} dBTP"
	if [[ -z "$input_i" || "$input_i" == "-inf" || "$input_i" == "inf" ]]; then
		echo "响度: 这段太短或太静，测不到整体响度，按目标直接拉齐。"
		af="loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}"
	else
		delta=$(awk -v a="$output_i" -v b="$input_i" 'BEGIN{
			if (a+0!=a || b+0!=b) { print ""; exit }
			printf "%.1f", a-b
		}')
		echo "拉齐前: 响度 ${input_i} LUFS，真峰值 ${input_tp} dBTP，起伏 ${input_lra} LU"
		if [[ -n "$delta" ]]; then
			awk -v d="$delta" 'BEGIN{
				if (d+0 >= 1) printf "变化: 整体偏轻，大约抬高 %.1f dB\n", d
				else if (d+0 <= -1) printf "变化: 整体偏响，大约压低 %.1f dB\n", -d
				else print "变化: 已经接近目标响度，这次只做微调"
			}'
		fi
		linear=false
		[[ "$norm_type" == "linear" ]] && linear=true
		af="loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:measured_I=${input_i}:measured_TP=${input_tp}:measured_LRA=${input_lra}:measured_thresh=${input_thresh}:offset=${offset}:linear=${linear}"
	fi

	echo
	echo "正在写出: $out"
	if ! ffmpeg -hide_banner -nostats -loglevel error -y -i "$in" \
		-af "$af" -map_chapters -1 \
		-c:a aac -b:a "$BITRATE" -movflags +faststart \
		"$out" 2>"$err"; then
		cat "$err" >&2
		die "写出失败: $out"
	fi

	echo
	echo "---------- 结果 ----------"
	echo "已写出: $out（$(human_size "$(stat -c %s "$out")")，$(fmt_clock "$(duration_of "$out")")）"
	if [[ -n "$output_i" && "$output_i" != "-inf" && "$output_i" != "inf" ]]; then
		echo "拉齐后大约 ${output_i} LUFS，真峰值按 ${TARGET_TP} dBTP 封顶。"
	fi
}

for f in "$@"; do
	process_one "$f"
done
