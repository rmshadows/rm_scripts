#!/usr/bin/python3
"""
PDF拆分(每一页),可实现pdf转图片
"""
import os.path

import m_PDF
import m_System

targetPdf = "1.pdf"
# targetPdf = "src"
outputPdfDir = "selectedPages"
# e.g.: pages = "2, 3-5, 4-5" 如果pages是None 则提取全部
pages_string = None
# pages_string = "1"

# 模式 True: JPG False:PDF
JpgMode = False
# JpgMode = True
jpgDPI = 300

# 是否生成新的pdf文件
# exportAsPDF = False
exportAsPDF = True
outputPdf = "soutput.pdf"


if __name__ == '__main__':
    if not os.path.exists(outputPdfDir):
        os.mkdir(outputPdfDir)
    # 拆分
    if os.path.isfile(targetPdf):
        # 如果是文件
        if JpgMode:
            m_PDF.extract_pages_to_jpg(targetPdf, outputPdfDir, pages_string, jpgDPI)
        else:
            m_PDF.extract_pages_to_pdf(targetPdf, outputPdfDir, pages_string)
        # 导出pdf文件
        if exportAsPDF:
            order_list = []
            if JpgMode:
                if pages_string is None:
                    m_PDF.image2pdf(outputPdfDir, outputPdf, pdf_resolution=300.0)
                else:
                    pages_list = m_PDF.parse_page_numbers(pages_string)
                    for i in pages_list:
                        order_list.append(os.path.join(outputPdfDir, f"{i}.jpg"))
                    m_PDF.image2pdf(outputPdfDir, outputPdf, order=order_list, pdf_resolution=300.0)
            else:
                if pages_string is None:
                    m_PDF.mergePdfs(outputPdfDir, outputPdf)
                else:
                    pages_list = m_PDF.parse_page_numbers(pages_string)
                    for i in pages_list:
                        order_list.append(os.path.join(outputPdfDir, f"{i}.pdf"))
                    m_PDF.mergePdfs(outputPdfDir, outputPdf, order_list)
    else:
        pdffs = m_System.getSuffixFile("pdf", targetPdf, False)
        for pdff in pdffs:
            print("\n\n\n")
            try:
                # 输出文件夹: {文件夹名字}{文件名}
                # src/20220314-漳州市龙海区农村人居环境整治领导小组办公室关于印发《农村人居环境整治工作成效“红黑榜”制度实施方案》的通知（龙人居办[2022]2号）.pdf
                pdfn = m_System.getFileNameOrDirectoryName(pdff)
                outputd = os.path.join(outputPdfDir, pdfn)
                m_System.mkdir(outputd)
                if JpgMode:
                    m_PDF.extract_pages_to_jpg(pdff, outputd, pages_string, jpgDPI)
                else:
                    m_PDF.extract_pages_to_pdf(pdff, outputd, pages_string)
                # 生成pdf文件
                order_list = []
                outputp = m_System.editFilename(pdff, None, prefix="selected-")
                if JpgMode:
                    if pages_string is None:
                        m_PDF.image2pdf(outputd, outputp, pdf_resolution=300.0)
                    else:
                        pages_list = m_PDF.parse_page_numbers(pages_string)
                        for i in pages_list:
                            order_list.append(os.path.join(outputd, f"{i}.jpg"))
                        m_PDF.image2pdf(outputd, outputp, order=order_list, pdf_resolution=300.0)
                else:
                    if pages_string is None:
                        m_PDF.mergePdfs(outputd, outputp)
                    else:
                        pages_list = m_PDF.parse_page_numbers(pages_string)
                        for i in pages_list:
                            order_list.append(os.path.join(outputd, f"{i}.pdf"))
                        m_PDF.mergePdfs(outputd, outputp, order_list)
            except Exception as e:
                print(f"错误: {pdff} - {e}")
