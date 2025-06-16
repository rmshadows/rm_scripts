#!/bin/bash

# 中文名：《子目录文件或目录移动工具（支持递归）》

# 函数：递归拷贝文件（所有子目录）
copy_files_recursive() {
    echo ">>> 正在递归移动所有子目录中的文件到当前目录..."
    find . -mindepth 2 -type f -exec mv -v {} ./ \;
}

# 函数：非递归拷贝文件（仅一级子目录）
copy_files_non_recursive() {
    echo ">>> 正在非递归移动一级子目录中的文件到当前目录..."
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
        find "$parent" -mindepth 1 -maxdepth 1 -type d -exec mv -v {} ./ \;
    done
}

echo
echo "================== 子目录文件或目录移动工具 =================="
echo
echo "说明："
echo "本工具可将当前目录下的子目录中的【文件】或【目录】移动到当前目录中。"
echo "你可以选择是否递归（处理多级子目录），或仅处理一级子目录。"
echo "默认：若直接回车不输入，将执行【移动文件 且 递归】的操作。"
echo

# 用户选择功能
read -p "请选择操作对象类型（1: 文件，2: 目录）[默认 1]: " mode
mode=${mode:-1}

# 用户选择是否递归
read -p "是否递归处理子目录（1: 是，2: 否）[默认 1]: " depth
depth=${depth:-1}

echo

# 执行对应操作
if [ "$mode" = "1" ]; then
    if [ "$depth" = "1" ]; then
        copy_files_recursive
    elif [ "$depth" = "2" ]; then
        copy_files_non_recursive
    else
        echo "⚠️ 无效的递归选项（$depth），请仅输入 1 或 2。"
        exit 1
    fi
elif [ "$mode" = "2" ]; then
    if [ "$depth" = "1" ]; then
        copy_dirs_recursive
    elif [ "$depth" = "2" ]; then
        copy_dirs_non_recursive
    else
        echo "⚠️ 无效的递归选项（$depth），请仅输入 1 或 2。"
        exit 1
    fi
else
    echo "⚠️ 无效的功能选择（$mode），请仅输入 1 或 2。"
    exit 1
fi

