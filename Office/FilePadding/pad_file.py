#!/usr/bin/env python3
"""通用文件 padding：truncate / dd / disguise"""

from __future__ import annotations

import argparse
import os
import shutil
import sys

from pypdf import PdfReader, PdfWriter

from file_pad_common import (
    HEADER_SIZE,
    FillType,
    FileKind,
    PadMethod,
    build_disguise_tail,
    build_header,
    build_recovery_tail,
    detect_file_kind,
    generate_fill,
)
from pdf_pad_common import build_font_disguise_payload, build_tail_disguise_block, pick_font_attachment_name


def calc_target(current: int, mode: str, size_bytes: int) -> tuple[int, bool]:
    """返回 (目标大小, 是否需要处理)。"""
    if mode == "to":
        if current >= size_bytes:
            return current, False
        return size_bytes, True
    target = current + size_bytes
    return target, size_bytes > 0


def write_append_block(output_path: str, block: bytes) -> None:
    with open(output_path, "ab") as f:
        f.write(block)


def pad_truncate(
    input_path: str,
    output_path: str,
    target: int,
    fill_type: FillType,
    file_kind: FileKind,
) -> None:
    orig_size = os.path.getsize(input_path)
    pad_total = target - orig_size
    header = build_header(PadMethod.TRUNCATE, fill_type, orig_size, pad_total, file_kind)
    fill_size = pad_total - len(header)

    shutil.copy2(input_path, output_path)
    with open(output_path, "r+b") as f:
        f.truncate(target)
        f.seek(orig_size)
        f.write(header)
        if fill_size > 0:
            f.write(generate_fill(fill_size, fill_type))


def pad_dd(
    input_path: str,
    output_path: str,
    target: int,
    fill_type: FillType,
    file_kind: FileKind,
) -> None:
    orig_size = os.path.getsize(input_path)
    pad_total = target - orig_size
    header = build_header(PadMethod.DD, fill_type, orig_size, pad_total, file_kind)
    fill_size = pad_total - len(header)

    shutil.copy2(input_path, output_path)
    write_append_block(output_path, header)
    if fill_size > 0:
        write_append_block(output_path, generate_fill(fill_size, fill_type))


def _pdf_embed_expand(input_path: str, output_path: str, target: int, original: bytes) -> None:
    """PDF 伪装：嵌入 font 附件；末尾藏 recovery 块供还原。"""
    recovery = build_recovery_tail(original)
    budget = target - len(recovery)
    if budget <= len(original):
        raise ValueError("目标体积过小，无法容纳 PDF 伪装与 recovery 数据")

    font_name = pick_font_attachment_name(os.path.abspath(input_path))
    pad_size = max(budget - os.path.getsize(input_path) - 512, 0)

    for _ in range(30):
        reader = PdfReader(input_path)
        writer = PdfWriter()
        writer.append_pages_from_reader(reader)
        if reader.metadata:
            writer.add_metadata(reader.metadata)
        writer.add_attachment(font_name, build_font_disguise_payload(max(pad_size, 0)))
        with open(output_path, "wb") as f:
            writer.write(f)
        actual = os.path.getsize(output_path)
        if actual + len(recovery) >= target or actual >= budget:
            break
        pad_size += budget - actual

    write_append_block(output_path, recovery)


def pad_disguise(
    input_path: str,
    output_path: str,
    target: int,
    fill_type: FillType,
) -> None:
    with open(input_path, "rb") as f:
        original = f.read()
    orig_size = len(original)
    file_kind = detect_file_kind(input_path, original)
    pad_total = target - orig_size
    header = build_header(PadMethod.DISGUISE, FillType.FONT_LIKE, orig_size, pad_total, file_kind)
    body_size = pad_total - HEADER_SIZE

    if file_kind == FileKind.PDF:
        recovery = build_recovery_tail(original)
        if body_size > len(recovery) + 64:
            _pdf_embed_expand(input_path, output_path, target, original)
            return
        shutil.copy2(input_path, output_path)
        write_append_block(output_path, header)
        write_append_block(output_path, build_tail_disguise_block(body_size))
        return

    shutil.copy2(input_path, output_path)
    write_append_block(output_path, header)
    write_append_block(output_path, build_disguise_tail(file_kind, body_size))


def pad_one(
    input_path: str,
    output_path: str,
    method: str,
    mode: str,
    size_bytes: int,
    fill_type: str,
) -> str:
    current = os.path.getsize(input_path)
    target, need = calc_target(current, mode, size_bytes)

    os.makedirs(os.path.dirname(os.path.abspath(output_path)) or ".", exist_ok=True)

    if not need:
        shutil.copy2(input_path, output_path)
        return "skip"

    ft = FillType.ZERO if fill_type == "zero" else FillType.RANDOM
    fk = detect_file_kind(input_path)

    if method == "truncate":
        pad_truncate(input_path, output_path, target, ft, fk)
    elif method == "dd":
        pad_dd(input_path, output_path, target, ft, fk)
    elif method == "disguise":
        pad_disguise(input_path, output_path, target, ft)
    else:
        raise ValueError(f"未知 method: {method}")

    return "done"


def main() -> int:
    parser = argparse.ArgumentParser(description="通用文件 padding")
    parser.add_argument("--method", choices=("truncate", "dd", "disguise"), required=True)
    parser.add_argument("--mode", choices=("to", "by"), required=True)
    parser.add_argument("--size", type=int, required=True)
    parser.add_argument(
        "--fill",
        choices=("zero", "random"),
        default="zero",
        help="truncate/dd 模式的填充类型（disguise 自动）",
    )
    parser.add_argument("input_file")
    parser.add_argument("output_file")
    args = parser.parse_args()

    if not os.path.isfile(args.input_file):
        print(f"错误：文件不存在：{args.input_file}", file=sys.stderr)
        return 1

    try:
        result = pad_one(
            args.input_file,
            args.output_file,
            args.method,
            args.mode,
            args.size,
            args.fill,
        )
        print(result)
    except Exception as exc:
        print(f"错误：{exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
