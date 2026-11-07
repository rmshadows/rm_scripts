# 会议录音

这个目录用来处理会议录音。第一步是把长时间没人说话的段落压短，方便回听。静音只缩短，不剪掉，句子之间仍留着停顿。

## 压缩静音

依赖系统里的 `ffmpeg` 和 `ffprobe`。

```bash
./compress_silence.sh 会议.m4a
./compress_silence.sh --dry-run 会议.wav
./compress_silence.sh --speed 6 --max-pause 0.8 录音1.m4a 录音2.mp3
```

输出写在原文件旁边，文件名加 `_compressed`，格式是 `.m4a`。已存在时不覆盖，确认要替换再加 `-y`。

没有长静音时不写新文件。把 `MIN_SILENCE` 调小，或把 `NOISE_DB` 调到 `-35` 这类没那么低的值，可以让更多空隙被算进去。

## 默认参数

阈值写在 `compress_silence.sh` 顶部，改完即对以后每次生效。命令行只覆盖这一次。

| 脚本里的变量 | 命令行 | 默认 | 作用 |
| --- | --- | --- | --- |
| `NOISE_DB` | `--noise-db` | `-40` | 低于这个电平（dB）才算静音 |
| `MIN_SILENCE` | `--min-silence` | `0.80` | 短于这么多秒的空隙保持原速 |
| `SPEED` | `--speed` | `4` | 长静音的加快倍数 |
| `MIN_KEEP` | `--min-keep` | `0.35` | 压缩后这段静音至少留这么多秒 |
| `EDGE_PAD` | `--edge-pad` | `0.10` | 静音两端各留这么多秒原速，避免切到字头字尾 |
| `MAX_PAUSE` | `--max-pause` | `1.20` | 压缩后整段停顿的上限（秒）。`0` 表示只按倍数缩短 |
| `BITRATE` | `--bitrate` | `96k` | 输出 AAC 码率 |

`--dry-run` 只列出将要加速的时间段。
