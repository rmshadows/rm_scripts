#!/bin/bash
# 轮转 fluxbox 日志（startup 调用）

LOG="${HOME}/.fluxbox/log"
MAX_BYTES=5242880  # 5MB

if [ ! -f "$LOG" ]; then
    exit 0
fi

size=$(stat -c%s "$LOG" 2>/dev/null || stat -f%z "$LOG" 2>/dev/null || echo 0)
if [ "$size" -gt "$MAX_BYTES" ]; then
    mv -f "$LOG" "${LOG}.old"
    : > "$LOG"
fi
