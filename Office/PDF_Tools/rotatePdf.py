#!/usr/bin/python3
"""
PDF文件顺时针旋转
"""
import os
import m_PDF
import m_Log

# 工作目录
targetDir = "pdfPages"
rotation_angle = 90

# ✅ 日志配置（脚本内置）
enable_log = False
log_path = "运行日志.log"   # 目录或文件：例如 "logErr/rotate_pdf.log"
m_Log.init_logger(enable_file=enable_log, log_path=log_path)

if __name__ == '__main__':
    # ✅ 没有 targetDir 就新建，然后报错退出（同时写日志）
    if not os.path.exists(targetDir):
        os.makedirs(targetDir, exist_ok=True)
        msg = f"输入PDF文件夹不存在，已新建：{targetDir}。请把 PDF 放入该文件夹后重新运行。"
        m_Log.error(msg)
        raise FileNotFoundError(msg)

    try:
        m_Log.info(f"Start rotate_pdf_pages: targetDir={targetDir}, rotation_angle={rotation_angle}")
        m_PDF.rotate_pdf_pages(targetDir, rotation_angle)
        m_Log.info("Done rotate_pdf_pages")
        print("PDF旋转完成！")
    except Exception:
        # ✅ 记录异常堆栈
        m_Log.exception(f"rotate_pdf_pages failed: targetDir={targetDir}, rotation_angle={rotation_angle}")
        raise
