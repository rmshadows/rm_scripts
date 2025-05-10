#!/bin/bash
# 版本1
WATCH_DIR="$(pwd)"
RECURSIVE=false
LOG_FILE=""
FILTER_TEMP=false
OUTPUT_CHINESE=false

usage() {
    echo "用法: $0 [-r] [-l logfile] [-f] [-c]"
    echo "  -r           递归监视子目录"
    echo "  -l logfile   输出记录到指定日志文件"
    echo "  -f           过滤临时文件（如以 .~ 开头的文件）"
    echo "  -c           输出中文事件描述"
    exit 1
}

while getopts ":rl:fc" opt; do
  case ${opt} in
    r )
      RECURSIVE=true
      ;;
    l )
      LOG_FILE="$OPTARG"
      ;;
    f )
      FILTER_TEMP=true
      ;;
    c )
      OUTPUT_CHINESE=true
      ;;
    \? )
      usage
      ;;
  esac
done

command -v inotifywait >/dev/null 2>&1 || {
    echo >&2 "请先安装 inotify-tools"; exit 1;
}

echo "正在监视目录：$WATCH_DIR"
[ "$RECURSIVE" = true ] && echo "启用递归子目录监视"
[ -n "$LOG_FILE" ] && echo "日志输出到：$LOG_FILE"
[ "$FILTER_TEMP" = true ] && echo "已启用临时文件过滤（如以 .~ 开头的文件）"
[ "$OUTPUT_CHINESE" = true ] && echo "已启用中文输出"
echo "按 Ctrl+C 退出"

# 参数数组，避免格式串问题
ARGS=( -m -e modify,create,delete,move --timefmt "%Y-%m-%d %H:%M:%S" --format "[%T] %e %w%f" )
$RECURSIVE && ARGS+=(-r)

inotifywait "${ARGS[@]}" "$WATCH_DIR" | while read line; do
    # 如果启用了过滤临时文件，并且文件以 .~ 开头，则跳过该事件
    if [ "$FILTER_TEMP" = true ] && [[ "$line" =~ \.\/\.\~ ]]; then
        continue
    fi
    
    # 处理中文输出
    if [ "$OUTPUT_CHINESE" = true ]; then
        if [[ "$line" =~ CREATE ]]; then
            line="${line/CREATE/创建}"
        elif [[ "$line" =~ MODIFY ]]; then
            line="${line/MODIFY/修改}"
        elif [[ "$line" =~ DELETE ]]; then
            line="${line/DELETE/删除}"
        elif [[ "$line" =~ MOVED_FROM ]]; then
            line="${line/MOVED_FROM/移动_来源}"
        elif [[ "$line" =~ MOVED_TO ]]; then
            line="${line/MOVED_TO/移动_目标}"
        fi
    fi

    echo "$line"
    [ -n "$LOG_FILE" ] && echo "$line" >> "$LOG_FILE"
done
