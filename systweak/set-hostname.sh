#!/usr/bin/env bash
# 修改系统主机名（hostname）；--undo 还原
# 用法:
#   sudo ./set-hostname.sh --apply 新主机名
#   sudo ./set-hostname.sh 新主机名          # 同上
#   sudo ./set-hostname.sh --undo
#   sudo ./set-hostname.sh --status
set -euo pipefail

NAME="set-hostname"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root/sudo 运行"

valid_hostname() {
  local h="$1"
  # 大致符合 hostname 规则：字母数字与连字符，1–63，不以连字符开头/结尾
  [[ "$h" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] || return 1
  return 0
}

current_hostname() {
  if command -v hostnamectl >/dev/null 2>&1; then
    hostnamectl --static 2>/dev/null || hostname -s 2>/dev/null || cat /etc/hostname 2>/dev/null
  else
    cat /etc/hostname 2>/dev/null || hostname -s
  fi
}

backup_once() {
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/hostname.prev" ]]; then
    current_hostname | tr -d '\r\n' >"$BACKUP_DIR/hostname.prev"
    log "已记录原主机名: $(cat "$BACKUP_DIR/hostname.prev")"
  fi
  if [[ -f /etc/hostname && ! -f "$BACKUP_DIR/etc-hostname.bak" ]]; then
    cp -a /etc/hostname "$BACKUP_DIR/etc-hostname.bak"
  fi
  if [[ -f /etc/hosts && ! -f "$BACKUP_DIR/etc-hosts.bak" ]]; then
    cp -a /etc/hosts "$BACKUP_DIR/etc-hosts.bak"
  fi
}

# 更新 /etc/hosts 中 127.0.1.1（Debian 常见）对应的名字
update_hosts() {
  local new="$1" old="$2"
  [[ -f /etc/hosts ]] || return 0
  if grep -qE '^[[:space:]]*127\.0\.1\.1[[:space:]]' /etc/hosts; then
    sed -i -E "s|^([[:space:]]*127\.0\.1\.1[[:space:]]+).*|\1${new}|" /etc/hosts
  else
    echo "127.0.1.1	${new}" >>/etc/hosts
  fi
  # 若旧名单独出现在其它 127.0.0.1 行，尽量替换（保守：只动含旧名的行）
  if [[ -n "$old" && "$old" != "$new" ]]; then
    sed -i -E "s/([[:space:]])${old}([[:space:]]|$)/\1${new}\2/g" /etc/hosts || true
  fi
}

apply_hostname() {
  local new="$1" old
  valid_hostname "$new" || die "非法主机名: $new（仅字母数字与连字符，勿以下划线/点开头）"
  backup_once
  old="$(cat "$BACKUP_DIR/hostname.prev")"
  if [[ "$old" == "$new" ]]; then
    log "主机名已是 $new，无需修改"
    cmd_status
    return
  fi

  if command -v hostnamectl >/dev/null 2>&1; then
    hostnamectl set-hostname "$new"
  else
    echo "$new" >/etc/hostname
    hostname "$new" 2>/dev/null || true
  fi
  update_hosts "$new" "$old"
  log "主机名: $old -> $new（部分程序需重新登录/重启才完全生效）"
  cmd_status
}

cmd_status() {
  echo "备份: $BACKUP_DIR"
  echo "当前: $(current_hostname)"
  [[ -f /etc/hostname ]] && echo "/etc/hostname: $(tr -d '\r\n' </etc/hostname)"
  if [[ -f "$BACKUP_DIR/hostname.prev" ]]; then
    echo "备份中的原名: $(cat "$BACKUP_DIR/hostname.prev")"
  fi
  grep -E '^[[:space:]]*127\.0\.1\.1[[:space:]]' /etc/hosts 2>/dev/null || true
}

cmd_undo() {
  [[ -f "$BACKUP_DIR/hostname.prev" ]] || die "无备份主机名，无法 --undo"
  local old
  old="$(tr -d '\r\n' <"$BACKUP_DIR/hostname.prev")"
  [[ -n "$old" ]] || die "备份为空"

  if [[ -f "$BACKUP_DIR/etc-hostname.bak" ]]; then
    cp -a "$BACKUP_DIR/etc-hostname.bak" /etc/hostname
  else
    echo "$old" >/etc/hostname
  fi
  if [[ -f "$BACKUP_DIR/etc-hosts.bak" ]]; then
    cp -a "$BACKUP_DIR/etc-hosts.bak" /etc/hosts
  fi
  if command -v hostnamectl >/dev/null 2>&1; then
    hostnamectl set-hostname "$old"
  else
    hostname "$old" 2>/dev/null || true
  fi
  log "已还原主机名为 $old"
  cmd_status
}

case "${1:---status}" in
  --apply|apply)
    shift || true
    [[ -n "${1:-}" ]] || die "请提供新主机名: $0 --apply myhost"
    apply_hostname "$1"
    ;;
  --undo|undo) cmd_undo ;;
  --status|status|"") cmd_status ;;
  -h|--help)
    cat <<EOF
用法: sudo $0 --apply <新主机名>
      sudo $0 <新主机名>
      sudo $0 --undo | --status
EOF
    ;;
  *)
    # 直接传主机名
    if valid_hostname "$1"; then
      apply_hostname "$1"
    else
      die "未知参数或非法主机名: $1（见 --help）"
    fi
    ;;
esac
