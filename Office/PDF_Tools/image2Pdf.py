#!/usr/bin/python3
"""
图片转 PDF 脚本

功能说明：
1. 读取指定目录（input）中的图片文件（png / jpg / jpeg）
2. 自动将 png、jpeg 统一转换为 jpg 格式（保证兼容性）
3. 按文件名自然排序后，将所有图片顺序合成为一个 PDF
4. 默认可为每一页生成目录（以图片文件名为索引，可在函数中控制）

运行流程：
- 若输入目录不存在，则自动创建并提示用户放入图片
- 调用 m_PDF.image2pdf 完成图片收集、格式统一、排序与合成
- 过程中可记录日志（可开关）
- 输出为单个 PDF 文件（output.pdf）

输出结果：
- 在当前目录生成 output.pdf
- 页面顺序与图片文件名排序一致
"""
import os
import m_PDF
import m_Log

imageDir = "input"
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
