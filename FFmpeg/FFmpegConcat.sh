#!/bin/bash
# 合并视频 注意音频采样率！
INPUT_FILE="2.txt"
ffmpeg -f concat -safe 0 -i "$INPUT_FILE" Concat.mp4


