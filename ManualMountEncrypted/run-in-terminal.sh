#!/bin/bash
# 在「某个终端窗口」里跑命令，跑完关窗。给快捷键用，不绑死业务脚本。
#
# 用法:
#   ./run-in-terminal.sh [/选项…] <命令> [参数…]
#
# 选项（也可仍用环境变量 HOLD / TERM_CMD）:
#   -t, --term <终端>   指定终端，如 xterm、gnome-terminal
#   -H, --hold          跑完按回车再关（看出错）
#   -h, --help          帮助
#
# 例:
#   ./run-in-terminal.sh /path/to/mountV
#   ./run-in-terminal.sh -t xterm /path/to/mountV
#   ./run-in-terminal.sh --term gnome-terminal --hold /path/to/mountV
#   ./run-in-terminal.sh -t xterm -- bash -lc 'cd /opt && ./mountB'
#
# 未指定 --term / TERM_CMD 时自动找；Debian 优先 x-terminal-emulator。
set -u

HOLD="${HOLD:-1}"
TERM_CMD="${TERM_CMD:-}"

die() { echo "[x] $*" >&2; exit 1; }

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -H|--hold)
      HOLD=1
      shift
      ;;
    -t|--term)
      [[ $# -ge 2 ]] || die "$1 需要参数，例如: $1 xterm"
      TERM_CMD="$2"
      shift 2
      ;;
    --term=*)
      TERM_CMD="${1#--term=}"
      [[ -n "$TERM_CMD" ]] || die "--term= 后面要写终端名"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "未知选项: $1（见 --help）"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -ge 1 ]] || { usage; exit 1; }

# 把相对路径收成绝对，避免终端启动后 cwd 不是你以为的目录
absolutize_cmd() {
  local c="$1"
  if [[ "$c" == /* ]]; then
    printf '%s' "$c"
    return
  fi
  if [[ "$c" == */* || -e "$c" || -e "./$c" ]]; then
    local dir base
    dir="$(cd "$(dirname "$c")" 2>/dev/null && pwd)" || { printf '%s' "$c"; return; }
    base="$(basename "$c")"
    printf '%s/%s' "$dir" "$base"
    return
  fi
  printf '%s' "$c"
}

pick_terminal() {
  local t
  if [[ -n "${TERM_CMD}" ]]; then
    if [[ "$TERM_CMD" == /* ]]; then
      [[ -x "$TERM_CMD" ]] || die "--term/TERM_CMD 不可执行: $TERM_CMD"
      printf '%s' "$TERM_CMD"
      return
    fi
    command -v "$TERM_CMD" >/dev/null 2>&1 || die "终端不在 PATH: $TERM_CMD"
    command -v "$TERM_CMD"
    return
  fi
  for t in x-terminal-emulator gnome-terminal xfce4-terminal mate-terminal \
           konsole lxterminal tilix kitty alacritty xterm rxvt urxvt; do
    if command -v "$t" >/dev/null 2>&1; then
      command -v "$t"
      return
    fi
  done
  die "未找到终端。请安装 xterm，或加: --term xterm"
}

first="$(absolutize_cmd "$1")"
shift
q_cmd="$(printf '%q' "$first")"
for a in "$@"; do
  q_cmd+=" $(printf '%q' "$a")"
done

if [[ "$HOLD" == "1" ]]; then
  INNER="${q_cmd}; ec=\$?; echo; echo \"[结束，退出码 \$ec]\"; read -r -p '按回车关闭…' _"
else
  INNER="${q_cmd}"
fi
RUNNER=(bash -lc "$INNER")
TERM_BIN="$(pick_terminal)"
TERM_NAME="$(basename "$TERM_BIN")"
[[ "$TERM_NAME" == gnome-terminal.wrapper ]] && TERM_NAME=x-terminal-emulator

case "$TERM_NAME" in
  gnome-terminal|gnome-terminal.real)
    exec "$TERM_BIN" -- "${RUNNER[@]}"
    ;;
  *)
    exec "$TERM_BIN" -e "${RUNNER[@]}"
    ;;
esac
