#!/usr/bin/env bash
# Text_PDF_to_Img_PDF.sh
#
# input/ 下的文字 PDF → 每一页栅格化 → 合成图片版 PDF → output/
#
# 全部页面按原顺序保留。支持子目录，相对路径会原样出现在 output/。
# 不修改、不清空 input/。渲染直接对准目标纸张，不再经 JPG 中转和 Ghostscript。
#
# 关联文件：
#   pdf_to_image_pdf.py
#
# 依赖：
#   sudo apt install poppler-utils
#   python3 包：pypdf
#
# 用法：
#   ./Text_PDF_to_Img_PDF.sh
#   ./Text_PDF_to_Img_PDF.sh --dpi 200 --paper A3 --orientation auto
#   ./Text_PDF_to_Img_PDF.sh --input input --output output --jobs 4
#
# 无命令行参数时，使用下方配置。默认 A4 竖版，与原先 pdf_to_a4_gs.sh 的成稿一致。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
export PYTHONUNBUFFERED=1

# ========== 配置区域（直接改这里即可）==========
INPUT_DIR="input"
OUTPUT_DIR="output"

# 输出到纸面上的分辨率。300 适合打印，150/200 更快。
DPI=300
# 目标纸张：A3 / A4 / A5 / Letter / Legal
PAPER="A4"
# auto：横页出横版，竖页出竖版
# portrait：全部放进竖版纸
# landscape：全部放进横版纸
ORIENTATION="portrait"
JPEG_QUALITY=90
# 同时处理几个 PDF。0 = 按 CPU 自动。单个多页 PDF 会把核心用在按页渲染上。
JOBS=0
# 渲染 DPI 上限，避免特别小的页面被放大到占满内存。
MAX_RENDER_DPI=600
# =============================================

usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input) INPUT_DIR="${2:-}"; shift 2 ;;
        --output) OUTPUT_DIR="${2:-}"; shift 2 ;;
        --dpi) DPI="${2:-}"; shift 2 ;;
        --paper) PAPER="${2:-}"; shift 2 ;;
        --orientation) ORIENTATION="${2:-}"; shift 2 ;;
        --quality) JPEG_QUALITY="${2:-}"; shift 2 ;;
        --jobs) JOBS="${2:-}"; shift 2 ;;
        --max-render-dpi) MAX_RENDER_DPI="${2:-}"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "未知参数：$1" >&2; usage ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "错误：未找到 python3" >&2
    exit 1
fi
if ! command -v pdftoppm >/dev/null 2>&1; then
    echo "错误：未找到 pdftoppm" >&2
    echo "请安装：sudo apt install poppler-utils" >&2
    exit 1
fi

exec python3 pdf_to_image_pdf.py \
    --input "$INPUT_DIR" \
    --output "$OUTPUT_DIR" \
    --dpi "$DPI" \
    --paper "$PAPER" \
    --orientation "$ORIENTATION" \
    --jpeg-quality "$JPEG_QUALITY" \
    --jobs "$JOBS" \
    --max-render-dpi "$MAX_RENDER_DPI"
