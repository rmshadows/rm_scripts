#!/bin/bash
# 配置直播服务
# 请使用普通用户权限运行
# change1: $INSTALLL_PATH
# change2: $USER
# 安装文件夹路径 末尾不要 "/"

sudo apt install ffmpeg
sudo apt install gawk

# 安装文件夹路径 末尾不要 "/"
SET_BROADCAST_PATH="$HOME/Applications/broadcast"

dincludes=`ls`

for each in ${dincludes[@]}
do
    if [ -d "$each" ];then
        sed -i s#changeme_path#$SET_BROADCAST_PATH#g $each/*
        sed -i s#changeme_dir#$each#g $each/*
        sed -i s/changeme_user/$USER/g $each/*.service
    fi
done

