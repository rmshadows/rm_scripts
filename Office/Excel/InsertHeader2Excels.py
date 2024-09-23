#!/usr/bin/python3

# 插入表头
import m_ExcelOpenpyxl

# 示例调用
target_file = '1.xlsx'  # 目标文件
header_file = 'header.xlsx'  # 包含表头的文件
header_range = 'A1:X3'  # 表头区域
target_sheets = None  # 插入所有工作表，或指定为['Sheet1', 'Sheet2']
output_filename = "inserted.xlsx"

if __name__ == '__main__':
    # 执行插入表头操作
    m_ExcelOpenpyxl.insert_header_from_excel(target_file, header_file, header_range, target_sheets, output_filename)
