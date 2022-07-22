#!/bin/bash
cd changeme_path/changeme_dir
source bilibili.txt
echo Living
echo "$RTMP"
echo "$MP4_FILE"

ffmpeg -re -stream_loop -1 -i "$MP4_FILE" -vcodec copy -acodec copy -f flv -flvflags no_duration_filesize "$RTMP"&
# Adv -r 帧率 -b 比特率
# ffmpeg -re -stream_loop -1 -i "$MP4_FILE" -r 10 -b 10k -f flv -flvflags no_duration_filesize "$RTMP"&

