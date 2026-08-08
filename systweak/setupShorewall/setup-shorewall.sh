#!/usr/bin/env bash
# 一键部署 Shorewall（配置来自 Debian_GNOME_Init/8/SW_CONF）
# 默认：安装软件包 + 写入配置 + shorewall check；**不**自动 start/enable（防锁死）
# 可选：--start 检查通过后启动并开机自启
#
# 拷贝方式（二选一或都带）：
#   1) 本脚本 + 同目录 shorewall/SW_CONF/ 目录
#   2) 本脚本 + 同目录 shorewall/SW_CONF.tar.gz（或 ./SW_CONF.tar.gz）
#
# 用法:
#   sudo ./setup-shorewall.sh
#   sudo ./setup-shorewall.sh --start
#   sudo ./setup-shorewall.sh --undo
#   sudo ./setup-shorewall.sh --status
#   sudo ./setup-shorewall.sh --check
set -euo pipefail

NAME="setup-shorewall"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ETC_SW="/etc/shorewall"
DO_START=0

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root/sudo 运行"

find_bundle() {
  # 返回可用的配置源：目录路径，或解压后的目录
  local candidates=(
    "${SYSTWEAK_SHOREWALL_CONF:-}"
    "$SCRIPT_DIR/shorewall/SW_CONF"
    "$SCRIPT_DIR/SW_CONF"
  )
  local c
  for c in "${candidates[@]}"; do
    [[ -n "$c" && -d "$c" && -f "$c/shorewall.conf" ]] && { echo "$c"; return 0; }
  done

  local tars=(
    "$SCRIPT_DIR/shorewall/SW_CONF.tar.gz"
    "$SCRIPT_DIR/SW_CONF.tar.gz"
    "$SCRIPT_DIR/shorewall-SW_CONF.tar.gz"
  )
  local t extract
  for t in "${tars[@]}"; do
    [[ -f "$t" ]] || continue
    extract="$(mktemp -d /tmp/systweak-sw-XXXXXX)"
    tar -xzf "$t" -C "$extract"
    if [[ -f "$extract/SW_CONF/shorewall.conf" ]]; then
      echo "$extract/SW_CONF"
      echo "$extract" >"$BACKUP_DIR/.extract_tmpdir"
      return 0
    fi
    if [[ -f "$extract/shorewall.conf" ]]; then
      echo "$extract"
      echo "$extract" >"$BACKUP_DIR/.extract_tmpdir"
      return 0
    fi
    rm -rf "$extract"
  done
  return 1
}

cleanup_extract() {
  if [[ -f "$BACKUP_DIR/.extract_tmpdir" ]]; then
    rm -rf "$(cat "$BACKUP_DIR/.extract_tmpdir")"
    rm -f "$BACKUP_DIR/.extract_tmpdir"
  fi
}

backup_etc() {
  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BACKUP_DIR/etc-shorewall.tar.gz" ]]; then
    if [[ -d "$ETC_SW" ]]; then
      tar -czf "$BACKUP_DIR/etc-shorewall.tar.gz" -C / etc/shorewall
      log "已备份 /etc/shorewall -> $BACKUP_DIR/etc-shorewall.tar.gz"
    else
      touch "$BACKUP_DIR/etc-shorewall.missing"
      log "原先无 $ETC_SW"
    fi
  else
    log "已有 /etc/shorewall 备份，跳过覆盖"
  fi
  if systemctl is-enabled shorewall >/dev/null 2>&1; then
    echo "enabled" >"$BACKUP_DIR/service.enabled.prev"
  else
    echo "disabled" >"$BACKUP_DIR/service.enabled.prev"
  fi
}

cmd_status() {
  echo "备份: $BACKUP_DIR"
  command -v shorewall >/dev/null && echo "shorewall: $(command -v shorewall)" || echo "shorewall: 未安装"
  if [[ -d "$ETC_SW" ]]; then
    echo "配置目录: $ETC_SW"
    [[ -f "$ETC_SW/shorewall.conf" ]] && grep -E '^STARTUP_ENABLED=' "$ETC_SW/shorewall.conf" || true
  else
    echo "配置目录: 无"
  fi
  systemctl is-enabled shorewall 2>/dev/null || echo "service: not enabled / absent"
  systemctl is-active shorewall 2>/dev/null || echo "service: inactive / absent"
}

cmd_check() {
  command -v shorewall >/dev/null || die "未安装 shorewall"
  shorewall check
}

cmd_apply() {
  mkdir -p "$BACKUP_DIR"
  local src
  src="$(find_bundle)" || die "找不到 SW_CONF。请把 shorewall/SW_CONF 或 SW_CONF.tar.gz 放在脚本旁（见 --help）"
  log "使用配置源: $src"

  if ! command -v shorewall >/dev/null 2>&1; then
    log "安装 shorewall..."
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y shorewall
    echo "installed=1" >"$BACKUP_DIR/pkgs.env"
  fi

  backup_etc
  mkdir -p "$ETC_SW"
  # 清空后拷入（不依赖 rsync）
  find "$ETC_SW" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  cp -a "$src"/. "$ETC_SW"/
  mkdir -p "$ETC_SW/log"
  # setup_rules.sh 可执行
  [[ -f "$ETC_SW/setup_rules.sh" ]] && chmod +x "$ETC_SW/setup_rules.sh"

  log "运行 shorewall check..."
  if ! shorewall check; then
    cleanup_extract
    die "shorewall check 失败。配置已写入但未启动。可 --undo 还原。"
  fi
  log "check 通过。"

  if [[ "$DO_START" -eq 1 ]]; then
    warn "即将 start + enable shorewall（错误规则可能导致断网，请确认本机可操作）"
    shorewall start
    systemctl enable shorewall
    log "已 start 并 enable"
  else
    warn "为安全起见未自动启动。确认 interfaces/rules 后执行："
    warn "  sudo shorewall start && sudo systemctl enable shorewall"
    warn "或重新运行: sudo $0 --start"
    warn "切换规则集可用: sudo $ETC_SW/setup_rules.sh"
  fi

  cleanup_extract
  echo "applied=$(date -Iseconds)" >"$BACKUP_DIR/state.env"
  cmd_status
}

cmd_undo() {
  [[ -d "$BACKUP_DIR" ]] || die "无备份目录"
  if systemctl is-active shorewall >/dev/null 2>&1; then
    shorewall stop || true
  fi
  if [[ -f "$BACKUP_DIR/service.enabled.prev" ]]; then
    if [[ "$(cat "$BACKUP_DIR/service.enabled.prev")" != "enabled" ]]; then
      systemctl disable shorewall 2>/dev/null || true
    fi
  else
    systemctl disable shorewall 2>/dev/null || true
  fi

  if [[ -f "$BACKUP_DIR/etc-shorewall.tar.gz" ]]; then
    rm -rf "$ETC_SW"
    tar -xzf "$BACKUP_DIR/etc-shorewall.tar.gz" -C /
    log "已还原 /etc/shorewall"
  elif [[ -f "$BACKUP_DIR/etc-shorewall.missing" ]]; then
    rm -rf "$ETC_SW"
    log "原先无配置目录，已删除 $ETC_SW"
  else
    die "无 /etc/shorewall 备份"
  fi
  [[ -f "$BACKUP_DIR/pkgs.env" ]] && warn "shorewall 软件包未卸载"
  cmd_status
}

usage() {
  cat <<EOF
用法: sudo $0 [--apply|--start|--check|--undo|--status]

  --apply   安装(按需)+部署 SW_CONF + check（默认，不启动）
  --start   同 apply，且 check 通过后 start+enable
  --check   仅 shorewall check
  --undo    停止服务并还原 /etc/shorewall

配置查找顺序:
  \$SYSTWEAK_SHOREWALL_CONF
  $SCRIPT_DIR/shorewall/SW_CONF/
  $SCRIPT_DIR/SW_CONF/
  $SCRIPT_DIR/shorewall/SW_CONF.tar.gz
  $SCRIPT_DIR/SW_CONF.tar.gz

建议拷贝到目标机:
  setup-shorewall.sh
  shorewall/SW_CONF.tar.gz   # 约数 KB，来自 GNOME Init（已去掉 examples）
EOF
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --start|start)
    DO_START=1
    cmd_apply
    ;;
  --check|check) cmd_check ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help|help) usage ;;
  *) die "未知参数: $1（见 --help）" ;;
esac
