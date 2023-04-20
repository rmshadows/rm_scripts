#!/bin/bash
# 合并字幕
# 参考：链接：https://www.jianshu.com/p/a9b4f95c2d99

# 内嵌字幕（速度快，但播放器不一定支持）
ffmpeg -i 1.MP4 -i 1.srt -c:s mov_text -c:v copy -c:a copy SRT_OUT.MP4

# 硬字幕
# ffmpeg -i 1.MP4 -vf subtitles=1.srt:force_style='Fontsize=30\,FontName=FZYBKSJW--GB1-0' SRT_FORCE_OUT.MP4

