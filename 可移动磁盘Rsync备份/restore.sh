#!/usr/bin/env bash
# 本地备份 → 可移动磁盘（恢复；默认 --delete，会让盘与备份一致）
# 用法:
#   ./restore.sh              # 用 config.sh 路径（会确认）
#   ./restore.sh --dry-run    # 只预览
#   ./restore.sh --yes        # 跳过确认
#   ./restore.sh --verbose    # 列出每个文件（大目录慎用）
#   BACKUP_SRC=... BACKUP_DST=... ./restore.sh
#
# 注意：这里 RSRC=备份目录，RDST=可移动盘（与 rsync.sh 方向相反）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

SRC="$RDST"
DST="$RSRC"

DRY_RUN=0
ASSUME_YES=0
VERBOSE=0
RSYNC_PID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "[x] 未知参数: $arg（见 --help）" >&2
      exit 2
      ;;
  esac
done

command -v rsync >/dev/null 2>&1 || { echo "[x] 需要 rsync：sudo apt install rsync" >&2; exit 1; }

if ! dir_nonempty "$SRC"; then
  echo "[x] 备份目录不存在或为空: $SRC" >&2
  echo "    恢复会带 --delete，空备份会清空目标盘，已中止。" >&2
  exit 1
fi

if [[ ! -d "$DST" ]]; then
  echo "[x] 目标盘目录不存在: $DST" >&2
  echo "    请先挂载可移动磁盘，并确认 config.sh 路径。" >&2
  exit 1
fi

LOCK_KEY="$(printf '%s\0%s' "$SRC" "$DST" | sha256sum | awk '{print $1}')"
LOCK_DIR="${TMPDIR:-/tmp}/rm-rsync-restore-${LOCK_KEY}.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "[x] 已有恢复在跑（锁: $LOCK_DIR）。若异常退出可: rmdir $LOCK_DIR" >&2
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

echo "[+] 恢复: $SRC  →  $DST"
echo "[!] 将使用 --delete：目标盘上多出来的文件也会被删，与备份对齐。"
[[ "$DRY_RUN" -eq 1 ]] && echo "[!] dry-run，不写盘"
[[ "$VERBOSE" -eq 1 ]] && echo "[!] verbose：会列出每个文件，大目录可能刷屏"

if [[ "$DRY_RUN" -eq 0 && "$ASSUME_YES" -eq 0 ]]; then
  if [[ ! -t 0 ]]; then
    echo "[x] 非交互请加 --yes 或先 --dry-run" >&2
    exit 1
  fi
  read -r -p "确认恢复到可移动盘？输入 yes 继续: " ans || true
  if [[ "${ans:-}" != "yes" ]]; then
    echo "已取消"
    exit 0
  fi
fi

RSYNC_EXTRA=()
[[ "$DRY_RUN" -eq 1 ]] && RSYNC_EXTRA+=(--dry-run)
if [[ "$VERBOSE" -eq 1 ]]; then
  RSYNC_EXTRA+=(-v)
elif [[ -t 1 ]]; then
  RSYNC_EXTRA+=(--info=progress2)
fi

rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXTRA[@]}" \
  --exclude=.rsync-partial \
  --exclude=rsync.time \
  --exclude=restore.time \
  --delete \
  "$SRC" "$DST" &
RSYNC_PID=$!

ec=0
wait "$RSYNC_PID" || ec=$?
RSYNC_PID=""

if [[ "$ec" -eq 20 || "$ec" -eq 130 ]]; then
  echo "[!] 已中断" >&2
  exit 130
fi
if [[ "$ec" -ne 0 ]]; then
  echo "[x] rsync 失败，退出码 $ec" >&2
  exit "$ec"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  date -Iseconds >"${SRC%/}/restore.time"
  echo "[✓] 完成。时间戳: ${SRC%/}/restore.time"
else
  echo "[✓] dry-run 结束（未修改目标盘）"
fi
