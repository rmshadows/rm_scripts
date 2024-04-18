#!/bin/bash
# 将RAR压缩包移动到当前目录并解密
# 密码
Passwd=woh0Eiphoh7o
# 目标压缩文件
ZIP_NAME=earchive.zip
# 加密的压缩包位置(末尾记得带斜杠！)
AimPath=/home/username/
# 要加密的文件夹名称
DIR_NAME=Work

mv "$DIR_NAME" "$DIR_NAME"_bak
cp "$AimPath""$ZIP_NAME" "$ZIP_NAME"
unzip -P "$Passwd" "$ZIP_NAME"

