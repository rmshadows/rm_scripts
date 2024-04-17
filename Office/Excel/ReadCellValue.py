"""
读取某个单元格的值
"""
import os.path

import m_ExcelOpenpyxl
import m_System

# 要读取的单元格名称
CELL = "F3"

# 读取单个文件或者某个目录
Target = "1.xlsx"
# Target = "src"
# 工作表索引或者名称或者全部
ReadAllWorksheets = True
# 详情(值)
Detail = False


def isNumber(var):
    return isinstance(var, (int, float))


def isBoolean(var):
    return isinstance(var, bool)


def isString(var):
    return isinstance(var, str)


if __name__ == '__main__':
    if os.path.isfile(Target):
        # 如果是单个文件
        wb = m_ExcelOpenpyxl.loadExcel(Target)
        if isBoolean(ReadAllWorksheets):
            # 如果所有worksheet都要
            if ReadAllWorksheets:
                for ws in m_ExcelOpenpyxl.getSheetNames(wb):
                    if Detail:
                        print(f"{Target}-{ws}：{wb[ws][CELL].value}")
                    else:
                        print(wb[ws][CELL].value)
            else:
                # 不是就第一张
                if Detail:
                    ws = m_ExcelOpenpyxl.getSheetByIndex(wb, 0)
                    print(f"{Target}-{ws}：{ws[CELL].value}")
                else:
                    print(m_ExcelOpenpyxl.getSheetByIndex(wb, 0)[CELL].value)
        elif isNumber(ReadAllWorksheets):
            # 如果指定worksheet
            if Detail:
                ws = m_ExcelOpenpyxl.getSheetByIndex(wb, ReadAllWorksheets)
                print(f"{Target}-{ws}：{ws[CELL].value}")
            else:
                print(m_ExcelOpenpyxl.getSheetByIndex(wb, ReadAllWorksheets)[CELL].value)
        elif isString(ReadAllWorksheets):
            # 如果指定名称
            print(wb[ReadAllWorksheets][CELL].value)
    else:
        # 如果是目录
        for wbf in m_System.getSuffixFile("xlsx", Target, False):
            wb = m_ExcelOpenpyxl.loadExcel(wbf)
            if isBoolean(ReadAllWorksheets):
                # 如果所有worksheet都要
                if ReadAllWorksheets:
                    for ws in m_ExcelOpenpyxl.getSheetNames(wb):
                        if Detail:
                            print(f"{wbf}-{ws}：{wb[ws][CELL].value}")
                        else:
                            print(wb[ws][CELL].value)
                else:
                    # 不是就第一张
                    if Detail:
                        ws = m_ExcelOpenpyxl.getSheetByIndex(wb, 0)
                        print(f"{wbf}-{ws}：{ws[CELL].value}")
                    else:
                        print(m_ExcelOpenpyxl.getSheetByIndex(wb, 0)[CELL].value)
            elif isNumber(ReadAllWorksheets):
                # 如果指定worksheet
                if Detail:
                    ws = m_ExcelOpenpyxl.getSheetByIndex(wb, ReadAllWorksheets)
                    print(f"{wbf}-{ws}：{ws[CELL].value}")
                else:
                    print(m_ExcelOpenpyxl.getSheetByIndex(wb, ReadAllWorksheets)[CELL].value)
            elif isString(ReadAllWorksheets):
                # 如果指定名称
                print(wb[ReadAllWorksheets][CELL].value)