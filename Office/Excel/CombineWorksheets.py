"""
合并某个文件夹中的Excel表格
"""
import m_ExcelOpenpyxl
import m_System


# 工作目录
WDIR = "src"

# True：复制全部worksheet，False仅复制第一张，数字：指定Index，字符串：指定名称
CopyAllWorksheet = True
# 显示详情
Verbose = False

def isNumber(var):
    return isinstance(var, (int, float))
def isBoolean(var):
    return isinstance(var, bool)
def isString(var):
    return isinstance(var, str)


def getWorksheets(wb):
    wss = []
    try:
        if isBoolean(CopyAllWorksheet):
            # 如果所有worksheet都要
            if CopyAllWorksheet:
                for i in m_ExcelOpenpyxl.getSheetNames(wb):
                    wss.append(wb[i])
                # print("Log: 添加所有Worksheet.")
            else:
                # 不是就第一张
                wss.append(m_ExcelOpenpyxl.getSheetByIndex(wb, 0))
                # print("Log: 添加第一张Worksheet.")
        elif isNumber(CopyAllWorksheet):
            # 如果指定worksheet
            wss.append(m_ExcelOpenpyxl.getSheetByIndex(wb, CopyAllWorksheet))
            # print(f"Log: 添加索引为{CopyAllWorksheet}的Worksheet.")
        elif isString(CopyAllWorksheet):
            # 如果指定名称
            wss.append(wb[CopyAllWorksheet])
            # print(f"Log: 添加名称为{CopyAllWorksheet}的Worksheet.")
        else:
            pass
    except Exception as e:
        print(e)
    return wss


if __name__ == '__main__':
    firstExcel = True
    saveWb = None
    for wbf in m_System.getSuffixFile("xlsx", WDIR, False):
        wb = None
        if Verbose:
            print(f"Log: 当前文件 = {wbf}")
        # 第一张表不做处理(以此为基础)
        if firstExcel:
            saveWb = m_ExcelOpenpyxl.loadExcel(wbf)
            # 选取需要的worksheet
            keepWs = []
            for i in getWorksheets(saveWb):
                # 添加的是名字
                keepWs.append(i.title)
            for i in m_ExcelOpenpyxl.getSheetNames(saveWb):
                if i not in keepWs:
                    # 删除不需要的表
                    m_ExcelOpenpyxl.deleteWorksheet(saveWb, i)
            if Verbose:
                for ws in m_ExcelOpenpyxl.getSheetNames(saveWb):
                    print(f"Log: 当前Worksheet = {saveWb[ws]}")
            firstExcel = False
            continue
        else:
            # 不是第一张Excel就添加
            wb = m_ExcelOpenpyxl.loadExcel(wbf)
            for ws in getWorksheets(wb):
                if Verbose:
                    print(f"Log: 当前Worksheet = {ws}")
                try:
                    saveWb = m_ExcelOpenpyxl.copyWorksheetInto(wb, ws.title, saveWb, None)
                except Exception as e:
                    print(e)
    print("合并完成。")
    saveWb.save("mergedExcel.xlsx")