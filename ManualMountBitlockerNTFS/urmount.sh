#!/bin/bash
# 取消挂载
## 新建文件夹（挂载文件夹）
dislockMount="/home/bitlocker"
# 可访问的挂载点
readMount="/media/bitlockermount"

sudo umount "$readMount"
sleep 1
sudo umount "$dislockMount"

