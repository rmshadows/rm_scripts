#!/bin/bash

# 脚本名称：clamav_watchdog.sh
# 脚本用途：
# 实时监控目录内的文件变更（写入完成后触发），
# 自动使用 ClamAV 扫描新文件，发现病毒则移动至 quarantine 隔离目录。
#
# 使用方法：
#   ./clamav_watchdog.sh [监控目录] [日志文件]
#   默认：监控当前目录 ./ ，日志写入 /var/log/clamav_realtime.log

# =========================
# 配置区（可传参覆盖）
# =========================
WATCH_DIR="${1:-.}"  # 默认监控当前目录
LOG_FILE="${2:-/var/log/clamav_realtime.log}"
QUARANTINE_DIR="quarantine"

# =========================
# 前置检查
# =========================
if ! command -v inotifywait &>/dev/null; then
    echo "错误：未安装 inotify-tools，请先安装它（如 apt install inotify-tools）。"
    exit 1
fi

if ! command -v clamscan &>/dev/null; then
    echo "错误：未安装 ClamAV，请先安装它（如 apt install clamav）。"
    exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$QUARANTINE_DIR"

echo "开始监控目录：$WATCH_DIR"
echo "日志输出：$LOG_FILE"
echo "隔离目录：$QUARANTINE_DIR"
echo "按 Ctrl+C 停止监控"
echo "----------------------------------"

# =========================
# 主循环：监听并扫描
# =========================
inotifywait -m -e close_write "$WATCH_DIR" --format '%w%f' |
while read -r NEW_FILE; do
    if [ -f "$NEW_FILE" ]; then
        echo "$(date '+%F %T') 检测到文件完成写入：$NEW_FILE" | tee -a "$LOG_FILE"
        clamscan --move="$QUARANTINE_DIR" "$NEW_FILE" 2>&1 | tee -a "$LOG_FILE" &
    fi
done

