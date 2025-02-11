#!/bin/bash
# 需要使用的Kplayer的配置
KCONF="config.json"
# global
play_model=random
# encode
video_width=780
video_height=480
video_fps=10
audio_channel_layout=3
audio_channels=2
bit_rate=0
avg_quality=19
# output
reconnect_internal=5
# 播放列表 将通过flists_file生成flists
flists_file="playlist.txt"
# 根据rtmp_file生成rtmp_url
rtmp_file="RTMP.txt"


if [[ -f "$rtmp_file" ]]; then
    flists=$(awk 'NR==1 {printf "    \"%s\"", $0; next} {printf ",\n                \"%s\"", $0} END {print ""}' "$flists_file")
    echo "读取到推流地址: $flists"
else
    echo "错误：文件 $flists_file 不存在！"
    exit 1
fi

# 确保文件存在
if [[ -f "$rtmp_file" ]]; then
    source "$rtmp_file"
    if [[ -z "$RTMP_ADDR" ]]; then
        echo "错误：RTMP_ADDR 未定义或为空！"
    fi
    rtmp_url="$RTMP_ADDR"
    echo "读取到推流地址: $rtmp_url"
else
    echo "错误：文件 $rtmp_file 不存在！"
    exit 1
fi
