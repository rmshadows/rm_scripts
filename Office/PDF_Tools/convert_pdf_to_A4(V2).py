import PyPDF2

#　转pdf到A4

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
            page_width = float(page.mediabox.width)
            page_height = float(page.mediabox.height)
            
            # 判断页面是横向还是竖向
            if page_width > page_height:
                # 横向页面，调整为横向 A4
                scale_x = A4_width / page_width
                scale_y = A4_height / page_height
            else:
                # 竖向页面，调整为竖向 A4
                scale_x = A4_height / page_width
                scale_y = A4_width / page_height
            
            scale = min(scale_x, scale_y)  # 保持比例
            
            # 计算缩放后的尺寸
            new_width = page_width * scale
            new_height = page_height * scale
            
            # 如果是横向页面且调整为竖向A4，调整页面方向
            if page_width > page_height:
                page.rotate(90)  # 将横向页面旋转为竖向

            # 设置裁剪框
            page.scale_to(new_width, new_height)
            
            # 添加到输出PDF
            writer.add_page(page)
        
        # 写入输出PDF文件
        with open(output_pdf_path, "wb") as output_file:
            writer.write(output_file)

# 使用示例
input_pdf = "1.pdf"  # 输入 PDF 文件路径
output_pdf = "output_a4.pdf"  # 输出 PDF 文件路径

convert_pdf_to_A4(input_pdf, output_pdf)
print("PDF 转换为 A4 完成！")

