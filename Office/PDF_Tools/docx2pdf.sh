#!/bin/bash
# docx转pdf
# 需要libreoffice
# 创建输出目录
mkdir -p output_pdf

# 遍历当前目录下所有 doc 和 docx 文件
for file in *.doc *.docx; do
    # 跳过不存在的文件情况（如当前目录没有 doc/docx 文件）
    [ -f "$file" ] || continue  

    echo "正在转换: $file"
    libreoffice --headless --convert-to pdf "$file" --outdir output_pdf
done

echo "所有文件已转换完成，PDF 保存在 output_pdf 目录中。"

