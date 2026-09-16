#!/usr/bin/env bash
# 可移动磁盘 → 本地备份（镜像；备份侧 --delete）
# 用法:
#   ./rsync.sh              # 用 config.sh 路径
#   ./rsync.sh --dry-run    # 只预览
#   BACKUP_SRC=/media/$USER/盘名/ BACKUP_DST=./盘Backup/ ./rsync.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
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

# 源必须存在且非空，否则 --delete 会清空备份
if ! dir_nonempty "$RSRC"; then
  echo "[x] 源目录不存在或为空: $RSRC" >&2
  echo "    请确认可移动磁盘已挂载，并改 config.sh（或 BACKUP_SRC）" >&2
  exit 1
fi

mkdir -p "$RDST"

# 锁必须在同步目标之外，否则 --delete 会删掉锁目录
LOCK_KEY="$(printf '%s\0%s' "$RSRC" "$RDST" | sha256sum | awk '{print $1}')"
LOCK_DIR="${TMPDIR:-/tmp}/rm-rsync-backup-${LOCK_KEY}.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "[x] 已有备份在跑（锁: $LOCK_DIR）。若异常退出可: rmdir $LOCK_DIR" >&2
  exit 1
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

echo "[+] 备份: $RSRC  →  $RDST"
[[ "$DRY_RUN" -eq 1 ]] && echo "[!] dry-run，不写盘"

RSYNC_EXTRA=()
[[ "$DRY_RUN" -eq 1 ]] && RSYNC_EXTRA+=(--dry-run)

rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXTRA[@]}" \
  "${RSYNC_EXCLUDES[@]}" \
  --delete \
  "$RSRC" "$RDST"

if [[ "$DRY_RUN" -eq 0 ]]; then
  date -Iseconds >"${RDST%/}/rsync.time"
  echo "[✓] 完成。时间戳: ${RDST%/}/rsync.time"
else
  echo "[✓] dry-run 结束（未修改备份目录）"
fi
