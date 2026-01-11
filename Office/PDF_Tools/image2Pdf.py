#!/usr/bin/python3
"""
图片转pdf
"""
import os
import m_PDF
import m_Log

imageDir = "images"
output = "output.pdf"

# ✅ 日志配置（脚本内置）
enable_log = False
log_path = "运行日志.log"  # 目录或文件：例如 "logErr/img2pdf.log"
m_Log.init_logger(enable_file=enable_log, log_path=log_path)

if __name__ == '__main__':
    # ✅ 没有 imageDir 就新建一个，然后 raise 报错退出（同时写日志）
    if not os.path.exists(imageDir):
        os.makedirs(imageDir, exist_ok=True)
        msg = f"输入图片文件夹不存在，已新建：{imageDir}。请把图片放入该文件夹后重新运行。"
        m_Log.error(msg)
        raise FileNotFoundError(msg)

    try:
        m_Log.info(f"Start image2pdf: imageDir={imageDir}, output={output}")
        m_PDF.image2pdf(imageDir, output)
        m_Log.info(f"Done image2pdf: output={output}")
        print("图片转 PDF 完成！")
    except Exception:
        # ✅ 记录异常堆栈
        m_Log.exception(f"image2pdf failed: imageDir={imageDir}, output={output}")
        raise  # ✅ 继续抛出异常，让程序退出
