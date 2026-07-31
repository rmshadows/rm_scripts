#!/usr/bin/env bash
# 设置 LightDM GTK greeter 背景图（非交互）
# 用法:
#   sudo ./lightdm-gtk-background.sh --apply /path/to/image.jpg
#   sudo ./lightdm-gtk-background.sh --undo
#   sudo ./lightdm-gtk-background.sh --status
set -euo pipefail

NAME="lightdm-gtk-background"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
CONF="/etc/lightdm/lightdm-gtk-greeter.conf"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root/sudo 运行"

cmd_status() {
  echo "配置: $CONF"
  if [[ -f "$CONF" ]]; then
    grep -E '^background=' "$CONF" || echo "background=（未设置）"
  else
    echo "配置文件不存在"
  fi
  echo "备份: $BACKUP_DIR"
}

cmd_apply() {
  local img="${1:-}"
  [[ -n "$img" ]] || die "请提供图片路径: $0 --apply /path/to.png"
  [[ -f "$img" ]] || die "文件不存在: $img"
  mkdir -p "$BACKUP_DIR" "$(dirname "$CONF")"
  if [[ -f "$CONF" && ! -f "$BACKUP_DIR/greeter.conf.bak" ]]; then
    cp -a "$CONF" "$BACKUP_DIR/greeter.conf.bak"
    log "已备份 $CONF"
  elif [[ ! -f "$CONF" && ! -f "$BACKUP_DIR/greeter.missing" ]]; then
    touch "$BACKUP_DIR/greeter.missing"
  fi
  if [[ ! -f "$CONF" ]]; then
    printf '[greeter]\nbackground=%s\n' "$img" >"$CONF"
  elif grep -q '^background=' "$CONF"; then
    sed -i "s|^background=.*|background=${img}|" "$CONF"
  else
    if grep -q '^\[greeter\]' "$CONF"; then
      sed -i "/^\[greeter\]/a background=${img}" "$CONF"
    else
      printf '\n[greeter]\nbackground=%s\n' "$img" >>"$CONF"
    fi
  fi
  log "已设置 background=$img"
  cmd_status
}

cmd_undo() {
  if [[ -f "$BACKUP_DIR/greeter.conf.bak" ]]; then
    cp -a "$BACKUP_DIR/greeter.conf.bak" "$CONF"
    log "已还原 $CONF"
  elif [[ -f "$BACKUP_DIR/greeter.missing" ]]; then
    rm -f "$CONF"
    log "原先无配置文件，已删除"
  else
    die "无备份"
  fi
  cmd_status
}

case "${1:---status}" in
  --apply|apply)
    shift || true
    cmd_apply "${1:-}"
    ;;
  --undo|undo) cmd_undo ;;
  --status|status|"") cmd_status ;;
  -h|--help)
    echo "用法: sudo $0 --apply /path/to/image"
    echo "      sudo $0 --undo | --status"
    ;;
  *)
    # 兼容: 直接传图片路径视为 apply
    if [[ -f "${1:-}" ]]; then
      cmd_apply "$1"
    else
      die "未知参数: $1（见 --help）"
    fi
    ;;
esac
