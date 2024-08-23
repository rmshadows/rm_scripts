#!/bin/bash

# nautilus删除所选文件夹下面的空文件夹

# 处理每个选中的目录
for dir in "$@"; do
    # 确保是一个目录
    if [ -d "$dir" ]; then
        # 递归删除该目录及其子目录中的空文件夹
        find "$dir" -type d -empty -delete
    fi
done

# 显示完成通知
notify-send "空文件夹删除完成" "已删除选定目录中的所有空文件夹。"

