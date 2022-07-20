#!/bin/bash
# 转发RTMP直播流
# https://sonnati.wordpress.com/2011/08/30/ffmpeg-%e2%80%93-the-swiss-army-knife-of-internet-streaming-%e2%80%93-part-iv/
cd changeme1
source RepostLive.txt
echo Reposting
echo "$RTMP_S"
echo "$RTMP_D"

ffmpeg -i "$RTMP_S" -c:a copy -c:v libx264 -vpre slow -f flv "$RTMP_D"
