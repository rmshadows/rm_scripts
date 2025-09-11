#!/usr/bin/python3
# 拆分pdf页面
import os
import m_PDF

# ========== 配置区域 ==========
input_dir = "pdfs"  # 指定要遍历的PDF文件夹
output_dir = "split_pages"  # 输出文件夹
# =================================

# 确保输出目录存在
os.makedirs(output_dir, exist_ok=True)

# 遍历 input_dir 下所有 PDF 文件
pdf_files = [f for f in os.listdir(input_dir) if f.lower().endswith(".pdf")]

for pdf in pdf_files:
    pdf_path = os.path.join(input_dir, pdf)
    m_PDF.batch_split_pdf(pdf_path, output_dir)

print("所有 PDF 文件已拆分完成！")

