#!/usr/bin/env bash
# 本地备份 → 可移动磁盘（恢复；默认 --delete）
# 个别文件出错会跳过并记日志，不中断整次恢复（rsync 23/24）。
# 用法:
#   ./restore.sh / ./restore.sh --dry-run / ./restore.sh --yes / ./restore.sh --verbose
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
LONGNAME_PY="$SCRIPT_DIR/longname.py"
LOG_FILE=""
HAD_SOFT_ERRORS=0

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "[x] 未知参数: $arg（见 --help）" >&2
      exit 2
      ;;
  esac
done

command -v rsync >/dev/null 2>&1 || { echo "[x] 需要 rsync：sudo apt install rsync" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "[x] 需要 python3（处理超长文件名）" >&2; exit 1; }
[[ -f "$LONGNAME_PY" ]] || { echo "[x] 找不到 $LONGNAME_PY" >&2; exit 1; }

if ! dir_nonempty "$SRC"; then
  echo "[x] 备份目录不存在或为空: $SRC" >&2
  exit 1
fi

if [[ ! -d "$DST" ]]; then
  echo "[x] 目标盘目录不存在: $DST" >&2
  exit 1
fi

# 日志写在备份目录侧，方便找
setup_run_log "$SRC" restore

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

log_line "[+] 恢复: $SRC  →  $DST"
log_line "[+] 日志: $LOG_FILE"
log_line "[!] 将使用 --delete：目标盘上多出来的文件也会被删，与备份对齐。"
[[ "$DRY_RUN" -eq 1 ]] && log_line "[!] dry-run，不写盘"
[[ "$VERBOSE" -eq 1 ]] && log_line "[!] verbose：会列出每个文件，大目录可能刷屏"

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
  --exclude=.rsync-longnames/ \
  --exclude=.rsync-logs/ \
  --exclude=rsync.time \
  --exclude=restore.time \
  --delete \
  "$SRC" "$DST" \
  2> >(tee -a "$LOG_FILE" >&2) &
RSYNC_PID=$!

ec=0
wait "$RSYNC_PID" || ec=$?
RSYNC_PID=""

if [[ "$ec" -eq 20 || "$ec" -eq 130 ]]; then
  log_line "[!] 已中断"
  exit 130
fi
if rsync_is_soft_exit "$ec"; then
  if [[ "$ec" -ne 0 ]]; then
    HAD_SOFT_ERRORS=1
    log_line "[!] rsync 部分文件跳过（退出码 $ec）。详见日志，恢复继续。"
  fi
else
  log_line "[x] rsync 严重失败，退出码 $ec"
  exit "$ec"
fi

if [[ -f "${SRC%/}/.rsync-longnames/map.tsv" ]]; then
  log_line "[+] 按映射表处理长文件名…（截取方向=${LONGNAME_KEEP}）"
  LN_ARGS=()
  while IFS= read -r _ln_arg; do
    [[ -n "$_ln_arg" ]] && LN_ARGS+=("$_ln_arg")
  done < <(longname_common_args)
  APPLY_ARGS=("$SRC" "$DST" "${LN_ARGS[@]}")
  [[ "$DRY_RUN" -eq 1 ]] && APPLY_ARGS+=(--dry-run)
  APPLY_OUT="$(python3 "$LONGNAME_PY" apply-restore "${APPLY_ARGS[@]}" 2>>"$LOG_FILE")" || true
  echo "$APPLY_OUT" | tee -a "$LOG_FILE"
  FAIL_N="$(echo "$APPLY_OUT" | awk -F= '/^LONGNAME_FAILED=/{print $2; exit}')"
  if [[ -n "${FAIL_N:-}" && "$FAIL_N" -gt 0 ]]; then
    HAD_SOFT_ERRORS=1
    log_line "[!] 长文件名还原有 $FAIL_N 个失败，已跳过（见日志）"
  fi
fi

if grep -qE '^rsync: |^rsync error:' "$LOG_FILE" 2>/dev/null; then
  HAD_SOFT_ERRORS=1
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  date -Iseconds >"${SRC%/}/restore.time"
  log_line "[✓] 恢复流程结束。时间戳: ${SRC%/}/restore.time"
else
  log_line "[✓] dry-run 结束"
fi

if [[ "$HAD_SOFT_ERRORS" -eq 1 ]]; then
  log_line "[!] 有文件被跳过或出错 —— 未整次中断。请查看:"
  log_line "    $LOG_FILE"
  exit 0
fi
log_line "[✓] 全部顺利"
