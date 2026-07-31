#!/usr/bin/env bash
# 为指定用户启用/撤销 sudo 免密（写入 /etc/sudoers.d/，拷走即可用）
# 用法: sudo ./sudo-nopasswd.sh [--apply|--undo|--status]
# 环境变量: TARGET_USER=用户名（默认 SUDO_USER 或 logname）
set -euo pipefail

NAME="sudo-nopasswd"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  TARGET_USER="${TARGET_USER:-$SUDO_USER}"
else
  TARGET_USER="${TARGET_USER:-$(logname 2>/dev/null || echo "$USER")}"
fi
SUDOERS_FILE="/etc/sudoers.d/nopasswd_${TARGET_USER}"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root/sudo 运行"
id -u "$TARGET_USER" >/dev/null 2>&1 || die "用户不存在: $TARGET_USER"

cmd_status() {
  if [[ -f "$SUDOERS_FILE" ]]; then
    echo "已启用免密: $SUDOERS_FILE"
    cat "$SUDOERS_FILE"
  else
    echo "未启用免密（无 $SUDOERS_FILE）"
  fi
}

cmd_apply() {
  mkdir -p "$BACKUP_DIR"
  if [[ -f "$SUDOERS_FILE" ]]; then
    log "已存在 $SUDOERS_FILE，跳过写入"
  else
    echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" >"$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo "created=1" >"$BACKUP_DIR/state.env"
    log "已写入 $SUDOERS_FILE"
  fi
  cmd_status
}

cmd_undo() {
  if [[ -f "$SUDOERS_FILE" ]]; then
    rm -f "$SUDOERS_FILE"
    log "已删除 $SUDOERS_FILE"
  else
    log "无需还原（文件本就不存在）"
  fi
  rm -f "$BACKUP_DIR/state.env" 2>/dev/null || true
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help) echo "用法: $0 [--apply|--undo|--status]"; echo "TARGET_USER=$TARGET_USER" ;;
  *) die "未知参数: $1" ;;
esac
