#!/bin/bash

# 默认文件名
default_file="1.zip"

# 使用传入参数或默认值
input_file="${1:-$default_file}"

# 分割大小与前缀
split_size="200M"
prefix="${input_file}_part_"

# 检查文件存在性
if [[ ! -f "$input_file" ]]; then
    echo "❌ Error: File '$input_file' not found!"
    exit 1
fi

# 执行 split 分割（两位数字编号）
echo "📦 Splitting '$input_file' into $split_size chunks..."
# 2表示01 3表示001
split -d -a 2 -b "$split_size" "$input_file" "$prefix"
echo "✅ Splitting done."

# 获取所有分段文件（按顺序）
parts=$(ls ${prefix}* | sort)

# 构建 Windows CMD 合并命令
bat_merge_cmd="copy /b "
for part in $parts; do
    bat_merge_cmd+="$part + "
done
bat_merge_cmd="${bat_merge_cmd::-3} $input_file"

# 构建 Linux/macOS 合并命令
sh_merge_cmd="cat"
for part in $parts; do
    sh_merge_cmd+=" $part"
done
sh_merge_cmd+=" > $input_file"

# --- 输出到终端，供复制 ---
echo ""
echo "📋 Copy-paste these commands to rejoin the file:"
echo ""
echo "🪟 Windows CMD:"
echo "$bat_merge_cmd"
echo ""
echo "🐧 Linux/macOS:"
echo "$sh_merge_cmd"
echo ""

# --- 生成 merge_parts.sh ---
echo "#!/bin/bash" > merge_parts.sh
echo "$sh_merge_cmd" >> merge_parts.sh
chmod +x merge_parts.sh
echo "✅ Generated: merge_parts.sh"

# 1. 使用 UTF-8 with BOM 编码保存文件Windows CMD 支持 UTF-8，但必须是带 BOM（Byte Order Mark） 的 UTF-8 文件；
# 否则中文（或非 ASCII）内容会乱码或无法显示；可在脚本中使用如下写法添加 BOM：utf8_bom=$'\xEF\xBB\xBF'
# printf "%s\n%s" "$utf8_bom" "$bat_content" > merge_parts.bat
# 2. 文件开头添加 chcp 65001 切换为 UTF-8 编码页 Windows CMD 默认不是 UTF-8，而是 chcp 936（GBK）；
#    所以必须加上这一行：chcp 65001
# 3. 行尾换行符格式需为 Windows 样式（CRLF）【可选】.bat 文件中的换行符应为 CRLF (\r\n) 而非 Linux 默认的 LF (\n);
#    虽然现代 Windows 能处理 LF，但老版本或部分编辑器会出问题；    使用 unix2dos 工具可转换（可选）：unix2dos merge_parts.bat

# --- 生成 merge_parts.bat（UTF-8 with BOM + chcp 65001） ---
bat_filename="merge_parts.bat"
utf8_bom=$'\xEF\xBB\xBF'

bat_content="@echo off
chcp 65001
echo 合并文件中...
$bat_merge_cmd
echo 完成。"

# 写入 .bat 文件（带 BOM，避免中文乱码）
printf "%s\n%s" "$utf8_bom" "$bat_content" > "$bat_filename"
unix2dos "$bat_filename"
echo "✅ Generated: merge_parts.bat (UTF-8 with BOM, 中文兼容)"


