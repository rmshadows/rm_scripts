#!/usr/bin/python3
from openpyxl import Workbook
from openpyxl import load_workbook

"""
文档：https://openpyxl.readthedocs.io/en/stable/tutorial.html#accessing-one-cell

#### 访问单元格
访问单元格：ws['A4'] 或者 ws.cell(row=4, column=2, value=10)
多个单元格：cell_range = ws['A1':'C2']
>>> colC = ws['C']
>>> col_range = ws['C:D']
>>> row10 = ws[10]
>>> row_range = ws[5:10]

### 所有行
Worksheet.rows

"""


def createNewWorkbook(firstSheetName=None):
    """
    新建workbook但不是新建一个实际的文件
    获取第一张自动生成的表wb.active
    Args:
        firstSheetName: 第一Sheet表的名称
    Returns:

    """
    if firstSheetName is None:
        return Workbook()
    else:
        wb = Workbook()
        wb.active.title = firstSheetName
        return wb


def createSheet(wb, sheetName, position=None):
    """
    新增表格
    position = None # insert at the end (default)
     0) # insert at first position
     -1) # insert at the penultimate position
    默认名称：Sheet, Sheet1, Sheet2
    访问：wb["New Title"]
    Args:
        wb:
        sheetName: sheet名
        position: 位置

    Returns:
        返回新增的worksheet
    """
    if position is None:
        return wb.create_sheet(sheetName)
    else:
        return wb.create_sheet(sheetName, position)


def getSheetNames(wb):
    """
    返回Sheets名字
    Args:
        wb:workbook

    Returns:
        str
    """
    return wb.sheetnames


def getSheetByIndex(wb, index):
    """
    返回Sheet
    Args:
        wb:workbook
        index:索引
    Returns:
        str
    """
    return wb[getSheetNames(wb)[index]]


def copyWorksheet(wb, ws):
    """
    复制工作表
    Args:
        wb: 复制到某workbook
        ws: 要被复制的worksheet

    Returns:

    """
    return wb.copy_worksheet(ws)


def readRows(ws, min_row, max_row, min_col, max_col, valueOnly=True):
    """
    读行
    Args:
        ws: worksheet
        min_row: 开始行
        max_row: 结束行
        min_col: 开始列
        max_col: 结束列
        valueOnly: 是否仅返回值
    Returns:
        <Cell Sheet1.A1>
        <Cell Sheet1.A2>
    """
    cs = []
    for row in ws.iter_rows(min_row=min_row, max_row=max_row, min_col=min_col, max_col=max_col, values_only=valueOnly):
        for cell in row:
            print(cell)
            cs.append(cell)
    return cs


def readColumns(ws, min_col, max_col, min_row, max_row, valueOnly=True):
    """
        读列
        Args:
            ws: worksheet
            min_col: 开始列
            max_col: 结束列
            min_row: 开始行
            max_row: 结束行
            valueOnly: 是否仅返回值
        Returns:
            <Cell Sheet1.A1>
            <Cell Sheet1.A2>
        """
    cs = []
    for col in ws.iter_cols(min_row=min_row, max_row=max_row, min_col=min_col, max_col=max_col, values_only=valueOnly):
        for cell in col:
            print(cell)
            cs.append(cell)
    return cs


def getCellRange(ws, cell1, cell2):
    """
    返回一个范围内的单元格
    colC = ws['C']
    col_range = ws['C:D']
    row10 = ws[10]
    row_range = ws[5:10]
    Args:
        ws: worksheet
        ws['A1':'C2']
        cell1: 起始
        cell2: 末尾

    Returns:

    """
    return ws[cell1:cell2]


def getRowOrColumns(ws, name):
    """
    返回行或者列
    colC = ws['C']
    col_range = ws['C:D']
    row10 = ws[10]
    row_range = ws[5:10]
    Args:
        ws: worksheet
        ws['A1':'C2']
        cell1: 起始
        cell2: 末尾

    Returns:

    """
    return ws[name]


def isnumeric(value):
    """
    检查给定参数类型
    Args:
        value:

    Returns:

    """
    if isinstance(value, int) or isinstance(value, float):
        return True
    else:
        return False


def justReadOneRow(ws, row, deep=60, valueOnly=True):
    """
    读1行,50列
    Args:
        ws: worksheet
        row: 行
        valueOnly: 是否仅返回值
    Returns:
        <Cell Sheet1.A1>
        <Cell Sheet1.A2>
    """
    cs = []
    for row in ws.iter_rows(min_row=row, max_row=row, min_col=0, max_col=deep, values_only=valueOnly):
        for cell in row:
            print(cell)
            cs.append(cell)
    return cs


def excel_column_to_number(column_name):
    """
    列名转换为对应的列索引
    Args:
        column_name:

    Returns:

    """
    result = 0
    for char in column_name:
        result = result * 26 + ord(char) - ord('A') + 1
    return result


def justReadOneColumn(ws, col, deep=50, valueOnly=True):
    """
        读列
        Args:
            ws: worksheet
            min_col: 开始列
            max_col: 结束列
            min_row: 开始行
            max_row: 结束行
            valueOnly: 是否仅返回值
        Returns:
            <Cell Sheet1.A1>
            <Cell Sheet1.A2>
        """
    cs = []
    if not isnumeric(col):
        col = excel_column_to_number(col)
    for col in ws.iter_cols(min_row=0, max_row=deep, min_col=col, max_col=col, values_only=valueOnly):
        for cell in col:
            print(cell)
            cs.append(cell)
    return cs


def loadExcel(filename):
    """
    加载现有的Excel表格
    Args:
        filename:Excel文件名

    Returns:
        wb
    """
    return load_workbook(filename=filename)


def replaceOneCellValue(wb, ws, cell, checkValue, replacement, whenEqual=True):
    """
    替换单元格值
    Args:
        wb: workbook
        ws: 工作表名字（字符串）或者索引（数字）
        cell: 单元格名称
        checkValue: 检查的值
        replacement: 替换值
        whenEqual: 什么时候替换，True表示是某个值的时候替换

    Returns:
        修改 返回 wb ，没有返回None
    """
    modify = False
    if isnumeric(ws):
        wss = getSheetByIndex(wb, ws)
    else:
        wss = wb[ws]
    ck = str(wss[cell].value)
    if wss[cell].value is None:
        ck = ""
    if whenEqual:
        if ck == str(checkValue):
            wss[cell] = replacement
            modify = True
    else:
        if ck != str(checkValue):
            wss[cell] = replacement
            modify = True
    if modify:
        return wb
    else:
        return None


if __name__ == '__main__':
    print("Hello World")
