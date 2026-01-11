#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
m_Log.py - 轻量日志模块（控制台 + 可选文件日志）

用途
- 给脚本提供统一的日志输出：info / warning / error / exception
- 支持“只输出控制台”或“同时写入日志文件”
- 支持指定日志文件位置：可以传“目录”或“完整文件名”
- 重点：exception() 会自动记录异常堆栈（traceback），方便定位问题

## 日志初始化
import m_Log
# ✅ 日志配置（脚本内置）
enable_log = True
log_path = "logsM"  # 目录：logs/xxx.log；或文件： "logs/split_error.log"
# ✅ 初始化日志
m_Log.init_logger(enable_file=enable_log, log_path=log_path)

m_Log.info(f"Start split: {pdf_path}")
m_Log.error(msg)
# ✅ 这里会把异常堆栈完整写到日志文件里
m_Log.exception(f"Failed split: {pdf_path}")

============================================================
快速使用（放在你的主脚本里）
------------------------------------------------------------
## 1) 导入
import m_Log

## 2)（可选）脚本内置配置：是否写文件、写到哪里
enable_log = True
log_path = "logErr"          # ① 目录：自动生成 logErr/pdf_split_YYYYmmdd_HHMMSS.log
# log_path = "logErr/split_error.log"  # ② 文件：固定写入该文件（默认追加）

## 3) 初始化（建议脚本启动时调用一次）
m_Log.init_logger(enable_file=enable_log, log_path=log_path)

## 4) 记录日志
m_Log.info("Start split ...")
m_Log.warning("Something might be wrong ...")
m_Log.error("A non-fatal error message ...")

## 5) 记录异常（关键）
try:
    1 / 0
except Exception:
    # ✅ 会把异常堆栈完整写到日志（控制台 + 文件）
    m_Log.exception("Failed split: some.pdf")

============================================================
log_path 规则说明
------------------------------------------------------------
init_logger(enable_file=True, log_path=...)

1) log_path 传 None / ""：
   - 默认当作目录 "logs"
   - 自动生成 logs/pdf_split_YYYYmmdd_HHMMSS.log

2) log_path 传“目录”：
   - 例如 "logs"、"logErr"、"logErr/"
   - 自动生成 <目录>/pdf_split_YYYYmmdd_HHMMSS.log

3) log_path 传“文件名”：
   - 例如 "logs/split_error.log"
   - 直接使用这个文件作为日志文件（默认追加写入）

============================================================
注意事项
------------------------------------------------------------
- init_logger() 只需要调用一次；重复调用不会重复添加 handler（避免日志重复输出）
- 如果你忘了 init_logger()，直接调用 m_Log.info/error/exception 也能用：
  模块会自动初始化一个默认 logger（默认写到 logs/）
"""

import os
import logging
from datetime import datetime
from typing import Optional

# 该模块内部使用的 logger 名称（同一名称确保全局复用同一个 logger）
_LOGGER_NAME = "pdf_split"


def init_logger(enable_file: bool = True, log_path: Optional[str] = "logs") -> logging.Logger:
    """
    初始化日志系统（建议在脚本开始处调用一次）。

    参数
    ----------
    enable_file : bool
        True  -> 输出到控制台 + 写入日志文件
        False -> 只输出到控制台

    log_path : Optional[str]
        日志位置，可传目录或文件名：
        - None / "" : 默认目录 "logs"，自动生成 logs/pdf_split_YYYYmmdd_HHMMSS.log
        - 目录路径 : 自动生成 <目录>/pdf_split_YYYYmmdd_HHMMSS.log
        - 文件路径 : 直接写入该文件（默认追加）

    返回
    ----------
    logging.Logger
        已配置好的 logger 对象（一般不需要直接用，直接调用 m_Log.info/error/exception 即可）
    """
    logger = logging.getLogger(_LOGGER_NAME)
    logger.setLevel(logging.INFO)

    # 避免重复添加 handler（例如脚本重复 import 或重复调用 init_logger）
    if getattr(logger, "_inited", False):
        return logger

    # 统一日志格式：时间 | 级别 | 内容
    fmt = logging.Formatter(
        fmt="%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # ========== 控制台输出 ==========
    sh = logging.StreamHandler()
    sh.setFormatter(fmt)
    logger.addHandler(sh)

    # ========== 文件输出（可选） ==========
    if enable_file:
        # log_path 为 None / "" 时，默认写到 logs/
        if not log_path:
            log_path = "logs"

        # 目录判定逻辑：
        # - 是已有目录：os.path.isdir(log_path)
        # - 或以路径分隔符结尾：log_path.endswith(os.sep)
        # - 或没有扩展名（如 "logErr"）：not os.path.splitext(log_path)[1]
        # 以上情况都当作“目录”，自动生成带时间戳文件名
        if os.path.isdir(log_path) or log_path.endswith(os.sep) or not os.path.splitext(log_path)[1]:
            os.makedirs(log_path, exist_ok=True)
            ts = datetime.now().strftime("%Y%m%d_H%M%S")
            log_file = os.path.join(log_path, f"pdf_split_{ts}.log")
        else:
            # 当作“文件路径”，确保父目录存在
            os.makedirs(os.path.dirname(os.path.abspath(log_path)), exist_ok=True)
            log_file = log_path

        # FileHandler 默认追加写入；如需覆盖写入，可把 FileHandler 改为 logging.FileHandler(log_file, mode="w", ...)
        fh = logging.FileHandler(log_file, encoding="utf-8")
        fh.setFormatter(fmt)
        logger.addHandler(fh)

        logger.info(f"Log file: {os.path.abspath(log_file)}")

    # 标记已初始化，后续调用 init_logger 不会重复加 handler
    logger._inited = True
    return logger


def _logger() -> logging.Logger:
    """
    获取本模块 logger。
    如果用户没有显式调用 init_logger，则这里会自动初始化一个默认 logger（写到 logs/）。
    """
    logger = logging.getLogger(_LOGGER_NAME)
    if not getattr(logger, "_inited", False):
        init_logger(enable_file=True, log_path="logs")
    return logger


def info(msg: str) -> None:
    """记录 INFO 级别日志（正常流程信息，如开始/完成）。"""
    _logger().info(msg)


def warning(msg: str) -> None:
    """记录 WARNING 级别日志（可继续运行，但可能存在问题的情况）。"""
    _logger().warning(msg)


def error(msg: str) -> None:
    """记录 ERROR 级别日志（错误信息文本，不包含堆栈）。"""
    _logger().error(msg)


def exception(msg: str) -> None:
    """
    记录异常日志（ERROR + traceback）。
    必须在 except 块中调用，才能自动把堆栈写入日志文件。
    """
    _logger().exception(msg)
