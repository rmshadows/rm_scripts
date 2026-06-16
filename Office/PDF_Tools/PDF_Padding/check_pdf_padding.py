#!/usr/bin/env python3
"""
检查 PDF 是否含有体积扩大 padding（含伪装 font subset 与旧版标记）
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass, field
from typing import List

from pdf_pad_common import scan_embed_attachments, scan_tail_padding


@dataclass
class PaddingFinding:
    kind: str
    detail: str
    bytes_size: int


@dataclass
class PaddingReport:
    path: str
    file_size: int
    findings: List[PaddingFinding] = field(default_factory=list)

    @property
    def has_padding(self) -> bool:
        return len(self.findings) > 0


def human_size(num: int) -> str:
    if num >= 1024 ** 3:
        return f"{num / 1024 ** 3:.2f}G"
    if num >= 1024 ** 2:
        return f"{num / 1024 ** 2:.2f}M"
    if num >= 1024:
        return f"{num / 1024:.2f}K"
    return f"{num}B"


def _kind_label(kind: str, name: str = "") -> str:
    labels = {
        "pad_disguised": "尾部填充 (font subset 伪装)",
        "pad_legacy": "尾部填充 (旧版标记)",
        "embed_topup_legacy": "嵌入补齐尾部 (旧版标记)",
        "embed_disguised": f"嵌入附件 {name} (font 伪装)",
        "embed_legacy": f"嵌入附件 {name} (旧版)",
    }
    return labels.get(kind, kind)


def inspect_pdf(pdf_path: str) -> PaddingReport:
    file_size = os.path.getsize(pdf_path)
    report = PaddingReport(path=pdf_path, file_size=file_size)

    with open(pdf_path, "rb") as f:
        data = f.read()

    for kind, size in scan_tail_padding(data):
        report.findings.append(
            PaddingFinding(kind, _kind_label(kind), size)
        )

    for kind, name, size in scan_embed_attachments(pdf_path):
        report.findings.append(
            PaddingFinding(kind, _kind_label(kind, name), size)
        )

    return report


def print_report(report: PaddingReport, show_clean: bool = True) -> None:
    if show_clean or report.has_padding:
        status = "有 padding" if report.has_padding else "无 padding"
        print(f"[{status}] {report.path}  ({human_size(report.file_size)})")

    for item in report.findings:
        print(f"  - {item.detail}: {human_size(item.bytes_size)}")


def collect_pdfs(path: str) -> List[str]:
    if os.path.isfile(path):
        return [path]
    pdfs: List[str] = []
    for root, _, files in os.walk(path):
        for name in sorted(files):
            if name.lower().endswith(".pdf"):
                pdfs.append(os.path.join(root, name))
    return pdfs


def main() -> int:
    parser = argparse.ArgumentParser(description="检查 PDF 是否含有 padding")
    parser.add_argument("target", nargs="?", default="input", help="PDF 文件或目录")
    parser.add_argument("--quiet-clean", action="store_true", help="不显示无 padding 的文件")
    args = parser.parse_args()

    if not os.path.exists(args.target):
        print(f"错误：路径不存在：{args.target}", file=sys.stderr)
        return 1

    pdfs = collect_pdfs(args.target)
    if not pdfs:
        print(f"未找到 PDF：{args.target}", file=sys.stderr)
        return 1

    padded = clean = 0
    print("========== PDF Padding 检查 ==========")
    print(f"检查路径 : {args.target}\n")

    for pdf in pdfs:
        report = inspect_pdf(pdf)
        padded += report.has_padding
        clean += not report.has_padding
        print_report(report, show_clean=not args.quiet_clean)

    print("\n========== 完成 ==========")
    print(f"总文件数   : {len(pdfs)}")
    print(f"有 padding : {padded}")
    print(f"无 padding : {clean}")
    return 1 if padded else 0


if __name__ == "__main__":
    raise SystemExit(main())
