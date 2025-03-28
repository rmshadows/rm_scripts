#!/bin/bash
# 未测试，转化图片格式
# ========== 用户可修改的参数 ==========
input_folder="/path/to/images"  # 修改此处为你的图片文件夹路径
output_format="jpg"             # 目标格式: "jpg" 或 "png"
output_folder="${input_folder}/converted_${output_format}"  # 输出文件夹
# ====================================

# 确保目标格式正确
if [[ "$output_format" != "jpg" && "$output_format" != "png" ]]; then
    echo "错误: 仅支持 jpg 或 png 作为目标格式"
    exit 1
fi

# 创建存放转换后图片的目录
mkdir -p "$output_folder"

# 遍历文件夹中的所有图片
for file in "$input_folder"/*; do
    # 确保是文件
    [ -f "$file" ] || continue

    # 获取文件名（去掉扩展名）
    filename=$(basename "$file")
    filename_no_ext="${filename%.*}"

    # 输出文件路径
    output_file="${output_folder}/${filename_no_ext}.${output_format}"

    # 转换图片格式
    convert "$file" "$output_file"

    # 打印转换信息
    echo "转换: $file -> $output_file"
done

echo "所有图片已转换为 $output_format 格式，存放于 $output_folder 目录。"
