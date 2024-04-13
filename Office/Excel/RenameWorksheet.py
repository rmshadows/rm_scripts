"""
重命名worksheet，如果没有读取到RenameFile，会显示当前excel的worksheets名称
"""
import os.path

import m_ExcelOpenpyxl
import m_System

Workbook = "1.xlsx"
RenameFile = "1.txt"
OutputFile = "Rename.xlsx"
ACTION = False
ACTION = True

if __name__ == '__main__':
    wb = m_ExcelOpenpyxl.loadExcel(Workbook)
    # 如果没有RenameFile
    if not os.path.exists(RenameFile):
        for i in m_ExcelOpenpyxl.getSheetNames(wb):
            print(i)
        exit(0)
    # 读取文件获取重命名的符号
    RN = []
    with open(RenameFile, "r", encoding="utf-8") as f:
        n = 1
        for i in f.readlines():
            i = m_System.remove_newlines(i)
            # print("{}: {}".format(n, i))
            if i == "":
                continue
            n += 1
            RN.append(i)
    # 打印表名
    WSN = m_ExcelOpenpyxl.getSheetNames(wb)
    for i in range(0, len(WSN)):
        print("{}: {} - > {}".format(i, WSN[i], RN[i]))
    # 执行
    if ACTION:
        for i in range(0, len(WSN)):
            wb[WSN[i]].title = RN[i]
        wb.save(OutputFile)


