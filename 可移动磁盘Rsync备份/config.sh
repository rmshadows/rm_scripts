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
