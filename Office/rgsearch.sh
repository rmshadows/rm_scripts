#!/usr/bin/env bash
# 文件搜索（正文 / 文件名；可选 Word、Excel）
#
# 用法:
#   ./rgsearch.sh '关键字' [路径...]
#   ./rgsearch.sh -F '报告' .                 # 只搜文件名（高亮匹配段）
#   ./rgsearch.sh -c -w -x '预算' ~/Docs      # 正文 + Word + Excel
#   ./rgsearch.sh -a -W '合同' .              # 文件名 + 正文（含 Office）
#   ./rgsearch.sh --profile low -w '合同' .   # 低配：单线程、让出 CPU、跳过大文件
#   ./rgsearch.sh --profile high -j 12 -W '合同'
#
# 引擎: 优先系统 rg，没有 rg 时用 ag。两个都没有就从 GitHub 发布包拉取 rg。
#       强制：RGSEARCH_BACKEND=rg 或 ag。缓存目录：RGSEARCH_CACHE。
# Word/Excel 另需 catdoc/antiword、docx2txt/pandoc、xlsx2csv 等（缺则跳过并提示）。
# 纯文本里没有正则符号时按固定字符串搜，更快。
# 默认只显示命中行。-C/-A/-B 控制上下文。
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
PROFILE="${RGSEARCH_PROFILE:-auto}"
JOBS="${RGSEARCH_JOBS:-}"
OFFICE_MB_OVERRIDE=""
BACKEND=""
RG_BIN=""
AG_BIN=""
PROFILE_TIER=""
NICE_LEVEL=0
IONICE_ARGS=()
TEXT_JOBS=1
OFFICE_JOBS=1
TEXT_MAX_SIZE=""
OFFICE_MAX_BYTES=0
LITERAL=0
CONTEXT_BEFORE=""
CONTEXT_AFTER=""
RG_RELEASE="${RGSEARCH_RG_VERSION:-14.1.1}"
TOOL_CACHE="${RGSEARCH_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/rgsearch}"
CPU_COUNT=1
MEM_MB=0
HIT_MARK=""
EXPLICIT_F=0
EXPLICIT_C=0
EXPLICIT_A=0
ERR_LOG="$(mktemp -t rgsearch.XXXXXX.err 2>/dev/null || mktemp)"
HIT=0
trap 'rm -f "$ERR_LOG" ${HIT_MARK:+"$HIT_MARK"}' EXIT

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
  -C N, --context N   命中行上下各 N 行（默认 0，只显示命中行）
  -A N, --after N     命中行后再显示 N 行
  -B N, --before N    命中行前再显示 N 行
  -l                  只输出命中文件路径
  -g GLOB             rg glob（可多次）
  -t TYPE             rg 类型（可多次，如 -t py）
  --max-depth N       目录深度
  --hidden            含隐藏文件
  --no-ignore         不尊重 .gitignore
  --color[=WHEN]      always|never|auto
  --profile P         low|mid|high|auto（默认 auto，按内存和核数选）
  -j, --jobs N        文本线程数，同时用作 Office 并行数。0 表示按 profile
  --max-office-mb N   超过此大小的 Word/Excel 不抽文本。0 表示不限制
  -h, --help

资源:
  low   1 线程，nice 19，文本最大 2M，Office 最大 8M
  mid   最多 4 线程，文本 20M，Office 80M
  high  用满 CPU，文本不限大小，Office 单文件仍限 256M（--max-office-mb 0 可放开）
  环境变量 RGSEARCH_PROFILE、RGSEARCH_JOBS、RGSEARCH_BACKEND=rg|ag
  本机没有 rg 也没有 ag 时，自动从 GitHub 拉取 ripgrep ${RG_RELEASE} 到 \$RGSEARCH_CACHE

短选项可合并，如 -Fwx、-awx、-cin（需参数的 -g/-t/-j/-A/-B/-C 请单独写，或写成 -C2）。

示例:
  $SCRIPT_NAME 'TODO'
  $SCRIPT_NAME -C 3 'TODO'
  $SCRIPT_NAME -B 2 -A 5 'TODO'
  $SCRIPT_NAME -F '振兴' ~/Data
  $SCRIPT_NAME -Fwx '预算' ./docs
  $SCRIPT_NAME --profile low -w '合同' .
  $SCRIPT_NAME --profile high -j 12 -W '合同' ~/Docs
EOF
}

die() { echo "$SCRIPT_NAME: $*" >&2; exit 2; }

# 参数写错时先说明错在哪，再把用法打出来。
usage_err() {
  echo "$SCRIPT_NAME: $*" >&2
  echo >&2
  usage >&2
  exit 2
}
have() { command -v "$1" >/dev/null 2>&1; }

# 系统里已有的 rg。找不到再看上次拉取的缓存。
find_rg() {
  if [[ -x /usr/bin/rg ]]; then
    printf '%s\n' /usr/bin/rg
  elif [[ -x /bin/rg ]]; then
    printf '%s\n' /bin/rg
  elif [[ -x "$TOOL_CACHE/rg" ]]; then
    printf '%s\n' "$TOOL_CACHE/rg"
  else
    type -P rg 2>/dev/null || true
  fi
}

find_ag() {
  local ag_path=""
  ag_path="$(type -P ag 2>/dev/null || true)"
  if [[ -n "$ag_path" ]]; then
    printf '%s\n' "$ag_path"
  elif [[ -x "$TOOL_CACHE/ag" ]]; then
    printf '%s\n' "$TOOL_CACHE/ag"
  fi
}

# 本机没有 rg/ag 时，从 ripgrep 的 GitHub 发布包拉 musl 静态二进制。
fetch_rg() {
  local arch url tgz unpack bin
  case "$(uname -m)" in
    x86_64|amd64) arch=x86_64-unknown-linux-musl ;;
    aarch64|arm64) arch=aarch64-unknown-linux-musl ;;
    i686|i386) arch=i686-unknown-linux-musl ;;
    *) die "没有 rg/ag，架构 $(uname -m) 没有对应的 ripgrep 发布包" ;;
  esac
  url="https://github.com/BurntSushi/ripgrep/releases/download/${RG_RELEASE}/ripgrep-${RG_RELEASE}-${arch}.tar.gz"
  mkdir -p "$TOOL_CACHE"
  tgz="$TOOL_CACHE/ripgrep-${RG_RELEASE}-${arch}.tar.gz"
  unpack="$TOOL_CACHE/unpack-${RG_RELEASE}-${arch}"
  echo "未找到 rg 和 ag，正在从 GitHub 仓库拉取 ripgrep ${RG_RELEASE} ..." >&2
  echo "  $url" >&2
  if have curl; then
    curl -fL --retry 2 --retry-delay 1 -o "$tgz" "$url" || die "拉取失败。可稍后重试，或: sudo apt install ripgrep"
  elif have wget; then
    wget -O "$tgz" "$url" || die "拉取失败。可稍后重试，或: sudo apt install ripgrep"
  else
    die "没有 curl 或 wget，无法拉取。请: sudo apt install ripgrep    或    sudo apt install curl"
  fi
  mkdir -p "$unpack"
  tar -xzf "$tgz" -C "$unpack" || die "解压失败: $tgz"
  bin=""
  while IFS= read -r bin; do
    [[ -n "$bin" ]] && break
  done < <(find "$unpack" -type f -name rg)
  [[ -n "$bin" ]] || die "压缩包里没有 rg: $url"
  install -m 755 "$bin" "$TOOL_CACHE/rg"
  "$TOOL_CACHE/rg" --version >/dev/null || die "拉取到的 rg 无法运行: $TOOL_CACHE/rg"
  echo "已放到 $TOOL_CACHE/rg" >&2
  printf '%s\n' "$TOOL_CACHE/rg"
}

# 优先系统 rg。没有 rg 时用 ag。两个都没有就拉取 rg。RGSEARCH_BACKEND=rg|ag 可强制。
resolve_backend() {
  local want="${RGSEARCH_BACKEND:-auto}" rg_path="" ag_path=""
  rg_path="$(find_rg || true)"
  ag_path="$(find_ag || true)"
  case "$want" in
    rg)
      if [[ -z "$rg_path" ]]; then
        rg_path="$(fetch_rg)"
      fi
      BACKEND=rg
      RG_BIN="$rg_path"
      ;;
    ag)
      if [[ -z "$ag_path" ]]; then
        usage_err "指定使用 ag，但本机没有 ag。ag 没有官方独立程序包。去掉 RGSEARCH_BACKEND 会自动拉取 rg，或: sudo apt install silversearcher-ag"
      fi
      BACKEND=ag
      AG_BIN="$ag_path"
      ;;
    auto|"")
      if [[ -n "$rg_path" ]]; then
        BACKEND=rg
        RG_BIN="$rg_path"
      elif [[ -n "$ag_path" ]]; then
        BACKEND=ag
        AG_BIN="$ag_path"
        echo "未找到 rg，改用 ag: $AG_BIN" >&2
      else
        rg_path="$(fetch_rg)"
        BACKEND=rg
        RG_BIN="$rg_path"
      fi
      ;;
    *) usage_err "RGSEARCH_BACKEND 只能是 auto、rg、ag，收到: $want" ;;
  esac
}

# 按内存和核数决定线程、优先级、单文件上限。--jobs / --max-office-mb 可盖过。
apply_profile() {
  CPU_COUNT="$(nproc 2>/dev/null || echo 1)"
  [[ "$CPU_COUNT" =~ ^[0-9]+$ ]] || CPU_COUNT=1
  MEM_MB="$(awk '/MemAvailable:/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
  [[ "$MEM_MB" =~ ^[0-9]+$ ]] || MEM_MB=0
  case "$PROFILE" in
    auto)
      if (( MEM_MB > 0 && MEM_MB < 2048 )) || (( CPU_COUNT <= 2 )); then
        PROFILE_TIER=low
      elif (( MEM_MB >= 8192 && CPU_COUNT >= 8 )); then
        PROFILE_TIER=high
      else
        PROFILE_TIER=mid
      fi
      ;;
    low|mid|high) PROFILE_TIER="$PROFILE" ;;
    *) usage_err "--profile 只能是 low、mid、high、auto，收到: $PROFILE" ;;
  esac

  local jobs_req=""
  if [[ -n "$JOBS" && "$JOBS" != 0 ]]; then
    [[ "$JOBS" =~ ^[0-9]+$ ]] || usage_err "--jobs 需要非负整数，收到: $JOBS"
    jobs_req="$JOBS"
  fi

  case "$PROFILE_TIER" in
    low)
      TEXT_JOBS=1
      OFFICE_JOBS=1
      NICE_LEVEL=19
      IONICE_ARGS=(-c 2 -n 7)
      TEXT_MAX_SIZE=2M
      OFFICE_MAX_BYTES=$((8 * 1024 * 1024))
      ;;
    mid)
      TEXT_JOBS=$(( CPU_COUNT < 4 ? CPU_COUNT : 4 ))
      OFFICE_JOBS=$(( CPU_COUNT < 2 ? CPU_COUNT : 2 ))
      NICE_LEVEL=5
      IONICE_ARGS=(-c 2 -n 4)
      TEXT_MAX_SIZE=20M
      OFFICE_MAX_BYTES=$((80 * 1024 * 1024))
      ;;
    high)
      TEXT_JOBS=$CPU_COUNT
      OFFICE_JOBS=$(( CPU_COUNT < 8 ? CPU_COUNT : 8 ))
      NICE_LEVEL=0
      IONICE_ARGS=()
      TEXT_MAX_SIZE=""
      OFFICE_MAX_BYTES=$((256 * 1024 * 1024))
      ;;
  esac
  if [[ -n "$jobs_req" ]]; then
    TEXT_JOBS=$jobs_req
    OFFICE_JOBS=$jobs_req
  fi
  (( TEXT_JOBS < 1 )) && TEXT_JOBS=1
  (( OFFICE_JOBS < 1 )) && OFFICE_JOBS=1
  if [[ -n "$OFFICE_MB_OVERRIDE" ]]; then
    [[ "$OFFICE_MB_OVERRIDE" =~ ^[0-9]+$ ]] || usage_err "--max-office-mb 需要非负整数，收到: $OFFICE_MB_OVERRIDE"
    if (( OFFICE_MB_OVERRIDE == 0 )); then
      OFFICE_MAX_BYTES=0
    else
      OFFICE_MAX_BYTES=$((OFFICE_MB_OVERRIDE * 1024 * 1024))
    fi
  fi
}

# nice/ionice 包住外部搜索进程。Office 子进程里再 renice 自己。
run_limited() {
  if (( NICE_LEVEL > 0 )) && command -v nice >/dev/null 2>&1; then
    if ((${#IONICE_ARGS[@]})) && command -v ionice >/dev/null 2>&1; then
      ionice "${IONICE_ARGS[@]}" nice -n "$NICE_LEVEL" "$@"
    else
      nice -n "$NICE_LEVEL" "$@"
    fi
  else
    "$@"
  fi
}

pattern_is_literal() {
  local rest="$PATTERN" c
  while [[ -n "$rest" ]]; do
    c="${rest:0:1}"
    rest="${rest:1}"
    case "$c" in
      '.'|'*'|'+'|'?'|'['|']'|'('|')'|'{'|'}'|'|'|'^'|'$'|'\\') return 1 ;;
    esac
  done
  return 0
}

# ag 2.2 的 -i 按字节做大小写折叠，中文关键字会失配。含非 ASCII 时不传 -i。
ag_case_opts() {
  if [[ "$IGNORE_CASE" -eq 0 ]]; then
    printf '%s\n' -s
    return 0
  fi
  if [[ "$PATTERN" == *[![:ascii:]]* ]]; then
    echo "ag 对含中文的关键字不使用 -i，否则会失配" >&2
    return 0
  fi
  printf '%s\n' -i
}

lower_worker_priority() {
  if (( NICE_LEVEL > 0 )); then
    renice -n "$NICE_LEVEL" -p $$ >/dev/null 2>&1 || true
    if ((${#IONICE_ARGS[@]})) && command -v ionice >/dev/null 2>&1; then
      ionice "${IONICE_ARGS[@]}" -p $$ >/dev/null 2>&1 || true
    fi
  fi
}

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
  if ((${#GLOB_ARGS[@]})); then
    for x in "${GLOB_ARGS[@]}"; do
      RG_COMMON+=(-g "$x")
    done
  fi
  if ((${#TYPE_ARGS[@]})); then
    for x in "${TYPE_ARGS[@]}"; do
      RG_COMMON+=(-t "$x")
    done
  fi
  RG_COMMON+=(-g '!.git/**' -g '!**/node_modules/**' -g '!**/.venv/**' -g '!**/.PythonVenv/**')
  if [[ -n "$TEXT_MAX_SIZE" ]]; then
    RG_COMMON+=(--max-filesize "$TEXT_MAX_SIZE")
  fi
  RG_COMMON+=(-j "$TEXT_JOBS")
  if [[ "$LITERAL" -eq 1 ]]; then
    RG_COMMON+=(-F)
  fi
  append_context RG_COMMON
}

# 命中行前后再多显示几行。没指定就保持现在这样，只输出命中行。
append_context() {
  local -n _ctx=$1
  if [[ -n "$CONTEXT_BEFORE" && "$CONTEXT_BEFORE" == "$CONTEXT_AFTER" ]]; then
    _ctx+=(-C "$CONTEXT_BEFORE")
    return 0
  fi
  if [[ -n "$CONTEXT_BEFORE" ]]; then
    _ctx+=(-B "$CONTEXT_BEFORE")
  fi
  if [[ -n "$CONTEXT_AFTER" ]]; then
    _ctx+=(-A "$CONTEXT_AFTER")
  fi
}

# ag 没有 rg 的 -g/-t/-j。*.后缀 会转成正则；线程数控不住，只靠 nice。
ag_common_limits() {
  local -n _out=$1
  [[ "$HIDDEN" -eq 1 ]] && _out+=(--hidden)
  [[ "$NO_IGNORE" -eq 1 ]] && _out+=(-U)
  [[ -n "$MAX_DEPTH" ]] && _out+=(--depth "$MAX_DEPTH")
  _out+=(--ignore .git --ignore node_modules --ignore .venv --ignore .PythonVenv)
  local g ext joined=""
  if ((${#GLOB_ARGS[@]})); then
    for g in "${GLOB_ARGS[@]}"; do
      if [[ "$g" == \*.* && "$g" != *\**\** ]]; then
        ext="${g#\*.}"
        ext="${ext//./\\.}"
        [[ -n "$joined" ]] && joined+="|"
        joined+="\\.${ext}\$"
      else
        echo "ag 跳过 -g $g（只支持 *.后缀）" >&2
      fi
    done
  fi
  [[ -n "$joined" ]] && _out+=(-G "$joined")
  local t
  if ((${#TYPE_ARGS[@]})); then
    for t in "${TYPE_ARGS[@]}"; do
      if [[ "$t" =~ ^[A-Za-z0-9_+-]+$ ]]; then
        _out+=("--$t")
      fi
    done
  fi
}

search_filenames_rg() {
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
  [[ "$LITERAL" -eq 1 ]] && filter_args+=(-F)
  filter_args+=(-e "$PATTERN")

  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    highlight_path "$line"
    HIT=1
  done < <(run_limited "$RG_BIN" "${list_args[@]}" -- "${PATHS[@]}" 2>>"$ERR_LOG" | "$RG_BIN" "${filter_args[@]}" || true)
}

search_filenames_ag() {
  echo "${C_HEAD}== 文件名 ==${C_RESET}" >&2
  local -a args=(--nocolor --noheading)
  local copt
  while IFS= read -r copt; do
    [[ -n "$copt" ]] && args+=("$copt")
  done < <(ag_case_opts)
  [[ "$LITERAL" -eq 1 ]] && args+=(-Q)
  ag_common_limits args
  args+=(-g "$PATTERN")
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    highlight_path "$line"
    HIT=1
  done < <(run_limited "$AG_BIN" "${args[@]}" -- "${PATHS[@]}" 2>>"$ERR_LOG" || true)
}

search_filenames() {
  if [[ "$BACKEND" == ag ]]; then
    search_filenames_ag
  else
    search_filenames_rg
  fi
}

search_content_text() {
  if [[ "$BACKEND" == ag ]]; then
    echo "${C_HEAD}== 文件内容 (ag) ==${C_RESET}" >&2
    local -a args=(--noheading --nobreak)
    if use_color; then args+=(--color); else args+=(--nocolor); fi
    local copt
    while IFS= read -r copt; do
      [[ -n "$copt" ]] && args+=("$copt")
    done < <(ag_case_opts)
    [[ "$LINE_NUM" -eq 0 || "$FILES_ONLY" -eq 1 ]] && args+=(--nonumbers)
    [[ "$FILES_ONLY" -eq 1 ]] && args+=(-l)
    [[ "$LITERAL" -eq 1 ]] && args+=(-Q)
    append_context args
    ag_common_limits args
    local ext
    for ext in doc docx DOC DOCX wps WPS xls xlsx XLS XLSX et ET; do
      args+=(--ignore "*.${ext}")
    done
    if run_limited "$AG_BIN" "${args[@]}" -- "$PATTERN" "${PATHS[@]}" 2>>"$ERR_LOG"; then
      HIT=1
    fi
    return 0
  fi

  echo "${C_HEAD}== 文件内容 (rg) ==${C_RESET}" >&2
  build_rg_common
  # Office 走专用通道，避免当二进制扫出乱码
  local -a excl=(
    -g '!*.doc' -g '!*.docx' -g '!*.DOC' -g '!*.DOCX' -g '!*.wps' -g '!*.WPS'
    -g '!*.xls' -g '!*.xlsx' -g '!*.XLS' -g '!*.XLSX' -g '!*.et' -g '!*.ET'
  )
  # 开了 Excel 通道时，csv 只走抽文本，避免和 rg 各报一遍。
  if [[ "$SEARCH_EXCEL" -eq 1 ]]; then
    excl+=(-g '!*.csv' -g '!*.CSV')
  fi
  if run_limited "$RG_BIN" "${RG_COMMON[@]}" "${excl[@]}" -e "$PATTERN" -- "${PATHS[@]}" 2>>"$ERR_LOG"; then
    HIT=1
  fi
  return 0
}

extract_office() {
  # 不能写成 local file="$1" ext="${file##*.}"。set -u 下同一条 local 里
  # file 还没赋值，${file} 会直接让整个脚本退出。
  local file="$1" ext
  ext="${file##*.}"
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

  # 全局数组。后台 worker 看不到函数里的 local 数组。
  GREP_OFFICE=()
  [[ "$IGNORE_CASE" -eq 1 ]] && GREP_OFFICE+=(-i)
  [[ "$LITERAL" -eq 1 ]] && GREP_OFFICE+=(-F)
  append_context GREP_OFFICE
  if [[ "$FILES_ONLY" -eq 1 ]]; then
    GREP_OFFICE+=(-q)
  else
    [[ "$LINE_NUM" -eq 1 ]] && GREP_OFFICE+=(-n)
    if use_color; then GREP_OFFICE+=(--color=always); else GREP_OFFICE+=(--color=never); fi
  fi

  HIT_MARK="$(mktemp)"
  local f sz queued=0 skipped=0 running=0
  while IFS= read -r -d '' f; do
    sz="$(stat -c %s "$f" 2>/dev/null || echo 0)"
    if (( OFFICE_MAX_BYTES > 0 && sz > OFFICE_MAX_BYTES )); then
      skipped=$((skipped + 1))
      continue
    fi
    queued=$((queued + 1))
    if (( OFFICE_JOBS <= 1 )); then
      office_worker "$f" || true
    else
      office_worker "$f" &
      running=$((running + 1))
      if (( running >= OFFICE_JOBS )); then
        wait -n || true
        running=$((running - 1))
      fi
    fi
  done < <(find "${PATHS[@]}" "${find_args[@]}" \( "${name_exprs[@]}" \) -type f -print0 2>>"$ERR_LOG")
  if (( OFFICE_JOBS > 1 )); then
    wait || true
  fi
  [[ -s "$HIT_MARK" ]] && HIT=1
  echo "Office: 扫描 ${queued} ，并行 ${OFFICE_JOBS} ，跳过过大 ${skipped}" >&2
}

# 抽一个 Office 文件再 grep。后台跑时各自 renice，避免低配被抽文本占满。
office_worker() {
  local f="$1" tmp
  lower_worker_priority
  tmp="$(mktemp)"
  # 先落成文件再 grep。函数直接接管道时，抽出来的正文可能进不了 grep。
  if extract_office "$f" >"$tmp" 2>>"$ERR_LOG"; then
    if [[ "$FILES_ONLY" -eq 1 ]]; then
      if grep "${GREP_OFFICE[@]}" -q -- "$PATTERN" <"$tmp"; then
        printf '%s\n' "$f"
        echo 1 >>"$HIT_MARK"
      fi
    elif grep -H --label="$f" "${GREP_OFFICE[@]}" -- "$PATTERN" <"$tmp"; then
      echo 1 >>"$HIT_MARK"
    fi
  fi
  rm -f "$tmp"
  return 0
}

set_context_flag() {
  local flag="$1" val="$2"
  [[ "$val" =~ ^[0-9]+$ ]] || usage_err "$flag 的行数必须是非负整数，收到: ${val:-（空）}"
  case "$flag" in
    -C|--context)
      CONTEXT_BEFORE="$val"
      CONTEXT_AFTER="$val"
      ;;
    -A|--after|--after-context) CONTEXT_AFTER="$val" ;;
    -B|--before|--before-context) CONTEXT_BEFORE="$val" ;;
    *) usage_err "未知的上下文选项: $flag" ;;
  esac
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
    --max-depth) [[ $# -ge 2 ]] || usage_err "--max-depth 需要一个数字"; MAX_DEPTH="$2"; shift 2 ;;
    --profile) [[ $# -ge 2 ]] || usage_err "--profile 需要 low、mid、high 或 auto"; PROFILE="$2"; shift 2 ;;
    --jobs) [[ $# -ge 2 ]] || usage_err "--jobs 需要一个非负整数"; JOBS="$2"; shift 2 ;;
    --max-office-mb) [[ $# -ge 2 ]] || usage_err "--max-office-mb 需要一个非负整数，0 表示不限制"; OFFICE_MB_OVERRIDE="$2"; shift 2 ;;
    --context|--after|--before)
      [[ $# -ge 2 ]] || usage_err "$1 需要行数，例如 $1 2"
      set_context_flag "$1" "$2"
      shift 2
      ;;
    --context=*|--after=*|--before=*)
      set_context_flag "${1%%=*}" "${1#*=}"
      shift
      ;;
    --after-context) [[ $# -ge 2 ]] || usage_err "--after-context 需要行数"; set_context_flag --after "$2"; shift 2 ;;
    --before-context) [[ $# -ge 2 ]] || usage_err "--before-context 需要行数"; set_context_flag --before "$2"; shift 2 ;;
    --after-context=*) set_context_flag --after "${1#*=}"; shift ;;
    --before-context=*) set_context_flag --before "${1#*=}"; shift ;;
    --hidden) HIDDEN=1; shift ;;
    --no-ignore) NO_IGNORE=1; shift ;;
    --color) COLOR=auto; shift ;;
    --color=*) COLOR="${1#*=}"; shift ;;
    --) shift; break ;;
    --*) usage_err "未知选项: $1" ;;
    -[FcaWwxIiNnlgthjABC]*)
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
            [[ -z "$_cluster" ]] || usage_err "-g 不能夹在合并短选项中间，请写成: -g '*.md'"
            [[ $# -ge 1 ]] || usage_err "-g 需要一个通配符，例如 -g '*.md'"
            GLOB_ARGS+=("$1"); shift
            ;;
          t)
            [[ -z "$_cluster" ]] || usage_err "-t 不能夹在合并短选项中间，请写成: -t py"
            [[ $# -ge 1 ]] || usage_err "-t 需要一个类型，例如 -t py"
            TYPE_ARGS+=("$1"); shift
            ;;
          j)
            [[ -z "$_cluster" ]] || usage_err "-j 不能夹在合并短选项中间，请写成: -j 4"
            [[ $# -ge 1 ]] || usage_err "-j 需要一个非负整数，例如 -j 4"
            JOBS="$1"; shift
            ;;
          A|B|C)
            if [[ -n "$_cluster" ]]; then
              set_context_flag "-$_c" "$_cluster"
              _cluster=""
            else
              [[ $# -ge 1 ]] || usage_err "-$_c 需要行数，例如 -$_c 2"
              set_context_flag "-$_c" "$1"
              shift
            fi
            ;;
          *) usage_err "未知短选项: -$_c" ;;
        esac
      done
      ;;
    -*) usage_err "未知选项: $1" ;;
    *)
      if [[ -z "$PATTERN" ]]; then PATTERN="$1"; else PATHS+=("$1"); fi
      shift
      ;;
  esac
done
while [[ $# -gt 0 ]]; do PATHS+=("$1"); shift; done

[[ -n "$PATTERN" ]] || usage_err "请提供搜索关键字。例如: $SCRIPT_NAME '合同'    或    $SCRIPT_NAME -C 2 -w '合同'"
[[ ${#PATHS[@]} -eq 0 ]] && PATHS=(.)

# -F 单独 → 只搜文件名；-Fwx / -F -w -x → 文件名 + 正文（含 Office）
if [[ "$EXPLICIT_F" -eq 1 && "$EXPLICIT_C" -eq 0 && "$EXPLICIT_A" -eq 0 \
   && "$SEARCH_WORD" -eq 0 && "$SEARCH_EXCEL" -eq 0 ]]; then
  MODE_CONTENT=0
elif [[ "$EXPLICIT_F" -eq 1 && ( "$SEARCH_WORD" -eq 1 || "$SEARCH_EXCEL" -eq 1 || "$EXPLICIT_C" -eq 1 ) ]]; then
  MODE_CONTENT=1
  MODE_FILENAME=1
fi

resolve_backend
apply_profile
if pattern_is_literal; then LITERAL=1; else LITERAL=0; fi
refresh_colors
: >"$ERR_LOG"

engine_bin="$RG_BIN"
[[ "$BACKEND" == ag ]] && engine_bin="$AG_BIN"
if (( OFFICE_MAX_BYTES > 0 )); then
  office_limit="$((OFFICE_MAX_BYTES / 1024 / 1024))M"
else
  office_limit="不限制"
fi
text_limit="${TEXT_MAX_SIZE:-不限制}"
if [[ "$BACKEND" == ag ]]; then
  text_jobs_show="ag 自己决定"
else
  text_jobs_show="$TEXT_JOBS"
fi
if [[ -n "$CONTEXT_BEFORE" || -n "$CONTEXT_AFTER" ]]; then
  context_show="前 ${CONTEXT_BEFORE:-0} 行 / 后 ${CONTEXT_AFTER:-0} 行"
else
  context_show="只显示命中行"
fi
echo "关键字: $PATTERN" >&2
echo "范围: ${PATHS[*]}  内容=$MODE_CONTENT 文件名=$MODE_FILENAME word=$SEARCH_WORD excel=$SEARCH_EXCEL  上下文=${context_show}" >&2
echo "引擎: $BACKEND ($engine_bin)" >&2
echo "资源: ${PROFILE}→${PROFILE_TIER}  内存=${MEM_MB}M 核=${CPU_COUNT}  文本线程=${text_jobs_show}  Office并行=${OFFICE_JOBS}  nice=${NICE_LEVEL}  文本上限=${text_limit}  Office上限=${office_limit}  固定字符串=${LITERAL}" >&2

[[ "$MODE_FILENAME" -eq 1 ]] && search_filenames
[[ "$MODE_CONTENT" -eq 1 ]] && search_content_text
[[ "$MODE_CONTENT" -eq 1 ]] && search_office_content

if [[ "$HIT" -eq 1 ]]; then
  exit 0
fi
echo "无匹配。" >&2
exit 1
