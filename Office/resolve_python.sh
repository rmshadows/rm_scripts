#!/usr/bin/env bash
# 解析用于 Office/Nautilus 脚本的 Python（不写死用户家目录下的某一路径）
#
# 优先级：
#   1) 已激活的 VIRTUAL_ENV
#   2) source ${PYTHON_VENV_ACTIVATE:-$HOME/.python_venv_activate}
#   3) ${PYTHON_VENV_DIR}/bin/python（若设置了 PYTHON_VENV_DIR）
#   4) $HOME/.PythonVenv/bin/python（未配置时的常见默认）
#   5) PATH 中的 python3
#
# 用法（在 Nautilus 包装脚本里）:
#   source "$NAUTILUS_ROOT/lib/Office/resolve_python.sh"
#   PYTHON="$(office_resolve_python)"
#   "$PYTHON" some.py
#
# 用户自定义示例（写入 ~/.zshrc / ~/.bashrc）:
#   export PYTHON_VENV_DIR="$HOME/myenv"
#   export PYTHON_VENV_ACTIVATE="$HOME/myenv/bin/activate"   # 或自建 activate 小文件

office_resolve_python() {
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
