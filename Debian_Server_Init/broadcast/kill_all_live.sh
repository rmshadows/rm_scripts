#!/bin/bash
# 杀死进程名带“live.sh、ffmpeg、kplayer”的直播
kill -9 `ps -ef | grep live.sh | awk '{print $2}'`
kill -9 `ps -ef | grep ffmpeg | awk '{print $2}'`
kill -9 `ps -ef | grep kplayer | awk '{print $2}'`
# 检查 
ps aux | grep live.sh
ps aux | grep ffmpeg
ps aux | grep kplayer
