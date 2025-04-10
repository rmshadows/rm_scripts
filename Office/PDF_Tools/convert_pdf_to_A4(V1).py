import PyPDF2

#　ｐｄｆ转A4 不稳定　测试效果不好，建议用V2

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
            is_landscape = page_width > page_height
            
            if is_landscape:
                # 横向页面，调整为横向 A4
                scale_x = A4_width / page_width
                scale_y = A4_height / page_height
            else:
                # 竖向页面，调整为竖向 A4
                scale_x = A4_width / page_width
                scale_y = A4_height / page_height
            
            scale = min(scale_x, scale_y)  # 保持比例
            
            # 缩放页面的内容
            page.scale_by(scale)
            
            # 如果页面的缩放后仍然没有填满A4，继续按比例填充
            new_width = page_width * scale
            new_height = page_height * scale
            if new_width < A4_width or new_height < A4_height:
                # 计算填充比例，确保页面填充整个A4
                fill_scale_x = A4_width / new_width
                fill_scale_y = A4_height / new_height
                fill_scale = max(fill_scale_x, fill_scale_y)
                
                # 缩放页面以填充 A4
                page.scale_by(fill_scale)
            
            # 如果页面是横向的，旋转到竖向 A4
            if is_landscape:
                page.rotate(90)  # 将横向页面旋转为竖向

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

