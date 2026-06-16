#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pdf_vector_to_size.py

脚本作用：
    递归处理 input/ 目录下所有 PDF，把每一页统一缩放并居中到指定纸张尺寸，
    输出到 output/ 目录，并保持原目录结构。

适用场景：
    - 文字型 PDF
    - Word / WPS / LibreOffice 导出的 PDF
    - 表格、公文、通知、报告
    - 需要统一页面尺寸，避免打印机自动缩放

处理方式：
    - 保留矢量内容，不转图片
    - 原页若不是目标尺寸，则按比例缩放后放入目标页面中央
    - 适合“清晰度优先”的场景

常用尺寸（单位：point）：
    A4      = 595.276 × 841.890
    A3      = 841.890 × 1190.551
    A5      = 419.528 × 595.276
    Letter  = 612.000 × 792.000
    Legal   = 612.000 × 1008.000

依赖：
    pip install pypdf
"""

from __future__ import annotations

import os
import sys
from typing import Dict, Tuple

try:
    from pypdf import PdfReader, PdfWriter, Transformation
except ImportError:
    try:
        from PyPDF2 import PdfReader, PdfWriter, Transformation
    except ImportError as exc:
        raise SystemExit("缺少依赖：pypdf 或 PyPDF2。请先执行：pip install pypdf") from exc


# ========= 内置参数 =========
INPUT_DIR = "input"
OUTPUT_DIR = "output"

# 目标纸张预设：A4 / A3 / A5 / Letter / Legal / Tabloid
TARGET_PAGE_NAME = "A4"

# 自定义纸张尺寸（单位：point）
# 如果这两个值都不为 None，则优先使用自定义尺寸。
# 常用尺寸：
#   A4      595.276 × 841.890
#   A3      841.890 × 1190.551
#   A5      419.528 × 595.276
#   Letter  612.000 × 792.000
#   Legal   612.000 × 1008.000
CUSTOM_TARGET_WIDTH_PT = None
CUSTOM_TARGET_HEIGHT_PT = None

# 页面四周留白（单位：point）
MARGIN_PT = 0.0

# 尺寸误差容忍值（单位：point）
SIZE_TOLERANCE_PT = 3.0

PAGE_SIZES: Dict[str, Tuple[float, float]] = {
    "A4": (595.276, 841.890),
    "A3": (841.890, 1190.551),
    "A5": (419.528, 595.276),
    "Letter": (612.000, 792.000),
    "Legal": (612.000, 1008.000),
    "Tabloid": (792.000, 1224.000),
}


def get_target_size(page_w: float, page_h: float) -> Tuple[float, float]:
    """
    根据页面方向获取目标尺寸。
    默认保持原页面方向：
        - 竖版页面 -> 竖版目标页
        - 横版页面 -> 横版目标页
    """
    if CUSTOM_TARGET_WIDTH_PT is not None and CUSTOM_TARGET_HEIGHT_PT is not None:
        return float(CUSTOM_TARGET_WIDTH_PT), float(CUSTOM_TARGET_HEIGHT_PT)

    base = PAGE_SIZES.get(TARGET_PAGE_NAME.upper())
    if base is None:
        raise ValueError(f"不支持的 TARGET_PAGE_NAME: {TARGET_PAGE_NAME}")

    base_w, base_h = base
    if page_w >= page_h:
        return base_h, base_w
    return base_w, base_h


def is_same_size(w1: float, h1: float, w2: float, h2: float, tol: float = SIZE_TOLERANCE_PT) -> bool:
    return abs(w1 - w2) <= tol and abs(h1 - h2) <= tol


def ensure_parent_dir(path: str) -> None:
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def process_pdf(input_path: str, output_path: str) -> None:
    """
    把 PDF 每页缩放并居中到目标纸张。
    不转图片，保留原始矢量内容。
    """
    with open(input_path, "rb") as f:
        reader = PdfReader(f)
        writer = PdfWriter()

        if getattr(reader, "is_encrypted", False):
            try:
                reader.decrypt("")
            except Exception:
                raise RuntimeError(f"PDF 可能已加密，无法处理：{input_path}")

        for page in reader.pages:
            # 尽量把页面旋转信息并入内容，避免宽高判断出错
            if hasattr(page, "transfer_rotation_to_content"):
                try:
                    page.transfer_rotation_to_content()
                except Exception:
                    pass

            src_w = float(page.mediabox.width)
            src_h = float(page.mediabox.height)
            target_w, target_h = get_target_size(src_w, src_h)

            # 如果页面本来就是目标尺寸，直接保留
            if is_same_size(src_w, src_h, target_w, target_h):
                writer.add_page(page)
                continue

            # 新建一个目标纸张的空白页
            blank = writer.add_blank_page(width=target_w, height=target_h)

            # 计算缩放与居中
            avail_w = target_w - 2 * MARGIN_PT
            avail_h = target_h - 2 * MARGIN_PT
            if avail_w <= 0 or avail_h <= 0:
                raise ValueError("MARGIN_PT 设置过大，导致可用区域非正数。")

            scale = min(avail_w / src_w, avail_h / src_h)
            new_w = src_w * scale
            new_h = src_h * scale
            offset_x = (target_w - new_w) / 2.0
            offset_y = (target_h - new_h) / 2.0

            # 先缩放，再平移
            page.add_transformation(Transformation().scale(scale).translate(offset_x, offset_y))

            # 合并到空白页
            blank.merge_page(page)

        ensure_parent_dir(output_path)
        with open(output_path, "wb") as out:
            writer.write(out)


def main() -> int:
    if not os.path.isdir(INPUT_DIR):
        print(f"输入目录不存在：{INPUT_DIR}", file=sys.stderr)
        return 1

    total = success = failed = 0

    for root, _, files in os.walk(INPUT_DIR):
        for name in files:
            if not name.lower().endswith(".pdf"):
                continue

            total += 1
            src = os.path.join(root, name)
            rel = os.path.relpath(src, INPUT_DIR)
            dst = os.path.join(OUTPUT_DIR, rel)

            try:
                print(f"处理：{rel}")
                process_pdf(src, dst)
                success += 1
            except Exception as e:
                failed += 1
                print(f"失败：{rel} -> {e}", file=sys.stderr)

    print()
    print(f"完成。总计 {total} 个 PDF，成功 {success} 个，失败 {failed} 个。")
    print(f"模式：vector")
    print(f"目标尺寸：{TARGET_PAGE_NAME}；自定义尺寸：{CUSTOM_TARGET_WIDTH_PT} × {CUSTOM_TARGET_HEIGHT_PT} pt")
    print(f"输出目录：{OUTPUT_DIR}")
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
