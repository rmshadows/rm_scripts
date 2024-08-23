#!/bin/bash

# 单线程

# 目标目录
target_dir="1"

# 创建一个临时文件来存储哈希值和文件路径
temp_file=$(mktemp)

# 遍历目标目录中的所有文件，计算SHA-256和MD5哈希值，并存储在临时文件中
for file in "$target_dir"/*; do
  if [ -f "$file" ]; then
    sha256_hash=$(shasum -a 256 "$file" | awk '{print $1}')
    md5_hash=$(md5sum "$file" | awk '{print $1}')
    # 使用TAB作为分隔符，避免空格带来的解析问题
    echo -e "$sha256_hash\t$md5_hash\t$file" >> "$temp_file"
  fi
done

# 查找重复文件
duplicates=$(awk -F'\t' '
{
  key = $1"\t"$2
  if (seen[key]++) {
    print $3
  }
}' "$temp_file")

# 如果有重复文件，展示并确认是否删除
if [ -n "$duplicates" ]; then
  echo "以下文件被识别为重复文件："
  echo "$duplicates"
  
  read -p "你确定要删除这些文件吗？(y/n): " confirm
  if [ "$confirm" == "y" ]; then
    echo "$duplicates" | xargs -d '\n' rm
    echo "重复文件已删除。"
  else
    echo "操作已取消，未删除任何文件。"
  fi
else
  echo "未找到重复文件。"
fi

# 删除临时文件
rm "$temp_file"
