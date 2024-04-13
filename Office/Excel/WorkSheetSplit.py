#!/usr/bin/python3
"""
拆分worksheet
"""
import m_ExcelOpenpyxl

# 表格
WORKBOOK = "1.xlsx"

if __name__ == '__main__':
    m_ExcelOpenpyxl.worksheetSplitInto(WORKBOOK)
