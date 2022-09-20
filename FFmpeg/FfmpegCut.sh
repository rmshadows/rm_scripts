#!/bin/bash
# 裁剪区间
FROM="00:00:00"
TO="00:02:07"
# 输入文件名
V_FILE="1.MP4"
# 输出文件名
OUTPUT_NAME="OUT1.MP4"

ffmpeg -ss "$FROM" -to "$TO" -i "$V_FILE" -vcodec copy -acodec copy "$OUTPUT_NAME"



