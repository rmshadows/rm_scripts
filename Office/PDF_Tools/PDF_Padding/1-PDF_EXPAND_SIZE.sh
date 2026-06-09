#!/usr/bin/env bash
# 1-PDF_EXPAND_SIZE.sh
#
# 将 input/ 下所有 PDF 扩大文件体积，输出到 output/（保持相对路径）
#
# 关联文件：
#   pdf_expand_size.py     单文件扩容逻辑（本脚本逐文件调用）
#   pdf_pad_common.py      PDF 伪装（尾部 font subset / 嵌入字体附件）
#   配对脚本 2-CHECK_PDF_PAD.sh → check_pdf_padding.py（检测本脚本产物）
#   说明：仅处理 PDF；任意文件通用扩容见 3-PAD_FILE.sh
#
# 两种模式（二选一）：
#   --to 3M      扩大到至少 3MB（已达标则原样复制）
#   --by 500K    在原有体积上再增加 500KB
#
# 两种方式（必选其一）：
#   --method pad    方式1：尾部填充（精确、最快）
#   --method embed    方式4：嵌入附件 stream（PDF 结构内合法）
#
# 示例：
#   ./1-PDF_EXPAND_SIZE.sh --method pad --to 3M
#   ./1-PDF_EXPAND_SIZE.sh --method embed --by 1M
#
# 体积单位：K/M/G（1024 进制），或直接写数字（字节）
#
# 无命令行参数时，直接使用下方「配置区域」中的默认值。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ========== 配置区域（直接改这里即可）==========
INPUT_DIR="input"
OUTPUT_DIR="output"

# 扩大方式：pad（尾部填充）| embed（嵌入附件）
METHOD="embed"

# 扩大模式：to（扩大到指定体积）| by（增加指定体积）
SIZE_MODE="by"
SIZE_RAW="8M"                # 例如 3M、500K、1048576

# 命令行参数会覆盖以上配置
# =============================================

METHOD_CLI=""
SIZE_MODE_CLI=""
SIZE_RAW_CLI=""

usage() {
    sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
    echo
    echo "用法: $0 [--method pad|embed] [--to SIZE | --by SIZE]"
    echo "      不带参数时使用脚本内配置区域的默认值"
    exit 1
}

# 解析 3M / 500K / 1G / 纯数字 → 字节
parse_size() {
    local raw="${1// /}"
    local num unit bytes

    if [[ "$raw" =~ ^[0-9]+$ ]]; then
        echo "$raw"
        return
    fi

    if [[ "$raw" =~ ^([0-9]+(\.[0-9]+)?)([KkMmGg])?$ ]]; then
        num="${BASH_REMATCH[1]}"
        unit="${BASH_REMATCH[3]}"
        unit="${unit^^}"

        case "$unit" in
            K) bytes=$(awk "BEGIN { printf \"%.0f\", $num * 1024 }") ;;
            M) bytes=$(awk "BEGIN { printf \"%.0f\", $num * 1024 * 1024 }") ;;
            G) bytes=$(awk "BEGIN { printf \"%.0f\", $num * 1024 * 1024 * 1024 }") ;;
            "") bytes=$(awk "BEGIN { printf \"%.0f\", $num }") ;;
            *) echo "错误：无法解析体积单位：$raw" >&2; return 1 ;;
        esac
        echo "$bytes"
        return
    fi

    echo "错误：无法解析体积：$raw（示例：3M、500K、1048576）" >&2
    return 1
}

human_size() {
    local b="$1"
    if (( b >= 1073741824 )); then
        awk "BEGIN { printf \"%.2fG\", $b / 1024 / 1024 / 1024 }"
    elif (( b >= 1048576 )); then
        awk "BEGIN { printf \"%.2fM\", $b / 1024 / 1024 }"
    elif (( b >= 1024 )); then
        awk "BEGIN { printf \"%.2fK\", $b / 1024 }"
    else
        echo "${b}B"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --method)
            METHOD_CLI="${2:-}"
            shift 2
            ;;
        --to)
            SIZE_MODE_CLI="to"
            SIZE_RAW_CLI="${2:-}"
            shift 2
            ;;
        --by)
            SIZE_MODE_CLI="by"
            SIZE_RAW_CLI="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "未知参数：$1" >&2
            usage
            ;;
    esac
done

# 命令行优先，否则用内置配置
[[ -n "$METHOD_CLI" ]] && METHOD="$METHOD_CLI"
[[ -n "$SIZE_MODE_CLI" ]] && SIZE_MODE="$SIZE_MODE_CLI"
[[ -n "$SIZE_RAW_CLI" ]] && SIZE_RAW="$SIZE_RAW_CLI"

[[ -n "$METHOD" ]] || { echo "错误：请在配置区域或命令行指定 --method" >&2; usage; }
[[ "$METHOD" == "pad" || "$METHOD" == "embed" ]] || { echo "错误：--method 只能是 pad 或 embed" >&2; exit 1; }
[[ -n "$SIZE_MODE" && -n "$SIZE_RAW" ]] || { echo "错误：请在配置区域或命令行指定 --to / --by" >&2; usage; }
[[ "$SIZE_MODE" == "to" || "$SIZE_MODE" == "by" ]] || { echo "错误：SIZE_MODE 只能是 to 或 by" >&2; exit 1; }

SIZE_BYTES="$(parse_size "$SIZE_RAW")" || exit 1
(( SIZE_BYTES > 0 )) || { echo "错误：体积必须大于 0" >&2; exit 1; }

mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
    echo "错误：未找到 python3" >&2
    exit 1
fi

mapfile -d '' PDF_FILES < <(find "$INPUT_DIR" -type f -iname '*.pdf' -print0 | sort -z)

if [[ ${#PDF_FILES[@]} -eq 0 ]]; then
    echo "input/ 中没有 PDF 文件，请先放入 PDF 后重试。"
    exit 1
fi

TOTAL=0
SKIPPED=0
PROCESSED=0

echo "方式   : $METHOD ($([[ "$METHOD" == "pad" ]] && echo "尾部填充" || echo "嵌入附件"))"
echo "模式   : $SIZE_MODE $SIZE_RAW ($(human_size "$SIZE_BYTES"))"
echo "输入   : $INPUT_DIR/"
echo "输出   : $OUTPUT_DIR/"
echo

for pdf in "${PDF_FILES[@]}"; do
    TOTAL=$((TOTAL + 1))
    rel="${pdf#$INPUT_DIR/}"
    rel="${rel#/}"
    out="$OUTPUT_DIR/$rel"
    mkdir -p "$(dirname "$out")"

    before=$(stat -c%s "$pdf")

    if [[ "$SIZE_MODE" == "to" && "$before" -ge "$SIZE_BYTES" ]]; then
        cp -f "$pdf" "$out"
        SKIPPED=$((SKIPPED + 1))
        echo "跳过(已达标)：$rel  $(human_size "$before")"
        continue
    fi

    python3 pdf_expand_size.py \
        --method "$METHOD" \
        --mode "$SIZE_MODE" \
        --size "$SIZE_BYTES" \
        "$pdf" "$out"

    after=$(stat -c%s "$out")
    PROCESSED=$((PROCESSED + 1))
    echo "完成：$rel  $(human_size "$before") → $(human_size "$after")"
done

echo
echo "========== 完成 =========="
echo "总文件数 : $TOTAL"
echo "已处理   : $PROCESSED"
echo "已跳过   : $SKIPPED"
echo "输出目录 : $OUTPUT_DIR/"
