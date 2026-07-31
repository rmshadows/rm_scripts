#!/usr/bin/env bash
# systweak 单功能脚本模板 —— 复制本文件后改 NAME / apply / undo / status
# 用法: ./_template.sh [--apply|--undo|--status|--help]
set -euo pipefail

NAME="template-demo"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

log()  { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[x] $*" >&2; exit 1; }

ensure_backup_dir() {
  mkdir -p "$BACKUP_DIR"
}

# 备份普通文件（存在才拷）
backup_file() {
  local src="$1"
  local dest="$BACKUP_DIR/$(basename "$src").bak"
  ensure_backup_dir
  if [[ -f "$src" && ! -f "$dest" ]]; then
    cp -a "$src" "$dest"
    log "已备份: $src -> $dest"
  elif [[ -f "$dest" ]]; then
    log "已有备份，跳过: $dest"
  fi
}

cmd_status() {
  echo "备份目录: $BACKUP_DIR"
  echo "（在此描述当前是否已应用）"
}

cmd_apply() {
  ensure_backup_dir
  # 1) 先 backup_file / 记录原值到 $BACKUP_DIR/state.env
  # 2) 再修改系统
  log "demo apply（模板未改系统）"
  echo "applied=$(date -Iseconds)" >"$BACKUP_DIR/state.env"
}

cmd_undo() {
  [[ -d "$BACKUP_DIR" ]] || die "无备份目录，无法还原: $BACKUP_DIR"
  # 从 $BACKUP_DIR 恢复文件 / state.env 中的原值
  log "demo undo"
  rm -f "$BACKUP_DIR/state.env"
}

usage() {
  cat <<EOF
用法: $(basename "$0") [--apply|--undo|--status|--help]

  --apply   备份后应用（默认）
  --undo    按 $BACKUP_DIR 还原
  --status  查看状态
EOF
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help|help) usage ;;
  *) die "未知参数: $1（见 --help）" ;;
esac
