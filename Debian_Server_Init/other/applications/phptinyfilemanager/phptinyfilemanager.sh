#!/bin/bash
## 交互式部署 fmgr
## 资源：本 Init 内的 fmgr文件传输/（打包前从仓库根模板复制进来）
# https://github.com/prasathmani/tinyfilemanager
source "../GlobalVariables.sh"
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 部署到的父目录（本体 → $SERVER_ROOT/fmgr）
SERVER_ROOT="${SERVER_ROOT:-/home/HTML}"

SET_DIR=$(pwd)

# 打包形态：Debian_Server_Init/fmgr文件传输/
# （phptinyfilemanager → applications → other → Debian_Server_Init）
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
    prompt -e "打包/使用前请从仓库根复制：cp -a fmgr文件传输 Debian_Server_Init/"
    exit 1
fi
prompt -i "模板：$FMGR_TEMPLATE"

export FMGR_PARENT="$SERVER_ROOT"
# 交互：让用户选 snippet / standalone
bash "$FMGR_TEMPLATE/NginxSetup/setupNginxForFmgr.sh"

prompt -i "部署结束请按脚本【必查】清单核对；弱口令见 $FMGR_TEMPLATE/README.md"
cd "$SET_DIR"
