#!/bin/bash
# Fluxbox 部署辅助函数

CDEF=" \033[0m"
CGSC=" \033[0;32m"
CRER=" \033[0;31m"
CWAR=" \033[0;33m"
CCIN=" \033[0;36m"

prompt() {
    case ${1} in
        -s) echo -e "${CGSC}${@/-s/}${CDEF}" ;;
        -e) echo -e "${CRER}${@/-e/}${CDEF}" ;;
        -w) echo -e "${CWAR}${@/-w/}${CDEF}" ;;
        -i) echo -e "${CCIN}${@/-i/}${CDEF}" ;;
        *)  echo -e "$@" ;;
    esac
}

get_repo_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

resolve_target() {
    local t="${SET_TARGET_DIR:-${HOME}/.fluxbox}"
    eval echo "$t"
}

backup_target() {
    local target="$1"
    if [ ! -d "$target" ] || [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
        prompt -w "跳过备份：目标目录不存在或为空 ($target)"
        return 0
    fi
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    local bak="${target}.backup.${stamp}"
    prompt -i "备份现有配置 -> $bak"
    cp -a "$target" "$bak"
    prompt -s "备份完成"
}

chmod_scripts() {
    local target="$1"
    find "$target/scripts" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
    find "$target/configs" -type f -name 'start.sh' -exec chmod +x {} + 2>/dev/null || true
}
