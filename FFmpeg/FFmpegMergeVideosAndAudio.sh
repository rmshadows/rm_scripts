#!/bin/bash
# 用一条音频替换视频原声，音频不够长时循环，成品长度默认等于视频。
#
# VIDEO_DURATION 留空：用 ffprobe 读取视频时长。
# 需要固定长度时再写成 01:30:00 或秒数。

VIDEO="1.MP4"
AUDIO="1.mp3"
OUTPUT="Task.MP4"
VIDEO_DURATION=""

set -euo pipefail

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
    echo "错误：需要 ffmpeg 和 ffprobe" >&2
    exit 1
fi
if [[ ! -f "$VIDEO" ]]; then
    echo "错误：找不到视频：$VIDEO" >&2
    exit 1
fi
if [[ ! -f "$AUDIO" ]]; then
    echo "错误：找不到音频：$AUDIO" >&2
    exit 1
fi

if [[ -z "$VIDEO_DURATION" ]]; then
    VIDEO_DURATION=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO")
    if [[ -z "$VIDEO_DURATION" || "$VIDEO_DURATION" == "N/A" ]]; then
        VIDEO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO")
    fi
    if [[ -z "$VIDEO_DURATION" || "$VIDEO_DURATION" == "N/A" ]]; then
        echo "错误：读不到视频时长：$VIDEO" >&2
        exit 1
    fi
    echo "视频时长：${VIDEO_DURATION} 秒"
fi

ffmpeg -an -i "$VIDEO" -stream_loop -1 -i "$AUDIO" -c:v copy -t "$VIDEO_DURATION" "$OUTPUT"
