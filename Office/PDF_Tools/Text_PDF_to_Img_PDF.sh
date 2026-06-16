#!/usr/bin/env bash
# 0-PDF2IMG.sh
#
# input/ 下 PDF → 栅格化转图 → 再合成 PDF → 转 A4，输出到 output/
#
# 关联文件：
#   pdf_select_pages_to_jpg.py   步骤1：PDF 拆页转 JPG（output/<pdf名>/1.jpg）
#   image2Pdf.py                 步骤3：JPG 合回 PDF（生成 output.pdf）
#   pdf_to_a4_gs.sh              步骤5：Ghostscript 统一转 A3（PAPER_SIZE=a3）
#   m_PDF.py / m_System.py / m_Log.py   上述 Python 脚本的公共依赖
#   说明：PDF 栅格化转图再合成流水线；
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INPUT_DIR="input"
OUTPUT_DIR="output"

mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

# 先保存 input 中的 PDF 列表（后续会清空 input 放图片）
mapfile -t PDF_FILES < <(find "$INPUT_DIR" -maxdepth 1 -type f -iname '*.pdf' | sort)

if [[ ${#PDF_FILES[@]} -eq 0 ]]; then
    echo "input 文件夹中没有 PDF 文件，请先放入 PDF 后重试。"
    exit 1
fi

# 步骤1: PDF 拆页转 JPG → output/<pdf名>/1.jpg
python3 pdf_select_pages_to_jpg.py

# 步骤2-4: 逐个 PDF 走「JPG → 再合成 PDF」
for pdf in "${PDF_FILES[@]}"; do
    pdf_name="$(basename "$pdf")"
    pdf_base="${pdf_name%.pdf}"
    jpg="${OUTPUT_DIR}/${pdf_base}/1.jpg"
    final_pdf="${OUTPUT_DIR}/${pdf_name}"

    if [[ ! -f "$jpg" ]]; then
        echo "警告: 未找到 ${jpg}，跳过 ${pdf_name}"
        continue
    fi

    echo ">>> 处理: ${pdf_name}"

    # 步骤2: 清空 input，放入生成的 1.jpg
    rm -f "$INPUT_DIR"/*
    cp "$jpg" "$INPUT_DIR/1.jpg"

    # 步骤3: 图片转 PDF（在当前目录生成 output.pdf）
    python3 image2Pdf.py

    # 步骤4: 取出 output.pdf，命名为与原 PDF 一致，放入 output 文件夹
    mv -f output.pdf "$final_pdf"

    # 删除中间产物图片目录
    rm -rf "${OUTPUT_DIR}/${pdf_base}"

    echo ">>> 完成: ${final_pdf}"
done

# 清理 input 中的临时图片
rm -f "$INPUT_DIR"/*

# 确保 output 只保留 PDF（清除可能残留的子目录）
find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

# 步骤5: 将 output 中的 PDF 统一转为 A3（pdf_to_a4_gs.sh 内 PAPER_SIZE=a3）
shopt -s nullglob
GENERATED_PDFS=("$OUTPUT_DIR"/*.pdf)

if [[ ${#GENERATED_PDFS[@]} -gt 0 ]]; then
    echo ">>> 开始 A3 转换..."
    for pdf in "${GENERATED_PDFS[@]}"; do
        mv "$pdf" "$INPUT_DIR/"
    done
    bash pdf_to_a4_gs.sh --all
    rm -f "$INPUT_DIR"/*.pdf
    echo ">>> A3 转换完成"
fi

echo "全部处理完成！"
