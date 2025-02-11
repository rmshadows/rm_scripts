#!/bin/bash
# 裁剪区间
FROM="00:00:00"
TO="00:00:40"
DUR="00:1:0"
# 输入文件名
V_FILE="1.MP4"
# 输出文件名
OUTPUT_NAME="OUT1.MP4"

ffmpeg -i "$V_FILE" -ss "$FROM" -to "$TO" -vcodec copy -acodec copy "$OUTPUT_NAME"
# 如果上面那一句出错的话
# ffmpeg -i "$V_FILE" -ss "$FROM" -t "$TO" -c copy "$OUTPUT_NAME"

# DUR是持续时间(用于快速剪辑，但不精确)
# ffmpeg -ss "$FROM" -i "$V_FILE" -to "$DUR" -c copy -avoid_negative_ts 1 "$OUTPUT_NAME"
# 绝对精确（如果上面的偏移了）
# ffmpeg -i "$V_FILE" -ss "$FROM" -to "$TO" -c:v libx264 -preset ultrafast -c:a aac -b:a 128k "$OUTPUT_NAME"


