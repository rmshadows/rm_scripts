#!/bin/bash

# 目标目录
target_dir="."

# 递归删除空文件夹
find "$target_dir" -type d -empty -delete

echo "空文件夹删除完成。"

