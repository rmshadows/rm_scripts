#!/usr/bin/env bash
# ============================================================
# Batch m3u8 -> mp4
# - Auto mode switch:
#     * if #EXT-X-KEY or #EXT-X-MAP exists => HLS demuxer (supports decrypt/init segment)
#     * else => concat demuxer (fast, local segments; supports temp rename no-extension segments)
# - Per-file logs in ./logs/<base>.log
# - Always run all files, then print summary (success/fail lists)
#
# Why HLS options matter (FFmpeg 7.x+):
#   HLS demuxer option "extension_picky" is enabled by default and may reject
#   extension-less URLs (e.g. .../0) even if format is detected as mpegts.
#   Fix: set "-extension_picky 0" and whitelist extensions via "-allowed_extensions ALL".
# ============================================================

# If script is executed by sh/dash, re-exec with bash (dash can't handle bash arrays)
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -u
set -o pipefail

: '
【可调整的固定参数（只改这里，不用运行传参）】
  OVERWRITE="1"          # 1 覆盖输出；0 输出存在则跳过
  LOG_DIR="logs"         # 日志目录
  AUTO_SANITIZE_M3U8="1" # 1 自动去除 CRLF 的 \r；0 不处理
  STRICT_MISSING_SEG="1" # concat 模式下，缺任何分片直接判失败（更靠谱）

  # concat 模式（仅用于无 KEY/MAP 的“普通本地分片”）
  FIX_NOEXT="1"          # 1=无扩展名分片临时补扩展名；0=不改名
  SEG_EXT="ts"           # 临时补的扩展名：ts/m4s/...
  KEEP_RENAMED="0"       # 1 不回滚（永久改名）；0 默认回滚
  ADD_AAC_BSF="0"        # 1 加 -bsf:a aac_adtstoasc（TS+ADTS AAC 常用）；fMP4 常用 0

  # HLS 模式（用于 KEY/MAP）
  HLS_ALLOWED_EXT="ALL"  # 对应 hls demuxer 的 allowed_extensions
  HLS_PROTOCOL_WHITELIST="file,crypto,data,http,https,tcp,tls"
  HLS_EXTENSION_PICKY="0" # 关键：0=关闭严格扩展名匹配（否则 .../0 这类会被拦）
  REENCODE_FALLBACK="0"  # 1 copy 失败则自动重编码（慢但兼容）；0 不重编码
'

# =========================
# 固定参数区（你只改这里）
# =========================
OVERWRITE="1"
LOG_DIR="logs"
AUTO_SANITIZE_M3U8="1"
STRICT_MISSING_SEG="1"

FIX_NOEXT="1"
SEG_EXT="ts"
KEEP_RENAMED="0"
ADD_AAC_BSF="0"

HLS_ALLOWED_EXT="ALL"
HLS_PROTOCOL_WHITELIST="file,crypto,data,http,https,tcp,tls"
HLS_EXTENSION_PICKY="0"
REENCODE_FALLBACK="0"
# =========================

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "❌ ffmpeg 未安装或不在 PATH 中"
  exit 1
fi

mkdir -p "$LOG_DIR"

# 临时文件清理
tmpfiles=()
cleanup() {
  for f in "${tmpfiles[@]:-}"; do
    [[ -e "$f" ]] && rm -f "$f"
  done
}
trap cleanup EXIT

# 分片行：m3u8 中非 # 开头且非空
is_segment_line() {
  local line="$1"
  [[ -n "$line" && "${line:0:1}" != "#" ]]
}

# 只做关键清洗：去掉 CRLF 的 \r（不要乱改 URI）
sanitize_m3u8() {
  local src="$1"
  local dst="$2"
  tr -d '\r' < "$src" > "$dst"
}

# 运行命令并把 stdout/stderr 写入 log；失败打印末尾 25 行
run_with_log() {
  local logfile="$1"; shift
  # shellcheck disable=SC2068
  "$@" >"$logfile" 2>&1
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "—— 失败，日志末尾 25 行：$logfile ——"
    tail -n 25 "$logfile" || true
    echo "—— end ——"
  fi
  return $rc
}

# -----------------------------
# HLS 模式：支持 KEY/MAP（解密 / init 段）
# -----------------------------
convert_hls() {
  local m3u8="$1"
  local out="$2"
  local logfile="$3"

  local ff=(ffmpeg -hide_banner)
  [[ "$OVERWRITE" == "1" ]] && ff+=(-y) || ff+=(-n)

  # ✅ HLS demuxer 关键固定参数（解决你现在的报错）
  # -allowed_extensions ALL  : 允许读取 .key 等扩展名
  # -extension_picky 0       : 关闭“严格按扩展名匹配”拦截（否则 .../0 这种 extension none 会被拒）
  # -protocol_whitelist ...  : 允许 file/crypto 等协议
  ff+=(
    -allowed_extensions "$HLS_ALLOWED_EXT"
    -extension_picky "$HLS_EXTENSION_PICKY"
    -protocol_whitelist "$HLS_PROTOCOL_WHITELIST"
    -i "$m3u8"
  )

  if [[ "$REENCODE_FALLBACK" == "1" ]]; then
    # 先 copy
    local ff_copy=("${ff[@]}" -c copy -movflags +faststart)
    [[ "$ADD_AAC_BSF" == "1" ]] && ff_copy+=(-bsf:a aac_adtstoasc)
    ff_copy+=("$out")

    if run_with_log "$logfile" "${ff_copy[@]}"; then
      return 0
    fi

    # copy 失败再重编码
    local ff_re=("${ff[@]}" -c:v libx264 -c:a aac -movflags +faststart "$out")
    run_with_log "$logfile" "${ff_re[@]}"
    return $?
  else
    ff+=(-c copy -movflags +faststart)
    [[ "$ADD_AAC_BSF" == "1" ]] && ff+=(-bsf:a aac_adtstoasc)
    ff+=("$out")
    run_with_log "$logfile" "${ff[@]}"
    return $?
  fi
}

# -----------------------------
# concat 模式：仅适合无 KEY/MAP 的“本地可直接拼接分片”
# -----------------------------
convert_concat() {
  local m3u8="$1"
  local out="$2"
  local logfile="$3"
  local base="${m3u8%.m3u8}"

  local m3u8_dir
  m3u8_dir="$(cd "$(dirname "$m3u8")" && pwd)"

  # 回滚映射 new|old
  local mapfile=""
  if [[ "$FIX_NOEXT" == "1" ]]; then
    mapfile="$(mktemp "${base}.rename.XXXXXX.map")"
    tmpfiles+=("$mapfile")
  fi

  # concat list
  local listfile
  listfile="$(mktemp "${base}.concat.XXXXXX.txt")"
  tmpfiles+=("$listfile")

  while IFS= read -r line || [[ -n "$line" ]]; do
    if ! is_segment_line "$line"; then
      continue
    fi

    local seg="$line"
    seg="${seg#file://}"
    seg="${seg#file:/}"
    seg="${seg//$'\r'/}"

    # trim
    seg="${seg#"${seg%%[![:space:]]*}"}"
    seg="${seg%"${seg##*[![:space:]]}"}"

    # concat 这里只做本地；遇到远程就跳过并记日志
    if [[ "$seg" =~ ^https?:// ]]; then
      echo "⚠️ concat: 发现远程分片，跳过该行: $seg" >>"$logfile"
      continue
    fi

    local seg_path
    if [[ "$seg" == /* ]]; then
      seg_path="$seg"
    else
      seg_path="${m3u8_dir}/${seg}"
    fi

    if [[ ! -e "$seg_path" ]]; then
      if [[ "$STRICT_MISSING_SEG" == "1" ]]; then
        echo "❌ concat: 缺分片（严格模式失败）: $seg_path" >>"$logfile"
        # 回滚
        if [[ "$FIX_NOEXT" == "1" && -s "$mapfile" && "$KEEP_RENAMED" == "0" ]]; then
          while IFS= read -r pair || [[ -n "$pair" ]]; do
            local newp="${pair%%|*}"
            local oldp="${pair#*|}"
            [[ -e "$newp" ]] && mv "$newp" "$oldp"
          done < "$mapfile"
        fi
        return 1
      else
        echo "⚠️ concat: 分片不存在，跳过: $seg_path" >>"$logfile"
        continue
      fi
    fi

    # 无扩展名临时改名
    if [[ "$FIX_NOEXT" == "1" ]]; then
      local seg_base seg_dir_abs
      seg_base="$(basename "$seg_path")"
      seg_dir_abs="$(dirname "$seg_path")"

      if [[ "$seg_base" != *.* ]]; then
        local new_path="${seg_dir_abs}/${seg_base}.${SEG_EXT}"
        if [[ -e "$new_path" ]]; then
          echo "⚠️ concat: 目标已存在，跳过改名: $new_path" >>"$logfile"
        else
          mv "$seg_path" "$new_path"
          echo "$new_path|$seg_path" >>"$mapfile"
          seg_path="$new_path"
        fi
      fi
    fi

    printf "file '%s'\n" "$seg_path" >>"$listfile"
  done < "$m3u8"

  if [[ ! -s "$listfile" ]]; then
    echo "❌ concat: list 为空（未收集到分片）" >>"$logfile"
    # 回滚
    if [[ "$FIX_NOEXT" == "1" && -s "$mapfile" && "$KEEP_RENAMED" == "0" ]]; then
      while IFS= read -r pair || [[ -n "$pair" ]]; do
        local newp="${pair%%|*}"
        local oldp="${pair#*|}"
        [[ -e "$newp" ]] && mv "$newp" "$oldp"
      done < "$mapfile"
    fi
    return 1
  fi

  local ff=(ffmpeg -hide_banner)
  [[ "$OVERWRITE" == "1" ]] && ff+=(-y) || ff+=(-n)

  # ✅ concat 核心固定参数
  # -f concat   : concat demuxer
  # -safe 0     : 允许绝对路径
  # -i list.txt : 每行 file '/abs/path'
  # -c copy     : 不重编码（快、无损）
  ff+=(-f concat -safe 0 -i "$listfile" -c copy)
  [[ "$ADD_AAC_BSF" == "1" ]] && ff+=(-bsf:a aac_adtstoasc)
  ff+=("$out")

  if run_with_log "$logfile" "${ff[@]}"; then
    # 成功回滚
    if [[ "$FIX_NOEXT" == "1" && -s "$mapfile" && "$KEEP_RENAMED" == "0" ]]; then
      while IFS= read -r pair || [[ -n "$pair" ]]; do
        local newp="${pair%%|*}"
        local oldp="${pair#*|}"
        [[ -e "$newp" ]] && mv "$newp" "$oldp"
      done < "$mapfile"
    fi
    return 0
  else
    # 失败回滚
    if [[ "$FIX_NOEXT" == "1" && -s "$mapfile" && "$KEEP_RENAMED" == "0" ]]; then
      while IFS= read -r pair || [[ -n "$pair" ]]; do
        local newp="${pair%%|*}"
        local oldp="${pair#*|}"
        [[ -e "$newp" ]] && mv "$newp" "$oldp"
      done < "$mapfile"
    fi
    return 1
  fi
}

# -----------------------------
# 单个 m3u8：清洗 + 自动判定模式
# -----------------------------
convert_one() {
  local orig_m3u8="$1"
  local base="${orig_m3u8%.m3u8}"
  local out="${base}.mp4"
  local logfile="${LOG_DIR}/${base}.log"

  if [[ "$OVERWRITE" == "0" && -e "$out" ]]; then
    echo "⏭️  跳过（已存在输出）: $out"
    echo "skip" >"$logfile"
    return 0
  fi

  echo "----------------------------"
  echo "正在转换: $orig_m3u8 → $out"
  echo "日志: $logfile"

  # 清洗 m3u8（主要为去 CRLF）
  local m3u8="$orig_m3u8"
  if [[ "$AUTO_SANITIZE_M3U8" == "1" ]]; then
    local clean
    clean="$(mktemp "${base}.clean.XXXXXX.m3u8")"
    tmpfiles+=("$clean")
    sanitize_m3u8 "$orig_m3u8" "$clean"
    m3u8="$clean"
  fi

  local has_key="0"
  local has_map="0"
  grep -q '#EXT-X-KEY' "$m3u8" && has_key="1" || true
  grep -q '#EXT-X-MAP' "$m3u8" && has_map="1" || true

  if [[ "$has_key" == "1" || "$has_map" == "1" ]]; then
    echo "模式: HLS（检测到 EXT-X-KEY/MAP）" | tee -a "$logfile" >/dev/null
    convert_hls "$m3u8" "$out" "$logfile"
    return $?
  else
    echo "模式: concat（未检测到 KEY/MAP）" | tee -a "$logfile" >/dev/null
    convert_concat "$m3u8" "$out" "$logfile"
    return $?
  fi
}

# -----------------------------
# main：跑完全部 + 汇总输出
# -----------------------------
shopt -s nullglob
m3u8_files=( *.m3u8 )

if [[ ${#m3u8_files[@]} -eq 0 ]]; then
  echo "当前目录没有 .m3u8 文件"
  exit 0
fi

OK_LIST=()
FAIL_LIST=()
FAIL_LOGS=()

for f in "${m3u8_files[@]}"; do
  if convert_one "$f"; then
    OK_LIST+=("$f")
  else
    FAIL_LIST+=("$f")
    FAIL_LOGS+=("${LOG_DIR}/${f%.m3u8}.log")
  fi
done

echo "============================"
echo "🎬 批处理完成（已处理 ${#m3u8_files[@]} 个 m3u8）"
echo "✅ 成功: ${#OK_LIST[@]} 个"
echo "❌ 失败: ${#FAIL_LIST[@]} 个"

if [[ ${#FAIL_LIST[@]} -gt 0 ]]; then
  echo
  echo "失败文件清单（含对应日志）："
  for i in "${!FAIL_LIST[@]}"; do
    echo "  - ${FAIL_LIST[$i]}    log: ${FAIL_LOGS[$i]}"
  done
fi

echo "============================"

if [[ ${#FAIL_LIST[@]} -gt 0 ]]; then
  exit 1
else
  exit 0
fi

