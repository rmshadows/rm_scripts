# FFmpeg辅助工具

# 文件列表

## FfmpegCut.sh

裁剪视频、音频文件

原理：`ffmpeg -ss 00:00:00 -to 00:01:00 -i input.mp4 -vcodec copy -acodec copy output.mp4`

## FFmpegFilesTxt.py

生成`ffmpeg -f concat -i file_list.txt -c copy OUT.MP4`合并视频、音频需要的文件列表。如：

```
file '1.MP4'
file '2.MP4'
file '3.MP4'
```

## RandomMusic.py

根据所给文件夹，生成随机音乐列表(**请保证文件夹中的音乐文件格式统一**！！)

## FFmpegMergeVideosAndAudio.sh

将视频和音频合并成成品视频

注意修改输入的视频、音频文件，以及**视频时长**！！

`ffmpeg -an -i input_video.MP4 -stream_loop -1 -i input_audio.mp3 -c:v copy -t 1:23:50 output.MP4`

## GenerateCover

生成视频封面

## FFmpegAppendSRT

添加字幕

## FfmpegBitrate

修改码率

## FFmpegConcat

>注意视频的音频采样率要一致

合并视频

## FFmpegAudioSampleRate

修改视频的音频采样率

## ConcatMTS

合并当前文件夹中所有的MTS文件

## MP42MTS

当前文件夹中所有MP4扩展名的文件转为MTS

## MTS2MP4

当前文件夹中所有MTS扩展名的文件转为MP4

# 我的视频处理流程

1. `FfmpegCut.sh`裁剪视频(裁剪去不需要的内容)
2. `FFmpegFilesTxt.py`生成合并视频需要的文件(合并分块视频)，然后用脚本最后给的命令合并
3. `RandomMusic.py`合并音频(生成随机音乐文件)
4. `FFmpegMergeVideosAndAudio.sh`合并音频和视频(视频的原有音频会被替换)

# 更新日志

- 20230719——0.0.4
  - 新增音频采样率工具

- 20230111——0.0.3
  - 新增码率工具

- 20221107——0.0.2
  - 新增封面工具
- 20220902——0.0.1
  - 初版















