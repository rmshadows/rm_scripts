"""
替换某个目录下excel表中某个范围内所有值为xxx的到yyy
注意：合并单元格不会改动
"""
import os.path

import m_ExcelOpenpyxl
import m_System

# 工作目录
WDIR = "."
# 单元格范围 如："A1:G19" 或者来自文件，如果来自文件则不会按照REPLACE_SRC和REPLACE_DST来，而是读取文件中的
"""
文件示例：
r.txt：
【单元格】（tab）【值】（tab）【替换的值】
"""
CELL = "A1:G19"
# CELL = "1.txt"
# 检查值(注意，“”表示空和None ,而None指的是不论什么值，直接替换)
REPLACE_SRC = ""
# 修改值
REPLACE_DST = "无"
# 是否替换所有工作表 允许值：True,False(默认第一张),索引,名称
REPLACE_ALL_WORKSHEET = True
# 保存文件前缀
FPrefix = "replace-"


def isNumber(var):
    return isinstance(var, (int, float))


def isBoolean(var):
    return isinstance(var, bool)


def isString(var):
    return isinstance(var, str)


def getWorksheets(wb):
    wss = []
    print(f"======================={wb}========================")
    try:
        if isBoolean(REPLACE_ALL_WORKSHEET):
            # 如果所有worksheet都要
            if REPLACE_ALL_WORKSHEET:
                for i in m_ExcelOpenpyxl.getSheetNames(wb):
                    wss.append(wb[i])
                print("Log: 添加所有Worksheet.")
            else:
                # 不是就第一张
                wss.append(m_ExcelOpenpyxl.getSheetByIndex(wb, 0))
                print("Log: 添加第一张Worksheet.")
        elif isNumber(REPLACE_ALL_WORKSHEET):
            # 如果指定worksheet
            wss.append(m_ExcelOpenpyxl.getSheetByIndex(wb, REPLACE_ALL_WORKSHEET))
            print(f"Log: 添加索引为{REPLACE_ALL_WORKSHEET}的Worksheet.")
        elif isBoolean(REPLACE_ALL_WORKSHEET):
            # 如果指定名称
            wss.append(wb[REPLACE_ALL_WORKSHEET])
            print(f"Log: 添加名称为{REPLACE_ALL_WORKSHEET}的Worksheet.")
        else:
            pass
    except Exception as e:
        print(e)
    return wss


if __name__ == '__main__':
    # 首先获取excel文件
    wbfs = m_System.getSuffixFile("xlsx", WDIR, False)
    # 遍历Excel文件添加ws
    for wbf in wbfs:
        changed = False
        # 从文件中选取worksheet
        wb = m_ExcelOpenpyxl.loadExcel(wbf)
        for ws in getWorksheets(wb):
            print(f"开始处理Worksheet: {ws}")
            # 处理单元格范围
            if os.path.exists(CELL):
                # print("将从文件中读取……")
                # 单元格 src dst
                for para in m_System.readFileAsList(CELL):
                    if str(ws[para[0]].value) == para[1]:
                        try:
                            ws[para[0]].value = para[2]
                            changed = True
                        except Exception as e:
                            print(f"{para[0]} : {e}")
            else:
                # 给定单元格范围内处理
                print(f"单元格范围：{CELL}")
                for i in ws[CELL]:
                    for j in i:
                        # 每个单元格
                        if REPLACE_SRC == "":
                            if j.value == "" or j.value is None:
                                # 如果是合并的单元格是修改不了数值的
                                try:
                                    j.value = REPLACE_DST
                                    changed = True
                                except Exception as e:
                                    print(f"{j}: {e}")
                        else:
                            # 这里会吧数字也当作字符串处理
                            if str(j.value) == REPLACE_SRC:
                                # 如果是合并的单元格是修改不了数值的
                                try:
                                    j.value = REPLACE_DST
                                    changed = True
                                except Exception as e:
                                    print(f"{j}: {e}")
        if changed:
            wb.save(m_System.editFilename(wbf, dst=None, prefix=FPrefix))
