#!/bin/bash
# 倍速
V_SPEED=5
# 输入文件名
V_FILE="1.MP4"
# 输出文件名
OUTPUT_NAME="OUT1.MP4"

VS=$((1/$V_SPEED))`echo "scale=1; 1 / $V_SPEED" | bc`
AS=`echo "scale=1; $V_SPEED / 1" | bc`

ffmpeg -i "$V_FILE" -filter_complex "[0:v]setpts="$VS"*PTS[v];[0:a]atempo="$AS"[a]" -map "[v]" -map "[a]" "$OUTPUT_NAME"

