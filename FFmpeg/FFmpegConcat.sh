#!/bin/bash
# 合并当前文件夹里同一扩展名的全部文件，不进入子目录。
#
# 用法：
#   ./FFmpegConcat.sh          使用下面的 EXT
#   ./FFmpegConcat.sh mp4      临时改扩展名
#
# 扩展名不区分大小写：mp4 会包含 .mp4 和 .MP4。
# 按文件名自然排序（1、2、10）。已存在的输出文件不会被再次合并进去。
# -c copy 要求这些文件的编码、分辨率、音频采样率一致。

EXT="MP4"

set -euo pipefail

if [[ $# -ge 1 ]]; then
    EXT="$1"
fi
ext="${EXT#.}"
if [[ -z "$ext" || "$ext" == */* || "$ext" == *.* ]]; then
    echo "错误：扩展名不合法：$EXT" >&2
    exit 1
fi

OUTPUT="Concat.${ext}"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "错误：未找到 ffmpeg" >&2
    exit 1
fi

list=$(mktemp)
trap 'rm -f "$list"' EXIT

count=0
while IFS= read -r -d '' path; do
    base=$(basename "$path")
    if [[ "$base" == "$OUTPUT" ]]; then
        continue
    fi
    full="$PWD/$base"
    escaped=${full//\'/\'\\\'\'}
    printf "file '%s'\n" "$escaped" >> "$list"
    count=$((count + 1))
done < <(find . -maxdepth 1 -type f -iname "*.${ext}" ! -name '.*' -print0 | sort -zV)

if [[ "$count" -eq 0 ]]; then
    echo "当前文件夹没有 .${ext} 文件。" >&2
    exit 1
fi

echo "将按此顺序合并 ${count} 个 .${ext} 文件到 ${OUTPUT}："
while IFS= read -r -d '' path; do
    base=$(basename "$path")
    [[ "$base" == "$OUTPUT" ]] && continue
    echo "  $base"
done < <(find . -maxdepth 1 -type f -iname "*.${ext}" ! -name '.*' -print0 | sort -zV)

ffmpeg -f concat -safe 0 -i "$list" -c copy "$OUTPUT"
