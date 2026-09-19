#!/usr/bin/env bash
# Office 模块依赖安装（apt 系统工具 + pip→venv，不锁版本）
#
# 用法:
#   ./0-Off-init.sh                 # 默认含 Nautilus 右键依赖
#   ./0-Off-init.sh --yes           # 非交互
#   ./0-Off-init.sh --without-nautilus  # 不要右键相关 apt（zenity/xclip/clamav 等）
#   ./0-Off-init.sh --with-imagegps # 含 ImageGPS 重依赖（pandas/geopandas）
#   ./0-Off-init.sh --apt-only | --py-only
#   ./0-Off-init.sh --apt-py        # 额外装 apt 的 python3-*（默认不装）
#   ./0-Off-init.sh --status        # 只检查，不安装
#
# 策略（对齐 Nautilus 右键）:
#   右键脚本会 source ~/.zshrc → 激活 ~/.PythonVenv，再用 python3
#   故 Python 库优先 pip 装进 ~/.PythonVenv；系统工具仍走 apt
#   不写 ==版本
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_YES=0
WITH_NAUTILUS=1
WITH_IMAGEGPS=0
DO_APT=1
DO_PY=1
APT_PY_EXTRA=0
STATUS_ONLY=0
PYPI_INDEX="${PYPI_INDEX_URL:-https://pypi.tuna.tsinghua.edu.cn/simple}"

usage() {
  cat <<'EOF'
Office 模块依赖安装（apt 系统工具 + pip→venv，不锁版本）

用法:
  ./0-Off-init.sh                    # 默认含 Nautilus 右键依赖
  ./0-Off-init.sh --yes              # 非交互
  ./0-Off-init.sh --without-nautilus # 不要右键相关 apt
  ./0-Off-init.sh --with-imagegps    # 含 ImageGPS 重依赖
  ./0-Off-init.sh --apt-only | --py-only
  ./0-Off-init.sh --apt-py           # 额外装 apt python3-*（一般不需要）
  ./0-Off-init.sh --status

策略: 系统工具 apt；Python 库 pip→~/.PythonVenv（与右键 source ~/.zshrc 一致）。
EOF
  exit 0
}

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    --with-nautilus) WITH_NAUTILUS=1; shift ;;  # 兼容旧参数（现已默认开启）
    --without-nautilus|--no-nautilus) WITH_NAUTILUS=0; shift ;;
    --with-imagegps) WITH_IMAGEGPS=1; shift ;;
    --apt-only) DO_PY=0; shift ;;
    --py-only) DO_APT=0; shift ;;
    --apt-py) APT_PY_EXTRA=1; shift ;;
    --status) STATUS_ONLY=1; shift ;;
    *) die "未知参数: $1（见 --help）" ;;
  esac
done

target_home() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    getent passwd "$SUDO_USER" | cut -d: -f6
  else
    echo "${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
  fi
}

TARGET_HOME="$(target_home)"
VENV_DIR="${PYTHON_VENV_DIR:-$TARGET_HOME/.PythonVenv}"
ACT_FILE="${PYTHON_VENV_ACTIVATE:-$TARGET_HOME/.python_venv_activate}"

# ---------- apt：系统工具（非 Python 库）----------
APT_CORE=(
  python3
  python3-pip
  python3-venv
  libreoffice
  libreoffice-java-common
  libreoffice-writer
  libreoffice-calc
  default-jre
  poppler-utils
  ghostscript
  pandoc
  parallel
  file
  openssl
  cups
)

APT_SOFT=(
  antiword
  catdoc
  docx2txt
  gnumeric
)

APT_NAUTILUS=(
  zenity
  libnotify-bin
  xclip
  xsel
  wl-clipboard
  gnome-terminal
  xfce4-terminal
  imagemagick
  gnupg
  clamav
  clamav-daemon
)

# 仅 --apt-py 时安装（默认走 venv/pip，与右键一致）
APT_PY=(
  python3-openpyxl
  python3-pil
  python3-pypdf
  python3-pypdf2
  python3-docx
  python3-natsort
)

APT_IMAGEGPS=(
  python3-pandas
  python3-shapely
)

# ---------- pip：模块 → PyPI 名（不写版本）----------
PIP_CORE_MAP=(
  "inputimeout:inputimeout"
  "pdf2image:pdf2image"
  "pypdf:pypdf"
  "PIL:Pillow"
  "openpyxl:openpyxl"
  "docx:python-docx"
  "natsort:natsort"
)

PIP_IMAGEGPS_MAP=(
  "pandas:pandas"
  "geopandas:geopandas"
  "shapely:shapely"
)

apt_can() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

pkg_installed() {
  dpkg-query -W -f '${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

cmd_ok() { command -v "$1" >/dev/null 2>&1; }

apt_install_list() {
  local -a pkgs=("$@")
  local -a need=()
  local p
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  for p in "${pkgs[@]}"; do
    pkg_installed "$p" && continue
    need+=("$p")
  done
  [[ ${#need[@]} -eq 0 ]] && { log "apt 已齐全（本组）"; return 0; }

  log "apt 安装: ${need[*]}"
  if apt_can apt-get install -y "${need[@]}"; then
    return 0
  fi
  warn "批量安装有失败，改为逐个尝试（可跳过缺失包）"
  local -a failed=()
  for p in "${need[@]}"; do
    pkg_installed "$p" && continue
    if apt_can apt-get install -y "$p"; then
      log "  ok  $p"
    else
      warn "  skip $p"
      failed+=("$p")
    fi
  done
  [[ ${#failed[@]} -gt 0 ]] && warn "未装上: ${failed[*]}"
  return 0
}

# 确保 ~/.PythonVenv + activate 文件（对齐 GNOME Init / systweak python-env）
ensure_venv() {
  if [[ ! -x "$VENV_DIR/bin/python" ]]; then
    log "创建 venv: $VENV_DIR"
    command -v python3 >/dev/null || die "需要 python3"
    # 系统 python3 -m venv（不要用已损坏的半成品目录）
    if [[ -d "$VENV_DIR" && ! -f "$VENV_DIR/pyvenv.cfg" ]]; then
      die "$VENV_DIR 存在但不是 venv，请手动处理"
    fi
    python3 -m venv "$VENV_DIR" || die "python3 -m venv 失败（可 apt install python3-venv）"
  fi
  if [[ ! -f "$ACT_FILE" ]]; then
    log "写入 $ACT_FILE"
    printf '# Python 全局虚拟环境\nsource %s/bin/activate\n' "$VENV_DIR" >"$ACT_FILE"
  fi
}

is_venv_python() {
  local py="$1" root
  [[ "$py" == "$VENV_DIR"/* ]] && return 0
  [[ -n "${VIRTUAL_ENV:-}" && "$py" == "$VIRTUAL_ENV"/* ]] && return 0
  root="$(cd "$(dirname "$py")/.." 2>/dev/null && pwd)" || return 1
  [[ -f "$root/pyvenv.cfg" ]]
}

resolve_python() {
  if [[ -n "${VIRTUAL_ENV:-}" && -x "${VIRTUAL_ENV}/bin/python" ]]; then
    echo "${VIRTUAL_ENV}/bin/python"
    return
  fi
  if [[ -x "$VENV_DIR/bin/python" ]]; then
    echo "$VENV_DIR/bin/python"
    return
  fi
  echo "python3"
}

pip_install_pkgs() {
  local -a pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  local py
  py="$(resolve_python)"
  log "pip 目标: $py"
  if ! "$py" -m pip --version >/dev/null 2>&1; then
    warn "无 pip，尝试确保 venv / python3-pip"
    ensure_venv
    py="$(resolve_python)"
  fi

  local -a flags=(-i "$PYPI_INDEX")
  if is_venv_python "$py"; then
    "$py" -m pip install "${flags[@]}" "${pkgs[@]}" || {
      warn "venv pip 失败: ${pkgs[*]}"
      return 1
    }
    return 0
  fi

  warn "未使用 venv（$py），回退 --user（建议先建 ~/.PythonVenv）"
  if "$py" -m pip install --user "${flags[@]}" "${pkgs[@]}"; then
    return 0
  fi
  "$py" -m pip install --user --break-system-packages "${flags[@]}" "${pkgs[@]}" || {
    warn "pip 安装失败: ${pkgs[*]}"
    return 1
  }
}

py_import_ok() {
  local mod="$1"
  "$(resolve_python)" -c "import $mod" >/dev/null 2>&1
}

show_status() {
  local py exe
  py="$(resolve_python)"
  exe="$("$py" -c 'import sys; print(sys.executable)' 2>/dev/null || echo "$py")"
  echo "=== 运行时（右键会 source ~/.zshrc → ~/.PythonVenv）==="
  echo "  HOME/venv: $VENV_DIR"
  echo "  activate:  $ACT_FILE ($( [[ -f $ACT_FILE ]] && echo 存在 || echo 缺失 ))"
  echo "  python:    $exe"
  echo "=== 命令检查 ==="
  local c
  for c in python3 soffice pdftoppm gs pandoc parallel zenity xclip convert gpg; do
    if cmd_ok "$c"; then
      printf '  OK  %s\n' "$c"
    else
      printf '  --  %s\n' "$c"
    fi
  done
  echo "=== Python 模块（venv）==="
  local m
  for m in openpyxl PIL pypdf docx natsort inputimeout pdf2image; do
    if py_import_ok "$m"; then
      printf '  OK  %s\n' "$m"
    else
      printf '  --  %s\n' "$m"
    fi
  done
}

pip_fill_map() {
  local -n _map=$1
  local -a need=()
  local pair mod pkg
  for pair in "${_map[@]}"; do
    mod="${pair%%:*}"
    pkg="${pair##*:}"
    if py_import_ok "$mod"; then
      log "py 已有: $mod"
    else
      need+=("$pkg")
    fi
  done
  if [[ ${#need[@]} -gt 0 ]]; then
    log "pip→venv（不锁版本）: ${need[*]}"
    pip_install_pkgs "${need[@]}" || warn "部分包未装上"
  else
    log "本组 Python 模块已满足"
  fi
}

# ---------- main ----------
if [[ "$STATUS_ONLY" -eq 1 ]]; then
  show_status
  exit 0
fi

echo "Office 依赖安装"
echo "  目录: $SCRIPT_DIR"
echo "  apt=$DO_APT  py=$DO_PY(venv优先)  apt-py=$APT_PY_EXTRA  nautilus=$WITH_NAUTILUS  imagegps=$WITH_IMAGEGPS"
echo "  venv: $VENV_DIR"
echo

if [[ "$ASSUME_YES" -eq 0 ]]; then
  if [[ ! -t 0 ]]; then
    die "非 TTY 请加 --yes"
  fi
  read -r -p "继续安装？[Y/n] " ans || true
  ans="${ans:-Y}"
  [[ "$ans" == [Yy]* ]] || { echo "已取消"; exit 0; }
fi

if [[ "$DO_APT" -eq 1 ]]; then
  log "更新 apt 索引…"
  apt_can apt-get update -y || warn "apt update 失败，继续尝试安装"

  apt_install_list "${APT_CORE[@]}"
  apt_install_list "${APT_SOFT[@]}"

  if [[ "$WITH_NAUTILUS" -eq 1 ]]; then
    apt_install_list "${APT_NAUTILUS[@]}"
  fi
  if [[ "$APT_PY_EXTRA" -eq 1 ]]; then
    apt_install_list "${APT_PY[@]}"
    [[ "$WITH_IMAGEGPS" -eq 1 ]] && apt_install_list "${APT_IMAGEGPS[@]}"
  fi
fi

if [[ "$DO_PY" -eq 1 ]]; then
  ensure_venv
  pip_fill_map PIP_CORE_MAP
  if [[ "$WITH_IMAGEGPS" -eq 1 ]]; then
    pip_fill_map PIP_IMAGEGPS_MAP
  fi
fi

echo
log "完成。可用 ./0-Off-init.sh --status 复查"
show_status
