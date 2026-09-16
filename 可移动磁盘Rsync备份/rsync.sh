#!/usr/bin/env bash
# 可移动磁盘 → 本地备份（镜像；备份侧 --delete）
# 用法:
#   ./rsync.sh              # 用 config.sh 路径
#   ./rsync.sh --dry-run    # 只预览
#   ./rsync.sh --verbose    # 列出每个文件（大目录慎用，会刷屏）
#   BACKUP_SRC=/media/$USER/盘名/ BACKUP_DST=./盘Backup/ ./rsync.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

DRY_RUN=0
VERBOSE=0
RSYNC_PID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help)
      sed -n '2,9p' "$0"
      exit 0
      ;;
    *)
      echo "[x] 未知参数: $arg（见 --help）" >&2
      exit 2
      ;;
  esac
done

command -v rsync >/dev/null 2>&1 || { echo "[x] 需要 rsync：sudo apt install rsync" >&2; exit 1; }

if ! dir_nonempty "$RSRC"; then
  echo "[x] 源目录不存在或为空: $RSRC" >&2
  echo "    请确认可移动磁盘已挂载，并改 config.sh（或 BACKUP_SRC）" >&2
  exit 1
fi

mkdir -p "$RDST"

LOCK_KEY="$(printf '%s\0%s' "$RSRC" "$RDST" | sha256sum | awk '{print $1}')"
LOCK_DIR="${TMPDIR:-/tmp}/rm-rsync-backup-${LOCK_KEY}.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "[x] 已有备份在跑（锁: $LOCK_DIR）。若异常退出可: rmdir $LOCK_DIR" >&2
  exit 1
fi

cleanup() {
  local ec=$?
  if [[ -n "${RSYNC_PID:-}" ]] && kill -0 "$RSYNC_PID" 2>/dev/null; then
    kill -TERM "$RSYNC_PID" 2>/dev/null || true
    wait "$RSYNC_PID" 2>/dev/null || true
  fi
  rmdir "$LOCK_DIR" 2>/dev/null || true
  return "$ec"
}
on_signal() {
  echo >&2
  echo "[!] 收到中断，正在停止 rsync…" >&2
  if [[ -n "${RSYNC_PID:-}" ]] && kill -0 "$RSYNC_PID" 2>/dev/null; then
    kill -TERM "$RSYNC_PID" 2>/dev/null || true
    wait "$RSYNC_PID" 2>/dev/null || true
  fi
  rmdir "$LOCK_DIR" 2>/dev/null || true
  exit 130
}
trap cleanup EXIT
trap on_signal INT TERM HUP

echo "[+] 备份: $RSRC  →  $RDST"
[[ "$DRY_RUN" -eq 1 ]] && echo "[!] dry-run，不写盘"
[[ "$VERBOSE" -eq 1 ]] && echo "[!] verbose：会列出每个文件，大目录可能刷屏"

RSYNC_EXTRA=()
[[ "$DRY_RUN" -eq 1 ]] && RSYNC_EXTRA+=(--dry-run)
if [[ "$VERBOSE" -eq 1 ]]; then
  RSYNC_EXTRA+=(-v)
elif [[ -t 1 ]]; then
  # 仅真实终端开单行进度；管道/日志里开会刷爆输出
  RSYNC_EXTRA+=(--info=progress2)
fi

# 后台跑 + wait：Ctrl+C 能立刻进 trap，不会被海量输出拖死
rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXTRA[@]}" \
  "${RSYNC_EXCLUDES[@]}" \
  --delete \
  "$RSRC" "$RDST" &
RSYNC_PID=$!

ec=0
wait "$RSYNC_PID" || ec=$?
RSYNC_PID=""

# 20 = 用户中断；其它非 0 失败
if [[ "$ec" -eq 20 || "$ec" -eq 130 ]]; then
  echo "[!] 已中断（可用 --partial 续传，直接再跑本脚本）" >&2
  exit 130
fi
if [[ "$ec" -ne 0 ]]; then
  echo "[x] rsync 失败，退出码 $ec" >&2
  exit "$ec"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  date -Iseconds >"${RDST%/}/rsync.time"
  echo "[✓] 完成。时间戳: ${RDST%/}/rsync.time"
else
  echo "[✓] dry-run 结束（未修改备份目录）"
fi
