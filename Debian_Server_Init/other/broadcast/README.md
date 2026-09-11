# 服务器推流

> kplayer：https://github.com/bytelang/kplayer-go  
> 文档：https://docs.kplayer.net/v0.5.8/

## 怎么选

| 机器 | 用哪个 | 原因 |
|------|--------|------|
| **1G 内存（1Gram）** | **只用不重编码的 ffmpegL** | kplayer 会按 `avg_quality` 重编码，内存很容易打满 |
| 内存比较宽裕、要随机播放列表且接受重编码 | kplayer | 功能多，但比 ffmpeg copy 吃内存 |

ffmpegL 现在也能循环一个目录或播放列表（不再只能单个文件）。默认 `ENCODE=copy`（h264+aac 直接推，内存通常几十 MB）。源不是 FLV/RTMP 常用编码时，把 `conf.txt` 里改成 `ENCODE=light`（ultrafast 480p，仍比 kplayer 轻）。

## FFmpeg 推流（推荐，尤其是 1G）

```bash
cd ffmpegL
bash ffmpegL.sh          # 安装 ffmpegL-1、ffmpegL-2 …
# 把视频放到 ~/Applications/broadcast/videos
# 编辑实例目录里的 conf.txt（RTMP 地址）
sudo systemctl enable --now ffmpegL-1
journalctl -u ffmpegL-1 -f
```

`conf.txt` 素材优先级：`VIDEO_DIR`（目录）> `PLAYLIST`（每行一个路径）> `MP4_FILE`（单文件）。`ORDER=seq|shuffle`。

### CLI 控制（切歌 / 顺序 / 改地址）

安装后会有总入口 `~/Applications/broadcast/livectl`，也可以进实例目录跑 `./ctl.sh`。

```bash
livectl 1 status
livectl 1 list
livectl 1 next              # 下一首（会短暂重连 RTMP）
livectl 1 ff                # 快进 30 秒（copy 按关键帧对齐）
livectl 1 ff 60
livectl 1 rew 15
livectl 1 seek 1:30         # 当前片跳到 1 分 30 秒
livectl 1 seek +30
livectl 1 skip 3            # 从 1 开始数
livectl 1 set order seq     # 或 shuffle
livectl 1 set rtmp rtmp://host/app/key
livectl 1 set dir ~/Applications/broadcast/videos
livectl 1 set encode copy   # 或 light
livectl 1 reload            # 目录里新增视频后扫描
livectl 1 restart
```

日常循环用 concat 连播，少断流；next/prev/skip/快进/改编码才会重启 ffmpeg。copy 快进只能落到附近关键帧。

```bash
# 改推流地址
~/Applications/broadcast/ffmpegL-1/reset_rtmp.sh
# 或: livectl 1 set rtmp rtmp://...
# 卸掉这个实例的服务
~/Applications/broadcast/ffmpegL-1/removeServices.sh
```

systemd **默认不限制内存**。安装时会问要不要加 `MemoryMax`（1G 建议开）。以后也能：

```bash
sudo systemctl edit ffmpegL-1    # 或 kplayer-1
# 写入：
# [Service]
# MemoryMax=384M
```

## Kplayer 推流（内存要够）

1. 运行 `kplayer-go/download_kplayer-go.sh` 下载二进制。
2. 运行 `kplayer-go/kplayer-go.sh` 安装 `kplayer-N` 服务。
3. 改实例目录里的 `playlist.txt`、`RTMP.txt`，再按它自带的 `kconfig.sh` / 服务启动。

1G 机器不要装这个。安装时可选 `MemoryMax=512M`，避免打满拖死整机。

## 停掉本仓库装的直播

```bash
bash kill_all_live.sh    # 只停 ffmpegL-* / kplayer-*，不再 kill 系统里其它 ffmpeg
```

## 更新日志

- 2026.09.11——0.0.3
  - ffmpegL CLI：`livectl` 切下一首/上一首/跳号、seq|shuffle、set rtmp/dir/encode；服务内信号控制
  - systemd 内存上限改为安装时可选（默认不加）；`kill_all_live.sh` 不再误杀其它 ffmpeg
  - README 标明 kplayer 不适合 1G

- 2025.02.11——0.0.2
  - 重构

- 2022.11.26——0.0.1
  - 重新改版，正式发布
