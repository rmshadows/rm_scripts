#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
修复乱码文件名工具（Windows ↔ Linux 文件系统编码差异）

✨ 使用说明：
--------------------------------------------------------
本工具用于修复由于文件系统编码不同导致的中文文件名乱码问题。

✅ 默认行为：
    假设你是在 Linux 上看到乱码（原始为 Windows 系统 GBK 文件名），
    自动尝试将文件名从 "乱码" ➜ 正常中文。

📦 使用方法：
    # 仅预览不改名（默认）
    python3 fix_filenames.py --path /your/folder

    # 实际执行重命名
    python3 fix_filenames.py --path /your/folder --apply

    # 从 Linux → Windows 方向修复（原始为 UTF-8，误当 GBK）
    python3 fix_filenames.py --direction linux2win --apply

🛠 参数说明：
    --path       要处理的目录，默认为当前目录 .
    --direction  修复方向：win2linux（默认）、linux2win
    --apply      执行实际重命名操作（不加则只预览）

📌 支持 Linux/macOS 环境，Python 3.6+
--------------------------------------------------------
"""

import os
import argparse

def looks_like_garbled(text):
    # 简单规则判断乱码：包含异常 ASCII 字符
    return any(ord(c) > 126 or ord(c) < 32 for c in text)

def try_fix_filename(filename, direction='win2linux'):
    try:
        if direction == 'win2linux':
            raw = filename.encode('latin1')
            fixed = raw.decode('gbk')
        elif direction == 'linux2win':
            raw = filename.encode('latin1')
            fixed = raw.decode('utf-8')
        else:
            return None
        return fixed
    except Exception:
        return None

def fix_directory_filenames(directory='.', direction='win2linux', dry_run=True):
    print(f"\n📂 正在扫描目录：{os.path.abspath(directory)}")
    print(f"🔁 解码方向：{'Windows ➜ Linux' if direction == 'win2linux' else 'Linux ➜ Windows'}")
    print(f"🔎 模式：{'仅预览（dry-run）' if dry_run else '实际重命名'}\n")

    for filename in os.listdir(directory):
        if not looks_like_garbled(filename):
            continue

        fixed_name = try_fix_filename(filename, direction)
        if fixed_name and fixed_name != filename:
            src = os.path.join(directory, filename)
            dst = os.path.join(directory, fixed_name)
            if os.path.exists(dst):
                print(f"⚠ 已存在目标名，跳过：{fixed_name}")
                continue

            print(f"✔ {filename} ➜ {fixed_name}")
            if not dry_run:
                os.rename(src, dst)
        else:
            print(f"❌ 无法转换：{filename}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='修复乱码文件名（Windows ↔ Linux 编码差异）')
    parser.add_argument('--path', type=str, default='.', help='要处理的文件夹路径')
    parser.add_argument('--direction', choices=['win2linux', 'linux2win'], default='win2linux', help='转换方向')
    parser.add_argument('--apply', action='store_true', help='执行重命名（默认仅预览）')

    args = parser.parse_args()
    fix_directory_filenames(directory=args.path, direction=args.direction, dry_run=not args.apply)
