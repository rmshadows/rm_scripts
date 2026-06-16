#!/usr/bin/env bash
# 4-RESTORE_FILE.sh
#
# 检查 input/ 文件是否为 padding 扩容产物，询问后还原到 output/
#
# 关联文件：
#   restore_file.py        检测 + 交互还原逻辑（本脚本直接调用）
#   file_pad_common.py     解析 FPADv1 元数据 / recovery 块 / 各类型 padding
#   pdf_pad_common.py      识别 1-PDF_EXPAND_SIZE.sh 旧版 PDF padding（仅提示，不可还原）
#   还原对象：3-PAD_FILE.sh 的产物（truncate / dd / disguise 均可还原）
#   说明：PDF 专用检测见 2-CHECK_PDF_PAD.sh
#
# 用法：
#   ./4-RESTORE_FILE.sh              # 逐个询问是否还原
#   ./4-RESTORE_FILE.sh --yes        # 全部自动还原
#   ./4-RESTORE_FILE.sh --check-only # 仅检测不还原

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ========== 配置区域 ==========
INPUT_DIR="input"
OUTPUT_DIR="output"
# ==============================

INPUT_CLI=""
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|--check-only)
            EXTRA_ARGS+=("$1")
            shift
            ;;
        -h|--help)
            sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            INPUT_CLI="$1"
            shift
            ;;
    esac
done

CHECK_DIR="${INPUT_CLI:-$INPUT_DIR}"
mkdir -p "$OUTPUT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
    echo "错误：未找到 python3" >&2
    exit 1
fi

# 仅检测
if [[ " ${EXTRA_ARGS[*]} " == *" --check-only "* ]]; then
    python3 restore_file.py --check-only "$CHECK_DIR"
    exit $?
fi

# 检测 + 交互还原
python3 restore_file.py --restore --output-dir "$OUTPUT_DIR" "${EXTRA_ARGS[@]}" "$CHECK_DIR"
