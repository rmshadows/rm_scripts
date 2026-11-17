#!/usr/bin/env bash
# 右键由文件管理器用 bash 启动，不读 .bashrc / .zshrc。
# 自定义虚拟环境：在 ~/.config/office/python-venv 写一行目录（绝对路径）。
# 本次运行也认环境变量 PYTHON_VENV_DIR。

office_configured_venv_dir() {
  local cfg="${OFFICE_VENV_FILE:-$HOME/.config/office/python-venv}" dir=""
  if [[ -n "${PYTHON_VENV_DIR:-}" ]]; then
    dir="$PYTHON_VENV_DIR"
  elif [[ -f "$cfg" ]]; then
    IFS= read -r dir <"$cfg" || true
    dir="${dir#"${dir%%[![:space:]]*}"}"
    dir="${dir%"${dir##*[![:space:]]}"}"
    case "$dir" in
      \~/*) dir="$HOME/${dir#\~/}" ;;
      \$HOME/*) dir="$HOME/${dir#\$HOME/}" ;;
    esac
  fi
  printf '%s\n' "$dir"
}

office_load_venv() {
  local dir act
  dir="$(office_configured_venv_dir)"
  if [[ -n "$dir" && -f "$dir/bin/activate" ]]; then
    # shellcheck disable=SC1091
    . "$dir/bin/activate"
    return 0
  fi
  # conda 环境没有 bin/activate，直接用它的 python。
  if [[ -n "$dir" && -x "$dir/bin/python" ]]; then
    PATH="$dir/bin:$PATH"
    export PATH
    export VIRTUAL_ENV="$dir"
    return 0
  fi
  act="${PYTHON_VENV_ACTIVATE:-$HOME/.python_venv_activate}"
  if [[ -f "$act" ]]; then
    # shellcheck disable=SC1090
    . "$act" 2>/dev/null || true
    return 0
  fi
  if [[ -f "$HOME/.PythonVenv/bin/activate" ]]; then
    # shellcheck disable=SC1091
    . "$HOME/.PythonVenv/bin/activate"
  fi
}

office_load_venv
