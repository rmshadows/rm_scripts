#!/bin/bash
cd changeme
source bilibili.txt
# source inke.txt
echo Living
echo "$RTMP"
# 视频文件
MP4_FILE="xxx.mp4"

ffmpeg -re -stream_loop -1 -i "$MP4_FILE" -vcodec copy -acodec copy -f flv -flvflags no_duration_filesize "$RTMP"&

