#!/bin/bash
# 码率
BR="270k"
# 输入文件名
V_FILE="1.MP4"
# 输出文件名
OUTPUT_NAME="BOUT1.MP4"

ffmpeg -i "$V_FILE" -b:v "$BR" "$OUTPUT_NAME"
