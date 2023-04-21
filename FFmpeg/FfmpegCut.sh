#!/bin/bash
# 裁剪区间
FROM="00:00:00"
TO="00:02:07"
# 输入文件名
V_FILE="1.MP4"
# 输出文件名
OUTPUT_NAME="OUT1.MP4"

ffmpeg -i "$V_FILE" -ss "$FROM" -to "$TO" -vcodec copy -acodec copy "$OUTPUT_NAME"
# 如果上面那一句出错的话
# ffmpeg -i "$V_FILE" -ss "$FROM" -t "$TO" -c copy "$OUTPUT_NAME"

