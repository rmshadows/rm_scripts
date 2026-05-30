#!/usr/bin/env bash
# pdf_to_a4_gs.sh
#
# 脚本作用：
#     递归处理 input/ 目录下所有 PDF，
#     使用 Ghostscript 统一转换为 A4，输出到 output/ 目录，
#     并保持原目录结构。
#
# 适用场景：
#     - 想把所有 PDF 统一压到 A4
#     - 需要方便打印，避免打印机自动缩放
#     - 不在乎保留原页面尺寸，只要最终能正常打印
#
# 特点：
#     - 对文字页、扫描页、混合页都可以直接处理
#     - 输出文件仍然是 PDF
#     - 处理后页面统一为 A4
#
# 依赖：
#     sudo apt install ghostscript

set -euo pipefail

INPUT_DIR="input"
OUTPUT_DIR="output"

# 目标纸张：
#   A4 / A3 / A5 / letter / legal / tabloid
# 默认 A4
PAPER_SIZE="a4"

mkdir -p "$OUTPUT_DIR"

if ! command -v gs >/dev/null 2>&1; then
    echo "错误：未找到 gs（Ghostscript）。请先安装：sudo apt install ghostscript" >&2
    exit 1
fi

find "$INPUT_DIR" -type f -iname "*.pdf" -print0 | while IFS= read -r -d '' PDF
do
    REL="${PDF#$INPUT_DIR/}"
    OUTFILE="$OUTPUT_DIR/$REL"
    mkdir -p "$(dirname "$OUTFILE")"

    echo "处理：$REL"

    gs \
        -q \
        -dNOPAUSE \
        -dBATCH \
        -sDEVICE=pdfwrite \
        -dPDFFitPage \
        -sPAPERSIZE="$PAPER_SIZE" \
        -sOutputFile="$OUTFILE" \
        "$PDF"
done

echo
echo "完成。输出目录：$OUTPUT_DIR"
