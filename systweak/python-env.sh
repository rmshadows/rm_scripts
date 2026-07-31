#!/usr/bin/env bash
# Python3 环境（合并原 python-env-basic + pypi-tsinghua-mirror）
# - 安装 python3 / pip / venv / tk / pipx（按需）
# - pip 清华镜像
# - 默认用户虚拟环境 ~/.PythonVenv + ~/.python_venv_activate（对齐 GNOME Init）
# - 在 shell 中加入 acpy / decpy（激活 / 取消激活）
# --undo：还原 pip.conf、删除本脚本创建的 venv/激活文件/shell 片段；不卸载 apt 包
# 用法: ./python-env.sh [--apply|--undo|--status]
# 目标用户: TARGET_USER 或 SUDO_USER 或当前用户
set -euo pipefail

NAME="python-env"
BACKUP_DIR="${SYSTWEAK_BACKUP:-$HOME/.systweak-backup}/${NAME}"
INDEX_URL="${PYPI_INDEX_URL:-https://pypi.tuna.tsinghua.edu.cn/simple}"

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

if [[ -n "${TARGET_USER:-}" ]]; then
  :
elif [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="$(logname 2>/dev/null || echo "${USER:-$(id -un)}")"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$TARGET_HOME" ]] || die "无法解析用户家目录: $TARGET_USER"

VENV_DIR="${PYTHON_VENV_DIR:-$TARGET_HOME/.PythonVenv}"
ACT_FILE="${PYTHON_VENV_ACTIVATE:-$TARGET_HOME/.python_venv_activate}"
PIP_CONF="$TARGET_HOME/.config/pip/pip.conf"
SHELL_MARK_BEGIN="# --- systweak python-env begin ---"
SHELL_MARK_END="# --- systweak python-env end ---"

run_as_user() {
  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    "$@"
  else
    sudo -H -u "$TARGET_USER" "$@"
  fi
}

apt_install() {
  if [[ $EUID -eq 0 ]]; then
    apt-get install -y "$@"
  else
    sudo apt-get install -y "$@"
  fi
}

apt_update() {
  if [[ $EUID -eq 0 ]]; then
    apt-get update -y
  else
    sudo apt-get update -y
  fi
}

backup_pip_conf() {
  mkdir -p "$BACKUP_DIR"
  if [[ -f "$PIP_CONF" && ! -f "$BACKUP_DIR/pip.conf.bak" ]]; then
    cp -a "$PIP_CONF" "$BACKUP_DIR/pip.conf.bak"
    log "已备份 pip.conf"
  elif [[ ! -f "$PIP_CONF" && ! -f "$BACKUP_DIR/pip.conf.missing" ]]; then
    touch "$BACKUP_DIR/pip.conf.missing"
  fi
}

ensure_shell_hooks() {
  local rc snippet
  snippet=$(cat <<EOF
${SHELL_MARK_BEGIN}
# acpy: 激活默认 venv；decpy: 退出（需已激活）
alias acpy='[ -f "\$HOME/.python_venv_activate" ] && source "\$HOME/.python_venv_activate" || echo "缺少 \$HOME/.python_venv_activate"'
alias decpy='type deactivate >/dev/null 2>&1 && deactivate || echo "当前未在虚拟环境中"'
${SHELL_MARK_END}
EOF
)
  for rc in "$TARGET_HOME/.zshrc" "$TARGET_HOME/.bashrc"; do
    if [[ ! -f "$rc" ]]; then
      continue
    fi
    if grep -qF "$SHELL_MARK_BEGIN" "$rc" 2>/dev/null; then
      log "shell 钩子已存在: $rc"
      continue
    fi
    if [[ ! -f "$BACKUP_DIR/$(basename "$rc").bak" ]]; then
      cp -a "$rc" "$BACKUP_DIR/$(basename "$rc").bak"
    fi
    printf '\n%s\n' "$snippet" >>"$rc"
    chown "${TARGET_USER}:${TARGET_USER}" "$rc" 2>/dev/null || true
    log "已写入 acpy/decpy 到 $rc"
    echo "patched_rc=$(basename "$rc")" >>"$BACKUP_DIR/shell.env"
  done
}

remove_shell_hooks() {
  local rc
  for rc in "$TARGET_HOME/.zshrc" "$TARGET_HOME/.bashrc"; do
    [[ -f "$rc" ]] || continue
    if grep -qF "$SHELL_MARK_BEGIN" "$rc" 2>/dev/null; then
      # 删除标记块
      sed -i "/${SHELL_MARK_BEGIN}/,/${SHELL_MARK_END}/d" "$rc"
      log "已从 $rc 移除 acpy/decpy 片段"
    fi
  done
}

cmd_status() {
  echo "用户: $TARGET_USER ($TARGET_HOME)"
  echo "备份: $BACKUP_DIR"
  command -v python3 >/dev/null && echo "python3: $(python3 --version)" || echo "python3: 无"
  command -v pip3 >/dev/null && echo "pip3: ok" || echo "pip3: 无"
  python3 -c "import tkinter" 2>/dev/null && echo "tkinter: ok" || echo "tkinter: 无"
  [[ -d "$VENV_DIR" && -f "$VENV_DIR/bin/activate" ]] && echo "venv: $VENV_DIR" || echo "venv: 无"
  [[ -f "$ACT_FILE" ]] && echo "activate 文件: $ACT_FILE" || echo "activate 文件: 无"
  [[ -f "$PIP_CONF" ]] && echo "pip.conf: 存在" || echo "pip.conf: 无"
  if [[ -f "$PIP_CONF" ]]; then
    grep -E 'index-url|extra-index' "$PIP_CONF" 2>/dev/null || true
  fi
  echo "shell: acpy=激活默认 venv，decpy=deactivate"
}

cmd_apply() {
  command -v python3 >/dev/null 2>&1 || {
    log "安装 python3..."
    apt_update
    apt_install python3
  }
  mkdir -p "$BACKUP_DIR"
  backup_pip_conf

  log "安装 python3-pip / python3-venv / python3-tk / pipx（按需）..."
  apt_update
  apt_install python3-pip python3-venv python3-tk pipx || apt_install python3-pip python3-venv python3-tk
  echo "apt_touched=1" >"$BACKUP_DIR/pkgs.env"

  # pip 清华源（用户级）
  run_as_user mkdir -p "$(dirname "$PIP_CONF")"
  run_as_user pip3 config set global.index-url "$INDEX_URL" || \
    run_as_user python3 -m pip config set global.index-url "$INDEX_URL"
  run_as_user python3 -m pip install -i "$INDEX_URL" --upgrade pip 2>/dev/null || true
  log "pip 镜像: $INDEX_URL"

  # 默认 venv（对齐 GNOME Init: ~/.PythonVenv + ~/.python_venv_activate）
  if [[ -d "$VENV_DIR" && -f "$VENV_DIR/bin/activate" ]]; then
    log "虚拟环境已存在: $VENV_DIR"
  else
    if [[ -d "$VENV_DIR" && ! -f "$VENV_DIR/bin/activate" ]]; then
      die "$VENV_DIR 已存在但不是 venv，请手动处理"
    fi
    log "创建虚拟环境: $VENV_DIR"
    run_as_user python3 -m venv "$VENV_DIR"
    echo "created_venv=1" >>"$BACKUP_DIR/state.env"
  fi

  if [[ ! -f "$ACT_FILE" ]]; then
    printf '# Python 默认虚拟环境（systweak python-env）\nsource %s/bin/activate\n' "$VENV_DIR" >"$ACT_FILE"
    chown "${TARGET_USER}:${TARGET_USER}" "$ACT_FILE" 2>/dev/null || true
    echo "created_act=1" >>"$BACKUP_DIR/state.env"
    log "已生成 $ACT_FILE"
  else
    log "已存在 $ACT_FILE（未覆盖）"
  fi

  # 在 venv 内也设一下镜像，方便激活后 pip
  if [[ -x "$VENV_DIR/bin/pip" ]]; then
    run_as_user "$VENV_DIR/bin/pip" config set global.index-url "$INDEX_URL" 2>/dev/null || \
      run_as_user "$VENV_DIR/bin/python" -m pip config set global.index-url "$INDEX_URL" || true
  fi

  ensure_shell_hooks
  log "完成。新开终端后: acpy 激活，decpy 退出。或: source $ACT_FILE"
  cmd_status
}

cmd_undo() {
  [[ -d "$BACKUP_DIR" ]] || die "无备份目录: $BACKUP_DIR"

  if [[ -f "$BACKUP_DIR/pip.conf.bak" ]]; then
    mkdir -p "$(dirname "$PIP_CONF")"
    cp -a "$BACKUP_DIR/pip.conf.bak" "$PIP_CONF"
    chown "${TARGET_USER}:${TARGET_USER}" "$PIP_CONF" 2>/dev/null || true
    log "已还原 pip.conf"
  elif [[ -f "$BACKUP_DIR/pip.conf.missing" ]]; then
    rm -f "$PIP_CONF"
    log "已删除后来创建的 pip.conf"
  fi

  if [[ -f "$BACKUP_DIR/state.env" ]] && grep -q 'created_act=1' "$BACKUP_DIR/state.env"; then
    rm -f "$ACT_FILE"
    log "已删除 $ACT_FILE"
  fi
  if [[ -f "$BACKUP_DIR/state.env" ]] && grep -q 'created_venv=1' "$BACKUP_DIR/state.env"; then
    rm -rf "$VENV_DIR"
    log "已删除 $VENV_DIR"
  else
    warn "未删除 $VENV_DIR（非本脚本创建或无记录）"
  fi

  remove_shell_hooks
  # 可选：还原整份 rc 备份（若只想去钩子，上面 sed 已够；有整文件 bak 则提示）
  for f in "$BACKUP_DIR"/.zshrc.bak "$BACKUP_DIR"/.bashrc.bak; do
    [[ -f "$f" ]] && warn "另有完整备份 $f，如需可手动覆盖"
  done

  [[ -f "$BACKUP_DIR/pkgs.env" ]] && warn "apt 包未卸载（见 $BACKUP_DIR/pkgs.env）"
  cmd_status
}

case "${1:---apply}" in
  --apply|apply) cmd_apply ;;
  --undo|undo) cmd_undo ;;
  --status|status) cmd_status ;;
  -h|--help)
    cat <<EOF
用法: $0 [--apply|--undo|--status]
环境变量: TARGET_USER  PYTHON_VENV_DIR  PYTHON_VENV_ACTIVATE  PYPI_INDEX_URL  SYSTWEAK_BACKUP
EOF
    ;;
  *) die "未知参数: $1" ;;
esac
