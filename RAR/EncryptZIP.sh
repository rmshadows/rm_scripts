#!/bin/bash
# 将目标文件夹压缩并移动到目的的目录
# 密码
Passwd=woh0Eiphoh7o
# 目标文件夹
DIR_NAME=Work
# 生成的zip压缩包名
ZIP_NAME=earchive.zip
# 加密后要移动到的文件夹位置(末尾记得带斜杠！)
AimPath=/home/username/


zip -r -P "$Passwd" "$ZIP_NAME" "$DIR_NAME"

# 测试
unzip -t "$ZIP_NAME"

if [ "$?" -eq 0 ];then
    cp "$ZIP_NAME" "$AimPath""$ZIP_NAME" 
else
    echo "Something ERROR!"
fi

