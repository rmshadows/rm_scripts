#!/usr/bin/env bash
# 3-PAD_FILE.sh
#
# 对 input/ 下所有文件 padding 扩容，输出到 output/
#
# 关联文件：
#   pad_file.py              单文件扩容逻辑（本脚本逐文件调用）
#   file_pad_common.py       元数据 FPADv1、各类型 disguise、格式识别
#   pdf_pad_common.py        PDF 字体伪装（被 pad_file / file_pad_common 引用）
#   list_disguise_formats.py 支持格式一览（可选：python3 list_disguise_formats.py）
#   配对脚本 4-RESTORE_FILE.sh → restore_file.py（检测并还原本脚本产物）
#
# 三种方式：
#   truncate  预分配文件到目标大小（零/随机填充）
#   dd        在文件末尾追加 padding（零/随机填充）
#   disguise  按文件类型高级伪装（见下方支持列表；运行 python3 list_disguise_formats.py 查看）
#
# disguise 支持概览：
#   PDF / PNG·JPEG·GIF·WebP·BMP·TIFF·ICO·PSD
#   Office(.docx/.xlsx/.pptx) / ZIP / JAR / APK / EPUB
#   MP4·MOV / MP3·WAV·FLAC·OGG / AVI·MKV
#   EXE·DLL / ELF / SQLite / XML·HTML / RTF / 文本·JSON
#   RAR·7z·TAR（overlay 追加，部分严格校验工具可能报警）
#
# 两种体积模式（二选一）：
#   --to 3M   扩到至少 3MB
#   --by 500K 增加 500KB
#
# truncate / dd 可选填充：
#   --fill zero    填 0（默认）
#   --fill random  随机字节
#
# 示例：
#   ./3-PAD_FILE.sh
#   ./3-PAD_FILE.sh --method dd --by 1M --fill random
#   ./3-PAD_FILE.sh --method disguise --to 5M

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ========== 配置区域 ==========
INPUT_DIR="input"
OUTPUT_DIR="output"

METHOD="disguise"          # truncate | dd | disguise
SIZE_MODE="by"             # to | by
SIZE_RAW="1M"
FILL="zero"                # zero | random（truncate/dd 有效）
# ==============================

METHOD_CLI=""
SIZE_MODE_CLI=""
SIZE_RAW_CLI=""
FILL_CLI=""
EXTRA_ARGS=()

usage() {
    sed -n '3,23p' "$0" | sed 's/^# \{0,1\}//'
    echo
    echo "用法: $0 [--method truncate|dd|disguise] [--to SIZE | --by SIZE] [--fill zero|random]"
    exit 1
}

parse_size() {
    local raw="${1// /}"
    local num unit bytes
    if [[ "$raw" =~ ^[0-9]+$ ]]; then echo "$raw"; return; fi
    if [[ "$raw" =~ ^([0-9]+(\.[0-9]+)?)([KkMmGg])?$ ]]; then
        num="${BASH_REMATCH[1]}"
        unit="${BASH_REMATCH[3]}"
        unit="${unit^^}"
        case "$unit" in
            K) bytes=$(awk "BEGIN { printf \"%.0f\", $num * 1024 }") ;;
            M) bytes=$(awk "BEGIN { printf \"%.0f\", $num * 1024 * 1024 }") ;;
            G) bytes=$(awk "BEGIN { printf \"%.0f\", $num * 1024 * 1024 * 1024 }") ;;
            "") bytes=$(awk "BEGIN { printf \"%.0f\", $num }") ;;
            *) echo "错误：无法解析体积：$raw" >&2; return 1 ;;
        esac
        echo "$bytes"
        return
    fi
    echo "错误：无法解析体积：$raw" >&2
    return 1
}

human_size() {
    local b="$1"
    if (( b >= 1073741824 )); then awk "BEGIN { printf \"%.2fG\", $b / 1024 / 1024 / 1024 }"
    elif (( b >= 1048576 )); then awk "BEGIN { printf \"%.2fM\", $b / 1024 / 1024 }"
    elif (( b >= 1024 )); then awk "BEGIN { printf \"%.2fK\", $b / 1024 }"
    else echo "${b}B"; fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --method) METHOD_CLI="${2:-}"; shift 2 ;;
        --to) SIZE_MODE_CLI="to"; SIZE_RAW_CLI="${2:-}"; shift 2 ;;
        --by) SIZE_MODE_CLI="by"; SIZE_RAW_CLI="${2:-}"; shift 2 ;;
        --fill) FILL_CLI="${2:-}"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "未知参数：$1" >&2; usage ;;
    esac
done

[[ -n "$METHOD_CLI" ]] && METHOD="$METHOD_CLI"
[[ -n "$SIZE_MODE_CLI" ]] && SIZE_MODE="$SIZE_MODE_CLI"
[[ -n "$SIZE_RAW_CLI" ]] && SIZE_RAW="$SIZE_RAW_CLI"
[[ -n "$FILL_CLI" ]] && FILL="$FILL_CLI"

[[ "$METHOD" =~ ^(truncate|dd|disguise)$ ]] || { echo "错误：method 无效" >&2; exit 1; }
[[ "$SIZE_MODE" =~ ^(to|by)$ ]] || { echo "错误：需指定 to/by" >&2; exit 1; }
[[ "$FILL" =~ ^(zero|random)$ ]] || { echo "错误：fill 只能是 zero/random" >&2; exit 1; }

SIZE_BYTES="$(parse_size "$SIZE_RAW")" || exit 1
(( SIZE_BYTES > 0 )) || { echo "错误：体积必须 > 0" >&2; exit 1; }

mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

mapfile -d '' FILES < <(find "$INPUT_DIR" -type f -print0 | sort -z)
if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "input/ 中没有文件"
    exit 1
fi

echo "方式   : $METHOD"
echo "模式   : $SIZE_MODE $SIZE_RAW ($(human_size "$SIZE_BYTES"))"
echo "填充   : $FILL"
echo "输入   : $INPUT_DIR/"
echo "输出   : $OUTPUT_DIR/"
echo

TOTAL=0
SKIPPED=0
DONE=0

for file in "${FILES[@]}"; do
    TOTAL=$((TOTAL + 1))
    rel="${file#$INPUT_DIR/}"
    rel="${rel#/}"
    out="$OUTPUT_DIR/$rel"
    mkdir -p "$(dirname "$out")"

    before=$(stat -c%s "$file")
    result=$(python3 pad_file.py \
        --method "$METHOD" \
        --mode "$SIZE_MODE" \
        --size "$SIZE_BYTES" \
        --fill "$FILL" \
        "$file" "$out")

    after=$(stat -c%s "$out")
    if [[ "$result" == "skip" ]]; then
        SKIPPED=$((SKIPPED + 1))
        echo "跳过(已达标)：$rel  $(human_size "$before")"
    else
        DONE=$((DONE + 1))
        echo "完成：$rel  $(human_size "$before") → $(human_size "$after")"
    fi
done

echo
echo "========== 完成 =========="
echo "总文件数 : $TOTAL"
echo "已处理   : $DONE"
echo "已跳过   : $SKIPPED"
