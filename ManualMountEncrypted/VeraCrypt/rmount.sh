#!/bin/bash
# 直接挂载，不再询问。参数在 config.sh。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib.sh"

if check_mount_point "$readMount"; then
    prompt -w "已经挂载: $readMount"
    exit 1
fi

mount_veracrypt
exit $?
