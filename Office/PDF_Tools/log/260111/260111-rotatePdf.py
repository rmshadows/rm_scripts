#!/usr/bin/python3
"""
PDF文件顺时针旋转
"""
import m_PDF

# 工作目录
targetDir = "pdfPages"
rotation_angle = 90

if __name__ == '__main__':
    m_PDF.rotate_pdf_pages(targetDir, rotation_angle)
