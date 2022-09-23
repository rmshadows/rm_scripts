#!/bin/bash
# 将RAR压缩包移动到当前目录并解密
# 密码
Passwd=7eiNhohmmoa4Guog
# 目标压缩文件
RAR_NAME=earchive.rar
# 加密的压缩包位置(末尾记得带斜杠！)
AimPath=/home/username/
# 要加密的文件夹名称
DIR_NAME=Work

mv "$DIR_NAME" "$DIR_NAME"_bak
cp "$AimPath""$RAR_NAME" "$RAR_NAME"
rar x -p$Passwd "$RAR_NAME"
