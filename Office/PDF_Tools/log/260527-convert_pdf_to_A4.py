import PyPDF2

def convert_pdf_to_A4(input_pdf_path, output_pdf_path):
    # 打开输入PDF文件
    with open(input_pdf_path, "rb") as input_file:
        reader = PyPDF2.PdfReader(input_file)
        writer = PyPDF2.PdfWriter()
        
        # 定义A4页面的尺寸，单位是points (1 inch = 72 points)
        A4_width = 595.276  # A4宽度，单位是points
        A4_height = 841.890  # A4高度，单位是points
        
        # 遍历每一页
        for page_num in range(len(reader.pages)):
            page = reader.pages[page_num]
            
            # 获取原页面的尺寸
            page_width = page.mediaBox.getWidth()
            page_height = page.mediaBox.getHeight()
            
            # 计算缩放比例，保持比例调整到 A4 尺寸
            scale_x = A4_width / page_width
            scale_y = A4_height / page_height
            scale = min(scale_x, scale_y)
            
            # 调整页面的裁剪框和大小
            page.scale_to(A4_width * scale, A4_height * scale)
            
            # 添加到输出PDF
            writer.add_page(page)
        
        # 写入输出PDF文件
        with open(output_pdf_path, "wb") as output_file:
            writer.write(output_file)

# 使用示例
input_pdf = "input.pdf"  # 输入 PDF 文件路径
output_pdf = "output_a4.pdf"  # 输出 PDF 文件路径

convert_pdf_to_A4(input_pdf, output_pdf)
print("PDF 转换为 A4 完成！")

