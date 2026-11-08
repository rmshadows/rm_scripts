#!/bin/bash
# 会议录音一条龙：压静音 → 拉齐音量 →（可选降噪）→ 准备 vibe →（可选切段）
#
# 用法：
#   ./run_workflow.sh 会议.m4a
#   ./run_workflow.sh --denoise --split 会议.m4a
#   ./run_workflow.sh --skip-compress -y 已压好的.m4a

set -euo pipefail
export LC_ALL=C

HERE="$(cd "$(dirname "$0")" && pwd)"
OVERWRITE=0
DO_DENOISE=0
DO_SPLIT=0
SKIP_COMPRESS=0
SKIP_NORM=0
SKIP_VIBE=0
CHUNK_MINUTES=25
PASSTHRU=()

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 录音文件 ...

默认流程:
  1. compress_silence.sh   → *_compressed.m4a
  2. normalize_loudness.sh → *_norm.m4a
  3. prepare_vibe.sh       → *_vibe.wav

选项:
      --denoise           归一化后再降噪（底噪明显时再开）
      --split             最后按 ${CHUNK_MINUTES} 分钟切段
  -m, --minutes N         切段分钟数，默认 ${CHUNK_MINUTES}
      --skip-compress     跳过压静音（输入已是压缩结果）
      --skip-norm         跳过音量拉齐
      --skip-vibe         跳过 vibe 预处理
  -y, --overwrite         各步覆盖已有输出
  -h, --help              显示本说明

其余未知选项会原样传给 compress_silence.sh（例如 --speed 6）。
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
	--denoise) DO_DENOISE=1; shift ;;
	--split) DO_SPLIT=1; shift ;;
	--skip-compress) SKIP_COMPRESS=1; shift ;;
	--skip-norm) SKIP_NORM=1; shift ;;
	--skip-vibe) SKIP_VIBE=1; shift ;;
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
		# 压静音的参数透传
		PASSTHRU+=("$1")
		if [[ "$1" =~ ^-([ndskmb]|-noise-db|-min-silence|-speed|-min-keep|-edge-pad|-max-pause|-bitrate)$ ]]; then
			[[ $# -ge 2 ]] || die "选项 $1 需要一个值"
			PASSTHRU+=("$2")
			shift 2
		else
			shift
		fi
		;;
	*) break ;;
	esac
done

[[ $# -ge 1 ]] || {
	usage >&2
	exit 1
}

yw=()
[[ "$OVERWRITE" -eq 1 ]] && yw=(-y)

run_step() {
	local title="$1"
	shift
	echo
	echo "==> $title"
	"$@"
}

pick_out() {
	# 若期望输出存在则用之，否则退回输入（例如压静音跳过未写文件）
	local want="$1" fallback="$2"
	if [[ -f "$want" ]]; then
		printf '%s\n' "$want"
	else
		printf '%s\n' "$fallback"
	fi
}

stem_of() {
	local base
	base=$(basename "$1")
	local stem="${base%.*}"
	[[ "$stem" == "$base" ]] && stem="$base"
	printf '%s\n' "$stem"
}

dir_of() {
	dirname "$1"
}

process_one() {
	local src="$1" cur dir stem next
	[[ -f "$src" ]] || die "找不到文件: $src"
	cur="$src"
	dir=$(dir_of "$cur")
	stem=$(stem_of "$cur")

	echo
	echo "######## 处理: $src ########"

	if [[ "$SKIP_COMPRESS" -eq 0 ]]; then
		run_step "压缩静音" "$HERE/compress_silence.sh" "${PASSTHRU[@]}" "${yw[@]}" "$cur"
		# compress 在无长静音时不写文件且返回 0
		next="${dir}/${stem}_compressed.m4a"
		cur=$(pick_out "$next" "$cur")
		dir=$(dir_of "$cur")
		stem=$(stem_of "$cur")
	fi

	if [[ "$SKIP_NORM" -eq 0 ]]; then
		run_step "拉齐音量" "$HERE/normalize_loudness.sh" "${yw[@]}" "$cur"
		cur="${dir}/${stem}_norm.m4a"
		dir=$(dir_of "$cur")
		stem=$(stem_of "$cur")
	fi

	if [[ "$DO_DENOISE" -eq 1 ]]; then
		run_step "降噪" "$HERE/denoise.sh" "${yw[@]}" "$cur"
		cur="${dir}/${stem}_denoise.m4a"
		dir=$(dir_of "$cur")
		stem=$(stem_of "$cur")
	fi

	if [[ "$SKIP_VIBE" -eq 0 ]]; then
		run_step "准备 vibe" "$HERE/prepare_vibe.sh" "${yw[@]}" "$cur"
		cur="${dir}/${stem}_vibe.wav"
		dir=$(dir_of "$cur")
		stem=$(stem_of "$cur")
	fi

	if [[ "$DO_SPLIT" -eq 1 ]]; then
		run_step "切段" "$HERE/split_chunks.sh" --minutes "$CHUNK_MINUTES" "${yw[@]}" "$cur"
	fi

	echo
	echo "最终可用: $cur"
}

for f in "$@"; do
	process_one "$f"
done
