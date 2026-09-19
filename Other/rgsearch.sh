#!/usr/bin/env bash
# 基于 ripgrep(rg) 的文件搜索（正文 / 文件名；可选 Word、Excel）
#
# 用法:
#   ./rgsearch.sh '关键字' [路径...]
#   ./rgsearch.sh -F '报告' .                 # 只搜文件名（高亮匹配段）
#   ./rgsearch.sh -c -w -x '预算' ~/Docs      # 正文 + Word + Excel
#   ./rgsearch.sh -a -W '合同' .              # 文件名 + 正文（含 Office）
#
# 依赖: ripgrep；Word/Excel 另需 catdoc/antiword、docx2txt/pandoc、xlsx2csv 等（缺则跳过并提示）
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
MODE_CONTENT=1
MODE_FILENAME=0
SEARCH_WORD=0
SEARCH_EXCEL=0
IGNORE_CASE=1
LINE_NUM=1
COLOR=auto
MAX_DEPTH=""
HIDDEN=0
NO_IGNORE=0
FILES_ONLY=0
GLOB_ARGS=()
TYPE_ARGS=()
PATTERN=""
PATHS=()
EXPLICIT_F=0
EXPLICIT_C=0
EXPLICIT_A=0
ERR_LOG="$(mktemp -t rgsearch.XXXXXX.err 2>/dev/null || mktemp)"
HIT=0
trap 'rm -f "$ERR_LOG"' EXIT

C_RESET=""; C_MATCH=""; C_PATH=""; C_HEAD=""
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_MATCH=$'\033[1;31m'
  C_PATH=$'\033[0;36m'
  C_HEAD=$'\033[1;34m'
fi

usage() {
  cat <<EOF
用法: $SCRIPT_NAME [选项] <关键字> [路径...]

基于 rg 搜索；可选同时扫 Word / Excel 正文。默认路径为当前目录。

模式:
  -c, --content       搜文件内容（默认开启）
  -F, --filename      搜文件名（高亮匹配段；单独用则只搜文件名）
  -a, --all           内容 + 文件名

Office 正文（默认关闭；与 -F 同用时会同时搜正文）:
  -w, --word          .doc / .docx / .wps
  -x, --excel         .xls / .xlsx / .et / .csv
  -W, --office        等同 -w -x

常用:
  -i / -I             忽略 / 区分大小写（默认忽略）
  -n / -N             内容行号开 / 关（默认开）
  -l                  只输出命中文件路径
  -g GLOB             rg glob（可多次）
  -t TYPE             rg 类型（可多次，如 -t py）
  --max-depth N       目录深度
  --hidden            含隐藏文件
  --no-ignore         不尊重 .gitignore
  --color[=WHEN]      always|never|auto
  -h, --help

短选项可合并，如 -Fwx、-awx、-cin（需参数的 -g/-t 请单独写）。

示例:
  $SCRIPT_NAME 'TODO'
  $SCRIPT_NAME -F '振兴' ~/Data
  $SCRIPT_NAME -Fwx '预算' ./docs
  $SCRIPT_NAME -awx '合同' . -g '*.md'
EOF
}

die() { echo "$SCRIPT_NAME: $*" >&2; exit 2; }
have() { command -v "$1" >/dev/null 2>&1; }

# 优先系统 rg，避免落到 IDE 自带的精简版
resolve_rg() {
  if [[ -x /usr/bin/rg ]]; then
    RG_BIN=/usr/bin/rg
  elif [[ -x /bin/rg ]]; then
    RG_BIN=/bin/rg
  else
    RG_BIN="$(type -P rg 2>/dev/null || true)"
    [[ -n "$RG_BIN" ]] || die "未安装 ripgrep。请: sudo apt install ripgrep"
  fi
}

rg() { command "$RG_BIN" "$@"; }

use_color() {
  case "$COLOR" in
    always) return 0 ;;
    never) return 1 ;;
    auto) [[ -t 1 ]];;
    *) return 1 ;;
  esac
}

refresh_colors() {
  if use_color; then
    C_RESET=$'\033[0m'
    C_MATCH=$'\033[1;31m'
    C_PATH=$'\033[0;36m'
    C_HEAD=$'\033[1;34m'
  else
    C_RESET=""; C_MATCH=""; C_PATH=""; C_HEAD=""
  fi
}

# 高亮路径里匹配的字段
highlight_path() {
  local path="$1"
  if ! use_color; then
    printf '%s\n' "$path"
    return
  fi
  IGNORE_CASE="$IGNORE_CASE" PATTERN="$PATTERN" \
    C_MATCH="$C_MATCH" C_PATH="$C_PATH" C_RESET="$C_RESET" \
    python3 - "$path" <<'PY'
import os, re, sys
path = sys.argv[1]
pat = os.environ["PATTERN"]
flags = re.I if os.environ.get("IGNORE_CASE") == "1" else 0
try:
    rx = re.compile(pat, flags)
except re.error:
    rx = re.compile(re.escape(pat), flags)
cm, cp, cr = os.environ["C_MATCH"], os.environ["C_PATH"], os.environ["C_RESET"]
out, last = [], 0
for m in rx.finditer(path):
    out.append(cp + path[last:m.start()] + cr)
    out.append(cm + m.group(0) + cr)
    last = m.end()
out.append(cp + path[last:] + cr)
print("".join(out))
PY
}

build_rg_common() {
  RG_COMMON=()
  if use_color; then RG_COMMON+=(--color=always); else RG_COMMON+=(--color=never); fi
  [[ "$IGNORE_CASE" -eq 1 ]] && RG_COMMON+=(-i)
  [[ "$LINE_NUM" -eq 1 && "$FILES_ONLY" -eq 0 ]] && RG_COMMON+=(-n)
  [[ "$FILES_ONLY" -eq 1 ]] && RG_COMMON+=(-l)
  [[ "$HIDDEN" -eq 1 ]] && RG_COMMON+=(--hidden)
  [[ "$NO_IGNORE" -eq 1 ]] && RG_COMMON+=(--no-ignore)
  [[ -n "$MAX_DEPTH" ]] && RG_COMMON+=(--max-depth "$MAX_DEPTH")
  local x
  for x in "${GLOB_ARGS[@]:-}"; do [[ -n "$x" ]] && RG_COMMON+=(-g "$x"); done
  for x in "${TYPE_ARGS[@]:-}"; do [[ -n "$x" ]] && RG_COMMON+=(-t "$x"); done
  RG_COMMON+=(-g '!.git/**' -g '!**/node_modules/**' -g '!**/.venv/**' -g '!**/.PythonVenv/**')
}

search_filenames() {
  echo "${C_HEAD}== 文件名 ==${C_RESET}" >&2
  local -a list_args=(--files)
  [[ "$HIDDEN" -eq 1 ]] && list_args+=(--hidden)
  [[ "$NO_IGNORE" -eq 1 ]] && list_args+=(--no-ignore)
  [[ -n "$MAX_DEPTH" ]] && list_args+=(--max-depth "$MAX_DEPTH")
  local x
  for x in "${GLOB_ARGS[@]:-}"; do [[ -n "$x" ]] && list_args+=(-g "$x"); done
  for x in "${TYPE_ARGS[@]:-}"; do [[ -n "$x" ]] && list_args+=(-t "$x"); done
  list_args+=(-g '!.git/**' -g '!**/node_modules/**')

  local -a filter_args=(--color=never)
  [[ "$IGNORE_CASE" -eq 1 ]] && filter_args+=(-i)
  filter_args+=(-e "$PATTERN")

  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    highlight_path "$line"
    HIT=1
  done < <(rg "${list_args[@]}" -- "${PATHS[@]}" 2>>"$ERR_LOG" | rg "${filter_args[@]}" || true)
}

search_content_rg() {
  echo "${C_HEAD}== 文件内容 (rg) ==${C_RESET}" >&2
  build_rg_common
  # Office 走专用通道，避免当二进制扫出乱码
  local -a excl=(
    -g '!*.doc' -g '!*.docx' -g '!*.DOC' -g '!*.DOCX' -g '!*.wps' -g '!*.WPS'
    -g '!*.xls' -g '!*.xlsx' -g '!*.XLS' -g '!*.XLSX' -g '!*.et' -g '!*.ET'
  )
  if rg "${RG_COMMON[@]}" "${excl[@]}" -e "$PATTERN" -- "${PATHS[@]}" 2>>"$ERR_LOG"; then
    HIT=1
  fi
  return 0
}

extract_office() {
  local file="$1" ext="${file##*.}"
  ext="${ext,,}"
  case "$ext" in
    doc)
      if have catdoc; then catdoc "$file" 2>>"$ERR_LOG"
      elif have antiword; then antiword "$file" 2>>"$ERR_LOG"
      else return 1; fi
      ;;
    docx|wps)
      if have docx2txt; then docx2txt <"$file" 2>>"$ERR_LOG"
      elif have pandoc; then pandoc -s "$file" -t plain 2>>"$ERR_LOG"
      else return 1; fi
      ;;
    xls)
      if have xls2csv; then xls2csv "$file" 2>>"$ERR_LOG"
      elif have ssconvert; then ssconvert -T Gnumeric_stf:stf_csv "$file" fd://1 2>>"$ERR_LOG"
      else return 1; fi
      ;;
    xlsx|et)
      if have xlsx2csv; then xlsx2csv "$file" 2>>"$ERR_LOG"
      elif have ssconvert; then ssconvert -T Gnumeric_stf:stf_csv "$file" fd://1 2>>"$ERR_LOG"
      elif have python3; then
        python3 - "$file" <<'PY' 2>>"$ERR_LOG"
import sys, zipfile, xml.etree.ElementTree as ET
path = sys.argv[1]
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
z = zipfile.ZipFile(path)
shared = []
if "xl/sharedStrings.xml" in z.namelist():
    root = ET.fromstring(z.read("xl/sharedStrings.xml"))
    for si in root.findall("m:si", NS):
        shared.append("".join(t.text or "" for t in si.findall(".//m:t", NS)))
for name in sorted(n for n in z.namelist() if n.startswith("xl/worksheets/sheet") and n.endswith(".xml")):
    root = ET.fromstring(z.read(name))
    for row in root.findall("m:sheetData/m:row", NS):
        cells = []
        for c in row.findall("m:c", NS):
            v = c.find("m:v", NS)
            if v is None or v.text is None:
                cells.append("")
            elif c.get("t") == "s":
                try:
                    cells.append(shared[int(v.text)])
                except Exception:
                    cells.append(v.text)
            else:
                cells.append(v.text)
        print("\t".join(cells))
PY
      else return 1; fi
      ;;
    csv) cat "$file" ;;
    *) return 1 ;;
  esac
}

search_office_content() {
  [[ "$SEARCH_WORD" -eq 1 || "$SEARCH_EXCEL" -eq 1 ]] || return 0
  echo "${C_HEAD}== Office 正文 ==${C_RESET}" >&2

  local -a miss=()
  if [[ "$SEARCH_WORD" -eq 1 ]]; then
    have catdoc || have antiword || miss+=("catdoc|antiword(.doc)")
    have docx2txt || have pandoc || miss+=("docx2txt|pandoc(.docx)")
  fi
  if [[ "$SEARCH_EXCEL" -eq 1 ]]; then
    have xlsx2csv || have ssconvert || have python3 || miss+=("xlsx2csv|python3(.xlsx)")
  fi
  [[ ${#miss[@]} -gt 0 ]] && echo "提示: 可能跳过部分类型（缺依赖）: ${miss[*]}" >&2

  local -a name_exprs=()
  if [[ "$SEARCH_WORD" -eq 1 ]]; then
    name_exprs+=( -iname '*.doc' -o -iname '*.docx' -o -iname '*.wps' )
  fi
  if [[ "$SEARCH_EXCEL" -eq 1 ]]; then
    [[ ${#name_exprs[@]} -gt 0 ]] && name_exprs+=( -o )
    name_exprs+=( -iname '*.xls' -o -iname '*.xlsx' -o -iname '*.et' -o -iname '*.csv' )
  fi

  local -a find_args=()
  [[ -n "$MAX_DEPTH" ]] && find_args+=( -maxdepth "$MAX_DEPTH" )

  local -a ga=()
  [[ "$IGNORE_CASE" -eq 1 ]] && ga+=(-i)
  if [[ "$FILES_ONLY" -eq 1 ]]; then
    ga+=(-q)
  else
    [[ "$LINE_NUM" -eq 1 ]] && ga+=(-n)
    if use_color; then ga+=(--color=always); else ga+=(--color=never); fi
  fi

  local f
  while IFS= read -r -d '' f; do
    if [[ "$FILES_ONLY" -eq 1 ]]; then
      if extract_office "$f" 2>>"$ERR_LOG" | grep "${ga[@]}" -- "$PATTERN" >/dev/null 2>&1; then
        printf '%s\n' "$f"
        HIT=1
      fi
    else
      if extract_office "$f" 2>>"$ERR_LOG" | grep -H --label="$f" "${ga[@]}" -- "$PATTERN"; then
        HIT=1
      fi
    fi
  done < <(find "${PATHS[@]}" "${find_args[@]}" \( "${name_exprs[@]}" \) -type f -print0 2>>"$ERR_LOG")
}

# ---- 参数（支持 -Fwx 这类短选项合并）----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --content) EXPLICIT_C=1; MODE_CONTENT=1; shift ;;
    --filename) EXPLICIT_F=1; MODE_FILENAME=1; shift ;;
    --all) EXPLICIT_A=1; MODE_CONTENT=1; MODE_FILENAME=1; shift ;;
    --word) SEARCH_WORD=1; shift ;;
    --excel) SEARCH_EXCEL=1; shift ;;
    --office) SEARCH_WORD=1; SEARCH_EXCEL=1; shift ;;
    --max-depth) [[ $# -ge 2 ]] || die "--max-depth 需要参数"; MAX_DEPTH="$2"; shift 2 ;;
    --hidden) HIDDEN=1; shift ;;
    --no-ignore) NO_IGNORE=1; shift ;;
    --color) COLOR=auto; shift ;;
    --color=*) COLOR="${1#*=}"; shift ;;
    --) shift; break ;;
    --*) die "未知选项: $1（见 --help）" ;;
    -[FcaWwxIiNnlgth]*)
      _cluster="${1#-}"
      shift
      while [[ -n "$_cluster" ]]; do
        _c="${_cluster:0:1}"
        _cluster="${_cluster:1}"
        case "$_c" in
          c) EXPLICIT_C=1; MODE_CONTENT=1 ;;
          F) EXPLICIT_F=1; MODE_FILENAME=1 ;;
          a) EXPLICIT_A=1; MODE_CONTENT=1; MODE_FILENAME=1 ;;
          w) SEARCH_WORD=1 ;;
          x) SEARCH_EXCEL=1 ;;
          W) SEARCH_WORD=1; SEARCH_EXCEL=1 ;;
          i) IGNORE_CASE=1 ;;
          I) IGNORE_CASE=0 ;;
          n) LINE_NUM=1 ;;
          N) LINE_NUM=0 ;;
          l) FILES_ONLY=1 ;;
          h) usage; exit 0 ;;
          g)
            [[ -z "$_cluster" ]] || die "-g 不能夹在合并短选项中间，请用: -g GLOB"
            [[ $# -ge 1 ]] || die "-g 需要参数"
            GLOB_ARGS+=("$1"); shift
            ;;
          t)
            [[ -z "$_cluster" ]] || die "-t 不能夹在合并短选项中间，请用: -t TYPE"
            [[ $# -ge 1 ]] || die "-t 需要参数"
            TYPE_ARGS+=("$1"); shift
            ;;
          *) die "未知短选项: -$_c（见 --help）" ;;
        esac
      done
      ;;
    -*) die "未知选项: $1（见 --help）" ;;
    *)
      if [[ -z "$PATTERN" ]]; then PATTERN="$1"; else PATHS+=("$1"); fi
      shift
      ;;
  esac
done
while [[ $# -gt 0 ]]; do PATHS+=("$1"); shift; done

[[ -n "$PATTERN" ]] || { usage >&2; die "请提供关键字"; }
[[ ${#PATHS[@]} -eq 0 ]] && PATHS=(.)

# -F 单独 → 只搜文件名；-Fwx / -F -w -x → 文件名 + 正文（含 Office）
if [[ "$EXPLICIT_F" -eq 1 && "$EXPLICIT_C" -eq 0 && "$EXPLICIT_A" -eq 0 \
   && "$SEARCH_WORD" -eq 0 && "$SEARCH_EXCEL" -eq 0 ]]; then
  MODE_CONTENT=0
elif [[ "$EXPLICIT_F" -eq 1 && ( "$SEARCH_WORD" -eq 1 || "$SEARCH_EXCEL" -eq 1 || "$EXPLICIT_C" -eq 1 ) ]]; then
  MODE_CONTENT=1
  MODE_FILENAME=1
fi

resolve_rg
refresh_colors
: >"$ERR_LOG"

echo "关键字: $PATTERN" >&2
echo "范围: ${PATHS[*]}  内容=$MODE_CONTENT 文件名=$MODE_FILENAME word=$SEARCH_WORD excel=$SEARCH_EXCEL" >&2

[[ "$MODE_FILENAME" -eq 1 ]] && search_filenames
[[ "$MODE_CONTENT" -eq 1 ]] && search_content_rg
[[ "$MODE_CONTENT" -eq 1 ]] && search_office_content

if [[ "$HIT" -eq 1 ]]; then
  exit 0
fi
echo "无匹配。" >&2
exit 1
