#!/usr/bin/env bash
# 2-CHECK_PDF_PAD.sh
#
# 检查 input/ 下 PDF 是否含有体积扩大 padding
#
# 关联文件：
#   check_pdf_padding.py   检测逻辑（本脚本直接调用）
#   pdf_pad_common.py      识别 PDF padding 标记（pad/embed/legacy）
#   检测对象：1-PDF_EXPAND_SIZE.sh 的产物；3-PAD_FILE.sh 的 PDF disguise 产物
#   说明：仅检查、不还原；还原见 4-RESTORE_FILE.sh
#
# 用法：
#   ./2-CHECK_PDF_PAD.sh              # 检查配置目录（默认 input/）
#   ./2-CHECK_PDF_PAD.sh output       # 检查指定目录
#   ./2-CHECK_PDF_PAD.sh --quiet-clean input   # 只显示有 padding 的文件
#
# 退出码：0 = 全部无 padding；1 = 至少一个文件有 padding

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ========== 配置区域 ==========
CHECK_DIR="input"
# ==============================

CHECK_DIR_CLI=""
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        --quiet-clean)
            EXTRA_ARGS+=("$1")
            shift
            ;;
        --*)
            EXTRA_ARGS+=("$1")
            shift
            ;;
        *)
            CHECK_DIR_CLI="$1"
            shift
            ;;
    esac
done

[[ -n "$CHECK_DIR_CLI" ]] && CHECK_DIR="$CHECK_DIR_CLI"

if ! command -v python3 >/dev/null 2>&1; then
    echo "错误：未找到 python3" >&2
    exit 1
fi

python3 check_pdf_padding.py "${EXTRA_ARGS[@]}" "$CHECK_DIR"
