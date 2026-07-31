#!/usr/bin/env bash
# 将 LightDM 的 greeter 设为 lightdm-gtk-greeter（可顺带设为默认显示管理器）
# 用法:
#   sudo ./lightdm-gtk-greeter.sh              # 安装(按需)并设置 greeter
#   sudo ./lightdm-gtk-greeter.sh --no-dm      # 只改 greeter，不改默认 DM
#   sudo ./lightdm-gtk-greeter.sh --undo
#   sudo ./lightdm-gtk-greeter.sh --status
set -euo pipefail

NAME="lightdm-gtk-greeter"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
DEFAULT_DM="/etc/X11/default-display-manager"
GREETER="lightdm-gtk-greeter"
SET_DEFAULT_DM=1

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root/sudo 运行"

ensure_pkgs() {
  local need=()
  dpkg -s lightdm >/dev/null 2>&1 || need+=(lightdm)
  dpkg -s lightdm-gtk-greeter >/dev/null 2>&1 || need+=(lightdm-gtk-greeter)
  if [[ ${#need[@]} -gt 0 ]]; then
    log "安装: ${need[*]}"
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${need[@]}"
    echo "installed_pkgs=${need[*]}" >>"$BACKUP_DIR/pkgs.env"
  fi
}

backup_once() {
  mkdir -p "$BACKUP_DIR"
  if [[ -f "$LIGHTDM_CONF" && ! -f "$BACKUP_DIR/lightdm.conf.bak" ]]; then
    cp -a "$LIGHTDM_CONF" "$BACKUP_DIR/lightdm.conf.bak"
    log "已备份 $LIGHTDM_CONF"
  elif [[ ! -f "$LIGHTDM_CONF" && ! -f "$BACKUP_DIR/lightdm.missing" ]]; then
    touch "$BACKUP_DIR/lightdm.missing"
  fi
  if [[ -f "$DEFAULT_DM" && ! -f "$BACKUP_DIR/default-display-manager.bak" ]]; then
    cp -a "$DEFAULT_DM" "$BACKUP_DIR/default-display-manager.bak"
    log "已备份 $DEFAULT_DM"
  fi
}

set_greeter_in_conf() {
  mkdir -p "$(dirname "$LIGHTDM_CONF")"
  if [[ ! -f "$LIGHTDM_CONF" ]]; then
    cat >"$LIGHTDM_CONF" <<EOF
[Seat:*]
greeter-session=${GREETER}
EOF
    log "已新建 $LIGHTDM_CONF"
    return
  fi

  # 统一写成 greeter-session=lightdm-gtk-greeter（兼容旧 [SeatDefaults]）
  if grep -qE '^[[:space:]]*greeter-session=' "$LIGHTDM_CONF"; then
    sed -i -E "s|^[[:space:]]*greeter-session=.*|greeter-session=${GREETER}|" "$LIGHTDM_CONF"
  else
    if grep -qE '^\[Seat' "$LIGHTDM_CONF"; then
      # 插到第一个 [Seat...] 段落后
      awk -v g="greeter-session=${GREETER}" '
        BEGIN{done=0}
        /^\[Seat/ && !done {print; print g; done=1; next}
        {print}
        END{if(!done){print "[Seat:*]"; print g}}
      ' "$LIGHTDM_CONF" >"${LIGHTDM_CONF}.tmp"
      mv "${LIGHTDM_CONF}.tmp" "$LIGHTDM_CONF"
    else
      printf '\n[Seat:*]\ngreeter-session=%s\n' "$GREETER" >>"$LIGHTDM_CONF"
    fi
  fi
  log "已设置 greeter-session=${GREETER}"
}

set_default_lightdm() {
  [[ "$SET_DEFAULT_DM" -eq 1 ]] || { log "跳过默认显示管理器（--no-dm）"; return; }
  local cur=""
  [[ -f "$DEFAULT_DM" ]] && cur="$(tr -d ' \t\r\n' <"$DEFAULT_DM" || true)"
  if [[ "$cur" == "/usr/sbin/lightdm" ]]; then
    log "默认显示管理器已是 lightdm"
    return
  fi
  echo /usr/sbin/lightdm >"$DEFAULT_DM"
  # 非交互 reconfigure（部分系统需要）
  echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections 2>/dev/null || true
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure lightdm 2>/dev/null || true
  log "已将默认显示管理器设为 lightdm（需重启/重登生效）"
}

cmd_status() {
  echo "备份: $BACKUP_DIR"
  if [[ -f "$LIGHTDM_CONF" ]]; then
    echo "--- $LIGHTDM_CONF ---"
    grep -E '^\[Seat|^[[:space:]]*greeter-session=' "$LIGHTDM_CONF" || echo "(无 greeter-session 行)"
  else
    echo "$LIGHTDM_CONF: 不存在"
  fi
  if [[ -f "$DEFAULT_DM" ]]; then
    echo "default-display-manager: $(cat "$DEFAULT_DM")"
  else
    echo "default-display-manager: 无"
  fi
  dpkg -s lightdm >/dev/null 2>&1 && echo "包 lightdm: 已安装" || echo "包 lightdm: 未安装"
  dpkg -s lightdm-gtk-greeter >/dev/null 2>&1 && echo "包 lightdm-gtk-greeter: 已安装" || echo "包 lightdm-gtk-greeter: 未安装"
}

cmd_apply() {
  mkdir -p "$BACKUP_DIR"
  backup_once
  ensure_pkgs
  set_greeter_in_conf
  set_default_lightdm
  cmd_status
  warn "改显示管理器后建议重启；仅改 greeter 可重登或 systemctl restart lightdm（会踢掉图形会话）"
}

cmd_undo() {
  [[ -d "$BACKUP_DIR" ]] || die "无备份: $BACKUP_DIR"
  if [[ -f "$BACKUP_DIR/lightdm.conf.bak" ]]; then
    cp -a "$BACKUP_DIR/lightdm.conf.bak" "$LIGHTDM_CONF"
    log "已还原 $LIGHTDM_CONF"
  elif [[ -f "$BACKUP_DIR/lightdm.missing" ]]; then
    rm -f "$LIGHTDM_CONF"
    log "原先无 conf，已删除"
  else
    warn "无 lightdm.conf 备份"
  fi
  if [[ -f "$BACKUP_DIR/default-display-manager.bak" ]]; then
    cp -a "$BACKUP_DIR/default-display-manager.bak" "$DEFAULT_DM"
    log "已还原 $DEFAULT_DM"
    local olddm
    olddm="$(tr -d ' \t\r\n' <"$DEFAULT_DM")"
    if [[ -n "$olddm" && -x "$olddm" ]]; then
      local name
      name="$(basename "$olddm")"
      echo "${name} shared/default-x-display-manager select ${name}" | debconf-set-selections 2>/dev/null || true
      DEBIAN_FRONTEND=noninteractive dpkg-reconfigure "$name" 2>/dev/null || true
    fi
  fi
  [[ -f "$BACKUP_DIR/pkgs.env" ]] && warn "本脚本安装过的包未自动卸载（见 $BACKUP_DIR/pkgs.env）"
  cmd_status
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --no-dm)
    SET_DEFAULT_DM=0
    cmd_apply
    ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help)
    cat <<EOF
用法: sudo $0 [--apply|--no-dm|--undo|--status]
  --apply   安装(按需)、设 greeter=lightdm-gtk-greeter、并设默认 DM 为 lightdm
  --no-dm   同上但不改默认显示管理器
EOF
    ;;
  *) die "未知参数: $1" ;;
esac
