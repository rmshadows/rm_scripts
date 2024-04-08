#!/usr/bin/python3
"""
修改某个目录下Excel表格的值（递归）
"""
import os

import m_ExcelOpenpyxl
import m_System

# 工作目录
WDIR = "."
# 单元格
CELL = "F4"
# 仅查看值
CHECK_ONLY = True
CHECK_ONLY = False
# 检查值(注意，“”表示空和None)
REPLACE_SRC = ""
# 修改值
REPLACE_DST = ""
# 保存文件后缀
SAVE_TO = "-c"

if __name__ == '__main__':
    # 首先列出Excel
    es = m_System.getSuffixFile("xlsx", WDIR)
    # 然后检查单元格的值
    if CHECK_ONLY:
        for i in es:
            wb = m_ExcelOpenpyxl.loadExcel(i)
            ws = m_ExcelOpenpyxl.getSheetByIndex(wb, 0)
            print("【{}】'{}' : {}".format(i, CELL, ws[CELL].value))
    else:
        for i in es:
            wb = m_ExcelOpenpyxl.loadExcel(i)
            ws = m_ExcelOpenpyxl.getSheetByIndex(wb, 0)
            wb1 = m_ExcelOpenpyxl.replaceOneCellValue(wb, 0, CELL, REPLACE_SRC, REPLACE_DST)
            if wb1 is not None:
                # 获取文件名和后缀
                basename, extension = os.path.splitext(i)
                ne = f"{basename}{SAVE_TO}{extension}"
                print("{} save to {}".format(i, ne))
                wb1.save(ne)
