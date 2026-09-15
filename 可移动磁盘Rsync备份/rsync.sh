#!/bin/bash
# rsync备份可移动磁盘
# https://baijiahao.baidu.com/s?id=1767368490362524638&wfr=spider&for=pc
# rsync -aH -e ssh --delete --exclude Cache --link-dest=yesterdaystargetdir remote1:sourcedir todaystargetdir
set -euo pipefail

# 要备份的
RSRC="/media/$USER/xxx/"
# 装备份的文件夹
RDST="./xxxBackup/"

# 源目录必须存在且非空，否则跳过（避免 --delete 清空备份）
if [ ! -d "$RSRC" ] || [ -z "$(ls -A "$RSRC" 2>/dev/null)" ]; then
    echo "源目录不存在或为空: $RSRC，跳过备份" >&2
    exit 1
fi

mkdir -p "$RDST"

# -v: 显示传输的文件名（直观，和旧脚本一样能看到在传什么）
# --partial + --partial-dir: 断点续传，中断后重新运行可继续未完成的文件
# --stats: 结束时显示传输统计
# 不用 --info=progress2（回车刷新进度条会导致终端卡顿、Ctrl+C无响应）
rsync -aHv --numeric-ids --partial --partial-dir=.rsync-partial --stats \
    --exclude Cache --exclude '.Trash-*' --exclude 'lost+found' \
    --delete "$RSRC" "$RDST"

echo "$(date)" > rsync.time
