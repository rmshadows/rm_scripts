#!/usr/bin/env bash
# 解析用于 Office/Nautilus 脚本的 Python（不写死用户家目录下的某一路径）
#
# 优先级：
#   1) PYTHON_VENV_DIR（本次指定）
#   2) ~/.config/office/python-venv（一行目录，用户可改）
#   3) 已激活的 VIRTUAL_ENV
#   4) ~/.python_venv_activate
#   5) $HOME/.PythonVenv/bin/python
#   6) PATH 中的 python3
#
# 右键脚本由文件管理器用 bash 启动，不读 .bashrc / .zshrc。
# 换路径：编辑 ~/.config/office/python-venv ，或
#   PYTHON_VENV_DIR=$HOME/myenv ./0-Off-init.sh

office_resolve_python() {
  local configured="" cfg="${OFFICE_VENV_FILE:-$HOME/.config/office/python-venv}"
  if [[ -n "${PYTHON_VENV_DIR:-}" && -x "${PYTHON_VENV_DIR}/bin/python" ]]; then
    printf '%s\n' "${PYTHON_VENV_DIR}/bin/python"
    return 0
  fi
  if [[ -f "$cfg" ]]; then
    IFS= read -r configured <"$cfg" || true
    case "$configured" in
      \~/*) configured="$HOME/${configured#\~/}" ;;
    esac
    if [[ -n "$configured" && -x "$configured/bin/python" ]]; then
      printf '%s\n' "$configured/bin/python"
      return 0
    fi
  fi
  if [[ -n "${VIRTUAL_ENV:-}" && -x "${VIRTUAL_ENV}/bin/python" ]]; then
    printf '%s\n' "${VIRTUAL_ENV}/bin/python"
    return 0
  fi

  local act="${PYTHON_VENV_ACTIVATE:-${HOME}/.python_venv_activate}"
  if [[ -f "$act" ]]; then
    # shellcheck disable=SC1090
    source "$act" 2>/dev/null || true
    if [[ -n "${VIRTUAL_ENV:-}" && -x "${VIRTUAL_ENV}/bin/python" ]]; then
      printf '%s\n' "${VIRTUAL_ENV}/bin/python"
      return 0
    fi
    # activate 文件里可能只有 source /path/bin/activate，再查一次
    if [[ -n "${VIRTUAL_ENV:-}" && -x "${VIRTUAL_ENV}/bin/python3" ]]; then
      printf '%s\n' "${VIRTUAL_ENV}/bin/python3"
      return 0
    fi
  fi

  if [[ -n "${PYTHON_VENV_DIR:-}" && -x "${PYTHON_VENV_DIR}/bin/python" ]]; then
    printf '%s\n' "${PYTHON_VENV_DIR}/bin/python"
    return 0
  fi
  if [[ -n "${PYTHON_VENV_DIR:-}" && -x "${PYTHON_VENV_DIR}/bin/python3" ]]; then
    printf '%s\n' "${PYTHON_VENV_DIR}/bin/python3"
    return 0
  fi

  # 未配置时：尝试用户家目录常见默认 ~/.PythonVenv
  if [[ -x "${HOME}/.PythonVenv/bin/python" ]]; then
    printf '%s\n' "${HOME}/.PythonVenv/bin/python"
    return 0
  fi
  if [[ -x "${HOME}/.PythonVenv/bin/python3" ]]; then
    printf '%s\n' "${HOME}/.PythonVenv/bin/python3"
    return 0
  fi

  command -v python3
}
