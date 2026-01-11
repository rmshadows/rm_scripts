#!/usr/bin/python3
"""
合并某个文件夹下面的pdf文件
"""
import m_PDF

# 工作目录
targetDir = "pdfPages"
output = "output.pdf"

if __name__ == '__main__':
    m_PDF.mergePdfs(targetDir, output)
