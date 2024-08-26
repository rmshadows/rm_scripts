#!/bin/bash

# 指定目录，默认为当前目录
directory="."
# 要替换的符号
REPLACEM="_"

# 递归遍历目录
function rrename() {
    local dir="$1"
    
    # 列出目录下的所有文件和文件夹
    for item in "$dir"/*; do
        # 检查是否存在空格
        if [[ "$item" =~ [[:space:]] ]]; then
            local new_item="${item// /$REPLACEM}"
            echo "【$item】->【$new_item】"
            mv "$item" "$new_item"
            item="$new_item"  # 更新item的值以便正确处理子目录
        fi
        
        # 如果是目录，递归处理
        if [ -d "$item" ]; then
            rrename "$item"
        fi
    done
}

# 调用函数
rrename "$directory"

