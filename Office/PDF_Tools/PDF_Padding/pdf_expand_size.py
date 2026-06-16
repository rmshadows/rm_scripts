#!/usr/bin/env python3
"""
PDF 文件体积扩大：方式1 尾部填充 / 方式4 嵌入附件（伪装为 font subset）

用法:
  pdf_expand_size.py --method pad|embed --mode to|by --size <bytes> input.pdf output.pdf
"""

import argparse
import os
import shutil
import sys

from pypdf import PdfReader, PdfWriter

from pdf_pad_common import (
    build_font_disguise_payload,
    build_tail_disguise_block,
    pick_font_attachment_name,
)


def expand_pad(input_path: str, output_path: str, add_bytes: int) -> None:
    """方式1：EOF 后追加伪装成 font subset cache 的二进制块。"""
    if add_bytes <= 0:
        shutil.copy2(input_path, output_path)
        return

    with open(input_path, "rb") as src, open(output_path, "wb") as dst:
        dst.write(src.read())
        dst.write(build_tail_disguise_block(add_bytes))


def expand_embed(input_path: str, output_path: str, target_bytes: int) -> None:
    """方式4：嵌入伪装成子集字体的附件 stream。"""
    current = os.path.getsize(input_path)
    if target_bytes <= current:
        shutil.copy2(input_path, output_path)
        return

    font_name = pick_font_attachment_name(os.path.abspath(input_path))
    pad_size = max(target_bytes - current - 512, 0)

    for _ in range(30):
        reader = PdfReader(input_path)
        writer = PdfWriter()
        writer.append_pages_from_reader(reader)

        if reader.metadata:
            writer.add_metadata(reader.metadata)

        writer.add_attachment(
            font_name,
            build_font_disguise_payload(pad_size),
        )

        with open(output_path, "wb") as f:
            writer.write(f)

        actual = os.path.getsize(output_path)
        if actual >= target_bytes:
            return

        pad_size += target_bytes - actual

    actual = os.path.getsize(output_path)
    if actual < target_bytes:
        with open(output_path, "ab") as f:
            f.write(build_tail_disguise_block(target_bytes - actual))


def main() -> int:
    parser = argparse.ArgumentParser(description="扩大 PDF 文件体积")
    parser.add_argument("--method", choices=("pad", "embed"), required=True)
    parser.add_argument("--mode", choices=("to", "by"), required=True)
    parser.add_argument("--size", type=int, required=True, help="目标/增量字节数")
    parser.add_argument("input_pdf")
    parser.add_argument("output_pdf")
    args = parser.parse_args()

    if not os.path.isfile(args.input_pdf):
        print(f"错误：输入文件不存在：{args.input_pdf}", file=sys.stderr)
        return 1

    if args.size < 0:
        print("错误：--size 不能为负数", file=sys.stderr)
        return 1

    current = os.path.getsize(args.input_pdf)

    if args.mode == "to":
        if current >= args.size:
            shutil.copy2(args.input_pdf, args.output_pdf)
            return 0
        target = args.size
        add_bytes = target - current
    else:
        target = current + args.size
        add_bytes = args.size

    os.makedirs(os.path.dirname(os.path.abspath(args.output_pdf)) or ".", exist_ok=True)

    if args.method == "pad":
        expand_pad(args.input_pdf, args.output_pdf, add_bytes)
    else:
        expand_embed(args.input_pdf, args.output_pdf, target)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
