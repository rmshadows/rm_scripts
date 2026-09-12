#!/usr/bin/env bash
# 隐藏/恢复 shell 提示符前的 (.PythonVenv) 标记
# 原理：venv 的 bin/activate 仅在 VIRTUAL_ENV_DISABLE_PROMPT 为空时改写 PS1；
#       在 ~/.python_venv_activate（GNOME/Server Init 与 python-env.sh 的共同入口，
#       zshrc 默认激活、acpy、手动 source 都走它）里 source 之前 export 该变量，
#       venv 照常激活（python/pip/PATH 不变），只是提示符前不再显示名字。
# 范围：仅影响默认全局 venv；以后手动 source 某项目 venv 的 bin/activate 仍显示各自名字。
# --undo：删除注入的标记块，恢复显示（另有完整文件备份）
# 用法: ./venv-prompt.sh [--apply|--undo|--status]
# 目标用户: TARGET_USER 或 SUDO_USER 或当前用户
set -euo pipefail

NAME="venv-prompt"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"

log()  { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[x] $*" >&2; exit 1; }

if [[ -n "${TARGET_USER:-}" ]]; then
  :
elif [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="$(logname 2>/dev/null || echo "${USER:-$(id -un)}")"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || die "无法解析用户家目录: $TARGET_USER"

ACT_FILE="${PYTHON_VENV_ACTIVATE:-$TARGET_HOME/.python_venv_activate}"
MARK_BEGIN="# --- systweak venv-prompt begin ---"
MARK_END="# --- systweak venv-prompt end ---"
BAK_FILE="$BACKUP_DIR/$(basename "$ACT_FILE").bak"

# 标准输入写入 ACT_FILE（普通用户直写，root 借 sudo 写并归权）
write_as_target() {
  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    cat > "$ACT_FILE"
  else
    local tmp
    tmp="$(mktemp)"
    cat > "$tmp"
    sudo cp "$tmp" "$ACT_FILE"
    sudo chown "${TARGET_USER}:${TARGET_USER}" "$ACT_FILE"
    rm -f "$tmp"
  fi
}

cmd_status() {
  echo "用户: $TARGET_USER ($TARGET_HOME)"
  echo "激活入口: $ACT_FILE"
  if [[ ! -f "$ACT_FILE" ]]; then
    echo "状态: 文件不存在（未通过 Debian 初始化 / python-env.sh 部署默认 venv）"
  elif grep -qF "$MARK_BEGIN" "$ACT_FILE" 2>/dev/null; then
    echo "状态: 已隐藏（(.PythonVenv) 不显示，venv 仍正常激活）"
  else
    echo "状态: 显示中（默认）"
  fi
  [[ -f "$BAK_FILE" ]] && echo "备份: $BAK_FILE"
}

cmd_apply() {
  [[ -f "$ACT_FILE" ]] || die "找不到激活文件: $ACT_FILE（请先通过 Debian 初始化或 python-env.sh 部署默认 venv）"

  if grep -qF "$MARK_BEGIN" "$ACT_FILE" 2>/dev/null; then
    log "已处于隐藏状态，无需修改: $ACT_FILE"
    cmd_status
    return
  fi

  mkdir -p "$BACKUP_DIR"
  if [[ ! -f "$BAK_FILE" ]]; then
    cp -a "$ACT_FILE" "$BAK_FILE"
    log "已备份原始文件: $BAK_FILE"
  else
    log "已有备份，沿用: $BAK_FILE"
  fi

  {
    printf '%s\n' \
      "$MARK_BEGIN" \
      "# 隐藏提示符前的 (.PythonVenv)（venv 仍正常激活；删除本块即恢复显示）" \
      "export VIRTUAL_ENV_DISABLE_PROMPT=1" \
      "$MARK_END"
    cat "$ACT_FILE"
  } | write_as_target
  log "已隐藏 (.PythonVenv) 提示符: $ACT_FILE"
  echo
  echo "新开终端自动生效；当前终端可执行: decpy && acpy"
  cmd_status
}

cmd_undo() {
  if [[ -f "$ACT_FILE" ]] && grep -qF "$MARK_BEGIN" "$ACT_FILE" 2>/dev/null; then
    sed "/${MARK_BEGIN}/,/${MARK_END}/d" "$ACT_FILE" | write_as_target
    log "已恢复 (.PythonVenv) 显示: $ACT_FILE"
    echo
    echo "新开终端自动生效；当前终端可依次执行: unset VIRTUAL_ENV_DISABLE_PROMPT; decpy; acpy"
  else
    log "未找到本脚本注入的标记块，无需还原: $ACT_FILE"
    [[ -f "$BAK_FILE" ]] && warn "另有完整备份可手动恢复: $BAK_FILE"
  fi
  cmd_status
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help)
    cat <<EOF
用法: $0 [--apply|--undo|--status]

  --apply   隐藏 (.PythonVenv) 提示符（默认）
  --undo    恢复显示
  --status  查看当前状态

环境变量: TARGET_USER  PYTHON_VENV_ACTIVATE  SYSTWEAK_BACKUP
EOF
    ;;
  *) die "未知参数: $1（见 --help）" ;;
esac
