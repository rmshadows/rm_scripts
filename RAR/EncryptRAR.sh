#!/bin/bash
# 将目标文件夹压缩并移动到目的的目录
# 密码
Passwd=7eiNhohmmoa4Guog
# 目标文件夹
DIR_NAME=Work
# 生成的rar压缩包名
RAR_NAME=earchive.rar
# 加密后要移动到的文件夹位置(末尾记得带斜杠！)
AimPath=/home/username/



rar a -p$Passwd "$RAR_NAME" "$DIR_NAME"
# 测试
rar t -p$Passwd "$RAR_NAME"
if [ "$?" -eq 0 ];then
    cp "$RAR_NAME" "$AimPath""$RAR_NAME" 
else
    echo "Something ERROR!"
fi

