#!/usr/bin/env python3
"""检测并还原 padding 文件"""

from __future__ import annotations

import argparse
import os
import sys

from file_pad_common import (
    PadInfo,
    fill_label,
    kind_label,
    method_label,
    parse_recovery_tail,
    scan_pad_info,
)


def human_size(num: int) -> str:
    if num >= 1024 ** 3:
        return f"{num / 1024 ** 3:.2f}G"
    if num >= 1024 ** 2:
        return f"{num / 1024 ** 2:.2f}M"
    if num >= 1024:
        return f"{num / 1024:.2f}K"
    return f"{num}B"


def format_info(info: PadInfo) -> str:
    if not info.is_padded:
        return f"[无 padding] {info.path} ({human_size(info.file_size)})"

    lines = [
        f"[有 padding] {info.path} ({human_size(info.file_size)})",
        f"  文件类型 : {kind_label(info.file_kind)}",
        f"  原始大小 : {human_size(info.orig_size) if info.orig_size else '未知'}",
        f"  padding  : {human_size(info.pad_total)}",
        f"  方式     : {method_label(info.method)}",
        f"  填充     : {fill_label(info.fill_type)}",
        f"  可还原   : {'是' if info.recoverable else '否（旧版 PDF padding）'}",
    ]
    return "\n".join(lines)


def restore_file(input_path: str, output_path: str, info: PadInfo) -> None:
    if not info.recoverable:
        raise ValueError("该文件无法自动还原（缺少 recovery 元数据）")

    with open(input_path, "rb") as f:
        data = f.read()

    if info.recovery_via == "tail_block":
        rec = parse_recovery_tail(data)
        if not rec:
            raise ValueError("recovery 块损坏")
        _orig_len, original = rec
        payload = original
    elif info.recovery_via == "header":
        payload = data[: info.orig_size]
    else:
        raise ValueError("不支持的 recovery 类型")

    os.makedirs(os.path.dirname(os.path.abspath(output_path)) or ".", exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(payload)


def main() -> int:
    parser = argparse.ArgumentParser(description="检测/还原 padding 文件")
    parser.add_argument("target", help="文件或目录")
    parser.add_argument("--restore", action="store_true", help="执行还原（需配合 --output-dir）")
    parser.add_argument("--output-dir", default="output", help="还原输出目录")
    parser.add_argument("--yes", action="store_true", help="不询问，直接还原所有可还原文件")
    parser.add_argument("--check-only", action="store_true", help="仅检测")
    args = parser.parse_args()

    targets: list[str] = []
    if os.path.isfile(args.target):
        targets = [args.target]
    elif os.path.isdir(args.target):
        for root, _, files in os.walk(args.target):
            for name in sorted(files):
                targets.append(os.path.join(root, name))
    else:
        print(f"错误：路径不存在：{args.target}", file=sys.stderr)
        return 1

    if not targets:
        print("未找到文件", file=sys.stderr)
        return 1

    padded_count = 0
    restored = 0

    print("========== Padding 检测 / 还原 ==========")
    print(f"路径 : {args.target}\n")

    for path in targets:
        info = scan_pad_info(path)
        print(format_info(info))
        print()

        if not info.is_padded:
            continue
        padded_count += 1

        if args.check_only or not args.restore:
            continue

        if not info.recoverable:
            print(f"  >> 跳过：无法还原\n")
            continue

        do_restore = args.yes
        if not do_restore:
            try:
                ans = input(f"  是否还原 {path} ? [y/N] ").strip().lower()
            except EOFError:
                ans = "n"
            do_restore = ans in ("y", "yes")

        if not do_restore:
            print("  >> 已取消\n")
            continue

        rel = os.path.relpath(path, args.target) if os.path.isdir(args.target) else os.path.basename(path)
        out_path = os.path.join(args.output_dir, rel)
        os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
        restore_file(path, out_path, info)
        restored += 1
        print(f"  >> 已还原 -> {out_path}\n")

    print("========== 完成 ==========")
    print(f"总文件数     : {len(targets)}")
    print(f"有 padding   : {padded_count}")
    if args.restore:
        print(f"已还原       : {restored}")

    return 1 if padded_count else 0


if __name__ == "__main__":
    raise SystemExit(main())
