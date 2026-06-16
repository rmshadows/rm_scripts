#!/usr/bin/env bash
#
# 批量将 .doc 和 .wps 转换为 .docx，并把原文件移动到 doc_src 文件夹
# 依赖：LibreOffice (soffice)
#
# 用法：
#   ./convert2docx.sh          # 只处理当前目录
#   ./convert2docx.sh -r       # 递归处理子目录

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
  FILES=$(find . -type f \( -iname "*.doc" -o -iname "*.wps" \))
else
  FILES=$(find . -maxdepth 1 -type f \( -iname "*.doc" -o -iname "*.wps" \))
fi

# 如果没有文件，直接退出
if [ -z "$FILES" ]; then
  echo "⚠️ 没有找到 .doc 或 .wps 文件"
  exit 0
fi

# 创建 doc_src 文件夹（在当前目录）
DEST="./doc_src"
mkdir -p "$DEST"

# 转换并移动
for f in $FILES; do
  echo "正在转换: $f"
  soffice --headless --convert-to docx:"MS Word 2007 XML" "$f" --outdir "$(dirname "$f")"
  
  echo "移动原文件到 $DEST"
  mv "$f" "$DEST/"
done

echo "✅ 转换完成，原文件已移动到 doc_src 文件夹"

