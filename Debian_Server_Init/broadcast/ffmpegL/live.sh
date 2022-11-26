#!/bin/bash
cd SET_BROADCAST_PATH_CHANGEME/
source conf.txt
echo Start Living....
echo "$RTMP"
echo "$MP4_FILE"

st=`date`
echo "$st 开始推流">> stream.log
ffmpeg -re -stream_loop -1 -i "$MP4_FILE" -vcodec copy -acodec copy -f flv -flvflags no_duration_filesize "$RTMP"&

# Adv -r 帧率 -b 比特率
# ffmpeg -re -stream_loop -1 -i "$MP4_FILE" -r 10 -b 10k -f flv -flvflags no_duration_filesize "$RTMP"&
#while true
#do
#    ffmpeg -re -i "1.mp4" -stream_loop -1 -vcodec copy -acodec copy -f flv "$RTMP_ADDR"
#done
