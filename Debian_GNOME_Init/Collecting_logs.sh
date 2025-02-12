#!/bin/bash

# 获取当前时间，格式为年月日时分秒
timestamp=$(date +"%Y%m%d%H%M%S")

# 创建一个以当前时间为名字的文件夹
mkdir "$timestamp"

# 查找当前目录下所有目录中的 setup.log 文件并复制到新创建的文件夹中
find . -type f -name "setup.log" | while read -r file; do
    # 获取上级文件夹的名字
    parent_dir=$(basename "$(dirname "$file")")

    # 创建新的文件名，格式为 上级文件夹名称-setup.log
    new_filename="$timestamp/$parent_dir-setup.log"

    # 复制并重命名文件
    cp "$file" "$new_filename"
    echo "已复制: $file -> $new_filename"
done

echo "所有 setup.log 文件已复制到 $timestamp 文件夹"

