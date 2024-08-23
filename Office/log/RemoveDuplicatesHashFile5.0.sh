#!/bin/bash
# 文件名排序
# 颜色输出
# 多线程，需要 sudo apt-get install parallel

# 如果尚未安装 GNU parallel，自动尝试安装
if ! dpkg -s parallel &>/dev/null; then
  sudo apt-get install parallel
  if [ "$?" -ne 0 ]; then
    echo "安装 parallel 出现错误。"  # 如果安装失败，输出错误信息并退出脚本
    exit 1
  fi
fi

# 设置目标目录
target_dir="1"

# 创建一个临时文件来存储文件的哈希值、文件大小和路径
temp_file=$(mktemp)

# 使用 GNU parallel 并行计算目标目录下每个文件的哈希值和文件大小
find "$target_dir" -type f | parallel -j+0 '
  file={}  # 当前处理的文件路径
  sha256_hash=$(shasum -a 256 "$file" | awk "{print \$1}")  # 计算 SHA-256 哈希值
  md5_hash=$(md5sum "$file" | awk "{print \$1}")  # 计算 MD5 哈希值
  file_size=$(stat -c%s "$file")  # 获取文件大小
  echo -e "$sha256_hash\t$md5_hash\t$file_size\t$file"  # 将结果输出并存储到临时文件中
' >>"$temp_file"

# 查找重复文件（通过检查文件的哈希值）
duplicates=$(awk -F'\t' '
{
  key = $1"\t"$2  # 使用 SHA-256 和 MD5 哈希值作为唯一键
  if (seen[key]++) {
    print $0  # 如果该哈希值已经见过，说明是重复文件，输出此文件信息
  }
}' "$temp_file" | sort -u | sort -t$'\t' -k4,4V)  # 对文件按自然顺序排序

# 为不同哈希值分配不同颜色
declare -A hash_colors  # 创建关联数组存储哈希值与颜色之间的映射
color_index=0  # 颜色索引

# 定义颜色代码数组（红、绿、黄、蓝、紫、青、白）
colors=(31 32 33 34 35 36 37)

# 如果有重复文件，展示并确认是否删除
if [ -n "$duplicates" ]; then
  echo "以下文件被识别为重复文件："

  # 输出重复文件的详细信息，包括哈希值、文件大小和路径，且不同哈希值用不同颜色显示
  while IFS= read -r line; do
    sha256_hash=$(echo "$line" | awk -F'\t' '{print $1}')  # 提取 SHA-256 哈希值
    md5_hash=$(echo "$line" | awk -F'\t' '{print $2}')  # 提取 MD5 哈希值
    file_size=$(echo "$line" | awk -F'\t' '{print $3}')  # 提取文件大小
    file=$(echo "$line" | awk -F'\t' '{print $4}')  # 提取文件路径
    
    # 如果当前哈希值没有分配颜色，则分配一个颜色
    if [ -z "${hash_colors[$sha256_hash]}" ]; then
      hash_colors[$sha256_hash]=$((color_index % ${#colors[@]}))
      color_index=$((color_index + 1))
    fi

    color=${colors[${hash_colors[$sha256_hash]}]}  # 获取当前哈希值对应的颜色代码
    printf "\e[${color}mHash: %s\tSize: %s\tFile: %s\e[0m\n" "$sha256_hash" "$file_size" "$file"
  done <<<"$duplicates"

  # 提示用户是否删除重复文件
  read -p "你确定要删除这些文件吗？(y/n): " confirm
  if [ "$confirm" == "y" ]; then
    # 使用 GNU parallel 并行删除重复文件
    echo "$duplicates" | awk -F'\t' '{print $4}' | parallel -j+0 rm
    echo "重复文件已删除。"
  else
    echo "操作已取消，未删除任何文件。"  # 用户选择不删除文件时的提示
  fi
else
  echo "未找到重复文件。"  # 如果没有找到重复文件的提示
fi

# 删除临时文件以释放资源
rm "$temp_file"

