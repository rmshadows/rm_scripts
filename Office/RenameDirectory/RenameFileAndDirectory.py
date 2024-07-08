#!/usr/bin/python3
"""
根据文件指定的修改文件和文件夹名
"""
import os.path

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
MatchMode = 2
# 针对文件还是文件夹 0:all 1:file 2:dir
MatchObj = 0
# 包含隐藏文件
encludeHinddenFile = True

# 排除的目录和文件
exclude = ["__pycache__"]
# 排除带有xx字符串的文件、文件夹
exclude_str = None


def mode1(dir=".", encludeHindden=True, excludeFile=None, excludeStr=None, recursive=True):
    abd = os.path.abspath(dir)
    # 1:精确匹配每个字符串，然后修改文件名到指定的
    # 列出当前目录
    for file in m_System.ls(abd, encludeHindden):
        if m_System.fileOrDirectory(file) == 1 and MatchObj == 2:
            continue
        elif m_System.fileOrDirectory(file) == 2 and MatchObj == 1:
            continue
        # 如果再排除列表中，去除
        if excludeFile is not None:
            if m_System.isInExcludeList(file, excludeFile):
                print("排除{}".format(file))
                continue
        if excludeStr is not None:
            if m_System.isInExcludeList(file, excludeStr, 2):
                print("排除{}".format(file))
                continue
        # 绝对路径
        # print("file: {}".format(file))
        fn = m_System.getFileNameOrDirectoryName(file)
        # print("file name: {}".format(fn))
        # 如果文件名或者文件夹名匹配了
        if fn == r[0]:
            nfn = m_System.editFilename(file, r[1])
            print("重命名 {} -> {} ".format(file, nfn))
            m_System.moveFD(file, nfn)
    # 是文件夹就递归
    if recursive:
        for fr in m_System.ls(abd, encludeHindden):
            if m_System.fileOrDirectory(fr) == 2:
                mode1(fr, encludeHindden, excludeFile, excludeStr)


def mode2(dir=".", encludeHindden=True, excludeFile=None, excludeStr=None, recursive=True):
    abd = os.path.abspath(dir)
    # 2:不精确匹配，只要文件中有就修改为指定名称
    # 列出当前目录
    for file in m_System.ls(abd, encludeHindden):
        if m_System.fileOrDirectory(file) == 1 and MatchObj == 2:
            continue
        elif m_System.fileOrDirectory(file) == 2 and MatchObj == 1:
            continue
        if excludeFile is not None:
            if m_System.isInExcludeList(file, excludeFile):
                print("排除{}".format(file))
                continue
        if excludeStr is not None:
            if m_System.isInExcludeList(file, excludeStr, 2):
                print("排除{}".format(file))
                continue
        # 绝对路径
        # print("file: {}".format(file))
        fn = m_System.getFileNameOrDirectoryName(file)
        # print("file name: {}".format(fn))
        # 如果文件名或者文件夹名匹配了
        if r[0] in fn:
            nfn = m_System.editFilename(file, r[1])
            print("重命名 {} -> {} ".format(file, nfn))
            m_System.moveFD(file, nfn)
    # 是文件夹就递归
    if recursive:
        for fr in m_System.ls(abd, encludeHindden):
            if m_System.fileOrDirectory(fr) == 2:
                mode2(fr, encludeHindden, excludeFile, excludeStr)


def mode3(dir=".", encludeHindden=True, excludeFile=None, excludeStr=None, recursive=True):
    abd = os.path.abspath(dir)
    # 2:不精确匹配，只要文件中有就修改为指定名称
    # 列出当前目录
    for file in m_System.ls(abd, encludeHindden):
        if m_System.fileOrDirectory(file) == 1 and MatchObj == 2:
            continue
        elif m_System.fileOrDirectory(file) == 2 and MatchObj == 1:
            continue
        # 如果再排除列表中，去除
        if excludeFile is not None:
            if m_System.isInExcludeList(file, excludeFile):
                print("排除{}".format(file))
                continue
        if excludeStr is not None:
            if m_System.isInExcludeList(file, excludeStr, 2):
                print("排除{}".format(file))
                continue
        # 绝对路径
        # print("file: {}".format(file))
        fn = m_System.getFileNameOrDirectoryName(file)
        # print("file name: {}".format(fn))
        # 如果文件名或者文件夹名匹配了
        if r[0] in fn:
            rfn = fn.replace(r[0], r[1])
            nfn = m_System.editFilename(file, rfn)
            print("重命名 {} -> {} ".format(file, nfn))
            m_System.moveFD(file, nfn)
    # 是文件夹就递归
    if recursive:
        for fr in m_System.ls(abd, encludeHindden):
            if m_System.fileOrDirectory(fr) == 2:
                mode3(fr, encludeHindden, excludeFile, excludeStr)


if __name__ == '__main__':
    # 读取规则文件(检查/替换/模式)
    rules = m_System.readFileAsList(rulesFile)
    # r = [匹配][替换][模式]
    for r in rules:
        print("Rule: {} -> {}".format(r[0], r[1]))
        if MatchMode == 0:
            if r[2] == 1:
                mode1(".", encludeHinddenFile, exclude, exclude_str)
            elif r[2] == 2:
                mode2(".", encludeHinddenFile, exclude, exclude_str)
            elif r[2] == 3:
                mode3(".", encludeHinddenFile, exclude, exclude_str)
            else:
                print("未知模式")
                exit(0)
        elif MatchMode == 1:
            mode1(".", encludeHinddenFile, exclude, exclude_str)
        elif MatchMode == 2:
            mode2(".", encludeHinddenFile, exclude, exclude_str)
        elif MatchMode == 3:
            mode3(".", encludeHinddenFile, exclude, exclude_str)

