#!/bin/bash

# 函数：递归拷贝文件（所有子目录）
copy_files_recursive() {
    echo ">>> 正在递归拷贝所有子目录中的文件到当前目录..."
    find . -mindepth 2 -type f -exec mv -v {} ./ \;
}

# 函数：非递归拷贝文件（仅一级子目录）
copy_files_non_recursive() {
    echo ">>> 正在非递归拷贝一级子目录中的文件到当前目录..."
    for dir in */; do
        [ -d "$dir" ] || continue
        find "$dir" -mindepth 1 -maxdepth 1 -type f -exec mv -v {} ./ \;
    done
}

# 函数：递归拷贝目录（保留结构）
copy_dirs_recursive() {
    echo ">>> 正在递归移动所有子目录到当前目录..."
    find . -mindepth 1 -type d -exec mv -v {} ./ \;
}

# 函数：非递归拷贝目录（仅一级目录）
copy_dirs_non_recursive() {
    echo ">>> 正在非递归移动各一级目录中的子目录..."
    for parent in */; do
        [ -d "$parent" ] || continue
        # 查找该目录中的一级子目录，不递归
        find "$parent" -mindepth 1 -maxdepth 1 -type d -exec mv -v {} ./ \;
    done
}


# 用户选择功能
echo "请选择功能："
echo "1: 拷贝文件"
echo "2: 拷贝目录"
read -p "请输入选择 (1/2): " mode

# 用户选择是否递归
echo "是否递归处理（多级子目录）？"
echo "1: 是"
echo "2: 否（仅一级子目录）"
read -p "请输入选择 (1/2): " depth

# 执行对应操作
if [ "$mode" -eq 1 ]; then
    # 拷贝文件
    if [ "$depth" -eq 1 ]; then
        copy_files_recursive
    elif [ "$depth" -eq 2 ]; then
        copy_files_non_recursive
    else
        echo "无效的选择（递归选项），退出"
        exit 1
    fi
elif [ "$mode" -eq 2 ]; then
    # 拷贝目录
    if [ "$depth" -eq 1 ]; then
        copy_dirs_recursive
    elif [ "$depth" -eq 2 ]; then
        copy_dirs_non_recursive
    else
        echo "无效的选择（递归选项），退出"
        exit 1
    fi
else
    echo "无效的功能选择，退出"
    exit 1
fi

