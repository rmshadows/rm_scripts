#!/usr/bin/env bash
# 启用 Linux Magic SysRq
# 默认：永久（/etc/sysctl.d/99-systweak-sysrq.conf + 立即生效）
# 可选：仅临时（只写 /proc/sys/kernel/sysrq，重启失效）
#
# 用法:
#   sudo ./enable-sysrq.sh                 # 永久启用（默认 kernel.sysrq=1）
#   sudo ./enable-sysrq.sh --apply
#   sudo ./enable-sysrq.sh --temp          # 仅临时
#   sudo ./enable-sysrq.sh --temp 176      # 临时并指定掩码
#   sudo ./enable-sysrq.sh --apply 1       # 永久，值为 1
#   sudo ./enable-sysrq.sh --undo
#   sudo ./enable-sysrq.sh --status
#
# 环境变量: KERNEL_SYSRQ=1（默认全开）；常用掩码见 --help
set -euo pipefail

NAME="enable-sysrq"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
SYSCTL_DROPIN="/etc/sysctl.d/99-systweak-sysrq.conf"
PROC_SYSRQ="/proc/sys/kernel/sysrq"
VALUE="${KERNEL_SYSRQ:-1}"

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root/sudo 运行"

valid_value() {
  [[ "$1" =~ ^[0-9]+$ ]] || return 1
  return 0
}

read_proc() {
  tr -d ' \t\r\n' <"$PROC_SYSRQ" 2>/dev/null || echo "?"
}

backup_once() {
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/proc.prev" ]]; then
    read_proc >"$BACKUP_DIR/proc.prev"
    log "已备份当时 /proc 值: $(cat "$BACKUP_DIR/proc.prev")"
  fi
  if [[ -f "$SYSCTL_DROPIN" && ! -f "$BACKUP_DIR/sysctl.dropin.bak" ]]; then
    cp -a "$SYSCTL_DROPIN" "$BACKUP_DIR/sysctl.dropin.bak"
  elif [[ ! -f "$SYSCTL_DROPIN" && ! -f "$BACKUP_DIR/sysctl.dropin.missing" ]]; then
    touch "$BACKUP_DIR/sysctl.dropin.missing"
  fi
  # 也备份其它可能已有的 kernel.sysrq（只记当前生效值，不改其它文件）
  if [[ ! -f "$BACKUP_DIR/sysctl-kernel.sysrq.prev" ]]; then
    sysctl -n kernel.sysrq 2>/dev/null >"$BACKUP_DIR/sysctl-kernel.sysrq.prev" || true
  fi
}

set_temp() {
  local v="$1"
  valid_value "$v" || die "非法 SysRq 值: $v"
  echo "$v" >"$PROC_SYSRQ"
  log "临时启用: $PROC_SYSRQ = $v（重启后失效，除非另有永久配置）"
}

set_permanent() {
  local v="$1"
  valid_value "$v" || die "非法 SysRq 值: $v"
  backup_once
  cat >"$SYSCTL_DROPIN" <<EOF
# managed by systweak enable-sysrq.sh
# 1 = 启用全部 Magic SysRq；0 = 禁用；其它为位掩码
kernel.sysrq = ${v}
EOF
  chmod 644 "$SYSCTL_DROPIN"
  # 立即生效
  sysctl -w "kernel.sysrq=${v}" >/dev/null
  echo "mode=permanent" >"$BACKUP_DIR/state.env"
  echo "value=${v}" >>"$BACKUP_DIR/state.env"
  log "永久启用: $SYSCTL_DROPIN -> kernel.sysrq=${v}（已 sysctl -w）"
}

cmd_status() {
  echo "备份: $BACKUP_DIR"
  echo "/proc 当前: $(read_proc)"
  if [[ -f "$SYSCTL_DROPIN" ]]; then
    echo "永久配置: $SYSCTL_DROPIN"
    grep -v '^#' "$SYSCTL_DROPIN" | grep -v '^$' || true
  else
    echo "永久配置: 无本脚本 drop-in"
  fi
  sysctl kernel.sysrq 2>/dev/null || true
  # 其它来源提示
  if grep -Rsl --include='*.conf' '^\s*kernel\.sysrq' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null | grep -v "$SYSCTL_DROPIN"; then
    warn "系统中还有其它 kernel.sysrq 配置文件（见上），以加载顺序为准"
  fi
}

cmd_undo() {
  [[ -d "$BACKUP_DIR" ]] || die "无备份目录"
  if [[ -f "$BACKUP_DIR/sysctl.dropin.bak" ]]; then
    cp -a "$BACKUP_DIR/sysctl.dropin.bak" "$SYSCTL_DROPIN"
    log "已还原 $SYSCTL_DROPIN"
  elif [[ -f "$BACKUP_DIR/sysctl.dropin.missing" ]]; then
    rm -f "$SYSCTL_DROPIN"
    log "已删除本脚本创建的 $SYSCTL_DROPIN"
  fi
  local prev=""
  if [[ -f "$BACKUP_DIR/proc.prev" ]]; then
    prev="$(tr -d ' \t\r\n' <"$BACKUP_DIR/proc.prev")"
  elif [[ -f "$BACKUP_DIR/sysctl-kernel.sysrq.prev" ]]; then
    prev="$(tr -d ' \t\r\n' <"$BACKUP_DIR/sysctl-kernel.sysrq.prev")"
  fi
  if [[ -n "$prev" && "$prev" != "?" ]]; then
    sysctl -w "kernel.sysrq=${prev}" >/dev/null 2>&1 || echo "$prev" >"$PROC_SYSRQ"
    log "已将运行时值恢复为 $prev"
  else
    # 重新加载 sysctl（按剩余配置）
    sysctl --system >/dev/null 2>&1 || true
    warn "无明确旧值，已尝试 sysctl --system"
  fi
  rm -f "$BACKUP_DIR/state.env"
  cmd_status
}

usage() {
  cat <<EOF
用法: sudo $0 [--apply [值]|--temp [值]|--undo|--status]

  --apply [值]   永久启用（默认值 ${VALUE}，或 KERNEL_SYSRQ）
  --temp  [值]   仅临时写入 /proc（不写 sysctl.d）
  --undo         删除/还原本脚本的永久配置，并恢复当时 /proc 值
  （无参数同 --apply）

常用值:
  0    禁用
  1    启用全部（默认）
  176  较常见的「安全」组合（含 sync/umount/reboot 等，视内核文档）
说明见: Documentation/admin-guide/sysrq.rst
EOF
}

# 解析
MODE="permanent"
case "${1:---apply}" in
  --apply|apply)
    shift || true
    [[ -n "${1:-}" ]] && VALUE="$1"
    ;;
  --temp|temp)
    MODE="temp"
    shift || true
    [[ -n "${1:-}" ]] && VALUE="$1"
    ;;
  --undo|undo)
    cmd_undo
    exit 0
    ;;
  --status|status)
    cmd_status
    exit 0
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  "")
    :
    ;;
  *)
    # 允许: ./enable-sysrq.sh 1
    if valid_value "$1"; then
      VALUE="$1"
    else
      die "未知参数: $1（见 --help）"
    fi
    ;;
esac

if [[ "$MODE" == "temp" ]]; then
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/proc.prev" ]]; then
    read_proc >"$BACKUP_DIR/proc.prev"
  fi
  set_temp "$VALUE"
  echo "mode=temp" >"$BACKUP_DIR/state.env"
else
  set_permanent "$VALUE"
fi
cmd_status
