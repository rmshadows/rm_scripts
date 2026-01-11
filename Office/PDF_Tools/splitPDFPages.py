#!/usr/bin/python3
# 拆分pdf页面
import os
import m_PDF

## 日志初始化
import m_Log
# ✅ 日志配置（脚本内置）
enable_log = False
log_path = "运行日志.log"  # 目录：logs/xxx.log；或文件： "logs/split_error.log"
# ✅ 初始化日志
m_Log.init_logger(enable_file=enable_log, log_path=log_path)
# m_Log.info(f"Start split: {pdf_path}")
# m_Log.error(msg)
# ✅ 这里会把异常堆栈完整写到日志文件里
# m_Log.exception(f"Failed split: {pdf_path}")


# ========== 配置区域 ==========
input_dir = "pdfs"  # 指定要遍历的PDF文件夹
output_dir = "split_pages"  # 输出文件夹
# =================================

# ✅ 先检查输入目录是否存在：不存在就新建，并提示后退出（同时写日志）
if not os.path.exists(input_dir):
    os.makedirs(input_dir, exist_ok=True)
    msg = f"输入文件夹不存在，已新建：{input_dir}。请把 PDF 放入该文件夹后重新运行。"
    print(msg)
    m_Log.error(msg)
    raise SystemExit(1)

# 确保输出目录存在
os.makedirs(output_dir, exist_ok=True)

# 遍历 input_dir 下所有 PDF 文件
pdf_files = [f for f in os.listdir(input_dir) if f.lower().endswith(".pdf")]

for pdf in pdf_files:
    pdf_path = os.path.join(input_dir, pdf)
    try:
        m_Log.info(f"Start split: {pdf_path}")
        m_PDF.batch_split_pdf(pdf_path, output_dir)
        m_Log.info(f"Done split:  {pdf_path}")
    except Exception:
        # ✅ 这里会把异常堆栈完整写到日志文件里（你要的“特别是报错一定要记录”）
        m_Log.exception(f"Failed split: {pdf_path}")

print("所有 PDF 文件已拆分完成！")
m_Log.info("所有 PDF 文件已拆分完成！")
