#!/bin/bash
#
# pdf_print_fix.sh
#【不一定能用】
# 递归处理 input 目录中的 PDF
#
# 模式：
#   embed  (默认)
#       Ghostscript 重生成 PDF
#
#   raster
#       栅格化 PDF
#       最稳，打印机绝不会因为字体乱码
#
# 输出：
#   output/
#

MODE="${1:-embed}"

INPUT_DIR="input"
OUTPUT_DIR="output"

mkdir -p "$OUTPUT_DIR"

check_dep() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "缺少依赖: $1"
        exit 1
    }
}

check_dep gs

if [ "$MODE" = "raster" ]; then
    check_dep pdftocairo
    check_dep img2pdf
fi

process_embed() {

    local in="$1"
    local out="$2"

    gs \
        -q \
        -dNOPAUSE \
        -dBATCH \
        -sDEVICE=pdfwrite \
        -dEmbedAllFonts=true \
        -dSubsetFonts=true \
        -dCompressFonts=true \
        -sOutputFile="$out" \
        "$in"
}

process_raster() {

    local in="$1"
    local out="$2"

    local tmpdir

    tmpdir=$(mktemp -d)

    pdftocairo \
        -png \
        -r 300 \
        "$in" \
        "$tmpdir/page" >/dev/null 2>&1

    img2pdf \
        "$tmpdir"/*.png \
        -o "$out"

    rm -rf "$tmpdir"
}

find "$INPUT_DIR" -type f -iname "*.pdf" | while read -r PDF
do

    REL="${PDF#$INPUT_DIR/}"

    mkdir -p "$OUTPUT_DIR/$(dirname "$REL")"

    OUTFILE="$OUTPUT_DIR/$REL"

    echo "处理: $PDF"

    if [ "$MODE" = "raster" ]
    then
        process_raster "$PDF" "$OUTFILE"
    else
        process_embed "$PDF" "$OUTFILE"
    fi

done

echo
echo "完成"
echo "模式: $MODE"
echo "输出目录: $OUTPUT_DIR"
