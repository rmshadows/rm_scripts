#!/bin/bash

: '
此脚本用于批量将当前目录下所有 .m3u8 格式的视频播放列表文件转换成 .mp4 视频文件。
转换过程中不进行重新编码，速度快且无损。
转换完成后，输出同名的 .mp4 文件。

使用方法：
  直接在包含 .m3u8 文件的目录执行此脚本即可。

依赖：
  需要已安装 ffmpeg，且其路径已添加至系统环境变量。
'

# 遍历当前目录下所有 .m3u8 文件
for file in *.m3u8; do
    # 判断文件是否存在（防止找不到匹配）
    [ -e "$file" ] || continue

    # 获取不带扩展名的文件名
    filename="${file%.m3u8}"
    output="${filename}.mp4"

    echo "正在转换: $file → $output"

    # 使用 ffmpeg 进行转换（不重新编码）
    ffmpeg -allowed_extensions ALL -i "$file" -c copy -bsf:a aac_adtstoasc "$output"

    # 检查转换是否成功
    if [ $? -eq 0 ]; then
        echo "✅ 转换成功: $output"
    else
        echo "❌ 转换失败: $file"
    fi

    echo "----------------------------"
done

echo "🎉 所有转换任务完成。"
