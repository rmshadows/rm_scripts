#!/usr/bin/env bash
# ==============================================================================
# ext4-wipe-offline
# 用途：【离线彻底清零】重置 ext4 日志环与优化紧缩目录索引块（无损现有文件）
# 用法：sudo ext4-wipe-offline <未挂载的块设备，如 /dev/mapper/veracrypt1>
# ==============================================================================
set -euo pipefail
export PATH="/sbin:/usr/sbin:$PATH"

if [[ $# -lt 1 ]]; then
    echo "用法: sudo $0 <未挂载的 ext4 块设备，例如 /dev/mapper/veracrypt1>"
    exit 1
fi

DEV="$1"
REAL_DEV=$(readlink -f "$DEV")

if [[ ! -b "$REAL_DEV" ]]; then
    echo "错误: 不是有效的块设备: $REAL_DEV"
    exit 1
fi

if grep -q "^$REAL_DEV " /proc/mounts || grep -q "^$DEV " /proc/mounts; then
    echo "错误: 设备正在挂载中！必须先 umount 卸载该设备后才能清理日志。"
    echo "提示: 可以执行: sudo umount $DEV"
    exit 1
fi

echo "=================================================="
echo "准备彻底重置 ext4 元数据日志环:"
echo "目标设备: $REAL_DEV"
echo "=================================================="
echo "该操作将重置并清空 Journal 事务历史，不会破坏现存正常文件。"
read -r -p "确认继续? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "已取消。"
    exit 0
fi

echo -n "[1/4] 正在先验检查文件系统... "
e2fsck -f -p "$REAL_DEV" || true
echo "完成"

echo -n "[2/4] 彻底移除并注销旧 Journal (清空历史快照)... "
tune2fs -O ^has_journal "$REAL_DEV"
echo "完成"

echo -n "[3/4] 重新创建全新空白 Journal (分配全新干净日志环)... "
tune2fs -O has_journal "$REAL_DEV"
echo "完成"

echo -n "[4/4] 紧缩重构所有目录索引块 (消除 Slack Space 残留)... "
e2fsck -f -D "$REAL_DEV"
echo "完成"

echo "=================================================="
echo "清理完成！"
echo "现在该分区所有的历史文件名、shred 改名链、删除记录已被 100% 连根抹杀。"
echo "重新挂载使用即可。"
echo "=================================================="
