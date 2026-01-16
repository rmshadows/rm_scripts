#!/usr/bin/python3
"""
PDF拆分(每一页),可实现pdf转图片

- targetPdf 可以是：
  1) PDF 文件：直接处理该文件
  2) 文件夹：遍历文件夹下所有 PDF 批处理（仅此模式下：input 不存在就新建并退出）

- outputPdfDir：不存在就直接创建（不退出）

可选：
- JpgMode=True：拆成 JPG；否则拆成单页 PDF
- exportAsPDF=True：把抽取结果重新合成为一个“选页 PDF”
"""

import os
import m_PDF
import m_System
import m_Log

# ========== 配置区域 ==========
# targetPdf = "1.pdf"
targetPdf = "input"
outputPdfDir = "output"

pages_string = None          # e.g. "2, 3-5"
# JpgMode = False              # True: JPG, False: PDF
JpgMode = True
jpgDPI = 600

exportAsPDF = False
outputPdf = "soutput.pdf"    # 单文件模式输出名

# 日志配置（脚本内置）
enable_log = False
log_path = "运行日志.log"
# =================================

m_Log.init_logger(enable_file=enable_log, log_path=log_path)


def ensure_output_dir(path: str):
    """output 目录：不存在就直接创建"""
    os.makedirs(path, exist_ok=True)


def ensure_input_dir_create_then_exit(path: str):
    """仅用于“输入是文件夹模式”：不存在就新建，然后报错退出"""
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)
        msg = f"输入PDF文件夹不存在，已新建：{path}。请把 PDF 放入该文件夹后重新运行。"
        m_Log.error(msg)
        raise FileNotFoundError(msg)


def split_pages(pdf_path: str, out_dir: str):
    """把一个 PDF 拆成单页 PDF 或 JPG"""
    if JpgMode:
        m_PDF.extract_pages_to_jpg(pdf_path, out_dir, pages_string, jpgDPI)
    else:
        m_PDF.extract_pages_to_pdf(pdf_path, out_dir, pages_string)


def export_selected_to_pdf(out_dir: str, out_pdf_path: str):
    """把 out_dir 的选页结果合成为一个 PDF"""
    if not exportAsPDF:
        return

    order_list = []
    if pages_string is not None:
        pages_list = m_PDF.parse_page_numbers(pages_string)
        if JpgMode:
            order_list = [os.path.join(out_dir, f"{i}.jpg") for i in pages_list]
        else:
            order_list = [os.path.join(out_dir, f"{i}.pdf") for i in pages_list]

    if JpgMode:
        if pages_string is None:
            m_PDF.image2pdf(out_dir, out_pdf_path, pdf_resolution=300.0)
        else:
            m_PDF.image2pdf(out_dir, out_pdf_path, order=order_list, pdf_resolution=300.0)
    else:
        if pages_string is None:
            m_PDF.mergePdfs(out_dir, out_pdf_path)
        else:
            m_PDF.mergePdfs(out_dir, out_pdf_path, order_list)


def process_one_pdf(pdf_path: str, out_dir: str, merged_pdf_path: str | None):
    """处理单个 PDF：拆分 +（可选）合并为一个选页 PDF"""
    m_Log.info(f"Start: {pdf_path} -> {out_dir} (jpgMode={JpgMode}, pages={pages_string})")

    os.makedirs(out_dir, exist_ok=True)
    split_pages(pdf_path, out_dir)

    if merged_pdf_path:
        export_selected_to_pdf(out_dir, merged_pdf_path)

    m_Log.info(f"Done: {pdf_path}")


if __name__ == '__main__':
    # ========= 单文件模式 =========
    if targetPdf.lower().endswith(".pdf"):
        # ✅ output：没有就创建（不退出）
        ensure_output_dir(outputPdfDir)
        if not os.path.isfile(targetPdf):
            msg = f"目标PDF文件不存在：{targetPdf}"
            m_Log.error(msg)
            raise FileNotFoundError(msg)

        try:
            merged_path = outputPdf if exportAsPDF else None
            process_one_pdf(targetPdf, outputPdfDir, merged_path)
            print("处理完成！")
        except Exception:
            m_Log.exception(f"Failed single file: {targetPdf}")
            raise

    # ========= 输入为文件夹：批处理模式（仅此模式下 input 不存在则新建并退出）=========
    else:
        ensure_input_dir_create_then_exit(targetPdf)
        # ✅ output：没有就创建（不退出）
        ensure_output_dir(outputPdfDir)
        pdffs = m_System.getSuffixFile("pdf", targetPdf, False)
        if not pdffs:
            msg = f"目录中未找到 PDF：{targetPdf}"
            m_Log.error(msg)
            raise FileNotFoundError(msg)

        for pdff in pdffs:
            try:
                pdfn = m_System.getFileNameOrDirectoryName(pdff)
                out_dir = os.path.join(outputPdfDir, pdfn)

                # 批处理的合并文件名：在原 PDF 同目录下生成 selected-xxx.pdf（你原来的行为）
                merged_path = m_System.editFilename(pdff, None, prefix="selected-") if exportAsPDF else None

                process_one_pdf(pdff, out_dir, merged_path)
            except Exception:
                m_Log.exception(f"Failed batch file: {pdff}")
                continue

        print("批处理完成！")
