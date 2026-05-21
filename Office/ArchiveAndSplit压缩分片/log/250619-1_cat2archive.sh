#!/bin/bash
# 运行
# 1_cat2archive.sh
# 固定参数配置
prefix="a"    # 分割文件的前缀(会自动补充_part_)
ext="zip"          # 压缩文件的扩展名（zip 或 tar.xz）

# 确保扩展名正确（zip 或 tar.xz）
if [[ "$ext" != "zip" && "$ext" != "tar.xz" ]]; then
    echo "Error: Unsupported file extension. Only 'zip' and 'tar.xz' are supported."
    exit 1
fi

# 确定合并后的文件名
output_file="${prefix}.${ext}"

# 检查文件是否已经存在，避免覆盖
if [[ -f "$output_file" ]]; then
    echo "Warning: The output file '$output_file' already exists. It will be overwritten."
fi

# 使用 cat 命令合并分割的文件
echo "Merging split files..."
cat ${prefix}_part_* > "$output_file"

# 提示用户合并结果
echo "Merge completed! The file has been saved as '$output_file'."

# 如果是 zip 格式，解压缩测试
if [[ "$ext" == "zip" ]]; then
    echo "Testing zip archive integrity..."
    unzip -t "$output_file"
elif [[ "$ext" == "tar.xz" ]]; then
    echo "Testing tar.xz archive integrity..."
    tar -tvf "$output_file" > /dev/null
fi

echo "File merging and integrity check completed."
