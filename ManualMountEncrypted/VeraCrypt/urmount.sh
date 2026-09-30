#!/bin/bash
# 直接卸载，不再询问。挂载点在 config.sh 的 readMount。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib.sh"

umount_veracrypt
exit $?
