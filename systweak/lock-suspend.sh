#!/usr/bin/env bash
# 休眠+锁屏：启用或禁用（非交互；替代旧 lock_suspend_manager 菜单）
# 用法:
#   ./lock-suspend.sh --apply          # 启用休眠锁屏
#   ./lock-suspend.sh --disable        # 禁用（也会先备份）
#   ./lock-suspend.sh --undo           # 还原到首次备份
#   ./lock-suspend.sh --status
set -euo pipefail

NAME="lock-suspend"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

snapshot() {
  mkdir -p "$BACKUP_DIR"
  [[ -f "$BACKUP_DIR/snapshot.done" ]] && return 0
  {
    if command -v gsettings >/dev/null 2>&1; then
      echo "lock_enabled=$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null || true)"
      echo "idle_delay=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null || true)"
      echo "sleep_ac=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || true)"
      echo "sleep_bat=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 2>/dev/null || true)"
    fi
  } >"$BACKUP_DIR/gsettings.env"
  if [[ -f /etc/systemd/logind.conf ]]; then
    sudo cp -a /etc/systemd/logind.conf "$BACKUP_DIR/logind.conf.bak"
  fi
  if [[ -f /etc/lightdm/lightdm.conf ]]; then
    sudo cp -a /etc/lightdm/lightdm.conf "$BACKUP_DIR/lightdm.conf.bak"
  fi
  touch "$BACKUP_DIR/snapshot.done"
  log "已快照到 $BACKUP_DIR"
}

cmd_status() {
  echo "备份: $BACKUP_DIR"
  command -v gsettings >/dev/null || { echo "无 gsettings"; return 0; }
  echo "lock-enabled: $(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null || true)"
  echo "idle-delay: $(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null || true)"
  echo "sleep-ac: $(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || true)"
  for t in suspend.target sleep.target hibernate.target; do
    echo -n "$t: "; systemctl is-enabled "$t" 2>/dev/null || echo "?"
  done
}

cmd_apply() {
  snapshot
  command -v gsettings >/dev/null 2>&1 || die "需要 gsettings"
  gsettings set org.gnome.desktop.screensaver lock-enabled true
  gsettings set org.gnome.desktop.session idle-delay 300
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
  sudo systemctl unmask suspend.target sleep.target hibernate.target 2>/dev/null || true

  sudo mkdir -p /etc/lightdm
  if [[ -f /etc/lightdm/lightdm.conf ]] && ! grep -q "gnome-screensaver-command -l" /etc/lightdm/lightdm.conf 2>/dev/null; then
    echo -e "[Seat:*]\nsession-setup-script=/usr/bin/gnome-screensaver-command -l" | sudo tee -a /etc/lightdm/lightdm.conf >/dev/null
  fi

  if [[ -f /etc/systemd/logind.conf ]]; then
    sudo sed -i '/HandleLidSwitch/d;/HandleLidSwitchDocked/d' /etc/systemd/logind.conf
    echo "HandleLidSwitch=suspend" | sudo tee -a /etc/systemd/logind.conf >/dev/null
    echo "HandleLidSwitchDocked=suspend" | sudo tee -a /etc/systemd/logind.conf >/dev/null
    sudo systemctl restart systemd-logind || true
  fi
  log "已启用休眠锁屏相关配置"
  cmd_status
}

cmd_disable() {
  snapshot
  command -v gsettings >/dev/null 2>&1 || die "需要 gsettings"
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
  sudo systemctl mask suspend.target sleep.target hibernate.target
  if [[ -f /etc/systemd/logind.conf ]]; then
    sudo sed -i '/HandleLidSwitch/d;/HandleLidSwitchDocked/d' /etc/systemd/logind.conf
    echo "HandleLidSwitch=ignore" | sudo tee -a /etc/systemd/logind.conf >/dev/null
    echo "HandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf >/dev/null
    sudo systemctl restart systemd-logind || true
  fi
  log "已禁用休眠锁屏"
  cmd_status
}

cmd_undo() {
  [[ -f "$BACKUP_DIR/snapshot.done" ]] || die "无快照，无法 --undo"
  if [[ -f "$BACKUP_DIR/gsettings.env" ]] && command -v gsettings >/dev/null; then
    # shellcheck disable=SC1090
    source "$BACKUP_DIR/gsettings.env"
    [[ -n "${lock_enabled:-}" ]] && gsettings set org.gnome.desktop.screensaver lock-enabled "${lock_enabled}"
    [[ -n "${idle_delay:-}" ]] && gsettings set org.gnome.desktop.session idle-delay "${idle_delay}"
    [[ -n "${sleep_ac:-}" ]] && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "${sleep_ac//\'/}"
    [[ -n "${sleep_bat:-}" ]] && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "${sleep_bat//\'/}"
  fi
  if [[ -f "$BACKUP_DIR/logind.conf.bak" ]]; then
    sudo cp -a "$BACKUP_DIR/logind.conf.bak" /etc/systemd/logind.conf
    sudo systemctl restart systemd-logind || true
  fi
  if [[ -f "$BACKUP_DIR/lightdm.conf.bak" ]]; then
    sudo cp -a "$BACKUP_DIR/lightdm.conf.bak" /etc/lightdm/lightdm.conf
  fi
  sudo systemctl unmask suspend.target sleep.target hibernate.target 2>/dev/null || true
  log "已按快照还原（systemd mask 状态若曾被其它脚本改过请再检查）"
  cmd_status
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --disable|disable) cmd_disable ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help)
    echo "用法: $0 [--apply|--disable|--undo|--status]"
    ;;
  *) die "未知参数: $1" ;;
esac
