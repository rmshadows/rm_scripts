"""通用文件 padding / 还原（truncate / dd / disguise）"""

from __future__ import annotations

import os
import struct
import zlib
from dataclasses import dataclass
from enum import IntEnum
from typing import Optional, Tuple

from pdf_pad_common import (
    PADDING_MAGIC,
    build_font_disguise_payload,
    build_tail_disguise_block,
    pick_font_attachment_name,
)

# ========== 元数据格式 ==========
FPAD_MAGIC = b"FPADv1\x7f"
FPADREC_MAGIC = b"FPADREC\x7f"
HEADER_SIZE = 32

PNG_IEND = b"IEND\xaeB`\x82"
JPEG_EOI = b"\xff\xd9"


class PadMethod(IntEnum):
    TRUNCATE = 0
    DD = 1
    DISGUISE = 2


class FillType(IntEnum):
    ZERO = 0
    RANDOM = 1
    FONT_LIKE = 2


class FileKind(IntEnum):
    UNKNOWN = 0
    PDF = 1
    PNG = 2
    JPEG = 3
    GIF = 4
    WEBP = 5
    BMP = 6
    TIFF = 7
    ZIP = 8
    MP4 = 9
    MP3 = 10
    WAV = 11
    FLAC = 12
    OGG = 13
    AVI = 14
    TAR = 15
    PE = 16
    ELF = 17
    SQLITE = 18
    XML = 19
    RTF = 20
    TEXT = 21
    ICO = 22
    PSD = 23
    MKV = 24
    RAR = 25
    SEVENZ = 26


# 扩展名 → 类型（小写）
_EXT_MAP: dict[str, FileKind] = {
    ".pdf": FileKind.PDF,
    ".png": FileKind.PNG,
    ".jpg": FileKind.JPEG,
    ".jpeg": FileKind.JPEG,
    ".jpe": FileKind.JPEG,
    ".jfif": FileKind.JPEG,
    ".gif": FileKind.GIF,
    ".webp": FileKind.WEBP,
    ".bmp": FileKind.BMP,
    ".dib": FileKind.BMP,
    ".tif": FileKind.TIFF,
    ".tiff": FileKind.TIFF,
    ".zip": FileKind.ZIP,
    ".docx": FileKind.ZIP,
    ".xlsx": FileKind.ZIP,
    ".pptx": FileKind.ZIP,
    ".odt": FileKind.ZIP,
    ".ods": FileKind.ZIP,
    ".odp": FileKind.ZIP,
    ".jar": FileKind.ZIP,
    ".apk": FileKind.ZIP,
    ".epub": FileKind.ZIP,
    ".kmz": FileKind.ZIP,
    ".whl": FileKind.ZIP,
    ".docm": FileKind.ZIP,
    ".xlsm": FileKind.ZIP,
    ".pptm": FileKind.ZIP,
    ".mp4": FileKind.MP4,
    ".m4v": FileKind.MP4,
    ".mov": FileKind.MP4,
    ".3gp": FileKind.MP4,
    ".3g2": FileKind.MP4,
    ".mp3": FileKind.MP3,
    ".wav": FileKind.WAV,
    ".flac": FileKind.FLAC,
    ".ogg": FileKind.OGG,
    ".oga": FileKind.OGG,
    ".ogv": FileKind.OGG,
    ".opus": FileKind.OGG,
    ".avi": FileKind.AVI,
    ".tar": FileKind.TAR,
    ".exe": FileKind.PE,
    ".dll": FileKind.PE,
    ".sys": FileKind.PE,
    ".scr": FileKind.PE,
    ".so": FileKind.ELF,
    ".elf": FileKind.ELF,
    ".db": FileKind.SQLITE,
    ".sqlite": FileKind.SQLITE,
    ".sqlite3": FileKind.SQLITE,
    ".db3": FileKind.SQLITE,
    ".xml": FileKind.XML,
    ".html": FileKind.XML,
    ".htm": FileKind.XML,
    ".xhtml": FileKind.XML,
    ".svg": FileKind.XML,
    ".xsd": FileKind.XML,
    ".xsl": FileKind.XML,
    ".rss": FileKind.XML,
    ".rtf": FileKind.RTF,
    ".txt": FileKind.TEXT,
    ".csv": FileKind.TEXT,
    ".md": FileKind.TEXT,
    ".markdown": FileKind.TEXT,
    ".log": FileKind.TEXT,
    ".ini": FileKind.TEXT,
    ".cfg": FileKind.TEXT,
    ".conf": FileKind.TEXT,
    ".yaml": FileKind.TEXT,
    ".yml": FileKind.TEXT,
    ".json": FileKind.TEXT,
    ".toml": FileKind.TEXT,
    ".properties": FileKind.TEXT,
    ".ico": FileKind.ICO,
    ".cur": FileKind.ICO,
    ".psd": FileKind.PSD,
    ".mkv": FileKind.MKV,
    ".webm": FileKind.MKV,
    ".mka": FileKind.MKV,
    ".rar": FileKind.RAR,
    ".7z": FileKind.SEVENZ,
}

_KIND_LABELS: dict[FileKind, str] = {
    FileKind.PDF: "PDF",
    FileKind.PNG: "PNG",
    FileKind.JPEG: "JPEG",
    FileKind.GIF: "GIF",
    FileKind.WEBP: "WebP",
    FileKind.BMP: "BMP",
    FileKind.TIFF: "TIFF",
    FileKind.ZIP: "ZIP/Office",
    FileKind.MP4: "MP4/MOV",
    FileKind.MP3: "MP3",
    FileKind.WAV: "WAV",
    FileKind.FLAC: "FLAC",
    FileKind.OGG: "OGG/Opus",
    FileKind.AVI: "AVI",
    FileKind.TAR: "TAR",
    FileKind.PE: "PE/EXE",
    FileKind.ELF: "ELF",
    FileKind.SQLITE: "SQLite",
    FileKind.XML: "XML/HTML",
    FileKind.RTF: "RTF",
    FileKind.TEXT: "文本/JSON",
    FileKind.ICO: "ICO",
    FileKind.PSD: "PSD",
    FileKind.MKV: "MKV/WebM",
    FileKind.RAR: "RAR",
    FileKind.SEVENZ: "7z",
    FileKind.UNKNOWN: "未知(随机填充)",
}

DISGUISE_SUPPORT_TEXT = """disguise 模式当前支持的常见文件类型：

  PDF        .pdf
  图片       .png .jpg .jpeg .gif .webp .bmp .tif .tiff .ico .psd
  Office     .docx .xlsx .pptx .docm .xlsm .pptm .odt .ods .odp
  压缩包     .zip .jar .apk .epub .whl .kmz .rar .7z .tar
  音视频     .mp4 .m4v .mov .3gp .mp3 .wav .flac .ogg .opus .avi .mkv .webm
  可执行     .exe .dll .sys .so .elf
  数据库     .db .sqlite .sqlite3
  文档文本   .xml .html .svg .rtf .txt .csv .md .json .yaml .ini .log ...

  未识别类型：末尾 FPAD 元数据 + 随机字节（仍可还原）
  PDF 大增量：子集字体附件 + recovery 块
"""


def kind_label(kind: FileKind) -> str:
    return _KIND_LABELS.get(kind, str(kind))


@dataclass
class PadInfo:
    path: str
    file_size: int
    orig_size: int
    pad_total: int
    method: PadMethod
    fill_type: FillType
    file_kind: FileKind
    recoverable: bool
    recovery_via: str  # "header" | "tail_block" | "legacy_pdf"

    @property
    def is_padded(self) -> bool:
        return self.recoverable or self.pad_total > 0


def detect_file_kind(path: str, data: Optional[bytes] = None) -> FileKind:
    ext = os.path.splitext(path)[1].lower()
    if ext in _EXT_MAP:
        return _EXT_MAP[ext]

    if not data:
        return FileKind.UNKNOWN

    head = data[:64]
    if head.startswith(b"%PDF"):
        return FileKind.PDF
    if head.startswith(b"\x89PNG\r\n\x1a\n"):
        return FileKind.PNG
    if head[:2] == b"\xff\xd8":
        return FileKind.JPEG
    if head[:6] in (b"GIF87a", b"GIF89a"):
        return FileKind.GIF
    if len(head) >= 12 and head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return FileKind.WEBP
    if head[:2] == b"BM":
        return FileKind.BMP
    if head[:4] in (b"II*\x00", b"MM\x00*"):
        return FileKind.TIFF
    if head[:4] == b"PK\x03\x04":
        return FileKind.ZIP
    if len(head) >= 8 and head[4:8] == b"ftyp":
        return FileKind.MP4
    if head[:3] == b"ID3" or head[:2] == b"\xff\xfb" or head[:2] == b"\xff\xfa":
        return FileKind.MP3
    if len(head) >= 12 and head[:4] == b"RIFF" and head[8:12] == b"WAVE":
        return FileKind.WAV
    if head[:4] == b"fLaC":
        return FileKind.FLAC
    if head[:4] == b"OggS":
        return FileKind.OGG
    if len(head) >= 12 and head[:4] == b"RIFF" and head[8:12] == b"AVI ":
        return FileKind.AVI
    if head[:2] == b"\x1f\x8b":
        return FileKind.UNKNOWN  # gzip 不宜尾部追加
    if head[:6] == b"ustar\x00" or head[:6] == b"ustar ":
        return FileKind.TAR
    if head[:2] == b"MZ":
        return FileKind.PE
    if head[:4] == b"\x7fELF":
        return FileKind.ELF
    if head[:16] == b"SQLite format 3\x00":
        return FileKind.SQLITE
    if head.lstrip().startswith((b"<?xml", b"<html", b"<!DOCTYPE", b"<svg")):
        return FileKind.XML
    if head.lstrip().startswith(b"{\\rtf"):
        return FileKind.RTF
    if head[:4] == b"\x00\x00\x01\x00":
        return FileKind.ICO
    if head[:4] == b"8BPS":
        return FileKind.PSD
    if head[:4] == b"\x1aE\xdf\xa3":
        return FileKind.MKV
    if head[:7] == b"Rar!\x1a\x07":
        return FileKind.RAR
    if head[:6] == b"7z\xbc\xaf\x27\x1c":
        return FileKind.SEVENZ

    return FileKind.UNKNOWN


def _block(label: bytes, add_bytes: int) -> bytes:
    header = label + PADDING_MAGIC
    if add_bytes <= len(header):
        return header[:add_bytes]
    return header + generate_fill(add_bytes - len(header), FillType.FONT_LIKE)


def _riff_chunk(tag: bytes, add_bytes: int) -> bytes:
    """伪造 RIFF/JUNK/free 块。"""
    if add_bytes < 8:
        return _block(b"JUNK", add_bytes)
    body = add_bytes - 8
    inner = PADDING_MAGIC + generate_fill(max(0, body - len(PADDING_MAGIC)), FillType.FONT_LIKE)
    return struct.pack("<I", add_bytes - 8) + tag + inner[:body]


def _mp4_free_box(add_bytes: int) -> bytes:
    if add_bytes < 8:
        return _block(b"free", add_bytes)
    body = add_bytes - 8
    inner = PADDING_MAGIC + generate_fill(max(0, body - len(PADDING_MAGIC)), FillType.FONT_LIKE)
    return struct.pack(">I", add_bytes) + b"free" + inner[:body]


def build_disguise_tail(file_kind: FileKind, add_bytes: int) -> bytes:
    """按文件类型生成伪装 tail（不含 FPAD 32 字节头）。"""
    if add_bytes <= 0:
        return b""

    if file_kind == FileKind.PNG:
        return build_png_disguise_tail(add_bytes)
    if file_kind == FileKind.JPEG:
        return build_jpeg_disguise_tail(add_bytes)

    builders = {
        FileKind.GIF: lambda n: _block(b"!\xfe\x0fGIF Comment Metadata Cache", n),
        FileKind.WEBP: lambda n: _riff_chunk(b"JUNK", n),
        FileKind.BMP: lambda n: _block(b"BMETA-DIBX\x00color profile residue", n),
        FileKind.TIFF: lambda n: _block(b"TIFF IFD extension cache\x00", n),
        FileKind.ZIP: lambda n: _block(b"PK\x05\x06ZIP metadata comment cache\x00", n),
        FileKind.MP4: _mp4_free_box,
        FileKind.MP3: lambda n: _block(b"TAGMP3INFOCACHE\x00", n),
        FileKind.WAV: lambda n: _riff_chunk(b"free", n),
        FileKind.FLAC: lambda n: _block(b"\x81flac-padding-metadata-block", n),
        FileKind.OGG: lambda n: _block(b"OggS\x00meta-cache-packet", n),
        FileKind.AVI: lambda n: _riff_chunk(b"JUNK", n),
        FileKind.TAR: lambda n: _block(b"././@PaxHeader\x00padding-cache", n),
        FileKind.PE: lambda n: _block(b"WIN_CERTIFICATE_OVERLAY_CACHE\r\n", n),
        FileKind.ELF: lambda n: _block(b"\x00.comment\x00ELF note cache", n),
        FileKind.SQLITE: lambda n: _block(b"-- SQLite free-page cache extension\n", n),
        FileKind.XML: lambda n: _block(b"\n<!-- embedded metadata profile cache -->\n", n),
        FileKind.RTF: lambda n: _block(b"{\\*\\company metadata cache}", n),
        FileKind.TEXT: lambda n: _block(b"\n# metadata cache (system generated)\n", n),
        FileKind.ICO: lambda n: _block(b"ICODATA resource tail cache", n),
        FileKind.PSD: lambda n: _block(b"8BPSImageResourcesCache", n),
        FileKind.MKV: lambda n: _block(b"\xec\x85\xEBMLVoidElementCache", n),
        FileKind.RAR: lambda n: _block(b"Rar!\x1a\x07\x01RAR metadata cache\x00", n),
        FileKind.SEVENZ: lambda n: _block(b"7zBCAF27\x1c7z metadata pad", n),
        FileKind.UNKNOWN: lambda n: generate_fill(n, FillType.RANDOM),
    }

    builder = builders.get(file_kind, builders[FileKind.UNKNOWN])
    return builder(add_bytes)


def build_header(
    method: PadMethod,
    fill_type: FillType,
    orig_size: int,
    pad_total: int,
    file_kind: FileKind,
) -> bytes:
    return struct.pack(
        "<7sBBQQB6s",
        FPAD_MAGIC,
        int(method),
        int(fill_type),
        orig_size,
        pad_total,
        int(file_kind),
        b"\x00" * 6,
    )


def parse_header(data: bytes, offset: int) -> Optional[Tuple[PadMethod, FillType, int, int, FileKind]]:
    if offset + HEADER_SIZE > len(data):
        return None
    chunk = data[offset : offset + HEADER_SIZE]
    if not chunk.startswith(FPAD_MAGIC):
        return None
    (
        _magic,
        method,
        fill_type,
        orig_size,
        pad_total,
        file_kind,
        _reserved,
    ) = struct.unpack("<7sBBQQB6s", chunk)
    if pad_total < HEADER_SIZE:
        return None
    if offset + pad_total > len(data):
        return None
    return PadMethod(method), FillType(fill_type), orig_size, pad_total, FileKind(file_kind)


def generate_fill(size: int, fill_type: FillType) -> bytes:
    if size <= 0:
        return b""
    if fill_type == FillType.ZERO:
        return b"\x00" * size
    if fill_type == FillType.RANDOM:
        return os.urandom(size)
    base = bytes((i * 37 + 11) % 256 for i in range(256))
    reps = size // len(base) + 1
    return (base * reps)[:size]


def build_recovery_tail(original: bytes) -> bytes:
    """PDF embed 等改写模式：在文件末尾藏原始字节以便还原。"""
    disguise = b"\n%%DocumentFontBackup: subset archive\r\n"
    return disguise + FPADREC_MAGIC + struct.pack("<Q", len(original)) + original


def parse_recovery_tail(data: bytes) -> Optional[Tuple[int, bytes]]:
    idx = data.rfind(FPADREC_MAGIC)
    if idx < 0:
        return None
    start = idx + len(FPADREC_MAGIC)
    if start + 8 > len(data):
        return None
    (orig_len,) = struct.unpack("<Q", data[start : start + 8])
    payload_start = start + 8
    payload_end = payload_start + orig_len
    if payload_end != len(data):
        return None
    original = data[payload_start:payload_end]
    if len(original) != orig_len:
        return None
    return orig_len, original


def build_png_disguise_tail(add_bytes: int) -> bytes:
    if add_bytes <= 0:
        return b""
    text = b"Comment\x00Embedded color profile cache"
    body = b"tEXt" + text
    crc = struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)
    header = struct.pack(">I", len(body) - 4) + body + crc + PADDING_MAGIC
    fill = max(0, add_bytes - len(header))
    return header + generate_fill(fill, FillType.FONT_LIKE)


def build_jpeg_disguise_tail(add_bytes: int) -> bytes:
    if add_bytes <= 0:
        return b""
    comment = b"ICC_PROFILE_METADATA_CACHE"
    header = b"\xff\xfe" + struct.pack(">H", len(comment) + 2) + comment + PADDING_MAGIC
    fill = max(0, add_bytes - len(header))
    return header + generate_fill(fill, FillType.FONT_LIKE)


def scan_pad_info(path: str) -> PadInfo:
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        data = f.read()

    # 1) 尾部 recovery block（PDF embed 改写）
    rec = parse_recovery_tail(data)
    if rec:
        orig_len, _original = rec
        return PadInfo(
            path=path,
            file_size=size,
            orig_size=orig_len,
            pad_total=size - orig_len,
            method=PadMethod.DISGUISE,
            fill_type=FillType.FONT_LIKE,
            file_kind=detect_file_kind(path, data[:16]),
            recoverable=True,
            recovery_via="tail_block",
        )

    # 2) FPADv1 头（truncate / dd / disguise-append）
    idx = data.find(FPAD_MAGIC)
    while idx >= 0:
        parsed = parse_header(data, idx)
        if parsed and idx == parsed[2] and idx + parsed[3] == len(data):
            method, fill_type, orig_size, pad_total, file_kind = parsed
            return PadInfo(
                path=path,
                file_size=size,
                orig_size=orig_size,
                pad_total=pad_total,
                method=PadMethod(method),
                fill_type=FillType(fill_type),
                file_kind=FileKind(file_kind),
                recoverable=True,
                recovery_via="header",
            )
        idx = data.find(FPAD_MAGIC, idx + 1)

    # 3) 旧版 PDF padding（1-PDF_EXPAND_SIZE.sh，无法精确还原）
    if detect_file_kind(path, data[:16]) == FileKind.PDF:
        from pdf_pad_common import scan_embed_attachments, scan_tail_padding

        legacy = scan_tail_padding(data) + [
            (k, n, s) for k, n, s in scan_embed_attachments(path)
        ]
        if legacy:
            extra = 0
            for item in legacy:
                extra += item[1] if len(item) == 2 else item[2]
            return PadInfo(
                path=path,
                file_size=size,
                orig_size=0,
                pad_total=extra,
                method=PadMethod.DISGUISE,
                fill_type=FillType.FONT_LIKE,
                file_kind=FileKind.PDF,
                recoverable=False,
                recovery_via="legacy_pdf",
            )

    return PadInfo(
        path=path,
        file_size=size,
        orig_size=size,
        pad_total=0,
        method=PadMethod.DD,
        fill_type=FillType.ZERO,
        file_kind=detect_file_kind(path, data[:16]),
        recoverable=False,
        recovery_via="",
    )


def method_label(method: PadMethod) -> str:
    return {PadMethod.TRUNCATE: "truncate", PadMethod.DD: "dd", PadMethod.DISGUISE: "disguise"}[
        method
    ]


def fill_label(fill_type: FillType) -> str:
    return {
        FillType.ZERO: "zero",
        FillType.RANDOM: "random",
        FillType.FONT_LIKE: "font_like",
    }[fill_type]
