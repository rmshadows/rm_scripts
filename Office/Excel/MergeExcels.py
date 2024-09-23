#!/usr/bin/python3
import m_ExcelOpenpyxl
# 合并excel
# 示例调用
src_folder = 'src'
output_file = 'merged_output.xlsx'
sheet_name = 'Sheet0'
cell_range = 'A5:X66'

if __name__ == '__main__':
    wb = m_ExcelOpenpyxl.merge_excel_with_format_and_merged_cells(src_folder, None, sheet_name, cell_range)
    m_ExcelOpenpyxl.remove_blank_rows_or_columns(wb, sheet_name, mode='row')  # 移除空白行
    wb.save(output_file)
