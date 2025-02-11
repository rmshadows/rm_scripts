# 服务器推流配置

>https://github.com/bytelang/kplayer-go
>
>https://docs.kplayer.net/v0.5.8/

## 使用方法

首先确认服务器配置，配置高的使用kplayer，配置低的请使用ffmpeg推流。目前ffmpeg推流仅支持推流单个文件。

## FFmpeg推流

1. 复制`ffmpegL`母文件夹为新文件夹：`XX直播`
2. 编辑`SetupFfmpegLivePath.sh`文件中的直播名称为`XX直播`
3. 运行`SetupFfmpegLivePath.sh`脚本自动配置
4. 如需生成服务，运行`Install_Servces.sh`或者手动拷贝到`systemd`的目录即可

## Kplayer推流

1. 运行`download_kplayer.sh`下载kplayer(版本号可以自行修改)，运行结束会生成一个`kplayer`母文件夹。
2. 复制母文件夹到新的副本(这样原来这个母文件夹可以作为更新kplayer用): `XX直播`
3. 将`kplayer_files`中的文件拷贝到你创建的副本文件夹`XX直播`中
4. 修改并运行`SetupKplayerPath.sh`脚本，会创建一个`.service`文件，后可自行配置成服务

## Update Log

- 2025.02.11——0.0.2
  - 重构

- 2022.11.26——0.0.1
  - 重新改版，正式发布







