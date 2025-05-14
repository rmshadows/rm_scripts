#!/usr/bin/python3
"""
修改某个目录下所有Excel表格的值（递归）
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
# 是否替换所有工作表
REPLACE_ALL_WORKSHEET = False
REPLACE_ALL_WORKSHEET = True
# 检查值(注意，“”表示空和None ,而None指的是不论什么值，直接替换)
REPLACE_SRC = ""
# 修改值
REPLACE_DST = "2333"
# 保存文件后缀
SAVE_TO = "-replace"

if __name__ == '__main__':
    # 首先列出Excel
    es = m_System.getSuffixFile("xlsx", WDIR)
    # 然后检查单元格的值
    if CHECK_ONLY:
        for i in es:
            wb = m_ExcelOpenpyxl.loadExcel(i)
            if REPLACE_ALL_WORKSHEET:
                # 获取所有表名
                wss = m_ExcelOpenpyxl.getSheetNames(wb)
                for j in range(0, len(wss)):
                    ws = wb[wss[j]]
                    print("【文件 {} 的第 {} 个表】'{}' : {}".format(i, j,  CELL, ws[CELL].value))
            else:
                ws = m_ExcelOpenpyxl.getSheetByIndex(wb, 0)
                print("【{}】'{}' : {}".format(i, CELL, ws[CELL].value))
    else:
        for i in es:
            wb = m_ExcelOpenpyxl.loadExcel(i)
            wb1 = None
            if REPLACE_ALL_WORKSHEET:
                wss = m_ExcelOpenpyxl.getSheetNames(wb)
                for j in range(0, len(wss)):
                    ws = wb[wss[j]]
                    wb1 = m_ExcelOpenpyxl.replaceOneCellValue(wb, j, CELL, REPLACE_SRC, REPLACE_DST)
            else:
                ws = m_ExcelOpenpyxl.getSheetByIndex(wb, 0)
                wb1 = m_ExcelOpenpyxl.replaceOneCellValue(wb, 0, CELL, REPLACE_SRC, REPLACE_DST)
            if wb1 is not None:
                # 获取文件名和后缀
                basename, extension = os.path.splitext(i)
                ne = f"{basename}{SAVE_TO}{extension}"
                print("{} save to {}".format(i, ne))
                wb1.save(ne)
