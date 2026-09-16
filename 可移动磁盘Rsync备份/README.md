# 可移动磁盘 Rsync 备份 / 恢复

把 U 盘、移动硬盘上的目录**镜像**到本机；需要时再镜像回去。

## 使用前

1. 编辑 [`config.sh`](config.sh) 里的 `RSRC` / `RDST`（或用环境变量覆盖）
2. 确认可移动磁盘已挂载：`ls "/media/$USER/…"`

```bash
# 环境变量（可选，覆盖 config.sh）
export BACKUP_SRC="/media/$USER/MyDisk/"
export BACKUP_DST="./MyDiskBackup/"
```

## 备份（盘 → 本机）

```bash
./rsync.sh --dry-run    # 先预览
./rsync.sh              # 正式备份（--delete：备份目录与盘对齐）
```

- 源为空或不存在会**直接失败**（防止清空备份）
- 排除：`Cache`、`.Trash-*`、`lost+found`、`.rsync-partial`
- 时间戳写在备份目录：`$RDST/rsync.time`
- 互斥锁在 `/tmp`（不在备份目录里，避免被 `--delete` 删掉）

## 恢复（本机 → 盘）

```bash
./restore.sh --dry-run  # 先预览
./restore.sh            # 会要求输入 yes
./restore.sh --yes      # 跳过确认（脚本/cron）
```

- 备份为空或不存在会**中止**（防止 `--delete` 清空整盘）
- 目标盘目录必须已存在（已挂载）
- 与备份使用同一套 rsync 参数；本地不用 `-z`
- 默认**完整还原**（不排除 Cache 等）；只排除锁文件与时间戳、半成品目录
- 时间戳：`$RDST/restore.time`（在备份目录里）

## 注意

- **`--delete`**：目标上比源多的文件会被删。先 `--dry-run`。
- `sudo` 跑时路径用 `SUDO_USER` 的 `/media/用户名/...`，不要变成 `/media/root/...`。
- 注释里提到的 `--link-dest` 按日快照未实现；当前是单目录镜像，简单够用。
- 改完路径再跑；不要用示例里的 `xxx`。
