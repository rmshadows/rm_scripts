#!/usr/bin/python3
"""
图片转pdf
"""
import m_PDF

imageDir = "images"
output = "output.pdf"

if __name__ == '__main__':
    m_PDF.image2pdf(imageDir, output)
