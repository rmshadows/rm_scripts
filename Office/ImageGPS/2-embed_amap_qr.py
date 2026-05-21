#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
直接运行即可：
    python embed_amap_qr.py

功能：
- 读取 gps_amap.tsv
- 使用 amap_url 生成 白底黑色 二维码
- 将二维码叠加到原图（不覆盖）
- 输出到镜像目录（保持子目录结构）
"""

# =======================
# 🔧 默认配置区（只改这里）
# =======================

TSV_FILE = "gps_amap.tsv"     # 输入 TSV
BASE_DIR = "."               # 图片基准目录
OUTPUT_DIR = "QR_OUT"        # 输出镜像目录

QR_SIZE_RATIO = 0.18         # 二维码占短边比例（0.15~0.25 都合理）
QR_POSITION = "bottom_right" # bottom_right / bottom_left / top_right / top_left / center
QR_MARGIN = 24               # 距离边缘像素

ADD_WHITE_PLATE = True       # 是否给二维码加白底托盘（强烈建议 True）
PLATE_PADDING = 12           # 白底托盘内边距

ONLY_STATUS_OK = True        # 只处理 status == OK 的行

# =======================
# 下面基本不用动
# =======================

import csv
from pathlib import Path
from PIL import Image, ImageOps
import qrcode


def make_qr(data: str) -> Image.Image:
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=2,
    )
    qr.add_data(data)
    qr.make(fit=True)
    return qr.make_image(
        fill_color="black",
        back_color="white"
    ).convert("RGB")


def qr_target_size(img_w, img_h):
    short = min(img_w, img_h)
    return max(80, int(short * QR_SIZE_RATIO))


def calc_pos(bg_w, bg_h, fg_w, fg_h):
    if QR_POSITION == "bottom_right":
        return bg_w - fg_w - QR_MARGIN, bg_h - fg_h - QR_MARGIN
    if QR_POSITION == "bottom_left":
        return QR_MARGIN, bg_h - fg_h - QR_MARGIN
    if QR_POSITION == "top_right":
        return bg_w - fg_w - QR_MARGIN, QR_MARGIN
    if QR_POSITION == "top_left":
        return QR_MARGIN, QR_MARGIN
    if QR_POSITION == "center":
        return (bg_w - fg_w) // 2, (bg_h - fg_h) // 2
    raise ValueError("未知 QR_POSITION")


def ensure_dir(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)


def process_image(img_path: Path, out_path: Path, amap_url: str):
    with Image.open(img_path) as im:
        im = ImageOps.exif_transpose(im)
        base = im.convert("RGB")
        w, h = base.size

        qr = make_qr(amap_url)
        size = qr_target_size(w, h)
        qr = qr.resize((size, size), Image.NEAREST)

        if ADD_WHITE_PLATE:
            plate = Image.new(
                "RGB",
                (size + PLATE_PADDING * 2, size + PLATE_PADDING * 2),
                "white"
            )
            plate.paste(qr, (PLATE_PADDING, PLATE_PADDING))
            overlay = plate
        else:
            overlay = qr

        x, y = calc_pos(w, h, overlay.width, overlay.height)
        base.paste(overlay, (x, y))

        ensure_dir(out_path)
        base.save(out_path, quality=95)


def main():
    tsv = Path(TSV_FILE)
    base_dir = Path(BASE_DIR)
    out_root = Path(OUTPUT_DIR)

    ok = fail = 0

    with tsv.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            try:
                if ONLY_STATUS_OK and row.get("status") != "OK":
                    continue

                rel = row["file"].strip()
                url = row["amap_url"].strip()

                src = (base_dir / rel).resolve()
                dst = (out_root / rel).resolve()

                if not src.exists():
                    raise FileNotFoundError(src)

                process_image(src, dst, url)
                ok += 1
                print(f"[OK] {rel}")
            except Exception as e:
                fail += 1
                print(f"[FAIL] {row.get('file')} -> {e}")

    print(f"\n完成：成功 {ok}，失败 {fail}")
    print(f"输出目录：{out_root.resolve()}")


if __name__ == "__main__":
    main()

