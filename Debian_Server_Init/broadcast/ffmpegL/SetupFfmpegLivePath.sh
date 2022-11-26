#!/bin/bash
# 配置ffmpeg直播服务
# 请使用普通用户权限运行
# 如果脚本处于母文件夹，拒绝配置

# Manual
# 直播名称
STREAM_NAME="ffmpegLiveStream"

# 一般情况下，下面无需修改
# 默认当前用户
SETUP_USER=$USER
# ffmpeg母文件夹名称
MOTHER_DIR_NAME="ffmpegL"
# 自动获取路径
SET_BROADCAST_PATH=`pwd`
echo "Install path: $SET_BROADCAST_PATH"
PARENT_DIR_PATH=`dirname "$SET_BROADCAST_PATH"`
echo "Parent dir path: $PARENT_DIR_PATH"
CURRENT_INSTALL_DIR_NAME=`basename $SET_BROADCAST_PATH`
echo "Current install dir name: $CURRENT_INSTALL_DIR_NAME"

if [ "$CURRENT_INSTALL_DIR_NAME" == "$MOTHER_DIR_NAME" ]; then
  echo 'Error: Operation not allowed.Please do not operate in the parent folder.

  Please run the current script in a copy of the current folder! ' >&2
  exit 1
fi

# 检查命令
if ! [ -x "$(command -v ffmpeg)" ]; then
  echo 'Error: ffmpeg is not installed.' >&2
  sudo apt install ffmpeg
fi
if ! [ -x "$(command -v gawk)" ]; then
  echo 'Error: gawk is not installed.' >&2
  sudo apt install gawk
fi
# 遍历文件
dincludes=`ls`
for each in ${dincludes[@]}
do
  if [ -f "$each" ];then
    # 排除自身
    if ! [ "$each" == `basename $0` ];then 
        echo "Setup file: $each..."
        sed -i s#PARENT_DIR_PATH_CHANGEME#$PARENT_DIR_PATH#g $each
        sed -i s#STREAM_NAME_CHANGEME#$STREAM_NAME#g $each
        sed -i s#SET_BROADCAST_PATH_CHANGEME#$SET_BROADCAST_PATH#g $each
        sed -i s#SETUP_USER_CHANGEME#$SETUP_USER#g $each
    fi
  fi
done
chmod +x live.sh
cp ffmpeg_live.service.bak $STREAM_NAME.service




