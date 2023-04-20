#!/bin/bash
# 裁剪区间
FROM="00:00:00"
TO="00:02:07"
# 输入文件名
V_FILE="1.MP4"
# 输出文件名
OUTPUT_NAME="OUT1.MP4"

ffmpeg -ss "$FROM" -i "$V_FILE" -to "$TO" -vcodec copy -acodec copy "$OUTPUT_NAME"
# 下面这句效果一样，只是视频搜寻速度不同
# ffmpeg -i "$V_FILE" -ss "$FROM" -to "$TO" -vcodec copy -acodec copy "$OUTPUT_NAME"
# 如果上面那一句出错的话
# ffmpeg -i "$V_FILE" -ss "$FROM" -t "$TO" -c copy "$OUTPUT_NAME"

