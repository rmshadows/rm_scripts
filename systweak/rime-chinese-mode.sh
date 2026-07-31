#!/usr/bin/env bash
# 当前会话：切换到 Rime 并尽量设为中文模式（即时操作，无持久备份）
# 用法: ./rime-chinese-mode.sh [--apply|--status|--help]
# 环境变量: FCITX_IM_NAME=rime
set -euo pipefail

IM_NAME="${FCITX_IM_NAME:-rime}"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

_rime_set_chinese() {
  local bus="$1"
  if command -v busctl >/dev/null 2>&1; then
    busctl --user call "$bus" /rime org.fcitx.Fcitx.Rime1 SetAsciiMode b false 2>/dev/null && return 0
  fi
  if command -v dbus-send >/dev/null 2>&1; then
    dbus-send --session --dest="$bus" /rime org.fcitx.Fcitx.Rime1.SetAsciiMode boolean:false >/dev/null 2>&1 && return 0
  fi
  return 1
}

cmd_status() {
  pgrep -x fcitx5 >/dev/null && echo "fcitx5: running" || echo "fcitx5: no"
  pgrep -x fcitx >/dev/null && echo "fcitx: running" || echo "fcitx: no"
  echo "IM_NAME=$IM_NAME"
  echo "说明: 本脚本无 --undo（会话态操作）"
}

cmd_apply() {
  if command -v fcitx5-remote >/dev/null 2>&1 && pgrep -x fcitx5 >/dev/null 2>&1; then
    fcitx5-remote -s "$IM_NAME"
    fcitx5-remote -o
    _rime_set_chinese org.fcitx.Fcitx5 || true
    log "已切换 fcitx5 / Rime 中文模式"
  elif command -v fcitx-remote >/dev/null 2>&1 && pgrep -x fcitx >/dev/null 2>&1; then
    fcitx-remote -s "$IM_NAME"
    fcitx-remote -o
    _rime_set_chinese org.fcitx.Fcitx5 || _rime_set_chinese org.fcitx.Fcitx || {
      fcitx-remote -s fcitx-keyboard-us 2>/dev/null || true
      fcitx-remote -s "$IM_NAME"
      fcitx-remote -o
      echo "[!] fcitx4 可能无 SetAsciiMode，已尝试重选 Rime" >&2
    }
    log "已切换 fcitx / Rime"
  else
    die "未检测到运行中的 fcitx/fcitx5"
  fi
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) die "本脚本不支持 --undo（即时会话操作）" ;;
  --status|status) cmd_status ;;
  -h|--help) echo "用法: $0 [--apply|--status]"; echo "无持久配置，不支持 --undo" ;;
  *) die "未知参数: $1" ;;
esac
