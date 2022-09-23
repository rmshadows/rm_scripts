#!/bin/bash
# 将视频和音频合并成成品视频    注意修改输入的视频、音频文件，以及**视频时长**！！
VIDEO_DURATION="01:30:00"
ffmpeg -an -i 1.MP4 -stream_loop -1 -i 1.mp3 -c:v copy -t "$VIDEO_DURATION" Task.MP4


