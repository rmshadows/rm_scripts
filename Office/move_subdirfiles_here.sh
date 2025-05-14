#!/bin/bash

# 函数：递归拷贝文件
copy_files_recursive() {
    # 遍历所有子文件夹并拷贝文件
    for dir in */; do
        if [ -d "$dir" ]; then
            echo "正在处理目录: $dir"
            # 拷贝目录中的所有文件到当前目录，不包括目录本身
            find "$dir" -type f -exec mv {} ./ \;
            # 如果选择递归，继续处理子目录
            if [ "$1" -eq 1 ]; then
                copy_files_recursive 1
            fi
        fi
    done
}

# 函数：拷贝当前目录下一级文件夹中的文件
copy_files_non_recursive() {
    # 只拷贝当前目录下的文件夹中的文件
    for dir in */; do
        if [ -d "$dir" ]; then
            echo "正在处理目录: $dir"
            # 拷贝目录中的所有文件到当前目录，不包括目录本身
            find "$dir" -type f -exec mv {} ./ \;
        fi
    done
}

# 提示用户选择是否递归
echo "是否递归拷贝（2级及更多子目录）？"
echo "1: 是"
echo "2: 否"
read -p "请输入选择 (1/2): " choice

# 判断用户的选择并执行相应的函数
if [ "$choice" -eq 1 ]; then
    copy_files_recursive 1
elif [ "$choice" -eq 2 ]; then
    copy_files_non_recursive
else
    echo "无效的选择，请选择 1 或 2."
    exit 1
fi

