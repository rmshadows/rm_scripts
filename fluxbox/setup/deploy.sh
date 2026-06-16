#!/bin/bash
# 将本仓库 fluxbox 配置部署到 ~/.fluxbox
#
# 用法:
#   ./setup/deploy.sh           # 部署
#   ./setup/deploy.sh --dry-run # 仅预览 rsync

set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=Lib.sh
source "${SCRIPT_DIR}/Lib.sh"
# shellcheck source=Config.sh
source "${SCRIPT_DIR}/Config.sh"

REPO="$(get_repo_root)"
TARGET="$(resolve_target)"

prompt -i "仓库: $REPO"
prompt -i "目标: $TARGET"

if [ "$SET_BACKUP_BEFORE_DEPLOY" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
    backup_target "$TARGET"
fi

mkdir -p "$TARGET"

RSYNC_OPTS=(-av --delete)
RSYNC_EXCLUDE=(
    --exclude 'setup/'
    --exclude 'backup/'
    --exclude 'OtherRes/'
    --exclude 'apt-install.sh'
    --exclude 'README.md'
    --exclude '.git/'
    --exclude 'log'
    --exclude 'log.old'
    --exclude 'backgrounds/'
)

if [ "$DRY_RUN" -eq 1 ]; then
    RSYNC_OPTS+=(-n --verbose)
    prompt -w "DRY RUN（不会实际写入）"
fi

prompt -i "开始 rsync ..."
rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDE[@]}" "${REPO}/" "${TARGET}/"

if [ "$DRY_RUN" -eq 1 ]; then
    exit 0
fi

if [ "$SET_CHMOD_SCRIPTS" -eq 1 ]; then
    chmod_scripts "$TARGET"
    prompt -s "已设置脚本可执行权限"
fi

if [ "$SET_WRITE_SYNC_REPO_PATH" -eq 1 ]; then
    mkdir -p "${TARGET}/config"
    echo "$REPO" > "${TARGET}/config/sync.repo.path"
    prompt -s "已写入 config/sync.repo.path"
fi

if [ "$SET_INIT_DEFAULT_THEME" -eq 1 ] && [ -x "${TARGET}/scripts/style/init-default-style.sh" ]; then
    bash "${TARGET}/scripts/style/init-default-style.sh"
    prompt -s "已初始化 default.theme"
fi

if [ "$SET_DEPLOY_GTKRC" -eq 1 ] && [ -f "${REPO}/OtherRes/gtk-display/.gtkrc-2.0" ]; then
    cp "${REPO}/OtherRes/gtk-display/.gtkrc-2.0" "${HOME}/.gtkrc-2.0"
    prompt -s "已部署 ~/.gtkrc-2.0"
fi

if [ "$SET_INSTALL_APT_DEPS" -eq 1 ] && [ -f "${REPO}/apt-install.sh" ]; then
    prompt -w "安装 apt 依赖（需要 sudo）..."
    bash "${REPO}/apt-install.sh"
fi

prompt -s "部署完成: ${TARGET}"
prompt -i "重载配置: fluxbox-remote reconfigure  或菜单 Restart Fluxbox"
