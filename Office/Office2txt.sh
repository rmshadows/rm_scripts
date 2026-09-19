#!/usr/bin/env bash
# 批量将 Word / Excel 转为纯文本，保持目录结构
# 用法:
#   ./Office2txt.sh [目录|文件]     # 默认目录 src
#   ./Office2txt.sh --help
#
# 输出: ./office_mirror/  （相对当前工作目录）
# 日志: ./office_mirror/_logs/
set -euo pipefail

WORD_EXTS=(doc docx wps)
EXCEL_EXTS=(xlsx xls et csv)
MIRROR_OUT="office_mirror"
NO_BLANK_FILENAME=1
OVERWRITE=1

usage() {
  cat <<'EOF'
批量 Office → txt（保持目录结构）

用法:
  ./Office2txt.sh [目录|文件]   默认目录: src
  ./Office2txt.sh -h|--help

输出目录: ./office_mirror/
日志目录: ./office_mirror/_logs/

依赖（缺了请安装，不会自动 sudo）:
  pandoc antiword catdoc libreoffice
  或: Office/0-Off-init.sh --yes
EOF
}

log() { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die() { printf '[x] %s\n' "$*" >&2; exit 1; }

need_cmd() {
  local c="$1"
  command -v "$c" >/dev/null 2>&1 || return 1
}

check_deps() {
  local -a miss=()
  need_cmd pandoc || miss+=(pandoc)
  need_cmd antiword || miss+=(antiword)
  need_cmd libreoffice || miss+=(libreoffice)
  # catdoc / iconv 可选
  if [[ ${#miss[@]} -gt 0 ]]; then
    die "缺少依赖: ${miss[*]}
请安装: sudo apt install pandoc antiword catdoc libreoffice libreoffice-java-common
或运行: $(dirname "$(readlink -f "$0")")/0-Off-init.sh --yes"
  fi
}

# 相对路径（基于 SRC_ROOT）
rel_to_src() {
  python3 - "$1" "$SRC_ROOT" <<'PY'
import os, sys
print(os.path.relpath(sys.argv[1], sys.argv[2]))
PY
}

blank_fix() {
  if [[ "$NO_BLANK_FILENAME" -eq 1 ]]; then
    echo "${1// /_}"
  else
    echo "$1"
  fi
}

# 构建输出 txt 路径；打印目录到 stdout 第二行不太方便，用全局 TARGET_PATH
build_target_txt() {
  local abs="$1"
  local rel dst_dir name
  rel="$(rel_to_src "$abs")"
  rel="$(blank_fix "$rel")"
  dst_dir="$MIRROR_OUT/$(dirname "$rel")"
  name="$(basename "$rel")"
  name="${name%.*}.txt"
  mkdir -p "$dst_dir"
  TARGET_PATH="$dst_dir/$name"
}

append_fail() {
  printf '%s\n' "$1" >>"$FAIL_LOG"
}

# LibreOffice → 指定目标（用独立临时目录，避免并发/撞名）
lo_convert() {
  local src="$1" dest="$2" filter="$3"  # filter: txt:Text | csv
  local tmp produced base ext
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/office2txt.XXXXXX")"

  if ! libreoffice --headless --convert-to "$filter" --outdir "$tmp" "$src" \
      >/dev/null 2>>"$ERR_LOG"; then
    rm -rf "$tmp"
    return 1
  fi

  base="$(basename "$src")"
  case "$filter" in
    csv) ext=csv ;;
    *)   ext=txt ;;
  esac
  produced="$tmp/${base%.*}.$ext"
  if [[ -f "$produced" ]]; then
    mv -f "$produced" "$dest"
    rm -rf "$tmp"
    return 0
  fi
  produced="$(find "$tmp" -maxdepth 1 -type f -name "*.$ext" | head -n 1 || true)"
  if [[ -n "${produced:-}" && -f "$produced" ]]; then
    mv -f "$produced" "$dest"
    rm -rf "$tmp"
    return 0
  fi
  rm -rf "$tmp"
  return 1
}

convert_csv_to_utf8_txt() {
  local src="$1" dest="$2"
  local enc
  enc="$(file -bi "$src" 2>/dev/null || true)"
  enc="${enc##*charset=}"
  enc="${enc%%;*}"
  enc="${enc,,}"

  if [[ "$enc" == "utf-8" || "$enc" == "us-ascii" ]]; then
    cp -f "$src" "$dest"
    return 0
  fi

  # 按探测结果试，再 GBK / GB18030
  local -a try=()
  [[ -n "$enc" && "$enc" != "unknown-8bit" && "$enc" != "binary" ]] && try+=("$enc")
  try+=(GBK GB18030 UTF-8)
  local f
  for f in "${try[@]}"; do
    if iconv -c -f "$f" -t UTF-8 "$src" -o "$dest" 2>>"$ERR_LOG"; then
      return 0
    fi
  done
  return 1
}

convert_word() {
  local file_path="$1" fext
  build_target_txt "$file_path"
  if [[ "$OVERWRITE" -eq 0 && -f "$TARGET_PATH" ]]; then
    ((SKIP++)) || true
    return 0
  fi
  fext="${file_path##*.}"
  fext="${fext,,}"
  log "Word: $file_path -> $TARGET_PATH"

  case "$fext" in
    doc)
      if antiword "$file_path" >"$TARGET_PATH" 2>>"$ERR_LOG"; then
        ((OK++)) || true
        return 0
      fi
      if need_cmd catdoc && catdoc "$file_path" >"$TARGET_PATH" 2>>"$ERR_LOG"; then
        ((OK++)) || true
        return 0
      fi
      append_fail "$file_path"
      ((FAIL++)) || true
      ;;
    docx)
      if pandoc -s "$file_path" -t plain -o "$TARGET_PATH" 2>>"$ERR_LOG"; then
        ((OK++)) || true
      else
        append_fail "$file_path"
        ((FAIL++)) || true
      fi
      ;;
    wps)
      if antiword "$file_path" >"$TARGET_PATH" 2>>"$ERR_LOG"; then
        ((OK++)) || true
      elif lo_convert "$file_path" "$TARGET_PATH" "txt:Text"; then
        ((OK++)) || true
      else
        append_fail "$file_path"
        ((FAIL++)) || true
      fi
      ;;
    *)
      if lo_convert "$file_path" "$TARGET_PATH" "txt:Text"; then
        ((OK++)) || true
      else
        append_fail "$file_path"
        ((FAIL++)) || true
      fi
      ;;
  esac
}

convert_excel() {
  local file_path="$1" fext tmp_csv
  build_target_txt "$file_path"
  if [[ "$OVERWRITE" -eq 0 && -f "$TARGET_PATH" ]]; then
    ((SKIP++)) || true
    return 0
  fi
  fext="${file_path##*.}"
  fext="${fext,,}"
  log "Excel: $file_path -> $TARGET_PATH"

  if [[ "$fext" == "csv" ]]; then
    if convert_csv_to_utf8_txt "$file_path" "$TARGET_PATH"; then
      ((OK++)) || true
    else
      append_fail "$file_path"
      ((FAIL++)) || true
    fi
    return 0
  fi

  tmp_csv="${TARGET_PATH%.txt}.__tmp.csv"
  if lo_convert "$file_path" "$tmp_csv" "csv"; then
    mv -f "$tmp_csv" "$TARGET_PATH"
    ((OK++)) || true
  else
    rm -f "$tmp_csv"
    append_fail "$file_path"
    ((FAIL++)) || true
  fi
}

collect_files() {
  local root="$1"
  shift
  local -a exts=("$@")
  local -a find_args=()
  local i=0 ext
  for ext in "${exts[@]}"; do
    [[ $i -gt 0 ]] && find_args+=( -o )
    find_args+=( -iname "*.${ext}" )
    ((i++)) || true
  done
  mapfile -t COLLECTED < <(find "$root" -type f \( "${find_args[@]}" \) -print0 \
    | xargs -0 -r realpath 2>/dev/null | sort -u)
}

# ---------- main ----------
INPUT="${1:-src}"
case "${INPUT}" in
  -h|--help) usage; exit 0 ;;
esac

check_deps

WORK_TMP=""
cleanup_main() {
  [[ -n "${WORK_TMP:-}" && -d "${WORK_TMP:-}" ]] && rm -rf "$WORK_TMP"
}
trap cleanup_main EXIT

if [[ -f "$INPUT" ]]; then
  WORK_TMP="$(mktemp -d ./officeTempWS.XXXXXX)"
  cp -f "$INPUT" "$WORK_TMP/"
  SRC_ROOT="$(realpath "$WORK_TMP")"
elif [[ -d "$INPUT" ]]; then
  SRC_ROOT="$(realpath "$INPUT")"
else
  die "路径不存在: $INPUT"
fi

mkdir -p "$MIRROR_OUT/_logs"
ERR_LOG="$MIRROR_OUT/_logs/error_log.txt"
FAIL_LOG="$MIRROR_OUT/_logs/no_convert.log"
: >"$ERR_LOG"
: >"$FAIL_LOG"

OK=0
FAIL=0
SKIP=0

log "源: $SRC_ROOT"
log "出: $(realpath "$MIRROR_OUT")"

collect_files "$SRC_ROOT" "${WORD_EXTS[@]}"
log "Word 候选: ${#COLLECTED[@]}"
for f in "${COLLECTED[@]:-}"; do
  [[ -n "$f" ]] || continue
  convert_word "$f" || true
done

collect_files "$SRC_ROOT" "${EXCEL_EXTS[@]}"
log "Excel 候选: ${#COLLECTED[@]}"
for f in "${COLLECTED[@]:-}"; do
  [[ -n "$f" ]] || continue
  convert_excel "$f" || true
done

echo
log "完成: 成功=$OK  跳过=$SKIP  失败=$FAIL"
[[ "$FAIL" -gt 0 ]] && warn "失败列表: $FAIL_LOG"
[[ -s "$ERR_LOG" ]] && warn "详情日志: $ERR_LOG"
exit 0
