#!/bin/bash
# 配置直播服务
# 请使用普通用户权限运行
# change1: $INSTALLL_PATH
# change2: $USER
# 安装文件夹路径 末尾不要 "/"
SET_BROADCAST_PATH="$HOME/Applications/broadcast/"

dincludes=`ls`

for each in ${dincludes[@]}
do
    if [ -d "$each" ];then
        sed -i s#changeme1#$SET_BROADCAST_PATH$each#g $each/*
        sed -i s/changeme2/$USER/g $each/*.service
    fi
done

