#!/usr/bin/python3
"""
根据文件指定的修改文件和文件夹名
"""

import m_System

# 规则文件
"""
格式:
查找的字符串(Tab)目标字符串(Tab)匹配模式
"""
rulesFile = "1.txt"
# 0:根据规则文件中的来
# 1:精确匹配每个字符串，然后修改文件名到指定的
# 2:不精确匹配，只要文件中有就修改为指定名称
# 3:不精确匹配，仅替换文件名中的该字符
MatchMode = 1

# 排除的目录和文件
exclude = ["__pycache__"]


if __name__ == '__main__':
    # 读取规则文件(检查/替换/模式)
    rules = m_System.readFileAsList(rulesFile)
    if MatchMode == 0:
        pass
    elif MatchMode == 1:
        # 1:精确匹配每个字符串，然后修改文件名到指定的
        # 列出当前目录
        for file in m_System.ls(".", True):
            print(file)
            print(m_System.getFileNameOrDirectoryName(file))
    elif MatchMode == 2:
        pass
    elif MatchMode == 3:
        pass

