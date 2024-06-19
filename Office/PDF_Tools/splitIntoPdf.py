#!/usr/bin/python3
"""
PDF拆分(每一页)
"""
import m_PDF

targetPdf = "1.pdf"
outputDir = "pdfPages"
exportMenu = False

if __name__ == '__main__':
    m_PDF.split_pdf(targetPdf, outputDir, exportMenu)