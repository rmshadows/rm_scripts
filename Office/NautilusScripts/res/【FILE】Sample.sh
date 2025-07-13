#!/bin/bash

# ===============================================
# 🌐 通用 Nautilus 脚本模板（单文件工具版）
# 自动部署并执行单脚本工具（如单个 Python、Shell 脚本）
#
# 🛠️ 脚本功能：
#   - 将本地预置的单个工具脚本复制到临时目录
#   - 将用户选中的文件复制到临时目录的 input 文件夹
#   - 执行该单文件工具脚本
#   - 结果输出回用户当前目录
#   - 自动清理临时目录
#
# 📁 默认目录结构示例：
#   └── lib/
#       └── YourTool.py （或 YourTool.sh）
#
# 🧾 示例适用工具：
#   ✅ 单文件图片处理脚本
#   ✅ 单脚本 PDF 拆分或合并
#   ✅ 单文件批量音频处理脚本
# ===============================================

# 初始化 shell 环境（可选）
source ~/.zshrc 2>/dev/null || true

# ===== 基础路径设置 =====
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"           # 当前脚本所在目录
LIB_NAME="YourTool.py"                                 # 工具脚本名（含后缀）
LIB_PATH="$SCRIPT_DIR/../lib/$LIB_NAME"                 # 工具脚本完整路径

TARGET_DIR="$(dirname "$(realpath "$1")")"                            # 选中文件所在目录
TMP_TOOL_DIR="$TARGET_DIR/${LIB_NAME%.*}_RUN"           # 临时目录（脚本名去后缀作为目录名）

# ===== 初始化并复制工具脚本 =====
rm -rf "$TMP_TOOL_DIR"
# mkdir -p "$TMP_TOOL_DIR/input"
cp "$LIB_PATH" "$TMP_TOOL_DIR/"
# 创建临时目录
rm -rf "$TMP_TOOL_DIR"
mkdir -p "$TMP_TOOL_DIR"


# ===== 复制选中文件到临时 input 目录 =====
#for item in "$@"; do
#    cp -r "$item" "$TMP_TOOL_DIR/input/"
#done
# 复制脚本到临时目录
cp "$LIB_PATH" "$TMP_TOOL_DIR/"
cp "${FILES[0]}" "$TMP_TOOL_DIR/"

cd "$TMP_TOOL_DIR" || exit 1
# ===== 执行脚本 =====
xfce4-terminal --working-directory="$TMP_TOOL_DIR" -e "bash -c 'source ~/.zshrc 2>/dev/null || true;bash ./\"$LIB_NAME\" \"${FILES[0]}\"; echo \"按任意键关闭终端...\"; read -r -n 1'"

# ===== 复制输出结果（示例假设生成 PDF） =====
# OUTPUT_NAME="处理结果.pdf"  # 根据实际修改
# cp ./*.pdf "$TARGET_DIR/$OUTPUT_NAME"

notify-send "✅ 处理完成" "结果已保存：$TARGET_DIR/$OUTPUT_NAME"

# ===== 清理 =====
cd ..
rm -rf "$TMP_TOOL_DIR"

