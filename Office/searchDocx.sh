#!/bin/bash
# 在 Office 文档中搜索关键字（非交互，输出风格接近 grep，可管道）
#
# 用法:
#   ./searchDocx.sh [选项] <关键字> [路径...]
#   ./searchDocx.sh -x '合同' ./docs
#   ./searchDocx.sh -x -n -I 'API' . | grep -E '重要|紧急'
#
# 默认搜 .doc/.docx；加 -x 同时搜 .xls/.xlsx。
# 匹配走 stdout；进度/依赖提示走 stderr。退出码同 grep：有匹配 0，无匹配 1，出错 2。

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SEARCH_WORD=1
SEARCH_XLSX=0
IGNORE_CASE=1
SHOW_LINE_NUM=0
COLOR=auto   # always|never|auto
MAXDEPTH=""
PATTERN=""
PATHS=()
ERR_LOG="searchOffice.err"
HIT=0

usage() {
	cat <<EOF
用法: $SCRIPT_NAME [选项] <关键字> [路径...]

在目录中搜索 Office 文档正文（非交互）。默认路径为当前目录。

选项:
  -w, --word        搜索 Word（.doc /.docx），默认开启
  -x, --xlsx        同时搜索 Excel（.xls /.xlsx）
  -X, --xlsx-only   只搜索 Excel（关闭 Word）
  -i                忽略大小写（默认）
  -I                区分大小写
  -n                显示行号（path:行号:内容）
  --color[=WHEN]    always|never|auto（默认 auto；管道时自动关色）
  --maxdepth N      限制 find 深度
  -h, --help        帮助

环境变量:
  GREP_OPTS         追加传给 grep 的选项（例如 GREP_OPTS='-w'）

示例:
  $SCRIPT_NAME '加强组织领导'
  $SCRIPT_NAME -x -n '预算' ~/Documents
  $SCRIPT_NAME -X 'Sheet1' . 2>/dev/null | cut -d: -f1 | sort -u
EOF
}

die() {
	echo "$SCRIPT_NAME: $*" >&2
	exit 2
}

have_cmd() {
	command -v "$1" >/dev/null 2>&1
}

# 将文件抽出纯文本到 stdout；失败返回非 0
extract_text() {
	local file="$1"
	local ext="${file##*.}"
	ext="${ext,,}"

	case "$ext" in
	doc)
		if have_cmd catdoc; then
			catdoc "$file" 2>>"$ERR_LOG"
		elif have_cmd antiword; then
			antiword "$file" 2>>"$ERR_LOG"
		else
			return 1
		fi
		;;
	docx)
		if have_cmd docx2txt; then
			docx2txt <"$file" 2>>"$ERR_LOG"
		elif have_cmd pandoc; then
			pandoc -s "$file" -t plain 2>>"$ERR_LOG"
		else
			return 1
		fi
		;;
	xls)
		if have_cmd xls2csv; then
			xls2csv "$file" 2>>"$ERR_LOG"
		elif have_cmd ssconvert; then
			ssconvert -T Gnumeric_stf:stf_csv "$file" fd://1 2>>"$ERR_LOG"
		else
			return 1
		fi
		;;
	xlsx)
		if have_cmd xlsx2csv; then
			xlsx2csv "$file" 2>>"$ERR_LOG"
		elif have_cmd ssconvert; then
			ssconvert -T Gnumeric_stf:stf_csv "$file" fd://1 2>>"$ERR_LOG"
		elif have_cmd python3; then
			# 无第三方库：从 xlsx(zip) 抽 sharedStrings / 单元格文本
			python3 - "$file" <<'PY' 2>>"$ERR_LOG"
import sys, zipfile, re, xml.etree.ElementTree as ET
path = sys.argv[1]
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
try:
    z = zipfile.ZipFile(path)
except Exception as e:
    sys.stderr.write(str(e) + "\n")
    sys.exit(1)
shared = []
if "xl/sharedStrings.xml" in z.namelist():
    root = ET.fromstring(z.read("xl/sharedStrings.xml"))
    for si in root.findall("m:si", NS):
        texts = [t.text or "" for t in si.findall(".//m:t", NS)]
        shared.append("".join(texts))
for name in sorted(n for n in z.namelist() if n.startswith("xl/worksheets/sheet") and n.endswith(".xml")):
    root = ET.fromstring(z.read(name))
    rows = []
    for row in root.findall("m:sheetData/m:row", NS):
        cells = []
        for c in row.findall("m:c", NS):
            t = c.get("t")
            v = c.find("m:v", NS)
            if v is None or v.text is None:
                cells.append("")
                continue
            if t == "s":
                try:
                    cells.append(shared[int(v.text)])
                except Exception:
                    cells.append(v.text)
            else:
                cells.append(v.text)
        rows.append("\t".join(cells))
    sys.stdout.write("\n".join(rows) + "\n")
PY
		else
			return 1
		fi
		;;
	*)
		return 1
		;;
	esac
}

check_deps_for_types() {
	local missing=()
	if [ "$SEARCH_WORD" -eq 1 ]; then
		if ! have_cmd catdoc && ! have_cmd antiword; then
			missing+=("catdoc|antiword(.doc)")
		fi
		if ! have_cmd docx2txt && ! have_cmd pandoc; then
			missing+=("docx2txt|pandoc(.docx)")
		fi
	fi
	if [ "$SEARCH_XLSX" -eq 1 ]; then
		if ! have_cmd xls2csv && ! have_cmd ssconvert; then
			missing+=("xls2csv|ssconvert(.xls)")
		fi
		if ! have_cmd xlsx2csv && ! have_cmd ssconvert && ! have_cmd python3; then
			missing+=("xlsx2csv|ssconvert|python3(.xlsx)")
		fi
	fi
	if [ "${#missing[@]}" -gt 0 ]; then
		echo "缺少依赖（将跳过对应类型）: ${missing[*]}" >&2
		echo "可尝试: sudo apt install catdoc docx2txt gnumeric  或 python3" >&2
	fi
}

use_color() {
	case "$COLOR" in
	always) return 0 ;;
	never) return 1 ;;
	auto)
		[ -t 1 ] && return 0
		return 1
		;;
	*) return 1 ;;
	esac
}

search_file() {
	local file="$1"
	local grep_args=()
	local label_args=()

	[ "$IGNORE_CASE" -eq 1 ] && grep_args+=(-i)
	[ "$SHOW_LINE_NUM" -eq 1 ] && grep_args+=(-n)

	if use_color; then
		grep_args+=(--color=always)
	else
		grep_args+=(--color=never)
	fi

	# shellcheck disable=SC2206
	local extra=( ${GREP_OPTS:-} )

	# grep 无文件名时用 --label；有 -H 更稳
	if extract_text "$file" | grep -H --label="$file" "${grep_args[@]}" "${extra[@]}" -- "$PATTERN"; then
		HIT=1
	fi
	return 0
}

# ---- 参数解析 ----
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	-w | --word)
		SEARCH_WORD=1
		shift
		;;
	-x | --xlsx)
		SEARCH_XLSX=1
		shift
		;;
	-X | --xlsx-only)
		SEARCH_WORD=0
		SEARCH_XLSX=1
		shift
		;;
	-i)
		IGNORE_CASE=1
		shift
		;;
	-I)
		IGNORE_CASE=0
		shift
		;;
	-n)
		SHOW_LINE_NUM=1
		shift
		;;
	--color)
		COLOR=auto
		shift
		;;
	--color=*)
		COLOR="${1#*=}"
		shift
		;;
	--maxdepth)
		[ $# -ge 2 ] || die "--maxdepth 需要参数"
		MAXDEPTH="$2"
		shift 2
		;;
	--)
		shift
		break
		;;
	-*)
		die "未知选项: $1（见 --help）"
		;;
	*)
		if [ -z "$PATTERN" ]; then
			PATTERN="$1"
		else
			PATHS+=("$1")
		fi
		shift
		;;
	esac
done

# -- 之后剩余全当路径
while [ $# -gt 0 ]; do
	PATHS+=("$1")
	shift
done

[ -n "$PATTERN" ] || {
	usage >&2
	die "请提供搜索关键字"
}

if [ "${#PATHS[@]}" -eq 0 ]; then
	PATHS=(.)
fi

: >"$ERR_LOG"
check_deps_for_types

name_exprs=()
if [ "$SEARCH_WORD" -eq 1 ]; then
	name_exprs+=( -name '*.doc' -o -name '*.docx' -o -name '*.DOC' -o -name '*.DOCX' )
fi
if [ "$SEARCH_XLSX" -eq 1 ]; then
	if [ "${#name_exprs[@]}" -gt 0 ]; then
		name_exprs+=( -o )
	fi
	name_exprs+=( -name '*.xls' -o -name '*.xlsx' -o -name '*.XLS' -o -name '*.XLSX' )
fi

if [ "${#name_exprs[@]}" -eq 0 ]; then
	die "未选择任何文件类型（不要同时关掉 word 又不开 xlsx）"
fi

find_args=()
if [ -n "$MAXDEPTH" ]; then
	find_args+=( -maxdepth "$MAXDEPTH" )
fi

echo "关键字: $PATTERN" >&2
echo "范围: ${PATHS[*]}  word=$SEARCH_WORD xlsx=$SEARCH_XLSX" >&2

# 收集文件列表（NUL 安全）
while IFS= read -r -d '' f; do
	echo "扫描: $f" >&2
	search_file "$f" || true
done < <(find "${PATHS[@]}" "${find_args[@]}" \( "${name_exprs[@]}" \) -type f -print0 2>>"$ERR_LOG")

if [ "$HIT" -eq 1 ]; then
	exit 0
fi
echo "无匹配。" >&2
exit 1
