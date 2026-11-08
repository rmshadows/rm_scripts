#!/bin/bash
# 繁体转简体。用本机 OpenCC，不联网。
#
# 接受 txt、csv、tsv、srt、md、markdown、ass、vtt。
# 给文件就转这些文件；给文件夹就只转这一层，不进入子目录。
# 结果写在旁边：原名_simp.原扩展名。原文件不动。
#
# 用法：
#   ./to_simplified.sh 会议.txt 字幕.srt
#   ./to_simplified.sh ./稿子
#   ./to_simplified.sh --ext txt,md,csv ./稿子

# ===== 默认参数（直接改这里）=====
# 空格分隔，不区分大小写。
EXTS="txt csv tsv srt md markdown ass vtt"
# 写在扩展名前面。会议.txt → 会议_simp.txt
OUTPUT_SUFFIX="_simp"
# OpenCC 配置。tw2sp 连常见词一起转（軟體→软件，網路→网络）。
# 只要逐字、不改词，改成 t2s。
OPENCC_CONFIG="tw2sp"
# =================================

set -euo pipefail
export LC_ALL=C

OVERWRITE=0

usage() {
	cat <<EOF
用法: $(basename "$0") [选项] 文件或文件夹 ...

繁体转简体，不联网。默认扩展名：${EXTS}
给文件夹时只处理这一层。输出为 原名${OUTPUT_SUFFIX}.原扩展名。

选项:
      --ext LIST          改用这一组扩展名，逗号分隔，如 txt,csv,srt,md
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
	--ext)
		need_arg "$@"
		EXTS="${2//,/ }"
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

command -v opencc >/dev/null 2>&1 || die "未找到 opencc。离线安装：sudo apt install opencc"
command -v iconv >/dev/null 2>&1 || die "未找到 iconv"

ext_ok() {
	local name ext lower
	name=$(basename "$1")
	[[ "$name" == *.* ]] || return 1
	ext="${name##*.}"
	lower=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
	local item
	for item in $EXTS; do
		item=$(printf '%s' "$item" | tr '[:upper:]' '[:lower:]')
		[[ "$lower" == "$item" ]] && return 0
	done
	return 1
}

out_path_for() {
	local in="$1" dir base stem ext
	dir=$(dirname "$in")
	base=$(basename "$in")
	ext="${base##*.}"
	stem="${base%.*}"
	printf '%s\n' "${dir}/${stem}${OUTPUT_SUFFIX}.${ext}"
}

# 读成 UTF-8 再交给 OpenCC。已经是 UTF-8 就直接转。
convert_one() {
	local in="$1" out="$2" tmp utf enc
	tmp=$(mktemp)
	utf=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f '$tmp' '$utf'" RETURN
	if iconv -f UTF-8 -t UTF-8 "$in" >"$utf" 2>/dev/null; then
		:
	else
		enc=""
		local try
		for try in BIG5 GB18030 GBK; do
			if iconv -f "$try" -t UTF-8 "$in" >"$utf" 2>/dev/null; then
				enc=$try
				break
			fi
		done
		if [[ -z "$enc" ]]; then
			rm -f "$tmp" "$utf"
			trap - RETURN
			echo "跳过: $in（不是 UTF-8 / BIG5 / GB18030 文本）" >&2
			return 1
		fi
		echo "编码: $in 按 ${enc} 读入"
	fi
	opencc -c "$OPENCC_CONFIG" -i "$utf" -o "$tmp" || return 1
	mv -f "$tmp" "$out"
	rm -f "$utf"
	trap - RETURN
	return 0
}

collect_from_dir() {
	local dir="$1"
	find "$dir" -maxdepth 1 -type f ! -name '.*' -print0 | sort -z
}

declare -a jobs=()
declare -a skipped=()

add_file() {
	local f="$1" base
	base=$(basename "$f")
	if [[ "$base" == *"${OUTPUT_SUFFIX}."* ]]; then
		skipped+=("$f（已是简体输出）")
		return
	fi
	if ! ext_ok "$f"; then
		skipped+=("$f（扩展名不在：${EXTS}）")
		return
	fi
	jobs+=("$f")
}

for arg in "$@"; do
	if [[ -d "$arg" ]]; then
		while IFS= read -r -d '' path; do
			add_file "$path"
		done < <(collect_from_dir "$arg")
	elif [[ -f "$arg" ]]; then
		add_file "$arg"
	else
		die "找不到: $arg"
	fi
done

if [[ "${#jobs[@]}" -eq 0 ]]; then
	echo "没有可转换的文本文件。" >&2
	if [[ "${#skipped[@]}" -gt 0 ]]; then
		printf '  %s\n' "${skipped[@]}" >&2
	fi
	exit 1
fi

echo "繁体 → 简体（OpenCC ${OPENCC_CONFIG}，不联网）"
echo "扩展名: ${EXTS}"
echo

ok=0
fail=0
declare -a done_lines=()
for src in "${jobs[@]}"; do
	dst=$(out_path_for "$src")
	if [[ -e "$dst" && "$OVERWRITE" -ne 1 ]]; then
		echo "跳过: $dst 已存在（加 -y 覆盖）"
		fail=$((fail + 1))
		continue
	fi
	if convert_one "$src" "$dst"; then
		echo "完成: $src → $dst"
		done_lines+=("$src → $dst")
		ok=$((ok + 1))
	else
		fail=$((fail + 1))
	fi
done

echo
echo "---------- 总结 ----------"
echo "转换: ${ok}"
echo "未转换: $((fail + ${#skipped[@]}))"
if [[ "${#done_lines[@]}" -gt 0 ]]; then
	printf '  %s\n' "${done_lines[@]}"
fi
if [[ "${#skipped[@]}" -gt 0 ]]; then
	printf '  %s\n' "${skipped[@]}"
fi
[[ "$fail" -eq 0 ]]
