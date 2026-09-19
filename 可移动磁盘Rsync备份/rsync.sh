#!/usr/bin/env bash
# 可移动磁盘 → 本地备份（镜像；备份侧 --delete）
# 个别文件出错会跳过并记日志，不中断整次备份（rsync 23/24）。
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
LONGNAME_PY="$SCRIPT_DIR/longname.py"
LOG_FILE=""
HAD_SOFT_ERRORS=0

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help)
      sed -n '2,10p' "$0"
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

if ! dir_nonempty "$RSRC"; then
  echo "[x] 源目录不存在或为空: $RSRC" >&2
  echo "    请确认可移动磁盘已挂载，并改 config.sh（或 BACKUP_SRC）" >&2
  exit 1
fi

mkdir -p "$RDST"
setup_run_log "$RDST" backup

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

log_line "[+] 备份: $RSRC  →  $RDST"
log_line "[+] 日志: $LOG_FILE"
[[ "$DRY_RUN" -eq 1 ]] && log_line "[!] dry-run，不写盘"
[[ "$VERBOSE" -eq 1 ]] && log_line "[!] verbose：会列出每个文件，大目录可能刷屏"

echo "[+] 检查目标文件名长度限制…（保留=${LONGNAME_KEEP}，安全上限=${LONGNAME_SAFE_MAX}）"
LN_ARGS=()
while IFS= read -r _ln_arg; do
  [[ -n "$_ln_arg" ]] && LN_ARGS+=("$_ln_arg")
done < <(longname_common_args)
PREPARE_OUT="$(python3 "$LONGNAME_PY" prepare "$RSRC" "$RDST" "${LN_ARGS[@]}" ${VERBOSE:+-v} 2>>"$LOG_FILE")" || true
echo "$PREPARE_OUT" | tee -a "$LOG_FILE"
NAME_MAX="$(echo "$PREPARE_OUT" | awk -F= '/^NAME_MAX=/{print $2; exit}')"
KEEP_USED="$(echo "$PREPARE_OUT" | awk -F= '/^KEEP=/{print $2; exit}')"
LONG_FILES="$(echo "$PREPARE_OUT" | awk -F= '/^LONG_FILES=/{print $2; exit}')"
EXCLUDE_FILE="${RDST%/}/.rsync-longnames/src.exclude"
PROTECT_FILE="${RDST%/}/.rsync-longnames/protect.filter"
if [[ -n "${LONG_FILES:-}" && "$LONG_FILES" -gt 0 ]]; then
  log_line "[!] 发现 $LONG_FILES 个超长路径（单分量上限=${NAME_MAX:-?}，截取=${KEEP_USED:-$LONGNAME_KEEP}），将自动缩短并记入映射表"
fi

RSYNC_EXTRA=()
[[ "$DRY_RUN" -eq 1 ]] && RSYNC_EXTRA+=(--dry-run)
if [[ "$VERBOSE" -eq 1 ]]; then
  RSYNC_EXTRA+=(-v)
elif [[ -t 1 ]]; then
  RSYNC_EXTRA+=(--info=progress2)
fi

RSYNC_LONG=()
RSYNC_LONG+=(--exclude=.rsync-longnames/ --exclude=.rsync-logs/)
if [[ -f "$EXCLUDE_FILE" && -s "$EXCLUDE_FILE" ]]; then
  RSYNC_LONG+=(--exclude-from="$EXCLUDE_FILE")
fi
if [[ -f "$PROTECT_FILE" && -s "$PROTECT_FILE" ]]; then
  RSYNC_LONG+=(--filter="merge $PROTECT_FILE")
fi

# stdout 进度仍上屏；stderr 错误同时进日志（不因单文件失败停整次）
rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXTRA[@]}" \
  "${RSYNC_EXCLUDES[@]}" \
  "${RSYNC_LONG[@]}" \
  --delete \
  "$RSRC" "$RDST" \
  2> >(tee -a "$LOG_FILE" >&2) &
RSYNC_PID=$!

ec=0
wait "$RSYNC_PID" || ec=$?
RSYNC_PID=""

if [[ "$ec" -eq 20 || "$ec" -eq 130 ]]; then
  log_line "[!] 已中断（可再跑本脚本续传）"
  exit 130
fi
if rsync_is_soft_exit "$ec"; then
  if [[ "$ec" -ne 0 ]]; then
    HAD_SOFT_ERRORS=1
    log_line "[!] rsync 部分文件跳过（退出码 $ec：23=部分出错，24=源文件消失）。详见日志，备份继续。"
  fi
else
  log_line "[x] rsync 严重失败，退出码 $ec"
  exit "$ec"
fi

# 预扫超长 + 日志里漏网的 File name too long，一并缩短拷贝
NEED_LONG=0
[[ -n "${LONG_FILES:-}" && "$LONG_FILES" -gt 0 ]] && NEED_LONG=1
if grep -q 'File name too long' "$LOG_FILE" 2>/dev/null; then
  NEED_LONG=1
fi

if [[ "$NEED_LONG" -eq 1 ]]; then
  log_line "[+] 处理超长文件名（含日志补抓）…"
  APPLY_ARGS=("$RSRC" "$RDST" "${LN_ARGS[@]}" --from-log "$LOG_FILE")
  [[ "$DRY_RUN" -eq 1 ]] && APPLY_ARGS+=(--dry-run)
  APPLY_OUT="$(python3 "$LONGNAME_PY" apply-backup "${APPLY_ARGS[@]}" 2>>"$LOG_FILE")" || true
  echo "$APPLY_OUT" | tee -a "$LOG_FILE"
  FAIL_N="$(echo "$APPLY_OUT" | awk -F= '/^LONGNAME_FAILED=/{print $2; exit}')"
  SALV_N="$(echo "$APPLY_OUT" | awk -F= '/^SALVAGE_FROM_LOG=/{print $2; exit}')"
  if [[ -n "${SALV_N:-}" && "$SALV_N" -gt 0 ]]; then
    log_line "[+] 从日志补抓到 $SALV_N 个超长名文件"
  fi
  if [[ -n "${FAIL_N:-}" && "$FAIL_N" -gt 0 ]]; then
    HAD_SOFT_ERRORS=1
    log_line "[!] 长文件名有 $FAIL_N 个失败，已跳过（见日志）"
  fi
fi

# 再扫一遍日志里是否已有 rsync: 错误行（长名已补抓的不再算未处理）
if grep -qE '^rsync: |^rsync error:' "$LOG_FILE" 2>/dev/null; then
  # 若仅剩 File name too long 且补抓成功，仍标软错误提示看日志，但不算中断
  HAD_SOFT_ERRORS=1
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  date -Iseconds >"${RDST%/}/rsync.time"
  log_line "[✓] 备份流程结束。时间戳: ${RDST%/}/rsync.time"
  if [[ "$NEED_LONG" -eq 1 ]]; then
    log_line "[✓] 长文件名映射: ${RDST%/}/.rsync-longnames/map.tsv"
  fi
else
  log_line "[✓] dry-run 结束"
fi

if [[ "$HAD_SOFT_ERRORS" -eq 1 ]]; then
  log_line "[!] 有文件被跳过或出错 —— 备份未整次中断（已尽量补拷长文件名）。请查看:"
  log_line "    $LOG_FILE"
  # 用 0 退出，方便 cron；软错误只靠日志/提示
  exit 0
fi
log_line "[✓] 全部顺利"
