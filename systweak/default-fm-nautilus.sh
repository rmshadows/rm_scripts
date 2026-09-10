#!/usr/bin/env bash
# 默认文件管理器设为 Nautilus（非交互）
# 通用查看/修改默认应用见 default-apps.sh
# 用法: ./default-fm-nautilus.sh [--apply|--undo|--status]
# 环境变量: TARGET_FM=org.gnome.Nautilus.desktop
set -euo pipefail

NAME="default-fm-nautilus"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
TARGET_FM="${TARGET_FM:-org.gnome.Nautilus.desktop}"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

command -v xdg-mime >/dev/null 2>&1 || die "需要 xdg-mime"

cmd_status() {
  echo "当前 inode/directory: $(xdg-mime query default inode/directory 2>/dev/null || echo n/a)"
  echo "目标: $TARGET_FM"
  echo "备份: $BACKUP_DIR"
}

cmd_apply() {
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/prev.env" ]]; then
    echo "prev=$(xdg-mime query default inode/directory 2>/dev/null || true)" >"$BACKUP_DIR/prev.env"
    log "已备份原默认 FM"
  fi
  xdg-mime default "$TARGET_FM" inode/directory
  log "已设置为 $TARGET_FM"
  cmd_status
}

cmd_undo() {
  [[ -f "$BACKUP_DIR/prev.env" ]] || die "无备份"
  # shellcheck disable=SC1090
  source "$BACKUP_DIR/prev.env"
  [[ -n "${prev:-}" ]] || die "备份中无 prev"
  xdg-mime default "$prev" inode/directory
  log "已还原为 $prev"
  cmd_status
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help) echo "用法: $0 [--apply|--undo|--status]" ;;
  *) die "未知参数: $1" ;;
esac
