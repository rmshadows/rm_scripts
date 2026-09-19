#!/usr/bin/env bash
# 可移动磁盘 rsync 共用配置 —— 只改这里的路径即可
# 由 rsync.sh / restore.sh source，勿直接执行。

# 挂载用户（sudo 时用真实用户，避免 /media/root/...）
MEDIA_USER="${SUDO_USER:-${USER:-$(id -un)}}"

# ========== 按需修改 ==========
# 要备份的可移动磁盘目录（末尾 / 表示同步「内容」）
RSRC="${BACKUP_SRC:-/media/${MEDIA_USER}/xxx/}"
# 本地备份目录（相对当前目录或绝对路径均可）
RDST="${BACKUP_DST:-./xxxBackup/}"
# ==============================

# 备份时排除（恢复默认不排除，完整还原）
RSYNC_EXCLUDES=(
  --exclude=Cache
  --exclude='.Trash-*'
  --exclude=lost+found
  --exclude=.rsync-partial
)

# ---------- 超长文件名 ----------
# head=保留前部（标题开头）；tail=保留后部（文号/扩展名附近）
LONGNAME_KEEP="${LONGNAME_KEEP:-head}"
# 比 NAME_MAX 更严的安全上限（可移动盘上 255 仍可能拒收中文长名）
LONGNAME_SAFE_MAX="${LONGNAME_SAFE_MAX:-180}"
# 目标绝对路径总长度上限（字节）
LONGNAME_SAFE_PATH="${LONGNAME_SAFE_PATH:-900}"
# 手动指定单分量上限；0=自动（检测值与 SAFE_MAX 取小）
LONGNAME_LIMIT="${LONGNAME_LIMIT:-0}"

longname_common_args() {
  # 打印到 stdout，供调用方：readarray / 手动拼进数组
  printf '%s\n' --keep "$LONGNAME_KEEP" --safe-max "$LONGNAME_SAFE_MAX" --safe-path "$LONGNAME_SAFE_PATH"
  if [[ "${LONGNAME_LIMIT:-0}" -gt 0 ]]; then
    printf '%s\n' --limit "$LONGNAME_LIMIT"
  fi
}

# 默认安静：不要 -v（大目录刷屏会让终端假死、Ctrl+C 像失灵）
# -aH: 归档+硬链接  --numeric-ids: 数值 uid/gid
# --partial + --partial-dir: 断点续传
# --stats: 结束统计
# 进度：仅在终端里开 --info=progress2（见 rsync.sh / restore.sh）
RSYNC_OPTS=(
  -aH
  --numeric-ids
  --partial
  --partial-dir=.rsync-partial
  --human-readable
  --stats
)

dir_nonempty() {
  local d="$1" first
  [[ -d "$d" ]] || return 1
  first="$(find "$d" -mindepth 1 -print -quit 2>/dev/null || true)"
  [[ -n "$first" ]]
}

# rsync 退出码：0 成功；23 部分文件出错；24 源文件中途消失 —— 都继续，不当整次失败
rsync_is_soft_exit() {
  case "$1" in
    0|23|24) return 0 ;;
    *) return 1 ;;
  esac
}

# 在目标备份目录下建日志；把说明写到 stdout，细节进日志
setup_run_log() {
  local root="$1" kind="$2"
  LOG_DIR="${root%/}/.rsync-logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="${LOG_DIR}/${kind}-$(date +%Y%m%d-%H%M%S).log"
  ln -sfn "$(basename "$LOG_FILE")" "${LOG_DIR}/latest-${kind}.log"
  {
    echo "==== ${kind} $(date -Iseconds) ===="
    echo "RSRC=$RSRC"
    echo "RDST=$RDST"
    echo
  } >"$LOG_FILE"
}

log_line() {
  printf '%s\n' "$*" | tee -a "${LOG_FILE:-/dev/null}"
}
