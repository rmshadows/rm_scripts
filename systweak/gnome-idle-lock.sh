#!/usr/bin/env bash
# GNOME：闲置 60 秒锁屏、lock-delay=0（非交互）
# 用法: ./gnome-idle-lock.sh [--apply|--undo|--status]
set -euo pipefail

NAME="gnome-idle-lock"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

command -v gsettings >/dev/null 2>&1 || die "需要 gsettings（GNOME 会话）"

cmd_status() {
  echo "idle-delay: $(gsettings get org.gnome.desktop.session idle-delay)"
  echo "lock-enabled: $(gsettings get org.gnome.desktop.screensaver lock-enabled)"
  echo "lock-delay: $(gsettings get org.gnome.desktop.screensaver lock-delay)"
  echo "备份: $BACKUP_DIR"
}

cmd_apply() {
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/idle-delay.prev" ]]; then
    gsettings get org.gnome.desktop.session idle-delay >"$BACKUP_DIR/idle-delay.prev"
    gsettings get org.gnome.desktop.screensaver lock-enabled >"$BACKUP_DIR/lock-enabled.prev"
    gsettings get org.gnome.desktop.screensaver lock-delay >"$BACKUP_DIR/lock-delay.prev"
    log "已备份 gsettings -> $BACKUP_DIR/*.prev"
  fi
  gsettings set org.gnome.desktop.session idle-delay 60
  gsettings set org.gnome.desktop.screensaver lock-enabled true
  gsettings set org.gnome.desktop.screensaver lock-delay 0
  log "已应用闲置 60s 锁屏"
  cmd_status
}

cmd_undo() {
  [[ -f "$BACKUP_DIR/idle-delay.prev" ]] || die "无备份，无法还原"
  # shellcheck disable=SC2046
  gsettings set org.gnome.desktop.session idle-delay $(cat "$BACKUP_DIR/idle-delay.prev")
  gsettings set org.gnome.desktop.screensaver lock-enabled $(cat "$BACKUP_DIR/lock-enabled.prev")
  gsettings set org.gnome.desktop.screensaver lock-delay $(cat "$BACKUP_DIR/lock-delay.prev")
  log "已还原 gsettings"
  cmd_status
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help) echo "用法: $0 [--apply|--undo|--status]" ;;
  *) die "未知参数: $1" ;;
esac
