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
./rsync.sh              # 正式备份（默认单行进度，不刷文件名）
./rsync.sh --verbose    # 列出每个文件（大目录慎用，终端会卡）
```

- 源为空或不存在会**直接失败**（防止清空备份）
- 排除：`Cache`、`.Trash-*`、`lost+found`、`.rsync-partial`
- **超长文件名**：按保守上限缩短（默认单分量 180 字节，比 `NAME_MAX=255` 更严），映射表在 `$RDST/.rsync-longnames/map.tsv`；rsync 日志里漏网的 `File name too long` 会再补抓拷贝
- **截取方向**（`config.sh` 或环境变量 `LONGNAME_KEEP`）：
  - `head`（默认）：保留文件名**前部** + `_` + 8 位哈希 + 扩展名
  - `tail`：保留文件名**后部**（靠近文号/扩展名）+ 哈希
- 还可调：`LONGNAME_SAFE_MAX`（默认 180）、`LONGNAME_SAFE_PATH`（整路径上限，默认 900）
- 时间戳写在备份目录：`$RDST/rsync.time`
- 互斥锁在 `/tmp`（不在备份目录里，避免被 `--delete` 删掉）
- **Ctrl+C**：会停掉 rsync 并清锁；已传完的文件保留，再跑可续传（`--partial`）
- **出错跳过**：个别文件失败（rsync 退出码 23/24）**不中断**整次备份，流程仍会跑完并尽量补拷长名；错误写入 `$RDST/.rsync-logs/`（`latest-backup.log`）。看到「有文件被跳过」≠ 整次停掉

## 恢复（本机 → 盘）

```bash
./restore.sh --dry-run  # 先预览
./restore.sh            # 会要求输入 yes
./restore.sh --yes      # 跳过确认（脚本/cron）
```

- 备份为空或不存在会**中止**（防止 `--delete` 清空整盘）
- 目标盘目录必须已存在（已挂载）
- 与备份使用同一套 rsync 参数；本地不用 `-z`
- 若有长名映射：目标文件系统够长时**自动还原原文件名**
- 时间戳：`$RDST/restore.time`（在备份目录里）
- 同样：**单文件错误跳过 + 记日志**（`$RDST/.rsync-logs/latest-restore.log`）

## 注意

- **`--delete`**：目标上比源多的文件会被删。先 `--dry-run`。
- 不同文件系统文件名长度不同；可移动盘上即便报 `NAME_MAX=255`，中文长名仍可能被拒，故默认用更严的 `LONGNAME_SAFE_MAX=180`。
- 部分文件仍可能因权限、坏块等失败：会跳过并写进 `.rsync-logs/`，**整次备份照样算完成**（退出码 0）。跑完看一眼日志即可。
- 想保留文号在文件名末尾可见：`LONGNAME_KEEP=tail ./rsync.sh`
- `sudo` 跑时路径用 `SUDO_USER` 的 `/media/用户名/...`，不要变成 `/media/root/...`。
- 改完路径再跑；不要用示例里的 `xxx`。
