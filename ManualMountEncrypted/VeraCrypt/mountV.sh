#!/bin/bash
# 已挂载则询问卸载；已解密但文件系统未挂载则询问挂载或取消解密；否则询问挂载。
# 参数在 config.sh。
#   ./mountV.sh --dry-run    只检查并演示红绿结论，不改挂载

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib.sh"

case "${1:-}" in
    --dry-run|-n)
        dry_run_preview interactive
        exit $?
        ;;
    "")
        ;;
    -h|--help)
        echo "用法: $(basename "$0") [--dry-run|-n]"
        exit 0
        ;;
    *)
        prompt -e "未知参数: $1"
        echo "用法: $(basename "$0") [--dry-run|-n]"
        exit 2
        ;;
esac

interactive_veracrypt
exit $?
