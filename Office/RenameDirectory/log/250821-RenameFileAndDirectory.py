#!/usr/bin/python3
"""
文件/文件夹批量重命名脚本（优化版）
================================
功能：
  - 根据规则文件，对指定目录下的文件或文件夹批量改名
  - 支持精确匹配 / 模糊匹配 / 替换部分字符
  - 可设置仅针对文件或文件夹，或两者同时处理
  - 可设置是否包含隐藏文件、排除指定目录/文件
  - includeExtension 控制匹配名是否包含扩展名
  - 新增 doRename、doRecursive、verbose 控制执行和输出
"""

import os.path
import m_System

# ===== 内部参数 =====
rulesFile = "1.txt"           # 规则文件
MatchMode = 0                 # 0=规则文件指定，1=精确，2=模糊，3=替换
MatchObj = 0                  # 0=all，1=file，2=dir
encludeHinddenFile = True     # 是否包含隐藏文件
includeExtension = False      # 匹配时是否包含扩展名
# includeExtension = True
exclude = ["__pycache__", "1.txt"]
exclude_str = None

# ===== 控制参数 =====
doRename = True               # 是否实际重命名
doRename = False
doRecursive = True            # 是否递归子目录
verbose = True                # 是否打印调试信息


def get_name_for_match(file: str) -> str:
    """获取匹配名，精确匹配时只匹配主体名"""
    fn = m_System.getFileNameOrDirectoryName(file)
    is_file = m_System.fileOrDirectory(file) == 1
    if MatchMode == 1 and is_file:
        return os.path.splitext(fn)[0]
    if not includeExtension and is_file:
        return os.path.splitext(fn)[0]
    return fn


def build_new_name(file: str, newbase: str) -> str:
    """生成最终新文件名"""
    is_file = m_System.fileOrDirectory(file) == 1
    if not includeExtension and is_file:
        ext = os.path.splitext(file)[1]
        return m_System.editFilename(file, newbase + ext)
    else:
        return m_System.editFilename(file, newbase)


def process_file(file: str, match_func):
    """执行单个文件/文件夹重命名"""
    fn = get_name_for_match(file)
    newname = match_func(fn)
    if newname:
        nfn = build_new_name(file, newname)
        print("重命名 {} -> {}".format(file, nfn))
        if doRename:
            m_System.moveFD(file, nfn)


def mode1(dir=".", encludeHindden=True, excludeFile=None, excludeStr=None):
    """精确匹配"""
    abd = os.path.abspath(dir)
    for file in m_System.ls(abd, encludeHindden):
        ftype = m_System.fileOrDirectory(file)
        if ftype == 1 and MatchObj == 2: continue
        if ftype == 2 and MatchObj == 1: continue
        if excludeFile and m_System.isInExcludeList(file, excludeFile):
            if verbose: print("排除{}".format(file)); continue
        if excludeStr and m_System.isInExcludeList(file, excludeStr, 2):
            if verbose: print("排除{}".format(file)); continue
        if get_name_for_match(file) == r[0]:
            process_file(file, lambda _: r[1])
    if doRecursive:
        for fr in m_System.ls(abd, encludeHindden):
            if m_System.fileOrDirectory(fr) == 2:
                mode1(fr, encludeHindden, excludeFile, excludeStr)


def mode2(dir=".", encludeHindden=True, excludeFile=None, excludeStr=None):
    """模糊匹配"""
    abd = os.path.abspath(dir)
    for file in m_System.ls(abd, encludeHindden):
        ftype = m_System.fileOrDirectory(file)
        if ftype == 1 and MatchObj == 2: continue
        if ftype == 2 and MatchObj == 1: continue
        if excludeFile and m_System.isInExcludeList(file, excludeFile):
            if verbose: print("排除{}".format(file)); continue
        if excludeStr and m_System.isInExcludeList(file, excludeStr, 2):
            if verbose: print("排除{}".format(file)); continue
        if r[0] in get_name_for_match(file):
            process_file(file, lambda _: r[1])
    if doRecursive:
        for fr in m_System.ls(abd, encludeHindden):
            if m_System.fileOrDirectory(fr) == 2:
                mode2(fr, encludeHindden, excludeFile, excludeStr)


def mode3(dir=".", encludeHindden=True, excludeFile=None, excludeStr=None):
    """替换部分字符"""
    abd = os.path.abspath(dir)
    for file in m_System.ls(abd, encludeHindden):
        ftype = m_System.fileOrDirectory(file)
        if ftype == 1 and MatchObj == 2: continue
        if ftype == 2 and MatchObj == 1: continue
        if excludeFile and m_System.isInExcludeList(file, excludeFile):
            if verbose: print("排除{}".format(file)); continue
        if excludeStr and m_System.isInExcludeList(file, excludeStr, 2):
            if verbose: print("排除{}".format(file)); continue
        fn = get_name_for_match(file)
        if r[0] in fn:
            process_file(file, lambda _: fn.replace(r[0], r[1]))
    if doRecursive:
        for fr in m_System.ls(abd, encludeHindden):
            if m_System.fileOrDirectory(fr) == 2:
                mode3(fr, encludeHindden, excludeFile, excludeStr)


if __name__ == '__main__':
    # 读取规则并保证第三列为整数
    rules = m_System.readFileAsList(rulesFile)
    for r in rules:
        r[2] = int(r[2])
        print("Rule: {} -> {}".format(r[0], r[1]))
        if MatchMode == 0:
            if r[2] == 1: mode1(".", encludeHinddenFile, exclude, exclude_str)
            elif r[2] == 2: mode2(".", encludeHinddenFile, exclude, exclude_str)
            elif r[2] == 3: mode3(".", encludeHinddenFile, exclude, exclude_str)
            else: print("未知模式"); exit(0)
        elif MatchMode == 1:
            mode1(".", encludeHinddenFile, exclude, exclude_str)
        elif MatchMode == 2:
            mode2(".", encludeHinddenFile, exclude, exclude_str)
        elif MatchMode == 3:
            mode3(".", encludeHinddenFile, exclude, exclude_str)

