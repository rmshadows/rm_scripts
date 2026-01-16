#!/usr/bin/python3
"""
合并某个文件夹下面的pdf文件
"""
import os
import m_PDF
import m_Log

# 工作目录
targetDir = "input"
output = "output.pdf"

# ✅ 日志配置（脚本内置）
enable_log = False
log_path = "运行日志.log"   # 目录或文件：例如 "logErr/merge_pdf.log"
m_Log.init_logger(enable_file=enable_log, log_path=log_path)

if __name__ == '__main__':
    # ✅ 没有 targetDir 就新建，然后报错退出（同时写日志）
    if not os.path.exists(targetDir):
        os.makedirs(targetDir, exist_ok=True)
        msg = f"输入PDF文件夹不存在，已新建：{targetDir}。请把 PDF 放入该文件夹后重新运行。"
        m_Log.error(msg)
        raise FileNotFoundError(msg)

    try:
        m_Log.info(f"Start mergePdfs: targetDir={targetDir}, output={output}")
        m_PDF.mergePdfs(targetDir, output)
        m_Log.info(f"Done mergePdfs: output={output}")
        print("PDF合并完成！")
    except Exception:
        # ✅ 记录异常堆栈
        m_Log.exception(f"mergePdfs failed: targetDir={targetDir}, output={output}")
        raise
