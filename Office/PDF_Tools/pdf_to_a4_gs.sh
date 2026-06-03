#!/usr/bin/env bash
# pdf_to_a4_gs.sh
#
# 功能：
#   递归处理 1/ 目录下所有 PDF
#   转换为 A4 页面后输出到 output/
#   保持原目录结构
#
# 默认行为：
#   已经是 A4 的 PDF 自动跳过
#   output 中只保留实际转换过的文件
#
# 强制全部转换：
#   ./pdf_to_a4_gs.sh --all
#
# 依赖：
#   sudo apt install ghostscript poppler-utils

set -euo pipefail

INPUT_DIR="input"
OUTPUT_DIR="output"
PAPER_SIZE="a4"

# 默认跳过A4
MODE="${1:---skip-a4}"

mkdir -p "$OUTPUT_DIR"

if ! command -v gs >/dev/null 2>&1; then
    echo "错误：未找到 Ghostscript(gs)"
    echo "请安装：sudo apt install ghostscript"
    exit 1
fi

if ! command -v pdfinfo >/dev/null 2>&1; then
    echo "错误：未找到 pdfinfo"
    echo "请安装：sudo apt install poppler-utils"
    exit 1
fi

is_a4() {
    pdfinfo "$1" 2>/dev/null | grep -q "(A4)"
}

TOTAL=0
SKIPPED=0
CONVERTED=0

while IFS= read -r -d '' PDF
do
    TOTAL=$((TOTAL + 1))

    REL="${PDF#$INPUT_DIR/}"
    OUTFILE="$OUTPUT_DIR/$REL"

    if [[ "$MODE" == "--skip-a4" ]] && is_a4 "$PDF"; then
        echo "跳过(A4)：$REL"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    mkdir -p "$(dirname "$OUTFILE")"

    echo "转换：$REL"

    gs \
        -q \
        -dNOPAUSE \
        -dBATCH \
        -sDEVICE=pdfwrite \
        -dPDFFitPage \
        -sPAPERSIZE="$PAPER_SIZE" \
        -sOutputFile="$OUTFILE" \
        "$PDF"

    CONVERTED=$((CONVERTED + 1))

done < <(find "$INPUT_DIR" -type f -iname "*.pdf" -print0)

echo
echo "========== 完成 =========="
echo "总文件数 : $TOTAL"
echo "已跳过A4 : $SKIPPED"
echo "已转换   : $CONVERTED"
echo "输出目录 : $OUTPUT_DIR"

