#!/bin/bash
# rsync恢复可移动磁盘
# https://baijiahao.baidu.com/s?id=1767368490362524638&wfr=spider&for=pc
# rsync -aH -e ssh --delete --exclude Cache --link-dest=yesterdaystargetdir remote1:sourcedir todaystargetdir
RSRC="./xxxBackup/"
RDST="/media/$USER/xxx/"
# REXC="/media/$USER/xxx/file"
rsync -avzH --delete "$RSRC" "$RDST"
# rsync -avzH --delete --exclude "$REXC" "$RSRC" "$RDST"
echo `date` > restore.time
