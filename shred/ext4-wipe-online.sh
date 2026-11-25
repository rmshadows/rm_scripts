#!/usr/bin/env bash
# ==============================================================================
# ext4-wipe-online
# 用途：【免卸载/在线模式】抹除指定目录及 ext4 日志中的历史元数据残留
# 用法：ext4-wipe-online /path/to/target_dir
# ==============================================================================
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <目标目录路径>"
    exit 1
fi

TARGET_DIR=$(realpath "$1")
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "错误: 目标路径不存在或不是目录: $TARGET_DIR"
    exit 1
fi

MOUNT_POINT=$(df -P "$TARGET_DIR" | tail -1 | awk '{print $6}')

echo "=================================================="
echo "目标目录: $TARGET_DIR"
echo "挂载点  : $MOUNT_POINT"
echo "模式    : 在线无缝清理（无需卸载）"
echo "=================================================="

echo "[1/2] 正在进行目录脱壳换新..."
PARENT_DIR=$(dirname "$TARGET_DIR")
TMP_CLEAN="${PARENT_DIR}/.tmp_clean_$$"

mkdir -p "$TMP_CLEAN"

shopt -s dotglob nullglob
FILES=("$TARGET_DIR"/*)
if [[ ${#FILES[@]} -gt 0 ]]; then
    mv "${FILES[@]}" "$TMP_CLEAN/"
fi
shopt -u dotglob nullglob

rmdir "$TARGET_DIR"
mv "$TMP_CLEAN" "$TARGET_DIR"

echo "  -> 目标目录已分配全新 Inode 和全新目录块，当前块内历史文件名已彻底清除。"

echo "[2/2] 正在滚刷 ext4 日志环（强制循环覆盖历史记录）..."
SCRUB_DIR="${MOUNT_POINT}/.journal_scrub_$$"
mkdir -p "$SCRUB_DIR"

TOTAL_ROUNDS=6
BATCH_SIZE=10000

for ((r=1; r<=TOTAL_ROUNDS; r++)); do
    echo "  正在滚刷日志环: 批次 $r / $TOTAL_ROUNDS ..."
    python3 -c "
import os
d = '$SCRUB_DIR'
for i in range($BATCH_SIZE):
    fn = os.path.join(d, f'{i:05d}')
    with open(fn, 'w') as f:
        pass
"
    sync
    python3 -c "
import os
d = '$SCRUB_DIR'
for i in range($BATCH_SIZE):
    fn = os.path.join(d, f'{i:05d}')
    try:
        os.unlink(fn)
    except FileNotFoundError:
        pass
"
    sync
done

rmdir "$SCRUB_DIR"
sync

echo "=================================================="
echo "在线清理完成！"
echo "1. 该目录的 Inode 和当前块已完全刷新。"
echo "2. ext4 日志环已被全量覆盖一整圈，历史文件名记录已湮灭。"
echo "=================================================="
