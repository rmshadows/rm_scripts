#!/bin/bash

# 多线程，需要 sudo apt-get install parallel
# 安装 parallel，如果尚未安装
if ! dpkg -s parallel &>/dev/null; then
  sudo apt-get install parallel
  if [ "$?" -ne 0 ]; then
    echo "安装 parallel 出现错误。"
    exit 1
  fi
fi

# 目标目录
target_dir="11"

# 创建一个临时文件来存储哈希值、文件大小和文件路径
temp_file=$(mktemp)

# 使用GNU parallel来并行计算文件的哈希值和文件大小
find "$target_dir" -type f | parallel -j+0 '
  file={}
  sha256_hash=$(shasum -a 256 "$file" | awk "{print \$1}")
  md5_hash=$(md5sum "$file" | awk "{print \$1}")
  file_size=$(stat -c%s "$file")
  echo -e "$sha256_hash\t$md5_hash\t$file_size\t$file"
' >>"$temp_file"

# 查找重复文件
duplicates=$(awk -F'\t' '
{
  key = $1"\t"$2
  if (seen[key]++) {
    print $0
  }
}' "$temp_file" | sort -u)

# 为不同哈希值分配不同颜色
declare -A hash_colors
color_index=0

# 定义颜色代码
colors=(31 32 33 34 35 36 37)  # 红色、绿色、黄色、蓝色、紫色、青色、白色

# 如果有重复文件，展示并确认是否删除
if [ -n "$duplicates" ]; then
  echo "以下文件被识别为重复文件："

  # 使用printf来正确显示带有特殊字符的文件名，并展示文件哈希和文件大小
  while IFS= read -r line; do
    sha256_hash=$(echo "$line" | awk -F'\t' '{print $1}')
    md5_hash=$(echo "$line" | awk -F'\t' '{print $2}')
    file_size=$(echo "$line" | awk -F'\t' '{print $3}')
    file=$(echo "$line" | awk -F'\t' '{print $4}')
    
    # 分配颜色
    if [ -z "${hash_colors[$sha256_hash]}" ]; then
      hash_colors[$sha256_hash]=$((color_index % ${#colors[@]}))
      color_index=$((color_index + 1))
    fi

    color=${colors[${hash_colors[$sha256_hash]}]}
    printf "\e[${color}mHash: %s\tSize: %s\tFile: %s\e[0m\n" "$sha256_hash" "$file_size" "$file"
  done <<<"$duplicates" | sort -V

  read -p "你确定要删除这些文件吗？(y/n): " confirm
  if [ "$confirm" == "y" ]; then
    # 使用GNU parallel来并行删除文件
    echo "$duplicates" | awk -F'\t' '{print $4}' | parallel -j+0 rm
    echo "重复文件已删除。"
  else
    echo "操作已取消，未删除任何文件。"
  fi
else
  echo "未找到重复文件。"
fi

# 删除临时文件
rm "$temp_file"
