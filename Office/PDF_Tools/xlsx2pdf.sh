#!/bin/bash
# excel转pdf
# ========== 用户可修改的变量 ==========
MODE="default"  # 可选：default, fit_width-所有列适应一页, fit_height-所有行适应一页, fit_page
SHEET_INDEX="all"  # 可选：all（所有表）或指定数字（如 1, 2, 3）
OUTPUT_DIR="output_pdf"

# ========== 创建输出目录 ==========
mkdir -p "$OUTPUT_DIR"

# ========== 适应模式参数 ==========
case "$MODE" in
    fit_width)
        EXPORT_OPTIONS="calc_pdf_Export:FitPageWidth=1"
        ;;
    fit_height)
        EXPORT_OPTIONS="calc_pdf_Export:FitPageHeight=1"
        ;;
    fit_page)
        EXPORT_OPTIONS="calc_pdf_Export:FitPageWidth=1,FITPAGEHEIGHT=1"
        ;;
    default)
        EXPORT_OPTIONS="calc_pdf_Export"
        ;;
    *)
        echo "无效的 MODE 选项！使用默认模式"
        EXPORT_OPTIONS="calc_pdf_Export"
        ;;
esac

# ========== 遍历所有 Excel 文件 ==========
for file in *.xls *.xlsx; do
    [ -f "$file" ] || continue  # 跳过不存在的文件

    echo "正在转换: $file"

    # ========== 处理单个表还是所有表 ==========
    if [ "$SHEET_INDEX" == "all" ]; then
        # 导出整个工作簿
        libreoffice --headless --convert-to pdf:"$EXPORT_OPTIONS" "$file" --outdir "$OUTPUT_DIR"
    else
        # 导出指定工作表
        libreoffice --headless --convert-to pdf:"$EXPORT_OPTIONS" --infilter="calc:Excel" --convert-filter-options "$SHEET_INDEX" "$file" --outdir "$OUTPUT_DIR"
    fi
done

echo "所有 Excel 文件已转换完成，PDF 保存在 $OUTPUT_DIR 目录中。"

