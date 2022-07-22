#!/bin/bash
kill -9 `ps -ef | grep _live.sh | awk '{print $2}'`
kill -9 `ps -ef | grep ffmpeg | awk '{print $2}'`
kill -9 `ps -ef | grep kplayer | awk '{print $2}'`
ps aux | grep _live.sh
ps aux | grep ffmpeg
ps aux | grep kplayer
