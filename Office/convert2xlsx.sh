#!/usr/bin/env bash
#
# 批量将 .xls 和 .et 转换为 .xlsx，并把原文件移动到 xls_src 文件夹
# 依赖：LibreOffice (soffice)
#
# 用法：
#   ./convert2xlsx.sh          # 只处理当前目录
#   ./convert2xlsx.sh -r       # 递归处理子目录

set -e

RECURSIVE=false

# 解析参数
while getopts "r" opt; do
  case $opt in
    r) RECURSIVE=true ;;
    *) echo "用法: $0 [-r]" >&2; exit 1 ;;
  esac
done

# 查找文件
if [ "$RECURSIVE" = true ]; then
  FILES=$(find . -type f \( -iname "*.xls" -o -iname "*.et" \))
else
  FILES=$(find . -maxdepth 1 -type f \( -iname "*.xls" -o -iname "*.et" \))
fi

# 如果没有文件，直接退出
if [ -z "$FILES" ]; then
  echo "⚠️ 没有找到 .xls 或 .et 文件"
  exit 0
fi

# 创建存放原始文件的文件夹
DEST="./xls_src"
mkdir -p "$DEST"

# 转换并移动
for f in $FILES; do
  echo "正在转换: $f"
  soffice --headless --convert-to xlsx:"Calc MS Excel 2007 XML" "$f" --outdir "$(dirname "$f")"
  
  echo "移动原文件到 $DEST"
  mv "$f" "$DEST/"
done

echo "✅ 转换完成，原文件已移动到 xls_src 文件夹"
