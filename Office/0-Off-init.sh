#!/usr/bin/env bash
# Office 模块依赖安装（apt 系统工具 + pip→venv，不锁版本）
#
# 跑完会做三件事：
#   1. 选定一个 Python 虚拟环境，记下路径，并让新开的终端自动启用。
#   2. 用 apt 装系统工具，再用 pip 把 Python 包装进那个虚拟环境。
#   3. 把右键脚本复制到文件管理器的脚本目录。
#
# 用法:
#   ./0-Off-init.sh                 # 默认：apt + pip + 复制右键脚本
#   ./0-Off-init.sh --yes           # 不问「继续安装？」
#   ./0-Off-init.sh --without-nautilus  # 不装 zenity/xclip/clamav 等右键相关 apt
#   ./0-Off-init.sh --with-imagegps # 额外装 ImageGPS 的 pandas/geopandas
#   ./0-Off-init.sh --apt-only      # 只装 apt，不动虚拟环境
#   ./0-Off-init.sh --py-only       # 只处理虚拟环境和 pip，不跑 apt
#   ./0-Off-init.sh --apt-py        # 额外用 apt 装 python3-*（默认不装，走 pip）
#   ./0-Off-init.sh --status        # 只检查，不安装、不复制
#   ./0-Off-init.sh --venv-auto     # 模式 1：自动检测，有就用
#   ./0-Off-init.sh --venv-fixed    # 模式 2：固定目录，没有就新建，有就沿用
#   ./0-Off-init.sh --venv-fixed ~/myenv
#
# 虚拟环境两种模式，改下面的 VENV_MODE，或用上面的命令行：
#   auto / 1  自动检测，有就用。顺序：
#        MANUAL_VENV_DIR、PYTHON_VENV_DIR（写了就用这个）
#        当前终端（venv 的 VIRTUAL_ENV，conda 的 CONDA_PREFIX）
#        ~/.config/office/python-venv、~/.python_venv_activate、~/.PythonVenv
#        都没有才新建 ~/.PythonVenv
#   fixed / 2  固定目录。只看 FIXED_VENV_DIR，留空就是 ~/.PythonVenv。
#        这个目录已是环境就沿用，还没有就新建。不看当前终端。
# 选定之后写回配置文件和 activate 文件，并在 ~/.bashrc、~/.zshrc 末尾加自动启用。
# 右键由文件管理器用 bash 非交互执行，读不到 bashrc/zshrc（非交互会在开头 return），
# 所以右键走 nautilus_env.sh：先读配置文件，再读 activate 文件。
# pip 不写 ==版本，装当前索引上的最新版。
# 装完会打印「以后要改这些参数」：每一项对应改脚本、改配置文件，还是改命令行。
set -euo pipefail

# 本脚本所在目录，也是要复制出去的 Office 源目录。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 可改参数（要固定行为，改这里；命令行参数会盖过同名开关）----------
# 模式。auto 或 1：自动检测，有就用。fixed 或 2：固定目录，没有就新建，有就沿用。
# 命令行 --venv-auto / --venv-fixed 会盖过这里。
VENV_MODE=auto
# 模式 2 的目录。留空 = ~/.PythonVenv。可写绝对路径、~/某目录、$HOME/某目录。
FIXED_VENV_DIR=""
# 模式 1 里的手动指定。留空 = 按检测走。模式 2 在 FIXED_VENV_DIR 为空时也会用它。
MANUAL_VENV_DIR=""

ASSUME_YES=0          # 1 = 跳过「继续安装？」。命令行 --yes
WITH_NAUTILUS=1       # 1 = 安装右键要用的系统包。关掉用 --without-nautilus
WITH_IMAGEGPS=0       # 1 = 额外装 ImageGPS 的 pandas/geopandas。或 --with-imagegps
DO_APT=1              # 1 = 跑 apt。只要 Python 用 --py-only
DO_PY=1               # 1 = 选虚拟环境并 pip。只要系统包用 --apt-only
APT_PY_EXTRA=0        # 1 = 再用 apt 装一份 python3-*。或 --apt-py
STATUS_ONLY=0         # 1 = 只打印检查结果。或 --status
# pip 镜像。临时换源可设环境变量 PYPI_INDEX_URL，不用改这一行。
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
  ./0-Off-init.sh --venv-auto        # 模式 1：自动检测，有就用
  ./0-Off-init.sh --venv-fixed       # 模式 2：固定 ~/.PythonVenv，没有就新建，有就沿用
  ./0-Off-init.sh --venv-fixed ~/myenv

虚拟环境模式改脚本顶部 VENV_MODE（auto/1 或 fixed/2），或用上面的命令行。
模式 1 看当前终端：venv 的 VIRTUAL_ENV，conda 的 CONDA_PREFIX。
模式 2 只看 FIXED_VENV_DIR，留空就是 ~/.PythonVenv。
右键不读 bashrc/zshrc，读配置文件和 activate 文件。
装完会提示每一项以后改哪里。
EOF
  exit 0
}

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }

# 解析参数。未知参数直接退出，避免装错一套。
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
    --venv-auto) VENV_MODE=auto; shift ;;
    --venv-fixed)
      VENV_MODE=fixed
      shift
      if [[ $# -gt 0 && "$1" != -* ]]; then
        FIXED_VENV_DIR="$1"
        shift
      fi
      ;;
    *) die "未知参数: $1（见 --help）" ;;
  esac
done

case "$VENV_MODE" in
  1|auto) VENV_MODE=auto ;;
  2|fixed) VENV_MODE=fixed ;;
  *) die "VENV_MODE 只能是 auto（1，自动检测有就用）或 fixed（2，固定目录：没有就新建，有就沿用）" ;;
esac

# 用 sudo 跑时，家目录和属主是发起 sudo 的桌面用户，不是 root。
# 直接用 root 登录（没有 SUDO_USER）时，才落到 root 自己的家目录。
target_home() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    getent passwd "$SUDO_USER" | cut -d: -f6
  else
    echo "${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
  fi
}

target_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    echo "$SUDO_USER"
  else
    id -un
  fi
}

TARGET_USER="$(target_user)"
TARGET_HOME="$(target_home)"
# 自动检测全落空时新建到这里。真正用哪个目录由 plan_venv 决定。
VENV_DIR="$TARGET_HOME/.PythonVenv"
# 一行激活命令。终端和右键都能 source 它，不依赖 bash 还是 zsh。
ACT_FILE="${PYTHON_VENV_ACTIVATE:-$TARGET_HOME/.python_venv_activate}"
# 上次选定的路径。文件内容是一行绝对路径，~ 和 $HOME/ 开头会展开。
CONFIG_FILE="${OFFICE_VENV_FILE:-$TARGET_HOME/.config/office/python-venv}"
# 命令行 PYTHON_VENV_DIR。空字符串表示这次没从环境变量指定。
USER_SET_VENV_DIR="${PYTHON_VENV_DIR:-}"
# bashrc / zshrc 里用这对标记包住我们写的那段，下次运行先删旧段再重写。
SHELL_BEGIN="# --- office python venv begin ---"
SHELL_END="# --- office python venv end ---"
CHOSE_VENV=""   # choose_venv 选定的目录，pip 只往这里装
CREATED_VENV=0  # 1 = 这次新建成的，才询问要不要在本进程里启用
PLANNED_VENV="" # plan_venv 算出来、还没创建的目录
PLANNED_WHY=""  # 为什么选它，打印给用户看
PLANNED_NEW=0   # 1 = 这个目录还不是虚拟环境，安装时会新建

# ---------- apt：系统工具（不是 Python 库）----------
# 缺了右键脚本会直接失败的命令：soffice、pdftoppm、gs、pandoc 等。
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

# 旧文档格式的可选转换器。某个发行版没有这个包就跳过，不让整次安装失败。
APT_SOFT=(
  antiword
  catdoc
  docx2txt
  gnumeric
)

# 右键菜单用：对话框、剪贴板、终端、看图、解密、杀毒。--without-nautilus 时不装。
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

# 仅 --apt-py 时安装。默认不装，避免和虚拟环境里的 pip 包各一份、版本打架。
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

# ---------- pip：import 名:PyPI 包名（不写版本）----------
# 左边用来探测「已经能 import 吗」，右边才是 pip install 的名字。
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

# 已经是 root 就直接跑；普通用户则借 sudo。只用于 apt。
apt_can() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

# dpkg 状态是「已安装」才算有，避免半安装的包被跳过。
pkg_installed() {
  dpkg-query -W -f '${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

cmd_ok() { command -v "$1" >/dev/null 2>&1; }

# 只装还没有的包。整批失败时改成逐个装，缺包的发行版可以跳过继续。
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

# 建虚拟环境、写家目录文件时用桌面用户的身份，避免 sudo 跑出来变成 root 所有。
run_as_target() {
  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    "$@"
  else
    sudo -H -u "$TARGET_USER" "$@"
  fi
}

own_file() {
  chown "${TARGET_USER}:${TARGET_USER}" "$1" 2>/dev/null || true
}

# 普通 venv 有 pyvenv.cfg。conda 环境没有这个文件，用 conda-meta 判断。
# 当前终端里 conda activate 之后，认的是 CONDA_PREFIX，不是 VIRTUAL_ENV。
venv_ok() {
  local dir="${1:-}"
  [[ -n "$dir" && -x "$dir/bin/python" ]] || return 1
  [[ -f "$dir/pyvenv.cfg" || -d "$dir/conda-meta" ]]
}

# 这个终端窗口此刻启用的环境。先看 venv，再看 conda。
current_terminal_env() {
  if venv_ok "${VIRTUAL_ENV:-}"; then
    printf '%s\n' "$VIRTUAL_ENV"
    return 0
  fi
  if venv_ok "${CONDA_PREFIX:-}"; then
    printf '%s\n' "$CONDA_PREFIX"
    return 0
  fi
  return 1
}

# 从 activate 文件取出目录。普通 venv 是 `. .../bin/activate`，conda 是 export VIRTUAL_ENV=。
venv_from_act() {
  local act="$1" line path
  [[ -f "$act" ]] || return 1
  line="$(grep -E '^[[:space:]]*(export[[:space:]]+VIRTUAL_ENV=|(\.|source)[[:space:]]+)' "$act" | head -n 1 || true)"
  [[ -n "$line" ]] || return 1
  if [[ "$line" == *VIRTUAL_ENV=* ]]; then
    path="${line#*=}"
  else
    path="${line#*source }"
    path="${path#. }"
    path="${path%%/bin/activate*}"
  fi
  path="${path//\"/}"
  path="${path//\'/}"
  path="${path%%$'\r'}"
  path="${path%"${path##*[![:space:]]}"}"
  venv_ok "$path" || return 1
  printf '%s\n' "$path"
}

# 写下 ~/.python_venv_activate。内容和现有文件一样就不动，避免无意义改时间戳。
write_act_file() {
  local venv="$1" tmp
  tmp="$(mktemp)"
  if [[ -f "$venv/bin/activate" ]]; then
    printf '# Python 虚拟环境。终端和右键脚本都读这个文件。\n. "%s/bin/activate"\n' "$venv" >"$tmp"
  else
    # conda 环境没有 bin/activate，把该环境的 python 放到 PATH 前面。
    printf '# conda 环境。终端和右键脚本都读这个文件。\nexport PATH="%s/bin:$PATH"\nexport VIRTUAL_ENV="%s"\n' "$venv" "$venv" >"$tmp"
  fi
  if [[ -f "$ACT_FILE" ]] && cmp -s "$tmp" "$ACT_FILE"; then
    rm -f "$tmp"
    return 0
  fi
  install -m 644 "$tmp" "$ACT_FILE"
  rm -f "$tmp"
  own_file "$ACT_FILE"
  log "已记录虚拟环境: $ACT_FILE → $venv"
}

# 生成要追加进 bashrc 和 zshrc 的那一段。
# 新开的交互终端会跑到这里：先看自定义路径，再退回 activate 文件。
shell_venv_block() {
  cat <<EOF
$SHELL_BEGIN
# 自定义路径：把虚拟环境目录写进 ~/.config/office/python-venv（一行绝对路径）。
# 右键脚本也读这个文件，不读 bashrc/zshrc。
_office_venv_dir=""
if [ -n "\${PYTHON_VENV_DIR:-}" ]; then
  _office_venv_dir="\$PYTHON_VENV_DIR"
elif [ -f "\$HOME/.config/office/python-venv" ]; then
  IFS= read -r _office_venv_dir < "\$HOME/.config/office/python-venv"
fi
if [ -n "\$_office_venv_dir" ] && [ -f "\$_office_venv_dir/bin/activate" ]; then
  . "\$_office_venv_dir/bin/activate"
elif [ -n "\$_office_venv_dir" ] && [ -x "\$_office_venv_dir/bin/python" ]; then
  PATH="\$_office_venv_dir/bin:\$PATH"
  export PATH
  export VIRTUAL_ENV="\$_office_venv_dir"
elif [ -f "\$HOME/.python_venv_activate" ]; then
  . "\$HOME/.python_venv_activate"
fi
unset _office_venv_dir
$SHELL_END
EOF
}

# 把上面那段写进指定的 rc。已有旧段就整段换成新的，用户自己的其它内容留着。
ensure_shell_rc() {
  local rc="$1" tmp
  tmp="$(mktemp)"
  if [[ -f "$rc" ]] && grep -qF "$SHELL_BEGIN" "$rc"; then
    awk -v begin="$SHELL_BEGIN" -v end="$SHELL_END" '
      $0 == begin { skip=1; next }
      skip && $0 == end { skip=0; next }
      !skip { print }
    ' "$rc" >"$tmp"
    printf '\n' >>"$tmp"
    shell_venv_block >>"$tmp"
    install -m 644 "$tmp" "$rc"
    rm -f "$tmp"
    own_file "$rc"
    log "已更新 $rc 里的激活命令"
    return 0
  fi
  if [[ ! -f "$rc" ]]; then
    : >"$rc"
    log "新建 $rc"
  fi
  printf '\n' >>"$rc"
  shell_venv_block >>"$rc"
  own_file "$rc"
  log "已把激活命令写入 $rc"
}

# 把用户写的路径展开成绝对路径。支持 ~/ 和 $HOME/，前后空白去掉。
expand_path() {
  local line="$1"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  case "$line" in
    \~) line="$TARGET_HOME" ;;
    \~/*) line="$TARGET_HOME/${line#\~/}" ;;
    \$HOME) line="$TARGET_HOME" ;;
    \$HOME/*) line="$TARGET_HOME/${line#\$HOME/}" ;;
  esac
  printf '%s\n' "$line"
}

# 读配置文件。空行和 # 开头忽略。
read_config_dir() {
  local line
  [[ -f "$CONFIG_FILE" ]] || return 1
  IFS= read -r line <"$CONFIG_FILE" || return 1
  line="$(expand_path "$line")"
  [[ -n "$line" && "$line" != \#* ]] || return 1
  printf '%s\n' "$line"
}

# 先把当前能看到的环境都找出来，再决定这次用哪个。不创建目录、不写文件。
plan_venv() {
  local manual="" from_env="" cfg="" act=""
  if [[ -n "$MANUAL_VENV_DIR" ]]; then
    manual="$(expand_path "$MANUAL_VENV_DIR")"
  fi
  if [[ -n "$USER_SET_VENV_DIR" ]]; then
    from_env="$(expand_path "$USER_SET_VENV_DIR")"
  fi
  cfg="$(read_config_dir 2>/dev/null || true)"
  act="$(venv_from_act "$ACT_FILE" 2>/dev/null || true)"

  # 检测结果留给 report_venv_plan 逐条打印。空字符串表示这一项没有。
  FOUND_TERM="$(current_terminal_env 2>/dev/null || true)"
  FOUND_CFG="$cfg"
  FOUND_ACT="$act"
  FOUND_DEFAULT="$TARGET_HOME/.PythonVenv"

  # 模式 2：不看当前终端。指定目录已是环境就沿用，否则新建。
  if [[ "$VENV_MODE" == "fixed" ]]; then
    local fixed="$FOUND_DEFAULT"
    if [[ -n "$FIXED_VENV_DIR" ]]; then
      fixed="$(expand_path "$FIXED_VENV_DIR")"
    elif [[ -n "$manual" ]]; then
      fixed="$manual"
    elif [[ -n "$from_env" ]]; then
      fixed="$from_env"
    fi
    PLANNED_VENV="$fixed"
    if venv_ok "$fixed"; then
      PLANNED_WHY="模式 2 固定目录，已有，沿用"
    else
      PLANNED_WHY="模式 2 固定目录，没有，将新建"
    fi
  elif [[ -n "$manual" ]]; then
    PLANNED_VENV="$manual"
    PLANNED_WHY="脚本内 MANUAL_VENV_DIR"
  elif [[ -n "$from_env" ]]; then
    PLANNED_VENV="$from_env"
    PLANNED_WHY="环境变量 PYTHON_VENV_DIR"
  elif venv_ok "$FOUND_TERM"; then
    PLANNED_VENV="$FOUND_TERM"
    if [[ -n "${CONDA_PREFIX:-}" && "$FOUND_TERM" == "$CONDA_PREFIX" ]]; then
      PLANNED_WHY="当前终端已启用 conda：${CONDA_DEFAULT_ENV:-$CONDA_PREFIX}"
    else
      PLANNED_WHY="当前终端已启用"
    fi
  elif venv_ok "$FOUND_CFG"; then
    PLANNED_VENV="$FOUND_CFG"
    PLANNED_WHY="配置文件 $CONFIG_FILE"
  elif venv_ok "$FOUND_ACT"; then
    PLANNED_VENV="$FOUND_ACT"
    PLANNED_WHY="已记录的 $ACT_FILE"
  elif venv_ok "$FOUND_DEFAULT"; then
    PLANNED_VENV="$FOUND_DEFAULT"
    PLANNED_WHY="已有的 ~/.PythonVenv"
  else
    PLANNED_VENV="$FOUND_DEFAULT"
    PLANNED_WHY="当前没有虚拟环境，将新建 ~/.PythonVenv"
  fi
  if venv_ok "$PLANNED_VENV"; then
    PLANNED_NEW=0
  else
    PLANNED_NEW=1
  fi
}

# 一行状态：是虚拟环境、路径还在但不是、或者根本没有。
describe_venv() {
  local path="$1"
  if [[ -z "$path" ]]; then
    echo "无"
  elif venv_ok "$path"; then
    echo "$path"
  elif [[ -e "$path" ]]; then
    echo "$path （在，但不是虚拟环境）"
  else
    echo "$path （没有这个目录）"
  fi
}

# 安装前先给用户看检测结果，以及脚本里有没有手写路径。
report_venv_plan() {
  plan_venv
  if [[ "$VENV_MODE" == "fixed" ]]; then
    echo "模式:         2 固定目录（没有就新建，有就沿用）"
  else
    echo "模式:         1 自动检测（有就用）"
  fi
  echo "自动检测当前虚拟环境:"
  echo "  当前终端:     $(describe_venv "$FOUND_TERM")"
  if [[ -n "${CONDA_DEFAULT_ENV:-}${CONDA_PREFIX:-}" ]]; then
    echo "  conda 环境名: ${CONDA_DEFAULT_ENV:-（未设置）}    前缀: ${CONDA_PREFIX:-无}"
  fi
  echo "  配置文件:     $(describe_venv "$FOUND_CFG")"
  if [[ -f "$ACT_FILE" && -z "$FOUND_ACT" ]]; then
    echo "  activate:     $ACT_FILE （文件在，里面的目录已经不能用）"
  else
    echo "  activate:     $(describe_venv "$FOUND_ACT")"
  fi
  echo "  ~/.PythonVenv: $(describe_venv "$FOUND_DEFAULT")"
  if [[ -n "$MANUAL_VENV_DIR" ]]; then
    echo "脚本内指定:   $(expand_path "$MANUAL_VENV_DIR")"
  else
    echo "脚本内指定:   空（改 0-Off-init.sh 顶部 MANUAL_VENV_DIR）"
  fi
  if [[ -n "$USER_SET_VENV_DIR" ]]; then
    echo "环境变量指定: $(expand_path "$USER_SET_VENV_DIR")"
  fi
  if [[ "$STATUS_ONLY" -eq 1 && "$PLANNED_NEW" -eq 1 ]]; then
    echo "检测选定:     $PLANNED_VENV （还没有，安装时才会新建）"
  elif [[ "$PLANNED_NEW" -eq 1 ]]; then
    echo "本次将使用:   $PLANNED_VENV （新建）"
  else
    echo "本次将使用:   $PLANNED_VENV"
  fi
  echo "选择原因:     $PLANNED_WHY"
  echo
}

# 把这次选定的目录写回配置文件，下次不用再猜。
write_config_dir() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  printf '%s\n' "$1" >"$CONFIG_FILE"
  own_file "$CONFIG_FILE"
  own_file "$(dirname "$CONFIG_FILE")"
  log "自定义路径文件: $CONFIG_FILE"
}

# 在指定目录新建虚拟环境。目录已存在但不是 venv 就停下，避免把普通目录当环境覆盖。
create_venv_at() {
  local dest="$1"
  if [[ -d "$dest" && ! -f "$dest/pyvenv.cfg" ]]; then
    die "$dest 存在但不是虚拟环境，请先挪走再运行"
  fi
  command -v python3 >/dev/null || die "需要 python3"
  log "新建虚拟环境: $dest"
  run_as_target mkdir -p "$(dirname "$dest")"
  if ! run_as_target python3 -m venv "$dest"; then
    die "python3 -m venv 失败。Debian 10 / 麒麟需要已安装 python3-venv"
  fi
  CREATED_VENV=1
}

# 按 plan_venv 的结果创建或沿用，然后写配置、写 activate、改 bashrc 和 zshrc。
choose_venv() {
  local found=""
  plan_venv
  found="$PLANNED_VENV"
  if [[ "$PLANNED_NEW" -eq 1 ]]; then
    create_venv_at "$found"
  else
    log "使用已有虚拟环境（$PLANNED_WHY）: $found"
  fi
  CHOSE_VENV="$found"
  VENV_DIR="$found"
  # 三处保持一致：配置文件、activate 文件、两个 shell 的 rc。
  write_config_dir "$found"
  write_act_file "$found"
  ensure_shell_rc "$TARGET_HOME/.bashrc"
  ensure_shell_rc "$TARGET_HOME/.zshrc"
  if [[ "$CREATED_VENV" -eq 1 ]]; then
    echo
    echo "激活命令已写入 ~/.bashrc 和 ~/.zshrc。新开的终端会自动启用。"
    echo "当前窗口要马上用，执行：  . ~/.python_venv_activate"
    # --yes 或非交互时默认在本进程启用，好让后面的 pip 装进新环境。
    local enable_now=1
    if [[ "$ASSUME_YES" -eq 0 && -t 0 ]]; then
      local ans
      read -r -p "现在就在本次安装里启用它？[Y/n] " ans || true
      ans="${ans:-Y}"
      if [[ "$ans" != [Yy]* ]]; then
        enable_now=0
        log "本次安装仍会把包装进该环境；你的终端窗口保持原样"
      fi
    fi
    if [[ "$enable_now" -eq 1 ]]; then
      # 只影响本次安装进程，改不了已经打开的终端窗口。
      # shellcheck disable=SC1090
      . "$ACT_FILE" || true
      log "本次安装已启用该环境"
    fi
  elif ! current_terminal_env >/dev/null; then
    echo
    echo "当前终端还没启用虚拟环境。新开终端会自动启用。"
    echo "这个窗口要马上用的话，执行：  . ~/.python_venv_activate"
  fi
}

# 判断这个 python 是不是虚拟环境里的。是的话 pip 不加 --user。
is_venv_python() {
  local py="$1" root
  [[ "$py" == "$VENV_DIR"/* ]] && return 0
  [[ -n "${VIRTUAL_ENV:-}" && "$py" == "$VIRTUAL_ENV"/* ]] && return 0
  root="$(cd "$(dirname "$py")/.." 2>/dev/null && pwd)" || return 1
  [[ -f "$root/pyvenv.cfg" || -d "$root/conda-meta" ]]
}

# pip 和模块检查都用选定环境的 python。还没选到，才退回系统 python3。
resolve_python() {
  if [[ -n "${CHOSE_VENV:-}" && -x "${CHOSE_VENV}/bin/python" ]]; then
    echo "${CHOSE_VENV}/bin/python"
    return
  fi
  if [[ -n "${PLANNED_VENV:-}" && -x "${PLANNED_VENV}/bin/python" ]]; then
    echo "${PLANNED_VENV}/bin/python"
    return
  fi
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

# 把包装进选定的虚拟环境。找不到 venv 时才 --user，并在 Debian 12+ 上补 --break-system-packages。
pip_install_pkgs() {
  local -a pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  local py
  py="$(resolve_python)"
  log "pip 目标: $py"
  if ! "$py" -m pip --version >/dev/null 2>&1; then
    warn "无 pip: $py"
    return 1
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

# 用选定环境的 python 试着 import，已有的包不再 pip 一次。
py_import_ok() {
  local mod="$1"
  "$(resolve_python)" -c "import $mod" >/dev/null 2>&1
}

# --status 和安装结束时都走这里。只看命令和模块在不在，不修改任何文件。
show_status() {
  local py exe
  py="$(resolve_python)"
  exe="$("$py" -c 'import sys; print(sys.executable)' 2>/dev/null || echo "$py")"
  echo "=== 运行时（右键读配置文件，不读 bashrc/zshrc）==="
  echo "  自定义路径: $CONFIG_FILE ($( [[ -f $CONFIG_FILE ]] && echo 存在 || echo 缺失 ))"
  echo "  HOME/venv: ${CHOSE_VENV:-${PLANNED_VENV:-$VENV_DIR}}"
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

# 一组「模块:包名」里，import 失败的才交给 pip。一组失败不中断下一组。
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

# 复制到文件管理器。scripts 是右键菜单，lib/Office 是脚本 source 的库。
# 不用 --delete，免得清掉用户自己放在 scripts 里的其它脚本。
# res/ 和 sample/ 只留在库里，不放进右键菜单。
install_nautilus_files() {
  local base="$TARGET_HOME/.local/share/nautilus"
  log "复制脚本到 $base"
  mkdir -p "$base/scripts" "$base/lib/Office"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' --exclude 'log' \
      "$SCRIPT_DIR/" "$base/lib/Office/"
    rsync -a --exclude 'res/' --exclude 'sample/' \
      "$SCRIPT_DIR/NautilusScripts/" "$base/scripts/"
  else
    cp -a "$SCRIPT_DIR/." "$base/lib/Office/"
    cp -a "$SCRIPT_DIR/NautilusScripts/." "$base/scripts/"
    rm -rf "$base/scripts/res" "$base/scripts/sample"
  fi
  find "$base/scripts" -type f ! -name '.*' -exec chmod +x {} \;
  if [[ "$(id -un)" != "$TARGET_USER" ]]; then
    chown -R "${TARGET_USER}:${TARGET_USER}" "$base"
  fi
  log "右键菜单: $base/scripts"
  log "脚本库:   $base/lib/Office"
}

# 安装结束后说明每一项以后去哪改。路径按这次的目标用户展开。
print_later_edits() {
  local venv_now="${CHOSE_VENV:-$PLANNED_VENV}"
  echo
  echo "以后要改这些参数，去下面的位置："
  echo
  echo "1. 虚拟环境目录（这次: ${venv_now:-尚未选择}）"
  echo "   锁定路径：编辑本脚本顶部 MANUAL_VENV_DIR，保存后再运行一次 ./0-Off-init.sh"
  echo "   只换以后终端和右键用的目录：编辑 $CONFIG_FILE ，里面一行绝对路径"
  echo "   临时指定一次、不改文件：PYTHON_VENV_DIR=/路径 ./0-Off-init.sh"
  echo
  echo "2. 新开终端自动启用"
  echo "   $TARGET_HOME/.bashrc"
  echo "   $TARGET_HOME/.zshrc"
  echo "   找标记 $SHELL_BEGIN 到 $SHELL_END 这一段"
  echo
  echo "3. 右键实际加载哪个环境"
  echo "   $TARGET_HOME/.local/share/nautilus/lib/Office/nautilus_env.sh"
  echo "   它读的是 $CONFIG_FILE ，其次是 $ACT_FILE"
  echo
  echo "4. 右键菜单和脚本库"
  echo "   菜单: $TARGET_HOME/.local/share/nautilus/scripts"
  echo "   库:   $TARGET_HOME/.local/share/nautilus/lib/Office"
  echo "   改的是仓库里的脚本时，重新运行本脚本才会复制过去"
  echo
  echo "5. 安装开关（本脚本顶部「可改参数」，命令行会盖过同名开关）"
  echo "   VENV_MODE=$VENV_MODE    auto/1 自动检测有就用；fixed/2 固定目录，没有就新建，有就沿用"
  echo "   FIXED_VENV_DIR=${FIXED_VENV_DIR:-（空，模式 2 用 ~/.PythonVenv）}"
  echo "   命令行: --venv-auto    或    --venv-fixed [目录]"
  echo "   WITH_NAUTILUS=$WITH_NAUTILUS    右键相关 apt。关掉: --without-nautilus"
  echo "   WITH_IMAGEGPS=$WITH_IMAGEGPS    ImageGPS 重依赖。打开: --with-imagegps"
  echo "   PYPI_INDEX=$PYPI_INDEX"
  echo "   临时换 pip 源: PYPI_INDEX_URL=地址 ./0-Off-init.sh"
  echo "   --apt-only  只装系统包    --py-only  只处理虚拟环境和 pip"
  echo "   --apt-py    额外 apt 装 python3-*    --yes  不问确认    --status  只检查"
  echo
  echo "6. 包名单（本脚本中部的数组）"
  echo "   APT_CORE  APT_SOFT  APT_NAUTILUS  APT_PY  APT_IMAGEGPS"
  echo "   PIP_CORE_MAP  PIP_IMAGEGPS_MAP"
  echo
}

# ---------- main ----------
# --status 只检测和检查，不写配置、不安装、不复制。
if [[ "$STATUS_ONLY" -eq 1 ]]; then
  report_venv_plan
  show_status
  print_later_edits
  exit 0
fi

echo "Office 依赖安装"
echo "  目录: $SCRIPT_DIR"
echo "  apt=$DO_APT  py=$DO_PY  apt-py=$APT_PY_EXTRA  nautilus=$WITH_NAUTILUS  imagegps=$WITH_IMAGEGPS  venv=$VENV_MODE"
echo

# 先把检测结果打出来，确认之前就能看到这次会用哪个环境。
report_venv_plan
if [[ "$DO_PY" -eq 0 ]]; then
  echo "本次 --apt-only，上面只是检测，不会创建或改写虚拟环境。"
  echo
fi

# 交互终端先确认。管道、脚本里调用必须带 --yes，否则直接退出。
if [[ "$ASSUME_YES" -eq 0 ]]; then
  if [[ ! -t 0 ]]; then
    die "非 TTY 请加 --yes"
  fi
  read -r -p "继续安装？[Y/n] " ans || true
  ans="${ans:-Y}"
  [[ "$ans" == [Yy]* ]] || { echo "已取消"; exit 0; }
fi

# 第 1 步：系统包。--py-only 时整段跳过。
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

# 第 2 步：选定虚拟环境，再补齐还缺的 Python 模块。--apt-only 时整段跳过。
if [[ "$DO_PY" -eq 1 ]]; then
  choose_venv
  pip_fill_map PIP_CORE_MAP
  if [[ "$WITH_IMAGEGPS" -eq 1 ]]; then
    pip_fill_map PIP_IMAGEGPS_MAP
  fi
fi

# 第 3 步：无论只装 apt 还是只装 Python，都把脚本同步到右键目录。
install_nautilus_files

echo
log "完成。可用 ./0-Off-init.sh --status 复查"
show_status
print_later_edits
