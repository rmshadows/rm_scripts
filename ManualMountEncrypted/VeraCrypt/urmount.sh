#!/bin/bash
# 直接卸载，不再询问。挂载点在 config.sh 的 readMount。
#   ./urmount.sh --dry-run    只检查并演示红绿结论，不改挂载

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib.sh"

case "${1:-}" in
    --dry-run|-n)
        dry_run_preview umount
        exit $?
        ;;
    "")
        ;;
    *)
        prompt -e "未知参数: $1"
        exit 2
        ;;
esac

umount_veracrypt
exit $?
