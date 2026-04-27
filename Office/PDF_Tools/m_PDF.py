#!/usr/bin/python3
"""
处理、合成PDF的模块
"""
import os
import os.path as op
import random

from PIL import Image
Image.MAX_IMAGE_PIXELS = None

# 改成 pypdf
from pypdf import PdfReader, PdfWriter

# 如果需要保留原来的别名
pdf_reader = PdfReader
pdf_writer = PdfWriter

from pdf2image import convert_from_path

import sys

import m_System


def add_content(pdf_in_name: str, pdf_out_name: str, content_dict: dict):
    """
    添加PDF注释（目录）
    Args:
        pdf_in_name: pdf文件名
        pdf_out_name: 输出pdf文件名
        content_dict: 字典 title:page {"索引":1}
    """
    pdf_in = pdf_reader(pdf_in_name)
    pdf_out = pdf_writer()

    # ✅ cloneDocumentFromReader（旧） -> 逐页拷贝（新）
    for page in pdf_in.pages:
        pdf_out.add_page(page)

    # ✅ addBookmark（旧） -> add_outline_item（新），做兼容
    for key in content_dict.keys():
        page_index = int(content_dict[key]) - 1
        if hasattr(pdf_out, "add_outline_item"):
            pdf_out.add_outline_item(key, page_index)  # 新版
        else:
            pdf_out.addBookmark(key, page_index)       # 旧版

    with open(pdf_out_name, "wb") as fout:
        pdf_out.write(fout)


def mergePdfs(directory, output_pdf_file, filepathOrder=None, add_bookmark=False):
    """
    合并指定目录下的PDF文件为一个PDF文件（可选生成目录/书签）
    参数：
    directory (str): 待合并PDF文件所在目录路径
    output_pdf_file (str): 输出的合并后PDF文件路径
    filepathOrder (list, optional): 指定PDF合并顺序的文件路径列表。
                                   若为None，则按文件名自然排序后合并。
    add_bookmark (bool, optional): 是否生成目录（PDF左侧书签）。
                                  True = 生成（文件名 → 起始页）
                                  False = 不生成（默认，兼容旧逻辑）
    功能说明：
    1. 获取目录下所有PDF文件
    2. 若未指定顺序，则按自然排序依次合并
    3. 若指定顺序，则按给定列表顺序合并
    4. 可选：为每个PDF生成目录（书签），指向其在合并后PDF中的起始页
    5. 将合并结果写出为新的PDF文件

    注意事项：
    - 页码采用 pypdf 规则：从0开始计数（内部处理，用户无感）
    - 目录名称默认使用PDF文件名（不含扩展名）
    - filepathOrder中的路径需为完整路径或可被正确识别
    - 依赖外部方法 m_System.getSuffixFile 和 m_System.natsorted
    - 需确保 PdfWriter / PdfReader 已正确导入
    """

    import sys
    import os
    sys.setrecursionlimit(1200)

    writer = PdfWriter()
    pdf_files = m_System.getSuffixFile("pdf", directory, False)

    # 确定顺序
    if filepathOrder is None:
        pdf_files = m_System.natsorted(pdf_files)
    else:
        pdf_files = filepathOrder

    page_index = 0  # 当前累计页数（用于目录定位）

    for pdf in pdf_files:
        # ===== 可选：添加目录 =====
        if add_bookmark:
            title = os.path.splitext(os.path.basename(pdf))[0]

            # 兼容新旧 pypdf 接口
            if hasattr(writer, "add_outline_item"):
                writer.add_outline_item(title, page_index)
            else:
                writer.addBookmark(title, page_index)

        # ===== 合并PDF =====
        writer.append(pdf)

        # ===== 更新页码 =====
        try:
            reader = PdfReader(pdf)
            page_index += len(reader.pages)
        except Exception:
            # 单个PDF异常时不中断整体流程
            pass

    # ===== 写出文件 =====
    with open(output_pdf_file, "wb") as f:
        writer.write(f)

    if add_bookmark:
        print(f"✅ 合并完成（带目录）: {output_pdf_file}")
    else:
        print(f"✅ 合并完成: {output_pdf_file}")


def image2pdf(directory, output_pdf_name, content:bool=True, order=None, removePngJpeg=True, pdf_resolution=100.0):
    """
    将所给文件夹的jpg图片转为PDF文档（提供目录）
    Args:
        directory: 文件夹路径
        output_pdf_name: 导出PDF名称
        content: 是否需要注释
        order: 是否有顺序,给图片文件名列表
        removePngJpeg:是否删除png和jpeg(已经转化过的)
        pdf_resolution: pdf分辨率
    """
    # 列出文件夹中的文件
    img_file = []
    for ext in ["png", "jpg", "jpeg"]:
        for gf in m_System.getSuffixFile(ext, directory, False):
            img_file.append(gf)
    # 转化png和jpeg到jpg
    for imgf in img_file:
        img_ext = m_System.splitFilePath(imgf)[2][1:]
        # 转化png为jpg  change all png into jpg & delete the .png files
        if img_ext == "png":
            # r, g, b, a = img.split()
            # img = Image.merge("RGB", (r, g, b))
            img = Image.open(imgf)
            if img.mode == "RGBA":
                img = img.convert("RGB")
            #     def editFilename(src, dst, prefix=None, suffix=None, ext=None):
            to_save_path = m_System.editFilename(imgf, None, None, None, ".jpg")
            img.save(to_save_path)
            # 删除原来的png
            if removePngJpeg:
                os.remove(imgf)
        elif img_ext == "jpeg":
            img = Image.open(imgf)
            # 构造完整文件路径
            to_save_path = m_System.editFilename(imgf, None, None, None, ".jpg")
            # 打开图像并保存为 .jpg 格式
            img.save(to_save_path, 'JPEG')
            print(f'Converted {imgf} to {to_save_path}')
            if removePngJpeg:
                os.remove(imgf)
        else:
            continue
    # 添加图片
    pdf_imgs = []
    if order is None:
        # 如果没制定顺序
        for jpg in m_System.getSuffixFile("jpg", directory, False):
            pdf_imgs.append(jpg)
    else:
        for jpg_file in order:
            pdf_imgs.append(jpg_file)
    # 排序
    if order is None:
        pdf_imgs = m_System.natsorted(pdf_imgs)
    # print(f"排序后的图像：{pdf_imgs}")
    # 生成目录
    content_dict = {}
    # 图片列表
    img_list = []
    n = 1
    # ['selectedPages/1.jpg', 'selectedPages/2.jpg', 'selectedPages/2.jpg']
    for f in pdf_imgs:
        c = m_System.splitFilePath(f)[1]
        content_dict[c] = n
        img_list.append(Image.open(f))
        n += 1
    # print(content_dict)
    # 制作pdf文件
    # 添加第一张图
    output_pdf = Image.open(pdf_imgs[0])
    # 去除第一张，因为第一张已经添加了
    img_list.pop(0)
    output_pdf.save(output_pdf_name, "PDF", resolution=pdf_resolution, save_all=True, append_images=img_list)
    if content:
        # 生成中间文件过渡防意外
        r = "{}.pdf".format(random.randint(9999,999999))
        os.rename(output_pdf_name, r)
        try:
            add_content(r, output_pdf_name, content_dict)
            os.remove(r)
        except Exception as e:
            print(e)


def pdf2images(pdfFile, dpi=200, format='png', output_directory="2images",
               max_size=None, mode="size"):
    m_System.mkdir(output_directory)
    if mode == "dpi":
        pages = convert_from_path(pdfFile, dpi=dpi, fmt=format)
    elif mode == "size":
        pages = convert_from_path(pdfFile, dpi=dpi, fmt=format, size=max_size)
    else:
        raise ValueError("mode 必须是 'dpi' 或 'size'")
    for i, page in enumerate(pages):
        page.save(op.join(output_directory, f"{i+1}.{format}"))
        print(f"页面 {i+1} 已经保存")


def jpg_to_individual_pdf(directory):
    """
    将指定文件夹中的每张 JPG 图片转换为单独的 PDF 文件
    Args:
        directory: 图片文件夹路径
    """
    # 获取文件夹中的所有 JPG 图片文件
    jpg_files = [file for file in os.listdir(directory) if file.lower().endswith('.jpg')]
    # 对文件名进行排序
    jpg_files.sort()
    # 逐个处理每张 JPG 图片
    for jpg_file in jpg_files:
        # 打开 JPG 图片
        with Image.open(os.path.join(directory, jpg_file)) as img:
            # 创建一个新的 PDF 文档
            output_pdf_name = os.path.splitext(jpg_file)[0] + '.pdf'
            # 将 JPG 图片保存为 PDF 文件
            img.save(output_pdf_name, 'PDF')


def batch_split_pdf(input_pdf_path, output_folder, pdf_strict=False):
    """批量拆分 PDF 为单页 PDF"""
    # pypdf.errors.PdfReadError: Could not read Boolean object
    # sudo apt install qpdf
    # qpdf --linearize 原文件.pdf 修复后.pdf
    pdf_name = os.path.splitext(os.path.basename(input_pdf_path))[0]  # 获取文件名（无扩展名）
    with open(input_pdf_path, "rb") as pdf_file:
        reader = pdf_reader(pdf_file, strict=pdf_strict)
        total_pages = len(reader.pages)
        for page_num in range(total_pages):
            writer = pdf_writer()
            writer.add_page(reader.pages[page_num])
            output_pdf_path = os.path.join(output_folder, f"{pdf_name}_page{page_num + 1}.pdf")
            with open(output_pdf_path, "wb") as output_pdf:
                writer.write(output_pdf)
            print(f"已拆分: {output_pdf_path}")


def split_single_pdf(input_pdf_path, output_dir, export_menu=False):
    """
    将PDF拆分成单页的PDF文件
    Args:
        input_pdf_path: 输入PDF文件路径
        output_dir: 输出目录路径
        export_menu: 是否导出目录
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    input_pdf = PdfReader(open(input_pdf_path, "rb"))
    total_pages = len(input_pdf.pages)
    for page_number in range(total_pages):
        pdf_writer = PdfWriter()
        pdf_writer.add_page(input_pdf.pages[page_number])
        output_pdf_path = os.path.join(output_dir, f"page_{page_number + 1}.pdf")
        with open(output_pdf_path, "wb") as output_pdf_file:
            pdf_writer.write(output_pdf_file)
        print(f"Saved: {output_pdf_path}")
    if export_menu:
        export_bookmarks(input_pdf_path, os.path.join(output_dir, "menu.txt"))


def get_bookmarks(pdf_path, outlines=None, parent_name=""):
    """
    获取PDF书签
    Args:
        pdf_path: 输入PDF文件路径
        outlines: 当前的书签列表
        parent_name: 父书签名称

    Returns:
        bookmarks: 包含页码和标题的书签列表
    """
    pdf_reader = PdfReader(open(pdf_path, "rb"))
    if outlines is None:
        outlines = pdf_reader.outlines
    bookmarks = []
    for outline in outlines:
        if isinstance(outline, list):
            # 递归处理子书签
            bookmarks += get_bookmarks(pdf_path, outline, parent_name)
        else:
            title = outline.title if not parent_name else f"{parent_name} - {outline.title}"
            bookmarks.append((pdf_reader.get_destination_page_number(outline) + 1, title))
    return bookmarks


def export_bookmarks(input_pdf_path, output_txt_path, delimiter="\t", ignoreTheSame=False):
    """
    导出PDF目录与页码的关系
    Args:
        input_pdf_path: 输入PDF文件路径
        output_txt_path: 输出文本文件路径
        delimiter: 分隔符
        ignoreTheSame: true则页面序号不会有重复
    """
    bookmarks = get_bookmarks(input_pdf_path)
    with open(output_txt_path, "w", encoding="utf-8") as f:
        for page_number in range(1, len(PdfReader(open(input_pdf_path, "rb")).pages) + 1):
            found = False
            for bookmark_page, title in bookmarks:
                if ignoreTheSame:
                    if bookmark_page == page_number:
                        f.write(f"{page_number}{delimiter}{title}\n")
                        found = True
                        break
                else:
                    f.write(f"{page_number}{delimiter}{title}\n")
                    found = True
            if not found:
                f.write(f"{page_number}{delimiter}None\n")


def rotate_pdf_pages(directory, rotation_angle):
    """
    将指定文件夹中的所有PDF文件按照指定角度顺时针旋转
    Args:
        directory: 包含PDF文件的文件夹路径
        rotation_angle: 旋转角度，可以是90、180、270等

    Returns:
        None
    """
    # 获取文件夹中所有PDF文件
    pdf_files = [f for f in os.listdir(directory) if f.endswith('.pdf')]
    for pdf_file in pdf_files:
        pdf_path = os.path.join(directory, pdf_file)
        output_path = os.path.join(directory, f"rotated_{pdf_file}")  # 新文件名加前缀
        # 打开PDF文件
        with open(pdf_path, 'rb') as file:
            pdf_reader = PdfReader(file)
            pdf_writer = PdfWriter()
            # 遍历PDF的每一页
            for page_num in range(len(pdf_reader.pages)):
                page = pdf_reader.pages[page_num]
                page.rotate(rotation_angle)
                pdf_writer.add_page(page)
            # 保存修改后的PDF文件到新文件
            with open(output_path, 'wb') as output_file:
                pdf_writer.write(output_file)


def get_pdf_page_sizes(pdf_file):
    """
    获取 PDF 文件中每一页的大小（宽度和高度）。

    Args:
    - pdf_file: PDF 文件路径。

    Returns:
    - page_sizes: 包含每一页大小的列表，每个元素是一个元组 (width, height)。
    """
    page_sizes = []
    with open(pdf_file, 'rb') as f:
        pdf_reader = PdfReader(f)
        num_pages = len(pdf_reader.pages)
        for page_num in range(num_pages):
            page = pdf_reader.pages[page_num]
            width = page.mediabox.upper_right[0] - page.mediabox.lower_left[0]
            height = page.mediabox.upper_right[1] - page.mediabox.lower_left[1]
            page_sizes.append((width, height))
    return page_sizes


def parse_page_numbers(page_numbers_str):
    """
    解析页码字符串，支持范围和重复页码。
    Args:
        page_numbers_str: 页码字符串，如 "2, 3-5, 4-5"
    Returns:
        page_numbers: 页码列表
    """
    page_numbers = []
    parts = page_numbers_str.split(',')
    for part in parts:
        part = part.strip()
        if '-' in part:
            start, end = map(int, part.split('-'))
            page_numbers.extend(range(start, end + 1))
        else:
            page_numbers.append(int(part))
    return page_numbers


def extract_pages_to_pdf(input_pdf_path, output_pdf_path, page_numbers_str):
    """
    从PDF文件中提取指定页码并保存为新的PDF文件
    Args:
        input_pdf_path: 输入PDF文件路径
        output_pdf_path: 输出PDF文件路径（文件夹）
        page_numbers_str: 要提取的页码字符串 None的话就是全部
    """
    if page_numbers_str is None:
        split_single_pdf(input_pdf_path, output_pdf_path, False)
    else:
        page_numbers = parse_page_numbers(page_numbers_str)
        page_numbers = set(page_numbers)
        pdf_reader = PdfReader(input_pdf_path)
        for page_number in page_numbers:
            if 1 <= page_number <= len(pdf_reader.pages):
                pdfp = os.path.join(output_pdf_path, str(page_number)) + ".pdf"
                print(pdfp)
                pdf_writer = PdfWriter()
                pdf_writer.add_page(pdf_reader.pages[page_number - 1])
                with open(pdfp, "wb") as f:
                    pdf_writer.write(f)
                print(f"提取的页面已保存为 {pdfp}")
                # pdf_writer.add_page(pdf_reader.pages[page_number - 1])
            else:
                print(f"页码 {page_number} 不在有效范围内")


def extract_pages_to_jpg(input_pdf_path, output_dir, page_numbers_str,
                         dpi=300, max_size=None, mode="size"):

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    if page_numbers_str is None:
        input_pdf_path = os.path.abspath(input_pdf_path)
        output_dir = os.path.abspath(output_dir)
        print(f"当前文件: {input_pdf_path}")
        pdf2images(
            input_pdf_path,
            dpi=dpi,
            format="jpg",
            output_directory=output_dir,
            max_size=max_size,
            mode=mode
        )
    else:
        page_numbers = set(parse_page_numbers(page_numbers_str))
        for page_number in page_numbers:
            if mode == "dpi":
                pages = convert_from_path(
                    input_pdf_path,
                    dpi=dpi,
                    first_page=page_number,
                    last_page=page_number
                )
            elif mode == "size":
                pages = convert_from_path(
                    input_pdf_path,
                    dpi=dpi,
                    first_page=page_number,
                    last_page=page_number,
                    size=max_size
                )
            else:
                raise ValueError("mode 必须是 'dpi' 或 'size'")
            for page in pages:
                output_jpg_path = os.path.join(output_dir, f"{page_number}.jpg")
                page.save(output_jpg_path, "JPEG")
                print(f"页码 {page_number} 已保存为 {output_jpg_path}")


if __name__ == '__main__':
    # 合并PDF
    # image2pdf("images", "output.pdf")
    # for i in get_pdf_page_sizes("1.pdf"):
    #     print(i)
    print(parse_page_numbers("1-3"))