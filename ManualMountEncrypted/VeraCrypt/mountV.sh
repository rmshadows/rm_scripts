#!/bin/bash
# 已挂载则询问卸载；已解密但文件系统未挂载则询问挂载或取消解密；否则询问挂载。
# 参数在 config.sh。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/lib.sh"

interactive_veracrypt
exit $?
