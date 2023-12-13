#!/bin/bash
# rsync备份可移动磁盘
# https://baijiahao.baidu.com/s?id=1767368490362524638&wfr=spider&for=pc
# rsync -aH -e ssh --delete --exclude Cache --link-dest=yesterdaystargetdir remote1:sourcedir todaystargetdir
# 要备份的
RSRC="/media/$USER/xxx/"
# 装备份的文件夹
RDST="./xxxBackup/"
# 除外的目录
# REXC="/media/$USER/xxx/file"
rsync -avzH --delete "$RSRC" "$RDST"
# rsync -avzH --delete --exclude "$REXC" "$RSRC" "$RDST"
echo `date` > rsync.time
