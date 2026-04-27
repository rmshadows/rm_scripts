#!/usr/bin/python3
"""
PDF文件旋转（支持方向 / 输出目录 / 是否删除原文件）
"""

import os
import argparse
import shutil
import m_PDF
import m_Log

# ============================================================
# 默认配置
# ============================================================

targetDir = "input"
rotation_angle = 270


# ============================================================
# 参数解析
# ============================================================

parser = argparse.ArgumentParser(add_help=False)

parser.add_argument("direction", nargs="?", default=None)
parser.add_argument("-o", "--output", dest="output_dir", default=None)
parser.add_argument("-d", "--delete", action="store_true")

args = parser.parse_args()

# 方向
if args.direction:
    arg = args.direction.lower()
    if arg == "r":
        rotation_angle = 90
    elif arg == "l":
        rotation_angle = 270
    elif arg == "u":
        rotation_angle = 180
    else:
        raise ValueError("仅支持 r / l / u")

output_dir = args.output_dir
delete_original = args.delete


# ============================================================
# 日志
# ============================================================

enable_log = False
log_path = "运行日志.log"
m_Log.init_logger(enable_file=enable_log, log_path=log_path)


# ============================================================
# 主程序
# ============================================================

if __name__ == '__main__':

    if not os.path.exists(targetDir):
        os.makedirs(targetDir, exist_ok=True)
        raise FileNotFoundError(f"请放入PDF：{targetDir}")

    try:
        m_Log.info(f"Start: dir={targetDir}, angle={rotation_angle}")

        # 1. 旋转（生成 rotated_*.pdf）
        m_PDF.rotate_pdf_pages(targetDir, rotation_angle)

        # 2. 收集文件
        all_files = os.listdir(targetDir)
        rotated_files = [f for f in all_files if f.startswith(
            "rotated_") and f.endswith(".pdf")]

        # 3. 覆盖原文件（-d）
        if delete_original:
            for f in rotated_files:
                rotated_path = os.path.join(targetDir, f)

                # 原文件名（去掉 rotated_ 前缀）
                original_name = f[len("rotated_"):]
                original_path = os.path.join(targetDir, original_name)

                # 先删除原文件（如果存在）
                if os.path.exists(original_path):
                    os.remove(original_path)

                # 再重命名 rotated → 原文件名
                os.rename(rotated_path, original_path)

        # 4. 输出目录处理（放在最后）
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)

            for f in os.listdir(targetDir):
                if f.endswith(".pdf"):
                    src = os.path.join(targetDir, f)
                    dst = os.path.join(output_dir, f)
                    shutil.move(src, dst)

        m_Log.info("Done")
        print("PDF旋转完成！")

    except Exception:
        m_Log.exception("rotate failed")
        raise
