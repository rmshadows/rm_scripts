#!/usr/bin/python3
from openpyxl.reader.excel import load_workbook

import m_ExcelOpenpyxl

# 以行、列去除范围内空白单元格（后面内容会跟上）

# 示例调用
targetf = '1.xlsx'
output_file = 'removed-output.xlsx'
sheet_name = 'Sheet0'
cell_range = 'A1:D33'

if __name__ == '__main__':
    target_wb = load_workbook(targetf)
    m_ExcelOpenpyxl.remove_blank_cells(target_wb, sheet_name, cell_range, mode='row')
    target_wb.save(output_file)
