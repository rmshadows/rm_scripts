"""PDF 体积 padding 的伪装与检测（expand / check 共用）"""

from __future__ import annotations

import hashlib
import os
from typing import List, Optional, Tuple

# 内部 magic（藏在二进制里，外观不像 padding 标记）
PADDING_MAGIC = b"PAD\x7f"

# 旧版明显标记（仅用于兼容检测）
LEGACY_PAD_MARKER = b"\n% PDF size padding\n"
LEGACY_EMBED_TOPUP_MARKER = b"\n% PDF size padding (embed top-up)\n"
LEGACY_EMBED_ATTACHMENT = "_size_padding.bin"

_FONT_SUBSET_PREFIXES = ("KQXBTX", "QHQRVL", "WXYZAB", "MNOPQR", "ABCDEF", "UVWXYY")
_FONT_SUBSET_NAMES = (
    "NimbusSanL-Regu",
    "ArialMT",
    "TimesNewRomanPSMT",
    "CourierNewPSMT",
    "Calibri",
    "SimSun",
    "DroidSansFallback",
)


def pick_font_attachment_name(seed: str) -> str:
    """生成类似 PDF 子集字体的附件名，例如 KQXBTX+NimbusSanL-Regu.ttf"""
    digest = hashlib.md5(seed.encode("utf-8")).hexdigest()
    h = int(digest[:8], 16)
    prefix = _FONT_SUBSET_PREFIXES[h % len(_FONT_SUBSET_PREFIXES)]
    font = _FONT_SUBSET_NAMES[h % len(_FONT_SUBSET_NAMES)]
    return f"{prefix}+{font}.ttf"


def _font_like_fill(size: int) -> bytes:
    """填充字节：避免大段全 0，略像 font binary table 数据。"""
    if size <= 0:
        return b""
    base = bytes((i * 37 + 11) % 256 for i in range(256))
    reps = size // len(base) + 1
    return (base * reps)[:size]


def build_font_disguise_payload(body_size: int) -> bytes:
    """
    构造伪装成 TrueType 子集数据的附件内容。
    body_size 为附件 payload 总长度。
    """
    header = (
        b"\x00\x01\x00\x00"       # TrueType sfnt version
        b"\x00\x0c"               # numTables
        b"\x00\x30\x00\x00"
        b"cmapglyfheadhheahmtx"
        b"locamaxpnamepostOS/2"
        + PADDING_MAGIC
    )
    fill = max(0, body_size - len(header))
    return header + _font_like_fill(fill)


def build_tail_disguise_block(add_bytes: int) -> bytes:
    """
    尾部填充：仿 PDF 文档私有数据 / font subset 注释 + 二进制块。
    add_bytes 为追加的总字节数（含头部）。
    """
    if add_bytes <= 0:
        return b""

    header = (
        b"\n%%DocumentPrivateData: FontSubsetCache\r\n"
        b"% Embedded glyph subset table\r\n"
        + PADDING_MAGIC
    )
    if add_bytes <= len(header):
        return header[:add_bytes]

    fill = add_bytes - len(header)
    return header + _font_like_fill(fill)


def payload_has_magic(payload: bytes) -> bool:
    return PADDING_MAGIC in payload


def attachment_payload_bytes(payload) -> bytes:
    if isinstance(payload, (bytes, bytearray)):
        return bytes(payload)
    if hasattr(payload, "get_data"):
        return payload.get_data()
    return bytes(payload)


def scan_tail_padding(data: bytes) -> List[Tuple[str, int]]:
    """扫描文件尾部 padding，返回 [(kind, bytes_size), ...]"""
    findings: List[Tuple[str, int]] = []

    legacy_pad = data.rfind(LEGACY_PAD_MARKER)
    if legacy_pad >= 0:
        size = len(data) - legacy_pad - len(LEGACY_PAD_MARKER)
        findings.append(("pad_legacy", size))

    legacy_topup = data.rfind(LEGACY_EMBED_TOPUP_MARKER)
    if legacy_topup >= 0:
        size = len(data) - legacy_topup - len(LEGACY_EMBED_TOPUP_MARKER)
        findings.append(("embed_topup_legacy", size))

    magic_idx = data.rfind(PADDING_MAGIC)
    if magic_idx >= 0:
        eof_idx = data.rfind(b"%%EOF")
        if eof_idx >= 0 and magic_idx > eof_idx:
            size = len(data) - magic_idx - len(PADDING_MAGIC)
            # 往回找到块起点（%%DocumentPrivateData 或旧 marker 之后）
            block_start = data.rfind(b"\n%%DocumentPrivateData:", 0, magic_idx)
            if block_start < 0:
                block_start = magic_idx
            total = len(data) - block_start
            findings.append(("pad_disguised", total if total > 0 else size))

    return findings


def scan_embed_attachments(pdf_path: str) -> List[Tuple[str, str, int]]:
    """扫描附件 padding，返回 [(kind, display_name, bytes_size), ...]"""
    from pypdf import PdfReader

    findings: List[Tuple[str, str, int]] = []
    try:
        reader = PdfReader(pdf_path)
    except Exception:
        return findings

    attachments = reader.attachments or {}
    for name, items in attachments.items():
        if not items:
            continue
        payload = attachment_payload_bytes(items[0])
        if name == LEGACY_EMBED_ATTACHMENT:
            findings.append(("embed_legacy", name, len(payload)))
        elif payload_has_magic(payload):
            findings.append(("embed_disguised", name, len(payload)))

    return findings
