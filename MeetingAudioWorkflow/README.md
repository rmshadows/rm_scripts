# 会议录音处理

方便回听，也方便丢给 vibe / 转写。静音只缩短不剪掉；后面可拉齐音量、降噪、转成 vibe 友好格式，长会再切段。

依赖系统里的 `ffmpeg` 和 `ffprobe`。

## 推荐用法（一条龙）

```bash
./run_workflow.sh 会议.m4a
./run_workflow.sh --denoise 会议.m4a          # 底噪明显再开
./run_workflow.sh --denoise --split 会议.m4a  # 再按 25 分钟切段
./run_workflow.sh -y --speed 6 会议.m4a       # -y 覆盖；多余选项传给压静音
```

默认顺序：

1. **压静音** → `原名_compressed.m4a`
2. **拉齐音量** → `原名_compressed_norm.m4a`
3. **准备 vibe** → `原名_compressed_norm_vibe.wav`（单声道 16 kHz）

加 `--denoise` 时，归一化后再出 `*_denoise.m4a`，再转 vibe。加 `--split` 时，在最终文件旁切出 `*_part001…`。

每一步结束都会打一段总结。压静音还会按每 2 秒看一次电平，列出较静、常见、较响三档；阈值偏了会给出一个 `--noise-db` 参考。没有长静音时不写新文件，后面步骤直接用原文件继续。

## 分步跑

```bash
./compress_silence.sh 会议.m4a
./normalize_loudness.sh 会议_compressed.m4a
./denoise.sh 会议_compressed_norm.m4a          # 可选
./prepare_vibe.sh 会议_compressed_norm.m4a
./split_chunks.sh --minutes 25 会议_compressed_norm_vibe.wav   # 可选
```

| 脚本 | 默认产物后缀 | 作用 |
| --- | --- | --- |
| `compress_silence.sh` | `_compressed.m4a` | 长静音加快，短停顿保留 |
| `normalize_loudness.sh` | `_norm.m4a` | loudnorm 拉齐音量 |
| `denoise.sh` | `_denoise.m4a` | 轻量降底噪（可不开） |
| `prepare_vibe.sh` | `_vibe.wav` | 单声道 16 kHz，给 vibe |
| `split_chunks.sh` | `_part001…` | 按时长切段 |
| `run_workflow.sh` | 串起上面几步 | 一条龙 |

输入格式：ffmpeg 能解的常见音频都可（m4a / mp3 / wav / flac 等）。中间步骤多输出 AAC `.m4a`；vibe 默认输出 `.wav`。

已存在同名输出时不覆盖，确认替换加 `-y`。

想边听边调静音参数时，用 `./preview_silence.py 会议.wav`。它在浏览器里打开，只压缩你选中的十几秒；滑块松开就同时给出原声和压过的声音。整段录音仍用页面底部给出的 `compress_silence.sh` 命令。

## 压静音参数

写在 `compress_silence.sh` 顶部，命令行只覆盖这一次。

| 变量 | 命令行 | 默认 | 作用 |
| --- | --- | --- | --- |
| `NOISE_DB` | `--noise-db` | `-40` | 低于这个电平（dB）才算静音 |
| `MIN_SILENCE` | `--min-silence` | `0.80` | 短于此时长的空隙保持原速 |
| `SPEED` | `--speed` | `4` | 静音中间放快几倍。4 约等于 4 秒收成 1 秒 |
| `MIN_KEEP` | `--min-keep` | `0.35` | 放快后至少还留这么多秒，避免两句话贴死 |
| `EDGE_PAD` | `--edge-pad` | `0.10` | 静音头尾各留这么多秒不加速，避免卷进字头字尾 |
| `MAX_PAUSE` | `--max-pause` | `1.20` | 压完后这段空白最长留这么多秒；`0` 不封顶 |
| `BITRATE` | `--bitrate` | `96k` | 成品音质。听内容 96k 够用，要更小改 64k |

`--dry-run` 只列出将要加速的时间段。

## 其他步骤要点

- **拉齐音量**：目标约 `-16` LUFS。人声忽大忽小时很有用。
- **降噪**：干净会议室别开。字头发糊就把 `denoise.sh` 里的 `NOISE_REDUCTION` 调小（如 `0.3`）。
- **prepare vibe**：默认 `1` 声道、`16000` Hz、`wav`。要更小文件可用 `./prepare_vibe.sh -f m4a`。
- **切段**：默认 25 分钟；短于一段的文件会跳过。
