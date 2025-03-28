#!/bin/bash
# 未测试，修正图片格式
# 遍历当前目录的所有图片文件
for file in *; do
    # 确保是文件
    [ -f "$file" ] || continue  

    # 使用 `file` 命令获取文件格式
    mimetype=$(file --mime-type -b "$file")

    # 根据 MIME 类型判断正确的扩展名
    case "$mimetype" in
        image/jpeg)  correct_ext="jpg" ;;
        image/png)   correct_ext="png" ;;
        image/gif)   correct_ext="gif" ;;
        image/webp)  correct_ext="webp" ;;
        image/bmp)   correct_ext="bmp" ;;
        image/tiff)  correct_ext="tiff" ;;
        image/x-icon) correct_ext="ico" ;;
        image/svg+xml) correct_ext="svg" ;;
        *) 
            echo "跳过：$file（未知类型 $mimetype）"
            continue
            ;;
    esac

    # 获取当前文件的扩展名（不区分大小写）
    current_ext="${file##*.}"
    current_ext_lower=$(echo "$current_ext" | tr 'A-Z' 'a-z')

    # 如果扩展名不匹配，则修改
    if [[ "$current_ext_lower" != "$correct_ext" ]]; then
        new_name="${file%.*}.$correct_ext"
        echo "重命名: $file -> $new_name"
        mv "$file" "$new_name"
    fi
done

echo "图片扩展名修正完成。"
