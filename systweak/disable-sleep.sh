#!/usr/bin/env bash
# 禁止系统休眠/挂起（systemd mask + GNOME/XFCE 电源项）
# 用法: ./disable-sleep.sh [--apply|--undo|--status]
# 注意: gsettings/xfconf 针对当前用户；mask 需要 sudo
set -euo pipefail

NAME="disable-sleep"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
TARGETS=(sleep.target suspend.target hibernate.target hybrid-sleep.target)

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

save_gsettings() {
  command -v gsettings >/dev/null 2>&1 || return 0
  {
    echo "sleep_ac=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || true)"
    echo "sleep_bat=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 2>/dev/null || true)"
    echo "lock_enabled=$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null || true)"
  } >"$BACKUP_DIR/gsettings.env"
}

restore_gsettings() {
  [[ -f "$BACKUP_DIR/gsettings.env" ]] || return 0
  command -v gsettings >/dev/null 2>&1 || return 0
  # shellcheck disable=SC1090
  source "$BACKUP_DIR/gsettings.env"
  [[ -n "${sleep_ac:-}" ]] && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "${sleep_ac//\'/}"
  [[ -n "${sleep_bat:-}" ]] && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "${sleep_bat//\'/}"
  [[ -n "${lock_enabled:-}" ]] && gsettings set org.gnome.desktop.screensaver lock-enabled "${lock_enabled}"
  log "已还原 GNOME gsettings"
}

cmd_status() {
  echo "备份目录: $BACKUP_DIR"
  for t in "${TARGETS[@]}"; do
    echo -n "$t: "
    systemctl is-enabled "$t" 2>/dev/null || echo "masked/unknown"
  done
  if command -v gsettings >/dev/null 2>&1; then
    echo "GNOME sleep-ac: $(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || echo n/a)"
    echo "GNOME lock: $(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null || echo n/a)"
  fi
}

cmd_apply() {
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/gsettings.env" ]]; then
    save_gsettings
  fi
  # 记录 mask 前是否已 mask
  if [[ ! -f "$BACKUP_DIR/systemd.env" ]]; then
    : >"$BACKUP_DIR/systemd.env"
    for t in "${TARGETS[@]}"; do
      if systemctl is-enabled "$t" 2>/dev/null | grep -q masked; then
        echo "${t}=was_masked" >>"$BACKUP_DIR/systemd.env"
      else
        echo "${t}=was_active" >>"$BACKUP_DIR/systemd.env"
      fi
    done
  fi

  sudo systemctl mask "${TARGETS[@]}"
  sudo systemctl stop "${TARGETS[@]}" 2>/dev/null || true

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    log "已配置 GNOME"
  fi
  if command -v xfconf-query >/dev/null 2>&1; then
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-on-ac -s 0 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-on-battery -s 0 2>/dev/null || true
    log "已配置 XFCE 电源项"
  fi
  log "休眠/挂起已禁止（可能需重新登录）"
  cmd_status
}

cmd_undo() {
  [[ -d "$BACKUP_DIR" ]] || die "无备份: $BACKUP_DIR"
  if [[ -f "$BACKUP_DIR/systemd.env" ]]; then
    while IFS='=' read -r t state; do
      [[ -z "$t" ]] && continue
      if [[ "$state" == "was_active" ]]; then
        sudo systemctl unmask "$t" 2>/dev/null || true
      fi
    done <"$BACKUP_DIR/systemd.env"
  else
    sudo systemctl unmask "${TARGETS[@]}" 2>/dev/null || true
  fi
  restore_gsettings
  log "已尽量还原；XFCE 项未逐条备份，请手动检查"
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help) echo "用法: $0 [--apply|--undo|--status]" ;;
  *) die "未知参数: $1" ;;
esac
