#!/bin/bash
ffmpeg -an -i 1.MP4 -stream_loop -1 -i 1.mp3 -c:v copy -t 1:23:50 an.MP4



