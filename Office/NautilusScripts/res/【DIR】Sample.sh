#!/bin/bash

# ===============================================
# 🌐 通用 Nautilus 脚本模板
# 自动部署并执行自定义工具（支持任意类型，如 PDF、图像、音频、打印等）
#
# 🛠️ 脚本功能：
#   - 将本地预置的工具目录复制到目标目录（支持多文件工具）
#   - 将用户选中的文件/文件夹批量复制到工具输入目录
#   - 自动检测并执行工具主程序（Python、Shell、可执行文件等）
#   - 结果输出回用户当前目录（支持多种文件类型）
#   - 自动清理临时目录
#
# 📁 默认工具目录结构示例：
#   └── lib/
#       └── YourTool/
#           ├── main.py / run.sh / tool_exec (可执行文件)
#           └── input/ 或 images/ （输入目录）
#
# ===============================================

# ---- 配置区（根据实际工具修改） ----
LIB_NAME="YourTool"                  # 工具目录名（lib/下）
MAIN_ENTRY="main.py"                 # 工具主程序文件名
INPUT_DIR_NAME="input"               # 工具输入目录名（必须和工具目录结构匹配）
OUTPUT_EXTENSIONS=("pdf" "txt")      # 期望输出文件后缀（支持多个）
OUTPUT_PREFIX="result"               # 输出文件名前缀（用于区分，拷贝时重命名）
# --------------------------------------

# shell 环境初始化（可选）
source ~/.zshrc 2>/dev/null || true

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LIB_DIR="$SCRIPT_DIR/../lib/$LIB_NAME"
if [ ! -d "$LIB_DIR" ]; then
  echo "❌ 找不到工具目录：$LIB_DIR"
  exit 1
fi

# 拿到用户选中第一个文件/目录的路径，用来确定工作目录
TARGET_DIR="$(dirname "$1")"
TMP_TOOL_DIR="$TARGET_DIR/${LIB_NAME}_RUN_$(date +%s)"

echo "📂 目标目录: $TARGET_DIR"
echo "🛠️ 创建临时工具目录: $TMP_TOOL_DIR"

rm -rf "$TMP_TOOL_DIR"
mkdir -p "$TMP_TOOL_DIR"

# 复制整个工具目录
cp -r "$LIB_DIR"/* "$TMP_TOOL_DIR/"

# 创建工具输入目录（确保存在）
mkdir -p "$TMP_TOOL_DIR/$INPUT_DIR_NAME"

# 拷贝所有选中内容到工具输入目录
echo "📥 复制输入文件..."
for item in "$@"; do
  if [ -e "$item" ]; then
    cp -r "$item" "$TMP_TOOL_DIR/$INPUT_DIR_NAME/"
  else
    echo "⚠️ 输入项不存在，跳过: $item"
  fi
done

cd "$TMP_TOOL_DIR"

echo "⚙️  执行工具主程序: $MAIN_ENTRY"
if [ ! -f "$MAIN_ENTRY" ]; then
  echo "❌ 主程序文件不存在：$MAIN_ENTRY"
  exit 1
fi

# 根据主程序文件类型执行
case "$MAIN_ENTRY" in
  *.py)
    python3 "$MAIN_ENTRY"
    ;;
  *.sh)
    bash "$MAIN_ENTRY"
    ;;
  *)
    if [ -x "$MAIN_ENTRY" ]; then
      ./"$MAIN_ENTRY"
    else
      echo "❌ 无法执行主程序：$MAIN_ENTRY 既不是 Python、Shell 脚本，也不是可执行文件"
      exit 1
    fi
    ;;
esac

# 查找输出文件，支持多后缀，复制到目标目录并重命名防冲突
echo "📤 复制输出文件到目标目录..."
for ext in "${OUTPUT_EXTENSIONS[@]}"; do
  matches=(*."$ext")
  if [ "${#matches[@]}" -gt 0 ] && [ -e "${matches[0]}" ]; then
    for file in "${matches[@]}"; do
      basefile="$(basename "$file")"
      destfile="${OUTPUT_PREFIX}_${basefile}"
      cp "$file" "$TARGET_DIR/$destfile"
      echo "✅ 已复制: $file -> $TARGET_DIR/$destfile"
    done
  fi
done

# 通知（需要 notify-send 支持）
if command -v notify-send >/dev/null 2>&1; then
  notify-send "✅ $LIB_NAME 运行完成" "结果文件已保存到 $TARGET_DIR"
fi

# 清理
cd ..
rm -rf "$TMP_TOOL_DIR"
echo "🧹 已清理临时目录"

exit 0

