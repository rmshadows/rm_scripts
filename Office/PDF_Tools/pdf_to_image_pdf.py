#!/usr/bin/env python3
"""
文字 PDF → 按页栅格化成 JPEG → 合成图片版 PDF（支持多页）。

这是实际做转换的程序。平时改 Office/PDF_Tools/Text_PDF_to_Img_PDF.sh
顶部的配置再运行那个脚本即可，它会把配置原样传给本文件。
直接运行本文件时，不带参数的默认值和那个脚本一致。

每一页都会保留，顺序与原文件一致。支持子目录，相对路径原样出现在输出目录。
不修改、不清空输入目录。多个 PDF 按进程并行，单个 PDF 的页面按 pdftoppm 并行。
渲染直接对准目标纸张。

依赖：
    sudo apt install poppler-utils
    python3 包：pypdf

用法（在 Office/PDF_Tools/ 下）：
    python3 pdf_to_image_pdf.py
    python3 pdf_to_image_pdf.py --dpi 200 --paper A3 --orientation auto
    python3 pdf_to_image_pdf.py --input input --output output --jobs 4

参数（省略时使用默认值）：
    --input DIR            输入目录，递归找 PDF。默认 input
    --output DIR           输出目录，相对路径与输入一致。默认 output
    --dpi N                印到纸面上的分辨率，36–1200。300 适合打印，150/200 更快。默认 300
    --paper NAME           目标纸张：A3 / A4 / A5 / Letter / Legal。默认 A4
    --orientation MODE     auto：横页出横版，竖页出竖版
                           portrait：全部放进竖版纸（默认）
                           landscape：全部放进横版纸
    --jpeg-quality N       JPEG 质量，30–100。默认 90
    --jobs N               同时处理几个 PDF。0 表示按 CPU 自动（默认）。
                           只有一个多页 PDF 时，核心会用在按页渲染上
    --max-render-dpi N     渲染 DPI 上限，避免特别小的页面被放大到占满内存。默认 600

    python3 pdf_to_image_pdf.py -h
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed

from pypdf import PdfReader, PdfWriter
from pypdf.generic import DictionaryObject, NameObject, NumberObject, StreamObject


def human_size(num: int) -> str:
    if num >= 1024 ** 3:
        return f"{num / 1024 ** 3:.2f}G"
    if num >= 1024 ** 2:
        return f"{num / 1024 ** 2:.2f}M"
    if num >= 1024:
        return f"{num / 1024:.2f}K"
    return f"{num}B"

PAPER_POINTS = {
    "A3": (841.890, 1190.551),
    "A4": (595.276, 841.890),
    "A5": (419.528, 595.276),
    "LETTER": (612.0, 792.0),
    "LEGAL": (612.0, 1008.0),
}


def paper_points(name: str, landscape: bool) -> tuple[float, float]:
    key = name.upper()
    if key not in PAPER_POINTS:
        known = " / ".join(sorted(PAPER_POINTS))
        raise ValueError(f"不支持的纸张：{name}（可选 {known}）")
    width, height = PAPER_POINTS[key]
    if width > height:
        width, height = height, width
    if landscape:
        return height, width
    return width, height


def wants_landscape(src_w: float, src_h: float, orientation: str) -> bool:
    if orientation == "portrait":
        return False
    if orientation == "landscape":
        return True
    return src_w > src_h


def jpeg_info(data: bytes) -> tuple[int, int, int]:
    """返回 (宽, 高, 颜色通道数)。"""
    if len(data) < 4 or data[:2] != b"\xff\xd8":
        raise ValueError("不是 JPEG")
    index = 2
    limit = len(data)
    while index + 3 < limit:
        if data[index] != 0xFF:
            index += 1
            continue
        while index < limit and data[index] == 0xFF:
            index += 1
        if index >= limit:
            break
        marker = data[index]
        index += 1
        if marker in (0xD8, 0xD9) or marker == 0x01 or 0xD0 <= marker <= 0xD7:
            continue
        if index + 1 >= limit:
            break
        seg_len = int.from_bytes(data[index:index + 2], "big")
        if seg_len < 2 or index + seg_len > limit:
            break
        if marker in (0xC0, 0xC1, 0xC2):
            height = int.from_bytes(data[index + 3:index + 5], "big")
            width = int.from_bytes(data[index + 5:index + 7], "big")
            return width, height, data[index + 7]
        if marker == 0xDA:
            break
        index += seg_len
    raise ValueError("JPEG 里没有找到图像尺寸")


def _close_reader(reader: PdfReader) -> None:
    close = getattr(reader, "close", None)
    if close is not None:
        close()


def plan_render(path: str, paper: str, out_dpi: int, orientation: str, max_render_dpi: int) -> tuple[int, int]:
    reader = PdfReader(path)
    try:
        if reader.is_encrypted:
            if reader.decrypt("") == 0:
                raise RuntimeError("PDF 已加密，无法读取")
        page_count = len(reader.pages)
        if page_count <= 0:
            raise RuntimeError("PDF 没有页面")
        needed = []
        for page in reader.pages:
            width = float(page.mediabox.width)
            height = float(page.mediabox.height)
            rotation = int(page.rotation or 0) % 360
            if rotation in (90, 270):
                width, height = height, width
            landscape = wants_landscape(width, height, orientation)
            page_w, page_h = paper_points(paper, landscape)
            if width < 1 or height < 1:
                needed.append(float(out_dpi))
            else:
                needed.append(out_dpi * min(page_w / width, page_h / height))
    finally:
        _close_reader(reader)

    render_dpi = int(round(max(needed)))
    render_dpi = max(36, min(render_dpi, max_render_dpi))
    return page_count, render_dpi


def _split_ranges(page_count: int, parts: int) -> list[tuple[int, int]]:
    parts = max(1, min(parts, page_count))
    base, extra = divmod(page_count, parts)
    ranges = []
    start = 1
    for index in range(parts):
        count = base + (1 if index < extra else 0)
        ranges.append((start, start + count - 1))
        start += count
    return ranges


def _page_number(path: str) -> int:
    stem = os.path.splitext(os.path.basename(path))[0]
    return int(stem.rsplit("-", 1)[1])


def _render_range(pdf_path: str, out_dir: str, first: int, last: int, dpi: int, quality: int) -> None:
    prefix = os.path.join(out_dir, f"r{first:05d}")
    cmd = [
        "pdftoppm",
        "-q",
        "-jpeg",
        "-r",
        str(dpi),
        "-jpegopt",
        f"quality={quality}",
        "-f",
        str(first),
        "-l",
        str(last),
        pdf_path,
        prefix,
    ]
    proc = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=False)
    if proc.returncode != 0:
        err = proc.stderr.decode("utf-8", "replace").strip()
        raise RuntimeError(err or f"pdftoppm 退出码 {proc.returncode}")


def render_pages(pdf_path: str, out_dir: str, page_count: int, dpi: int, quality: int, threads: int) -> list[str]:
    ranges = _split_ranges(page_count, threads)
    with ThreadPoolExecutor(max_workers=len(ranges)) as pool:
        list(pool.map(lambda item: _render_range(pdf_path, out_dir, item[0], item[1], dpi, quality), ranges))

    paths = [
        os.path.join(out_dir, name)
        for name in os.listdir(out_dir)
        if name.lower().endswith(".jpg")
    ]
    paths.sort(key=_page_number)
    numbers = [_page_number(path) for path in paths]
    expected = list(range(1, page_count + 1))
    if numbers != expected:
        raise RuntimeError(f"渲染页码不完整，期望 {page_count} 页，实际 {numbers}")
    return paths


def _add_jpeg_page(writer: PdfWriter, jpeg: bytes, render_dpi: int, paper: str, orientation: str) -> None:
    img_w, img_h, components = jpeg_info(jpeg)
    if components == 1:
        color_space = "/DeviceGray"
    elif components == 3:
        color_space = "/DeviceRGB"
    else:
        raise RuntimeError(f"JPEG 颜色通道数为 {components}，无法嵌入 PDF")

    landscape = wants_landscape(float(img_w), float(img_h), orientation)
    page_w, page_h = paper_points(paper, landscape)
    natural_w = img_w * 72.0 / render_dpi
    natural_h = img_h * 72.0 / render_dpi
    fit = min(page_w / natural_w, page_h / natural_h)
    draw_w = natural_w * fit
    draw_h = natural_h * fit
    origin_x = (page_w - draw_w) / 2.0
    origin_y = (page_h - draw_h) / 2.0

    image = StreamObject()
    image.set_data(jpeg)
    image.update({
        NameObject("/Type"): NameObject("/XObject"),
        NameObject("/Subtype"): NameObject("/Image"),
        NameObject("/Width"): NumberObject(img_w),
        NameObject("/Height"): NumberObject(img_h),
        NameObject("/ColorSpace"): NameObject(color_space),
        NameObject("/BitsPerComponent"): NumberObject(8),
        NameObject("/Filter"): NameObject("/DCTDecode"),
    })
    image_ref = writer._add_object(image)

    content = StreamObject()
    content.set_data(
        (
            f"q\n{draw_w:.4f} 0 0 {draw_h:.4f} {origin_x:.4f} {origin_y:.4f} cm\n/Im0 Do\nQ\n"
        ).encode("ascii")
    )
    content_ref = writer._add_object(content)

    page = writer.add_blank_page(width=page_w, height=page_h)
    resources = DictionaryObject()
    resources[NameObject("/XObject")] = DictionaryObject({NameObject("/Im0"): image_ref})
    page[NameObject("/Resources")] = resources
    page[NameObject("/Contents")] = content_ref


def write_image_pdf(jpeg_paths: list[str], dest: str, render_dpi: int, paper: str, orientation: str) -> None:
    writer = PdfWriter()
    for path in jpeg_paths:
        with open(path, "rb") as handle:
            _add_jpeg_page(writer, handle.read(), render_dpi, paper, orientation)
    with open(dest, "wb") as handle:
        writer.write(handle)


def _is_inside(child: str, parent: str) -> bool:
    child_abs = os.path.abspath(child)
    parent_abs = os.path.abspath(parent)
    return child_abs == parent_abs or child_abs.startswith(parent_abs + os.sep)


def collect_pdfs(root: str, output_dir: str) -> list[str]:
    found: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(
            name for name in dirnames
            if not name.startswith(".") and not _is_inside(os.path.join(dirpath, name), output_dir)
        )
        if _is_inside(dirpath, output_dir) and os.path.abspath(dirpath) != os.path.abspath(root):
            continue
        for name in filenames:
            if name.startswith(".") or not name.lower().endswith(".pdf"):
                continue
            path = os.path.join(dirpath, name)
            if _is_inside(path, output_dir):
                continue
            found.append(path)
    found.sort()
    return found


def process_one(task: dict) -> dict:
    rel = task["rel"]
    started = time.perf_counter()
    src = task["src"]
    dst = task["dst"]
    parent = os.path.dirname(os.path.abspath(dst))
    os.makedirs(parent, exist_ok=True)
    work = tempfile.mkdtemp(prefix=".render-", dir=parent)
    image_pdf = os.path.join(work, "image.pdf")
    try:
        page_count, render_dpi = plan_render(
            src, task["paper"], task["dpi"], task["orientation"], task["max_render_dpi"]
        )
        jpeg_paths = render_pages(
            src, work, page_count, render_dpi, task["jpeg_quality"], task["page_threads"]
        )
        write_image_pdf(jpeg_paths, image_pdf, render_dpi, task["paper"], task["orientation"])
        os.replace(image_pdf, dst)
        elapsed = time.perf_counter() - started
        after = os.path.getsize(dst)
        return {
            "ok": True,
            "rel": rel,
            "message": (
                f"完成：{rel}  {page_count} 页  "
                f"{human_size(task['before'])} → {human_size(after)}  {elapsed:.1f}s"
            ),
        }
    except Exception as exc:
        return {"ok": False, "rel": rel, "message": f"失败：{rel}  {exc}"}
    finally:
        shutil.rmtree(work, ignore_errors=True)


def plan_parallel(n_files: int, jobs: int, out_dpi: int, max_render_dpi: int) -> tuple[int, int]:
    cpu = os.cpu_count() or 1
    if jobs <= 0:
        jobs = cpu
    file_jobs = max(1, min(jobs, n_files, cpu))
    page_threads = max(1, cpu // file_jobs)
    render_dpi = min(max(out_dpi, int(out_dpi * 1.5)), max_render_dpi)
    page_bytes = (11.7 * render_dpi) * (16.5 * render_dpi) * 4
    if page_bytes > 0:
        ram_cap = max(1, int((2 * 1024 ** 3) / page_bytes))
        page_threads = min(page_threads, ram_cap)
    return file_jobs, max(1, page_threads)


def _run(tasks: list[dict], jobs: int) -> list[dict]:
    if jobs == 1:
        results = []
        for task in tasks:
            item = process_one(task)
            print(item["message"], flush=True)
            results.append(item)
        return results

    order = {task["rel"]: index for index, task in enumerate(tasks)}
    results: list[dict | None] = [None] * len(tasks)
    with ProcessPoolExecutor(max_workers=jobs) as pool:
        futures = [pool.submit(process_one, task) for task in tasks]
        for future in as_completed(futures):
            item = future.result()
            print(item["message"], flush=True)
            results[order[item["rel"]]] = item
    return [item for item in results if item is not None]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="文字 PDF 转图片版 PDF。不带参数时：input/ → output/，A4 竖版，300 DPI。",
        epilog="平时可改 Text_PDF_to_Img_PDF.sh 顶部配置后运行那个脚本，效果相同。",
    )
    parser.add_argument("--input", default="input", help="输入目录，递归查找 PDF（默认 input）")
    parser.add_argument("--output", default="output", help="输出目录，保留相对路径（默认 output）")
    parser.add_argument("--dpi", type=int, default=300, help="印到纸面上的分辨率，36–1200（默认 300）")
    parser.add_argument("--paper", default="A4", help="目标纸张：A3 / A4 / A5 / Letter / Legal（默认 A4）")
    parser.add_argument(
        "--orientation",
        choices=("auto", "portrait", "landscape"),
        default="portrait",
        help="auto 按原页方向，portrait 全部竖版，landscape 全部横版（默认 portrait）",
    )
    parser.add_argument("--jpeg-quality", type=int, default=90, help="JPEG 质量，30–100（默认 90）")
    parser.add_argument("--jobs", type=int, default=0, help="同时处理的 PDF 数，0 为按 CPU 自动")
    parser.add_argument("--max-render-dpi", type=int, default=600, help="渲染 DPI 上限（默认 600）")
    args = parser.parse_args()

    if args.dpi < 36 or args.dpi > 1200:
        print("错误：--dpi 需要在 36 到 1200 之间", file=sys.stderr)
        return 1
    if not 30 <= args.jpeg_quality <= 100:
        print("错误：--jpeg-quality 需要在 30 到 100 之间", file=sys.stderr)
        return 1
    if args.max_render_dpi < 36:
        print("错误：--max-render-dpi 不能小于 36", file=sys.stderr)
        return 1
    if shutil.which("pdftoppm") is None:
        print("错误：未找到 pdftoppm，请安装 poppler-utils", file=sys.stderr)
        return 1

    if not os.path.isdir(args.input):
        os.makedirs(args.input, exist_ok=True)
        print(f"输入目录不存在，已新建：{args.input}")
        print("请把 PDF 放进去后重新运行。")
        return 1

    os.makedirs(args.output, exist_ok=True)
    pdfs = collect_pdfs(args.input, args.output)
    if not pdfs:
        print(f"{args.input}/ 中没有 PDF 文件，请先放入 PDF 后重试。", file=sys.stderr)
        return 1

    file_jobs, page_threads = plan_parallel(len(pdfs), args.jobs, args.dpi, args.max_render_dpi)
    print(f"纸张   : {args.paper} ({args.orientation})")
    print(f"分辨率 : {args.dpi} DPI（渲染上限 {args.max_render_dpi}）")
    print(f"并行   : {file_jobs} 个文件同时处理，每个文件 {page_threads} 路渲染")
    print(f"输入   : {args.input}/")
    print(f"输出   : {args.output}/")
    print(flush=True)

    tasks = []
    for src in pdfs:
        rel = os.path.relpath(src, args.input)
        dst = os.path.join(args.output, rel)
        if os.path.abspath(src) == os.path.abspath(dst):
            print(f"失败：{rel}  输入和输出是同一个文件", file=sys.stderr)
            return 1
        tasks.append({
            "src": src,
            "dst": dst,
            "rel": rel,
            "before": os.path.getsize(src),
            "dpi": args.dpi,
            "paper": args.paper,
            "orientation": args.orientation,
            "jpeg_quality": args.jpeg_quality,
            "page_threads": page_threads,
            "max_render_dpi": args.max_render_dpi,
        })

    started = time.perf_counter()
    results = _run(tasks, file_jobs)
    failed = sum(not item["ok"] for item in results)
    print()
    print("========== 完成 ==========")
    print(f"总文件数 : {len(results)}")
    print(f"成功     : {len(results) - failed}")
    print(f"失败     : {failed}")
    print(f"用时     : {time.perf_counter() - started:.1f}s")
    print(f"输出目录 : {args.output}/")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
