#!/usr/bin/python3
"""
PDF 拆分脚本（批量按页拆分）

📌 使用方式：
1. 将需要拆分的 PDF 文件放入：
   ./input/

   示例：
   input/
     ├── A.pdf
     ├── B.pdf

2. 运行脚本：
   python3 splitPdf.py

3. 拆分结果输出到：
   ./split_pages/

   示例：
   split_pages/
     ├── A_page1.pdf
     ├── A_page2.pdf
     ├── B_page1.pdf
     ├── B_page2.pdf


============================================================

⚙️ 脚本做了什么（执行流程）：

1. 检查输入目录 input/
   - 若不存在：自动创建
   - 提示用户放入 PDF 后退出（避免空跑）

2. 扫描 input/ 下所有 PDF 文件
   - 仅处理 .pdf（不区分大小写）

3. 逐个 PDF 进行拆分
   - 每一页生成一个独立 PDF
   - 命名规则：原文件名_pageX.pdf

4. 输出到 split_pages/ 目录
   - 自动创建目录（如不存在）

5. 全程支持日志记录（可开关）
   - 正常处理：记录开始/完成
   - 异常情况：记录完整错误堆栈


============================================================

📂 目录结构示意：

当前目录/
├── splitPdf.py
├── input/
│   └── xxx.pdf
└── split_pages/
    └── xxx_page1.pdf


============================================================

⚠️ 注意事项：

- 仅拆分，不修改原 PDF
- 输出文件会覆盖同名文件（若存在）
- 若 PDF 损坏，可能拆分失败（错误会写入日志）
- 日志默认关闭，可通过 enable_log 开启

"""
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
input_dir = "input"  # 指定要遍历的PDF文件夹
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
