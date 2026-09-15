#!/bin/bash
## 卸载 fmgr：调用本 Init 内的 fmgr文件传输/
## 需要 sudo
source "../GlobalVariables.sh"
source "../Lib.sh"

SERVER_ROOT="${SERVER_ROOT:-/home/HTML}"
SET_DIR=$(pwd)

resolve_fmgr_template() {
    local cand
    cand="$(cd "$SET_DIR/../../.." && pwd)/fmgr文件传输"
    if [ -f "$cand/NginxSetup/setupNginxForFmgr.sh" ]; then
        echo "$cand"
        return 0
    fi
    return 1
}

FMGR_TEMPLATE="$(resolve_fmgr_template || true)"
if [ -z "$FMGR_TEMPLATE" ]; then
    prompt -e "找不到 Debian_Server_Init/fmgr文件传输/"
    prompt -e "请先：cp -a fmgr文件传输 Debian_Server_Init/"
    exit 1
fi

export FMGR_PARENT="$SERVER_ROOT"
prompt -i "卸载模板：$FMGR_TEMPLATE （FMGR_PARENT=$FMGR_PARENT）"
bash "$FMGR_TEMPLATE/NginxSetup/setupNginxForFmgr.sh" --uninstall

prompt -s "phptinyfilemanager 卸载流程结束。"
cd "$SET_DIR"
