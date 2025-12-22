#!/usr/bin/env bash
#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Name: extract_gps.sh
#
# Description:
#   批量扫描图片文件的 EXIF 信息，提取 GPS 经纬度（十进制），并：
#     - 输出结果到 TSV 文本文件（file / lat / lon / status）
#     - 可选：按“经纬度”重命名带 GPS 的图片
#     - 可选：将【没有 GPS 信息】的图片移动到指定目录
#     - 终端实时显示处理过程（verbose），无 GPS 文件红色标记
#
# Features:
#   - 支持常见图片格式：jpg / jpeg / png / tif / tiff / webp / heic
#   - GPS 输出为十进制度（适合地图/程序处理）
#   - 自动避免重名覆盖（追加 __1、__2 ...）
#   - 仅在终端显示颜色，不污染输出文件
#
# Usage:
#   ./extract_gps.sh DIR [options]
#
# Options:
#   --rename              将【有 GPS】的图片按经纬度重命名
#   --out FILE            输出 TSV 文件路径（默认: gps.tsv）
#   --nogps-dir DIR       将【无 GPS】的图片移动到该目录（默认: NOGPS）
#   -v, --verbose         显示详细处理过程（默认开启）
#
# Examples:
#   仅提取 GPS 到文本：
#     ./extract_gps.sh photos
#
#   重命名带 GPS 的图片：
#     ./extract_gps.sh photos --rename
#
#   无 GPS 的图片移动到 NOGPS 目录（红色提示）：
#     ./extract_gps.sh photos --nogps-dir NOGPS
#
#   全功能（verbose + rename + 分类）：
#     ./extract_gps.sh photos --rename --nogps-dir NOGPS -v
#
# Requirements:
#   - bash >= 4
#   - exiftool
#
#   Debian / Ubuntu 安装依赖：
#     sudo apt update
#     sudo apt install libimage-exiftool-perl
#
# Notes:
#   - 部分平台（如微信/微博/QQ）导出的图片可能被剥离 EXIF/GPS 信息
#   - 输出 TSV 文件不包含颜色控制字符，适合后续程序处理
#
###############################################################################

set -euo pipefail

# Usage:
# ./extract_gps.sh DIR [--rename] [--out gps.tsv] [-v|--verbose] [--nogps-dir DIR]
# Requires: exiftool

DIR="${1:-.}"
RENAME=0
OUT="gps.tsv"
VERBOSE=1
NOGPS_DIR="NOGPS"

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rename) RENAME=1; shift ;;
    --out) OUT="$2"; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    --nogps-dir) NOGPS_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

log() { [[ "$VERBOSE" -eq 1 ]] && echo "[*] $*" >&2; }
err() { echo "[!] $*" >&2; }

# Color (only when stdout/stderr is a tty)
if [[ -t 2 ]]; then
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  RESET=$'\033[0m'
else
  RED=""; YELLOW=""; RESET=""
fi

command -v exiftool >/dev/null 2>&1 || {
  err "exiftool not found. Install with: sudo apt install libimage-exiftool-perl"
  exit 1
}

[[ -n "$NOGPS_DIR" ]] && mkdir -p "$NOGPS_DIR"

echo -e "file\tlat\tlon\tstatus" > "$OUT"

COUNT=0
COUNT_GPS=0
COUNT_NOGPS=0
COUNT_RENAMED=0
COUNT_MOVED=0

safe_move() {
  local src="$1"
  local dst_dir="$2"
  local base ext stem target i=1

  base="$(basename "$src")"
  ext=".${base##*.}"
  stem="${base%.*}"
  target="${dst_dir}/${base}"

  if [[ -e "$target" ]]; then
    while [[ -e "${dst_dir}/${stem}__${i}${ext}" ]]; do
      i=$((i+1))
    done
    target="${dst_dir}/${stem}__${i}${ext}"
  fi

  mv -- "$src" "$target"
  echo "$target"
}

while IFS= read -r -d '' f; do
  COUNT=$((COUNT+1))
  log "Processing: $f"

  lat="$(exiftool -n -s -s -s -GPSLatitude "$f" 2>/dev/null || true)"
  lon="$(exiftool -n -s -s -s -GPSLongitude "$f" 2>/dev/null || true)"

  if [[ -z "$lat" || -z "$lon" ]]; then
    COUNT_NOGPS=$((COUNT_NOGPS+1))
    # log "  -> NO GPS"
    [[ "$VERBOSE" -eq 1 ]] && echo -e "${RED}[*]   -> NO GPS${RESET}" >&2
    echo -e "${f}\t\t\tNO_GPS" >> "$OUT"

    if [[ -n "$NOGPS_DIR" ]]; then
      newpath="$(safe_move "$f" "$NOGPS_DIR")"
      COUNT_MOVED=$((COUNT_MOVED+1))
      # log "  -> moved to: $newpath"
      [[ "$VERBOSE" -eq 1 ]] && echo -e "${YELLOW}[*]   -> moved to: $newpath${RESET}" >&2
    fi
    continue
  fi

  COUNT_GPS=$((COUNT_GPS+1))
  log "  -> GPS: lat=$lat lon=$lon"
  echo -e "${f}\t${lat}\t${lon}\tOK" >> "$OUT"

  if [[ "$RENAME" -eq 1 ]]; then
    base="$(basename "$f")"
    dirn="$(dirname "$f")"
    ext=".${base##*.}"
    stem="${base%.*}"
    new="${stem}__${lat}_${lon}${ext}"

    if [[ -e "${dirn}/${new}" ]]; then
      i=1
      while [[ -e "${dirn}/${stem}__${lat}_${lon}__${i}${ext}" ]]; do
        i=$((i+1))
      done
      new="${stem}__${lat}_${lon}__${i}${ext}"
    fi

    log "  -> rename: $base -> $new"
    mv -- "$f" "${dirn}/${new}"
    COUNT_RENAMED=$((COUNT_RENAMED+1))
  fi

done < <(find "$DIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
  -iname "*.tif" -o -iname "*.tiff" -o \
  -iname "*.webp" -o -iname "*.heic" \
\) -print0)

echo
echo "Done."
echo "Total files   : $COUNT"
echo "With GPS      : $COUNT_GPS"
echo "Without GPS   : $COUNT_NOGPS"
[[ "$RENAME" -eq 1 ]] && echo "Renamed files : $COUNT_RENAMED"
[[ -n "$NOGPS_DIR" ]] && echo "Moved NO_GPS  : $COUNT_MOVED -> $NOGPS_DIR"
echo "Output written: $OUT"

