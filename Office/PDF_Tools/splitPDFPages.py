#!/usr/bin/python3
# 拆分pdf页面
import os
import PyPDF2

# ========== 配置区域 ==========
input_dir = "pdfs"  # 指定要遍历的PDF文件夹
output_dir = "split_pages"  # 输出文件夹
# =================================

# 确保输出目录存在
os.makedirs(output_dir, exist_ok=True)

def split_pdf(input_pdf_path, output_folder):
    """拆分 PDF 为单页 PDF"""
    pdf_name = os.path.splitext(os.path.basename(input_pdf_path))[0]  # 获取文件名（无扩展名）
    
    with open(input_pdf_path, "rb") as pdf_file:
        reader = PyPDF2.PdfReader(pdf_file)
        total_pages = len(reader.pages)

        for page_num in range(total_pages):
            writer = PyPDF2.PdfWriter()
            writer.add_page(reader.pages[page_num])

            output_pdf_path = os.path.join(output_folder, f"{pdf_name}_page{page_num+1}.pdf")
            with open(output_pdf_path, "wb") as output_pdf:
                writer.write(output_pdf)

            print(f"已拆分: {output_pdf_path}")

# 遍历 input_dir 下所有 PDF 文件
pdf_files = [f for f in os.listdir(input_dir) if f.lower().endswith(".pdf")]

for pdf in pdf_files:
    pdf_path = os.path.join(input_dir, pdf)
    split_pdf(pdf_path, output_dir)

print("所有 PDF 文件已拆分完成！")

