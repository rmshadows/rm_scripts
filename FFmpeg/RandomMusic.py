#!/usr/bin/env python3
"""按文件夹把音乐随机排序后拼成一个文件。文件夹内音频格式需一致。"""

import random
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# 音乐文件夹
MD = ["jazz1", "jazz2", "jazz3"]
# MD = ["waltz1", "waltz2", "waltz3"]
# MD = ["violin"]
# MD = ["梦乡1", "梦乡2"]
# 每个文件夹生成几份
MNUM = 2

AUDIO_EXTS = {".mp3", ".m4a", ".aac", ".wav", ".flac", ".ogg", ".opus", ".wma"}
# 内存缓存上限：2GB（2 * 1024 * 1024 * 1024 字节）。
# 文件夹里全是 MP3，而且总体积不超过这个数时，整夹读进内存，多份列表只读一次磁盘。
# 超过 2GB（如 Waltz、Jazz）就逐份从磁盘拼接，避免一次占用过多内存。
CACHE_LIMIT = 2 * 1024 * 1024 * 1024


def list_audio(folder: Path) -> list[Path]:
    files = [
        p
        for p in folder.iterdir()
        if p.is_file() and not p.name.startswith(".") and p.suffix.lower() in AUDIO_EXTS
    ]
    if not files:
        raise SystemExit(f"没有音频文件: {folder}")
    exts = {p.suffix.lower() for p in files}
    if len(exts) != 1:
        raise SystemExit(f"{folder} 里格式不统一: {', '.join(sorted(exts))}")
    return files


def strip_id3(data: bytes) -> bytes:
    """去掉首尾标签，只留下 MP3 帧，方便多首直接串起来。"""
    if len(data) >= 10 and data[:3] == b"ID3":
        size = (
            ((data[6] & 0x7F) << 21)
            | ((data[7] & 0x7F) << 14)
            | ((data[8] & 0x7F) << 7)
            | (data[9] & 0x7F)
        )
        end = 10 + size
        if data[3] == 4 and data[5] & 0x10:
            end += 10
        if end <= len(data):
            data = data[end:]
    if len(data) >= 128 and data[-128:-125] == b"TAG":
        data = data[:-128]
    return data


def output_path(folder: Path, ext: str, index: int) -> Path:
    stamp = datetime.now().strftime("%H%M%S%f")
    return Path(f"{folder.name}-{stamp}-{index}{ext}")


def write_playlist(files: list[Path], list_path: Path) -> None:
    lines = []
    for path in files:
        escaped = str(path.resolve()).replace("'", r"'\''")
        lines.append(f"file '{escaped}'")
    list_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_ffmpeg(cmd: list[str], payload: bytes | None = None) -> None:
    result = subprocess.run(cmd, input=payload, stderr=subprocess.PIPE)
    if result.returncode != 0:
        err = result.stderr.decode("utf-8", "replace").strip()
        raise SystemExit(f"ffmpeg 失败:\n{err}")


def concat_from_disk(files: list[Path], dest: Path) -> None:
    list_path = dest.with_suffix(".txt")
    write_playlist(files, list_path)
    run_ffmpeg(
        [
            "ffmpeg",
            "-y",
            "-nostdin",
            "-hide_banner",
            "-loglevel",
            "error",
            "-f",
            "concat",
            "-safe",
            "0",
            "-i",
            str(list_path),
            "-map",
            "0:a",
            "-c",
            "copy",
            str(dest),
        ]
    )


def concat_from_memory(blobs: list[bytes], dest: Path) -> None:
    run_ffmpeg(
        [
            "ffmpeg",
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-f",
            "mp3",
            "-i",
            "pipe:0",
            "-c",
            "copy",
            str(dest),
        ],
        payload=b"".join(blobs),
    )


def random_music(folder: Path, copies: int) -> None:
    files = list_audio(folder)
    ext = files[0].suffix.lower()
    total = sum(path.stat().st_size for path in files)
    cached = None
    if ext == ".mp3" and copies > 1 and total <= CACHE_LIMIT:
        cached = [strip_id3(path.read_bytes()) for path in files]
        print(f"{folder}: 读入 {len(files)} 首，{total / 1024 / 1024:.0f} MB，生成 {copies} 份")
    else:
        print(f"{folder}: {len(files)} 首，逐份从磁盘拼接，生成 {copies} 份")

    for index in range(1, copies + 1):
        order = files[:]
        random.shuffle(order)
        dest = output_path(folder, ext, index)
        write_playlist(order, dest.with_suffix(".txt"))
        print(dest)
        if cached is None:
            concat_from_disk(order, dest)
        else:
            by_name = {path.name: blob for path, blob in zip(files, cached)}
            concat_from_memory([by_name[path.name] for path in order], dest)
        print(f"完成 {dest}")


def main() -> None:
    if shutil.which("ffmpeg") is None:
        raise SystemExit("找不到 ffmpeg")
    folders = [Path(name) for name in (sys.argv[1:] or MD)]
    for folder in folders:
        if not folder.is_dir():
            print(f"跳过，找不到文件夹: {folder}", file=sys.stderr)
            continue
        random_music(folder, MNUM)


if __name__ == "__main__":
    main()
