#!/usr/bin/python3
import os
import re

# 指定目录
directory = "."
# 要替换成的
REPLACEM="_"

def list_files_and_folders(directory):
    fl = []
    # 列出目录下的所有文件和文件夹
    for item in os.listdir(directory):
        # item_path = os.path.join(directory, item)
        # ./d/2 3
        # fl.append(item_path)
        fl.append(item)
    return fl

def contains_space(path, isFullPath=False):
    if isFullPath:
        # 获取路径的最后一个部分
        last_part = path.split("/")[-1]
    else:
        last_part = path
    # 判断是否包含空格
    if " " in last_part:
        return True
    else:
        return False


def merge_spaces(input_string):
    # 使用正则表达式将连续两个以上的空格替换为一个空格
    output_string = re.sub(r'\s{2,}', ' ', input_string)
    return output_string


def rename_file(old_name, new_name):
    # 使用 os.rename 函数进行重命名
    os.rename(old_name, new_name)
    # print(f"File renamed from '{old_name}' to '{new_name}'")


def rrename(dd):
    # 调用函数
    for i in list_files_and_folders(dd):
        idd = os.path.join(dd, i)
        # 有空格就重命名
        if contains_space(i):
            ofp = idd
            nfp = os.path.join(dd, merge_spaces(i).replace(" ", REPLACEM))
            idd = nfp
            print("【{}】->【{}】".format(ofp, nfp))
            # 重命名
            rename_file(ofp, nfp)
        if os.path.isdir(idd):
            rrename(idd)


if __name__ == "__main__":
    rrename(directory)




