#!/bin/bash
# 音频重新采样率
INPUT_FILE="1.MP4"
AR="44100"
ffmpeg -i "$INPUT_FILE" -ac 1 -ar "$AR" -vcodec copy AR.MP4


