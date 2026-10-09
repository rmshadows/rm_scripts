#!/bin/bash
# 直接挂载，不再询问。参数在 config.sh。
#   ./rmount.sh --dry-run    只检查并演示红绿结论，不改挂载

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib.sh"

case "${1:-}" in
    --dry-run|-n)
        dry_run_preview mount
        exit $?
        ;;
    "")
        ;;
    *)
        prompt -e "未知参数: $1"
        exit 2
        ;;
esac

if check_mount_point "$readMount"; then
    print_result_banner ok "已经挂载" "$readMount"
    exit 1
fi

mount_veracrypt
exit $?
